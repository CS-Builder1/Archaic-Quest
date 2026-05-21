extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.18
@export var dodge_recovery: float = 0.22
@export var primary_attack_range: float = 96.0
@export var primary_attack_arc_degrees: float = 70.0

@onready var camera: Camera2D = $Camera2D
@onready var input_intent: PlayerInputIntent = $PlayerInputIntent

const CLASS_BARBARIAN := "Barbarian"
const CLASS_ARCHER := "Archer"
const CLASS_MAGE := "Mage"

const CLASS_ORDER := [CLASS_BARBARIAN, CLASS_ARCHER, CLASS_MAGE]
const CLASS_WEAPONS := {
	CLASS_BARBARIAN: ["Heavy Axe", "Maul"],
	CLASS_ARCHER: ["Longbow", "Shortbow"],
	CLASS_MAGE: ["Fire Staff", "Ember Focus"]
}

var facing_direction: Vector2 = Vector2.RIGHT
var state: String = "IDLE"
var dodge_timer: float = 0.0
var recovery_timer: float = 0.0
var last_move_vector: Vector2 = Vector2.RIGHT
var active_class: String = CLASS_BARBARIAN
var active_weapon_index: int = 0
var rage: float = 0.0
var focus: float = 100.0
var mana: float = 100.0

func _physics_process(delta: float) -> void:
	input_intent.collect_intent(camera)
	_update_facing()
	_handle_class_intents()
	_update_state(delta)
	move_and_slide()

	if input_intent.wants_reload_scene:
		get_tree().reload_current_scene()

	if input_intent.wants_secondary:
		_swap_weapon()

	if input_intent.wants_primary and _can_process_primary_attack():
		_process_attack()

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

func _handle_class_intents() -> void:
	if input_intent.wants_switch_class_1:
		_set_class(CLASS_BARBARIAN)
	elif input_intent.wants_switch_class_2:
		_set_class(CLASS_ARCHER)
	elif input_intent.wants_switch_class_3:
		_set_class(CLASS_MAGE)
	elif input_intent.wants_cycle_class:
		var next_index := (CLASS_ORDER.find(active_class) + 1) % CLASS_ORDER.size()
		_set_class(CLASS_ORDER[next_index])

func _set_class(new_class: String) -> void:
	if active_class == new_class:
		return
	active_class = new_class
	active_weapon_index = 0
	EventBus.debug_message.emit("Class switched to %s. Active weapon: %s" % [active_class, get_active_weapon()])

func _swap_weapon() -> void:
	var weapons: Array = CLASS_WEAPONS.get(active_class, [])
	if weapons.is_empty():
		return
	active_weapon_index = (active_weapon_index + 1) % weapons.size()
	EventBus.debug_message.emit("Weapon swapped to %s" % get_active_weapon())

func _can_process_primary_attack() -> bool:
	return state == "IDLE" or state == "MOVING"

func _process_attack() -> void:
	var target := _find_attack_target()
	if target == null:
		return
	if target.has_method("take_damage"):
		target.take_damage(10.0, active_class, get_active_weapon())
	elif target.has_method("apply_damage"):
		target.apply_damage(10.0)
	elif target.has_node("HealthComponent"):
		var health_component: HealthComponent = target.get_node("HealthComponent")
		health_component.apply_damage(10.0)
	_update_resources_on_attack()

func _find_attack_target() -> Node:
	var world := get_tree().current_scene
	if world == null:
		return null

	var potential_targets: Array[Node] = []
	potential_targets.append_array(get_tree().get_nodes_in_group("enemies"))
	potential_targets.append_array(get_tree().get_nodes_in_group("combat_dummies"))

	if world.has_node("CombatDummy"):
		potential_targets.append(world.get_node("CombatDummy"))
	if world.has_node("Enemy"):
		potential_targets.append(world.get_node("Enemy"))

	var max_angle := deg_to_rad(primary_attack_arc_degrees * 0.5)
	var best_target: Node = null
	var best_distance := INF

	for target in potential_targets:
		if target == null or not is_instance_valid(target) or not (target is Node2D):
			continue
		var target_2d := target as Node2D
		var to_target := target_2d.global_position - global_position
		var distance := to_target.length()
		if distance > primary_attack_range or distance <= 0.001:
			continue
		var direction := to_target / distance
		if facing_direction.angle_to(direction) > max_angle:
			continue
		if distance < best_distance:
			best_distance = distance
			best_target = target

	return best_target

func _update_resources_on_attack() -> void:
	match active_class:
		CLASS_BARBARIAN:
			rage = min(rage + 15.0, 100.0)
		CLASS_ARCHER:
			focus = max(focus - 10.0, 0.0)
		CLASS_MAGE:
			mana = max(mana - 12.0, 0.0)

func get_active_weapon() -> String:
	var weapons: Array = CLASS_WEAPONS.get(active_class, [])
	if weapons.is_empty():
		return "Unarmed"
	return str(weapons[active_weapon_index])

func get_debug_overlay_lines() -> PackedStringArray:
	var class_hint := "[1] Barbarian [2] Archer [3] Mage | [C] Cycle | RMB Swap"
	var resources := "Rage %.0f | Focus %.0f | Mana %.0f" % [rage, focus, mana]
	return PackedStringArray([
		"Class: %s" % active_class,
		"Weapon: %s" % get_active_weapon(),
		"Switch: %s" % class_hint,
		"Resources: %s" % resources
	])
