extends CanvasLayer

@onready var label: Label = $MarginContainer/DebugLabel
@onready var player = get_node_or_null("../Player")

func _process(_delta: float) -> void:
	if DebugFlags.show_debug_overlay:
		visible = true
		label.text = _build_debug_text()
	else:
		visible = false

func _build_debug_text() -> String:
	if player == null:
		return "Debug Overlay\nPlayer: missing"

	var intent = player.input_intent
	var stamina_str := "N/A"
	if player.stamina_component:
		stamina_str = "%.1f / %.1f" % [player.stamina_component.current_stamina, player.stamina_component.max_stamina]

	var stagger_str := "N/A"
	if player.stagger_component:
		stagger_str = "%.1f / %.1f (%s)" % [
			player.stagger_component.current_stagger,
			player.stagger_component.stagger_threshold,
			player.stagger_component.stagger_state
		]

	var attack_phase := "IDLE"
	var attack_timer := 0.0
	var weapon_id := "None"
	var attack_id := "None"
	if player.attack_state_machine:
		attack_phase = player.attack_state_machine.state
		attack_timer = player.attack_state_machine.phase_timer
		weapon_id = player.attack_state_machine.weapon_id
		attack_id = player.attack_state_machine.attack_id if player.attack_state_machine.attack_id != "" else "None"

	var last_hit := {}
	if player.hitbox_component and not player.hitbox_component.last_hit_payload.is_empty():
		last_hit = player.hitbox_component.last_hit_payload
	elif player.hurtbox_component and not player.hurtbox_component.last_hit_payload.is_empty():
		last_hit = player.hurtbox_component.last_hit_payload

	return "\n".join([
		"Archaic Quest Prototype Debug",
		"---------------------------------",
		"Player State: %s" % player.get_state_name(),
		"Buffered Action: %s" % player.get_buffered_action_name(),
		"Velocity: (%.1f, %.1f)" % [player.velocity.x, player.velocity.y],
		"Facing: (%.2f, %.2f)" % [player.facing_direction.x, player.facing_direction.y],
		"Move Intent: (%.2f, %.2f)" % [intent.move_vector.x, intent.move_vector.y],
		"Aim Position: (%.1f, %.1f)" % [intent.aim_world_position.x, intent.aim_world_position.y],
		"Primary Pressed: %s" % str(intent.wants_primary),
		"Dodge Pressed: %s" % str(intent.wants_dodge),
		"---------------------------------",
		"Stamina: %s" % stamina_str,
		"Stagger: %s" % stagger_str,
		"Attack Phase: %s" % attack_phase,
		"Attack Timer: %.3f" % attack_timer,
		"Weapon ID: %s" % weapon_id,
		"Attack ID: %s" % attack_id,
		"Last Hit Payload: %s" % str(last_hit),
		"---------------------------------",
		"Reload Scene: R"
	])
