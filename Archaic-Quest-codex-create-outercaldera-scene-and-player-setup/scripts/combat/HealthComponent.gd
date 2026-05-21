extends Node

signal damaged(amount: int, source: Node)
signal died(source: Node)

@export var max_health: int = 100
var current_health: int = 100

func _ready() -> void:
	current_health = max_health

func apply_damage(amount: int, source: Node = null) -> void:
	if amount <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	damaged.emit(amount, source)
	EventBus.emit_combat("damage_applied", {
		"target": get_parent().name if get_parent() else "unknown",
		"amount": amount,
	})
	if current_health <= 0:
		died.emit(source)
		EventBus.emit_combat("actor_died", {
			"target": get_parent().name if get_parent() else "unknown",
		})

func heal(amount: int) -> void:
	current_health = mini(current_health + amount, max_health)
