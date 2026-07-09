extends DefaultEnemyMovementState
class_name ScrapCrawlerWalkingState

func enter() -> void:
	movement_mode = MovementMode.WANDER
	if control_center:
		current_speed = control_center.walk_speed
		current_accel = control_center.acceleration
	else:
		current_speed = 3.0
		current_accel = 10.0

func physics_update(delta: float) -> void:
	apply_movement(delta, current_speed, current_accel)
