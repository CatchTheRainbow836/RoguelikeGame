extends DefaultEnemyAttackState
class_name ExplodeHaloSentryAttackState

var sentry: HaloSentry
var explosion_damage: float
var explosion_radius: float
var delay_before_explosion: float = 0.5
var is_active: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    sentry = owner as HaloSentry
    if sentry:
        explosion_damage = sentry.explosion_damage
        explosion_radius = sentry.explosion_radius

func enter() -> void :
    super.enter()
    is_active = true
    await get_tree().create_timer(delay_before_explosion).timeout
    if not is_active:
        return
    _explode()
    sentry.start_shield_regen()
    transition.emit("IdleAttackState")

func exit() -> void :
    is_active = false

func _explode() -> void :
    var container = Node3D.new()
    owner.get_parent().add_child(container)
    container.global_position = owner.global_position

    var sphere = MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = explosion_radius
    sphere.mesh.height = explosion_radius * 2
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0.5, 0, 0.5)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    sphere.material_override = material
    container.add_child(sphere)
    sphere.position = Vector3.ZERO

    var light = OmniLight3D.new()
    light.omni_range = explosion_radius * 2
    light.light_color = Color(1, 0.5, 0)
    light.light_energy = 15
    container.add_child(light)
    light.position = Vector3.ZERO

    var tween = get_tree().create_tween().bind_node(container)
    tween.set_parallel(true)
    tween.tween_property(sphere, "scale", Vector3.ZERO, 0.5)
    tween.tween_property(light, "light_energy", 0.0, 0.5)
    tween.tween_callback(container.queue_free)

    var space = owner.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = explosion_radius
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), owner.global_position)
    params.collision_mask = 2
    params.exclude = [owner]

    var hits = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider.has_method("take_damage"):
            collider.take_damage(explosion_damage)
