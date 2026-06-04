extends LeviathanAttackState
class_name PhaseTwoSummonLeviathanAttackState

var boss: Leviathan
var shrapnel_damage: float
var shrapnel_count: int
var shrapnel_radius: float
var shrapnel_height: float
var shrapnel_arc_height: float
var shrapnel_speed: float
var shrapnel_range: float
var area_radius: float = 50.0
var min_distance_between: float = 3.5
var underground_y: float = -0.5

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as Leviathan
    if boss:
        shrapnel_damage = boss.phase2_shrapnel_damage
        shrapnel_count = boss.phase2_shrapnel_count
        shrapnel_radius = boss.phase2_shrapnel_radius
        shrapnel_height = boss.phase2_shrapnel_height
        shrapnel_arc_height = boss.phase2_shrapnel_arc_height
        shrapnel_speed = boss.phase2_shrapnel_speed
        shrapnel_range = boss.phase2_shrapnel_range

func enter() -> void :
    super.enter()
    _spawn_shrapnel()
    await get_tree().process_frame
    transition.emit("IdleAttackState")

func _get_random_start_positions() -> Array[Vector3]:
    if not PLAYER:
        return []
    var positions: Array[Vector3] = []
    var center = PLAYER.global_position
    var max_attempts = 200
    for i in range(shrapnel_count):
        var attempts = 0
        var valid = false
        var candidate: Vector3
        while not valid and attempts < max_attempts:
            var angle = randf_range(0, TAU)
            var radius = randf_range(0, area_radius)
            var offset = Vector3(cos(angle) * radius, underground_y, sin(angle) * radius)
            candidate = center + offset
            valid = true
            for pos in positions:
                if candidate.distance_to(pos) < min_distance_between:
                    valid = false
                    break
            attempts += 1
        if valid:
            positions.append(candidate)
        else:
            if positions.is_empty():
                positions.append(center + Vector3(0, underground_y, 0))
            else:
                var avg_dir = Vector3.ZERO
                for pos in positions:
                    avg_dir += (candidate - pos).normalized()
                avg_dir = avg_dir.normalized()
                var new_pos = center + avg_dir * min_distance_between
                new_pos.y = underground_y
                positions.append(new_pos)
    return positions

func _spawn_shrapnel() -> void :
    var start_positions = _get_random_start_positions()
    for start_pos in start_positions:
        var angle = randf_range(0, TAU)
        var direction = Vector3(cos(angle), 0, sin(angle)).normalized()
        var travel_dist = shrapnel_range * randf_range(0.8, 1.2)
        var end_pos = start_pos + direction * travel_dist
        end_pos.y = underground_y

        var container = Node3D.new()
        container.name = "Shrapnel"
        owner.get_parent().add_child(container)
        container.global_position = start_pos

        var shrapnel_mesh = MeshInstance3D.new()
        shrapnel_mesh.mesh = CylinderMesh.new()
        shrapnel_mesh.mesh.top_radius = 0.0
        shrapnel_mesh.mesh.bottom_radius = shrapnel_radius
        shrapnel_mesh.mesh.height = shrapnel_height
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(0.5, 0.3, 0.1, 1.0)
        shrapnel_mesh.material_override = material
        container.add_child(shrapnel_mesh)
        shrapnel_mesh.position = Vector3.ZERO

        var straight_dir = (end_pos - start_pos).normalized()
        if straight_dir.length_squared() > 0.001:
            var quat = Quaternion(Vector3.UP, straight_dir)
            shrapnel_mesh.quaternion = quat

        var area = Area3D.new()
        area.collision_mask = 2
        area.collision_layer = 0
        var shape = CollisionShape3D.new()
        var sphere_shape = SphereShape3D.new()
        sphere_shape.radius = shrapnel_radius
        shape.shape = sphere_shape
        area.add_child(shape)
        container.add_child(area)
        area.position = Vector3.ZERO

        var damaged = false
        area.body_entered.connect( func(body):
            if damaged: return
            if body.is_in_group("player") and body.has_method("take_damage"):
                body.take_damage(shrapnel_damage)
                damaged = true
        )

        container.set_meta("start_pos", start_pos)
        container.set_meta("end_pos", end_pos)
        container.set_meta("total_time", start_pos.distance_to(end_pos) / shrapnel_speed)
        container.set_meta("elapsed", 0.0)
        container.set_meta("prev_pos", start_pos)
        container.set_meta("mesh", shrapnel_mesh)

        var move_timer = Timer.new()
        move_timer.wait_time = 0.016
        move_timer.one_shot = false
        move_timer.timeout.connect(_update_shrapnel.bind(container))
        container.add_child(move_timer)
        move_timer.start()

func _update_shrapnel(container: Node3D) -> void :
    if not is_instance_valid(container):
        return
    var start_pos: Vector3 = container.get_meta("start_pos")
    var end_pos: Vector3 = container.get_meta("end_pos")
    var total_time: float = container.get_meta("total_time")
    var elapsed: float = container.get_meta("elapsed")
    var dt = 0.016
    elapsed += dt
    container.set_meta("elapsed", elapsed)

    var t = clamp(elapsed / total_time, 0.0, 1.0)
    var new_pos = start_pos.lerp(end_pos, t)
    var arc_y = underground_y + shrapnel_arc_height * 4 * t * (1 - t)
    new_pos.y = arc_y

    var prev_pos: Vector3 = container.get_meta("prev_pos")
    var move_dir = (new_pos - prev_pos).normalized()

    var mesh: MeshInstance3D = container.get_meta("mesh")
    if mesh and move_dir.length_squared() > 0.001:
        var quat = Quaternion(Vector3.UP, move_dir)
        mesh.quaternion = quat

    container.global_position = new_pos

    container.set_meta("prev_pos", new_pos)

    if t >= 1.0:
        container.queue_free()
