class_name Card
extends RefCounted


var name: String
var rarity: int

var series: String
var picture: Texture2D
var id: int
var description: String
var trivia: Dictionary = {}
var _prices: CardPrices


func _init(
	card_name: String,
	card_picture: Texture2D,
	card_series: String,
	card_rarity: int,
	card_id: int,
	card_prices: CardPrices,
	card_description: String = "",
	card_trivia: Dictionary = {}
) -> void:
	name = card_name
	picture = card_picture
	series = card_series
	rarity = card_rarity
	id = card_id
	description = card_description
	trivia = card_trivia.duplicate(true)
	_prices = card_prices


func get_literal_name() -> String:
	match rarity:
		0:
			return "C"
		1:
			return "U"
		2:
			return "R"
		3:
			return "SR"
		4:
			return "SP"
		5:
			return "SSP"
		_:
			return "NO"


func get_price() -> int:
	return _prices.get_price(id)
