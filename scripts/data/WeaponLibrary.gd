extends Node
class_name WeaponLibrary

const WEAPON_DATA_PATH := "res://data/weapons/weapons.slice.json"

static func load_barbarian_weapons() -> Array[Dictionary]:
	var file := FileAccess.open(WEAPON_DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("Unable to open weapon slice data at %s" % WEAPON_DATA_PATH)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or !parsed.has("weapons"):
		push_error("Weapon slice JSON malformed.")
		return []
	var source_weapons: Array = parsed["weapons"]
	var result: Array[Dictionary] = []
	for weapon_variant in source_weapons:
		if typeof(weapon_variant) != TYPE_DICTIONARY:
			continue
		var weapon: Dictionary = weapon_variant
		var class_tags: Array = weapon.get("class_tags", [])
		if class_tags.has("barbarian") and weapon.has("startup_ms"):
			result.append(weapon)
	return result
