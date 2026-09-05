class_name CustomerManager
extends Control


signal item_given(description: String)
signal replica_spoken(text: String)
signal customer_dialogue_ended(customer: CustomerData)
signal customer_spawned(customer: CustomerData)

const DEV_CONSOLE_GROUP := &"dev_console"
const CUSTOMER_MANAGER_GROUP := &"customer_manager"
const CONSOLE_MESSAGE_PREFIX := "Customer received: "
const PORTRAIT_PATH_TEMPLATE := "res://assets/portraits/M%d.png"

@export var drag_surface_path: NodePath
@export var drop_region_path: NodePath = NodePath(".")
@export var portrait_path: NodePath
@export var speech_bubble_path: NodePath
@export var speech_label_path: NodePath
@export var speech_timer_path: NodePath
@export_range(0.1, 60.0, 0.1, "or_greater") var default_replica_duration := 4.0
@export_range(0.05, 5.0, 0.05, "or_greater") var fade_duration := 0.35
@export_range(0, 1000, 1, "or_greater") var initial_portrait_number := 6
@export_range(0, 1000, 1, "or_greater") var initial_patience_turns := 5
@export_range(0, 1000000000, 1, "or_greater") var initial_customer_money := 250
@export_range(0, 1000000, 1, "or_greater") var initial_card_count := 3

var _drag_surface: Node
var _drop_region: Control
var _portrait: TextureRect
var _speech_bubble: Control
var _speech_label: Label
var _speech_timer: Timer
var _transition_tween: Tween
var _current_customer: CustomerData
var _shows_transfer_cursor := false
var _customer_present := false
var _transitioning := false


func _ready() -> void:
	add_to_group(CUSTOMER_MANAGER_GROUP)
	item_given.connect(_log_given_item)
	_drag_surface = get_node_or_null(drag_surface_path)
	_drop_region = get_node_or_null(drop_region_path) as Control
	_portrait = get_node_or_null(portrait_path) as TextureRect
	_speech_bubble = get_node_or_null(speech_bubble_path) as Control
	_speech_label = get_node_or_null(speech_label_path) as Label
	_speech_timer = get_node_or_null(speech_timer_path) as Timer

	if _drop_region == null:
		push_error("CustomerManager requires drop_region_path to reference a Control.")
	if _portrait == null:
		push_error("CustomerManager requires portrait_path to reference a TextureRect.")
	if _speech_timer != null:
		_speech_timer.timeout.connect(_hide_replica)
	if _speech_bubble != null:
		_speech_bubble.visible = false

	_current_customer = CustomerData.new(
		initial_portrait_number,
		initial_patience_turns,
		initial_customer_money,
		initial_card_count
	)
	_customer_present = _apply_portrait_texture(initial_portrait_number)
	if _portrait != null:
		_portrait.visible = _customer_present
		_portrait.modulate.a = 1.0
	modulate.a = 1.0
	_register_as_drop_receiver()


func _exit_tree() -> void:
	clear_draggable_hover()
	if is_instance_valid(_transition_tween):
		_transition_tween.kill()
	if is_instance_valid(_drag_surface) and _drag_surface.has_method("unregister_drop_receiver"):
		_drag_surface.call("unregister_drop_receiver", self)


func get_current_customer() -> CustomerData:
	return _current_customer


func has_customer() -> bool:
	return _customer_present


func is_transitioning() -> bool:
	return _transitioning


func end_customer_dialogue() -> bool:
	if not _customer_present or _transitioning or _portrait == null:
		return false

	_transitioning = true
	clear_draggable_hover()
	_hide_replica()
	var departing_customer := _current_customer
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait,
		"modulate:a",
		0.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.tween_property(
		self,
		"modulate:a",
		0.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_transition_tween.finished.connect(
		_finish_customer_exit.bind(departing_customer)
	)
	return true


func spawn_new_customer(customer: CustomerData) -> bool:
	if customer == null or _customer_present or _transitioning or _portrait == null:
		return false
	if not _apply_portrait_texture(customer.portrait_number):
		return false

	_current_customer = customer
	_transitioning = true
	visible = true
	_portrait.visible = true
	modulate.a = 0.0
	_portrait.modulate.a = 0.0
	_transition_tween = create_tween()
	_transition_tween.set_parallel(true)
	_transition_tween.tween_property(
		_portrait,
		"modulate:a",
		1.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(
		self,
		"modulate:a",
		1.0,
		fade_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_transition_tween.finished.connect(
		_finish_customer_spawn.bind(customer)
	)
	return true


func try_accept_draggable(draggable, global_pointer: Vector2) -> bool:
	if not _can_interact_with_customer() or not _is_pointer_inside_drop_region(global_pointer):
		return false
	var description := _describe_supported_item(draggable)
	if description.is_empty():
		return false
	_notify_item_given(description)
	return true


func update_draggable_hover(draggable, global_pointer: Vector2) -> void:
	var can_drop := (
		_can_interact_with_customer()
		and _is_pointer_inside_drop_region(global_pointer)
		and not _describe_supported_item(draggable).is_empty()
	)
	_set_transfer_cursor(can_drop)


func clear_draggable_hover() -> void:
	_set_transfer_cursor(false)


func say(text: String, duration: float = -1.0) -> bool:
	var replica := text.strip_edges()
	if (
		replica.is_empty()
		or not _can_interact_with_customer()
		or _speech_bubble == null
		or _speech_label == null
	):
		return false
	_speech_label.text = replica
	_speech_bubble.visible = true
	if _speech_timer != null:
		var visible_duration := duration if duration > 0.0 else default_replica_duration
		_speech_timer.start(visible_duration)
	replica_spoken.emit(replica)
	return true


func _register_as_drop_receiver() -> void:
	if not is_instance_valid(_drag_surface):
		push_error("CustomerManager requires a valid drag_surface_path.")
		return
	if not _drag_surface.has_method("register_drop_receiver"):
		push_error("CustomerManager drag surface does not support drop receivers.")
		return
	_drag_surface.call("register_drop_receiver", self)


func _can_interact_with_customer() -> bool:
	return _customer_present and not _transitioning


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
		var card := (target as DraggableCard).get_card_data()
		if card == null:
			return ""
		return "card #%d \"%s\" (%s, %s)" % [
			card.id,
			card.name,
			card.series,
			card.get_literal_name(),
		]
	if target is DraggableReceipt:
		var receipt := target as DraggableReceipt
		return "%s receipt for $%d" % [
			str(receipt.get_receipt_type()),
			receipt.get_amount(),
		]
	return ""


func _apply_portrait_texture(portrait_number: int) -> bool:
	if _portrait == null:
		return false
	var portrait_resource_path := PORTRAIT_PATH_TEMPLATE % portrait_number
	if not ResourceLoader.exists(portrait_resource_path):
		return false
	var portrait_texture := load(portrait_resource_path) as Texture2D
	if portrait_texture == null:
		return false
	_portrait.texture = portrait_texture
	return true


func _notify_item_given(description: String) -> void:
	item_given.emit(description)


func _log_given_item(description: String) -> void:
	var console_message := CONSOLE_MESSAGE_PREFIX + description
	print(console_message)
	get_tree().call_group(DEV_CONSOLE_GROUP, "write_external_line", console_message)


func _set_transfer_cursor(enabled: bool) -> void:
	if _shows_transfer_cursor == enabled:
		return
	_shows_transfer_cursor = enabled
	Input.set_default_cursor_shape(
		Input.CURSOR_CAN_DROP if enabled else Input.CURSOR_ARROW
	)


func _hide_replica() -> void:
	if _speech_timer != null:
		_speech_timer.stop()
	if _speech_bubble != null:
		_speech_bubble.visible = false


func _finish_customer_exit(departing_customer: CustomerData) -> void:
	_transition_tween = null
	_transitioning = false
	_customer_present = false
	_current_customer = null
	if _portrait != null:
		_portrait.visible = false
	visible = false
	customer_dialogue_ended.emit(departing_customer)


func _finish_customer_spawn(customer: CustomerData) -> void:
	_transition_tween = null
	_transitioning = false
	_customer_present = true
	customer_spawned.emit(customer)
