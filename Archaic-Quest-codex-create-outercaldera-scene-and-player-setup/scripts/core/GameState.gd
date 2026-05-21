extends Node

## Prototype world-state authority for the local vertical slice.
## Multiplayer/server authority comes later; V1 is a local simulation.

var outer_caldera_state: Dictionary = {
	"ecology_pressure": 50,
	"threat_density": 50,
	"trade_health": 50,
	"resurrection_strain": 25,
	"embersteel_supply": 50,
	"fire_beast_population": 50,
	"ash_scavenger_pressure": 20,
	"black_market_pressure": 0,
	"faction_pressure": {
		"concord": 20,
		"circle": 35,
		"meridian": 25,
		"uncontrolled": 40,
	},
	"control_node_owner": "UNCONTROLLED",
	"settlement_state": "BASELINE",
	"dungeon_state": "DORMANT",
}

func set_world_value(key: String, value: Variant) -> void:
	if !outer_caldera_state.has(key):
		push_warning("Unknown world-state key: %s" % key)
		return
	var old_value: Variant = outer_caldera_state[key]
	outer_caldera_state[key] = value
	EventBus.emit_world_change(key, old_value, value)

func adjust_world_value(key: String, amount: int) -> void:
	if !outer_caldera_state.has(key):
		push_warning("Unknown world-state key: %s" % key)
		return
	var current: Variant = outer_caldera_state[key]
	if typeof(current) != TYPE_INT and typeof(current) != TYPE_FLOAT:
		push_warning("World-state key is not numeric: %s" % key)
		return
	set_world_value(key, clampi(int(current) + amount, 0, 100))

func register_player_death() -> void:
	adjust_world_value("resurrection_strain", 8)
	adjust_world_value("threat_density", 2)

func register_fire_beast_overhunt() -> void:
	adjust_world_value("fire_beast_population", -10)
	adjust_world_value("ecology_pressure", 8)
	adjust_world_value("ash_scavenger_pressure", 10)

func reset_slice_state() -> void:
	outer_caldera_state = {
		"ecology_pressure": 50,
		"threat_density": 50,
		"trade_health": 50,
		"resurrection_strain": 25,
		"embersteel_supply": 50,
		"fire_beast_population": 50,
		"ash_scavenger_pressure": 20,
		"black_market_pressure": 0,
		"faction_pressure": {
			"concord": 20,
			"circle": 35,
			"meridian": 25,
			"uncontrolled": 40,
		},
		"control_node_owner": "UNCONTROLLED",
		"settlement_state": "BASELINE",
		"dungeon_state": "DORMANT",
	}
	EventBus.debug_message.emit("Outer Caldera state reset.")
