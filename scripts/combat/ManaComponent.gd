extends Node
class_name ManaComponent

signal mana_changed(current: float, max_value: float)
signal depleted()

@export var max_mana: float = 100.0
@export var regen_per_second: float = 15.0
@export var regen_delay_after_spend: float = 0.55

var current_mana: float = 100.0
var regen_delay_timer: float = 0.0

func _ready() -> void:
	current_mana = max_mana

func _process(delta: float) -> void:
	if regen_delay_timer > 0.0:
		regen_delay_timer -= delta
		return
	if current_mana < max_mana:
		current_mana = minf(current_mana + regen_per_second * delta, max_mana)
		mana_changed.emit(current_mana, max_mana)

func can_spend(amount: float) -> bool:
	return current_mana >= amount

func spend(amount: float) -> bool:
	if amount <= 0.0:
		return true
	if !can_spend(amount):
		depleted.emit()
		return false
	current_mana -= amount
	regen_delay_timer = regen_delay_after_spend
	mana_changed.emit(current_mana, max_mana)
	return true
