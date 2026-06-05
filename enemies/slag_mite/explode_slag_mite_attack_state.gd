extends DefaultEnemyAttackState
class_name ExplodeSlagMiteAttackState

var mite: SlagMite
var explosion_damage: float
var explosion_radius: float
var explosion_delay: float

func _ready() -> void :
	super._ready()
	await owner.ready
	mite = owner as SlagMite
	if mite:
		explosion_damage = mite.explosion_damage
		explosion_radius = mite.explosion_radius
		explosion_delay = mite.explosion_delay

func enter() -> void :
	super.enter()
	await get_tree().create_timer(explosion_delay).timeout
	_explode()
	mite.queue_free()

func exit() -> void :
	pass

func physics_update(delta: float) -> void :
	pass

func _explode() -> void :
	var world = owner.get_world_3d().direct_space_state
	var explosion_position = owner.global_position

	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.mesh.radius = explosion_radius
	sphere.mesh.height = explosion_radius * 2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sphere.material_override = material
	owner.get_parent().add_child(sphere)
	sphere.global_position = explosion_position

	var light = OmniLight3D.new()
	light.omni_range = explosion_radius * 2
	light.light_color = Color(1, 0.5, 0)
	light.light_energy = 15
	owner.get_parent().add_child(light)
	light.global_position = explosion_position

	var sphere_tween = sphere.create_tween()
	sphere_tween.tween_property(sphere, "scale", Vector3.ZERO, 0.5)
	sphere_tween.tween_callback(sphere.queue_free)

	var light_tween = light.create_tween()
	light_tween.tween_property(light, "light_energy", 0.0, 0.5)
	light_tween.tween_callback(light.queue_free)

	var shape = SphereShape3D.new()
	shape.radius = explosion_radius
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), explosion_position)
	params.collision_mask = 2
	params.exclude = [owner]

	var hits = world.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider.has_method("take_damage"):
			collider.take_damage(explosion_damage)
