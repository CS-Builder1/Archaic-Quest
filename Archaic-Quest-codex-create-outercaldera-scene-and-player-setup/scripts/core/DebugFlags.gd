extends Node

var show_debug_overlay: bool = true
var invulnerable_player: bool = false
var freeze_world_state: bool = false
var log_combat_events: bool = true

func toggle_debug_overlay() -> void:
	show_debug_overlay = !show_debug_overlay
