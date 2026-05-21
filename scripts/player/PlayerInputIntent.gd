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
var wants_switch_class: bool = false
var wants_switch_weapon: bool = false

func collect_intent(camera: Camera2D) -> void:
	move_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	wants_primary = Input.is_action_just_pressed("primary_action")
	wants_secondary = Input.is_action_just_pressed("secondary_action")
	wants_dodge = Input.is_action_just_pressed("dodge")
	wants_interact = Input.is_action_just_pressed("interact")
	wants_switch_class = Input.is_action_just_pressed("switch_class")
	wants_switch_weapon = Input.is_action_just_pressed("switch_weapon")

	if camera != null:
		aim_world_position = camera.get_global_mouse_position()
