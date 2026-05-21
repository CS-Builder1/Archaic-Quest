extends CharacterBody2D
class_name PlayerController

const WEAPON_DATA_PATH := "res://data/weapons/weapons.slice.json"

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.18
@export var dodge_recovery: float = 0.22

@onready var camera: Camera2D = $Camera2D
@onready var input_intent: PlayerInputIntent = $PlayerInputIntent
@onready var stamina_component: StaminaComponent = get_node_or_null("StaminaComponent")
@onready var mana_component: ManaComponent = get_node_or_null("ManaComponent")

var facing_direction: Vector2 = Vector2.RIGHT
var state: String = "IDLE"
var dodge_timer: float = 0.0
var recovery_timer: float = 0.0
var last_move_vector: Vector2 = Vector2.RIGHT

var combat_class: String = "barbarian"
var class_cycle: Array[String] = ["barbarian", "archer", "mage"]
var class_index: int = 0
var class_weapons: Dictionary = {
	"barbarian": ["barbarian_heavy_axe", "barbarian_maul"],
	"archer": ["archer_longbow", "archer_shortbow"],
	"mage": ["mage_fire_staff", "mage_ember_focus"],
}
var weapon_index_by_class: Dictionary = {"barbarian": 0, "archer": 0, "mage": 0}
var weapons_by_id: Dictionary = {}

var attack_phase: String = "idle"
var attack_timer: float = 0.0
var queued_attack_payload: Dictionary = {}
var class_state_label: String = "ready"
var active_areas: Array[Dictionary] = []

func _ready() -> void:
	_load_weapon_data()

func _physics_process(delta: float) -> void:
	input_intent.collect_intent(camera)
	_update_facing()
	_update_state(delta)
	_update_attack_state(delta)
	_update_active_areas(delta)
	move_and_slide()

	if Input.is_action_just_pressed("reload_test_scene"):
		get_tree().reload_current_scene()

func _process(_delta: float) -> void:
	if input_intent.wants_switch_class:
		_switch_class(1)
	if input_intent.wants_switch_weapon:
		_cycle_weapon()

func _update_facing() -> void:
	var to_mouse := input_intent.aim_world_position - global_position
	if to_mouse.length() > 1.0:
		facing_direction = to_mouse.normalized()
		rotation = facing_direction.angle()

func _update_state(delta: float) -> void:
	if state == "DODGING":
		dodge_timer -= delta
		velocity = last_move_vector * dodge_speed
		if dodge_timer <= 0.0:
			state = "RECOVERING"
			recovery_timer = dodge_recovery
		return

	if state == "RECOVERING":
		recovery_timer -= delta
		velocity = input_intent.move_vector * (move_speed * 0.45)
		if recovery_timer <= 0.0:
			state = "IDLE"
		return

	if input_intent.move_vector.length() > 0.01:
		last_move_vector = input_intent.move_vector.normalized()
		velocity = input_intent.move_vector * move_speed
		state = "MOVING"
	else:
		velocity = Vector2.ZERO
		state = "IDLE"

	if input_intent.wants_dodge:
		state = "DODGING"
		dodge_timer = dodge_duration
		velocity = last_move_vector * dodge_speed

func _update_attack_state(delta: float) -> void:
	if attack_phase == "idle":
		if input_intent.wants_primary:
			_start_attack()
		return

	attack_timer -= delta
	if attack_timer > 0.0:
		return

	if attack_phase == "startup":
		attack_phase = "active"
		attack_timer = queued_attack_payload["active_ms"] / 1000.0
		class_state_label = "release"
		_resolve_attack(queued_attack_payload)
		return

	if attack_phase == "active":
		attack_phase = "recovery"
		attack_timer = queued_attack_payload["recovery_ms"] / 1000.0
		class_state_label = "follow_through"
		return

	attack_phase = "idle"
	queued_attack_payload = {}
	class_state_label = "ready"

func _start_attack() -> void:
	if attack_phase != "idle":
		return
	var weapon := get_active_weapon()
	if weapon.is_empty():
		return
	if !_spend_resource_for_weapon(weapon):
		return
	queued_attack_payload = weapon
	attack_phase = "startup"
	attack_timer = weapon["startup_ms"] / 1000.0
	class_state_label = "draw" if combat_class == "archer" else "channel" if combat_class == "mage" else "windup"

func _resolve_attack(weapon: Dictionary) -> void:
	if combat_class == "archer":
		_fire_archer_attack(weapon)
	elif combat_class == "mage":
		_fire_mage_attack(weapon)
	else:
		_fire_barbarian_attack(weapon)

func _fire_barbarian_attack(weapon: Dictionary) -> void:
	var center := global_position + facing_direction * (weapon.get("reach", 2.0) * 32.0)
	_apply_radius_damage(center, weapon.get("reach", 2.0) * 26.0, int(weapon.get("stagger_value", 20)))

func _fire_archer_attack(weapon: Dictionary) -> void:
	class_state_label = "arrow_flight"
	var projectile_distance := weapon.get("reach", 12.0) * 32.0
	var impact_center := global_position + facing_direction * projectile_distance
	var impact_radius := 20.0 if weapon.get("id", "") == "archer_longbow" else 14.0
	var base_damage := 30 if weapon.get("id", "") == "archer_longbow" else 18
	_apply_radius_damage(impact_center, impact_radius, base_damage)

func _fire_mage_attack(weapon: Dictionary) -> void:
	class_state_label = "aoe_bloom"
	var impact_center := global_position + facing_direction * (weapon.get("reach", 7.0) * 24.0)
	var radius := 80.0 if weapon.get("id", "") == "mage_fire_staff" else 52.0
	var base_damage := 20 if weapon.get("id", "") == "mage_fire_staff" else 13
	_apply_radius_damage(impact_center, radius, base_damage)
	_spawn_burn_zone(impact_center, radius, int(weapon.get("status_application", [{"intensity": 3}])[0].get("intensity", 3)))

func _spawn_burn_zone(center: Vector2, radius: float, intensity: int) -> void:
	active_areas.append({"center": center, "radius": radius, "duration": 2.5, "tick": 0.0, "intensity": intensity})

func _update_active_areas(delta: float) -> void:
	for area in active_areas:
		area["duration"] -= delta
		area["tick"] -= delta
		if area["tick"] <= 0.0:
			area["tick"] = 0.45
			_apply_radius_damage(area["center"], area["radius"], maxi(1, int(area["intensity"]/3)))
	active_areas = active_areas.filter(func(area: Dictionary) -> bool: return area["duration"] > 0.0)

func _apply_radius_damage(center: Vector2, radius: float, amount: int) -> void:
	for node in get_tree().get_nodes_in_group("combat_test_target"):
		if node is Node2D and node.has_node("HealthComponent"):
			if (node as Node2D).global_position.distance_to(center) <= radius:
				node.get_node("HealthComponent").apply_damage(amount, self)

func _spend_resource_for_weapon(weapon: Dictionary) -> bool:
	var cost := float(weapon.get("resource_cost", 0.0))
	var resource_type := String(weapon.get("resource_type", "stamina"))
	if resource_type == "mana":
		if mana_component == null:
			return false
		return mana_component.spend(cost)
	if stamina_component == null:
		return true
	return stamina_component.spend(cost)

func _switch_class(direction: int) -> void:
	class_index = posmod(class_index + direction, class_cycle.size())
	combat_class = class_cycle[class_index]
	class_state_label = "ready"

func _cycle_weapon() -> void:
	var weapon_ids: Array = class_weapons.get(combat_class, [])
	if weapon_ids.is_empty():
		return
	weapon_index_by_class[combat_class] = posmod(int(weapon_index_by_class.get(combat_class, 0)) + 1, weapon_ids.size())

func get_active_weapon() -> Dictionary:
	var weapon_ids: Array = class_weapons.get(combat_class, [])
	if weapon_ids.is_empty():
		return {}
	var idx: int = int(weapon_index_by_class.get(combat_class, 0))
	var weapon_id: String = weapon_ids[idx]
	return weapons_by_id.get(weapon_id, {})

func get_debug_snapshot() -> Dictionary:
	var weapon := get_active_weapon()
	return {
		"class": combat_class,
		"weapon": weapon.get("display_name", "None"),
		"stamina": stamina_component.current_stamina if stamina_component else -1,
		"mana": mana_component.current_mana if mana_component else -1,
		"attack_phase": attack_phase,
		"class_state": class_state_label,
		"active_burn_zones": active_areas.size(),
	}

func _load_weapon_data() -> void:
	if !FileAccess.file_exists(WEAPON_DATA_PATH):
		return
	var raw := FileAccess.get_file_as_string(WEAPON_DATA_PATH)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for weapon in parsed.get("weapons", []):
		if typeof(weapon) == TYPE_DICTIONARY and weapon.has("id"):
			weapons_by_id[weapon["id"]] = weapon
