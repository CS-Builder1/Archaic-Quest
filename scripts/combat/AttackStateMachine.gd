extends Node
class_name AttackStateMachine

signal state_changed(new_state: String)
signal attack_started(attack_id: String)
signal attack_phase_changed(phase: String, phase_timer: float)
signal attack_finished(attack_id: String)
signal hit_stop_requested(duration: float)

@export var default_startup: float = 0.12
@export var default_active: float = 0.10
@export var default_recovery: float = 0.24
@export var hit_stop_duration: float = 0.06

var state: String = "IDLE"
var attack_id: String = ""
var weapon_id: String = "barbarian_heavy_axe"
var phase_timer: float = 0.0
var last_attack_payload: Dictionary = {}

var _queued_primary: bool = false

func request_primary_attack(payload: Dictionary = {}) -> bool:
	if state != "IDLE":
		if state == "RECOVERY":
			_queued_primary = true
		return false

	attack_id = str(payload.get("attack_id", "primary_light"))
	weapon_id = str(payload.get("weapon_id", weapon_id))
	var startup: float = float(payload.get("startup", default_startup))
	var active: float = float(payload.get("active", default_active))
	var recovery: float = float(payload.get("recovery", default_recovery))

	last_attack_payload = {
		"attack_id": attack_id,
		"weapon_id": weapon_id,
		"startup": startup,
		"active": active,
		"recovery": recovery,
	}

	_change_state("STARTUP", startup)
	attack_started.emit(attack_id)
	EventBus.emit_combat("attack_started", last_attack_payload)
	return true

func tick(delta: float) -> void:
	if state == "IDLE":
		return

	phase_timer = maxf(phase_timer - delta, 0.0)
	if phase_timer > 0.0:
		return

	match state:
		"STARTUP":
			_change_state("ACTIVE", float(last_attack_payload.get("active", default_active)))
		"ACTIVE":
			_change_state("RECOVERY", float(last_attack_payload.get("recovery", default_recovery)))
		"RECOVERY":
			_change_state("IDLE", 0.0)
			attack_finished.emit(attack_id)
			EventBus.emit_combat("attack_finished", {"attack_id": attack_id})
			attack_id = ""
			if _queued_primary:
				_queued_primary = false
		"_":
			_change_state("IDLE", 0.0)

func is_hitbox_active() -> bool:
	return state == "ACTIVE"

func trigger_hit_stop() -> void:
	hit_stop_requested.emit(hit_stop_duration)
	EventBus.emit_combat("hit_stop", {"duration": hit_stop_duration})

func _change_state(new_state: String, timer: float) -> void:
	state = new_state
	phase_timer = timer
	state_changed.emit(state)
	attack_phase_changed.emit(state, phase_timer)
