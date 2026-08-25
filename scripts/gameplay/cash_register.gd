class_name CashRegister
extends "res://scripts/ui/drag_drop/dual_space_draggable.gd"


const DRAGGABLE_RECEIPT_SCENE := preload("res://scenes/ui/draggable_receipt.tscn")
const MAX_DIGITS := 9

@onready var desk_amount_label: Label = $DeskView/Body/Screen/AmountLabel
@onready var counter_amount_label: Label = $CounterView/AmountLabel
@onready var receipt_slot: Control = $DeskView/Body/ReceiptSlot
@onready var draggable_component: UIDraggable = $UIDraggable

@onready var digit_buttons: Array[Button] = [
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit0,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit1,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit2,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit3,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit4,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit5,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit6,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit7,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit8,
	$DeskView/KeyboardDrawer/KeyboardSurface/Digit9,
]
@onready var backspace_button: Button = $DeskView/KeyboardDrawer/KeyboardSurface/BackspaceButton
@onready var ask_button: Button = $DeskView/KeyboardDrawer/KeyboardSurface/AskButton
@onready var offer_button: Button = $DeskView/KeyboardDrawer/KeyboardSurface/OfferButton

var _amount_digits := ""


func _ready() -> void:
	super()
	_connect_controls()
	_configure_interactive_controls()
	_refresh_amount()


func set_drag_space(space_name: StringName) -> void:
	super(space_name)
	if is_node_ready():
		_configure_interactive_controls()


func can_start_drag_at(global_point: Vector2) -> bool:
	if current_space != &"desk":
		return true
	for button in _get_interactive_buttons():
		if button.is_visible_in_tree() and button.get_global_rect().has_point(global_point):
			return false
	return true


func get_amount() -> int:
	return _amount_digits.to_int() if not _amount_digits.is_empty() else 0


func get_amount_digits() -> String:
	return _amount_digits


func _connect_controls() -> void:
	for button in digit_buttons:
		button.pressed.connect(_append_digit.bind(button.text))
	backspace_button.pressed.connect(_erase_last_digit)
	ask_button.pressed.connect(_print_receipt.bind(&"ASK"))
	offer_button.pressed.connect(_print_receipt.bind(&"OFFER"))


func _configure_interactive_controls() -> void:
	var mouse_mode := Control.MOUSE_FILTER_STOP if current_space == &"desk" else Control.MOUSE_FILTER_IGNORE
	for button in _get_interactive_buttons():
		button.mouse_filter = mouse_mode


func _get_interactive_buttons() -> Array[Button]:
	var buttons := digit_buttons.duplicate()
	buttons.append(backspace_button)
	buttons.append(ask_button)
	buttons.append(offer_button)
	return buttons


func _append_digit(digit: String) -> void:
	if _amount_digits.length() >= MAX_DIGITS:
		return
	if _amount_digits == "0":
		_amount_digits = digit
	elif digit == "0" and _amount_digits.is_empty():
		_amount_digits = "0"
	else:
		_amount_digits += digit
	_refresh_amount()


func _erase_last_digit() -> void:
	if _amount_digits.is_empty():
		return
	_amount_digits = _amount_digits.left(_amount_digits.length() - 1)
	_refresh_amount()


func _refresh_amount() -> void:
	var amount_text := "$%d" % get_amount()
	desk_amount_label.text = amount_text
	counter_amount_label.text = amount_text
	set_item_payload({
		"amount": get_amount(),
		"digits": _amount_digits,
	})


func _print_receipt(receipt_type: StringName) -> void:
	if current_space != &"desk" or get_amount() <= 0:
		return
	var surface := draggable_component.get_surface_reference() as Control
	if surface == null or not surface.has_method("register_draggable"):
		push_warning("Cash register cannot print without a drag surface.")
		return

	var receipt := DRAGGABLE_RECEIPT_SCENE.instantiate() as DraggableReceipt
	receipt.z_index = _get_next_z_index(surface)
	surface.add_child(receipt)
	receipt.setup_receipt(receipt_type, get_amount())
	receipt.global_position = _get_receipt_spawn_position(receipt)
	var receipt_draggable := receipt.get_node_or_null("UIDraggable") as UIDraggable
	if receipt_draggable != null:
		receipt_draggable.synchronize_position()
	_amount_digits = ""
	_refresh_amount()
	


func _get_receipt_spawn_position(receipt: Control) -> Vector2:
	var slot_rect := receipt_slot.get_global_rect()
	return Vector2(
		slot_rect.get_center().x - receipt.size.x * 0.5,
		slot_rect.position.y - receipt.size.y + 18.0
	)


func _get_next_z_index(surface: Control) -> int:
	var highest_z_index := z_index
	for child in surface.get_children():
		if child is Control:
			highest_z_index = maxi(highest_z_index, (child as Control).z_index)
	return highest_z_index + 1
