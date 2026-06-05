extends DefaultEnemyMovementState
class_name IdleSlagMiteState

func enter() -> void :
	pass

func exit() -> void :
	pass

func physics_update(delta: float) -> void :
	if owner.is_dying:
		_velocity = Vector3.ZERO
		owner.velocity = _velocity
		owner.move_and_slide()
		return

	_vision_timer -= delta

	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:
		transition.emit("RunningEnemyState")
	else:
		transition.emit("WalkingEnemyState")

	owner.velocity = _velocity
	owner.move_and_slide()
