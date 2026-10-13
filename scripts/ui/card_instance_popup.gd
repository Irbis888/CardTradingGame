class_name CardInstancePopup
extends PanelContainer


const FONT := preload("res://assets/fonts/at01.ttf")

@onready var title: Label = $Margin/Body/Title
@onready var identity: Label = $Margin/Body/Identity
@onready var scroll: ScrollContainer = $Margin/Body/Scroll
@onready var rows: VBoxContainer = $Margin/Body/Scroll/Rows


func display_card(card: Card) -> void:
	title.text = card.name
	identity.text = "Card #%d  ·  Specimen %s" % [card.id, card.specimen_id]
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	_section("PRINTING & SPECIMEN")
	_row("Printing", "P%d" % card.printing)
	_row("Foil", _yes(card.is_foil))
	_row("Holo", _yes(card.is_holo))
	_row("Art variant", str(card.art_variant))
	_row("Special features", _list(card.special_features))
	_row("Serial number", str(card.serial_number) if card.serial_number > 0 else "None")
	_row("Serial total", str(card.serial_total) if card.serial_total > 0 else "None")
	_row("Signatures", _list(card.signatures))
	_row("Extra stamps", _list(card.extra_stamps))
	var errors: Array[String] = []
	for misprint in card.misprints:
		var details: Array[String] = []
		for field in misprint:
			if field != "type":
				details.append("%s: %s" % [str(field).capitalize(), str(misprint[field])])
		errors.append("%s · %s" % [misprint.get("type", "other"), ", ".join(details)])
	_row("Misprints", _list(errors))
	var condition := card.condition
	_section("PHYSICAL CONDITION")
	_row("Wear", _severity(condition.wear))
	_row("Scratches", _severity(condition.scratches))
	_row("Crease", _yes(condition.crease))
	_row("Surface damage", _yes(condition.surface_damage))
	_section("AUTHENTICITY & ORIGIN")
	_row("Factory stamp", CardCondition.FactoryStampState.keys()[condition.factory_stamp].capitalize())
	_row("Edge perforation", CardCondition.EdgePerforationState.keys()[condition.edge_perforation].capitalize())
	_row("Factory authentic", _yes(condition.is_factory_authentic()))
	_row("Origin", CardCondition.OriginType.keys()[condition.origin].capitalize())
	_row("Verification hole", _yes(condition.conjuration_verification_hole))
	_row("Glass halo", _yes(condition.origin == CardCondition.OriginType.CONJURED))


func fit_to_viewport(viewport_size: Vector2) -> void:
	var height := rows.get_combined_minimum_size().y + 115.0
	size = Vector2(minf(470.0, viewport_size.x - 32.0), minf(height, minf(760.0, viewport_size.y - 32.0)))


func scroll_by(direction: int) -> void:
	scroll.scroll_vertical += direction * 72


func _section(text: String) -> void:
	var label := _label(text, 17)
	label.add_theme_color_override("font_color", Color(0.5, 0.34, 0.16))
	label.custom_minimum_size.y = 34.0
	rows.add_child(label)


func _row(field: String, value: String) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	rows.add_child(row)
	var key := _label(field, 17)
	key.custom_minimum_size.x = 180.0
	key.custom_maximum_size.x = 180.0
	key.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(key)
	var entry := _label(value, 17)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	entry.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(entry)


func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.18, 0.15, 0.11))
	return label


func _list(values: Array[String]) -> String:
	return "\n".join(values) if not values.is_empty() else "None"


func _yes(value: bool) -> String:
	return "Yes" if value else "No"


func _severity(value: int) -> String:
	return "%d/3 · %s" % [value, ["None", "Light", "Noticeable", "Severe"][value]]
