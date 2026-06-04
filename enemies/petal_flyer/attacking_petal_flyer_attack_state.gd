extends DefaultEnemyAttackState
class_name AttackingPetalFlyerAttackState

var explosion_damage: float
var explosion_radius: float
var flyer: PetalFlyer

func _ready() -> void :
    super._ready()
    await owner.ready
    flyer = owner as PetalFlyer
    if flyer:
        explosion_damage = flyer.explosion_damage
        explosion_radius = flyer.explosion_radius

func enter() -> void :
    super.enter()
    _explode(owner.global_position, explosion_damage, explosion_radius)
    flyer.queue_free()

func exit() -> void :
    pass

func physics_update(delta: float) -> void :
    pass

func _explode(position: Vector3, damage: float, radius: float) -> void :
    var sphere = MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = radius
    sphere.mesh.height = radius * 2
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.YELLOW
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.3
    material.cull_mode = BaseMaterial3D.CullMode.CULL_DISABLED
    sphere.material_override = material
    get_tree().current_scene.add_child(sphere)
    sphere.global_position = position

    var light = OmniLight3D.new()
    light.omni_range = radius * 2
    light.light_color = Color.YELLOW
    light.light_energy = 20
    get_tree().current_scene.add_child(light)
    light.global_position = position

    var sphere_tween = sphere.create_tween()
    sphere_tween.tween_property(sphere, "scale", Vector3.ZERO, 0.5)
    sphere_tween.finished.connect(sphere.queue_free)

    var light_tween = light.create_tween()
    light_tween.tween_property(light, "light_energy", 0.0, 0.5)
    light_tween.finished.connect(light.queue_free)

    var fallback_timer = Timer.new()
    fallback_timer.wait_time = 1.0
    fallback_timer.one_shot = true
    fallback_timer.timeout.connect( func():
        if is_instance_valid(sphere):
            sphere.queue_free()
        if is_instance_valid(light):
            light.queue_free()
    )
    get_tree().current_scene.add_child(fallback_timer)
    fallback_timer.start()

    var space = owner.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = radius
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), position)
    params.collision_mask = 4294967295
    params.exclude = [owner]

    var hits = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider is Player:
            collider.take_damage(damage)
