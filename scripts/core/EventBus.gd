extends Node

## Global signal hub for the prototype.
## Keep this thin. Systems should emit semantic events, not call each other directly.

signal combat_event(event_name: String, payload: Dictionary)
signal world_state_changed(variable_name: String, old_value: Variant, new_value: Variant)
signal debug_message(message: String)

func emit_combat(event_name: String, payload: Dictionary = {}) -> void:
	combat_event.emit(event_name, payload)
	debug_message.emit("Combat: %s %s" % [event_name, str(payload)])

func emit_world_change(variable_name: String, old_value: Variant, new_value: Variant) -> void:
	world_state_changed.emit(variable_name, old_value, new_value)
	debug_message.emit("WorldState: %s %s -> %s" % [variable_name, str(old_value), str(new_value)])
