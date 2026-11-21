extends Control


const NIGHT_SCENE := preload("res://scenes/ui/night_supply.tscn")

@onready var shop_view: Control = $ShopView
@onready var desk: TradingDesk = $TradingDesk
@onready var console: DevConsole = $DevConsole

var _storage_binder: CardBinder
var _day_label: Label
var _close_button: Button
var _night: Control


func _ready() -> void:
	# Cache the shelf's existing binder before it can be moved to another surface.
	_storage_binder = desk.lower_shelf.get_node("SecondCardBinder") as CardBinder
	var layer := CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	var toolbar := HBoxContainer.new()
	toolbar.position = Vector2(20, 16)
	toolbar.add_theme_constant_override("separation", 24)
	layer.add_child(toolbar)
	_day_label = Label.new()
	_day_label.add_theme_font_size_override("font_size", 24)
	toolbar.add_child(_day_label)
	_close_button = Button.new()
	_close_button.text = "Закрыть магазин"
	_close_button.custom_minimum_size = Vector2(230, 48)
	_close_button.pressed.connect(close_shop)
	toolbar.add_child(_close_button)
	_night = NIGHT_SCENE.instantiate()
	layer.add_child(_night)
	_night.next_day_requested.connect(start_next_day)
	_night.hide()
	_refresh_day()


func close_shop() -> void:
	if not GameState.day_cycle.close_shop():
		return
	console.set_console_open(false)
	desk.drag_surface.cancel_active_drag()
	desk.counter_surface.cancel_active_drag()
	shop_view.hide()
	desk.hide()
	shop_view.process_mode = Node.PROCESS_MODE_DISABLED
	desk.process_mode = Node.PROCESS_MODE_DISABLED
	_close_button.hide()
	_night.show()
	_night.refresh()


func start_next_day() -> void:
	var delivered := GameState.day_cycle.pending_orders.size()
	if not GameState.day_cycle.start_next_day(_storage_binder.get_collection()):
		return
	_storage_binder.refresh_storage()
	_night.hide()
	shop_view.process_mode = Node.PROCESS_MODE_INHERIT
	desk.process_mode = Node.PROCESS_MODE_INHERIT
	shop_view.show()
	desk.show()
	_close_button.show()
	_refresh_day()
	if delivered > 0:
		_day_label.text += " · Доставлено в подстольный альбом: %d" % delivered


func _refresh_day() -> void:
	_day_label.text = "День %d" % GameState.day_cycle.day
