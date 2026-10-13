extends Node


const POPUP_SCENE := preload("res://scenes/ui/card_instance_popup.tscn")
const HOVER_DELAY := 1.5

static var _active_inspector: Node

var popup: CardInstancePopup
var _card_node: DraggableCard
var _draggable: UIDraggable
var _hover_elapsed := 0.0
var _pointer := Vector2.ZERO
var _has_pointer := false
var _popup_refresh_elapsed := 0.0
var _shown_properties: Dictionary = {}
var _window_focused := true


func _ready() -> void:
	_card_node = get_parent() as DraggableCard
	_draggable = _card_node.get_node("UIDraggable") as UIDraggable
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	popup = POPUP_SCENE.instantiate() as CardInstancePopup
	layer.add_child(popup)
	get_window().focus_exited.connect(_on_focus_exited)
	get_window().focus_entered.connect(_on_focus_entered)
	for console in get_tree().get_nodes_in_group(&"dev_console"):
		console.visibility_changed.connect(_reset_hover)


func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		_pointer = event.position
		_has_pointer = true
		if not _card_node.get_global_rect().has_point(_pointer) and not (popup.visible and popup.get_global_rect().has_point(_pointer)):
			_reset_hover()
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if popup.visible and popup.get_global_rect().has_point(button.position):
			if button.pressed and button.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				popup.scroll_by(-1 if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			# Surfaces handle input before GUI controls; consume popup clicks here.
			get_viewport().set_input_as_handled()
		elif button.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			_reset_hover()


func _process(delta: float) -> void:
	if not _has_pointer:
		_pointer = _card_node.get_viewport().get_mouse_position()
	if not _is_eligible():
		_reset_hover()
		return
	if is_instance_valid(_active_inspector) and _active_inspector != self and _active_inspector.popup.visible and _active_inspector.popup.get_global_rect().has_point(_pointer):
		_reset_hover()
		return
	if popup.visible and popup.get_global_rect().has_point(_pointer):
		return
	var surface := _card_node.get_parent()
	if not _card_node.get_global_rect().has_point(_pointer) or surface.get_top_draggable_at(_pointer) != _draggable:
		_reset_hover()
		return
	_hover_elapsed += delta
	if _hover_elapsed >= HOVER_DELAY and not popup.visible:
		if is_instance_valid(_active_inspector) and _active_inspector != self:
			_active_inspector._reset_hover()
		_active_inspector = self
		_shown_properties = _card_node.card_data.to_dictionary()
		popup.display_card(_card_node.card_data)
		popup.show()
		call_deferred("_place_popup")
	if popup.visible:
		_popup_refresh_elapsed += delta
		if _popup_refresh_elapsed >= 0.5:
			_popup_refresh_elapsed = 0.0
			var properties := _card_node.card_data.to_dictionary()
			if properties != _shown_properties:
				_shown_properties = properties
				var scroll_position := popup.scroll.scroll_vertical
				popup.display_card(_card_node.card_data)
				popup.scroll.scroll_vertical = scroll_position
				call_deferred("_place_popup")


func _is_eligible() -> bool:
	if not _window_focused or _card_node.card_data == null or _card_node.current_space != &"desk" or not _card_node.is_visible_in_tree():
		return false
	var surface := _card_node.get_parent()
	return (
		surface is UIDragSurface and surface.space_name == &"desk"
		and surface.is_processing_input() and _draggable.enabled
		and not surface.has_active_drag() and not _card_node.card_visual.is_flipping()
		and _card_node.global_position.distance_squared_to(_draggable.get_desired_global_position()) < 1.0
	)


func _place_popup() -> void:
	if not popup.visible:
		return
	var viewport_size := _card_node.get_viewport_rect().size
	popup.fit_to_viewport(viewport_size)
	var card_rect := _card_node.get_global_rect()
	var x := card_rect.end.x + 12.0
	if x + popup.size.x > viewport_size.x - 16.0:
		x = card_rect.position.x - popup.size.x - 12.0
	popup.position = Vector2(
		clampf(x, 16.0, maxf(16.0, viewport_size.x - popup.size.x - 16.0)),
		clampf(card_rect.position.y, 16.0, maxf(16.0, viewport_size.y - popup.size.y - 16.0))
	)


func _reset_hover() -> void:
	_hover_elapsed = 0.0
	_popup_refresh_elapsed = 0.0
	if popup != null:
		popup.hide()
	if _active_inspector == self:
		_active_inspector = null


func _exit_tree() -> void:
	if _active_inspector == self:
		_active_inspector = null


func _on_focus_exited() -> void:
	_window_focused = false
	_reset_hover()


func _on_focus_entered() -> void:
	_window_focused = true
	_has_pointer = false
