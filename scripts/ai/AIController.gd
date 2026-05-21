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
	_setup_visuals_and_physics()

func _setup_visuals_and_physics() -> void:
	# Clean up any existing visuals/collision first to prevent duplicates
	var old_visual = get_node_or_null("BodyVisual")
	if old_visual:
		old_visual.queue_free()
	var old_col = get_node_or_null("BodyCollision")
	if old_col:
		old_col.queue_free()

	var poly := Polygon2D.new()
	poly.name = "BodyVisual"
	
	var col := CollisionShape2D.new()
	col.name = "BodyCollision"
	var col_shape := CircleShape2D.new()

	var role_name := role_behavior.get_role_name()
	if role_name == "Bruiser":
		poly.polygon = _get_reg_poly(8, 24.0) # large octagon
		poly.color = Color("e53e3e")          # premium lava crimson
		col_shape.radius = 20.0
	elif role_name == "Skirmisher":
		poly.polygon = PackedVector2Array([
			Vector2(20, 0),   # Dart tip
			Vector2(-12, -10),
			Vector2(-4, 0),
			Vector2(-12, 10)
		])                                    # sleek gray dart/diamond
		poly.color = Color("718096")          # premium sleek ash-gray
		col_shape.radius = 12.0
	elif role_name == "Support":
		poly.polygon = _get_reg_poly(5, 16.0) # golden pentagon
		poly.color = Color("ecc94b")          # premium amber gold
		col_shape.radius = 14.0
	else:
		poly.polygon = _get_reg_poly(6, 16.0) # fallback hexagon
		poly.color = Color("319795")          # premium sage green
		col_shape.radius = 14.0

	col.shape = col_shape
	add_child(poly)
	add_child(col)

	# Clean up any existing combat components to prevent duplication
	var old_hb = get_node_or_null("HurtboxComponent")
	if old_hb: old_hb.queue_free()
	var old_hc = get_node_or_null("HealthComponent")
	if old_hc: old_hc.queue_free()
	var old_sc = get_node_or_null("StaggerComponent")
	if old_sc: old_sc.queue_free()

	# Programmatic HealthComponent
	var hc := HealthComponent.new()
	hc.name = "HealthComponent"
	hc.max_health = 250 if role_name == "Bruiser" else (150 if role_name == "Support" else 100)
	add_child(hc)
	hc.died.connect(func(_source): queue_free())

	# Programmatic StaggerComponent
	var sc := StaggerComponent.new()
	sc.name = "StaggerComponent"
	sc.stagger_threshold = 120.0 if role_name == "Bruiser" else 60.0
	add_child(sc)

	# Programmatic HurtboxComponent Area2D
	var hb := HurtboxComponent.new()
	hb.name = "HurtboxComponent"
	hb.health_component_path = NodePath("../HealthComponent")
	hb.stagger_component_path = NodePath("../StaggerComponent")
	
	var hb_col := CollisionShape2D.new()
	var hb_shape := CircleShape2D.new()
	hb_shape.radius = col_shape.radius + 4.0
	hb_col.shape = hb_shape
	hb.add_child(hb_col)
	
	add_child(hb)


func _get_reg_poly(sides: int, radius: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(sides):
		var angle := i * TAU / sides
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts

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

func is_alive() -> bool:
	var hc = get_node_or_null("HealthComponent")
	return hc.current_health > 0 if hc else true
