extends Node2D

var TraderList : Array[Trader] = []
var traderScene = load("res://TradingStuff/traderButton.tscn")
@onready var container = $ScrollContainer/GridContainer

func generate_traders():
	for i in range(4):
		var pn = randi_range(2, 6)
		var portrait = load("res://TradingStuff/Style/Portraits/M" + str(pn) + ".png")
		var gangName = Globals.nameList.pick_random()
		var coll = []

		var rand_rank = randi_range(Globals.CardRanks.SIX, Globals.CardRanks.ACE)
		var rand_suit = Globals.CardSuits[randi_range(0, 3)]
		for j in range(randi_range(20, 60)):
			coll.append(Globals.cardList.pick_random())
		TraderList.append(Trader.new(gangName, randi_range(10, 100)+100, coll, portrait, rand_rank, rand_suit))
		
func _ready() -> void:
	generate_traders()
	var ts
	for i in TraderList:
		ts = traderScene.instantiate()
		container.add_child(ts)
		ts.init(i)

func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
