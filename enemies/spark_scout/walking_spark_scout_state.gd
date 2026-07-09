extends DefaultEnemyMovementState
class_name WalkingSparkScoutState

func enter() -> void:
	movement_mode = MovementMode.WANDER
	if control_center:
		current_speed = control_center.walk_speed
		current_accel = control_center.acceleration
	else:
		current_speed = 4.0
		current_accel = 10.0

func physics_update(delta: float) -> void:
	apply_movement(delta, current_speed, current_accel)
	if control_center:
		var target_y = control_center.target_altitude + sin(control_center._bob_phase) * control_center.bob_amplitude
		maintain_altitude(target_y, delta)
