class_name CardCatalog
extends "res://scripts/ui/drag_drop/dual_space_draggable.gd"


const ENTRIES_PER_PAGE := 12
const CATALOG_FONT := preload("res://assets/fonts/at01.ttf")

@onready var previous_button: Button = $DeskView/PreviousButton
@onready var next_button: Button = $DeskView/NextButton
@onready var page_label: Label = $DeskView/PageLabel
@onready var entries_grid: GridContainer = $DeskView/EntriesGrid

var _cards: Array[Card] = []
var _current_page := 0


func _ready() -> void:
	super()
	_cards = Globals.get_cards()
	previous_button.pressed.connect(_show_previous_page)
	next_button.pressed.connect(_show_next_page)
	_configure_interactive_controls()
	set_item_payload(_cards)
	_refresh_page()


func set_drag_space(space_name: StringName) -> void:
	super(space_name)
	if is_node_ready():
		_configure_interactive_controls()


func can_start_drag_at(global_point: Vector2) -> bool:
	if current_space != &"desk":
		return true
	for button in [previous_button, next_button]:
		if button.is_visible_in_tree() and button.get_global_rect().has_point(global_point):
			return false
	return true


func _show_previous_page() -> void:
	if _current_page <= 0:
		return
	_current_page -= 1
	_refresh_page()


func _show_next_page() -> void:
	if _current_page >= _get_page_count() - 1:
		return
	_current_page += 1
	_refresh_page()


func _refresh_page() -> void:
	var page_count := _get_page_count()
	_current_page = clampi(_current_page, 0, page_count - 1)
	page_label.text = "%d / %d" % [_current_page + 1, page_count]
	previous_button.disabled = _current_page == 0
	next_button.disabled = _current_page == page_count - 1

	for child in entries_grid.get_children():
		entries_grid.remove_child(child)
		child.queue_free()

	var first_index := _current_page * ENTRIES_PER_PAGE
	var last_index := mini(first_index + ENTRIES_PER_PAGE, _cards.size())
	for card_index in range(first_index, last_index):
		_add_card_entry(_cards[card_index])


func _add_card_entry(card: Card) -> void:
	var name_label := Label.new()
	name_label.text = card.name
	name_label.custom_minimum_size = Vector2(170.0, 24.0)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_override("font", CATALOG_FONT)
	name_label.add_theme_color_override("font_color", Color(0.19, 0.14, 0.08))
	entries_grid.add_child(name_label)

	var price_label := Label.new()
	price_label.text = "$%d" % card.base_price
	price_label.custom_minimum_size = Vector2(55.0, 24.0)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_label.add_theme_font_override("font", CATALOG_FONT)
	price_label.add_theme_color_override("font_color", Color(0.12, 0.1, 0.07))
	entries_grid.add_child(price_label)


func _get_page_count() -> int:
	return maxi(1, ceili(float(_cards.size()) / float(ENTRIES_PER_PAGE)))


func _configure_interactive_controls() -> void:
	var mouse_mode := (
		Control.MOUSE_FILTER_STOP
		if current_space == &"desk"
		else Control.MOUSE_FILTER_IGNORE
	)
	previous_button.mouse_filter = mouse_mode
	next_button.mouse_filter = mouse_mode
