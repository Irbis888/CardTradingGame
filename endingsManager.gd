extends Node

var endings := [] # Массив словарей с данными концовок
var unlocked_endings := [] # Список id разблокированных концовок

func _ready():
	endings = Globals.load_json_file("res://Resources/endings.json")
	#check_for_endings()

func check_for_endings()-> bool:
	for ending in endings:
		if ending.id in unlocked_endings:
			continue # Уже разблокирована

		if check_ending_condition(ending):
			unlocked_endings.append(ending.id)
			trigger_ending(ending)
			return true
	return false

func check_ending_condition(ending: Dictionary) -> bool:
	match ending.condition_type:
		"has_all_ssp":
			return Globals.has_all_ssp_cards()
		"quest_completed":
			return Globals.quest_manager.is_quest_completed(ending.quest_id)
		_: # Неизвестное условие
			return false

func trigger_ending(ending: Dictionary) -> void:
	print("Ending unlocked: ", ending.name)
	Globals.current_ending = ending
	get_tree().change_scene_to_file("res://ending_scene.tscn")
