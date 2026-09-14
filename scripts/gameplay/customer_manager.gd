class_name CustomerManager
extends Node


signal item_given(description: String)
signal replica_spoken(text: String)
signal customer_arrival_started(customer: CustomerData)
signal customer_departure_started(customer: CustomerData)
signal customer_dialogue_ended(customer: CustomerData)
signal customer_spawned(customer: CustomerData)
signal negotiation_started(card: Card)
signal negotiation_updated(card: Card, player_ask: int, customer_offer: int, patience_left: int)
signal negotiation_finished(card: Card, sold: bool, price: int)
signal dialogue_requested(key: String, values: Dictionary, duration: float)
signal raw_replica_requested(text: String, duration: float)
signal card_return_requested(card: Card)

const DEV_CONSOLE_GROUP := &"dev_console"
const CUSTOMER_MANAGER_GROUP := &"customer_manager"
const CONSOLE_MESSAGE_PREFIX := "Customer received: "
const TRADE_MESSAGE_PREFIX := "Trade: "

@export var shop_money_counter_path: NodePath
@export var next_customer_timer_path: NodePath
@export var result_timer_path: NodePath
@export var available_portrait_numbers: Array[int] = [1, 2]
@export_range(0.0, 1.0, 0.05) var requested_card_chance := 0.7
@export_range(0.0, 1.0, 0.05) var reveal_price_chance := 0.55
@export_range(1, 20, 1) var minimum_patience := 2
@export_range(1, 20, 1) var maximum_patience := 5
@export_range(-0.5, 0.5, 0.05) var minimum_acceptability := -0.2
@export_range(-0.5, 0.5, 0.05) var maximum_acceptability := 0.35
@export_range(0.0, 10.0, 0.1, "or_greater") var next_customer_delay := 0.8
@export_range(0.1, 10.0, 0.1, "or_greater") var result_display_duration := 1.2

var _shop_money_counter: ShopMoneyCounter
var _next_customer_timer: Timer
var _result_timer: Timer
var _current_customer: CustomerData
var _active_negotiation: SellNegotiation
var _rng := RandomNumberGenerator.new()
var _customer_present := false
var _transitioning := false
var _waiting_to_depart := false
var _delivery_in_progress := false


func _ready() -> void:
	add_to_group(CUSTOMER_MANAGER_GROUP)
	item_given.connect(_log_given_item)
	_rng.randomize()
	_resolve_dependencies()
	_connect_timers()
	_prepare_empty_counter()
	call_deferred("_spawn_next_random_customer")


func get_current_customer() -> CustomerData:
	return _current_customer


func get_active_negotiation() -> SellNegotiation:
	return _active_negotiation


func has_customer() -> bool:
	return _customer_present


func is_transitioning() -> bool:
	return _transitioning


func can_accept_delivery() -> bool:
	return _customer_present and not _transitioning and not _waiting_to_depart and not _delivery_in_progress


func begin_item_delivery() -> bool:
	if not can_accept_delivery():
		return false
	_delivery_in_progress = true
	return true


func cancel_item_delivery() -> void:
	_delivery_in_progress = false


func give_card(card: Card) -> bool:
	if not _can_process_delivered_item() or card == null:
		cancel_item_delivery()
		return false
	item_given.emit(_describe_card(card))
	_receive_card(card)
	cancel_item_delivery()
	return true


func submit_ask(receipt_type: StringName, amount: int) -> bool:
	if not _can_process_delivered_item():
		cancel_item_delivery()
		return false
	item_given.emit("%s receipt for $%d" % [str(receipt_type), amount])
	_receive_ask(receipt_type, amount)
	cancel_item_delivery()
	return true


func say(text: String, duration: float = -1.0) -> bool:
	var replica := text.strip_edges()
	if replica.is_empty() or not _customer_present or _transitioning:
		return false
	raw_replica_requested.emit(replica, duration)
	replica_spoken.emit(replica)
	return true


func spawn_new_customer(customer: CustomerData) -> bool:
	if customer == null or _current_customer != null or _transitioning:
		return false
	if _next_customer_timer != null:
		_next_customer_timer.stop()
	_current_customer = customer
	_active_negotiation = SellNegotiation.new(customer.requested_card, customer) if customer.requested_card != null else null
	_transitioning = true
	_waiting_to_depart = false
	_delivery_in_progress = false
	customer_arrival_started.emit(customer)
	return true


func complete_customer_arrival(customer: CustomerData) -> void:
	if customer != _current_customer or not _transitioning or _customer_present:
		return
	_transitioning = false
	_customer_present = true
	customer_spawned.emit(customer)
	_announce_customer_request()


func end_customer_dialogue() -> bool:
	if not _customer_present or _transitioning or _delivery_in_progress:
		return false
	_abort_active_negotiation()
	_waiting_to_depart = false
	if _result_timer != null:
		_result_timer.stop()
	_transitioning = true
	customer_departure_started.emit(_current_customer)
	return true


func complete_customer_departure(customer: CustomerData) -> void:
	if customer != _current_customer or not _transitioning:
		return
	_transitioning = false
	_customer_present = false
	_current_customer = null
	_active_negotiation = null
	_delivery_in_progress = false
	customer_dialogue_ended.emit(customer)
	if _next_customer_timer != null:
		_next_customer_timer.start(next_customer_delay)
	else:
		call_deferred("_spawn_next_random_customer")


func _resolve_dependencies() -> void:
	_shop_money_counter = get_node_or_null(shop_money_counter_path) as ShopMoneyCounter
	_next_customer_timer = get_node_or_null(next_customer_timer_path) as Timer
	_result_timer = get_node_or_null(result_timer_path) as Timer
	if _shop_money_counter == null:
		push_error("CustomerManager requires shop_money_counter_path.")


func _connect_timers() -> void:
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
	_delivery_in_progress = false


func _can_process_delivered_item() -> bool:
	return _current_customer != null and _customer_present and not _transitioning and not _waiting_to_depart


func _receive_card(card: Card) -> void:
	if _active_negotiation != null:
		if _active_negotiation.card.id != card.id or _active_negotiation.card_presented:
			_request_dialogue("wrong_card", {"card": card.name})
			card_return_requested.emit(card)
			return
	else:
		_active_negotiation = SellNegotiation.new(card, _current_customer)

	_active_negotiation.present_card()
	negotiation_started.emit(card)
	if _current_customer.requested_card == null or _current_customer.reveals_price:
		_request_dialogue("opening_offer", {"price": _active_negotiation.customer_offer})
	else:
		_request_dialogue("request_card", {"card": card.name})


func _receive_ask(receipt_type: StringName, amount: int) -> void:
	if _active_negotiation == null or not _active_negotiation.card_presented:
		_request_dialogue("card_first")
		return
	if receipt_type != &"ASK" and receipt_type != &"OFFER":
		_request_dialogue("ask_only")
		return
	var result := _active_negotiation.submit_ask(amount, receipt_type == &"OFFER")
	_handle_negotiation_result(result)


func _handle_negotiation_result(result: Dictionary) -> void:
	if _active_negotiation == null:
		return
	var resolution := int(result.get("resolution", SellNegotiation.Resolution.INVALID))
	match resolution:
		SellNegotiation.Resolution.CONTINUE:
			negotiation_updated.emit(
				_active_negotiation.card,
				_active_negotiation.last_ask,
				_active_negotiation.customer_offer,
				_active_negotiation.patience_left
			)
			if _current_customer.reveals_price:
				var key := "last_offer" if bool(result.get("last_chance", false)) else "counter_offer"
				_request_dialogue(key, {"price": _active_negotiation.customer_offer})
			else:
				_request_dialogue("last_hidden" if bool(result.get("last_chance", false)) else "counter_hidden")
		SellNegotiation.Resolution.ACCEPTED:
			_complete_sale(int(result.get("deal_price", 0)))
		SellNegotiation.Resolution.REJECTED:
			_finish_unsold_trade()
		_:
			_request_dialogue("trade_error")


func _complete_sale(price: int) -> void:
	if _active_negotiation == null or _current_customer == null or _shop_money_counter == null:
		_finish_unsold_trade()
		return
	var sold_card := _active_negotiation.card
	if not _current_customer.buy_card(sold_card, price):
		_finish_unsold_trade()
		return
	_shop_money_counter.add_money(price)
	_request_dialogue("accepted", {"price": price})
	negotiation_finished.emit(sold_card, true, price)
	_log_trade("%s sold for $%d" % [sold_card.name, price])
	_active_negotiation = null
	_wait_for_customer_departure()


func _finish_unsold_trade() -> void:
	if _active_negotiation == null:
		return
	var unsold_card := _active_negotiation.card
	if _active_negotiation.card_presented:
		card_return_requested.emit(unsold_card)
	_request_dialogue("rejected")
	negotiation_finished.emit(unsold_card, false, 0)
	_log_trade("%s was not sold" % unsold_card.name)
	_active_negotiation = null
	_wait_for_customer_departure()


func _wait_for_customer_departure() -> void:
	_waiting_to_depart = true
	if _result_timer != null:
		_result_timer.start(result_display_duration)
	else:
		call_deferred("_on_result_timer_timeout")


func _abort_active_negotiation() -> void:
	if _active_negotiation == null:
		return
	if _active_negotiation.card_presented:
		card_return_requested.emit(_active_negotiation.card)
	_active_negotiation = null


func _request_dialogue(key: String, values: Dictionary = {}, duration: float = -1.0) -> void:
	dialogue_requested.emit(key, values, duration)


func _spawn_next_random_customer() -> void:
	if _current_customer != null or _transitioning:
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
		price_reference = all_cards[_rng.randi_range(0, all_cards.size() - 1)].base_price

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
	var reveal_price := true if requested == null else _rng.randf() < reveal_price_chance
	var empty_hand: Array[Card] = []
	return CustomerData.new(
		_pick_available_portrait(),
		patience,
		customer_money,
		0,
		empty_hand,
		acceptability,
		requested,
		reveal_price
	)


func _pick_available_portrait() -> int:
	if available_portrait_numbers.is_empty():
		return 1
	return available_portrait_numbers[
		_rng.randi_range(0, available_portrait_numbers.size() - 1)
	]


func _announce_customer_request() -> void:
	if _current_customer == null:
		return
	if _current_customer.requested_card == null:
		_request_dialogue("any_card")
		return
	if _current_customer.reveals_price and _active_negotiation != null:
		_request_dialogue("request_card_price", {
			"card": _current_customer.requested_card.name,
			"price": _active_negotiation.customer_offer,
		})
	else:
		_request_dialogue("request_card", {"card": _current_customer.requested_card.name})


func _on_result_timer_timeout() -> void:
	if _customer_present and not _transitioning:
		end_customer_dialogue()


func _describe_card(card: Card) -> String:
	return "card #%d \"%s\" (%s, %s)" % [
		card.id,
		card.name,
		card.series,
		card.get_literal_name(),
	]


func _log_given_item(description: String) -> void:
	var console_message := CONSOLE_MESSAGE_PREFIX + description
	print(console_message)
	get_tree().call_group(DEV_CONSOLE_GROUP, "write_external_line", console_message)


func _log_trade(message: String) -> void:
	var console_message := TRADE_MESSAGE_PREFIX + message
	print(console_message)
	get_tree().call_group(DEV_CONSOLE_GROUP, "write_external_line", console_message)
