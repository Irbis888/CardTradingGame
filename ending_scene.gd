extends Control

@onready var description = $bckgr/Label
@onready var menu_button = $bckgr/MenuButton

var ending_data: Dictionary

func _ready() -> void:
	ending_data = Globals.current_ending
	
	if ending_data:
		print(ending_data)
		description.text = "%s\n%s" % [ending_data["name"], ending_data["description"]]
	else: print("nah no ending data")
	menu_button.pressed.connect(_on_ending_menu_button_pressed)
	
	
func _on_ending_menu_button_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
