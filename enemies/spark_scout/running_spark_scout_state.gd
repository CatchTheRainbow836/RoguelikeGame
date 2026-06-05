extends DefaultEnemyMovementState
class_name RunningSparkScoutState

var alert_duration: float
var alert_timer: float = 0.0
var attack_range: float
var preferred_distance: float
var turn_speed: float
var scout: SparkScout
var hover_angle: float = 0.0

var last_known_player_pos: Vector3

func _ready() -> void :
	super._ready()
	await owner.ready
	scout = owner as SparkScout
	if scout:
		speed = scout.speed
		accel = scout.accel
		view_distance = scout.attack_range
		attack_range = scout.attack_range
		preferred_distance = scout.preferred_distance
		turn_speed = scout.turn_speed
		alert_duration = scout.alert_duration

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
		last_known_player_pos = PLAYER.global_position
	else:
		alert_timer -= delta
		if alert_timer <= 0.0:
			transition.emit("WalkingEnemyState")
			return

	var target_pos: Vector3
	if is_player_visible:
		var to_player = PLAYER.global_position - owner.global_position
		var dist_to_player = to_player.length()
		var dir_to_player = to_player.normalized()

		if dist_to_player <= attack_range:

			hover_angle += delta * scout.hover_strafe_speed

			var right = Vector3(dir_to_player.z, 0, - dir_to_player.x).normalized()
			var strafe_offset = right * sin(hover_angle) * (preferred_distance * 0.5)
			var ideal_position = PLAYER.global_position - dir_to_player * preferred_distance
			target_pos = ideal_position + strafe_offset
		else:

			var desired_offset = - dir_to_player * preferred_distance
			target_pos = PLAYER.global_position + desired_offset

		var target_y = scout.target_altitude + sin(scout.bob_phase) * scout.bob_amplitude
		scout.bob_phase += scout.bob_frequency * delta
		target_pos.y = target_y
	else:

		target_pos = owner.global_position
		target_pos.y = scout.target_altitude + sin(scout.bob_phase) * scout.bob_amplitude
		scout.bob_phase += scout.bob_frequency * delta

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
	if abs(y_error) > scout.altitude_tolerance:
		_velocity.y = move_toward(_velocity.y, y_error * 5.0, accel * delta)
	else:
		_velocity.y = move_toward(_velocity.y, 0.0, accel * delta)

	if is_player_visible and PLAYER:
		var target_dir = PLAYER.global_position - pivot.global_position
		target_dir.y = 0.0
		if target_dir.length_squared() > 0.001:
			var target_transform = pivot.global_transform.looking_at(
				pivot.global_position + target_dir, 
				Vector3.UP
			)
			pivot.global_transform.basis = pivot.global_transform.basis.slerp(
				target_transform.basis, 
				turn_speed * delta
			)
	elif alert_timer > 0 and last_known_player_pos:
		var target_dir = last_known_player_pos - pivot.global_position
		target_dir.y = 0.0
		if target_dir.length_squared() > 0.001:
			var target_transform = pivot.global_transform.looking_at(
				pivot.global_position + target_dir, 
				Vector3.UP
			)
			pivot.global_transform.basis = pivot.global_transform.basis.slerp(
				target_transform.basis, 
				turn_speed * delta * 0.5
			)

	owner.velocity = _velocity
	owner.move_and_slide()
