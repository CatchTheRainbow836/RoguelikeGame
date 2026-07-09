extends DefaultEnemyMovementState
class_name RunningArcTurretState

func enter() -> void:
	movement_mode = MovementMode.MOVE_TO
	current_speed = 0.0
	current_accel = 0.0

func physics_update(delta: float) -> void:
	if control_center and control_center.look_target != Vector3.ZERO:
		look_at_target(control_center.look_target, delta, control_center.turn_speed)

	_velocity = Vector3.ZERO
	owner_enemy.velocity = _velocity
	owner_enemy.move_and_slide()
