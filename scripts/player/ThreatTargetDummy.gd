extends CharacterBody2D
class_name ThreatTargetDummy

@export var move_speed: float = 190.0
@export var health_ratio: float = 1.0
@export var recent_damage_output: float = 0.25
@export var focus_value: float = 0.5

func _ready() -> void:
	add_to_group("player")

	# Programmatic visual representation for the player dummy (rust-orange triangle)
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
	var col := CollisionShape2D.new()
	var col_shape := CircleShape2D.new()
	col_shape.radius = 16.0
	col.shape = col_shape
	add_child(col)

func _physics_process(_delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * move_speed
	move_and_slide()

func is_alive() -> bool:
	return true

func get_health_ratio() -> float:
	return clamp(health_ratio, 0.0, 1.0)

func get_recent_damage_output() -> float:
	return max(recent_damage_output, 0.0)

func get_focus_value() -> float:
	return max(focus_value, 0.0)
