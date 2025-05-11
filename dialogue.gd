extends Control

var is_to_trade: bool

func _ready() -> void:
	# проверка
	if Globals.day == 0:
		Globals.traderList.clear()
		Globals.get_story_bitches()
		Globals.generate_traders()
		EventManager.apply_event(EventManager.current_event)
		Globals.day = 1
		Globals.quest_manager.get_quests_for_day(Globals.day)
	
	$bckgr/TextureRect.texture = Globals.NextPic
	$bckgr/Label.text = Globals.NextText
	is_to_trade = Globals.is_next_to_trade


func _on_start_button_pressed() -> void:
	Globals.is_next_to_trade = !is_to_trade
	if is_to_trade:
		Globals.NextPic = load("res://TradingStuff/Style/StoryPics/zloi.jpg")
		Globals.NextText = "One another day in trading. You spent all your todays money on ZLOI juice.
	#You still have your cards."
		get_tree().change_scene_to_file("res://TradingStuff/main_trade_screen.tscn")
		#EventManager.apply_event(EventManager.current_event)
		
		Globals.playerAccount.LI = 0
	else:

		Globals.quest_manager.check_quests_end_of_day(Globals.traderList)
		Globals.NextPic = load("res://TradingStuff/Style/StoryPics/playing.jpg")
		#Globals.NextText = "Good morning! Time to participate in trading"
		EventManager.pick_random_event()
		Globals.traderList.clear()
		print("hi ", Globals.story_traders.size())
		Globals.day +=1
		Globals.get_story_bitches()
		Globals.generate_traders()
		EventManager.apply_event(EventManager.current_event)
		
		Globals.quest_manager.get_quests_for_day(Globals.day)

		
		Globals.NextText = EventManager.current_event.description
		get_tree().change_scene_to_file("res://dialogue.tscn")
