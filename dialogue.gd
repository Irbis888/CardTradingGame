extends Control

var is_to_trade: bool

func _ready() -> void:
	$bckgr/TextureRect.texture = Globals.NextPic
	$bckgr/Label.text = Globals.NextText
	is_to_trade = Globals.is_next_to_trade


func _on_start_button_pressed() -> void:
	Globals.is_next_to_trade = !is_to_trade
	if is_to_trade:
		Globals.NextPic = load("res://TradingStuff/Style/StoryPics/zloi.jpg")
		Globals.NextText = "One another day in trading. You spent all your todays money on ZLOI juice.
	You still have your cards."
		get_tree().change_scene_to_file("res://TradingStuff/main_trade_screen.tscn")
	else:
		Globals.NextPic = load("res://TradingStuff/Style/StoryPics/playing.jpg")
		Globals.NextText = "Good morning! Time to participate in trading"
		get_tree().change_scene_to_file("res://dialogue.tscn")
