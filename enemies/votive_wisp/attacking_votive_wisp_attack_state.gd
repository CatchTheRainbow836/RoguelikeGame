extends DefaultEnemyAttackState
class_name AttackingVotiveWispAttackState

var wisp: VotiveWisp
var explosion_damage: float
var explosion_radius: float

func _ready() -> void :
    super._ready()
    await owner.ready
    wisp = owner as VotiveWisp
    if wisp:
        explosion_damage = wisp.explosion_damage
        explosion_radius = wisp.explosion_radius

func physics_update(delta: float) -> void :
    if not wisp.shield_broken:
        transition.emit("IdleAttackState")
        return

    if not wisp.initial_knockback_active and _should_explode_from_collision():
        _explode(owner.global_position)
        wisp.die()
        return

    if PLAYER and owner.global_position.distance_to(PLAYER.global_position) <= 1.2:
        _explode(owner.global_position)
        wisp.die()

func _should_explode_from_collision() -> bool:
    var count: int = owner.get_slide_collision_count()
    for i in range(count):
        var collision: KinematicCollision3D = owner.get_slide_collision(i)
        if collision == null:
            continue
        var normal: = collision.get_normal()
        if abs(normal.y) < 0.75:
            return true
    return false

func _explode(position: Vector3) -> void :
    var explosion_container = Node3D.new()
    explosion_container.name = "ExplosionContainer"

    var scene_root = owner.get_tree().current_scene
    scene_root.add_child(explosion_container)
    explosion_container.global_position = position

    var sphere: = MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    (sphere.mesh as SphereMesh).radius = explosion_radius
    (sphere.mesh as SphereMesh).height = explosion_radius * 2.0
    var material: = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.6, 0.0, 0.5)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    sphere.material_override = material
    explosion_container.add_child(sphere)
    sphere.position = Vector3.ZERO
    sphere.scale = Vector3.ZERO

    var light: = OmniLight3D.new()
    light.omni_range = explosion_radius * 2.0
    light.light_color = Color(1.0, 0.6, 0.0)
    light.light_energy = 0.0
    explosion_container.add_child(light)
    light.position = Vector3.ZERO

    AlertnessManager.add_alert(position, 5)

    var tween: = explosion_container.create_tween()
    tween.set_trans(Tween.TRANS_EXPO)
    tween.set_ease(Tween.EASE_OUT)

    tween.tween_property(sphere, "scale", Vector3.ONE, 1.0)
    tween.parallel().tween_property(light, "light_energy", 15.0, 0.5)

    tween.tween_property(sphere, "scale", Vector3.ZERO, 1.0)
    tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)

    tween.tween_callback(explosion_container.queue_free)

    var space: PhysicsDirectSpaceState3D = owner.get_world_3d().direct_space_state
    var shape: = SphereShape3D.new()
    shape.radius = explosion_radius
    var params: = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), position)
    params.collision_mask = 2
    params.exclude = [owner.get_rid()]
    var hits: = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider and collider.has_method("take_damage"):
            collider.take_damage(explosion_damage)
