extends Control

@onready var description = $bckgr/Label

var ending_data: Dictionary

func _ready() -> void:
	ending_data = Globals.current_ending
	
	if ending_data:
		print(ending_data)
		description.text = "%s\n%s" % [ending_data["name"], ending_data["description"]]
	else: push_warning("Ending screen opened without ending data.")
	
	
func _on_ending_menu_button_pressed():
	get_tree().change_scene_to_file(GamePaths.SCENE_MAIN_MENU)
