extends LeviathanAttackState
class_name PhaseThreePushLeviathanAttackState

var boss: Leviathan
var wall_width: float
var wall_height: float
var wall_thickness: float
var wall_speed: float
var wall_max_distance: float
var push_distance: float
var push_duration: float = 0.35
var wall_color: Color
var wall_count: int = 3
var spawn_area_radius: float = 50.0

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as Leviathan
	if boss:
		wall_width = boss.phase3_wall_width
		wall_height = boss.phase3_wall_height
		wall_thickness = boss.phase3_wall_thickness
		wall_speed = boss.phase3_wall_speed
		wall_max_distance = boss.phase3_wall_max_distance
		push_distance = boss.phase3_push_distance
		wall_color = boss.phase3_wall_color

func enter() -> void :
	super.enter()
	_cast_walls()
	await get_tree().process_frame
	transition.emit("IdleAttackState")

func _cast_walls() -> void :
	if not PLAYER:
		return
	var positions = _get_random_spawn_positions()
	for pos in positions:
		_create_wall_at_position(pos)

func _get_random_spawn_positions() -> Array:
	if not PLAYER:
		return []
	var player_pos = PLAYER.global_position
	var positions = []
	var min_distance = 3.0
	var max_attempts = 50
	for i in range(wall_count):
		var attempts = 0
		var valid = false
		var candidate: Vector3
		while not valid and attempts < max_attempts:
			var angle = randf_range(0, TAU)
			var radius = randf_range(2.0, spawn_area_radius)
			var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
			candidate = player_pos + offset
			candidate.y = 0
			valid = true
			for pos in positions:
				if candidate.distance_to(pos) < min_distance:
					valid = false
					break
			attempts += 1
		if valid:
			positions.append(candidate)
		else:
			var angle = (TAU / wall_count) * i
			var offset = Vector3(cos(angle) * 4.0, 0, sin(angle) * 4.0)
			positions.append(player_pos + offset)
	return positions

func _create_wall_at_position(start_pos: Vector3) -> void :
	if not PLAYER:
		return

	var direction = (PLAYER.global_position - start_pos).normalized()
	direction.y = 0.0
	if direction.length() < 0.001:
		direction = Vector3.FORWARD

	var wall_container = Node3D.new()
	wall_container.name = "PushWall"
	owner.get_parent().add_child(wall_container)

	var wall_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(wall_width, wall_height, wall_thickness)
	wall_mesh.mesh = box_mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = wall_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mesh.material_override = material
	wall_container.add_child(wall_mesh)
	wall_mesh.position = Vector3.ZERO

	var area = Area3D.new()
	area.collision_mask = 2
	area.collision_layer = 0
	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(wall_width, wall_height, wall_thickness)
	collision_shape.shape = box_shape
	area.add_child(collision_shape)
	wall_container.add_child(area)
	area.position = Vector3.ZERO

	var spawn_offset = direction * (wall_thickness / 2.0 + 0.5)
	wall_container.global_position = start_pos + spawn_offset
	wall_container.global_position.y = wall_height / 2.0
	wall_container.look_at(wall_container.global_position + direction, Vector3.UP)

	var wall_data = {
		"has_pushed": false, 
		"area": area, 
		"collision_shape": collision_shape, 
		"direction": direction, 
		"push_distance": push_distance, 
		"material": material, 
		"wall_container": wall_container
	}

	area.body_entered.connect(_on_wall_body_entered.bind(wall_data))

	var move_timer = Timer.new()
	move_timer.wait_time = 0.016
	move_timer.one_shot = false
	var travel_dist = 0.0

	move_timer.timeout.connect(_on_wall_move_timeout.bind(wall_container, material, move_timer, direction, travel_dist))
	owner.add_child(move_timer)
	move_timer.start()

func _on_wall_body_entered(body: Node, wall_data: Dictionary) -> void :
	if wall_data["has_pushed"]:
		return
	if body.is_in_group("player"):
		wall_data["has_pushed"] = true
		var area = wall_data["area"] as Area3D
		var collision_shape = wall_data["collision_shape"] as CollisionShape3D
		if area.body_entered.is_connected(_on_wall_body_entered.bind(wall_data)):
			area.body_entered.disconnect(_on_wall_body_entered.bind(wall_data))
		collision_shape.set_deferred("disabled", true)
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		_smooth_push_player(body, wall_data["direction"], wall_data["push_distance"])

func _on_wall_move_timeout(wall_container: Node3D, material: StandardMaterial3D, move_timer: Timer, direction: Vector3, travel_dist: float) -> void :
	if not is_instance_valid(wall_container):
		move_timer.queue_free()
		return
	var dt = move_timer.wait_time
	var step = wall_speed * dt
	travel_dist += step
	wall_container.global_position += direction * step

	if travel_dist >= wall_max_distance:
		var fade_tween = create_tween()
		fade_tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
		fade_tween.tween_callback(wall_container.queue_free)
		move_timer.queue_free()
	else:
		wall_container.set_meta("travel_dist", travel_dist)
		pass

func _on_wall_move_timeout_fixed(wall_container: Node3D, material: StandardMaterial3D, move_timer: Timer, direction: Vector3) -> void :
	if not is_instance_valid(wall_container):
		move_timer.queue_free()
		return
	var dt = move_timer.wait_time
	var step = wall_speed * dt
	var travel_dist = wall_container.get_meta("travel_dist", 0.0)
	travel_dist += step
	wall_container.set_meta("travel_dist", travel_dist)
	wall_container.global_position += direction * step

	if travel_dist >= wall_max_distance:
		var fade_tween = create_tween()
		fade_tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
		fade_tween.tween_callback(wall_container.queue_free)
		move_timer.queue_free()

func _smooth_push_player(player: Node, direction: Vector3, max_distance: float) -> void :
	if not player:
		return

	var start_pos = player.global_position
	var target_pos = start_pos + direction * max_distance

	var space = owner.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = start_pos
	params.to = target_pos
	params.exclude = [player, owner, self]
	params.collision_mask = 4294967295
	var result = space.intersect_ray(params)
	if result:
		var hit_distance = start_pos.distance_to(result.position)
		target_pos = start_pos + direction * (hit_distance - 0.2)

	var actual_distance = start_pos.distance_to(target_pos)
	if actual_distance < 0.1:
		return

	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(player, "global_position", target_pos, push_duration)

	await tween.finished
	if is_instance_valid(player) and player is CharacterBody3D:
		var residual = direction * (actual_distance / push_duration) * 0.2
		player.velocity = residual
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(player):
			player.velocity = Vector3.ZERO
