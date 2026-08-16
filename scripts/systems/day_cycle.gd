class_name DayCycle
extends RefCounted


static func initialize_game() -> void:
	Globals.traderList.clear()
	Globals.add_story_traders_for_current_day()
	Globals.generate_traders()
	EventManager.apply_event(EventManager.current_event)
	Globals.day = 1
	Globals.quest_manager.get_quests_for_day(Globals.day)


static func prepare_trade_screen() -> void:
	Globals.NextPic = load(GamePaths.DAY_COMPLETE_IMAGE)
	Globals.NextText = Globals.content.story.day_complete


static func reset_daily_money() -> void:
	Globals.playerAccount.LI = 0


static func advance_to_next_day() -> void:
	Globals.NextPic = load(GamePaths.EVENT_IMAGE)

	if EventManager.queued_event_id != -1:
		EventManager.current_event = EventManager.get_event_by_id(EventManager.queued_event_id)
		EventManager.queued_event_id = -1
	else:
		EventManager.pick_random_event()

	Globals.traderList.clear()
	Globals.day += 1
	Globals.add_story_traders_for_current_day()
	Globals.generate_traders()
	EventManager.apply_event(EventManager.current_event)
	Globals.quest_manager.get_quests_for_day(Globals.day)
	Globals.NextText = EventManager.current_event.description

