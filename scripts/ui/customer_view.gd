class_name CustomerView
extends Control


signal replica_spoken(text: String)

const PORTRAIT_PATH_TEMPLATE := "res://assets/portraits_new/Customer_00%d.png"
const DRAGGABLE_CARD_SCENE := preload("res://scenes/ui/draggable_card.tscn")

@export var customer_manager_path: NodePath = NodePath("..")
@export var drag_surface_path: NodePath
@export var card_return_surface_path: NodePath
@export var drop_region_path: NodePath = NodePath(".")
@export var portrait_path: NodePath
@export var handoff_layer_path: NodePath
@export var speech_bubble_path: NodePath
@export var speech_label_path: NodePath
@export var speech_timer_path: NodePath
@export_range(0.1, 60.0, 0.1, "or_greater") var default_replica_duration := 4.0
@export_range(0.05, 5.0, 0.05, "or_greater") var fade_duration := 0.35
@export_range(0.0, 10000.0, 50.0, "or_greater") var handoff_fall_acceleration := 2400.0
@export_range(0.0, 5000.0, 25.0, "or_greater") var handoff_initial_fall_speed := 180.0
@export_range(0.0, 10000.0, 50.0, "or_greater") var handoff_maximum_fall_speed := 1800.0

var _customer_manager: CustomerManager
var _drag_surface: Node
var _card_return_surface: Control
var _drop_region: Control
var _portrait: TextureRect
var _handoff_layer: Control
var _speech_bubble: Control
var _speech_label: Label
var _speech_timer: Timer
var _transition_tween: Tween
var _trade_text: Dictionary = {}
var _shows_transfer_cursor := false
var _pending_item_transfers: Array[Dictionary] = []


func _ready() -> void:
	_load_trade_text()
	_resolve_node_references()
	_connect_customer_manager()
	_connect_timers()
	_prepare_empty_view()
	_register_as_drop_receiver()


func _process(delta: float) -> void:
	_process_pending_item_transfers(delta)


func _exit_tree() -> void:
	clear_draggable_hover()
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	if is_instance_valid(_drag_surface) and _drag_surface.has_method("unregister_drop_receiver"):
		_drag_surface.call("unregister_drop_receiver", self)


func try_accept_draggable(draggable, global_pointer: Vector2) -> bool:
	return (
		_customer_manager != null
		and _customer_manager.can_accept_delivery()
		and _is_pointer_inside_drop_region(global_pointer)
		and not _describe_supported_item(draggable).is_empty()
	)


func take_accepted_draggable(draggable) -> bool:
	if (
		_customer_manager == null
		or not is_instance_valid(_handoff_layer)
		or not is_instance_valid(_portrait)
		or draggable == null
		or not draggable.has_method("get_target")
	):
		return false
	var target := draggable.get_target() as Control
	var transfer := _make_item_transfer(target)
	if target == null or transfer.is_empty():
		return false
	if not _customer_manager.begin_item_delivery():
		return false

	draggable.enabled = false
	draggable.set_velocity(Vector2.ZERO)
	target.reparent(_handoff_layer, true)
	target.z_index = 0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transfer["target"] = target
	transfer["fall_speed"] = handoff_initial_fall_speed
	_pending_item_transfers.append(transfer)
	return true


func update_draggable_hover(draggable, global_pointer: Vector2) -> void:
	var can_drop := (
		_customer_manager != null
		and _customer_manager.can_accept_delivery()
		and _is_pointer_inside_drop_region(global_pointer)
		and not _describe_supported_item(draggable).is_empty()
	)
	_set_transfer_cursor(can_drop)


func clear_draggable_hover() -> void:
	_set_transfer_cursor(false)


func _resolve_node_references() -> void:
	_customer_manager = get_node_or_null(customer_manager_path) as CustomerManager
	_drag_surface = get_node_or_null(drag_surface_path)
	_card_return_surface = get_node_or_null(card_return_surface_path) as Control
	_drop_region = get_node_or_null(drop_region_path) as Control
	_portrait = get_node_or_null(portrait_path) as TextureRect
	_handoff_layer = get_node_or_null(handoff_layer_path) as Control
	_speech_bubble = get_node_or_null(speech_bubble_path) as Control
	_speech_label = get_node_or_null(speech_label_path) as Label
	_speech_timer = get_node_or_null(speech_timer_path) as Timer

	if _customer_manager == null:
		push_error("CustomerView requires customer_manager_path.")
	if _drop_region == null:
		push_error("CustomerView requires drop_region_path to reference a Control.")
	if _portrait == null:
		push_error("CustomerView requires portrait_path to reference a TextureRect.")
	if _handoff_layer == null:
		push_error("CustomerView requires handoff_layer_path to reference a Control.")
	if _card_return_surface == null:
		push_error("CustomerView requires card_return_surface_path.")


func _connect_customer_manager() -> void:
	if _customer_manager == null:
		return
	_customer_manager.customer_arrival_started.connect(_on_customer_arrival_started)
	_customer_manager.customer_departure_started.connect(_on_customer_departure_started)
	_customer_manager.dialogue_requested.connect(_on_dialogue_requested)
	_customer_manager.raw_replica_requested.connect(_show_replica)
	_customer_manager.card_return_requested.connect(_return_card_to_player)


func _connect_timers() -> void:
	if _speech_timer != null:
		_speech_timer.timeout.connect(_hide_replica)


func _prepare_empty_view() -> void:
	visible = false
	modulate.a = 1.0
	if _portrait != null:
		_portrait.visible = false
		_portrait.modulate.a = 1.0
	if _speech_bubble != null:
		_speech_bubble.visible = false


func _register_as_drop_receiver() -> void:
	if not is_instance_valid(_drag_surface):
		push_error("CustomerView requires a valid drag_surface_path.")
		return
	if not _drag_surface.has_method("register_drop_receiver"):
		push_error("CustomerView drag surface does not support drop receivers.")
		return
	_drag_surface.call("register_drop_receiver", self)


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
		return "card" if (target as DraggableCard).get_card_data() != null else ""
	if target is DraggableReceipt:
		return "receipt"
	return ""


func _make_item_transfer(target: Control) -> Dictionary:
	if target is DraggableCard:
		var card := (target as DraggableCard).get_card_data()
		return {"kind": &"card", "card": card} if card != null else {}
	if target is DraggableReceipt:
		var receipt := target as DraggableReceipt
		return {
			"kind": &"receipt",
			"receipt_type": receipt.get_receipt_type(),
			"amount": receipt.get_amount(),
		}
	return {}


func _process_pending_item_transfers(delta: float) -> void:
	if _pending_item_transfers.is_empty() or not is_instance_valid(_portrait):
		return
	var delivery_y := _portrait.get_global_rect().end.y
	for index in range(_pending_item_transfers.size() - 1, -1, -1):
		var transfer := _pending_item_transfers[index]
		var target := transfer.get("target") as Control
		if not is_instance_valid(target):
			_pending_item_transfers.remove_at(index)
			if _customer_manager != null:
				_customer_manager.cancel_item_delivery()
			continue

		var fall_speed := minf(
			float(transfer.get("fall_speed", 0.0)) + handoff_fall_acceleration * delta,
			handoff_maximum_fall_speed
		)
		target.global_position += Vector2.DOWN * fall_speed * delta
		transfer["fall_speed"] = fall_speed
		_pending_item_transfers[index] = transfer
		if target.global_position.y >= delivery_y:
			_finish_item_transfer(index, transfer, target)


func _finish_item_transfer(index: int, transfer: Dictionary, target: Control) -> void:
	_pending_item_transfers.remove_at(index)
	var handled := false
	if _customer_manager != null:
		match transfer.get("kind", &"") as StringName:
			&"card":
				handled = _customer_manager.give_card(transfer.get("card") as Card)
			&"receipt":
				handled = _customer_manager.submit_ask(
					transfer.get("receipt_type", &"") as StringName,
					int(transfer.get("amount", 0))
				)
	if not handled and transfer.get("kind", &"") == &"card":
		_return_card_to_player(transfer.get("card") as Card)
	if is_instance_valid(target):
		target.queue_free()


func _on_customer_arrival_started(customer: CustomerData) -> void:
	if _portrait == null:
		_customer_manager.complete_customer_arrival(customer)
		return
	_kill_transition_tween()
	_apply_portrait_texture(customer.portrait_number)
	visible = true
	_portrait.visible = true
	modulate.a = 0.0
	_portrait.modulate.a = 0.0
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait, "modulate:a", 1.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(
		self, "modulate:a", 1.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.finished.connect(_finish_customer_arrival.bind(customer))


func _finish_customer_arrival(customer: CustomerData) -> void:
	_transition_tween = null
	if _customer_manager != null:
		_customer_manager.complete_customer_arrival(customer)


func _on_customer_departure_started(customer: CustomerData) -> void:
	clear_draggable_hover()
	_hide_replica()
	if _portrait == null:
		_finish_customer_departure(customer)
		return
	_kill_transition_tween()
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait, "modulate:a", 0.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(
		self, "modulate:a", 0.0, fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.finished.connect(_finish_customer_departure.bind(customer))


func _finish_customer_departure(customer: CustomerData) -> void:
	_transition_tween = null
	if _portrait != null:
		_portrait.visible = false
	visible = false
	if _customer_manager != null:
		_customer_manager.complete_customer_departure(customer)


func _kill_transition_tween() -> void:
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	_transition_tween = null


func _on_dialogue_requested(key: String, values: Dictionary, duration: float) -> void:
	_show_replica(_trade_line(key, values), duration)


func _show_replica(text: String, duration: float = -1.0) -> void:
	var replica := text.strip_edges()
	if replica.is_empty() or _speech_bubble == null or _speech_label == null:
		return
	_speech_label.text = replica
	_speech_bubble.visible = true
	if _speech_timer != null:
		var visible_duration := duration if duration > 0.0 else default_replica_duration
		_speech_timer.start(visible_duration)
	replica_spoken.emit(replica)


func _hide_replica() -> void:
	if _speech_timer != null:
		_speech_timer.stop()
	if _speech_bubble != null:
		_speech_bubble.visible = false


func _load_trade_text() -> void:
	var loaded_text = ContentLoader.load_json(GamePaths.DATA_TRADING_TEXT)
	if loaded_text is Dictionary:
		_trade_text = loaded_text
	else:
		push_error("Trading text could not be loaded.")
		_trade_text = {}


func _trade_line(key: String, values: Dictionary = {}) -> String:
	return str(_trade_text.get(key, key)).format(values)


func _apply_portrait_texture(portrait_number: int) -> bool:
	if _portrait == null:
		return false
	var portrait_resource_path := PORTRAIT_PATH_TEMPLATE % portrait_number
	if not ResourceLoader.exists(portrait_resource_path):
		push_warning("Customer portrait does not exist: %s" % portrait_resource_path)
		return false
	var portrait_texture := load(portrait_resource_path) as Texture2D
	if portrait_texture == null:
		return false
	_portrait.texture = portrait_texture
	return true


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


func _set_transfer_cursor(enabled: bool) -> void:
	if _shows_transfer_cursor == enabled:
		return
	_shows_transfer_cursor = enabled
	Input.set_default_cursor_shape(
		Input.CURSOR_CAN_DROP if enabled else Input.CURSOR_ARROW
	)
