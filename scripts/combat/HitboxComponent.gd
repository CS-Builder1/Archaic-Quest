extends Area2D
class_name HitboxComponent

signal valid_hit(payload: Dictionary)

@export var damage: int = 20
@export var stagger_damage: float = 22.0

var owner_actor: Node = null
var attack_state_machine: AttackStateMachine = null
var active_attack_id: String = ""
var active: bool = false
var last_hit_payload: Dictionary = {}

var _hit_targets: Dictionary = {}

func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)

func bind_attack_state_machine(machine: AttackStateMachine) -> void:
	attack_state_machine = machine
	attack_state_machine.attack_phase_changed.connect(_on_attack_phase_changed)
	attack_state_machine.attack_started.connect(_on_attack_started)
	attack_state_machine.attack_finished.connect(_on_attack_finished)

func _on_attack_started(attack_id: String) -> void:
	active_attack_id = attack_id
	_hit_targets.clear()

func _on_attack_finished(_attack_id: String) -> void:
	active = false
	monitoring = false

func _on_attack_phase_changed(phase: String, _phase_timer: float) -> void:
	active = phase == "ACTIVE"
	monitoring = active
	if phase != "ACTIVE":
		_hit_targets.clear()

func _on_area_entered(area: Area2D) -> void:
	if !active:
		return
	if area == self:
		return
	if _hit_targets.has(area):
		return
	if !area.has_method("receive_hit"):
		return

	_hit_targets[area] = true
	var payload := {
		"source": owner_actor,
		"attack_id": active_attack_id,
		"weapon_id": attack_state_machine.weapon_id if attack_state_machine else "unknown",
		"damage": damage,
		"stagger": stagger_damage,
	}
	var accepted: bool = bool(area.call("receive_hit", payload))
	if accepted:
		last_hit_payload = payload.duplicate(true)
		valid_hit.emit(last_hit_payload)
		if attack_state_machine:
			attack_state_machine.trigger_hit_stop()
