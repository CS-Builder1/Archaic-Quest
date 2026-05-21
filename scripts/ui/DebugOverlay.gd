extends CanvasLayer

@onready var label: Label = $Panel/Label
@export var player_path: NodePath
@onready var player: PlayerController = get_node_or_null(player_path)

func _process(_delta: float) -> void:
	visible = DebugFlags.show_debug_overlay
	if player == null:
		label.text = "Debug: player missing"
		return
	var hp := 0.0
	var max_hp := 0.0
	var player_hc = player.get_node_or_null("HealthComponent")
	if player_hc != null:
		hp = player_hc.current_health
		max_hp = player_hc.max_health
	
	var stagger := 0.0
	var max_stagger := 0.0
	var player_sc = player.get_node_or_null("StaggerComponent")
	if player_sc != null:
		stagger = player_sc.current_stagger
		max_stagger = player_sc.stagger_threshold

	var weapon: Dictionary = player._get_active_weapon()
	label.text = "\n".join([
		"Player HP: %.1f / %.1f" % [hp, max_hp],
		"Player Stagger: %.1f / %.1f" % [stagger, max_stagger],
		"State: %s" % player.state,
		"Attack Phase: %s" % player.attack_phase,
		"Hitbox Active: %s" % str(player.hitbox_active),
		"Weapon: %s" % weapon.get("display_name", "none"),
		"startup/active/recovery: %s/%s/%s ms" % [weapon.get("startup_ms", 0), weapon.get("active_ms", 0), weapon.get("recovery_ms", 0)],
		"hit_stop: %s ms" % weapon.get("hit_stop_ms", 0),
		"stagger: %s reach: %s cost: %s" % [weapon.get("stagger_value", 0), weapon.get("reach", 0), weapon.get("resource_cost", 0)],
		"Stamina: %.1f / %.1f" % [player.stamina.current_stamina, player.stamina.max_stamina],
		"Last Hit Target: %s" % player.last_hit_target,
		"Last Hit Damage: %d" % player.last_hit_damage,
		"Last Stagger Applied: %.1f" % player.last_stagger_applied,
		"Swap Weapon: RMB"
	])
