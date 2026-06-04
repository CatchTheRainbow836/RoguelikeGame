extends CrucibleCoreAttackState
class_name PhaseTwoDropCrucibleCoreAttackState

var boss: CrucibleCore
var drop_damage: float
var ball_radius: float
var fall_speed: float
var active_balls: Array = []

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as CrucibleCore
    if boss:
        drop_damage = boss.drop_damage
        ball_radius = boss.drop_ball_radius
        fall_speed = boss.drop_fall_speed

func enter() -> void :
    super.enter()
    var elevated_positions = []
    for pos_key in boss.elevated_cubes.keys():
        var cube = boss.elevated_cubes[pos_key]
        if cube.global_position.y >= 0:
            elevated_positions.append(cube.global_position)
    elevated_positions.shuffle()
    var selected = elevated_positions.slice(0, randi_range(2, 4))
    for pos in selected:
        _create_drop_ball(pos)
    await get_tree().create_timer(4.0).timeout
    _cleanup()
    transition.emit("IdleAttackState")

func _create_drop_ball(target_pos: Vector3) -> void :
    var ball = MeshInstance3D.new()
    ball.mesh = SphereMesh.new()
    ball.mesh.radius = ball_radius
    ball.mesh.height = ball_radius * 2
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.7, 0.7, 0.7)
    ball.material_override = material
    boss.get_parent().add_child(ball)
    ball.global_position = target_pos + Vector3(0, 5, 0)

    var area = Area3D.new()
    area.collision_mask = 2
    var shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = ball_radius
    shape.shape = sphere_shape
    area.add_child(shape)
    ball.add_child(area)
    var damaged = false
    area.body_entered.connect( func(body):
        if damaged: return
        if body.is_in_group("player"):
            body.take_damage(drop_damage)
            damaged = true
    )

    var tween = create_tween()
    tween.tween_property(ball, "global_position:y", target_pos.y - ball_radius, (5 - (target_pos.y - ball_radius)) / fall_speed)
    tween.tween_callback( func():
        for pos_key in boss.elevated_cubes.keys():
            var cube = boss.elevated_cubes[pos_key]
            if cube.global_position.distance_to(target_pos) < 1.0:
                var tween_down = create_tween()
                tween_down.tween_property(cube, "global_position:y", -1.5, 0.5)
                tween_down.tween_callback( func():
                    boss.elevated_cubes.erase(pos_key)
                )
                break
        ball.queue_free()
    )
    active_balls.append(ball)

func _cleanup() -> void :
    for ball in active_balls:
        if is_instance_valid(ball):
            ball.queue_free()
    active_balls.clear()
