class_name CardBinder
extends "res://scripts/ui/drag_drop/dual_space_draggable.gd"


const SLOTS_PER_PAGE := 6
const CARD_PREVIEW_SIZE := Vector2(550.0, 800.0)
const DROP_DISTANCE_FROM_CENTER_FRACTION := 0.5
const HOVERED_SLOT_MODULATE := Color(0.82, 0.82, 0.82, 1.0)
const NORMAL_SLOT_MODULATE := Color.WHITE
const DRAGGABLE_CARD_SCENE := preload("res://scenes/ui/draggable_card.tscn")
const CARD_VIEW_SCENE := preload("res://scenes/ui/card_view.tscn")

@export_range(1, 24, 1) var page_count := 3
@export var initial_card_ids: Array[int] = [8, 16, 24, 9, 17, 25, 10, 18, 26]

@onready var previous_button: Button = $DeskView/PreviousButton
@onready var next_button: Button = $DeskView/NextButton
@onready var page_label: Label = $DeskView/PageLabel
@onready var counter_count_label: Label = $CounterView/CardCountLabel
@onready var draggable_component: UIDraggable = $UIDraggable

@onready var _slot_panels: Array[Control] = [
	$DeskView/Slot1,
	$DeskView/Slot2,
	$DeskView/Slot3,
	$DeskView/Slot4,
	$DeskView/Slot5,
	$DeskView/Slot6,
]
@onready var _preview_hosts: Array[Control] = [
	$DeskView/Slot1/PreviewHost,
	$DeskView/Slot2/PreviewHost,
	$DeskView/Slot3/PreviewHost,
	$DeskView/Slot4/PreviewHost,
	$DeskView/Slot5/PreviewHost,
	$DeskView/Slot6/PreviewHost,
]
@onready var _empty_labels: Array[Label] = [
	$DeskView/Slot1/EmptyLabel,
	$DeskView/Slot2/EmptyLabel,
	$DeskView/Slot3/EmptyLabel,
	$DeskView/Slot4/EmptyLabel,
	$DeskView/Slot5/EmptyLabel,
	$DeskView/Slot6/EmptyLabel,
]
@onready var _slot_buttons: Array[Button] = [
	$DeskView/Slot1/SlotButton,
	$DeskView/Slot2/SlotButton,
	$DeskView/Slot3/SlotButton,
	$DeskView/Slot4/SlotButton,
	$DeskView/Slot5/SlotButton,
	$DeskView/Slot6/SlotButton,
]

var _slot_cards: Array[Card] = []
var _current_page := 0
var _registered_surface: Node
var _hovered_slot := -1


func _ready() -> void:
	super()
	_connect_controls()
	_initialize_card_slots()
	_configure_interactive_controls()
	_register_as_drop_receiver()
	_refresh_page()


func _exit_tree() -> void:
	_unregister_as_drop_receiver()


func set_drag_space(space_name: StringName) -> void:
	super(space_name)
	if not is_node_ready():
		return
	if current_space != &"desk":
		clear_draggable_hover()
	_configure_interactive_controls()
	_register_as_drop_receiver()


func can_start_drag_at(global_point: Vector2) -> bool:
	if current_space != &"desk":
		return true
	for slot_button in _slot_buttons:
		if slot_button.is_visible_in_tree() and slot_button.get_global_rect().has_point(global_point):
			return false
	for page_button in [previous_button, next_button]:
		if page_button.is_visible_in_tree() and page_button.get_global_rect().has_point(global_point):
			return false
	return true


func try_accept_draggable(draggable, global_pointer: Vector2) -> bool:
	if current_space != &"desk":
		return false
	var card_node := draggable.get_target() as DraggableCard
	if card_node == null or card_node == self or card_node.get_card_data() == null:
		return false

	var local_slot := _find_empty_drop_slot(global_pointer)
	if local_slot < 0:
		return false

	var storage_index := _current_page * SLOTS_PER_PAGE + local_slot
	_slot_cards[storage_index] = card_node.get_card_data()
	_refresh_page()
	return true


func update_draggable_hover(draggable, global_pointer: Vector2) -> void:
	var hovered_slot := -1
	if current_space == &"desk":
		var card_node := draggable.get_target() as DraggableCard
		if card_node != null and card_node != self and card_node.get_card_data() != null:
			hovered_slot = _find_empty_drop_slot(global_pointer)
	_set_hovered_slot(hovered_slot)


func clear_draggable_hover() -> void:
	_set_hovered_slot(-1)


func get_stored_cards() -> Array[Card]:
	var stored_cards: Array[Card] = []
	for card in _slot_cards:
		if card != null:
			stored_cards.append(card)
	return stored_cards


func get_slot_cards() -> Array[Card]:
	return _slot_cards.duplicate()


func get_current_page() -> int:
	return _current_page


func _connect_controls() -> void:
	previous_button.pressed.connect(_show_previous_page)
	next_button.pressed.connect(_show_next_page)
	for local_slot in range(SLOTS_PER_PAGE):
		_slot_buttons[local_slot].button_down.connect(_extract_card.bind(local_slot))


func _initialize_card_slots() -> void:
	page_count = maxi(page_count, 1)
	_slot_cards.resize(page_count * SLOTS_PER_PAGE)
	var maximum_initial_cards := mini(initial_card_ids.size(), _slot_cards.size() / 2)
	for card_index in range(maximum_initial_cards):
		var card := Globals.get_card_by_id(initial_card_ids[card_index])
		if card != null:
			_slot_cards[card_index * 2] = card
	set_item_payload(_slot_cards)


func _configure_interactive_controls() -> void:
	var mouse_mode := Control.MOUSE_FILTER_STOP if current_space == &"desk" else Control.MOUSE_FILTER_IGNORE
	previous_button.mouse_filter = mouse_mode
	next_button.mouse_filter = mouse_mode
	for slot_button in _slot_buttons:
		slot_button.mouse_filter = mouse_mode


func _register_as_drop_receiver() -> void:
	var current_surface := draggable_component.get_surface_reference()
	if current_surface == _registered_surface:
		return
	_unregister_as_drop_receiver()
	_registered_surface = current_surface
	if is_instance_valid(_registered_surface) and _registered_surface.has_method("register_drop_receiver"):
		_registered_surface.call("register_drop_receiver", self)


func _unregister_as_drop_receiver() -> void:
	if is_instance_valid(_registered_surface) and _registered_surface.has_method("unregister_drop_receiver"):
		_registered_surface.call("unregister_drop_receiver", self)
	_registered_surface = null


func _show_previous_page() -> void:
	if _current_page <= 0:
		return
	clear_draggable_hover()
	_current_page -= 1
	_refresh_page()


func _show_next_page() -> void:
	if _current_page >= page_count - 1:
		return
	clear_draggable_hover()
	_current_page += 1
	_refresh_page()


func _refresh_page() -> void:
	_current_page = clampi(_current_page, 0, page_count - 1)
	page_label.text = "%d / %d" % [_current_page + 1, page_count]
	previous_button.disabled = _current_page == 0
	next_button.disabled = _current_page == page_count - 1

	for local_slot in range(SLOTS_PER_PAGE):
		_clear_preview(_preview_hosts[local_slot])
		var storage_index := _current_page * SLOTS_PER_PAGE + local_slot
		var card := _slot_cards[storage_index]
		_empty_labels[local_slot].visible = card == null
		if card != null:
			_create_card_preview(_preview_hosts[local_slot], _slot_panels[local_slot], card)

	counter_count_label.text = "%d / %d CARDS" % [get_stored_cards().size(), _slot_cards.size()]
	_refresh_slot_hover()


func _clear_preview(preview_host: Control) -> void:
	for child in preview_host.get_children():
		preview_host.remove_child(child)
		child.queue_free()


func _create_card_preview(preview_host: Control, slot_panel: Control, card: Card) -> void:
	var preview := CARD_VIEW_SCENE.instantiate() as Control
	preview_host.add_child(preview)
	preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
	preview.size = CARD_PREVIEW_SIZE
	var available_size := slot_panel.size - Vector2(14.0, 14.0)
	var preview_scale := minf(
		available_size.x / CARD_PREVIEW_SIZE.x,
		available_size.y / CARD_PREVIEW_SIZE.y
	)
	preview.scale = Vector2.ONE * preview_scale
	preview.position = (slot_panel.size - CARD_PREVIEW_SIZE * preview_scale) * 0.5
	_set_mouse_input_ignored(preview)
	preview.call("init", card)


func _set_mouse_input_ignored(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_input_ignored(child)


func _extract_card(local_slot: int) -> void:
	if current_space != &"desk" or not is_instance_valid(_registered_surface):
		return
	if not _registered_surface.has_method("begin_draggable_drag"):
		return

	var storage_index := _current_page * SLOTS_PER_PAGE + local_slot
	var card := _slot_cards[storage_index]
	if card == null:
		return

	var card_instance := DRAGGABLE_CARD_SCENE.instantiate() as DraggableCard
	_registered_surface.add_child(card_instance)
	card_instance.display_card(card)
	var slot_rect := _slot_panels[local_slot].get_global_rect()
	card_instance.global_position = slot_rect.get_center() - card_instance.size * 0.5

	_slot_cards[storage_index] = null
	_refresh_page()
	_registered_surface.call(
		"begin_draggable_drag",
		card_instance.get_node("UIDraggable"),
		get_viewport().get_mouse_position()
	)


func _find_empty_drop_slot(global_pointer: Vector2) -> int:
	for local_slot in range(SLOTS_PER_PAGE):
		var storage_index := _current_page * SLOTS_PER_PAGE + local_slot
		if _slot_cards[storage_index] != null:
			continue
		if _is_pointer_inside_slot_drop_region(_slot_panels[local_slot], global_pointer):
			return local_slot
	return -1


func _is_pointer_inside_slot_drop_region(slot: Control, global_pointer: Vector2) -> bool:
	var slot_rect := slot.get_global_rect()
	var distance_from_center := (global_pointer - slot_rect.get_center()).abs()
	var maximum_distance := (
		slot_rect.size * 0.5 * DROP_DISTANCE_FROM_CENTER_FRACTION
	)
	return (
		distance_from_center.x <= maximum_distance.x
		and distance_from_center.y <= maximum_distance.y
	)


func _set_hovered_slot(local_slot: int) -> void:
	if _hovered_slot == local_slot:
		return
	_hovered_slot = local_slot
	_refresh_slot_hover()


func _refresh_slot_hover() -> void:
	if not is_node_ready():
		return
	for local_slot in range(SLOTS_PER_PAGE):
		var storage_index := _current_page * SLOTS_PER_PAGE + local_slot
		var is_empty := _slot_cards[storage_index] == null
		_slot_panels[local_slot].self_modulate = (
			HOVERED_SLOT_MODULATE
			if is_empty and local_slot == _hovered_slot
			else NORMAL_SLOT_MODULATE
		)
