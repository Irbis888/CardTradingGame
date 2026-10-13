class_name Card
extends RefCounted


var definition: CardDefinition
var specimen_id: String
var condition: CardCondition

var printing := 1:
	set(value):
		printing = clampi(value, 1, 3)
var is_foil := false
var is_holo := false
var art_variant: StringName = &"standard"
var special_features: Array[String] = []
var serial_number := 0
var serial_total := 0
var signatures: Array[String] = []
var extra_stamps: Array[String] = []
# Text misprints: {"type": "name" or "biography", "text": "printed text"}.
# Visual misprints use other type values and remain metadata for now.
var misprints: Array[Dictionary] = []

var id: int:
	get:
		return definition.id
var name: String:
	get:
		return definition.name
var rarity: int:
	get:
		return definition.rarity
var series: String:
	get:
		return definition.series
var picture: Texture2D:
	get:
		return definition.picture
var description: String:
	get:
		return definition.description
var trivia: Dictionary:
	get:
		return definition.trivia


func _init(card_definition: CardDefinition, properties: Dictionary = {}) -> void:
	definition = card_definition
	specimen_id = str(properties.get("specimen_id", ""))
	if specimen_id.is_empty():
		specimen_id = Crypto.new().generate_random_bytes(16).hex_encode()
	var condition_data = properties.get("condition", {})
	condition = CardCondition.new(condition_data if condition_data is Dictionary else {})
	printing = int(properties.get("printing", 1))
	is_foil = bool(properties.get("is_foil", false))
	is_holo = bool(properties.get("is_holo", false))
	art_variant = StringName(str(properties.get("art_variant", "standard")))
	special_features = _strings(properties.get("special_features", []))
	serial_total = maxi(0, int(properties.get("serial_total", 0)))
	serial_number = int(properties.get("serial_number", 0))
	if serial_number <= 0 or serial_number > serial_total:
		serial_number = 0
		serial_total = 0
	signatures = _strings(properties.get("signatures", []))
	extra_stamps = _strings(properties.get("extra_stamps", []))
	var print_errors = properties.get("misprints", [])
	if print_errors is Array:
		for entry in print_errors:
			if entry is Dictionary:
				if str(entry.get("type", "")) in ["factory_stamp", "edge_perforation"]:
					push_warning("Factory authenticity signs belong to CardCondition, not misprints.")
					continue
				misprints.append(entry.duplicate(true))
			else:
				misprints.append({"type": "other", "description": str(entry)})


func get_literal_name() -> String:
	return definition.get_literal_name()


func get_price() -> int:
	return definition.get_price()


func get_printed_name() -> String:
	return _printed_text("name", name)


func get_printed_description() -> String:
	return _printed_text("biography", description)


func get_serial_text() -> String:
	return "%d/%d" % [serial_number, serial_total] if serial_number > 0 and serial_total > 0 else ""


func to_dictionary() -> Dictionary:
	return {
		"card_id": id, "specimen_id": specimen_id, "condition": condition.to_dictionary(),
		"printing": printing, "is_foil": is_foil, "is_holo": is_holo,
		"art_variant": str(art_variant), "special_features": special_features.duplicate(),
		"serial_number": serial_number, "serial_total": serial_total,
		"signatures": signatures.duplicate(), "extra_stamps": extra_stamps.duplicate(),
		"misprints": misprints.duplicate(true),
	}


func _printed_text(kind: String, original: String) -> String:
	for misprint in misprints:
		if str(misprint.get("type", "")) == kind and misprint.has("text"):
			return str(misprint["text"])
	return original


static func _strings(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for entry in value:
			result.append(str(entry))
	return result
