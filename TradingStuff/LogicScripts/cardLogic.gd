# card.gd
class_name Card


var name: String
var base_price: int

func _init(name: String, base_price: int):
	self.name = name
	self.base_price = base_price

func get_price() -> int:
	# Пока просто возвращает базовую цену
	return base_price
