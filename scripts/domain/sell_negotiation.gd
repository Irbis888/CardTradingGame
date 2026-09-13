class_name SellNegotiation
extends RefCounted


enum Resolution {
	INVALID,
	CONTINUE,
	ACCEPTED,
	REJECTED,
}

const AUTO_ACCEPT_PROBABILITY := 0.95
const PROBABILITY_SOFTNESS := 0.08

var card: Card
var customer: CustomerData
var reference_price := 0
var reservation_price := 0
var customer_offer := 0
var patience_left := 0
var last_ask := 0
var last_probability := 0.0
var card_presented := false
var closed := false

var _concession_rate := 0.25


func _init(traded_card: Card, buyer: CustomerData) -> void:
	card = traded_card
	customer = buyer
	if card == null or customer == null:
		closed = true
		return
	reference_price = maxi(card.base_price, 1)
	reservation_price = mini(
		customer.money,
		maxi(1, int(round(reference_price * (1.0 + customer.acceptability))))
	)
	patience_left = maxi(customer.patience_turns, 1)
	_concession_rate = randf_range(0.18, 0.34)
	if reservation_price > 0:
		customer_offer = clampi(
			int(round(reservation_price * randf_range(0.62, 0.80))),
			1,
			reservation_price
		)


func present_card() -> void:
	card_presented = true


func submit_ask(ask_price: int, final_offer: bool = false) -> Dictionary:
	if closed or not card_presented or ask_price <= 0:
		return _make_result(Resolution.INVALID)

	last_ask = ask_price
	last_probability = calculate_acceptance_probability(ask_price)
	if ask_price <= customer_offer or last_probability >= AUTO_ACCEPT_PROBABILITY:
		closed = true
		return _make_result(Resolution.ACCEPTED, ask_price)

	if final_offer:
		return _resolve_probability(ask_price)

	patience_left = maxi(patience_left - 1, 0)
	if patience_left <= 0:
		return _resolve_probability(ask_price)

	_raise_customer_offer_toward(ask_price)
	return _make_result(Resolution.CONTINUE)


func calculate_acceptance_probability(ask_price: int) -> float:
	if reservation_price <= 0 or ask_price <= 0 or ask_price > customer.money:
		return 0.0
	var price_ratio := float(ask_price) / float(reservation_price)
	var exponent := clampf(
		(price_ratio - 1.0) / PROBABILITY_SOFTNESS,
		-60.0,
		60.0
	)
	return clampf(1.0 / (1.0 + exp(exponent)), 0.0, 1.0)


func _raise_customer_offer_toward(ask_price: int) -> void:
	var concession_target := mini(ask_price, reservation_price)
	if concession_target <= customer_offer:
		return
	var concession := maxi(
		1,
		int(round((concession_target - customer_offer) * _concession_rate))
	)
	customer_offer = mini(customer_offer + concession, reservation_price)


func _resolve_probability(ask_price: int) -> Dictionary:
	closed = true
	if randf() <= last_probability:
		return _make_result(Resolution.ACCEPTED, ask_price)
	return _make_result(Resolution.REJECTED)


func _make_result(resolution: int, deal_price: int = 0) -> Dictionary:
	return {
		"resolution": resolution,
		"deal_price": deal_price,
		"customer_offer": customer_offer,
		"patience_left": patience_left,
		"probability": last_probability,
		"last_chance": patience_left == 1,
	}
