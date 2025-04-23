extends Node2D

var TraderList : Array[Trader] = []
var traderScene = load("res://TradingStuff/traderButton.tscn")
@onready var container = $ScrollContainer/GridContainer



func generate_traders():
	var weights = Globals.get_rank_weights_for(Globals.playerAccount.rank)
	
	for i in range(4):
		var pn = randi_range(2, 6)
		var portrait = load("res://TradingStuff/Style/Portraits/M" + str(pn) + ".png")
		var gangName = Globals.nameList.pick_random()
		var coll = []

		#var rand_rank = randi_range(Globals.CardRanks.SIX, Globals.CardRanks.ACE)
		var trader_rank = Globals.choose_weighted_rank(weights)
		var rand_suit = Globals.CardSuits[randi_range(0, 3)]
		for j in range(randi_range(4, 10)):
			coll.append(Globals.choose_card_for_rank(trader_rank))
		#TraderList.append(Trader.new(gangName, randi_range(10, 100)+100, coll, portrait, trader_rank, rand_suit, 1.0))
		Globals.traderList.append(Trader.new(gangName, randi_range(10, 100)+100, coll, portrait, trader_rank, rand_suit, 1.0))
		
func _ready() -> void:
	Globals.traderList.clear()
	generate_traders()
	EventManager.apply_event(EventManager.current_event)
	var ts
	#for i in TraderList:
	for i in Globals.traderList:
		ts = traderScene.instantiate()
		container.add_child(ts)
		ts.init(i)

func _on_exit_button_pressed() -> void:
	Globals.NextPic = load("res://TradingStuff/Style/StoryPics/zloi.jpg")
	Globals.NextText = "One another day in trading. You spent all your todays money on ZLOI juice.
	You still have your cards."
	get_tree().change_scene_to_file("res://dialogue.tscn")
	
