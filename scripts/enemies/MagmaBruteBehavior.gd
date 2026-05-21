extends RoleBehavior
class_name MagmaBruteBehavior

func get_role_name() -> String:
	return "Bruiser"

func evaluate_state(controller: AIController, _delta: float) -> String:
	if controller.target_actor == null:
		return "IDLE"
	var distance := controller.global_position.distance_to(controller.target_actor.global_position)
	if distance > 120.0:
		return "HEAVY_ADVANCE"
	return "WINDUP_SWING"

func get_desired_velocity(controller: AIController) -> Vector2:
	if controller.target_actor == null:
		return Vector2.ZERO
	var to_target := controller.target_actor.global_position - controller.global_position
	var direction := to_target.normalized()
	if controller.current_state == "WINDUP_SWING":
		return direction * (controller.move_speed * 0.2)
	return direction * (controller.move_speed * 0.55)
