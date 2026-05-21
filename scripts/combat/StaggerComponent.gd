extends Node
class_name StaggerComponent

signal stagger_changed(current: float, threshold: float)
signal staggered(source_payload: Dictionary)

@export var stagger_threshold: float = 100.0
@export var decay_per_second: float = 16.0

var current_stagger: float = 0.0
var stagger_state: String = "STEADY"

func _process(delta: float) -> void:
	if current_stagger <= 0.0:
		return
	current_stagger = maxf(0.0, current_stagger - decay_per_second * delta)
	if current_stagger == 0.0:
		stagger_state = "STEADY"
	stagger_changed.emit(current_stagger, stagger_threshold)

func apply_stagger(amount: float, source_payload: Dictionary = {}) -> void:
	if amount <= 0.0:
		return
	current_stagger += amount
	if current_stagger >= stagger_threshold:
		current_stagger = 0.0
		stagger_state = "STAGGERED"
		staggered.emit(source_payload)
		EventBus.emit_combat("stagger_break", source_payload)
	else:
		stagger_state = "PRESSURED"
	stagger_changed.emit(current_stagger, stagger_threshold)
