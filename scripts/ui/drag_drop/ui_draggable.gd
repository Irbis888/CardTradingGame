class_name UIDraggable
extends Node


@export var enabled := true
@export_range(0.0, 60.0, 0.5, "or_greater") var follow_speed := 20.0
@export_range(0.0, 0.95, 0.05) var maximum_outside_fraction := 0.8
@export var target_path := NodePath("..")

var _target: Control
var _surface: Node
var _desired_global_position := Vector2.ZERO


func _ready() -> void:
	_target = get_node_or_null(target_path) as Control
	if _target == null:
		push_error("UIDraggable requires target_path to reference a Control node.")
		return

	var ancestor: Node = get_parent()
	while ancestor != null and not ancestor.has_method("register_draggable"):
		ancestor = ancestor.get_parent()

	_surface = ancestor
	if _surface == null:
		push_error("UIDraggable must be placed below a UIDragSurface node.")
		return

	_desired_global_position = _target.global_position
	_surface.call("register_draggable", self)


func _exit_tree() -> void:
	if is_instance_valid(_surface) and _surface.has_method("unregister_draggable"):
		_surface.call("unregister_draggable", self)


func get_target() -> Control:
	return _target


func is_drag_enabled() -> bool:
	return enabled and is_instance_valid(_target) and _target.is_visible_in_tree()


func contains_global_point(global_point: Vector2) -> bool:
	return is_drag_enabled() and _target.get_global_rect().has_point(global_point)


func get_desired_global_position() -> Vector2:
	return _desired_global_position


func set_desired_global_position(global_position: Vector2) -> void:
	_desired_global_position = global_position


func synchronize_position() -> void:
	if is_instance_valid(_target):
		_desired_global_position = _target.global_position


func follow_target(delta: float) -> void:
	if not is_instance_valid(_target):
		return

	if follow_speed <= 0.0:
		_target.global_position = _desired_global_position
		return

	if _target.global_position.distance_squared_to(_desired_global_position) < 0.01:
		_target.global_position = _desired_global_position
		return

	var follow_weight := 1.0 - exp(-follow_speed * delta)
	_target.global_position = _target.global_position.lerp(
		_desired_global_position,
		follow_weight
	)


func bring_to_front(z_index_value: int) -> void:
	if is_instance_valid(_target):
		_target.z_index = z_index_value
