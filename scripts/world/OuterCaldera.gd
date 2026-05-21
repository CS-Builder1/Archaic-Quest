extends Node2D

func _ready() -> void:
	if has_node("MagmaBrute"):
		_configure_enemy($MagmaBrute, MagmaBruteBehavior.new(), 72.0)
	if has_node("AshScavenger"):
		_configure_enemy($AshScavenger, AshScavengerBehavior.new(), 110.0)
	if has_node("EmberTender"):
		_configure_enemy($EmberTender, EmberTenderBehavior.new(), 92.0)

func _configure_enemy(enemy: AIController, behavior: RoleBehavior, speed: float) -> void:
	enemy.move_speed = speed
	enemy.set_role_behavior(behavior)
