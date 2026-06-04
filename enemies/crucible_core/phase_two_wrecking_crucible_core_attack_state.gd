extends CrucibleCoreAttackState
class_name PhaseTwoWreckingCrucibleCoreAttackState

var boss: CrucibleCore
var ram_damage: float
var ram_radius: float
var ram_height: float
var ram_speed: float
var ram_push_distance: float
var active_cylinders: Array = []

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as CrucibleCore
    if boss:
        ram_damage = boss.ram_damage
        ram_radius = boss.ram_radius
        ram_height = boss.ram_height
        ram_speed = boss.ram_speed
        ram_push_distance = boss.ram_push_distance

func enter() -> void :
    super.enter()
    _spawn_ram_cylinders()
    await get_tree().create_timer(5.0).timeout
    _cleanup()
    transition.emit("IdleAttackState")

func _spawn_ram_cylinders() -> void :
    var cube_size = boss.cube_size
    var ring1_min = 4.0 * cube_size
    var ring1_max = 6.0 * cube_size
    var ring2_min = 8.0 * cube_size
    var ring2_max = 10.0 * cube_size

    var rings = [
        {"min": ring1_min, "max": ring1_max, "name": "ring1"}, 
        {"min": ring2_min, "max": ring2_max, "name": "ring2"}
    ]
    for ring in rings:
        var min_dist = ring.min
        var max_dist = ring.max
        var sides = ["top", "bottom", "left", "right"]
        for side in sides:
            var lane = randi() % 2
            var start_pos: Vector3
            var end_pos: Vector3
            var movement_dir: Vector3
            var cylinder_axis: Vector3
            match side:
                "top":
                    var z_offset = min_dist + lane * cube_size
                    var z = boss.arena_center.z - z_offset
                    start_pos = Vector3(boss.arena_center.x - max_dist, 0, z)
                    end_pos = Vector3(boss.arena_center.x + max_dist, 0, z)
                    movement_dir = Vector3.RIGHT
                    cylinder_axis = Vector3.RIGHT
                "bottom":
                    var z_offset = min_dist + lane * cube_size
                    var z = boss.arena_center.z + z_offset
                    start_pos = Vector3(boss.arena_center.x - max_dist, 0, z)
                    end_pos = Vector3(boss.arena_center.x + max_dist, 0, z)
                    movement_dir = Vector3.RIGHT
                    cylinder_axis = Vector3.RIGHT
                "left":
                    var x_offset = min_dist + lane * cube_size
                    var x = boss.arena_center.x - x_offset
                    start_pos = Vector3(x, 0, boss.arena_center.z - max_dist)
                    end_pos = Vector3(x, 0, boss.arena_center.z + max_dist)
                    movement_dir = Vector3.FORWARD
                    cylinder_axis = Vector3.FORWARD
                "right":
                    var x_offset = min_dist + lane * cube_size
                    var x = boss.arena_center.x + x_offset
                    start_pos = Vector3(x, 0, boss.arena_center.z - max_dist)
                    end_pos = Vector3(x, 0, boss.arena_center.z + max_dist)
                    movement_dir = Vector3.FORWARD
                    cylinder_axis = Vector3.FORWARD

            start_pos.y = ram_height / 2
            end_pos.y = ram_height / 2
            _create_ram_cylinder(start_pos, end_pos, movement_dir, cylinder_axis)

func _create_ram_cylinder(start: Vector3, end: Vector3, movement_dir: Vector3, cylinder_axis: Vector3) -> void :
    var container = Node3D.new()
    boss.get_parent().add_child(container)
    container.global_position = start

    var cylinder_mesh = MeshInstance3D.new()
    var cyl = CylinderMesh.new()
    cyl.top_radius = ram_radius
    cyl.bottom_radius = ram_radius
    cyl.height = ram_height
    cylinder_mesh.mesh = cyl
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.7, 0.5, 0.2, 1.0)
    cylinder_mesh.material_override = material
    container.add_child(cylinder_mesh)





    if cylinder_axis == Vector3.RIGHT:
        cylinder_mesh.rotate_object_local(Vector3.FORWARD, PI / 2)
    else:
        cylinder_mesh.rotate_object_local(Vector3.RIGHT, PI / 2)
    cylinder_mesh.position = Vector3.ZERO

    var area = Area3D.new()
    area.collision_mask = 2
    var shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = ram_radius
    cylinder_shape.height = ram_height
    shape.shape = cylinder_shape
    area.add_child(shape)
    cylinder_mesh.add_child(area)
    area.position = Vector3.ZERO

    if cylinder_axis == Vector3.RIGHT:
        area.rotate_object_local(Vector3.FORWARD, PI / 2)
    else:
        area.rotate_object_local(Vector3.RIGHT, PI / 2)

    var damaged = false
    area.body_entered.connect( func(body):
        if damaged: return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(ram_damage)
            damaged = true
            var push_dir = movement_dir.normalized()
            _push_player(body, push_dir)
    )

    var distance = start.distance_to(end)
    var duration = distance / ram_speed
    var tween = create_tween()
    tween.tween_property(container, "global_position", end, duration)
    tween.tween_callback(container.queue_free)
    active_cylinders.append(container)

func _push_player(player: CharacterBody3D, direction: Vector3) -> void :
    var target_pos = player.global_position + direction * ram_push_distance
    var space = owner.get_world_3d().direct_space_state
    var params = PhysicsRayQueryParameters3D.new()
    params.from = player.global_position
    params.to = target_pos
    params.exclude = [player, owner]
    var result = space.intersect_ray(params)
    if result:
        var hit_point = result.position
        var safe_distance = 0.2
        var new_dir = (hit_point - player.global_position).normalized()
        target_pos = hit_point - new_dir * safe_distance
    var tween = create_tween()
    tween.tween_property(player, "global_position", target_pos, 0.1)

func _cleanup() -> void :
    for c in active_cylinders:
        if is_instance_valid(c):
            c.queue_free()
    active_cylinders.clear()
