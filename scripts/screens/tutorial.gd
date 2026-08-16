extends Control

var strs: Array = []
var page = 0

func  _ready() -> void:
	strs = Globals.content.tutorial.pages
	set_label_text()

func set_label_text():
	var s = strs[page]
	var out = ""
	var c = 0
	for i in s:
		if i == "\n":
			c = 0
		if c >= 50:
			out += "\n"
			c = 0
		out += i
		c += 1
	$TextureRect/Label.text = out


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file(GamePaths.SCENE_MAIN_MENU)


func _on_prev_page_pressed() -> void:
	page = max(0, page - 1)
	set_label_text()


func _on_next_page_pressed() -> void:
	page = min(len(strs)-1, page + 1)
	set_label_text()
