extends RoleBehavior
class_name EmberTenderBehavior

func get_role_name() -> String:
	return "Support"

func evaluate_state(controller: AIController, _delta: float) -> String:
	if controller.target_actor == null:
		return "IDLE"
	var distance := controller.global_position.distance_to(controller.target_actor.global_position)
	if distance < 150.0:
		return "BACKSTEP_SUPPORT"
	return "ALLY_SCREEN"

func get_desired_velocity(controller: AIController) -> Vector2:
	if controller.target_actor == null:
		return Vector2.ZERO
	var to_target := controller.target_actor.global_position - controller.global_position
	if controller.current_state == "BACKSTEP_SUPPORT":
		return -to_target.normalized() * (controller.move_speed * 0.85)

	var anchor := _find_bruiser_anchor(controller)
	if anchor != null:
		var to_anchor := anchor.global_position - controller.global_position
		return to_anchor.normalized() * (controller.move_speed * 0.6)
	return to_target.normalized() * (controller.move_speed * 0.4)

func _find_bruiser_anchor(controller: AIController) -> Node2D:
	for sibling in controller.get_parent().get_children():
		if sibling is AIController and sibling != controller:
			if sibling.name.contains("Brute"):
				return sibling
	return null
