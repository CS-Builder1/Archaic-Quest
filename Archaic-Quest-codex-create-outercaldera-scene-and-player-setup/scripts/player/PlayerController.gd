extends CharacterBody2D
class_name PlayerController

enum PlayerState {
	IDLE,
	MOVING,
	ATTACK_STARTUP,
	ATTACK_ACTIVE,
	ATTACK_RECOVERY,
	DODGING,
	DODGE_RECOVERY
}

enum BufferedAction {
	NONE,
	PRIMARY_ATTACK,
	DODGE
}

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.18
@export var dodge_recovery: float = 0.22
@export var attack_startup_duration: float = 0.12
@export var attack_active_duration: float = 0.08
@export var attack_recovery_duration: float = 0.28
@export var input_buffer_duration: float = 0.2

@onready var camera: Camera2D = $Camera2D
@onready var input_intent = $PlayerInputIntent

var facing_direction: Vector2 = Vector2.RIGHT
var state: int = PlayerState.IDLE
var dodge_timer: float = 0.0
var recovery_timer: float = 0.0
var attack_timer: float = 0.0
var last_move_vector: Vector2 = Vector2.RIGHT
var buffered_action: int = BufferedAction.NONE
var buffered_action_timer: float = 0.0

func _physics_process(delta: float) -> void:
	input_intent.collect_intent(camera)
	_update_facing()
	_update_buffer(delta)
	_update_state(delta)
	move_and_slide()

	if input_intent.wants_reload_test_scene:
		get_tree().reload_current_scene()

func _update_facing() -> void:
	var to_mouse: Vector2 = input_intent.aim_world_position - global_position
	if to_mouse.length() > 1.0:
		facing_direction = to_mouse.normalized()
		rotation = facing_direction.angle()

func _update_buffer(delta: float) -> void:
	if buffered_action != BufferedAction.NONE:
		buffered_action_timer -= delta
		if buffered_action_timer <= 0.0:
			buffered_action = BufferedAction.NONE

	if input_intent.wants_primary:
		if can_start_attack():
			_start_attack()
		else:
			_buffer_action(BufferedAction.PRIMARY_ATTACK)

	if input_intent.wants_dodge:
		if can_dodge():
			_start_dodge()
		else:
			_buffer_action(BufferedAction.DODGE)

func _update_state(delta: float) -> void:
	match state:
		PlayerState.DODGING:
			dodge_timer -= delta
			velocity = last_move_vector * dodge_speed
			if dodge_timer <= 0.0:
				state = PlayerState.DODGE_RECOVERY
				recovery_timer = dodge_recovery
			return
		PlayerState.DODGE_RECOVERY:
			recovery_timer -= delta
			velocity = input_intent.move_vector * (move_speed * 0.45)
			if recovery_timer <= 0.0:
				state = PlayerState.IDLE
			_attempt_consume_buffer()
			return
		PlayerState.ATTACK_STARTUP:
			attack_timer -= delta
			velocity = Vector2.ZERO
			if attack_timer <= 0.0:
				state = PlayerState.ATTACK_ACTIVE
				attack_timer = attack_active_duration
			return
		PlayerState.ATTACK_ACTIVE:
			attack_timer -= delta
			velocity = Vector2.ZERO
			if attack_timer <= 0.0:
				state = PlayerState.ATTACK_RECOVERY
				attack_timer = attack_recovery_duration
			return
		PlayerState.ATTACK_RECOVERY:
			attack_timer -= delta
			velocity = input_intent.move_vector * (move_speed * 0.35)
			if attack_timer <= 0.0:
				state = PlayerState.IDLE
			_attempt_consume_buffer()
			return

	if input_intent.move_vector.length() > 0.01 and can_move():
		last_move_vector = input_intent.move_vector.normalized()
		velocity = input_intent.move_vector * move_speed
		state = PlayerState.MOVING
	else:
		velocity = Vector2.ZERO
		state = PlayerState.IDLE

	_attempt_consume_buffer()

func can_move() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVING]

func can_dodge() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVING]

func can_start_attack() -> bool:
	return state in [PlayerState.IDLE, PlayerState.MOVING]

func can_buffer_attack() -> bool:
	return state in [PlayerState.ATTACK_STARTUP, PlayerState.ATTACK_ACTIVE, PlayerState.ATTACK_RECOVERY, PlayerState.DODGING, PlayerState.DODGE_RECOVERY]

func _attempt_consume_buffer() -> void:
	if buffered_action == BufferedAction.PRIMARY_ATTACK and can_start_attack():
		_start_attack()
		_clear_buffer()
	elif buffered_action == BufferedAction.DODGE and can_dodge():
		_start_dodge()
		_clear_buffer()

func _start_attack() -> void:
	state = PlayerState.ATTACK_STARTUP
	attack_timer = attack_startup_duration
	velocity = Vector2.ZERO

func _start_dodge() -> void:
	state = PlayerState.DODGING
	dodge_timer = dodge_duration
	velocity = last_move_vector * dodge_speed

func _buffer_action(action: int) -> void:
	if action == BufferedAction.PRIMARY_ATTACK and not can_buffer_attack():
		return
	buffered_action = action
	buffered_action_timer = input_buffer_duration

func _clear_buffer() -> void:
	buffered_action = BufferedAction.NONE
	buffered_action_timer = 0.0

func get_state_name() -> String:
	return PlayerState.keys()[state]

func get_buffered_action_name() -> String:
	return BufferedAction.keys()[buffered_action]
