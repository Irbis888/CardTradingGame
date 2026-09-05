class_name CustomerData
extends RefCounted


var portrait_number: int
var patience_turns: int
var money: int
var card_count: int


func _init(
	portrait: int = 6,
	patience: int = 5,
	carried_money: int = 250,
	cards: int = 3
) -> void:
	portrait_number = maxi(portrait, 0)
	patience_turns = maxi(patience, 0)
	money = maxi(carried_money, 0)
	card_count = maxi(cards, 0)


func get_description() -> String:
	return "portrait #%d, patience %d turns, $%d, %d cards" % [
		portrait_number,
		patience_turns,
		money,
		card_count,
	]
