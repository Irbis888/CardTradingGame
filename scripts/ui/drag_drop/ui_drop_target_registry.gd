class_name UIDropTargetRegistry
extends RefCounted


var _targets: Array[Node] = []


func register(target: Node) -> void:
	if target not in _targets:
		_targets.append(target)


func unregister(target: Node) -> void:
	if is_instance_valid(target) and target.has_method("clear_draggable_hover"):
		target.call("clear_draggable_hover")
	_targets.erase(target)


func find_accepting(draggable, global_pointer: Vector2) -> Node:
	_remove_invalid_targets()
	for target in _targets:
		if target.has_method("can_accept_drop") and bool(
			target.call("can_accept_drop", draggable, global_pointer)
		):
			return target
	return null


func update_hover(draggable, global_pointer: Vector2) -> void:
	_remove_invalid_targets()
	for target in _targets:
		if target.has_method("update_draggable_hover"):
			target.call("update_draggable_hover", draggable, global_pointer)


func clear_hover() -> void:
	_remove_invalid_targets()
	for target in _targets:
		if target.has_method("clear_draggable_hover"):
			target.call("clear_draggable_hover")


func _remove_invalid_targets() -> void:
	for index in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[index]):
			_targets.remove_at(index)
