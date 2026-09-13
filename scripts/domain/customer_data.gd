class_name CustomerData
extends RefCounted


var portrait_number: int
var patience_turns: int
var money: int
var card_count: int
var cards_on_hands: Array[Card] = []
var requested_card: Card
var reveals_price: bool
var _acceptability := 0.0

var acceptability: float:
	get:
		return _acceptability
	set(value):
		_acceptability = clampf(value, -0.5, 0.5)


func _init(
	portrait: int = 1,
	patience: int = 5,
	carried_money: int = 250,
	cards: int = 3,
	hand_cards: Array[Card] = [],
	initial_acceptability: float = 0.0,
	requested: Card = null,
	reveal_price: bool = true
) -> void:
	portrait_number = maxi(portrait, 0)
	patience_turns = maxi(patience, 0)
	money = maxi(carried_money, 0)
	card_count = maxi(cards, 0)
	cards_on_hands.assign(hand_cards)
	acceptability = initial_acceptability
	requested_card = requested
	reveals_price = reveal_price


func add_card_to_hand(card: Card) -> void:
	if card == null:
		return
	cards_on_hands.append(card)
	card_count += 1


func get_description() -> String:
	var request_text := requested_card.name if requested_card != null else "any card"
	return "portrait #%d, patience %d turns, $%d, %d cards, %d known in hand, acceptability %.2f, wants %s" % [
		portrait_number,
		patience_turns,
		money,
		card_count,
		cards_on_hands.size(),
		acceptability,
		request_text,
	]
