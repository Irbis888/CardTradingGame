class_name CardCondition
extends RefCounted


enum FactoryStampState { CORRECT, INCORRECT, MISSING }
enum EdgePerforationState { CORRECT, MISSING }
enum OriginType { PHYSICAL, CONJURED }

var wear: int = 0:
	set(value):
		wear = clampi(value, 0, 3)
var scratches: int = 0:
	set(value):
		scratches = clampi(value, 0, 3)
var crease := false
var surface_damage := false
var factory_stamp: FactoryStampState = FactoryStampState.CORRECT:
	set(value):
		factory_stamp = clampi(value, FactoryStampState.CORRECT, FactoryStampState.MISSING) as FactoryStampState
var edge_perforation: EdgePerforationState = EdgePerforationState.CORRECT:
	set(value):
		edge_perforation = clampi(value, EdgePerforationState.CORRECT, EdgePerforationState.MISSING) as EdgePerforationState
var origin: OriginType = OriginType.PHYSICAL:
	set(value):
		origin = OriginType.PHYSICAL if conjuration_verification_hole else clampi(value, OriginType.PHYSICAL, OriginType.CONJURED) as OriginType
var conjuration_verification_hole := false:
	set(value):
		conjuration_verification_hole = value
		if value:
			origin = OriginType.PHYSICAL


func _init(data: Dictionary = {}) -> void:
	wear = int(data.get("wear", 0))
	scratches = int(data.get("scratches", 0))
	crease = bool(data.get("crease", false))
	surface_damage = bool(data.get("surface_damage", false))
	factory_stamp = _enum_value(data.get("factory_stamp", "CORRECT"), FactoryStampState) as FactoryStampState
	edge_perforation = _enum_value(data.get("edge_perforation", "CORRECT"), EdgePerforationState) as EdgePerforationState
	origin = _enum_value(data.get("origin", "PHYSICAL"), OriginType) as OriginType
	# A verified hole certifies physical origin, even in malformed imported data.
	conjuration_verification_hole = bool(data.get("conjuration_verification_hole", false))


func is_factory_authentic() -> bool:
	return factory_stamp == FactoryStampState.CORRECT and edge_perforation == EdgePerforationState.CORRECT


func inspect_through_glass(rng: RandomNumberGenerator, damage_chance: float = 0.2) -> bool:
	var halo := origin == OriginType.CONJURED
	if rng.randf() < clampf(damage_chance, 0.0, 1.0):
		if rng.randi_range(0, 1) == 0:
			wear += 1
		else:
			scratches += 1
	return halo


func to_dictionary() -> Dictionary:
	return {
		"wear": wear, "scratches": scratches, "crease": crease,
		"surface_damage": surface_damage,
		"factory_stamp": FactoryStampState.keys()[factory_stamp],
		"edge_perforation": EdgePerforationState.keys()[edge_perforation],
		"origin": OriginType.keys()[origin],
		"conjuration_verification_hole": conjuration_verification_hole,
	}


static func _enum_value(value: Variant, values: Dictionary) -> int:
	if value is String:
		return int(values.get(value.to_upper(), 0))
	return clampi(int(value), 0, values.size() - 1)
