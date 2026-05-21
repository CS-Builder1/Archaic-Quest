extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.18
@export var dodge_recovery: float = 0.22

@onready var camera: Camera2D = $Camera2D
@onready var input_intent: PlayerInputIntent = $PlayerInputIntent
@onready var stamina_component: StaminaComponent = $StaminaComponent
@onready var attack_state_machine: AttackStateMachine = $AttackStateMachine
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var stagger_component: StaggerComponent = $StaggerComponent
@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

var facing_direction: Vector2 = Vector2.RIGHT
var state: String = "IDLE"
var dodge_timer: float = 0.0
var recovery_timer: float = 0.0
var last_move_vector: Vector2 = Vector2.RIGHT
var hit_stop_timer: float = 0.0

const PRIMARY_ATTACK_COST: float = 20.0
const DODGE_COST: float = 25.0

func _ready() -> void:
	hitbox_component.owner_actor = self
	hitbox_component.bind_attack_state_machine(attack_state_machine)
	hitbox_component.valid_hit.connect(_on_valid_hit)
	attack_state_machine.hit_stop_requested.connect(_on_hit_stop_requested)

func _physics_process(delta: float) -> void:
	if _process_hit_stop(delta):
		return

	input_intent.collect_intent(camera)
	attack_state_machine.tick(delta)
	_try_primary_attack()
	_update_facing()
	_update_state(delta)
	move_and_slide()
	_emit_debug_overlay_snapshot()

	if input_intent.wants_reload_test_scene:
		get_tree().reload_current_scene()

func _process_hit_stop(delta: float) -> bool:
	if hit_stop_timer <= 0.0:
		return false
	hit_stop_timer -= delta
	velocity = Vector2.ZERO
	_emit_debug_overlay_snapshot()
	return true

func _try_primary_attack() -> void:
	if !input_intent.wants_primary:
		return
	if stamina_component.current_stamina < PRIMARY_ATTACK_COST:
		return
	var attack_started := attack_state_machine.request_primary_attack({
		"attack_id": "barbarian_primary",
		"weapon_id": "barbarian_heavy_axe",
	})
	if attack_started:
		stamina_component.spend(PRIMARY_ATTACK_COST)

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

	# If we are actively attacking, check attack machine phase
	if attack_state_machine.state in ["STARTUP", "ACTIVE"]:
		velocity = Vector2.ZERO
		return
	elif attack_state_machine.state == "RECOVERY":
		velocity = input_intent.move_vector * (move_speed * 0.35)
		return

	if input_intent.move_vector.length() > 0.01:
		last_move_vector = input_intent.move_vector.normalized()
		velocity = input_intent.move_vector * move_speed
		state = "MOVING"
	else:
		velocity = Vector2.ZERO
		state = "IDLE"

	if input_intent.wants_dodge:
		if stamina_component.current_stamina >= DODGE_COST:
			if stamina_component.spend(DODGE_COST):
				state = "DODGING"
				dodge_timer = dodge_duration
				velocity = last_move_vector * dodge_speed

func _on_valid_hit(_payload: Dictionary) -> void:
	# Placeholder hook for future VFX/SFX.
	pass

func _on_hit_stop_requested(duration: float) -> void:
	hit_stop_timer = maxf(hit_stop_timer, duration)

func _emit_debug_overlay_snapshot() -> void:
	var snapshot := {
		"player_state": state,
		"attack_phase": attack_state_machine.state,
		"attack_timer": snappedf(attack_state_machine.phase_timer, 0.001),
		"weapon_id": attack_state_machine.weapon_id,
		"attack_id": attack_state_machine.attack_id,
		"stamina": snappedf(stamina_component.current_stamina, 0.01),
		"stagger": snappedf(stagger_component.current_stagger, 0.01),
		"last_hit_payload": hitbox_component.last_hit_payload if !hitbox_component.last_hit_payload.is_empty() else hurtbox_component.last_hit_payload,
	}
	EventBus.debug_message.emit("Overlay: %s" % str(snapshot))

func get_state_name() -> String:
	return state

func get_buffered_action_name() -> String:
	if attack_state_machine._queued_primary:
		return "PRIMARY_ATTACK"
	return "NONE"
