extends CanvasLayer

@onready var label: Label = $MarginContainer/DebugLabel
@onready var player: PlayerController = get_node_or_null("../Player")

func _process(_delta: float) -> void:
	if DebugFlags.show_debug_overlay:
		visible = true
		label.text = _build_debug_text()
	else:
		visible = false

func _build_debug_text() -> String:
	if player == null:
		return "Debug Overlay\nPlayer: missing"

	var intent := player.input_intent
	return "\n".join([
		"Archaic Quest Prototype Debug",
		"State: %s" % player.get_state_name(),
		"Buffered Action: %s" % player.get_buffered_action_name(),
		"Velocity: (%.1f, %.1f)" % [player.velocity.x, player.velocity.y],
		"Facing: (%.2f, %.2f)" % [player.facing_direction.x, player.facing_direction.y],
		"Move Intent: (%.2f, %.2f)" % [intent.move_vector.x, intent.move_vector.y],
		"Aim: (%.1f, %.1f)" % [intent.aim_world_position.x, intent.aim_world_position.y],
		"Primary Intent: %s" % str(intent.wants_primary),
		"Dodge Intent: %s" % str(intent.wants_dodge),
		"Reload Scene: R"
	])
