extends Node
class_name PlayerInputIntent

## Converts physical input into gameplay intent.
## Gameplay systems should read this intent object, not raw input directly.

var move_vector: Vector2 = Vector2.ZERO
var aim_world_position: Vector2 = Vector2.ZERO
var wants_primary: bool = false
var wants_secondary: bool = false
var wants_dodge: bool = false
var wants_interact: bool = false
var wants_reload_scene: bool = false
var wants_switch_class_1: bool = false
var wants_switch_class_2: bool = false
var wants_switch_class_3: bool = false
var wants_cycle_class: bool = false

func _ready() -> void:
	_ensure_input_action("switch_class_1", KEY_1)
	_ensure_input_action("switch_class_2", KEY_2)
	_ensure_input_action("switch_class_3", KEY_3)
	_ensure_input_action("cycle_class", KEY_C)
	_ensure_input_action("reload_test_scene", KEY_R)
	
	# Add extra F1 binding for reload
	var f1_event := InputEventKey.new()
	f1_event.physical_keycode = KEY_F1 as Key
	InputMap.action_add_event("reload_test_scene", f1_event)

func _ensure_input_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	# Check if the key is already mapped to avoid duplicating events
	var already_mapped := false
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.physical_keycode == keycode:
			already_mapped = true
			break
	
	if not already_mapped:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode as Key
		InputMap.action_add_event(action_name, key_event)

func collect_intent(camera: Camera2D) -> void:
	move_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	wants_primary = Input.is_action_just_pressed("primary_action")
	wants_secondary = Input.is_action_just_pressed("secondary_action")
	wants_dodge = Input.is_action_just_pressed("dodge")
	wants_interact = Input.is_action_just_pressed("interact")
	wants_reload_scene = Input.is_action_just_pressed("reload_test_scene")
	wants_switch_class_1 = Input.is_action_just_pressed("switch_class_1")
	wants_switch_class_2 = Input.is_action_just_pressed("switch_class_2")
	wants_switch_class_3 = Input.is_action_just_pressed("switch_class_3")
	wants_cycle_class = Input.is_action_just_pressed("cycle_class")

	if camera != null:
		aim_world_position = camera.get_global_mouse_position()
