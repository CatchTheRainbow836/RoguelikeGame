extends DefaultEnemyControlCenter
class_name ScrapCrawlerControlCenter

var _search_timer: float = 0.0
var _investigate_timer: float = 0.0
var _search_duration: float = 10.0
var _investigate_duration: float = 8.0

var _search_origin: Vector3 = Vector3.ZERO

func _decide_action(delta: float) -> void:
	if can_see_player():
		last_seen_player_pos = PLAYER.global_position
		_was_chasing = true

		current_ai_state = AIState.CHASE
		navigation_agent_3d.target_position = PLAYER.global_position

		var dist = owner_enemy.global_position.distance_to(PLAYER.global_position)
		if dist <= attack_range:
			_transition_movement("IdleEnemyState")
		else:
			_transition_movement("RunningEnemyState")
		_transition_attack("AttackingAttackState")
		return

	if _was_chasing:
		_was_chasing = false
		current_ai_state = AIState.SEARCH
		_search_timer = _search_duration
		_search_origin = last_seen_player_pos
		navigation_agent_3d.target_position = _search_origin
		_transition_movement("RunningEnemyState")
		_transition_attack("IdleAttackState")
		return

	var alert_data = get_alert_info()
	var alert_value = alert_data.get("value", 0.0)
	var alert_pos = alert_data.get("position", Vector3.ZERO)

	if alert_value > alertness_threshold:
		last_alert_strength = alert_value
		alert_position = alert_pos
		last_alert_time = Time.get_ticks_msec() / 1000.0

		var dist_to_alert = owner_enemy.global_position.distance_to(alert_position)
		var ignore = false

		if last_alert_strength < 0.7 and dist_to_alert > 15.0:
			ignore = randf() < 0.8
		elif last_alert_strength < 0.9 and dist_to_alert > 10.0:
			ignore = randf() < 0.4

		if not ignore:
			current_ai_state = AIState.INVESTIGATE
			_transition_attack("IdleAttackState")
			_transition_movement("RunningEnemyState")
			navigation_agent_3d.target_position = alert_position
			_investigate_timer = _investigate_duration
			if dist_to_alert < 1.5:
				_search_origin = alert_position
				_enter_search_state()
			return

	match current_ai_state:
		AIState.SEARCH:
			_handle_search(delta)
		AIState.INVESTIGATE:
			_handle_investigate(delta)
		_:
			current_ai_state = AIState.PATROL
			_transition_attack("IdleAttackState")
			_handle_patrol(delta)

func _enter_search_state() -> void:
	current_ai_state = AIState.SEARCH
	_search_timer = _search_duration
	_transition_movement("RunningEnemyState")
	_pick_search_target()

func _handle_search(delta: float) -> void:
	_search_timer -= delta
	if _search_timer <= 0.0:
		current_ai_state = AIState.PATROL
		return
	if navigation_agent_3d.is_navigation_finished():
		_pick_search_target()

func _handle_investigate(delta: float) -> void:
	_investigate_timer -= delta
	if _investigate_timer <= 0.0 or navigation_agent_3d.is_target_reachable() == false:
		_search_origin = alert_position
		_enter_search_state()

func _handle_patrol(delta: float) -> void:
	_patrol_timer -= delta
	if _patrol_timer <= 0.0 or navigation_agent_3d.is_navigation_finished():
		_pick_new_wander_target()
		_patrol_timer = _patrol_interval
	_transition_movement("WalkingEnemyState")

func _pick_search_target() -> void:
	var offset = Vector3(
		randf_range(-_search_patrol_radius, _search_patrol_radius),
		0,
		randf_range(-_search_patrol_radius, _search_patrol_radius)
	)
	navigation_agent_3d.target_position = _search_origin + offset

func _pick_new_wander_target() -> void:
	if not navigation_agent_3d:
		return
	var origin = owner_enemy.global_position
	var offset = Vector3(
		randf_range(-wander_radius, wander_radius),
		0,
		randf_range(-wander_radius, wander_radius)
	)
	var candidate = origin + offset
	for i in range(5):
		navigation_agent_3d.target_position = candidate
		if navigation_agent_3d.is_target_reachable():
			break
		offset *= 0.7
		candidate = origin + offset
