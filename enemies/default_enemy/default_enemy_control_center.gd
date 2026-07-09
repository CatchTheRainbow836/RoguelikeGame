class_name DefaultEnemyControlCenter
extends Node

enum AIState { IDLE, PATROL, INVESTIGATE, CHASE, SEARCH }

var owner_enemy: CharacterBody3D
var PLAYER: CharacterBody3D
var pivot: Node3D
var navigation_agent_3d: NavigationAgent3D
var movement_state_machine: StateMachine
var attack_state_machine: StateMachine

var enemy_type: String
var max_health: float
var current_health: float
var attack_damage: float
var attack_range: float
var attack_cooldown: float
var run_speed: float
var walk_speed: float
var acceleration: float
var wander_radius: float
var view_distance: float
var fov_degrees: float
var alert_duration: float

var search_duration: float
var investigate_duration: float
var search_wander_interval: float

var last_alert_strength: float = 0.0
var alert_position: Vector3 = Vector3.ZERO
var last_alert_time: float = -1.0
var alertness_threshold: float = 0.5

var current_ai_state: int = AIState.IDLE

var _patrol_timer: float = 0.0
var _patrol_interval: float = 2.5
var _search_patrol_radius: float = 4.0

var last_seen_player_pos: Vector3 = Vector3.ZERO
var _was_chasing: bool = false

func setup(enemy: CharacterBody3D) -> void:
	owner_enemy = enemy
	pivot = enemy.get_node("Pivot")
	navigation_agent_3d = enemy.get_node("NavigationAgent3D")
	movement_state_machine = enemy.get_node("EnemyStateMachine")
	attack_state_machine = enemy.get_node("AttackStateMachine")
	PLAYER = get_tree().get_first_node_in_group("player")

	var stats = EnemyStats.DATA.get(enemy_type, {})
	max_health = stats.get("max_health", 5.0)
	current_health = max_health
	attack_damage = stats.get("attack_damage", 2.0)
	attack_range = stats.get("attack_range", 2.0)
	attack_cooldown = stats.get("attack_cooldown", 1.0)
	run_speed = stats.get("run_speed", 6.0)
	walk_speed = stats.get("walk_speed", 3.0)
	acceleration = stats.get("acceleration", 10.0)
	wander_radius = stats.get("wander_radius", 8.0)
	view_distance = stats.get("view_distance", 20.0)
	fov_degrees = stats.get("fov_degrees", 90.0)
	alert_duration = stats.get("alert_duration", 5.0)
	search_duration = stats.get("search_duration", 6.0)
	investigate_duration = stats.get("investigate_duration", 8.0)
	search_wander_interval = stats.get("search_wander_interval", 1.5)

	enemy.max_health = max_health
	enemy.current_health = current_health

	_patrol_timer = 0.0

func _physics_process(delta: float) -> void:
	if not owner_enemy or not PLAYER:
		return
	_decide_action(delta)

func _decide_action(delta: float) -> void:
	pass

func can_see_player() -> bool:
	if not PLAYER or not pivot:
		return false

	var to_player = PLAYER.global_transform.origin - pivot.global_transform.origin
	var dist = to_player.length()
	if dist > view_distance:
		return false

	var forward = -pivot.global_transform.basis.z.normalized()
	var dir_norm = to_player.normalized()
	var angle_threshold = cos(deg_to_rad(fov_degrees * 0.5))
	if forward.dot(dir_norm) < angle_threshold:
		return false

	var space = owner_enemy.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = pivot.global_position + Vector3.UP * 0.5
	params.to = PLAYER.global_position + Vector3.UP * 1.0
	params.exclude = [owner_enemy, pivot]
	params.collision_mask = 4294967295
	var res = space.intersect_ray(params)
	return res.size() > 0 and res.get("collider") == PLAYER

func get_alert_info() -> Dictionary:
	var lm = get_node_or_null("/root/LevelManager")
	if not lm or not lm.has_method("add_alert"):
		return {"value": 0.0, "position": Vector3.ZERO}

	var enemy_cell = lm.get_cell_from_world(owner_enemy.global_position)
	var max_val = 0.0
	var best_pos = Vector3.ZERO

	for alert in lm._alerts:
		var direct_vals = alert.get("direct_values", {})
		if enemy_cell in direct_vals:
			var v = direct_vals[enemy_cell]
			if v > max_val:
				max_val = v
				best_pos = Vector3(alert["cell"].x, 0.0, alert["cell"].y)

	return {"value": max_val, "position": best_pos}

func _transition_movement(state_name: String) -> void:
	if movement_state_machine.CURRENT_STATE.name != state_name:
		movement_state_machine.CURRENT_STATE.transition.emit(state_name)

func _transition_attack(state_name: String) -> void:
	if attack_state_machine.CURRENT_STATE.name != state_name:
		attack_state_machine.CURRENT_STATE.transition.emit(state_name)

func ai_state_string() -> String:
	match current_ai_state:
		AIState.IDLE: return "IDLE"
		AIState.PATROL: return "PATROL"
		AIState.INVESTIGATE: return "INVESTIGATE"
		AIState.CHASE: return "CHASE"
		AIState.SEARCH: return "SEARCH"
	return "UNKNOWN"
