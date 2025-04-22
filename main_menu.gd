extends Control

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://TradingStuff/main_trade_screen.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_tutor_button_pressed() -> void:
	get_tree().change_scene_to_file("res://tutorial.tscn")
