extends ArchonAttackState
class_name PhaseThreeOrbArchonAttackState

var boss: ArchonOfBlinding
var orb_damage: float
var orb_radius: float
var orb_speed: float
var arena_half_size: float = 28
var balls: Array = []

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as ArchonOfBlinding
	if boss:
		orb_damage = boss.phase3_orb_damage
		orb_radius = boss.phase3_orb_radius
		orb_speed = boss.phase3_orb_speed

func enter() -> void :
	super.enter()
	_spawn_balls()
	await get_tree().create_timer(5.0).timeout
	_cleanup_balls()
	transition.emit("IdleAttackState")

func _spawn_balls() -> void :
	var arena_center = boss.arena_center
	var left_x = arena_center.x - arena_half_size - orb_radius - 0.5
	var right_x = arena_center.x + arena_half_size + orb_radius + 0.5
	var top_z = arena_center.z - arena_half_size - orb_radius - 0.5
	var bottom_z = arena_center.z + arena_half_size + orb_radius + 0.5
	var sides = [
		{"pos": Vector3(left_x, 0, arena_center.z), "dir": Vector3(1, 0, 0)}, 
		{"pos": Vector3(right_x, 0, arena_center.z), "dir": Vector3(-1, 0, 0)}, 
		{"pos": Vector3(arena_center.x, 0, top_z), "dir": Vector3(0, 0, 1)}, 
		{"pos": Vector3(arena_center.x, 0, bottom_z), "dir": Vector3(0, 0, -1)}
	]
	for side in sides:
		for i in range(4):
			var offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
			var spawn_pos = side.pos + offset
			spawn_pos.y = orb_radius
			var ball = MeshInstance3D.new()
			ball.mesh = SphereMesh.new()
			ball.mesh.radius = orb_radius
			ball.mesh.height = orb_radius * 2
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.5, 0.8, 1.0, 1.0)
			ball.material_override = material
			owner.get_parent().add_child(ball)
			ball.global_position = spawn_pos
			var area = Area3D.new()
			area.collision_mask = 2
			var shape = CollisionShape3D.new()
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = orb_radius
			shape.shape = sphere_shape
			area.add_child(shape)
			ball.add_child(area)
			var damaged = false
			area.body_entered.connect( func(body):
				if damaged: return
				if body.is_in_group("player") and body.has_method("take_damage"):
					body.take_damage(orb_damage)
					damaged = true
					ball.queue_free()
			)
			var move_timer = Timer.new()
			move_timer.wait_time = 0.016
			move_timer.one_shot = false
			move_timer.timeout.connect( func():
				if not is_instance_valid(ball):
					move_timer.queue_free()
					return
				ball.global_position += side.dir * orb_speed * move_timer.wait_time
				if abs(ball.global_position.x - arena_center.x) > arena_half_size + orb_radius + 2 or \
abs(ball.global_position.z - arena_center.z) > arena_half_size + orb_radius + 2:
					ball.queue_free()
					move_timer.queue_free()
			)
			owner.add_child(move_timer)
			move_timer.start()
			balls.append(ball)

func _cleanup_balls() -> void :
	for ball in balls:
		if is_instance_valid(ball):
			ball.queue_free()
	balls.clear()
