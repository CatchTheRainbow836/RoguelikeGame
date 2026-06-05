extends CrucibleCoreMovementState
class_name PhaseThreeRunningCrucibleCoreState

var boss: CrucibleCore
var weapon_type: int
var melee_range: float
var preferred_distance: float = 8.0
var strafe_angle: float = 0.0
var strafe_speed: float = 2.0

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as CrucibleCore

func enter() -> void :
	super.enter()
	if boss.recorded_weapon:
		weapon_type = boss.recorded_weapon.type
		if _is_melee():
			melee_range = boss.recorded_weapon.range
			speed = 6.0
			accel = 10.0
		else:
			speed = 5.0
			accel = 8.0

func physics_update(delta: float) -> void :
	if not PLAYER:
		return
	if _is_melee():
		_melee_movement(delta)
	else:
		_ranged_movement(delta)
	_look_at_player_smooth(delta)
	owner.velocity = _velocity
	owner.move_and_slide()

func _is_melee() -> bool:
	return str(weapon_type).begins_with("2")

func _is_ranged() -> bool:
	return str(weapon_type).begins_with("1")

func _is_grenade() -> bool:
	return str(weapon_type).begins_with("3")

func _melee_movement(delta: float) -> void :
	var to_player = PLAYER.global_position - owner.global_position
	var dist = to_player.length()
	var dir_to_player = to_player.normalized()
	var target_pos = PLAYER.global_position - dir_to_player * melee_range
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

func _ranged_movement(delta: float) -> void :
	var to_player = PLAYER.global_position - owner.global_position
	var dir_to_player = to_player.normalized()
	strafe_angle += delta * strafe_speed
	var right = Vector3(dir_to_player.z, 0, - dir_to_player.x).normalized()
	var strafe_offset = right * sin(strafe_angle) * (preferred_distance * 0.5)
	var desired_offset = - dir_to_player * preferred_distance
	var target_pos = PLAYER.global_position + desired_offset + strafe_offset
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

func _look_at_player_smooth(delta: float) -> void :
	if not pivot or not PLAYER:
		return
	var to_target = PLAYER.global_position - pivot.global_position
	to_target.y = 0.0
	if to_target.length_squared() > 0.001:
		var target_transform = pivot.global_transform.looking_at(
			pivot.global_position - to_target, 
			Vector3.UP, 
			true
		)
		pivot.global_transform.basis = pivot.global_transform.basis.slerp(
			target_transform.basis, 
			6.0 * delta
		)
