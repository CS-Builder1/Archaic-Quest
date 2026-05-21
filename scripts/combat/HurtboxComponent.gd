extends Area2D
class_name HurtboxComponent

@export var health_component_path: NodePath
@export var stagger_component_path: NodePath

@onready var health_component: HealthComponent = get_node_or_null(health_component_path)
@onready var stagger_component: StaggerComponent = get_node_or_null(stagger_component_path)

func apply_hit(damage: int, stagger_amount: float, source: Node) -> void:
	if health_component != null:
		health_component.apply_damage(damage, source)
	if stagger_component != null:
		stagger_component.apply_stagger(stagger_amount)
