extends Node

signal stamina_changed(current: float, max_value: float)
signal exhausted()

@export var max_stamina: float = 100.0
@export var regen_per_second: float = 18.0
@export var regen_delay_after_spend: float = 0.45

var current_stamina: float = 100.0
var regen_delay_timer: float = 0.0

func _ready() -> void:
	current_stamina = max_stamina

func _process(delta: float) -> void:
	if regen_delay_timer > 0.0:
		regen_delay_timer -= delta
		return
	if current_stamina < max_stamina:
		current_stamina = minf(current_stamina + regen_per_second * delta, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)

func can_spend(amount: float) -> bool:
	return current_stamina >= amount

func spend(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if !can_spend(amount):
		exhausted.emit()
		return false
	current_stamina -= amount
	regen_delay_timer = regen_delay_after_spend
	stamina_changed.emit(current_stamina, max_stamina)
	return true
