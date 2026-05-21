extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.18
@export var dodge_recovery: float = 0.22
@export var base_damage: int = 22

@onready var camera: Camera2D = $Camera2D
@onready var input_intent: PlayerInputIntent = $PlayerInputIntent
@onready var stamina: StaminaComponent = $StaminaComponent
@onready var attack_area: Area2D = $AttackArea
@onready var attack_collision: CollisionShape2D = $AttackArea/CollisionShape2D

var facing_direction: Vector2 = Vector2.RIGHT
var state: String = "IDLE"
var dodge_timer: float = 0.0
var recovery_timer: float = 0.0
var last_move_vector: Vector2 = Vector2.RIGHT

var weapons: Array[Dictionary] = []
var active_weapon_index: int = 0
var attack_phase: String = "NONE"
var attack_timer: float = 0.0
var hitbox_active: bool = false
var active_window_hit_targets: Dictionary = {}
var last_hit_target: String = "-"
var last_hit_damage: int = 0
var last_stagger_applied: float = 0.0
var attack_weapon: Dictionary = {}

func _ready() -> void:
	weapons = WeaponLibrary.load_barbarian_weapons()
	_set_weapon_by_id("barbarian_heavy_axe")
	attack_collision.disabled = true

func _physics_process(delta: float) -> void:
	input_intent.collect_intent(camera)
	_handle_weapon_swap_intent()
	_update_facing()
	_update_attack_state(delta)
	_update_state(delta)
	move_and_slide()
	if Input.is_action_just_pressed("reload_test_scene"):
		get_tree().reload_current_scene()

func _handle_weapon_swap_intent() -> void:
	if attack_phase == "NONE" and input_intent.wants_secondary and weapons.size() >= 2:
		active_weapon_index = (active_weapon_index + 1) % weapons.size()
		_configure_attack_shape()

func _update_facing() -> void:
	var to_mouse := input_intent.aim_world_position - global_position
	if to_mouse.length() > 1.0:
		facing_direction = to_mouse.normalized()
		rotation = facing_direction.angle()

func _update_state(delta: float) -> void:
	if attack_phase != "NONE":
		velocity = Vector2.ZERO
		return
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
	if input_intent.wants_primary:
		_try_start_attack()

func _try_start_attack() -> void:
	if attack_phase != "NONE":
		return
	attack_weapon = _get_active_weapon().duplicate(true)
	if attack_weapon.is_empty():
		return
	if !stamina.spend(float(attack_weapon.get("resource_cost", 0))):
		return
	attack_phase = "STARTUP"
	attack_timer = float(attack_weapon.get("startup_ms", 0)) / 1000.0
	last_hit_target = "-"
	last_hit_damage = 0
	last_stagger_applied = 0.0

func _update_attack_state(delta: float) -> void:
	if attack_phase == "NONE":
		return
	attack_timer -= delta
	if attack_timer > 0.0:
		return
	if attack_phase == "STARTUP":
		attack_phase = "ACTIVE"
		attack_timer = float(attack_weapon.get("active_ms", 0)) / 1000.0
		hitbox_active = true
		attack_collision.disabled = false
		active_window_hit_targets.clear()
		_resolve_hits()
	elif attack_phase == "ACTIVE":
		attack_phase = "RECOVERY"
		attack_timer = float(attack_weapon.get("recovery_ms", 0)) / 1000.0
		hitbox_active = false
		attack_collision.disabled = true
	elif attack_phase == "RECOVERY":
		attack_phase = "NONE"
		attack_weapon = {}

func _resolve_hits() -> void:
	for body in attack_area.get_overlapping_areas():
		if body is HurtboxComponent:
			var target_name := body.get_parent().name if body.get_parent() else body.name
			if active_window_hit_targets.has(target_name):
				continue
			active_window_hit_targets[target_name] = true
			var stagger_amount := float(attack_weapon.get("stagger_value", 0))
			body.apply_hit(base_damage, stagger_amount, self)
			last_hit_target = target_name
			last_hit_damage = base_damage
			last_stagger_applied = stagger_amount
			Engine.time_scale = 0.05
			await get_tree().create_timer(float(attack_weapon.get("hit_stop_ms", 0)) / 1000.0, true, false, true).timeout
			Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _set_weapon_by_id(weapon_id: String) -> void:
	for i in range(weapons.size()):
		if weapons[i].get("id", "") == weapon_id:
			active_weapon_index = i
			_configure_attack_shape()
			return
	if weapons.size() > 0:
		active_weapon_index = 0
		_configure_attack_shape()

func _configure_attack_shape() -> void:
	var weapon := _get_active_weapon()
	var reach := float(weapon.get("reach", 2.0))
	var radius := 36.0
	var angle_span := deg_to_rad(65.0)
	if weapon.get("id", "") == "barbarian_heavy_axe":
		radius = 52.0
		angle_span = deg_to_rad(105.0)
	elif weapon.get("id", "") == "barbarian_maul":
		radius = 46.0
		angle_span = deg_to_rad(55.0)
	var shape := CapsuleShape2D.new()
	shape.radius = radius
	shape.height = reach * 24.0
	attack_collision.shape = shape
	attack_area.position = Vector2((reach * 24.0) * 0.5, 0)

func _get_active_weapon() -> Dictionary:
	if weapons.is_empty() or active_weapon_index < 0 or active_weapon_index >= weapons.size():
		return {}
	return weapons[active_weapon_index]
