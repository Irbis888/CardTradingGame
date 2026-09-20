class_name UIDragSurface
extends Control


signal drag_released(draggable, global_pointer: Vector2)

@export var space_name: StringName = &"desk"
@export_range(0.0, 32.0, 0.5) var boundary_inset := 0.0
@export_range(-1.0, 0.95, 0.05) var outside_fraction_override := -1.0
@export var left_transfer_surface_path: NodePath
#@export var right_transfer_surface_path: NodePath
@export var gravity_enabled := false
@export_range(0.0, 10000.0, 50.0, "or_greater") var gravity_acceleration := 1800.0
@export_range(0.0, 10000.0, 50.0, "or_greater") var horizontal_deceleration := 1200.0
@export_range(0.0, 10000.0, 50.0, "or_greater") var maximum_horizontal_speed := 1200.0
@export var ground_level_path: NodePath

var _draggables: Array = []
var _active_draggable = null
var _grab_offset := Vector2.ZERO
var _top_z_index := 0
var _left_transfer_surface: Node
var _right_transfer_surface: Node
var _ground_level: Control
var _drop_targets := UIDropTargetRegistry.new()
var _motion := UIDragMotion.new()


func _ready() -> void:
	_configure_motion()
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
			if gravity_enabled:
				_motion.decelerate_horizontal_velocity(draggable, delta)
		elif gravity_enabled:
			_motion.apply_gravity(draggable, delta, self, _ground_level)
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
			_end_drag(mouse_button.position)
	elif event is InputEventMouseMotion and _active_draggable != null:
		var mouse_motion := event as InputEventMouseMotion
		_update_drag(mouse_motion.position, mouse_motion.velocity)
	elif event is InputEventScreenTouch:
		var screen_touch := event as InputEventScreenTouch
		if screen_touch.index != 0:
			return
		if screen_touch.pressed:
			_begin_drag(screen_touch.position)
		else:
			_end_drag(screen_touch.position)
	elif event is InputEventScreenDrag and _active_draggable != null:
		var screen_drag := event as InputEventScreenDrag
		if screen_drag.index == 0:
			_update_drag(screen_drag.position, screen_drag.velocity)


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


func has_active_drag() -> bool:
	return _active_draggable != null


func get_active_draggable():
	return _active_draggable


func set_gravity_active(active: bool) -> void:
	gravity_enabled = active
	_motion.gravity_enabled = active


func transfer_active_draggable_to(
	destination_surface: Node,
	global_pointer: Vector2,
	entry_side: StringName
) -> bool:
	if _active_draggable == null or not is_instance_valid(destination_surface):
		return false
	if not destination_surface.has_method("accept_transferred_draggable"):
		return false
	_transfer_active_to_surface(
		destination_surface,
		global_pointer,
		Vector2.ZERO,
		entry_side
	)
	return true


func register_drop_receiver(receiver: Node) -> void:
	_drop_targets.register(receiver)


func unregister_drop_receiver(receiver: Node) -> void:
	_drop_targets.unregister(receiver)


func begin_draggable_drag(draggable, global_pointer: Vector2) -> bool:
	if _active_draggable != null or not draggable.is_drag_enabled():
		return false
	if draggable not in _draggables:
		register_draggable(draggable)
	_activate_draggable(draggable, global_pointer)
	return true


func set_right_transfer_surface(surface: Node) -> void:
	_right_transfer_surface = surface


func get_boundary_rect() -> Rect2:
	return _motion.get_boundary(self, _ground_level)


func _begin_drag(global_pointer: Vector2) -> void:
	if not get_boundary_rect().has_point(global_pointer):
		return

	var picked = null
	for draggable in _draggables:
		if not draggable.is_drag_enabled():
			continue
		var target := draggable.get_target() as Control
		if target == null or not target.get_global_rect().has_point(global_pointer):
			continue
		if picked == null or target.z_index >= picked.get_target().z_index:
			picked = draggable

	if picked == null or not picked.contains_global_point(global_pointer):
		return
	_activate_draggable(picked, global_pointer)


func _activate_draggable(draggable, global_pointer: Vector2) -> void:
	_active_draggable = draggable
	_active_draggable.synchronize_position()
	_active_draggable.set_picked(true)
	_active_draggable.set_velocity(Vector2.ZERO)
	_grab_offset = global_pointer - _active_draggable.get_target().global_position
	_top_z_index += 2
	_active_draggable.bring_to_front(_top_z_index)
	_update_drop_receiver_hover(_active_draggable, global_pointer)
	get_viewport().set_input_as_handled()


func _update_drag(
	global_pointer: Vector2,
	pointer_velocity: Vector2 = Vector2.ZERO
) -> void:
	_motion.set_horizontal_velocity(_active_draggable, pointer_velocity.x)
	var desired_position := global_pointer - _grab_offset
	if _should_transfer_left(global_pointer, desired_position):
		_transfer_active_to_surface(
			_left_transfer_surface,
			global_pointer,
			pointer_velocity,
			&"right"
		)
		return
	if _should_transfer_right(global_pointer, desired_position):
		_transfer_active_to_surface(
			_right_transfer_surface,
			global_pointer,
			pointer_velocity,
			&"left"
		)
		return

	_update_drop_receiver_hover(_active_draggable, global_pointer)
	_active_draggable.set_desired_global_position(
		_clamp_position_to_surface(_active_draggable, desired_position)
	)
	get_viewport().set_input_as_handled()


func _end_drag(global_pointer: Vector2) -> void:
	if _active_draggable == null:
		return

	var released_draggable = _active_draggable
	released_draggable.set_picked(false)
	var accepting_receiver := _find_accepting_drop_receiver(
		released_draggable,
		global_pointer
	)
	_clear_drop_receiver_hover()
	if accepting_receiver != null and accepting_receiver.has_method("accept_drop") and bool(
		accepting_receiver.call("accept_drop", released_draggable, global_pointer)
	):
		unregister_draggable(released_draggable)
		_active_draggable = null
		get_viewport().set_input_as_handled()
		return

	if gravity_enabled:
		var release_velocity: Vector2 = released_draggable.get_velocity()
		released_draggable.set_velocity(Vector2(release_velocity.x, 0.0))
		released_draggable.synchronize_position()
	else:
		released_draggable.reset_motion()
	_active_draggable = null
	drag_released.emit(released_draggable, global_pointer)
	get_viewport().set_input_as_handled()


func accept_transferred_draggable(
	draggable,
	global_pointer: Vector2,
	normalized_grab_offset: Vector2,
	entry_side: StringName,
	pointer_velocity: Vector2 = Vector2.ZERO
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
	_motion.set_horizontal_velocity(_active_draggable, pointer_velocity.x)
	_update_drop_receiver_hover(draggable, global_pointer)
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
	pointer_velocity: Vector2,
	entry_side: StringName
) -> void:
	var draggable = _active_draggable
	var target: Control = draggable.get_target() as Control
	var target_size := target.get_global_rect().size
	var normalized_grab_offset := Vector2(
		clampf(_grab_offset.x / maxf(target_size.x, 1.0), 0.0, 1.0),
		clampf(_grab_offset.y / maxf(target_size.y, 1.0), 0.0, 1.0)
	)
	_clear_drop_receiver_hover()
	_active_draggable = null
	unregister_draggable(draggable)
	target.reparent(destination_surface, true)
	destination_surface.call(
		"accept_transferred_draggable",
		draggable,
		global_pointer,
		normalized_grab_offset,
		entry_side,
		pointer_velocity
	)
	get_viewport().set_input_as_handled()


func _find_accepting_drop_receiver(
	draggable,
	global_pointer: Vector2
) -> Node:
	return _drop_targets.find_accepting(draggable, global_pointer)


func _update_drop_receiver_hover(draggable, global_pointer: Vector2) -> void:
	_drop_targets.update_hover(draggable, global_pointer)


func _clear_drop_receiver_hover() -> void:
	_drop_targets.clear_hover()


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
	return _motion.clamp_position(draggable, desired_position, self, _ground_level)


func _configure_motion() -> void:
	_motion.boundary_inset = boundary_inset
	_motion.outside_fraction_override = outside_fraction_override
	_motion.gravity_enabled = gravity_enabled
	_motion.gravity_acceleration = gravity_acceleration
	_motion.horizontal_deceleration = horizontal_deceleration
	_motion.maximum_horizontal_speed = maximum_horizontal_speed
