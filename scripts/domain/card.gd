class_name Card
extends RefCounted


var name: String
var base_price: int
var rarity: int

var str: int
var def: int
var mag: int

var series: String
var picture: Resource
var id: int


func _init(
	card_name: String,
	card_picture: Resource,
	attack: int,
	defense: int,
	magic: int,
	card_series: String,
	card_rarity: int,
	card_id: int,
	catalog_price: int = -1
) -> void:
	name = card_name
	picture = card_picture
	str = attack
	def = defense
	mag = magic
	series = card_series
	rarity = card_rarity
	id = card_id
	base_price = (
		catalog_price
		if catalog_price > 0
		else _calculate_catalog_price()
	)


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
	return base_price


func _calculate_catalog_price() -> int:
	var stat_total := maxi(str, 0) + maxi(def, 0) + maxi(mag, 0)
	var rarity_tier := maxi(rarity + 1, 1)
	return maxi(stat_total * 8 + rarity_tier * rarity_tier * 25, 1)
