extends EdenRemnantAttackState
class_name PhaseOneAttackingEdenRemnantAttackState

var boss: EdenRemnant
var vine_count: int
var vine_spread_deg: float
var vine_damage: float
var attack_duration: float = 2.0
var attack_timer: float = 0.0
var warning_phase: bool = true
var damage_phase: bool = false
var retract_phase: bool = false
var warning_rods: Array = []
var damage_rods: Array = []
var target_data: Array = []
var is_active: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as EdenRemnant
    if boss:
        vine_count = boss.phase1_vine_count
        vine_spread_deg = boss.phase1_vine_spread_degrees
        vine_damage = boss.phase1_vine_damage

func enter() -> void :
    super.enter()
    is_active = true
    attack_timer = 0.0
    warning_phase = true
    damage_phase = false
    retract_phase = false
    warning_rods.clear()
    damage_rods.clear()
    target_data.clear()

    _calculate_target_points()
    _spawn_warning_rods()


func exit() -> void :
    is_active = false
    _cleanup_rods()

func physics_update(delta: float) -> void :
    if not is_active:
        return

    attack_timer += delta

    if warning_phase and attack_timer >= 0.5:
        warning_phase = false
        damage_phase = true
        _cleanup_warning_rods()
        _spawn_damage_rods()

    if damage_phase and attack_timer >= 1.25:
        damage_phase = false
        retract_phase = true
        _retract_damage_rods()

    if retract_phase and attack_timer >= 2.0:
        transition.emit("IdleAttackState")


func _calculate_target_points() -> void :
    var space = owner.get_world_3d().direct_space_state
    var player_pos = PLAYER.global_position
    var radius = 50
    var spread_rad = deg_to_rad(vine_spread_deg)
    var ceiling_check_distance = 50.0

    for i in range(vine_count):
        var angle_h = randf_range(0, TAU)
        var dist = randf_range(0, radius)
        var offset = Vector3(cos(angle_h) * dist, 0, sin(angle_h) * dist)
        var start = player_pos + offset
        start.y = -0.5

        var vertical_angle = randf_range(0, spread_rad)
        var azimuth = randf_range(0, TAU)
        var dir = Vector3(sin(vertical_angle) * cos(azimuth), cos(vertical_angle), sin(vertical_angle) * sin(azimuth)).normalized()

        var params = PhysicsRayQueryParameters3D.new()
        params.from = start
        params.to = start + dir * ceiling_check_distance
        params.collision_mask = 4294967295
        params.exclude = [owner]
        var result = space.intersect_ray(params)
        var end: Vector3
        if result.size() > 0:
            end = result.position
        else:
            end = start + dir * ceiling_check_distance

        target_data.append({"start": start, "end": end})

func _create_rod_container(start: Vector3, end: Vector3, radius_top: float, radius_bottom: float, color: Color, opacity: float) -> Node3D:
    var delta: = end - start
    if delta.length_squared() < 1e-06:
        delta = Vector3.UP * 0.001

    var length = delta.length()
    var dir = delta / length

    var container = Node3D.new()
    container.top_level = true
    owner.get_parent().add_child(container)
    container.global_position = start

    var up = Vector3.UP
    var dot = abs(dir.dot(up))
    if dot > 0.9999:
        container.global_transform.basis = Basis()
    else:
        var axis = up.cross(dir)
        if axis.length_squared() < 1e-06:
            container.global_transform.basis = Basis()
        else:
            axis = axis.normalized()
            var angle = up.angle_to(dir)
            container.global_transform.basis = Basis(Quaternion(axis, angle))

    var cylinder = MeshInstance3D.new()
    cylinder.mesh = CylinderMesh.new()
    cylinder.mesh.top_radius = radius_top
    cylinder.mesh.bottom_radius = radius_bottom
    cylinder.mesh.height = length

    var material = StandardMaterial3D.new()
    material.albedo_color = Color(color.r, color.g, color.b, opacity)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    cylinder.material_override = material

    cylinder.position = Vector3(0, length / 2.0, 0)
    container.add_child(cylinder)

    container.scale = Vector3(1, 0.01, 1)
    return container

func _spawn_warning_rods() -> void :
    for data in target_data:
        var container = _create_rod_container(data.start, data.end, 0.05, 0.05, Color(0.6, 0.3, 0.0), 0.2)
        warning_rods.append(container)
        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_EXPO)
        tween.tween_property(container, "scale:y", 1.0, 0.5)
        tween.tween_callback(container.queue_free)

func _cleanup_warning_rods() -> void :
    for container in warning_rods:
        if is_instance_valid(container):
            container.queue_free()
    warning_rods.clear()

func _spawn_damage_rods() -> void :
    for i in range(target_data.size()):
        var data = target_data[i]
        var container = _create_rod_container(data.start, data.end, 0.0, 0.25, Color(0.5, 0.2, 0.0), 1)
        damage_rods.append(container)

        var length = data.start.distance_to(data.end)
        var area = Area3D.new()
        area.collision_mask = 2
        var shape = CollisionShape3D.new()
        var capsule_shape = CapsuleShape3D.new()
        capsule_shape.radius = 0.35
        capsule_shape.height = length
        shape.shape = capsule_shape
        area.add_child(shape)
        container.add_child(area)
        area.position = Vector3(0, length / 2.0, 0)












        var damaged = false
        area.body_entered.connect( func(body):
            if damaged: return
            if body == PLAYER:
                body.take_damage(vine_damage)
                damaged = true
        )

        var tween = create_tween()
        tween.set_ease(Tween.EASE_OUT)
        tween.set_trans(Tween.TRANS_EXPO)
        tween.tween_property(container, "scale:y", 1.0, 0.75)

func _retract_damage_rods() -> void :
    for container in damage_rods:
        if is_instance_valid(container):
            var tween = create_tween()
            tween.set_ease(Tween.EASE_OUT)
            tween.set_trans(Tween.TRANS_EXPO)
            tween.tween_property(container, "scale:y", 0.0, 0.75)
            tween.tween_callback(container.queue_free)

func _cleanup_rods() -> void :
    for container in warning_rods + damage_rods:
        if is_instance_valid(container):
            container.queue_free()
    warning_rods.clear()
    damage_rods.clear()
