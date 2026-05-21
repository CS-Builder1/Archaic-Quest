extends CharacterBody2D
class_name AIController

@export var move_speed: float = 90.0
@export var detection_radius: float = 320.0
@export var target_group: StringName = &"player"

var current_state: String = "IDLE"
var target_actor: Node2D = null
var threat_model: ThreatModel = ThreatModel.new()
var role_behavior: RoleBehavior = RoleBehavior.new()
var known_targets: Array[Node2D] = []

@onready var state_label: Label = get_node_or_null("DebugStateLabel")

func _physics_process(delta: float) -> void:
	_refresh_candidates()
	target_actor = threat_model.choose_target(self, known_targets, target_actor)
	current_state = role_behavior.evaluate_state(self, delta)
	velocity = role_behavior.get_desired_velocity(self)
	move_and_slide()
	_update_debug_readout()

func set_role_behavior(behavior: RoleBehavior) -> void:
	if behavior == null:
		return
	role_behavior = behavior

func _refresh_candidates() -> void:
	known_targets.clear()
	for node in get_tree().get_nodes_in_group(target_group):
		if not (node is Node2D):
			continue
		var body := node as Node2D
		if global_position.distance_to(body.global_position) <= detection_radius:
			known_targets.append(body)

func _update_debug_readout() -> void:
	if state_label == null or not DebugFlags.show_debug_overlay:
		if state_label != null:
			state_label.visible = false
		return

	state_label.visible = true
	var target_name := "None"
	if target_actor != null:
		target_name = target_actor.name
	state_label.text = "%s | %s\nTarget: %s" % [name, current_state, target_name]
