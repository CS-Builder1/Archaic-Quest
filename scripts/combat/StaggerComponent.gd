extends Node
class_name StaggerComponent

signal stagger_applied(amount: float)

@export var stagger_threshold: float = 100.0
var current_stagger: float = 0.0

func apply_stagger(amount: float) -> void:
	if amount <= 0.0:
		return
	current_stagger = minf(current_stagger + amount, stagger_threshold)
	stagger_applied.emit(amount)
