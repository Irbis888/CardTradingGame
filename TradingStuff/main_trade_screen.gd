extends Node2D

var TraderList : Array[Trader] = []
var traderScene = load("res://TradingStuff/traderButton.tscn")
@onready var container = $ScrollContainer/GridContainer


		
func _ready() -> void:
	#Globals.traderList.clear()
	#generate_traders()
	#EventManager.apply_event(EventManager.current_event)
	var ts
	#for i in TraderList:
	for i in Globals.traderList:
		ts = traderScene.instantiate()
		container.add_child(ts)
		ts.init(i)

func _on_exit_button_pressed() -> void:
	Globals.quest_manager.check_quests_end_of_day(Globals.traderList)
	if EndingsManager.check_for_endings():
			return
		
	Globals.NextPic = load("res://TradingStuff/Style/StoryPics/zloi.jpg")
	Globals.NextText = "One another day in trading. You spent all your todays money on ZLOI juice.
	You still have your cards."
	get_tree().change_scene_to_file("res://dialogue.tscn")
	
