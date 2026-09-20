class_name CustomerTradeController
extends RefCounted


signal negotiation_started(card: Card)
signal negotiation_updated(card: Card, player_ask: int, customer_offer: int, patience_left: int)
signal negotiation_finished(card: Card, sold: bool, price: int)
signal dialogue_requested(key: String, values: Dictionary, duration: float)
signal card_return_requested(card: Card)
signal trade_logged(message: String)
signal trade_resolved

var _customer: CustomerVisit
var _negotiation: SellNegotiation


func begin_visit(customer: CustomerVisit) -> void:
	_customer = customer
	_negotiation = (
		SellNegotiation.new(customer.requested_card, customer)
		if customer != null and customer.requested_card != null
		else null
	)


func end_visit() -> void:
	abort_trade()
	_customer = null


func get_active_negotiation() -> SellNegotiation:
	return _negotiation


func receive_card(card: Card) -> void:
	if _customer == null or card == null:
		return
	if _negotiation != null:
		if _negotiation.card.id != card.id or _negotiation.card_presented:
			_request_dialogue("wrong_card", {"card": card.name})
			card_return_requested.emit(card)
			return
	else:
		_negotiation = SellNegotiation.new(card, _customer)

	_negotiation.present_card()
	negotiation_started.emit(card)
	if _customer.requested_card == null or _customer.reveals_price:
		_request_dialogue("opening_offer", {"price": _negotiation.customer_offer})
	else:
		_request_dialogue("request_card", {"card": card.name})


func receive_ask(receipt_type: StringName, amount: int) -> void:
	if _negotiation == null or not _negotiation.card_presented:
		_request_dialogue("card_first")
		return
	if receipt_type != &"ASK" and receipt_type != &"OFFER":
		_request_dialogue("ask_only")
		return
	_handle_negotiation_result(
		_negotiation.submit_ask(amount, receipt_type == &"OFFER")
	)


func announce_customer_request() -> void:
	if _customer == null:
		return
	if _customer.requested_card == null:
		_request_dialogue("any_card")
		return
	if _customer.reveals_price and _negotiation != null:
		_request_dialogue("request_card_price", {
			"card": _customer.requested_card.name,
			"price": _negotiation.customer_offer,
		})
	else:
		_request_dialogue("request_card", {"card": _customer.requested_card.name})


func abort_trade() -> void:
	if _negotiation == null:
		return
	if _negotiation.card_presented:
		card_return_requested.emit(_negotiation.card)
	_negotiation = null


func _handle_negotiation_result(result: Dictionary) -> void:
	if _negotiation == null:
		return
	var resolution := int(result.get("resolution", SellNegotiation.Resolution.INVALID))
	match resolution:
		SellNegotiation.Resolution.CONTINUE:
			_continue_negotiation(result)
		SellNegotiation.Resolution.ACCEPTED:
			_complete_sale(int(result.get("deal_price", 0)))
		SellNegotiation.Resolution.REJECTED:
			_finish_unsold_trade()
		_:
			_request_dialogue("trade_error")


func _continue_negotiation(result: Dictionary) -> void:
	negotiation_updated.emit(
		_negotiation.card,
		_negotiation.last_ask,
		_negotiation.customer_offer,
		_negotiation.patience_left
	)
	if _customer.reveals_price:
		var key := "last_offer" if bool(result.get("last_chance", false)) else "counter_offer"
		_request_dialogue(key, {"price": _negotiation.customer_offer})
	else:
		var key := "last_hidden" if bool(result.get("last_chance", false)) else "counter_hidden"
		_request_dialogue(key)


func _complete_sale(price: int) -> void:
	if _negotiation == null or _customer == null:
		_finish_unsold_trade()
		return
	var sold_card := _negotiation.card
	if not _customer.buy_card(sold_card, price):
		_finish_unsold_trade()
		return
	GameState.add_money(price)
	_request_dialogue("accepted", {"price": price})
	negotiation_finished.emit(sold_card, true, price)
	trade_logged.emit("%s sold for $%d" % [sold_card.name, price])
	_negotiation = null
	trade_resolved.emit()


func _finish_unsold_trade() -> void:
	if _negotiation == null:
		return
	var unsold_card := _negotiation.card
	if _negotiation.card_presented:
		card_return_requested.emit(unsold_card)
	_request_dialogue("rejected")
	negotiation_finished.emit(unsold_card, false, 0)
	trade_logged.emit("%s was not sold" % unsold_card.name)
	_negotiation = null
	trade_resolved.emit()


func _request_dialogue(key: String, values: Dictionary = {}, duration: float = -1.0) -> void:
	dialogue_requested.emit(key, values, duration)
