extends Area2D
class_name HurtboxComponent

@export var health_component_path: NodePath
@export var stagger_component_path: NodePath

@onready var health_component: HealthComponent = get_node_or_null(health_component_path)
@onready var stagger_component: StaggerComponent = get_node_or_null(stagger_component_path)

func _ready() -> void:
	# Add a premium visual representation to the dummy
	var poly := Polygon2D.new()
	poly.name = "DummyVisual"
	# Create a circle-like polygon representing the dummy
	var points := PackedVector2Array()
	var segments := 16
	var radius := 28.0
	for i in range(segments):
		var angle := i * 2.0 * PI / segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	poly.polygon = points
	poly.color = Color("3a6b5c") # premium deep sage green
	add_child(poly)

func apply_hit(damage: int, stagger_amount: float, source: Node) -> void:
	if health_component != null:
		health_component.apply_damage(damage, source)
	if stagger_component != null:
		stagger_component.apply_stagger(stagger_amount)
	
	# Visual juicy feedback: flash red on hit
	var visual = get_node_or_null("DummyVisual")
	if visual == null:
		visual = get_parent().get_node_or_null("BodyVisual")
	if visual is Polygon2D:
		var orig_color: Color = visual.color
		visual.color = Color("ff4a4a") # juicy glowing red flash
		await get_tree().create_timer(0.08, true, false, true).timeout
		visual.color = orig_color

