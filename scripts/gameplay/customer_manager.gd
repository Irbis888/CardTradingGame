class_name CustomerManager
extends Control


signal item_given(description: String)
signal replica_spoken(text: String)
signal customer_dialogue_ended(customer: CustomerData)
signal customer_spawned(customer: CustomerData)
signal negotiation_started(card: Card)
signal negotiation_updated(
	card: Card,
	player_ask: int,
	customer_offer: int,
	patience_left: int
)
signal negotiation_finished(card: Card, sold: bool, price: int)

const DEV_CONSOLE_GROUP := &"dev_console"
const CUSTOMER_MANAGER_GROUP := &"customer_manager"
const CONSOLE_MESSAGE_PREFIX := "Customer received: "
const TRADE_MESSAGE_PREFIX := "Trade: "
const PORTRAIT_PATH_TEMPLATE := "res://assets/portraits_new/Customer_00%d.png"
const DRAGGABLE_CARD_SCENE := preload("res://scenes/ui/draggable_card.tscn")

@export var drag_surface_path: NodePath
@export var card_return_surface_path: NodePath
@export var shop_money_counter_path: NodePath
@export var drop_region_path: NodePath = NodePath(".")
@export var portrait_path: NodePath
@export var handoff_layer_path: NodePath
@export var speech_bubble_path: NodePath
@export var speech_label_path: NodePath
@export var speech_timer_path: NodePath
@export var next_customer_timer_path: NodePath
@export var result_timer_path: NodePath
@export var available_portrait_numbers: Array[int] = [1, 2]
@export_range(0.0, 1.0, 0.05) var requested_card_chance := 0.7
@export_range(0.0, 1.0, 0.05) var reveal_price_chance := 0.55
@export_range(1, 20, 1) var minimum_patience := 2
@export_range(1, 20, 1) var maximum_patience := 5
@export_range(-0.5, 0.5, 0.05) var minimum_acceptability := -0.2
@export_range(-0.5, 0.5, 0.05) var maximum_acceptability := 0.35
@export_range(0.1, 60.0, 0.1, "or_greater") var default_replica_duration := 4.0
@export_range(0.05, 5.0, 0.05, "or_greater") var fade_duration := 0.35
@export_range(0.0, 10.0, 0.1, "or_greater") var next_customer_delay := 0.8
@export_range(0.1, 10.0, 0.1, "or_greater") var result_display_duration := 1.2
@export_range(0.0, 10000.0, 50.0, "or_greater") var handoff_fall_acceleration := 2400.0
@export_range(0.0, 5000.0, 25.0, "or_greater") var handoff_initial_fall_speed := 180.0
@export_range(0.0, 10000.0, 50.0, "or_greater") var handoff_maximum_fall_speed := 1800.0

var _drag_surface: Node
var _card_return_surface: Control
var _shop_money_counter: ShopMoneyCounter
var _drop_region: Control
var _portrait: TextureRect
var _handoff_layer: Control
var _speech_bubble: Control
var _speech_label: Label
var _speech_timer: Timer
var _next_customer_timer: Timer
var _result_timer: Timer
var _transition_tween: Tween
var _current_customer: CustomerData
var _active_negotiation: SellNegotiation
var _trade_text: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _shows_transfer_cursor := false
var _customer_present := false
var _transitioning := false
var _waiting_to_depart := false
var _pending_item_transfers: Array[Dictionary] = []


func _ready() -> void:
	add_to_group(CUSTOMER_MANAGER_GROUP)
	item_given.connect(_log_given_item)
	_rng.randomize()
	_load_trade_text()
	_resolve_node_references()
	_connect_timers()
	_prepare_empty_counter()
	_register_as_drop_receiver()
	call_deferred("_spawn_next_random_customer")


func _process(delta: float) -> void:
	_process_pending_item_transfers(delta)


func _exit_tree() -> void:
	clear_draggable_hover()
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	if is_instance_valid(_drag_surface) and _drag_surface.has_method("unregister_drop_receiver"):
		_drag_surface.call("unregister_drop_receiver", self)


func get_current_customer() -> CustomerData:
	return _current_customer


func get_active_negotiation() -> SellNegotiation:
	return _active_negotiation


func has_customer() -> bool:
	return _customer_present


func is_transitioning() -> bool:
	return _transitioning


func end_customer_dialogue() -> bool:
	if (
		not _customer_present
		or _transitioning
		or _portrait == null
		or not _pending_item_transfers.is_empty()
	):
		return false

	_abort_active_negotiation()
	_waiting_to_depart = false
	if _result_timer != null:
		_result_timer.stop()
	_transitioning = true
	clear_draggable_hover()
	_hide_replica()
	var departing_customer := _current_customer
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait,
		"modulate:a",
		0.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.finished.connect(
		_finish_customer_exit.bind(departing_customer)
	)
	return true


func spawn_new_customer(customer: CustomerData) -> bool:
	if customer == null or _customer_present or _transitioning or _portrait == null:
		return false
	if not _apply_portrait_texture(customer.portrait_number):
		return false

	if _next_customer_timer != null:
		_next_customer_timer.stop()
	_current_customer = customer
	_active_negotiation = (
		SellNegotiation.new(customer.requested_card, customer)
		if customer.requested_card != null
		else null
	)
	_transitioning = true
	_waiting_to_depart = false
	visible = true
	_portrait.visible = true
	modulate.a = 0.0
	_portrait.modulate.a = 0.0
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait,
		"modulate:a",
		1.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.finished.connect(
		_finish_customer_spawn.bind(customer)
	)
	return true


func try_accept_draggable(draggable, global_pointer: Vector2) -> bool:
	if not _can_interact_with_customer() or not _is_pointer_inside_drop_region(global_pointer):
		return false
	return not _describe_supported_item(draggable).is_empty()


func take_accepted_draggable(draggable) -> bool:
	if not is_instance_valid(_handoff_layer) or not is_instance_valid(_portrait):
		return false
	var description := _describe_supported_item(draggable)
	if description.is_empty():
		return false
	var target := draggable.get_target() as Control
	if target == null:
		return false

	draggable.enabled = false
	draggable.set_velocity(Vector2.ZERO)
	target.reparent(_handoff_layer, true)
	target.z_index = 0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pending_item_transfers.append({
		"target": target,
		"description": description,
		"fall_speed": handoff_initial_fall_speed,
	})
	return true


func update_draggable_hover(draggable, global_pointer: Vector2) -> void:
	var can_drop := (
		_can_interact_with_customer()
		and _is_pointer_inside_drop_region(global_pointer)
		and not _describe_supported_item(draggable).is_empty()
	)
	_set_transfer_cursor(can_drop)


func clear_draggable_hover() -> void:
	_set_transfer_cursor(false)


func say(text: String, duration: float = -1.0) -> bool:
	var replica := text.strip_edges()
	if (
		replica.is_empty()
		or not _customer_present
		or _transitioning
		or _speech_bubble == null
		or _speech_label == null
	):
		return false
	_speech_label.text = replica
	_speech_bubble.visible = true
	if _speech_timer != null:
		var visible_duration := duration if duration > 0.0 else default_replica_duration
		_speech_timer.start(visible_duration)
	replica_spoken.emit(replica)
	return true


func _resolve_node_references() -> void:
	_drag_surface = get_node_or_null(drag_surface_path)
	_card_return_surface = get_node_or_null(card_return_surface_path) as Control
	_shop_money_counter = get_node_or_null(shop_money_counter_path) as ShopMoneyCounter
	_drop_region = get_node_or_null(drop_region_path) as Control
	_portrait = get_node_or_null(portrait_path) as TextureRect
	_handoff_layer = get_node_or_null(handoff_layer_path) as Control
	_speech_bubble = get_node_or_null(speech_bubble_path) as Control
	_speech_label = get_node_or_null(speech_label_path) as Label
	_speech_timer = get_node_or_null(speech_timer_path) as Timer
	_next_customer_timer = get_node_or_null(next_customer_timer_path) as Timer
	_result_timer = get_node_or_null(result_timer_path) as Timer

	if _drop_region == null:
		push_error("CustomerManager requires drop_region_path to reference a Control.")
	if _portrait == null:
		push_error("CustomerManager requires portrait_path to reference a TextureRect.")
	if _handoff_layer == null:
		push_error("CustomerManager requires handoff_layer_path to reference a Control.")
	if _card_return_surface == null:
		push_error("CustomerManager requires card_return_surface_path.")
	if _shop_money_counter == null:
		push_error("CustomerManager requires shop_money_counter_path.")


func _connect_timers() -> void:
	if _speech_timer != null:
		_speech_timer.timeout.connect(_hide_replica)
	if _next_customer_timer != null:
		_next_customer_timer.timeout.connect(_spawn_next_random_customer)
	if _result_timer != null:
		_result_timer.timeout.connect(_on_result_timer_timeout)


func _prepare_empty_counter() -> void:
	_current_customer = null
	_active_negotiation = null
	_customer_present = false
	_transitioning = false
	_waiting_to_depart = false
	visible = false
	modulate.a = 1.0
	if _portrait != null:
		_portrait.visible = false
		_portrait.modulate.a = 1.0
	if _speech_bubble != null:
		_speech_bubble.visible = false


func _register_as_drop_receiver() -> void:
	if not is_instance_valid(_drag_surface):
		push_error("CustomerManager requires a valid drag_surface_path.")
		return
	if not _drag_surface.has_method("register_drop_receiver"):
		push_error("CustomerManager drag surface does not support drop receivers.")
		return
	_drag_surface.call("register_drop_receiver", self)


func _can_interact_with_customer() -> bool:
	return (
		_customer_present
		and not _transitioning
		and not _waiting_to_depart
		and _pending_item_transfers.is_empty()
	)


func _is_pointer_inside_drop_region(global_pointer: Vector2) -> bool:
	return (
		is_instance_valid(_drop_region)
		and _drop_region.is_visible_in_tree()
		and _drop_region.get_global_rect().has_point(global_pointer)
	)


func _describe_supported_item(draggable) -> String:
	if draggable == null or not draggable.has_method("get_target"):
		return ""
	var target := draggable.get_target() as Control
	if target is DraggableCard:
		var card := (target as DraggableCard).get_card_data()
		if card == null:
			return ""
		return "card #%d \"%s\" (%s, %s)" % [
			card.id,
			card.name,
			card.series,
			card.get_literal_name(),
		]
	if target is DraggableReceipt:
		var receipt := target as DraggableReceipt
		return "%s receipt for $%d" % [
			str(receipt.get_receipt_type()),
			receipt.get_amount(),
		]
	return ""


func _handle_delivered_item(target: Control) -> void:
	if target is DraggableCard:
		_receive_card((target as DraggableCard).get_card_data())
	elif target is DraggableReceipt:
		_receive_receipt(target as DraggableReceipt)


func _receive_card(card: Card) -> void:
	if card == null or _current_customer == null:
		return
	if _active_negotiation != null:
		if (
			_active_negotiation.card.id != card.id
			or _active_negotiation.card_presented
		):
			say(_trade_line("wrong_card", {"card": card.name}))
			_return_card_to_player(card)
			return
	else:
		_active_negotiation = SellNegotiation.new(card, _current_customer)

	_active_negotiation.present_card()
	negotiation_started.emit(card)
	if _current_customer.requested_card == null or _current_customer.reveals_price:
		say(_trade_line(
			"opening_offer",
			{"price": _active_negotiation.customer_offer}
		))
	else:
		say(_trade_line("request_card", {"card": card.name}))


func _receive_receipt(receipt: DraggableReceipt) -> void:
	if (
		receipt == null
		or _active_negotiation == null
		or not _active_negotiation.card_presented
	):
		say(_trade_line("card_first"))
		return

	var receipt_type := receipt.get_receipt_type()
	if receipt_type != &"ASK" and receipt_type != &"OFFER":
		say(_trade_line("ask_only"))
		return

	var result := _active_negotiation.submit_ask(
		receipt.get_amount(),
		receipt_type == &"OFFER"
	)
	_handle_negotiation_result(result)


func _handle_negotiation_result(result: Dictionary) -> void:
	if _active_negotiation == null:
		return
	var resolution := int(result.get(
		"resolution",
		SellNegotiation.Resolution.INVALID
	))
	match resolution:
		SellNegotiation.Resolution.CONTINUE:
			negotiation_updated.emit(
				_active_negotiation.card,
				_active_negotiation.last_ask,
				_active_negotiation.customer_offer,
				_active_negotiation.patience_left
			)
			if _current_customer.reveals_price:
				var key := (
					"last_offer"
					if bool(result.get("last_chance", false))
					else "counter_offer"
				)
				say(_trade_line(
					key,
					{"price": _active_negotiation.customer_offer}
				))
			else:
				say(_trade_line(
					"last_hidden"
					if bool(result.get("last_chance", false))
					else "counter_hidden"
				))
		SellNegotiation.Resolution.ACCEPTED:
			_complete_sale(int(result.get("deal_price", 0)))
		SellNegotiation.Resolution.REJECTED:
			_finish_unsold_trade()
		_:
			say(_trade_line("trade_error"))


func _complete_sale(price: int) -> void:
	if (
		_active_negotiation == null
		or _current_customer == null
		or price <= 0
		or price > _current_customer.money
		or _shop_money_counter == null
	):
		_finish_unsold_trade()
		return

	var sold_card := _active_negotiation.card
	_current_customer.money -= price
	_current_customer.add_card_to_hand(sold_card)
	_shop_money_counter.add_money(price)
	say(_trade_line("accepted", {"price": price}))
	negotiation_finished.emit(sold_card, true, price)
	_log_trade("%s sold for $%d" % [sold_card.name, price])
	_active_negotiation = null
	_wait_for_customer_departure()


func _finish_unsold_trade() -> void:
	if _active_negotiation == null:
		return
	var unsold_card := _active_negotiation.card
	if _active_negotiation.card_presented:
		_return_card_to_player(unsold_card)
	say(_trade_line("rejected"))
	negotiation_finished.emit(unsold_card, false, 0)
	_log_trade("%s was not sold" % unsold_card.name)
	_active_negotiation = null
	_wait_for_customer_departure()


func _wait_for_customer_departure() -> void:
	_waiting_to_depart = true
	clear_draggable_hover()
	if _result_timer != null:
		_result_timer.start(result_display_duration)
	else:
		call_deferred("_on_result_timer_timeout")


func _abort_active_negotiation() -> void:
	if _active_negotiation == null:
		return
	if _active_negotiation.card_presented:
		_return_card_to_player(_active_negotiation.card)
	_active_negotiation = null


func _return_card_to_player(card: Card) -> void:
	if card == null or not is_instance_valid(_card_return_surface):
		return
	var card_instance := DRAGGABLE_CARD_SCENE.instantiate() as DraggableCard
	card_instance.z_index = _get_next_return_z_index()
	_card_return_surface.add_child(card_instance)
	card_instance.display_card(card)
	var cascade := _count_loose_cards() % 6
	card_instance.global_position = (
		_card_return_surface.get_global_rect().position
		+ Vector2(35.0 + cascade * 24.0, 45.0 + cascade * 18.0)
	)
	var draggable := card_instance.get_node_or_null("UIDraggable") as UIDraggable
	if draggable != null:
		draggable.synchronize_position()


func _count_loose_cards() -> int:
	var count := 0
	for child in _card_return_surface.get_children():
		if child is DraggableCard:
			count += 1
	return count


func _get_next_return_z_index() -> int:
	var highest := 0
	for child in _card_return_surface.get_children():
		if child is Control:
			highest = maxi(highest, (child as Control).z_index)
	return highest + 1


func _notify_item_given(description: String) -> void:
	item_given.emit(description)


func _process_pending_item_transfers(delta: float) -> void:
	if _pending_item_transfers.is_empty() or not is_instance_valid(_portrait):
		return
	var delivery_y := _portrait.get_global_rect().end.y
	for index in range(_pending_item_transfers.size() - 1, -1, -1):
		var transfer := _pending_item_transfers[index]
		var target := transfer.get("target") as Control
		if not is_instance_valid(target):
			_pending_item_transfers.remove_at(index)
			continue

		var fall_speed := minf(
			float(transfer.get("fall_speed", 0.0))
				+ handoff_fall_acceleration * delta,
			handoff_maximum_fall_speed
		)
		target.global_position += Vector2.DOWN * fall_speed * delta
		transfer["fall_speed"] = fall_speed
		_pending_item_transfers[index] = transfer
		if target.global_position.y >= delivery_y:
			_finish_item_transfer(index, target, str(transfer["description"]))


func _finish_item_transfer(
	index: int,
	target: Control,
	description: String
) -> void:
	_pending_item_transfers.remove_at(index)
	_notify_item_given(description)
	_handle_delivered_item(target)
	target.queue_free()


func _load_trade_text() -> void:
	var loaded_text = ContentLoader.load_json(GamePaths.DATA_TRADING_TEXT)
	if loaded_text is Dictionary:
		_trade_text = loaded_text
	else:
		push_error("Trading text could not be loaded.")
		_trade_text = {}


func _trade_line(key: String, values: Dictionary = {}) -> String:
	return str(_trade_text.get(key, key)).format(values)


func _spawn_next_random_customer() -> void:
	if _customer_present or _transitioning:
		return
	spawn_new_customer(_create_random_customer())


func _create_random_customer() -> CustomerData:
	var all_cards := Globals.get_cards()
	var requested: Card
	if not all_cards.is_empty() and _rng.randf() < requested_card_chance:
		requested = all_cards[_rng.randi_range(0, all_cards.size() - 1)]

	var price_reference := 200
	if requested != null:
		price_reference = requested.base_price
	elif not all_cards.is_empty():
		price_reference = all_cards[
			_rng.randi_range(0, all_cards.size() - 1)
		].base_price

	var portrait_number := _pick_available_portrait()
	var patience := _rng.randi_range(
		mini(minimum_patience, maximum_patience),
		maxi(minimum_patience, maximum_patience)
	)
	var acceptability := _rng.randf_range(
		minf(minimum_acceptability, maximum_acceptability),
		maxf(minimum_acceptability, maximum_acceptability)
	)
	var customer_money := maxi(
		100,
		int(round(price_reference * _rng.randf_range(1.15, 1.8)))
	)
	var reveal_price := (
		true
		if requested == null
		else _rng.randf() < reveal_price_chance
	)
	var empty_hand: Array[Card] = []
	return CustomerData.new(
		portrait_number,
		patience,
		customer_money,
		0,
		empty_hand,
		acceptability,
		requested,
		reveal_price
	)


func _pick_available_portrait() -> int:
	var valid_portraits: Array[int] = []
	for portrait_number in available_portrait_numbers:
		if ResourceLoader.exists(PORTRAIT_PATH_TEMPLATE % portrait_number):
			valid_portraits.append(portrait_number)
	if valid_portraits.is_empty():
		return 1
	return valid_portraits[_rng.randi_range(0, valid_portraits.size() - 1)]


func _announce_customer_request() -> void:
	if _current_customer == null:
		return
	if _current_customer.requested_card == null:
		say(_trade_line("any_card"))
		return
	if _current_customer.reveals_price and _active_negotiation != null:
		say(_trade_line(
			"request_card_price",
			{
				"card": _current_customer.requested_card.name,
				"price": _active_negotiation.customer_offer,
			}
		))
	else:
		say(_trade_line(
			"request_card",
			{"card": _current_customer.requested_card.name}
		))


func _apply_portrait_texture(portrait_number: int) -> bool:
	if _portrait == null:
		return false
	var portrait_resource_path := PORTRAIT_PATH_TEMPLATE % portrait_number
	if not ResourceLoader.exists(portrait_resource_path):
		return false
	var portrait_texture := load(portrait_resource_path) as Texture2D
	if portrait_texture == null:
		return false
	_portrait.texture = portrait_texture
	return true


func _on_result_timer_timeout() -> void:
	if _customer_present and not _transitioning:
		end_customer_dialogue()


func _hide_replica() -> void:
	if _speech_timer != null:
		_speech_timer.stop()
	if _speech_bubble != null:
		_speech_bubble.visible = false


func _finish_customer_exit(departing_customer: CustomerData) -> void:
	_transition_tween = null
	_transitioning = false
	_customer_present = false
	_current_customer = null
	_active_negotiation = null
	if _portrait != null:
		_portrait.visible = false
	visible = false
	customer_dialogue_ended.emit(departing_customer)
	if _next_customer_timer != null:
		_next_customer_timer.start(next_customer_delay)
	else:
		call_deferred("_spawn_next_random_customer")


func _finish_customer_spawn(customer: CustomerData) -> void:
	_transition_tween = null
	_transitioning = false
	_customer_present = true
	customer_spawned.emit(customer)
	_announce_customer_request()


func _log_given_item(description: String) -> void:
	var console_message := CONSOLE_MESSAGE_PREFIX + description
	print(console_message)
	get_tree().call_group(DEV_CONSOLE_GROUP, "write_external_line", console_message)


func _log_trade(message: String) -> void:
	var console_message := TRADE_MESSAGE_PREFIX + message
	print(console_message)
	get_tree().call_group(DEV_CONSOLE_GROUP, "write_external_line", console_message)


func _set_transfer_cursor(enabled: bool) -> void:
	if _shows_transfer_cursor == enabled:
		return
	_shows_transfer_cursor = enabled
	Input.set_default_cursor_shape(
		Input.CURSOR_CAN_DROP if enabled else Input.CURSOR_ARROW
	)
