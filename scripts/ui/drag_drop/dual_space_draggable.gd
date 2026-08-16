class_name DualSpaceDraggable
extends Control


@export var desk_view_path := NodePath("DeskView")
@export var counter_view_path := NodePath("CounterView")
@export var desk_size := Vector2(240.0, 344.0)
@export var counter_size := Vector2(120.0, 78.0)

var item_payload: Variant
var current_space: StringName = &"desk"

var _desk_view: Control
var _counter_view: Control


func _ready() -> void:
	_desk_view = get_node_or_null(desk_view_path) as Control
	_counter_view = get_node_or_null(counter_view_path) as Control
	_apply_space_view()
	_disable_mouse_input(self)


func set_item_payload(payload: Variant) -> void:
	item_payload = payload


func get_item_payload() -> Variant:
	return item_payload


func set_drag_space(space_name: StringName) -> void:
	current_space = space_name
	if is_node_ready():
		_apply_space_view()


func get_drag_space() -> StringName:
	return current_space


func _apply_space_view() -> void:
	var on_counter := current_space == &"counter"
	if _desk_view != null:
		_desk_view.visible = not on_counter
	if _counter_view != null:
		_counter_view.visible = on_counter

	var representation_size := counter_size if on_counter else desk_size
	custom_minimum_size = representation_size
	size = representation_size
	pivot_offset = representation_size * 0.5


func _disable_mouse_input(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_disable_mouse_input(child)
