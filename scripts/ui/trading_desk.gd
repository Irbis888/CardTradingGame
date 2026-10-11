class_name TradingDesk
extends Control


# Coordinates the trading screen's focused UI components.


@onready var card_binder: CardBinder = $DragSurface/CardBinder
@onready var card_catalog: CardCatalog = $DragSurface/CardCatalog
@onready var cash_register: CashRegister = $DragSurface/CashRegister
@onready var customer_manager: CustomerManager = $VisitorArea/CustomerManager
@onready var visitor_area: Control = $VisitorArea
@onready var counter_surface: UIDragSurface = $CounterSurface
@onready var drag_surface: UIDragSurface = $DragSurface
@onready var lower_shelf: LowerShelf = $CounterSurface/LowerShelf
@onready var lower_shelf_hover_strip: Control = $LowerShelfHoverStrip

var _shelf_open := false


func _ready() -> void:
	lower_shelf_hover_strip.mouse_entered.connect(_show_lower_shelf)
	lower_shelf.return_to_counter_requested.connect(_show_customer_area)
	lower_shelf.slide_finished.connect(_on_shelf_slide_finished)
	lower_shelf.set_shelf_active(false, false)


func get_card_binder() -> CardBinder:
	return card_binder


func get_card_catalog() -> CardCatalog:
	return card_catalog


func get_cash_register() -> CashRegister:
	return cash_register


func get_customer_manager() -> CustomerManager:
	return customer_manager


func _show_lower_shelf() -> void:
	if _shelf_open or lower_shelf.is_sliding():
		return
	_shelf_open = true
	counter_surface.set_gravity_active(false)
	_transfer_held_item(drag_surface, counter_surface, &"right")
	visitor_area.visible = true
	lower_shelf.set_shelf_active(true)


func _show_customer_area() -> void:
	if not _shelf_open or lower_shelf.is_sliding():
		return
	_shelf_open = false
	lower_shelf.release_held_item(counter_surface.get_active_draggable())
	_transfer_held_item(counter_surface, drag_surface, &"left")
	visitor_area.visible = true
	lower_shelf.set_shelf_active(false)


func _on_shelf_slide_finished(active: bool) -> void:
	counter_surface.set_gravity_active(not active)
	visitor_area.visible = not active


func _transfer_held_item(
	from_surface: UIDragSurface,
	to_surface: UIDragSurface,
	entry_side: StringName
) -> void:
	if not from_surface.has_active_drag():
		return
	from_surface.transfer_active_draggable_to(
		to_surface,
		get_viewport().get_mouse_position(),
		entry_side
	)
