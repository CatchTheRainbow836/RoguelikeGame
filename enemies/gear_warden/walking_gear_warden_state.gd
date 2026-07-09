extends DefaultEnemyMovementState
class_name WalkingGearWardenState

func enter() -> void:
	movement_mode = MovementMode.WANDER
	if control_center:
		current_speed = control_center.walk_speed
		current_accel = control_center.acceleration
	else:
		current_speed = 2.5
		current_accel = 8.0

func physics_update(delta: float) -> void:
	apply_movement(delta, current_speed, current_accel)
	if control_center and control_center.look_target != Vector3.ZERO:
		look_at_target(control_center.look_target, delta)
