class_name DefaultEnemyMovementState
extends State

enum MovementMode { IDLE, WANDER, MOVE_TO }

var owner_enemy: CharacterBody3D
var pivot: Node3D
var navigation_agent_3d: NavigationAgent3D
var control_center: DefaultEnemyControlCenter

var movement_mode: int = MovementMode.IDLE
var current_speed: float = 0.0
var current_accel: float = 10.0

func can_see_player():
	pass
var vision_check_interval
var _wander_timer
func _pick_new_wander_target():
	pass
var wander_interval
var PLAYER

var _velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	await owner.ready
	owner_enemy = owner as CharacterBody3D
	pivot = owner_enemy.get_node("Pivot")
	navigation_agent_3d = owner_enemy.get_node("NavigationAgent3D")
	control_center = owner_enemy.get_node("EnemyControlCenter") if owner_enemy.has_node("EnemyControlCenter") else null

func apply_movement(delta: float, speed: float, accel_val: float) -> void:
	if not owner_enemy or not navigation_agent_3d:
		return

	if speed <= 0.0:
		_velocity.x = move_toward(_velocity.x, 0.0, accel_val * delta)
		_velocity.z = move_toward(_velocity.z, 0.0, accel_val * delta)
	else:
		if navigation_agent_3d.is_navigation_finished():
			_velocity.x = move_toward(_velocity.x, 0.0, accel_val * delta)
			_velocity.z = move_toward(_velocity.z, 0.0, accel_val * delta)
		else:
			var next_pos = navigation_agent_3d.get_next_path_position()
			var move_dir = (next_pos - owner_enemy.global_transform.origin)
			move_dir.y = 0.0
			if move_dir.length() > 0.2:
				move_dir = move_dir.normalized()
				pivot.look_at(pivot.global_position + move_dir, Vector3.UP)
				_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel_val * delta)
				_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel_val * delta)
			else:
				_velocity.x = move_toward(_velocity.x, 0.0, accel_val * delta)
				_velocity.z = move_toward(_velocity.z, 0.0, accel_val * delta)

	owner_enemy.velocity = _velocity
	owner_enemy.move_and_slide()

func look_at_target(target: Vector3, delta: float, turn_speed: float = 6.0) -> void:
	if not pivot:
		return
	var to_target = target - pivot.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.001:
		return
	var target_transform = pivot.global_transform.looking_at(
		pivot.global_position - to_target,
		Vector3.UP,
		true
	)
	pivot.global_transform.basis = pivot.global_transform.basis.slerp(
		target_transform.basis,
		turn_speed * delta
	)
