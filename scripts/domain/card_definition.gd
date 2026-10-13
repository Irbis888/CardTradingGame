class_name CardDefinition
extends RefCounted


var id: int
var name: String
var picture: Texture2D
var series: String
var rarity: int
var description: String
var trivia: Dictionary
var _prices: CardPrices


func _init(card_name: String, card_picture: Texture2D, card_series: String,
		card_rarity: int, card_id: int, prices: CardPrices,
		card_description: String = "", card_trivia: Dictionary = {}) -> void:
	name = card_name
	picture = card_picture
	series = card_series
	rarity = card_rarity
	id = card_id
	description = card_description
	trivia = card_trivia.duplicate(true)
	_prices = prices


func get_price() -> int:
	return _prices.get_price(id)


func get_literal_name() -> String:
	return ["C", "U", "R", "SR", "SP", "SSP"][rarity] if rarity in range(6) else "NO"
