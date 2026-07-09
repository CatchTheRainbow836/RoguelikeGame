extends DefaultEnemyControlCenter
class_name ArcTurretControlCenter

var _search_timer: float = 0.0
var _investigate_timer: float = 0.0

func _decide_action(delta: float) -> void:
	if can_see_player():
		last_seen_player_pos = PLAYER.global_position
		_was_chasing = true

		current_ai_state = AIState.CHASE
		look_target = PLAYER.global_position
		_transition_movement("RunningEnemyState")
		_transition_attack("AttackingAttackState")
		return

	if _was_chasing:
		_was_chasing = false
		current_ai_state = AIState.SEARCH
		_search_timer = search_duration
		look_target = last_seen_player_pos
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

		current_ai_state = AIState.INVESTIGATE
		look_target = alert_position
		_transition_movement("RunningEnemyState")
		_transition_attack("IdleAttackState")
		_investigate_timer = investigate_duration
		return

	current_ai_state = AIState.IDLE
	_transition_attack("IdleAttackState")

	match current_ai_state:
		AIState.SEARCH:
			_handle_search(delta)
		AIState.INVESTIGATE:
			_handle_investigate(delta)
		_:
			_transition_movement("IdleEnemyState")

func _handle_search(delta: float) -> void:
	_search_timer -= delta
	if _search_timer <= 0.0:
		current_ai_state = AIState.IDLE

func _handle_investigate(delta: float) -> void:
	_investigate_timer -= delta
	if _investigate_timer <= 0.0:
		current_ai_state = AIState.IDLE
