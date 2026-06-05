extends DefaultEnemyMovementState
class_name RunningMiddenSpitterState

var alert_duration: float
var alert_timer: float = 0.0
var attack_range: float
var preferred_distance: float
var turn_speed: float
var spitter: MiddenSpitter
var strafe_angle: float = 0.0
var strafe_speed: float

func _ready() -> void :
	super._ready()
	await owner.ready
	spitter = owner as MiddenSpitter
	if spitter:
		speed = spitter.speed
		accel = spitter.accel
		view_distance = spitter.view_distance
		fov_degrees = spitter.fov_degrees
		attack_range = spitter.attack_range
		preferred_distance = spitter.preferred_distance
		turn_speed = spitter.turn_speed
		alert_duration = spitter.alert_duration
		strafe_speed = spitter.hover_strafe_speed

func enter() -> void :
	super.enter()
	alert_timer = alert_duration

func exit() -> void :
	super.exit()

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:
		navigation_agent_3d.target_position = PLAYER.global_position
		alert_timer = alert_duration
	else:
		alert_timer -= delta
		if alert_timer <= 0.0:
			transition.emit("WalkingEnemyState")
			return

	var to_player = PLAYER.global_position - owner.global_position
	var dist = to_player.length()
	var dir_to_player = to_player.normalized()

	strafe_angle += delta * strafe_speed
	var right = Vector3(dir_to_player.z, 0, - dir_to_player.x).normalized()
	var strafe_offset = right * sin(strafe_angle) * (preferred_distance * 0.5)

	var desired_offset = - dir_to_player * preferred_distance
	var target_pos = PLAYER.global_position + desired_offset + strafe_offset

	var target_y = spitter.target_altitude + sin(spitter.bob_phase) * spitter.bob_amplitude
	spitter.bob_phase += spitter.bob_frequency * delta
	target_pos.y = target_y

	var move_dir = (target_pos - owner.global_position)
	var horizontal_dist = Vector2(move_dir.x, move_dir.z).length()
	if horizontal_dist > 0.2:
		var hor_dir = Vector3(move_dir.x, 0, move_dir.z).normalized()
		_velocity.x = move_toward(_velocity.x, hor_dir.x * speed, accel * delta)
		_velocity.z = move_toward(_velocity.z, hor_dir.z * speed, accel * delta)
	else:
		_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	var y_error = target_pos.y - owner.global_position.y
	if abs(y_error) > spitter.altitude_tolerance:
		_velocity.y = move_toward(_velocity.y, y_error * 5.0, accel * delta)
	else:
		_velocity.y = move_toward(_velocity.y, 0.0, accel * delta)

	_look_at_player_smooth(delta)

	owner.velocity = _velocity
	owner.move_and_slide()
