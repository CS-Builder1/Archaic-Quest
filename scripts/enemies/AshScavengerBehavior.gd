extends RoleBehavior
class_name AshScavengerBehavior

func get_role_name() -> String:
	return "Skirmisher"

func evaluate_state(controller: AIController, _delta: float) -> String:
	if controller.target_actor == null:
		return "IDLE"
	var distance := controller.global_position.distance_to(controller.target_actor.global_position)
	if distance < 100.0:
		return "RETREAT_BAIT"
	if distance > 210.0:
		return "FLANK_APPROACH"
	return "PUNISH_WINDOW"

func get_desired_velocity(controller: AIController) -> Vector2:
	if controller.target_actor == null:
		return Vector2.ZERO
	var to_target := controller.target_actor.global_position - controller.global_position
	var tangent := Vector2(-to_target.y, to_target.x).normalized()
	if controller.current_state == "RETREAT_BAIT":
		return -to_target.normalized() * (controller.move_speed * 1.1)
	if controller.current_state == "PUNISH_WINDOW":
		return tangent * (controller.move_speed * 0.9)
	return to_target.normalized() * (controller.move_speed * 1.0)
