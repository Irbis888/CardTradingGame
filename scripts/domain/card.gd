# card.gd
class_name Card


var name: String
var base_price: int = 10
var rarity: int

var str: int
var def: int
var mag: int

var series: String
var picture: Resource

var id: int


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

func _init(name: String, pic: Resource, str, def, mag, series, rarity, id):
	self.name = name
	self.picture = pic
	self.str = str
	self.def = def
	self.mag = mag
	self.rarity = rarity
	self.series = series
	self.id = id
	base_price = abs(self.get_price())

func get_price() -> int:
	# Пока просто возвращает базовую цену
	var coeffVector = Vector3i(1,1,1) * randi()%10
	var sum = int(Vector3(coeffVector).dot(Vector3(str, def, mag)))
	sum += (rarity+1) * randf_range(0.5, 1.5) * 20
	sum *= randf_range(0.8, 1.2)
	return sum
