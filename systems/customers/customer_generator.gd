class_name CustomerGenerator
extends RefCounted


var available_portrait_numbers: Array[int] = [1]
var requested_card_chance := 0.7
var reveal_price_chance := 0.55
var minimum_patience := 2
var maximum_patience := 5
var minimum_acceptability := -0.2
var maximum_acceptability := 0.35

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func create_visit(all_cards: Array[Card]) -> CustomerVisit:
	var requested := _pick_requested_card(all_cards)
	var price_reference := _pick_price_reference(all_cards, requested)
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
	return CustomerVisit.new(
		_pick_available_portrait(),
		patience,
		customer_money,
		0,
		empty_hand,
		acceptability,
		requested,
		reveal_price
	)


func _pick_requested_card(all_cards: Array[Card]) -> Card:
	if all_cards.is_empty() or _rng.randf() >= requested_card_chance:
		return null
	return all_cards[_rng.randi_range(0, all_cards.size() - 1)]


func _pick_price_reference(all_cards: Array[Card], requested: Card) -> int:
	if requested != null:
		return requested.base_price
	if all_cards.is_empty():
		return 200
	return all_cards[_rng.randi_range(0, all_cards.size() - 1)].base_price


func _pick_available_portrait() -> int:
	if available_portrait_numbers.is_empty():
		return 1
	return available_portrait_numbers[
		_rng.randi_range(0, available_portrait_numbers.size() - 1)
	]
