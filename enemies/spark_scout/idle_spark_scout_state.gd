extends DefaultEnemyMovementState
class_name IdleSparkScoutState

func enter() -> void:
	movement_mode = MovementMode.IDLE
	current_speed = 0.0
	current_accel = control_center.acceleration if control_center else 10.0

func physics_update(delta: float) -> void:
	apply_movement(delta, 0.0, current_accel)
	if control_center:
		var target_y = control_center.target_altitude + sin(control_center._bob_phase) * control_center.bob_amplitude
		maintain_altitude(target_y, delta)
	
	look_at_target(control_center.look_target, delta)
