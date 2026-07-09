extends DefaultEnemyMovementState
class_name IdleArcTurretState

var _rotate_timer: float = 0.0
var _target_yaw: float = 0.0

func enter() -> void:
	movement_mode = MovementMode.IDLE
	current_speed = 0.0
	current_accel = 0.0
	_target_yaw = pivot.rotation.y
	_rotate_timer = 0.0

func physics_update(delta: float) -> void:
	if not control_center:
		return

	_rotate_timer -= delta
	if _rotate_timer <= 0.0:
		var current_yaw = pivot.rotation.y
		var max_delta = deg_to_rad(control_center.idle_rotate_range)
		var new_yaw = current_yaw + randf_range(-max_delta, max_delta)
		_target_yaw = new_yaw
		_rotate_timer = control_center.idle_rotate_interval

	var current_yaw = pivot.rotation.y
	var angle_diff = wrapf(_target_yaw - current_yaw, -PI, PI)
	var step = control_center.idle_rotate_speed * delta
	if abs(angle_diff) > step:
		current_yaw += step * sign(angle_diff)
	else:
		current_yaw = _target_yaw
	pivot.rotation.y = current_yaw

	_velocity = Vector3.ZERO
	owner_enemy.velocity = _velocity
	owner_enemy.move_and_slide()
