extends "res://scripts/ui/drag_drop/dual_space_draggable.gd"


func _ready() -> void:
	super()
	set_item_payload({
		"kind": &"greybox",
		"desk_color": Color(0.82, 0.075, 0.055, 1.0),
		"label": "TEST ITEM",
	})
