extends DefaultEnemyMovementState
class_name IdleGearWardenState

func enter() -> void:
	movement_mode = MovementMode.IDLE
	current_speed = 0.0
	current_accel = control_center.acceleration if control_center else 8.0

func physics_update(delta: float) -> void:
	apply_movement(delta, 0.0, current_accel)
	if control_center and control_center.look_target != Vector3.ZERO:
		look_at_target(control_center.look_target, delta)
