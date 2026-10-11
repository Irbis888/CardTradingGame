class_name LowerShelf
extends Control


signal return_to_counter_requested
signal slide_finished(active: bool)

@export var drag_surface_path := NodePath("..")
@export var return_strip_path := NodePath("ReturnHoverStrip")
@export var slot_paths: Array[NodePath] = []
@export var initial_item_paths: Array[NodePath] = []
@export_range(0.05, 2.0, 0.05) var slide_duration := 0.35

var _drag_surface: UIDragSurface
var _return_strip: Control
var _slots: Array[Control] = []
var _slot_items: Array[Control] = []
var _slide_tween: Tween
var _sliding_item_states: Dictionary = {}


func _ready() -> void:
	_resolve_nodes()
	if _return_strip != null:
		_return_strip.mouse_entered.connect(_on_return_strip_mouse_entered)
	if _drag_surface != null:
		_drag_surface.drag_released.connect(_on_drag_released)
		_drag_surface.child_exiting_tree.connect(_on_surface_child_exiting_tree)
	call_deferred("_place_initial_items")


func _exit_tree() -> void:
	if _slide_tween != null:
		_slide_tween.kill()
	_restore_item_input()


func is_sliding() -> bool:
	return _slide_tween != null


func set_shelf_active(active: bool, animated: bool = true) -> void:
	if _slide_tween != null:
		_slide_tween.kill()
		_slide_tween = null
	var destination := Vector2(0.0, 0.0 if active else size.y)
	if not animated:
		_set_slide_position(destination)
		_finish_slide(active)
		return

	visible = true
	for slot_index in range(_slot_items.size()):
		var item := _slot_items[slot_index]
		if not is_instance_valid(item):
			continue
		_place_item_in_slot(item, slot_index)
		var draggable := item.get_node_or_null("UIDraggable") as UIDraggable
		if draggable != null:
			if not _sliding_item_states.has(draggable):
				_sliding_item_states[draggable] = draggable.enabled
			draggable.enabled = false

	var remaining_fraction := clampf(absf(destination.y - position.y) / maxf(size.y, 1.0), 0.0, 1.0)
	_slide_tween = create_tween()
	_slide_tween.tween_method(_set_slide_position, position, destination,
		maxf(slide_duration * remaining_fraction, 0.01)
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_slide_tween.finished.connect(_finish_slide.bind(active))


func _set_slide_position(value: Vector2) -> void:
	position = value
	for slot_index in range(_slot_items.size()):
		var item := _slot_items[slot_index]
		if is_instance_valid(item):
			_place_item_in_slot(item, slot_index)


func _finish_slide(active: bool) -> void:
	_slide_tween = null
	visible = active
	for item in _slot_items:
		if is_instance_valid(item):
			item.visible = active
	_restore_item_input()
	slide_finished.emit(active)


func _restore_item_input() -> void:
	for draggable in _sliding_item_states:
		if is_instance_valid(draggable):
			draggable.enabled = bool(_sliding_item_states[draggable])
	_sliding_item_states.clear()


func get_slot_count() -> int:
	return _slots.size()


func get_item_in_slot(slot_index: int) -> Control:
	if slot_index < 0 or slot_index >= _slot_items.size():
		return null
	return _slot_items[slot_index]


func release_held_item(draggable) -> void:
	if draggable == null or not draggable.has_method("get_target"):
		return
	var item := draggable.get_target() as Control
	if item == null:
		return
	var slot_index := _find_item_slot(item)
	if slot_index >= 0:
		_slot_items[slot_index] = null


func _on_surface_child_exiting_tree(item: Node) -> void:
	var slot_index := _slot_items.find(item)
	if slot_index >= 0:
		_slot_items[slot_index] = null


func _resolve_nodes() -> void:
	_drag_surface = get_node_or_null(drag_surface_path) as UIDragSurface
	_return_strip = get_node_or_null(return_strip_path) as Control
	if _drag_surface == null:
		push_error("LowerShelf requires a UIDragSurface parent.")
	if _return_strip == null:
		push_error("LowerShelf requires return_strip_path.")

	_slots.clear()
	for slot_path in slot_paths:
		var slot := get_node_or_null(slot_path) as Control
		if slot != null:
			_slots.append(slot)
	_slot_items.resize(_slots.size())


func _place_initial_items() -> void:
	for item_index in range(mini(initial_item_paths.size(), _slots.size())):
		var item := get_node_or_null(initial_item_paths[item_index]) as Control
		if item == null:
			continue
		_slot_items[item_index] = item
		_place_item_in_slot(item, item_index)
		item.visible = visible


func _on_drag_released(draggable, global_pointer: Vector2) -> void:
	if not visible or is_sliding() or draggable == null or not draggable.has_method("get_target"):
		return
	var item := draggable.get_target() as Control
	if item == null:
		return

	var previous_slot := _find_item_slot(item)
	var target_slot := _find_slot_at(global_pointer)
	if target_slot < 0 or (
		_slot_items[target_slot] != null
		and _slot_items[target_slot] != item
	):
		if previous_slot >= 0:
			_place_item_in_slot(item, previous_slot)
		return

	if previous_slot >= 0 and previous_slot != target_slot:
		_slot_items[previous_slot] = null
	_slot_items[target_slot] = item
	_place_item_in_slot(item, target_slot)


func _find_item_slot(item: Control) -> int:
	for slot_index in range(_slot_items.size()):
		if _slot_items[slot_index] == item:
			return slot_index
	return -1


func _find_slot_at(global_pointer: Vector2) -> int:
	for slot_index in range(_slots.size()):
		if _slots[slot_index].get_global_rect().has_point(global_pointer):
			return slot_index
	return -1


func _place_item_in_slot(item: Control, slot_index: int) -> void:
	if slot_index < 0 or slot_index >= _slots.size():
		return
	if _drag_surface != null and item.get_parent() != _drag_surface:
		item.reparent(_drag_surface, true)
	var slot_rect := _slots[slot_index].get_global_rect()
	item.global_position = slot_rect.get_center() - item.size * 0.5
	item.z_index = 20 + slot_index
	item.visible = visible
	var draggable := item.get_node_or_null("UIDraggable") as UIDraggable
	if draggable != null:
		if _drag_surface != null:
			_drag_surface.register_draggable(draggable)
		draggable.synchronize_position()


func _on_return_strip_mouse_entered() -> void:
	if not is_sliding():
		return_to_counter_requested.emit()
