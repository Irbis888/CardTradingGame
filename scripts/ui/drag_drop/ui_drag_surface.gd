class_name UIDragSurface
extends Control


@export_range(0.0, 32.0, 0.5) var boundary_inset := 0.0

var _draggables: Array = []
var _active_draggable = null
var _grab_offset := Vector2.ZERO
var _top_z_index := 0


func _ready() -> void:
	resized.connect(_keep_items_reachable)
	get_viewport().size_changed.connect(_keep_items_reachable)
	call_deferred("_keep_items_reachable")


func _process(delta: float) -> void:
	for draggable in _draggables:
		draggable.follow_target(delta)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_begin_drag(mouse_button.position)
		else:
			_end_drag()
	elif event is InputEventMouseMotion and _active_draggable != null:
		_update_drag((event as InputEventMouseMotion).position)
	elif event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		if screen_touch.index != 0:
			return
		if screen_touch.pressed:
			_begin_drag(screen_touch.position)
		else:
			_end_drag()
	elif event is InputEventScreenDrag and _active_draggable != null:
		var screen_drag := event as InputEventScreenDrag
		if screen_drag.index == 0:
			_update_drag(screen_drag.position)


func register_draggable(draggable) -> void:
	if draggable in _draggables:
		return
	_draggables.append(draggable)
	var target: Control = draggable.get_target() as Control
	if target != null:
		_top_z_index = maxi(_top_z_index, target.z_index)
		draggable.synchronize_position()


func unregister_draggable(draggable) -> void:
	_draggables.erase(draggable)
	if _active_draggable == draggable:
		_active_draggable = null


func get_boundary_rect() -> Rect2:
	return get_global_rect()


func _begin_drag(global_pointer: Vector2) -> void:
	if not get_boundary_rect().has_point(global_pointer):
		return

	var picked = null
	for draggable in _draggables:
		if not draggable.contains_global_point(global_pointer):
			continue
		if picked == null or draggable.get_target().z_index >= picked.get_target().z_index:
			picked = draggable

	if picked == null:
		return

	_active_draggable = picked
	_active_draggable.synchronize_position()
	_grab_offset = global_pointer - _active_draggable.get_target().global_position
	_top_z_index += 1
	_active_draggable.bring_to_front(_top_z_index)
	get_viewport().set_input_as_handled()


func _update_drag(global_pointer: Vector2) -> void:
	var desired_position := global_pointer - _grab_offset
	_active_draggable.set_desired_global_position(
		_clamp_position_to_surface(_active_draggable, desired_position)
	)
	get_viewport().set_input_as_handled()


func _end_drag() -> void:
	if _active_draggable == null:
		return
	_active_draggable = null
	get_viewport().set_input_as_handled()


func _keep_items_reachable() -> void:
	for draggable in _draggables:
		if not draggable.is_drag_enabled():
			continue
		var clamped_target := _clamp_position_to_surface(
			draggable,
			draggable.get_desired_global_position()
		)
		draggable.set_desired_global_position(clamped_target)
		var target: Control = draggable.get_target() as Control
		target.global_position = _clamp_position_to_surface(
			draggable,
			target.global_position
		)


func _clamp_position_to_surface(
	draggable,
	desired_position: Vector2
) -> Vector2:
	var boundary := get_boundary_rect()
	var target_size: Vector2 = draggable.get_target().get_global_rect().size
	var outside_fraction: float = clampf(
		draggable.maximum_outside_fraction,
		0.0,
		0.95
	)
	var maximum_outside := target_size * outside_fraction
	var minimum_inside := target_size - maximum_outside
	var inset := Vector2.ONE * boundary_inset
	var minimum_position := boundary.position + inset - maximum_outside
	var maximum_position := boundary.end - inset - minimum_inside
	return Vector2(
		clampf(desired_position.x, minimum_position.x, maximum_position.x),
		clampf(desired_position.y, minimum_position.y, maximum_position.y)
	)
