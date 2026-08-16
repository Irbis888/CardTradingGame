extends Control

var is_to_trade: bool

func _ready() -> void:
	if Globals.day == 0:
		DayCycle.initialize_game()

	$bckgr/TextureRect.texture = Globals.NextPic
	$bckgr/Label.text = Globals.NextText
	is_to_trade = Globals.is_next_to_trade


func _on_start_button_pressed() -> void:
	Globals.is_next_to_trade = !is_to_trade

	if is_to_trade:
		DayCycle.prepare_trade_screen()
		get_tree().change_scene_to_file(GamePaths.SCENE_TRADER_LIST)
		DayCycle.reset_daily_money()
	else:
		DayCycle.advance_to_next_day()
		get_tree().change_scene_to_file(GamePaths.SCENE_DIALOGUE)

func _on_menu_button_pressed() -> void:
	pass # Replace with function body.
