extends LeviathanAttackState
class_name PhaseOneSplashLeviathanAttackState

var boss: Leviathan
var splash_damage: float
var splash_radius: float
var splash_count: int
var area_radius: float
var attack_duration: float = 2.0
var is_active: bool = false
var player: CharacterBody3D

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as Leviathan
    if boss:
        splash_damage = boss.phase1_splash_damage
        splash_radius = boss.phase1_splash_radius
        splash_count = boss.phase1_splash_count
        area_radius = boss.phase1_splash_area_radius
        player = PLAYER

func enter() -> void :
    super.enter()
    is_active = true
    _spawn_warning_circles()
    boss.block_animation_for(attack_duration)
    boss.animation_player.play("Swim_Idle")
    await get_tree().create_timer(attack_duration).timeout
    if is_active:
        transition.emit("IdleAttackState")

func exit() -> void :
    is_active = false

func _spawn_warning_circles() -> void :
    var positions = _get_random_positions()
    for pos in positions:
        var circle = MeshInstance3D.new()
        circle.mesh = CylinderMesh.new()
        circle.mesh.top_radius = 0.1
        circle.mesh.bottom_radius = 0.1
        circle.mesh.height = 0.05
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.2, 0.5, 0.8, 0.5)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        circle.material_override = material
        owner.get_parent().add_child(circle)
        circle.global_position = pos + Vector3(0, 0.05, 0)

        var tween = create_tween()
        tween.tween_property(circle.mesh, "top_radius", splash_radius, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
        tween.parallel().tween_property(circle.mesh, "bottom_radius", splash_radius, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
        tween.tween_callback(_spawn_damage_circle.bind(pos, circle))
        tween.tween_callback(circle.queue_free)

func _spawn_damage_circle(pos: Vector3, warning_circle: MeshInstance3D) -> void :
    if not is_instance_valid(warning_circle):
        return
    var circle = MeshInstance3D.new()
    circle.mesh = CylinderMesh.new()
    circle.mesh.top_radius = splash_radius
    circle.mesh.bottom_radius = splash_radius
    circle.mesh.height = 0.1
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.6, 1.0, 1.0)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    circle.material_override = material
    owner.get_parent().add_child(circle)
    circle.global_position = pos + Vector3(0, 0.05, 0)

    var area = Area3D.new()
    area.collision_mask = 2
    var shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = splash_radius
    cylinder_shape.height = 0.1
    shape.shape = cylinder_shape
    area.add_child(shape)
    circle.add_child(area)
    area.position = Vector3(0, 0, 0)

    var damaged = false
    area.body_entered.connect( func(body):
        if damaged: return
        if body == PLAYER:
            body.take_damage(splash_damage)
            damaged = true
    )

    var descend_timer = Timer.new()
    descend_timer.one_shot = true
    descend_timer.wait_time = 1.0
    descend_timer.timeout.connect( func():
        if is_instance_valid(circle):
            var tween = create_tween()
            tween.tween_property(circle, "position:y", -0.25, 0.5)
            tween.parallel().tween_property(material, "albedo_color:a", 0.5, 0.5)
            tween.tween_callback(circle.queue_free)
    )
    circle.add_child(descend_timer)
    descend_timer.start()

func _get_random_positions() -> Array:
    if not player:
        return []
    var min_distance = 2.0 * splash_radius
    var center = player.global_position
    var positions = []
    var max_attempts = 200
    for i in range(splash_count):
        var attempts = 0
        var valid_position = false
        var candidate: Vector3
        while not valid_position and attempts < max_attempts:
            var angle = randf_range(0, TAU)
            var radius = randf_range(0, area_radius)
            var offset = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
            candidate = center + offset
            candidate.y = 0
            valid_position = true
            for pos in positions:
                if candidate.distance_to(pos) < min_distance:
                    valid_position = false
                    break
            attempts += 1
        if valid_position:
            positions.append(candidate)
        else:
            if positions.is_empty():
                positions.append(center)
            else:
                var avg_dir = Vector3.ZERO
                for pos in positions:
                    avg_dir += (candidate - pos).normalized()
                avg_dir = avg_dir.normalized()
                var new_pos = center + avg_dir * min_distance
                new_pos.y = 0
                if new_pos.distance_to(center) > area_radius:
                    new_pos = center + avg_dir * area_radius
                positions.append(new_pos)
    return positions
