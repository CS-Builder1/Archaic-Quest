extends RefCounted
class_name RoleBehavior

func get_role_name() -> String:
	return "Role"

func evaluate_state(controller: AIController, _delta: float) -> String:
	if controller.target_actor == null:
		return "IDLE"
	return "HOLD"

func get_desired_velocity(controller: AIController) -> Vector2:
	if controller.target_actor == null:
		return Vector2.ZERO
	var to_target := controller.target_actor.global_position - controller.global_position
	return to_target.normalized() * controller.move_speed
