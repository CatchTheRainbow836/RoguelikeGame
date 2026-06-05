extends DefaultEnemyMovementState
class_name IdleSparkScoutState

var scout: SparkScout

func _ready() -> void :
	super._ready()
	await owner.ready
	scout = owner as SparkScout
	if scout:
		speed = scout.speed
		accel = scout.accel
		view_distance = scout.attack_range
		wander_radius = scout.wander_radius

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
		maintain_altitude(delta)
		_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	owner.velocity = _velocity
	owner.move_and_slide()

func maintain_altitude(delta: float) -> void :
	if not scout:
		return
	var current_y = owner.global_position.y
	var target_y = scout.target_altitude + sin(scout.bob_phase) * scout.bob_amplitude
	scout.bob_phase += scout.bob_frequency * delta

	var y_error = target_y - current_y
	if abs(y_error) > scout.altitude_tolerance:
		_velocity.y = move_toward(_velocity.y, y_error * 5.0, accel * delta)
	else:
		_velocity.y = move_toward(_velocity.y, 0.0, accel * delta)
