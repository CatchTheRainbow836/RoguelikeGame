extends DefaultEnemyMovementState
class_name RunningDefaultEnemyState

signal can_attack(active: bool)

func enter() -> void :
	can_attack.emit(true)

func exit() -> void :
	can_attack.emit(false)

func physics_update(delta: float) -> void :
	_vision_timer -= delta

	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:

		_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)
		_look_at_player_smooth(delta)

		navigation_agent_3d.target_position = owner.global_position
	else:
		transition.emit("WalkingEnemyState")

	owner.velocity = _velocity
	owner.move_and_slide()
