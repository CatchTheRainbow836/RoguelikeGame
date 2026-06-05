extends EdenRemnantMovementState
class_name PhaseTwoRunningEdenRemnantState

var attack_range: float
var boss: EdenRemnant

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as EdenRemnant
	if boss:
		speed = boss.phase2_speed
		accel = boss.phase2_accel
		view_distance = boss.phase1_view_distance
		fov_degrees = boss.phase1_fov_degrees
		attack_range = boss.phase2_attack_range

func enter() -> void :
	super.enter()

func physics_update(delta: float) -> void :
	navigation_agent_3d.target_position = PLAYER.global_position

	var dist = owner.global_position.distance_to(PLAYER.global_position)
	var move_dir = Vector3.ZERO

	if dist <= attack_range:
		_velocity = Vector3.ZERO
		owner.velocity = _velocity
		owner.move_and_slide()
		return

	if not navigation_agent_3d.is_navigation_finished():
		var next_pos = navigation_agent_3d.get_next_path_position()
		move_dir = (next_pos - owner.global_transform.origin)
		move_dir.y = 0.0
		if move_dir.length() > 0.2:
			move_dir = move_dir.normalized()
			pivot.look_at(pivot.global_position + move_dir, Vector3.UP)
			_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
			_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
		else:
			_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
			_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	_look_at_player_smooth(delta)
	owner.velocity = _velocity
	owner.move_and_slide()
