extends Node2D

var TraderList : Array[Trader] = []
var traderScene = load("res://TradingStuff/traderButton.tscn")
@onready var container = $GridContainer

func generate_traders():
	for i in range(3):
		var pn = randi_range(2, 6)
		var portrait = load("res://TradingStuff/Style/Portraits/M" + str(pn) + ".png")
		var gangName = Globals.nameList.pick_random()
		var coll = []
		for j in range(randi_range(2, 6)):
			coll.append(Globals.cardList.pick_random())
		TraderList.append(Trader.new(gangName, randi_range(10, 100)+100, coll, portrait))
		
func _ready() -> void:
	generate_traders()
	var ts
	for i in TraderList:
		ts = traderScene.instantiate()
		container.add_child(ts)
		ts.init(i)
		
	
	
	
