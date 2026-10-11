extends Control


signal side_changed(back_visible: bool)

const PLACEHOLDER_DESCRIPTION := "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua."
const INK := Color(0.18, 0.15, 0.11)

@export_range(0.1, 1.0, 0.05) var flip_duration := 0.28

@onready var faces: Control = $Faces
@onready var front: Control = $Faces/Front
@onready var back: Control = $Faces/Back
@onready var portrait: TextureRect = $Faces/Front/Portrait
@onready var front_name: Label = $Faces/Front/NameLabel
@onready var back_name: Label = $Faces/Back/NameLabel
@onready var description_label: Label = $Faces/Back/Content/Body/Description
@onready var trivia_rows: VBoxContainer = $Faces/Back/Content/Body/TriviaRows
@onready var series_label: Label = $Faces/Back/SeriesLabel
@onready var flip_button: Button = $FlipButton
@onready var content: ScrollContainer = $Faces/Back/Content

var is_back := false
var _flip_tween: Tween


func _ready() -> void:
	flip_button.pressed.connect(flip)
	resized.connect(_update_pivot)
	_update_pivot()
	_apply_side()


func _exit_tree() -> void:
	if _flip_tween != null:
		_flip_tween.kill()


func init(card: Card) -> void:
	portrait.texture = card.picture as Texture2D
	front_name.text = card.name
	_update_name_plate()
	back_name.text = card.name
	description_label.text = card.description if not card.description.is_empty() else PLACEHOLDER_DESCRIPTION
	series_label.text = card.series
	content.scroll_vertical = 0
	for child in trivia_rows.get_children():
		trivia_rows.remove_child(child)
		child.queue_free()
	for field in card.trivia:
		_add_trivia_row(str(field), str(card.trivia[field]))


func set_interactive(enabled: bool) -> void:
	flip_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	flip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	content.mouse_filter = Control.MOUSE_FILTER_PASS if enabled else Control.MOUSE_FILTER_IGNORE
	content.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func can_flip_at(global_point: Vector2) -> bool:
	return flip_button.is_visible_in_tree() and flip_button.get_global_rect().has_point(global_point)


func is_flipping() -> bool:
	return _flip_tween != null


func can_scroll_at(global_point: Vector2) -> bool:
	var scroll_bar := content.get_v_scroll_bar()
	return is_back and scroll_bar.is_visible_in_tree() and scroll_bar.get_global_rect().has_point(global_point)


func scroll_details(direction: int) -> void:
	if is_back:
		content.scroll_vertical += direction * 60


func flip() -> void:
	set_back_visible(not is_back, true)


func set_back_visible(value: bool, animated: bool = false) -> void:
	if _flip_tween != null or value == is_back:
		return
	if not animated:
		_change_side(value)
		return
	flip_button.disabled = true
	_flip_tween = create_tween()
	_flip_tween.tween_property(faces, "scale:x", 0.0, flip_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_flip_tween.tween_callback(_change_side.bind(value))
	_flip_tween.tween_property(faces, "scale:x", 1.0, flip_duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_flip_tween.finished.connect(_finish_flip)


func _change_side(value: bool) -> void:
	is_back = value
	_apply_side()
	side_changed.emit(is_back)


func _apply_side() -> void:
	front.visible = not is_back
	back.visible = is_back
	flip_button.tooltip_text = "Show portrait" if is_back else "Read the card"


func _finish_flip() -> void:
	_flip_tween = null
	flip_button.disabled = false


func _update_pivot() -> void:
	faces.pivot_offset = size * 0.5
	_update_name_plate()


func _update_name_plate() -> void:
	var font := front_name.get_theme_font("font")
	var font_size := front_name.get_theme_font_size("font_size")
	var title_width := font.get_string_size(front_name.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var plate_width := minf(title_width + 32.0, size.x - 40.0)
	front_name.offset_left = (size.x - plate_width) * 0.5
	front_name.offset_right = front_name.offset_left + plate_width


func _add_trivia_row(field: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	trivia_rows.add_child(row)
	var field_label := _make_trivia_label(field)
	field_label.custom_minimum_size.x = 190.0
	field_label.custom_maximum_size.x = 190.0
	field_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(field_label)
	var leader := _make_trivia_label("········································")
	leader.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	leader.clip_text = true
	row.add_child(leader)
	var value_label := _make_trivia_label(value)
	value_label.custom_minimum_size.x = 220.0
	value_label.custom_maximum_size.x = 220.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(value_label)


func _make_trivia_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", INK)
	return label
