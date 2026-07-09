extends DefaultEnemyMovementState
class_name IdleScrapCrawlerState

func enter() -> void:
	movement_mode = MovementMode.IDLE
	current_speed = 0.0
	current_accel = control_center.acceleration if control_center else 10.0

func physics_update(delta: float) -> void:
	apply_movement(delta, 0.0, current_accel)
