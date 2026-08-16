class_name UIDragSurface
extends Control


@export var space_name: StringName = &"desk"
@export_range(0.0, 32.0, 0.5) var boundary_inset := 0.0
@export_range(-1.0, 0.95, 0.05) var outside_fraction_override := -1.0
@export var left_transfer_surface_path: NodePath
@export var gravity_enabled := false
@export_range(0.0, 10000.0, 50.0, "or_greater") var gravity_acceleration := 1800.0
@export var ground_level_path: NodePath

var _draggables: Array = []
var _active_draggable = null
var _grab_offset := Vector2.ZERO
var _top_z_index := 0
var _left_transfer_surface: Node
var _right_transfer_surface: Node
var _ground_level: Control


func _ready() -> void:
	_left_transfer_surface = get_node_or_null(left_transfer_surface_path)
	if is_instance_valid(_left_transfer_surface):
		_left_transfer_surface.call_deferred("set_right_transfer_surface", self)
	_ground_level = get_node_or_null(ground_level_path) as Control
	resized.connect(_keep_items_reachable)
	get_viewport().size_changed.connect(_keep_items_reachable)
	call_deferred("_keep_items_reachable")


func _process(delta: float) -> void:
	for draggable in _draggables:
		if draggable == _active_draggable:
			draggable.follow_target(delta)
		elif gravity_enabled:
			_apply_gravity(draggable, delta)
		else:
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
	draggable.set_surface_reference(self)
	draggable.set_drag_space(space_name)
	draggable.reset_motion()
	var target: Control = draggable.get_target() as Control
	if target != null:
		_top_z_index = maxi(_top_z_index, target.z_index)


func unregister_draggable(draggable) -> void:
	_draggables.erase(draggable)
	if _active_draggable == draggable:
		_active_draggable = null


func set_right_transfer_surface(surface: Node) -> void:
	_right_transfer_surface = surface


func get_boundary_rect() -> Rect2:
	var boundary := get_global_rect()
	if gravity_enabled and is_instance_valid(_ground_level):
		var ground_y := _ground_level.get_global_rect().position.y
		boundary.size.y = maxf(0.0, ground_y - boundary.position.y)
	return boundary


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
	_active_draggable.set_picked(true)
	_active_draggable.set_velocity(Vector2.ZERO)
	_grab_offset = global_pointer - _active_draggable.get_target().global_position
	_top_z_index += 1
	_active_draggable.bring_to_front(_top_z_index)
	get_viewport().set_input_as_handled()


func _update_drag(global_pointer: Vector2) -> void:
	var desired_position := global_pointer - _grab_offset
	if _should_transfer_left(global_pointer, desired_position):
		_transfer_active_to_surface(_left_transfer_surface, global_pointer, &"right")
		return
	if _should_transfer_right(global_pointer, desired_position):
		_transfer_active_to_surface(_right_transfer_surface, global_pointer, &"left")
		return

	_active_draggable.set_desired_global_position(
		_clamp_position_to_surface(_active_draggable, desired_position)
	)
	get_viewport().set_input_as_handled()


func _end_drag() -> void:
	if _active_draggable == null:
		return
	_active_draggable.set_picked(false)
	_active_draggable.reset_motion()
	_active_draggable = null
	get_viewport().set_input_as_handled()


func accept_transferred_draggable(
	draggable,
	global_pointer: Vector2,
	normalized_grab_offset: Vector2,
	entry_side: StringName
) -> void:
	register_draggable(draggable)
	var target: Control = draggable.get_target() as Control
	var target_size := target.get_global_rect().size
	_grab_offset = target_size * normalized_grab_offset
	var desired_position := global_pointer - _grab_offset
	var boundary := get_boundary_rect()
	if entry_side == &"left":
		desired_position.x = maxf(
			desired_position.x,
			boundary.position.x - target_size.x * 0.5 + 1.0
		)
	elif entry_side == &"right":
		desired_position.x = minf(
			desired_position.x,
			boundary.end.x - target_size.x * 0.5 - 1.0
		)
	desired_position = _clamp_position_to_surface(draggable, desired_position)
	target.global_position = desired_position
	draggable.set_desired_global_position(desired_position)
	_grab_offset = global_pointer - desired_position
	_active_draggable = draggable
	_top_z_index += 1
	draggable.bring_to_front(_top_z_index)
	draggable.set_picked(true)
	get_viewport().set_input_as_handled()


func _should_transfer_left(
	global_pointer: Vector2,
	desired_position: Vector2
) -> bool:
	if not is_instance_valid(_left_transfer_surface):
		return false
	var boundary := get_boundary_rect()
	var target_size: Vector2 = _active_draggable.get_target().get_global_rect().size
	var center_crossed := desired_position.x + target_size.x * 0.5 < boundary.position.x
	return global_pointer.x < boundary.position.x or center_crossed


func _should_transfer_right(
	global_pointer: Vector2,
	desired_position: Vector2
) -> bool:
	if not is_instance_valid(_right_transfer_surface):
		return false
	var boundary := get_boundary_rect()
	var target_size: Vector2 = _active_draggable.get_target().get_global_rect().size
	var center_crossed := desired_position.x + target_size.x * 0.5 > boundary.end.x
	return global_pointer.x > boundary.end.x or center_crossed


func _transfer_active_to_surface(
	destination_surface: Node,
	global_pointer: Vector2,
	entry_side: StringName
) -> void:
	var draggable = _active_draggable
	var target: Control = draggable.get_target() as Control
	var target_size := target.get_global_rect().size
	var normalized_grab_offset := Vector2(
		clampf(_grab_offset.x / maxf(target_size.x, 1.0), 0.0, 1.0),
		clampf(_grab_offset.y / maxf(target_size.y, 1.0), 0.0, 1.0)
	)
	_active_draggable = null
	unregister_draggable(draggable)
	target.reparent(destination_surface, true)
	destination_surface.call(
		"accept_transferred_draggable",
		draggable,
		global_pointer,
		normalized_grab_offset,
		entry_side
	)
	get_viewport().set_input_as_handled()


func _apply_gravity(draggable, delta: float) -> void:
	var target: Control = draggable.get_target() as Control
	var velocity: Vector2 = draggable.get_velocity()
	velocity.y += gravity_acceleration * delta
	var next_position := target.global_position + velocity * delta
	var boundary := get_boundary_rect()
	var target_size := target.get_global_rect().size
	var ground_position := boundary.end.y - target_size.y
	if next_position.y >= ground_position:
		next_position.y = ground_position
		velocity.y = 0.0
	next_position = _clamp_position_to_surface(draggable, next_position)
	target.global_position = next_position
	draggable.set_desired_global_position(next_position)
	draggable.set_velocity(velocity)


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
	var outside_fraction: float = draggable.maximum_outside_fraction
	if outside_fraction_override >= 0.0:
		outside_fraction = outside_fraction_override
	outside_fraction = clampf(outside_fraction, 0.0, 0.95)
	var maximum_outside := target_size * outside_fraction
	var minimum_inside := target_size - maximum_outside
	var inset := Vector2.ONE * boundary_inset
	var minimum_position := boundary.position + inset - maximum_outside
	var maximum_position := boundary.end - inset - minimum_inside
	return Vector2(
		clampf(desired_position.x, minimum_position.x, maximum_position.x),
		clampf(desired_position.y, minimum_position.y, maximum_position.y)
	)
