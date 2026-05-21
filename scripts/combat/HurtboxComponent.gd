extends Area2D
class_name HurtboxComponent

@export var health_path: NodePath
@export var stagger_path: NodePath

var health_component: HealthComponent = null
var stagger_component: StaggerComponent = null
var last_hit_payload: Dictionary = {}

func _ready() -> void:
	monitorable = true
	monitoring = true
	if health_path != NodePath():
		health_component = get_node_or_null(health_path) as HealthComponent
	if stagger_path != NodePath():
		stagger_component = get_node_or_null(stagger_path) as StaggerComponent

func receive_hit(payload: Dictionary) -> bool:
	if payload.is_empty():
		return false
	last_hit_payload = payload.duplicate(true)
	if health_component:
		health_component.apply_damage(int(payload.get("damage", 0)), payload.get("source", null))
	if stagger_component:
		stagger_component.apply_stagger(float(payload.get("stagger", 0.0)), payload)
	EventBus.emit_combat("hurtbox_hit", {
		"target": get_parent().name if get_parent() else name,
		"attack_id": str(payload.get("attack_id", "unknown")),
		"damage": int(payload.get("damage", 0)),
	})
	return true
