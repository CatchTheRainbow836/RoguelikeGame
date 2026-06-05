extends DefaultEnemyAttackState
class_name ExplodeVeinHarvesterAttackState

var harvester: VeinHarvester
var grenade_damage: float
var grenade_bounce_count: int
var grenade_speed: float
var grenade_radius: float
var explosion_radius: float = 3.0
var pivot: Node3D

func _ready() -> void :
	super._ready()
	await owner.ready
	harvester = owner as VeinHarvester
	if harvester:
		grenade_damage = harvester.grenade_damage
		grenade_bounce_count = harvester.grenade_bounce_count
		grenade_speed = harvester.grenade_speed
		grenade_radius = harvester.grenade_radius
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	_throw_grenade()
	await get_tree().process_frame
	transition.emit("IdleAttackState")

func _throw_grenade() -> void :
	if not PLAYER:
		return
	var from = pivot.global_position
	var to_player = PLAYER.global_position - from
	var direction = to_player.normalized()
	direction.y = 0.2

	var launch_speed = grenade_speed * 0.8

	var grenade = MeshInstance3D.new()
	grenade.mesh = SphereMesh.new()
	grenade.mesh.radius = grenade_radius
	grenade.mesh.height = grenade_radius * 2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.2, 0.2, 1.0)
	grenade.material_override = material
	owner.get_parent().add_child(grenade)
	grenade.global_position = from

	var velocity = direction * launch_speed
	grenade.set_meta("velocity", velocity)
	grenade.set_meta("bounces", 0)
	grenade.set_meta("spawn_origin", from)

	var area = Area3D.new()
	area.collision_mask = 2
	area.collision_layer = 0
	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = grenade_radius
	shape.shape = sphere_shape
	area.add_child(shape)
	grenade.add_child(area)

	var move_timer = Timer.new()
	move_timer.wait_time = 0.016
	move_timer.one_shot = false
	move_timer.timeout.connect(_update_grenade.bind(grenade, move_timer))
	grenade.add_child(move_timer)
	move_timer.start()

	var exploded = false
	area.body_entered.connect( func(body):
		if exploded: return
		if body.is_in_group("player") and body.has_method("take_damage"):
			exploded = true
			_explode(grenade.global_position, grenade)
			grenade.queue_free()
			if move_timer: move_timer.queue_free()
	)

func _update_grenade(grenade: MeshInstance3D, timer: Timer) -> void :
	if not is_instance_valid(grenade):
		timer.queue_free()
		return

	var dt = timer.wait_time
	var velocity = grenade.get_meta("velocity", Vector3.ZERO)
	var bounces = grenade.get_meta("bounces", 0)

	velocity.y -= 12.0 * dt
	grenade.set_meta("velocity", velocity)

	var new_pos = grenade.global_position + velocity * dt
	grenade.global_position = new_pos

	var space = grenade.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = grenade.global_position - velocity * dt
	params.to = grenade.global_position
	params.exclude = [grenade]
	params.collision_mask = 4294967295
	var result = space.intersect_ray(params)

	if result:
		bounces += 1
		grenade.set_meta("bounces", bounces)
		var normal = result.normal
		velocity = velocity.bounce(normal)
		velocity *= 0.85
		grenade.set_meta("velocity", velocity)
		grenade.global_position = result.position + normal * 0.05

		if bounces >= grenade_bounce_count:
			_explode(grenade.global_position, grenade)
			grenade.queue_free()
			timer.queue_free()
			return

	var spawn_origin = grenade.get_meta("spawn_origin", grenade.global_position)
	if grenade.global_position.distance_to(spawn_origin) > 50.0:
		grenade.queue_free()
		timer.queue_free()

func _explode(pos: Vector3, source: Node3D) -> void :
	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.mesh.radius = explosion_radius
	sphere.mesh.height = explosion_radius * 2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere.material_override = material
	source.get_parent().add_child(sphere)
	sphere.global_position = pos
	var tween = sphere.create_tween()
	tween.tween_property(sphere, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(sphere.queue_free)

	var light = OmniLight3D.new()
	light.omni_range = explosion_radius * 2
	light.light_color = Color(1, 0.5, 0)
	light.light_energy = 10
	source.get_parent().add_child(light)
	light.global_position = pos
	var light_tween = light.create_tween()
	light_tween.tween_property(light, "light_energy", 0.0, 0.3)
	light_tween.tween_callback(light.queue_free)

	var space = source.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = explosion_radius
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), pos)
	params.collision_mask = 2
	var hits = space.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider.is_in_group("player") and collider.has_method("take_damage"):
			collider.take_damage(grenade_damage)
