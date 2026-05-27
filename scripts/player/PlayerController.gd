extends CharacterBody2D
class_name PlayerController

const WEAPON_DATA_PATH := "res://data/weapons/weapons.slice.json"

@export var move_speed: float = 220.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.18
@export var dodge_recovery: float = 0.22
@export var base_damage: int = 22

@onready var camera: Camera2D = $Camera2D
@onready var input_intent: PlayerInputIntent = $PlayerInputIntent

# Dynamic component references (can be configured in scene or programmatically instantiated)
@onready var stamina_component: StaminaComponent = get_node_or_null("StaminaComponent")
@onready var stamina: StaminaComponent = get_node_or_null("StaminaComponent")
@onready var mana_component: ManaComponent = get_node_or_null("ManaComponent")
@onready var attack_area: Area2D = get_node_or_null("AttackArea")
@onready var attack_collision: CollisionShape2D = get_node_or_null("AttackArea/CollisionShape2D")

var facing_direction: Vector2 = Vector2.RIGHT
var state: String = "IDLE"
var dodge_timer: float = 0.0
var recovery_timer: float = 0.0
var last_move_vector: Vector2 = Vector2.RIGHT

# Class Switching & Weapon Systems (M5 implementation)
const CLASS_BARBARIAN := "Barbarian"
const CLASS_ARCHER := "Archer"
const CLASS_MAGE := "Mage"

const CLASS_ORDER := [CLASS_BARBARIAN, CLASS_ARCHER, CLASS_MAGE]
const CLASS_WEAPONS := {
	CLASS_BARBARIAN: ["Heavy Axe", "Maul"],
	CLASS_ARCHER: ["Longbow", "Shortbow"],
	CLASS_MAGE: ["Fire Staff", "Ember Focus"]
}

var active_class: String = CLASS_BARBARIAN
var active_weapon_index: int = 0
var rage: float = 0.0
var focus: float = 100.0
var mana: float = 100.0

var combat_class: String = "barbarian"
var class_cycle: Array[String] = ["barbarian", "archer", "mage"]
var class_index: int = 0
var class_weapons: Dictionary = {
	"barbarian": ["barbarian_heavy_axe", "barbarian_maul"],
	"archer": ["archer_longbow", "archer_shortbow"],
	"mage": ["mage_fire_staff", "mage_ember_focus"],
}
var weapon_index_by_class: Dictionary = {"barbarian": 0, "archer": 0, "mage": 0}
var weapons_by_id: Dictionary = {}

# Unified Combat State Machine (lowercase-based for M5, co-integrated with stagger/hit-stop)
var attack_phase: String = "idle"
var attack_timer: float = 0.0
var queued_attack_payload: Dictionary = {}
var class_state_label: String = "ready"
var active_areas: Array[Dictionary] = []

# Hit-Stop and Overlap validation values
var hitbox_active: bool = false
var active_window_hit_targets: Dictionary = {}
var last_hit_target: String = "-"
var last_hit_damage: int = 0
var last_stagger_applied: float = 0.0
var attack_weapon: Dictionary = {}

func _ready() -> void:
	add_to_group("player")

	# Programmatic visual representation for the player (rotated ship)
	var old_visual = get_node_or_null("BodyVisual")
	if old_visual:
		old_visual.queue_free()
	var poly := Polygon2D.new()
	poly.name = "BodyVisual"
	poly.polygon = PackedVector2Array([
		Vector2(20, 0),    # Tip pointing right (facing)
		Vector2(-16, -14), # Bottom left
		Vector2(-8, 0),    # Rear indent
		Vector2(-16, 14)   # Top left
	])
	poly.color = Color("bf5b30") # premium rust orange
	add_child(poly)

	# Programmatic collision shape for physical movement
	var old_col = get_node_or_null("BodyCollision")
	if old_col:
		old_col.queue_free()
	var col := CollisionShape2D.new()
	col.name = "BodyCollision"
	var col_shape := CircleShape2D.new()
	col_shape.radius = 16.0
	col.shape = col_shape
	add_child(col)

	# Programmatic Player HealthComponent
	var hc = get_node_or_null("HealthComponent")
	if hc == null:
		hc = HealthComponent.new()
		hc.name = "HealthComponent"
		hc.max_health = 200
		add_child(hc)
	hc.died.connect(_on_player_died)

	# Programmatic Player StaggerComponent
	if get_node_or_null("StaggerComponent") == null:
		var sc := StaggerComponent.new()
		sc.name = "StaggerComponent"
		sc.stagger_threshold = 100.0
		add_child(sc)

	# Programmatic Player HurtboxComponent
	if get_node_or_null("HurtboxComponent") == null:
		var hb := HurtboxComponent.new()
		hb.name = "HurtboxComponent"
		hb.health_component_path = NodePath("../HealthComponent")
		hb.stagger_component_path = NodePath("../StaggerComponent")
		
		var hb_col := CollisionShape2D.new()
		var hb_shape := CircleShape2D.new()
		hb_shape.radius = 18.0
		hb_col.shape = hb_shape
		hb.add_child(hb_col)
		add_child(hb)

	# Programmatic ManaComponent (Required for Mage class casting in M5)
	if get_node_or_null("ManaComponent") == null:
		var mc := ManaComponent.new()
		mc.name = "ManaComponent"
		mc.max_mana = 100.0
		mc.regen_per_second = 15.0
		mc.regen_delay_after_spend = 0.55
		add_child(mc)
		mana_component = mc

	# Initialize StaminaComponent fallback
	if stamina_component == null:
		stamina_component = get_node_or_null("StaminaComponent")
		stamina = stamina_component

	# Load the JSON weapons configuration
	_load_weapon_data()

	# Configure the default initial weapon shape
	_configure_attack_shape()
	if attack_collision:
		attack_collision.disabled = true

func _process(_delta: float) -> void:
	if input_intent.wants_switch_class_1:
		_set_class(CLASS_BARBARIAN)
	elif input_intent.wants_switch_class_2:
		_set_class(CLASS_ARCHER)
	elif input_intent.wants_switch_class_3:
		_set_class(CLASS_MAGE)
	elif input_intent.wants_cycle_class:
		var next_index := (CLASS_ORDER.find(active_class) + 1) % CLASS_ORDER.size()
		_set_class(CLASS_ORDER[next_index])

	if input_intent.wants_secondary and attack_phase == "idle":
		_cycle_weapon() # RMB weapon swap

func _physics_process(delta: float) -> void:
	input_intent.collect_intent(camera)
	
	if mana_component != null:
		mana = mana_component.current_mana
		
	_update_facing()
	_update_attack_state(delta)
	_update_state(delta)
	_update_active_areas(delta)
	move_and_slide()
	_update_visuals()

	# Melee real-time collision checks during active frames (Barbarian class)
	if hitbox_active and combat_class == "barbarian":
		_resolve_hits()

	if input_intent.wants_reload_scene:
		get_tree().reload_current_scene()

func _update_facing() -> void:
	if state == "DODGING":
		return
	var to_mouse := input_intent.aim_world_position - global_position
	if to_mouse.length() > 1.0:
		facing_direction = to_mouse.normalized()
		rotation = facing_direction.angle()

func _update_state(delta: float) -> void:
	if attack_phase != "idle":
		velocity = Vector2.ZERO
		return

	if state == "DODGING":
		dodge_timer -= delta
		velocity = last_move_vector * dodge_speed
		if dodge_timer <= 0.0:
			state = "RECOVERING"
			recovery_timer = dodge_recovery
		return

	if state == "RECOVERING":
		recovery_timer -= delta
		velocity = input_intent.move_vector * (move_speed * 0.45)
		if recovery_timer <= 0.0:
			state = "IDLE"
		return

	# Handle normal movement
	if input_intent.move_vector.length() > 0.01:
		last_move_vector = input_intent.move_vector.normalized()
		velocity = input_intent.move_vector * move_speed
		state = "MOVING"
	else:
		velocity = Vector2.ZERO
		state = "IDLE"

	# Dodge activation (costs 15 stamina)
	if input_intent.wants_dodge:
		var has_stamina := false
		if stamina_component != null:
			has_stamina = stamina_component.spend(15.0)
		elif stamina != null:
			has_stamina = stamina.spend(15.0)
			
		if has_stamina:
			state = "DODGING"
			dodge_timer = dodge_duration
			velocity = last_move_vector * dodge_speed

func _update_attack_state(delta: float) -> void:
	if attack_phase == "idle":
		if input_intent.wants_primary:
			_start_attack()
		return

	attack_timer -= delta
	if attack_timer > 0.0:
		return

	if attack_phase == "startup":
		attack_phase = "active"
		attack_timer = queued_attack_payload.get("active_ms", 100.0) / 1000.0
		class_state_label = "release"
		_resolve_attack(queued_attack_payload)
		return

	if attack_phase == "active":
		attack_phase = "recovery"
		attack_timer = queued_attack_payload.get("recovery_ms", 100.0) / 1000.0
		class_state_label = "follow_through"
		# Disable real-time physical hitbox overlap checking
		hitbox_active = false
		if attack_collision != null:
			attack_collision.disabled = true
		return

	# Attack sequence finished, return to idle
	attack_phase = "idle"
	queued_attack_payload = {}
	attack_weapon = {}
	class_state_label = "ready"

func _start_attack() -> void:
	if attack_phase != "idle":
		return
	var weapon := _get_active_weapon_dict()
	if weapon.is_empty():
		return
	if !_spend_resource_for_weapon(weapon):
		return
	_update_resources_on_attack()
	queued_attack_payload = weapon.duplicate(true)
	attack_weapon = queued_attack_payload
	attack_phase = "startup"
	attack_timer = float(weapon.get("startup_ms", 0)) / 1000.0
	if combat_class == "archer":
		class_state_label = "draw"
	elif combat_class == "mage":
		class_state_label = "channel"
	else:
		class_state_label = "windup"

	# Clear previous hit target memory for the new swing
	active_window_hit_targets.clear()

func _resolve_attack(weapon: Dictionary) -> void:
	if combat_class == "archer":
		_fire_archer_attack(weapon)
	elif combat_class == "mage":
		_fire_mage_attack(weapon)
	else:
		# Barbarian melee activation: starts continuous real-time hitbox registration
		hitbox_active = true
		if attack_collision != null:
			attack_collision.disabled = false
		_configure_attack_shape()
		_resolve_hits()

func _fire_barbarian_attack(weapon: Dictionary) -> void:
	var reach := float(weapon.get("reach", 2.0))
	var center := global_position + facing_direction * (reach * 32.0)
	var radius := reach * 26.0
	var damage := base_damage
	var stagger := int(weapon.get("stagger_value", 40))
	_apply_radius_damage(center, radius, damage, stagger)

func _fire_archer_attack(weapon: Dictionary) -> void:
	class_state_label = "arrow_flight"
	var reach := float(weapon.get("reach", 12.0))
	var projectile_distance := reach * 32.0
	var impact_center := global_position + facing_direction * projectile_distance
	
	var impact_radius := 16.0
	var damage := 20
	if weapon.get("id", "") == "archer_longbow":
		impact_radius = 24.0
		damage = 35
		
	var stagger := int(weapon.get("stagger_value", 30))
	_apply_line_damage(global_position, impact_center, impact_radius, damage, stagger)

func _fire_mage_attack(weapon: Dictionary) -> void:
	class_state_label = "aoe_bloom"
	var reach := float(weapon.get("reach", 7.0))
	var impact_center := global_position + facing_direction * (reach * 24.0)
	var radius := 52.0
	var damage := 15
	if weapon.get("id", "") == "mage_fire_staff":
		radius = 80.0
		damage = 24
	var stagger := int(weapon.get("stagger_value", 15))
	
	# Apply instant impact bloom damage
	_apply_radius_damage(impact_center, radius, damage, stagger)
	
	# Spawn dynamic periodic burn zone (lingering fire pool)
	var intensity := 4
	var status_list = weapon.get("status_application", [])
	if not status_list.is_empty():
		intensity = int(status_list[0].get("intensity", 4))
	_spawn_burn_zone(impact_center, radius, intensity)

func _spawn_burn_zone(center: Vector2, radius: float, intensity: int) -> void:
	active_areas.append({
		"center": center,
		"radius": radius,
		"duration": 2.5,
		"tick": 0.0,
		"intensity": intensity
	})

func _update_active_areas(delta: float) -> void:
	for area in active_areas:
		area["duration"] -= delta
		area["tick"] -= delta
		if area["tick"] <= 0.0:
			area["tick"] = 0.45
			# Periodic tick damage (smaller than primary impact)
			var tick_damage := maxi(2, int(area["intensity"]))
			_apply_radius_damage(area["center"], area["radius"], tick_damage, 5.0)
	active_areas = active_areas.filter(func(area: Dictionary) -> bool: return area["duration"] > 0.0)

func _apply_radius_damage(center: Vector2, radius: float, amount: int, stagger_amount: float = 20.0) -> void:
	# Scan for valid combat target nodes (Enemies group, Dummy, or AIControllers)
	var targets: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D:
			targets.append(node)
	
	var dummy = get_tree().current_scene.get_node_or_null("Dummy")
	if dummy is Node2D:
		targets.append(dummy)
		
	# Fallback: scan current scene children for AIControllers or Dummy
	for child in get_tree().current_scene.get_children():
		if child is AIController or child.name == "Dummy":
			if child is Node2D and not targets.has(child):
				targets.append(child)

	# Execute hit routing, stagger, and juicy screen hit-stop freeze
	for target in targets:
		if is_instance_valid(target):
			var dist := target.global_position.distance_to(center)
			if dist <= radius:
				var hurtbox = target.get_node_or_null("HurtboxComponent")
				if hurtbox is HurtboxComponent:
					var target_name: String = target.name
					if active_window_hit_targets.has(target_name):
						continue
					active_window_hit_targets[target_name] = true
					
					# Standard damage & stagger routing
					hurtbox.apply_hit(amount, stagger_amount, self)
					
					last_hit_target = target_name
					last_hit_damage = amount
					last_stagger_applied = stagger_amount

					# Hit stop implementation for weights
					var hit_stop_time := float(queued_attack_payload.get("hit_stop_ms", 60)) / 1000.0
					if hit_stop_time > 0.0 and is_inside_tree():
						var tree := get_tree()
						if tree != null:
							Engine.time_scale = 0.05
							await tree.create_timer(hit_stop_time, true, false, true).timeout
							Engine.time_scale = 1.0

func _apply_line_damage(start: Vector2, end: Vector2, width: float, amount: int, stagger_amount: float = 20.0) -> void:
	var targets: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D:
			targets.append(node)
	
	var dummy = get_tree().current_scene.get_node_or_null("Dummy")
	if dummy is Node2D:
		targets.append(dummy)
		
	for child in get_tree().current_scene.get_children():
		if child is AIController or child.name == "Dummy":
			if child is Node2D and not targets.has(child):
				targets.append(child)

	for target in targets:
		if is_instance_valid(target):
			var ab := end - start
			var ap := target.global_position - start
			var ab_len_sq := ab.length_squared()
			var t := 0.0
			if ab_len_sq > 0.0:
				t = clampf(ap.dot(ab) / ab_len_sq, 0.0, 1.0)
			var closest_point := start + ab * t
			var dist := target.global_position.distance_to(closest_point)
			
			if dist <= width:
				var hurtbox = target.get_node_or_null("HurtboxComponent")
				if hurtbox is HurtboxComponent:
					var target_name: String = target.name
					if active_window_hit_targets.has(target_name):
						continue
					active_window_hit_targets[target_name] = true
					
					hurtbox.apply_hit(amount, stagger_amount, self)
					
					last_hit_target = target_name
					last_hit_damage = amount
					last_stagger_applied = stagger_amount

					var hit_stop_time := float(queued_attack_payload.get("hit_stop_ms", 60)) / 1000.0
					if hit_stop_time > 0.0 and is_inside_tree():
						var tree := get_tree()
						if tree != null:
							Engine.time_scale = 0.05
							await tree.create_timer(hit_stop_time, true, false, true).timeout
							Engine.time_scale = 1.0

func _resolve_hits() -> void:
	if attack_area == null:
		return
	var areas := attack_area.get_overlapping_areas()
	for body in areas:
		if is_instance_valid(body) and body is HurtboxComponent:
			var parent = body.get_parent()
			if parent == self:
				continue
			var target_name: String = ""
			if parent != null:
				target_name = parent.name
			else:
				target_name = body.name
			if active_window_hit_targets.has(target_name):
				continue
			active_window_hit_targets[target_name] = true
			
			var stagger_amount := float(attack_weapon.get("stagger_value", 50))
			body.apply_hit(base_damage, stagger_amount, self)
			
			last_hit_target = target_name
			last_hit_damage = base_damage
			last_stagger_applied = stagger_amount
			
			var hit_stop_time := float(attack_weapon.get("hit_stop_ms", 80)) / 1000.0
			if hit_stop_time > 0.0 and is_inside_tree():
				var tree := get_tree()
				if tree != null:
					Engine.time_scale = 0.05
					await tree.create_timer(hit_stop_time, true, false, true).timeout
					Engine.time_scale = 1.0

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _spend_resource_for_weapon(weapon: Dictionary) -> bool:
	var cost := float(weapon.get("resource_cost", 0.0))
	var resource_type := String(weapon.get("resource_type", "stamina"))
	if resource_type == "mana":
		if mana_component == null:
			return false
		return mana_component.spend(cost)
	if stamina_component != null:
		return stamina_component.spend(cost)
	elif stamina != null:
		return stamina.spend(cost)
	return true

func _set_class(new_class: String) -> void:
	if active_class == new_class:
		return
	active_class = new_class
	combat_class = active_class.to_lower()
	class_index = CLASS_ORDER.find(active_class)
	active_weapon_index = int(weapon_index_by_class.get(combat_class, 0))
	class_state_label = "ready"
	_configure_attack_shape()
	EventBus.debug_message.emit("Class switched to %s. Active weapon: %s" % [active_class, get_active_weapon()])

func _cycle_weapon() -> void:
	if attack_phase != "idle":
		return
	var weapon_ids: Array = class_weapons.get(combat_class, [])
	if weapon_ids.is_empty():
		return
	var new_idx := posmod(int(weapon_index_by_class.get(combat_class, 0)) + 1, weapon_ids.size())
	weapon_index_by_class[combat_class] = new_idx
	active_weapon_index = new_idx
	_configure_attack_shape()
	EventBus.debug_message.emit("Weapon swapped to %s" % get_active_weapon())

func _get_active_weapon_dict() -> Dictionary:
	var weapon_ids: Array = class_weapons.get(combat_class, [])
	if weapon_ids.is_empty():
		return {}
	var idx: int = int(weapon_index_by_class.get(combat_class, 0))
	var weapon_id: String = weapon_ids[idx]
	return weapons_by_id.get(weapon_id, {})

func _get_active_weapon() -> Dictionary:
	return _get_active_weapon_dict()

func get_active_weapon() -> String:
	var weapons: Array = CLASS_WEAPONS.get(active_class, [])
	if weapons.is_empty():
		return "Unarmed"
	return str(weapons[active_weapon_index])

func get_debug_overlay_lines() -> PackedStringArray:
	var class_hint := "[1] Barbarian [2] Archer [3] Mage | [C] Cycle | RMB Swap"
	var resources := "Rage %.0f | Focus %.0f | Mana %.0f" % [rage, focus, mana]
	return PackedStringArray([
		"Class: %s" % active_class,
		"Weapon: %s" % get_active_weapon(),
		"Switch: %s" % class_hint,
		"Resources: %s" % resources
	])

func _update_resources_on_attack() -> void:
	match active_class:
		CLASS_BARBARIAN:
			rage = min(rage + 15.0, 100.0)
		CLASS_ARCHER:
			focus = max(focus - 10.0, 0.0)
		CLASS_MAGE:
			if mana_component == null:
				mana = max(mana - 12.0, 0.0)

func _configure_attack_shape() -> void:
	var weapon := _get_active_weapon_dict()
	if weapon.is_empty() or attack_area == null or attack_collision == null:
		return
	var reach := float(weapon.get("reach", 2.0))
	var radius := 36.0
	if weapon.get("id", "") == "barbarian_heavy_axe":
		radius = 52.0
	elif weapon.get("id", "") == "barbarian_maul":
		radius = 46.0
	var shape := CircleShape2D.new()
	shape.radius = radius + (reach * 8.0)
	attack_collision.shape = shape
	attack_area.position = Vector2(reach * 12.0, 0)

func _update_visuals() -> void:
	queue_redraw()
	var visual = get_node_or_null("BodyVisual")
	if visual is Polygon2D:
		if state == "DODGING":
			visual.color = Color("38b2ac") # premium cyan/teal dodge
		elif attack_phase == "startup":
			visual.color = Color("ecc94b") # premium golden yellow
		elif attack_phase == "active":
			visual.color = Color("e53e3e") # premium active crimson/red
		elif attack_phase == "recovery":
			visual.color = Color("718096") # premium muted slate gray
		else:
			# Premium class colors
			if combat_class == "barbarian":
				visual.color = Color("bf5b30") # premium rust orange
			elif combat_class == "archer":
				visual.color = Color("2f855a") # premium hunter green
			elif combat_class == "mage":
				visual.color = Color("805ad5") # premium wizard purple
			else:
				visual.color = Color("bf5b30")

func _draw() -> void:
	# Render the dynamic weapon indicator overlays (startup windup, active slice/bloom/arrow path)
	var weapon := _get_active_weapon_dict()
	if weapon.is_empty():
		return

	var reach := float(weapon.get("reach", 2.0))

	if combat_class == "barbarian" and attack_phase != "idle":
		var radius := 36.0
		var angle_span := 65.0
		if weapon.get("id", "") == "barbarian_heavy_axe":
			radius = 52.0
			angle_span = 105.0
		elif weapon.get("id", "") == "barbarian_maul":
			radius = 46.0
			angle_span = 55.0
		
		var arc_radius := radius + (reach * 8.0)
		var center := Vector2(reach * 12.0, 0)
		
		if attack_phase == "startup":
			draw_arc(center, arc_radius, -deg_to_rad(angle_span/2), deg_to_rad(angle_span/2), 32, Color("ecc94b", 0.4), 2.0)
		elif attack_phase == "active":
			var points := PackedVector2Array()
			points.append(Vector2.ZERO)
			var steps := 16
			for i in range(steps + 1):
				var angle := -deg_to_rad(angle_span/2) + (i * deg_to_rad(angle_span) / steps)
				points.append(center + Vector2(cos(angle), sin(angle)) * arc_radius)
			draw_polygon(points, [Color("ff4a4a", 0.45)])
			draw_arc(center, arc_radius, -deg_to_rad(angle_span/2), deg_to_rad(angle_span/2), 32, Color("ff8a8a", 0.8), 3.0)

	elif combat_class == "archer" and attack_phase != "idle":
		var arrow_reach := reach * 32.0
		if attack_phase == "startup":
			var dots := 12
			for i in range(dots):
				var t := float(i) / dots
				draw_circle(Vector2(t * arrow_reach, 0), 2.0, Color("ecc94b", 0.6))
		elif attack_phase == "active":
			draw_line(Vector2.ZERO, Vector2(arrow_reach, 0), Color("48bb78", 0.85), 3.0)
			draw_circle(Vector2(arrow_reach, 0), 6.0, Color("48bb78", 0.95))

	elif combat_class == "mage" and attack_phase != "idle":
		var cast_reach := reach * 24.0
		var radius := 52.0
		if weapon.get("id", "") == "mage_fire_staff":
			radius = 80.0
		var center := Vector2(cast_reach, 0)
		if attack_phase == "startup":
			draw_arc(center, radius, 0, TAU, 32, Color("ecc94b", 0.55), 2.0)
			var pulse := absf(sin(Time.get_ticks_msec() * 0.01))
			draw_circle(center, radius * 0.3 * pulse, Color("ecc94b", 0.3))
		elif attack_phase == "active":
			draw_circle(center, radius, Color("ff4a4a", 0.35))
			draw_arc(center, radius, 0, TAU, 32, Color("ff8a8a", 0.85), 3.0)

	# Global un-rotated drawing for lingering Mage burn zones (fire pools)
	for area in active_areas:
		var local_center: Vector2 = (area["center"] - global_position).rotated(-rotation)
		draw_circle(local_center, area["radius"], Color("e53e3e", 0.15))
		draw_arc(local_center, area["radius"], 0, TAU, 32, Color("ecc94b", 0.45), 1.5)

func _load_weapon_data() -> void:
	if !FileAccess.file_exists(WEAPON_DATA_PATH):
		return
	var raw := FileAccess.get_file_as_string(WEAPON_DATA_PATH)
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for weapon in parsed.get("weapons", []):
		if typeof(weapon) == TYPE_DICTIONARY and weapon.has("id"):
			weapons_by_id[weapon["id"]] = weapon

# Threat Model Candidate Interface (Ensures AI threat calculation evaluates player accurately)
func is_alive() -> bool:
	var hc = get_node_or_null("HealthComponent")
	if hc != null:
		return hc.current_health > 0
	return true

func get_health_ratio() -> float:
	var hc = get_node_or_null("HealthComponent")
	if hc != null and hc.max_health > 0:
		return float(hc.current_health) / float(hc.max_health)
	return 1.0

func get_recent_damage_output() -> float:
	return 0.75

func get_focus_value() -> float:
	return 0.5

func _on_player_died(_source: Node) -> void:
	GameState.register_player_death()
	EventBus.debug_message.emit("Player resurrected at watchpost! Resurrection Strain increased.")
	# Reload current scene to simulate resurrection/respawn
	get_tree().reload_current_scene()
