extends DefaultEnemyMovementState
class_name RunningSovereignWightState

var alert_duration: float
var alert_timer: float = 0.0
var jump_range: float
var preferred_distance: float
var wight: SovereignWight
var can_jump: bool = true

func _ready() -> void :
	super._ready()
	await owner.ready
	wight = owner as SovereignWight
	if wight:
		speed = wight.speed
		accel = wight.accel
		view_distance = wight.view_distance
		fov_degrees = wight.fov_degrees
		jump_range = wight.jump_range
		preferred_distance = wight.preferred_distance
		alert_duration = wight.alert_duration

func enter() -> void :
	super.enter()
	alert_timer = alert_duration
	can_jump = true

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

	var dist_to_player = owner.global_position.distance_to(PLAYER.global_position)

	if can_jump and dist_to_player <= jump_range:
		transition.emit("JumpingEnemyState")
		return

	var to_player = PLAYER.global_position - owner.global_position
	var dir_to_player = to_player.normalized()
	var target_pos = PLAYER.global_position - dir_to_player * preferred_distance
	target_pos.y = owner.global_position.y

	var move_dir = (target_pos - owner.global_position)
	move_dir.y = 0.0
	if move_dir.length() > 0.2:
		move_dir = move_dir.normalized()
		_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
		_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
	else:
		_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	_look_at_player_smooth(delta)

	owner.velocity = _velocity
	owner.move_and_slide()
