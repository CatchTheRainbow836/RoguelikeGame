extends EdenRemnantMovementState
class_name PhaseOneRunningEdenRemnantState

var attack_cooldown_timer: float = 0.0

func _ready() -> void :
	super._ready()
	var boss = owner as EdenRemnant
	if boss:
		speed = boss.phase1_speed
		accel = boss.phase1_accel
		view_distance = boss.phase1_view_distance
		fov_degrees = boss.phase1_fov_degrees
		wander_radius = boss.phase1_wander_radius

func enter() -> void :
	super.enter()
	attack_cooldown_timer = 0.0

func physics_update(delta: float) -> void :
	attack_cooldown_timer -= delta
	if attack_cooldown_timer <= 0.0:
		owner.get_node("EdenRemnantStateMachine/PhaseOneStateMachine/AttackStateMachine").on_child_transition("AttackingAttackState")
		attack_cooldown_timer = (owner as EdenRemnant).phase1_attack_cooldown

	_wander_timer -= delta
	if navigation_agent_3d.is_navigation_finished() or _wander_timer <= 0.0:
		if _wander_timer <= 0.0:
			_pick_new_wander_target()
			_wander_timer = wander_interval

	if not navigation_agent_3d.is_navigation_finished():
		var next_pos = navigation_agent_3d.get_next_path_position()
		var move_dir = (next_pos - owner.global_transform.origin)
		move_dir.y = 0.0
		if move_dir.length() > 0.2:
			move_dir = move_dir.normalized()
			pivot.look_at(pivot.global_position + move_dir, Vector3.UP)
			_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
			_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
		else:
			_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
			_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	owner.velocity = _velocity
	owner.move_and_slide()
