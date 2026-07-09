extends DefaultEnemyMovementState
class_name RunningSparkScoutState

func enter() -> void:
	movement_mode = MovementMode.MOVE_TO
	current_speed = control_center.run_speed
	current_accel = control_center.acceleration


func physics_update(delta: float) -> void:
	apply_movement(delta, current_speed, current_accel)
	#var target_y = control_center.target_altitude + sin(control_center._bob_phase) * control_center.bob_amplitude
	var target_y = control_center.target_altitude\
	 + control_center.bob_amplitude * (
		sin(randf_range(0, TAU) + control_center.bob_frequency * (0.9 + float(owner.get_instance_id() % 100) / 500) * delta)
		+ 0.3 * sin (randf_range(0, TAU) + 2.31)
	)
	
	maintain_altitude(target_y, delta)
	if control_center.look_target != Vector3.ZERO:
		look_at_target(control_center.look_target, delta)
