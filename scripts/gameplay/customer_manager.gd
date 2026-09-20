class_name CustomerManager
extends Node


signal item_given(description: String)
signal replica_spoken(text: String)
signal customer_arrival_started(customer: CustomerVisit)
signal customer_departure_started(customer: CustomerVisit)
signal customer_dialogue_ended(customer: CustomerVisit)
signal customer_spawned(customer: CustomerVisit)
signal negotiation_started(card: Card)
signal negotiation_updated(card: Card, player_ask: int, customer_offer: int, patience_left: int)
signal negotiation_finished(card: Card, sold: bool, price: int)
signal dialogue_requested(key: String, values: Dictionary, duration: float)
signal raw_replica_requested(text: String, duration: float)
signal card_return_requested(card: Card)
signal activity_logged(message: String)

const CUSTOMER_MANAGER_GROUP := &"customer_manager"
const CONSOLE_MESSAGE_PREFIX := "Customer received: "
const TRADE_MESSAGE_PREFIX := "Trade: "

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

var _next_customer_timer: Timer
var _result_timer: Timer
var _current_customer: CustomerVisit
var _customer_generator := CustomerGenerator.new()
var _trade_controller := CustomerTradeController.new()
var _customer_present := false
var _transitioning := false
var _waiting_to_depart := false
var _delivery_in_progress := false


func _ready() -> void:
	add_to_group(CUSTOMER_MANAGER_GROUP)
	_configure_customer_generator()
	_resolve_dependencies()
	_connect_timers()
	_connect_trade_controller()
	_prepare_empty_counter()
	call_deferred("_spawn_next_random_customer")


func get_current_customer() -> CustomerVisit:
	return _current_customer


func get_active_negotiation() -> SellNegotiation:
	return _trade_controller.get_active_negotiation()


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
	var description := _describe_card(card)
	item_given.emit(description)
	_log_activity(CONSOLE_MESSAGE_PREFIX + description)
	_trade_controller.receive_card(card)
	cancel_item_delivery()
	return true


func submit_ask(receipt_type: StringName, amount: int) -> bool:
	if not _can_process_delivered_item():
		cancel_item_delivery()
		return false
	var description := "%s receipt for $%d" % [str(receipt_type), amount]
	item_given.emit(description)
	_log_activity(CONSOLE_MESSAGE_PREFIX + description)
	_trade_controller.receive_ask(receipt_type, amount)
	cancel_item_delivery()
	return true


func say(text: String, duration: float = -1.0) -> bool:
	var replica := text.strip_edges()
	if replica.is_empty() or not _customer_present or _transitioning:
		return false
	raw_replica_requested.emit(replica, duration)
	replica_spoken.emit(replica)
	return true


func spawn_new_customer(customer: CustomerVisit) -> bool:
	if customer == null or _current_customer != null or _transitioning:
		return false
	if _next_customer_timer != null:
		_next_customer_timer.stop()
	_current_customer = customer
	_trade_controller.begin_visit(customer)
	_transitioning = true
	_waiting_to_depart = false
	_delivery_in_progress = false
	customer_arrival_started.emit(customer)
	return true


func complete_customer_arrival(customer: CustomerVisit) -> void:
	if customer != _current_customer or not _transitioning or _customer_present:
		return
	_transitioning = false
	_customer_present = true
	customer_spawned.emit(customer)
	_trade_controller.announce_customer_request()


func end_customer_dialogue() -> bool:
	if not _customer_present or _transitioning or _delivery_in_progress:
		return false
	_trade_controller.abort_trade()
	_waiting_to_depart = false
	if _result_timer != null:
		_result_timer.stop()
	_transitioning = true
	customer_departure_started.emit(_current_customer)
	return true


func complete_customer_departure(customer: CustomerVisit) -> void:
	if customer != _current_customer or not _transitioning:
		return
	_transitioning = false
	_customer_present = false
	_current_customer = null
	_trade_controller.end_visit()
	_delivery_in_progress = false
	customer_dialogue_ended.emit(customer)
	if _next_customer_timer != null:
		_next_customer_timer.start(next_customer_delay)
	else:
		call_deferred("_spawn_next_random_customer")


func _resolve_dependencies() -> void:
	_next_customer_timer = get_node_or_null(next_customer_timer_path) as Timer
	_result_timer = get_node_or_null(result_timer_path) as Timer


func _connect_timers() -> void:
	if _next_customer_timer != null:
		_next_customer_timer.timeout.connect(_spawn_next_random_customer)
	if _result_timer != null:
		_result_timer.timeout.connect(_on_result_timer_timeout)


func _connect_trade_controller() -> void:
	_trade_controller.negotiation_started.connect(negotiation_started.emit)
	_trade_controller.negotiation_updated.connect(negotiation_updated.emit)
	_trade_controller.negotiation_finished.connect(negotiation_finished.emit)
	_trade_controller.dialogue_requested.connect(dialogue_requested.emit)
	_trade_controller.card_return_requested.connect(card_return_requested.emit)
	_trade_controller.trade_logged.connect(_log_trade)
	_trade_controller.trade_resolved.connect(_wait_for_customer_departure)


func _configure_customer_generator() -> void:
	_customer_generator.available_portrait_numbers = available_portrait_numbers.duplicate()
	_customer_generator.requested_card_chance = requested_card_chance
	_customer_generator.reveal_price_chance = reveal_price_chance
	_customer_generator.minimum_patience = minimum_patience
	_customer_generator.maximum_patience = maximum_patience
	_customer_generator.minimum_acceptability = minimum_acceptability
	_customer_generator.maximum_acceptability = maximum_acceptability


func _prepare_empty_counter() -> void:
	_current_customer = null
	_customer_present = false
	_transitioning = false
	_waiting_to_depart = false
	_delivery_in_progress = false


func _can_process_delivered_item() -> bool:
	return _current_customer != null and _customer_present and not _transitioning and not _waiting_to_depart


func _wait_for_customer_departure() -> void:
	_waiting_to_depart = true
	if _result_timer != null:
		_result_timer.start(result_display_duration)
	else:
		call_deferred("_on_result_timer_timeout")


func _spawn_next_random_customer() -> void:
	if _current_customer != null or _transitioning:
		return
	spawn_new_customer(_customer_generator.create_visit(CardDatabase.get_cards()))


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


func _log_trade(message: String) -> void:
	_log_activity(TRADE_MESSAGE_PREFIX + message)


func _log_activity(message: String) -> void:
	print(message)
	activity_logged.emit(message)
