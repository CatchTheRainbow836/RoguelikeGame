extends DefaultEnemyMovementState
class_name IdleNectarShadeState

var shade: NectarShade

func _ready() -> void :
	super._ready()
	await owner.ready
	shade = owner as NectarShade
	if shade:
		speed = shade.speed
		accel = shade.accel
		view_distance = shade.view_distance
		fov_degrees = shade.fov_degrees
		wander_radius = shade.wander_radius

func enter() -> void :
	pass

func exit() -> void :
	pass

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:
		transition.emit("RunningEnemyState")
	else:
		transition.emit("WalkingEnemyState")

	maintain_altitude(delta)
	_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
	_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	owner.velocity = _velocity
	owner.move_and_slide()

func maintain_altitude(delta: float) -> void :
	if not shade:
		return
	var current_y = owner.global_position.y
	var target_y = shade.target_altitude + sin(shade.bob_phase) * shade.bob_amplitude
	shade.bob_phase += shade.bob_frequency * delta

	var y_error = target_y - current_y
	if abs(y_error) > shade.altitude_tolerance:
		_velocity.y = move_toward(_velocity.y, y_error * 5.0, accel * delta)
	else:
		_velocity.y = move_toward(_velocity.y, 0.0, accel * delta)
