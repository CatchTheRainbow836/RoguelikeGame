extends DefaultEnemyAttackState
class_name MeleeHaloSentryAttackState

var sentry: HaloSentry
var melee_damage: float
var original_radius: float = 0.6
var expanded_radius: float = 1.2
var attack_duration: float = 0.5
var is_active: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    sentry = owner as HaloSentry
    if sentry:
        melee_damage = sentry.melee_damage

func enter() -> void :
    super.enter()
    is_active = true
    for ring in sentry.rings:
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_EXPO)
        tween.tween_property(ring.mesh, "inner_radius", expanded_radius, attack_duration)
        tween.parallel().tween_property(ring.mesh, "outer_radius", expanded_radius + 0.05, attack_duration)

    var area = Area3D.new()
    area.collision_mask = 2
    var shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = expanded_radius
    shape.shape = sphere_shape
    area.add_child(shape)
    sentry.add_child(area)
    area.global_position = sentry.global_position

    var damaged = false
    area.body_entered.connect( func(body):
        if damaged: return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(melee_damage)
            damaged = true
    )

    await get_tree().create_timer(attack_duration).timeout
    area.queue_free()

    for ring in sentry.rings:
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_EXPO)
        tween.tween_property(ring.mesh, "inner_radius", original_radius, attack_duration)
        tween.parallel().tween_property(ring.mesh, "outer_radius", original_radius + 0.05, attack_duration)

    await get_tree().create_timer(attack_duration).timeout
    if is_active:
        transition.emit("IdleAttackState")

func exit() -> void :
    is_active = false
