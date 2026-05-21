extends RefCounted
class_name ThreatModel

## Computes threat scores so AI picks by pressure, not nearest-only aggro.

var distance_weight: float = 0.35
var health_weight: float = 0.15
var recent_damage_weight: float = 0.4
var focus_weight: float = 0.1

func choose_target(self_actor: Node2D, candidates: Array[Node2D], fallback: Node2D = null) -> Node2D:
	var best_target: Node2D = fallback
	var best_score: float = -INF

	for candidate in candidates:
		if candidate == null:
			continue
		if not candidate.has_method("is_alive"):
			continue
		if not candidate.is_alive():
			continue

		var score := _score_candidate(self_actor, candidate)
		if score > best_score:
			best_score = score
			best_target = candidate

	return best_target

func _score_candidate(self_actor: Node2D, candidate: Node2D) -> float:
	var distance_score := 0.0
	if self_actor != null:
		var dist := self_actor.global_position.distance_to(candidate.global_position)
		distance_score = 1.0 / max(dist, 24.0)

	var health_score := 0.5
	if candidate.has_method("get_health_ratio"):
		health_score = 1.0 - candidate.get_health_ratio()

	var recent_damage_score := 0.0
	if candidate.has_method("get_recent_damage_output"):
		recent_damage_score = candidate.get_recent_damage_output()

	var focus_score := 0.0
	if candidate.has_method("get_focus_value"):
		focus_score = candidate.get_focus_value()

	return (
		distance_score * distance_weight
		+ health_score * health_weight
		+ recent_damage_score * recent_damage_weight
		+ focus_score * focus_weight
	)
