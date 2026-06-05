extends DefaultEnemyMovementState
class_name FurnaceColossusMovementState

func _ready() -> void :
	var root = owner
	while root and not root is FurnaceColossus:
		root = root.get_parent()
	if not root:
		push_error("FurnaceColossusMovementState: Could not find FurnaceColossus root")
		return
	var enemy = root as FurnaceColossus

	mesh_instance_3d = enemy.get_node("MeshInstance3D")
	collision_shape_3d = enemy.get_node("CollisionShape3D")
	pivot = enemy.get_node("Pivot")
	navigation_agent_3d = enemy.get_node("NavigationAgent3D")

	PLAYER = get_tree().get_first_node_in_group("player")
	owner = enemy

	enemy.add_to_group("enemies")

	await get_tree().process_frame

	navigation_agent_3d.max_speed = speed if "max_speed" in navigation_agent_3d else speed
	navigation_agent_3d.avoidance_enabled = false
	_wander_timer = 0.0
	_vision_timer = 0.0
	is_player_visible = false

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
