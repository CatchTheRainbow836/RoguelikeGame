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
		look_at_target(control_center.PLAYER.global_position, delta)
