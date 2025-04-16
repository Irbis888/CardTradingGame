# card.gd
class_name Card


var name: String
var base_price: int
var rarity: int

var str: int
var def: int
var mag: int

var series: String
var picture: Resource

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

func _init(name: String, base_price: int):
	self.name = name
	self.base_price = base_price

func get_price(coeffVector: Vector3i) -> int:
	# Пока просто возвращает базовую цену
	var sum = int(Vector3(coeffVector).dot(Vector3(str, def, mag)))
	sum += (rarity+1) * randf_range(0.5, 1.5) * 20
	sum *= randf_range(0.8, 1.2)
	return sum
