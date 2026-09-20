class_name CustomerHandoffView
extends Control


const DRAGGABLE_CARD_SCENE := preload("res://scenes/ui/draggable_card.tscn")

@export var customer_manager_path: NodePath
@export var drag_surface_path: NodePath
@export var card_return_surface_path: NodePath
@export var drop_region_path: NodePath
@export var portrait_path: NodePath
@export_range(0.0, 10000.0, 50.0, "or_greater") var fall_acceleration := 2400.0
@export_range(0.0, 5000.0, 25.0, "or_greater") var initial_fall_speed := 180.0
@export_range(0.0, 10000.0, 50.0, "or_greater") var maximum_fall_speed := 1800.0

var _customer_manager: CustomerManager
var _drag_surface: Node
var _card_return_surface: Control
var _drop_region: Control
var _portrait: TextureRect
var _shows_transfer_cursor := false
var _pending_transfers: Array[Dictionary] = []


func _ready() -> void:
	_resolve_dependencies()
	_register_as_drop_target()
	if _customer_manager != null:
		_customer_manager.card_return_requested.connect(_return_card_to_player)


func _process(delta: float) -> void:
	_process_pending_transfers(delta)


func _exit_tree() -> void:
	clear_draggable_hover()
	if is_instance_valid(_drag_surface) and _drag_surface.has_method("unregister_drop_receiver"):
		_drag_surface.call("unregister_drop_receiver", self)


func can_accept_drop(draggable, global_pointer: Vector2) -> bool:
	return (
		_customer_manager != null
		and _customer_manager.can_accept_delivery()
		and _is_pointer_inside_drop_region(global_pointer)
		and not _describe_supported_item(draggable).is_empty()
	)


func accept_drop(draggable, _global_pointer: Vector2) -> bool:
	if not can_accept_drop(draggable, _global_pointer) or not is_instance_valid(_portrait):
		return false
	var target := draggable.get_target() as Control
	var transfer := _make_transfer(target)
	if target == null or transfer.is_empty() or not _customer_manager.begin_item_delivery():
		return false

	draggable.enabled = false
	draggable.set_velocity(Vector2.ZERO)
	target.reparent(self, true)
	target.z_index = 0
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transfer["target"] = target
	transfer["fall_speed"] = initial_fall_speed
	_pending_transfers.append(transfer)
	return true


func update_draggable_hover(draggable, global_pointer: Vector2) -> void:
	_set_transfer_cursor(can_accept_drop(draggable, global_pointer))


func clear_draggable_hover() -> void:
	_set_transfer_cursor(false)


func _resolve_dependencies() -> void:
	_customer_manager = get_node_or_null(customer_manager_path) as CustomerManager
	_drag_surface = get_node_or_null(drag_surface_path)
	_card_return_surface = get_node_or_null(card_return_surface_path) as Control
	_drop_region = get_node_or_null(drop_region_path) as Control
	_portrait = get_node_or_null(portrait_path) as TextureRect
	if _customer_manager == null:
		push_error("CustomerHandoffView requires customer_manager_path.")
	if _drop_region == null:
		push_error("CustomerHandoffView requires drop_region_path.")
	if _portrait == null:
		push_error("CustomerHandoffView requires portrait_path.")
	if _card_return_surface == null:
		push_error("CustomerHandoffView requires card_return_surface_path.")


func _register_as_drop_target() -> void:
	if not is_instance_valid(_drag_surface) or not _drag_surface.has_method("register_drop_receiver"):
		push_error("CustomerHandoffView requires a compatible drag surface.")
		return
	_drag_surface.call("register_drop_receiver", self)


func _is_pointer_inside_drop_region(global_pointer: Vector2) -> bool:
	return (
		is_instance_valid(_drop_region)
		and _drop_region.is_visible_in_tree()
		and _drop_region.get_global_rect().has_point(global_pointer)
	)


func _describe_supported_item(draggable) -> String:
	if draggable == null or not draggable.has_method("get_target"):
		return ""
	var target := draggable.get_target() as Control
	if target is DraggableCard:
		return "card" if (target as DraggableCard).get_card_data() != null else ""
	if target is DraggableReceipt:
		return "receipt"
	return ""


func _make_transfer(target: Control) -> Dictionary:
	if target is DraggableCard:
		var card := (target as DraggableCard).get_card_data()
		return {"kind": &"card", "card": card} if card != null else {}
	if target is DraggableReceipt:
		var receipt := target as DraggableReceipt
		return {
			"kind": &"receipt",
			"receipt_type": receipt.get_receipt_type(),
			"amount": receipt.get_amount(),
		}
	return {}


func _process_pending_transfers(delta: float) -> void:
	if _pending_transfers.is_empty() or not is_instance_valid(_portrait):
		return
	var delivery_y := _portrait.get_global_rect().end.y
	for index in range(_pending_transfers.size() - 1, -1, -1):
		var transfer := _pending_transfers[index]
		var target := transfer.get("target") as Control
		if not is_instance_valid(target):
			_pending_transfers.remove_at(index)
			if _customer_manager != null:
				_customer_manager.cancel_item_delivery()
			continue

		var fall_speed := minf(
			float(transfer.get("fall_speed", 0.0)) + fall_acceleration * delta,
			maximum_fall_speed
		)
		target.global_position += Vector2.DOWN * fall_speed * delta
		transfer["fall_speed"] = fall_speed
		_pending_transfers[index] = transfer
		if target.global_position.y >= delivery_y:
			_finish_transfer(index, transfer, target)


func _finish_transfer(index: int, transfer: Dictionary, target: Control) -> void:
	_pending_transfers.remove_at(index)
	var handled := false
	if _customer_manager != null:
		match transfer.get("kind", &"") as StringName:
			&"card":
				handled = _customer_manager.give_card(transfer.get("card") as Card)
			&"receipt":
				handled = _customer_manager.submit_ask(
					transfer.get("receipt_type", &"") as StringName,
					int(transfer.get("amount", 0))
				)
	if not handled and transfer.get("kind", &"") == &"card":
		_return_card_to_player(transfer.get("card") as Card)
	if is_instance_valid(target):
		target.queue_free()


func _return_card_to_player(card: Card) -> void:
	if card == null or not is_instance_valid(_card_return_surface):
		return
	var card_instance := DRAGGABLE_CARD_SCENE.instantiate() as DraggableCard
	card_instance.z_index = _get_next_return_z_index()
	_card_return_surface.add_child(card_instance)
	card_instance.display_card(card)
	var cascade := _count_loose_cards() % 6
	card_instance.global_position = (
		_card_return_surface.get_global_rect().position
		+ Vector2(35.0 + cascade * 24.0, 45.0 + cascade * 18.0)
	)
	var draggable := card_instance.get_node_or_null("UIDraggable") as UIDraggable
	if draggable != null:
		draggable.synchronize_position()


func _count_loose_cards() -> int:
	var count := 0
	for child in _card_return_surface.get_children():
		if child is DraggableCard:
			count += 1
	return count


func _get_next_return_z_index() -> int:
	var highest := 0
	for child in _card_return_surface.get_children():
		if child is Control:
			highest = maxi(highest, (child as Control).z_index)
	return highest + 1


func _set_transfer_cursor(enabled: bool) -> void:
	if _shows_transfer_cursor == enabled:
		return
	_shows_transfer_cursor = enabled
	Input.set_default_cursor_shape(
		Input.CURSOR_CAN_DROP if enabled else Input.CURSOR_ARROW
	)
