extends LeviathanMovementState
class_name PhaseTwoRunningLeviathanState

var melee_range: float
var boss: Leviathan

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as Leviathan
	if boss:
		speed = boss.phase2_speed
		accel = boss.phase2_accel
		melee_range = boss.phase2_melee_range
		view_distance = 30.0

func enter() -> void :
	super.enter()

func physics_update(delta: float) -> void :
	if not PLAYER:
		return

	var to_player = PLAYER.global_position - owner.global_position
	var dist_to_player = to_player.length()
	var move_dir = Vector3.ZERO

	if dist_to_player <= melee_range:
		_velocity = Vector3.ZERO
	else:
		move_dir = to_player.normalized()
		move_dir.y = 0.0
		if move_dir.length() > 0.2:
			pivot.look_at(pivot.global_position + move_dir, Vector3.UP)
			_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
			_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
		else:
			_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
			_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	_look_at_player_smooth(delta)

	owner.velocity = _velocity
	owner.move_and_slide()
