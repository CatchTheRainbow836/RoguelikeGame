extends DefaultEnemyMovementState
class_name ScrapCrawlerRunningState

func enter() -> void:
	movement_mode = MovementMode.MOVE_TO
	if control_center:
		current_speed = control_center.run_speed
		current_accel = control_center.acceleration
	else:
		current_speed = 6.0
		current_accel = 10.0

func physics_update(delta: float) -> void:
	apply_movement(delta, current_speed, current_accel)
	if control_center and control_center.PLAYER:
		var to_target = control_center.PLAYER.global_position - pivot.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.001:
			var target_transform = pivot.global_transform.looking_at(
				pivot.global_position - to_target, Vector3.UP, true
			)
			pivot.global_transform.basis = pivot.global_transform.basis.slerp(
				target_transform.basis, 6.0 * delta
			)
