class_name CardBinderPreviewRenderer
extends RefCounted


const CARD_VIEW_SCENE := preload("res://scenes/ui/card_view.tscn")


static func render(
	preview_host: Control,
	slot_panel: Control,
	card: Card,
	preview_size: Vector2
) -> void:
	clear(preview_host)
	if card == null:
		return
	var preview := CARD_VIEW_SCENE.instantiate() as Control
	preview_host.add_child(preview)
	preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
	preview.size = preview_size
	var available_size := slot_panel.size - Vector2(14.0, 14.0)
	var preview_scale := minf(
		available_size.x / preview_size.x,
		available_size.y / preview_size.y
	)
	preview.scale = Vector2.ONE * preview_scale
	preview.position = (slot_panel.size - preview_size * preview_scale) * 0.5
	_set_mouse_input_ignored(preview)
	preview.call("init", card)


static func clear(preview_host: Control) -> void:
	for child in preview_host.get_children():
		preview_host.remove_child(child)
		child.queue_free()


static func _set_mouse_input_ignored(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_input_ignored(child)
