extends DefaultEnemyMovementState
class_name RunningPetalFlyerState

var alert_duration: float
var alert_timer: float = 0.0
var turn_speed: float
var flyer: PetalFlyer
var current_direction: Vector3 = Vector3.FORWARD
var _has_triggered_explosion: bool = false

func _ready() -> void :
	super._ready()
	await owner.ready
	flyer = owner as PetalFlyer
	if flyer:
		speed = flyer.speed
		accel = flyer.accel
		view_distance = flyer.view_distance
		fov_degrees = flyer.fov_degrees
		alert_duration = flyer.alert_duration
		turn_speed = flyer.turn_speed

func enter() -> void :
	super.enter()
	alert_timer = alert_duration
	_has_triggered_explosion = false
	if PLAYER:
		current_direction = (PLAYER.global_position - owner.global_position).normalized()
	else:
		current_direction = owner.transform.basis.z

func exit() -> void :
	super.exit()

func physics_update(delta: float) -> void :
	if _has_triggered_explosion:
		return

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

	var target_pos = PLAYER.global_position
	target_pos.y += 0.5
	var desired_dir = (target_pos - owner.global_position).normalized()
	var angle_diff = current_direction.angle_to(desired_dir)
	var max_rotation = turn_speed * delta
	if angle_diff > max_rotation:
		current_direction = current_direction.slerp(desired_dir, max_rotation / angle_diff).normalized()
	else:
		current_direction = desired_dir

	var move_dir = current_direction
	move_dir.y = 0.0
	if move_dir.length() > 0.2:
		move_dir = move_dir.normalized()
		_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
		_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
	else:
		_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	maintain_altitude(delta)

	if move_dir.length_squared() > 0.01:
		pivot.look_at(pivot.global_position + move_dir, Vector3.UP)


	owner.velocity = _velocity
	owner.move_and_slide()

	var collision_count = owner.get_slide_collision_count()
	for i in range(collision_count):
		var collision = owner.get_slide_collision(i)
		if collision:
			var collider = collision.get_collider()
			if collider == PLAYER or (collider and not collider.is_in_group("enemies")):
				_trigger_explosion()
				return

	var dist_to_player = owner.global_position.distance_to(PLAYER.global_position)
	if dist_to_player <= 1.2:
		_trigger_explosion()
		return

func maintain_altitude(delta: float) -> void :
	if not flyer:
		return
	var current_y = owner.global_position.y
	var base_y = flyer.target_altitude
	if PLAYER and owner.global_position.distance_to(PLAYER.global_position) < 5.0:
		base_y = PLAYER.global_position.y + 0.5
	var target_y = base_y + sin(flyer.bob_phase) * flyer.bob_amplitude
	flyer.bob_phase += flyer.bob_frequency * delta

	var y_error = target_y - current_y
	if abs(y_error) > flyer.altitude_tolerance:
		_velocity.y = move_toward(_velocity.y, y_error * 5.0, accel * delta)
	else:
		_velocity.y = move_toward(_velocity.y, 0.0, accel * delta)

func _trigger_explosion() -> void :
	if _has_triggered_explosion:
		return
	_has_triggered_explosion = true
	var attack_state_machine = owner.get_node("AttackStateMachine")
	if attack_state_machine and attack_state_machine.has_method("on_child_transition"):
		attack_state_machine.on_child_transition("AttackingAttackState")
	else:
		transition.emit("AttackingAttackState")
