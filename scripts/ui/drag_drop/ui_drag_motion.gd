class_name UIDragMotion
extends RefCounted


var boundary_inset := 0.0
var outside_fraction_override := -1.0
var gravity_enabled := false
var gravity_acceleration := 1800.0
var horizontal_deceleration := 1200.0
var maximum_horizontal_speed := 1200.0


func get_boundary(surface: Control, ground_level: Control) -> Rect2:
	var boundary := surface.get_global_rect()
	if gravity_enabled and is_instance_valid(ground_level):
		var ground_y := ground_level.get_global_rect().position.y
		boundary.size.y = maxf(0.0, ground_y - boundary.position.y)
	return boundary


func clamp_position(
	draggable,
	desired_position: Vector2,
	surface: Control,
	ground_level: Control
) -> Vector2:
	var boundary := get_boundary(surface, ground_level)
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


func set_horizontal_velocity(draggable, horizontal_speed: float) -> void:
	if not gravity_enabled or draggable == null:
		return
	draggable.set_velocity(Vector2(
		clampf(horizontal_speed, -maximum_horizontal_speed, maximum_horizontal_speed),
		0.0
	))


func decelerate_horizontal_velocity(draggable, delta: float) -> void:
	var velocity: Vector2 = draggable.get_velocity()
	velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * delta)
	velocity.y = 0.0
	draggable.set_velocity(velocity)


func apply_gravity(
	draggable,
	delta: float,
	surface: Control,
	ground_level: Control
) -> void:
	var target: Control = draggable.get_target() as Control
	var velocity: Vector2 = draggable.get_velocity()
	velocity.x = move_toward(velocity.x, 0.0, horizontal_deceleration * delta)
	velocity.y += gravity_acceleration * delta
	var unclamped_position := target.global_position + velocity * delta
	var boundary := get_boundary(surface, ground_level)
	var target_size := target.get_global_rect().size
	var ground_position := boundary.end.y - target_size.y
	if unclamped_position.y >= ground_position:
		unclamped_position.y = ground_position
		velocity.y = 0.0
	var next_position := clamp_position(draggable, unclamped_position, surface, ground_level)
	if not is_equal_approx(next_position.x, unclamped_position.x):
		velocity.x = 0.0
	target.global_position = next_position
	draggable.set_desired_global_position(next_position)
	draggable.set_velocity(velocity)
