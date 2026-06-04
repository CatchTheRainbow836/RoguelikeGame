extends DefaultEnemyAttackState
class_name AttackingSandStalkerAttackState

var stalker: SandStalker

var spear_container: Node3D
var spear_head: MeshInstance3D
var spear_area: Area3D
var spear_collision_shape: CollisionShape3D
var spear_rope_container: Node3D
var spear_rope: MeshInstance3D

var is_moving: bool = false
var move_timer: Timer

var spear_speed: float = 15.0
var spear_direction: Vector3 = Vector3.ZERO
var spear_start: Vector3 = Vector3.ZERO
var spear_destination: Vector3 = Vector3.ZERO
var spear_current_pos: Vector3 = Vector3.ZERO
var spear_total_distance: float = 0.0

var wall_hit_point: Vector3 = Vector3.ZERO
var has_hit_wall: bool = false
var spear_damage: float = 0.0

var rope_base_length: float = 0.02
var rope_radius: float = 0.05
var head_radius: float = 0.125
var head_height: float = 0.5

var _has_dealt_damage: bool = false

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    stalker = owner as SandStalker
    if stalker:
        spear_damage = stalker.spear_damage

func enter() -> void :
    super.enter()
    _has_dealt_damage = false
    if not PLAYER:
        transition.emit("IdleAttackState")
        return

    spear_start = owner.global_position
    spear_start.y = 1.0

    var target = PLAYER.global_position
    target.y = 1.0

    spear_destination = _get_spear_destination(spear_start, target)
    spear_direction = (spear_destination - spear_start).normalized()

    if spear_direction.length_squared() < 0.0001:
        transition.emit("IdleAttackState")
        return

    spear_total_distance = spear_start.distance_to(spear_destination)
    spear_current_pos = spear_start
    has_hit_wall = (spear_destination != target)

    _create_spear()
    _orient_spear_once()

    is_moving = true
    _update_spear_position(0.0)

    move_timer = Timer.new()
    move_timer.wait_time = 0.016
    move_timer.one_shot = false
    move_timer.timeout.connect(_move_spear)
    owner.add_child(move_timer)
    move_timer.start()

    var anim_length = animation_player.get_animation("OverhandThrow").length
    animation_player.play("OverhandThrow")
    stalker.block_animation_for(anim_length)

func exit() -> void :
    is_moving = false

    if move_timer:
        move_timer.stop()
        move_timer.queue_free()
        move_timer = null

    _cleanup_spear()

    var idle_state = get_parent().get_node("IdleAttackState") as IdleSandStalkerAttackState
    if idle_state:
        idle_state.attack_cooldown = stalker.attack_cooldown

func _get_spear_destination(from_pos: Vector3, target_pos: Vector3) -> Vector3:
    var dir = (target_pos - from_pos).normalized()
    var space = owner.get_world_3d().direct_space_state
    var params = PhysicsRayQueryParameters3D.new()
    params.from = from_pos
    params.to = from_pos + dir * 1000.0
    params.exclude = [owner, stalker, PLAYER]
    params.collision_mask = 4294967295
    var result = space.intersect_ray(params)
    if result:
        return result.position
    return target_pos

func _create_spear() -> void :
    spear_container = Node3D.new()
    spear_container.name = "Spear"
    owner.get_parent().add_child(spear_container)
    spear_container.global_position = spear_start

    spear_head = MeshInstance3D.new()
    spear_head.name = "SpearHead"
    var cone_mesh = CylinderMesh.new()
    cone_mesh.top_radius = 0.0
    cone_mesh.bottom_radius = head_radius
    cone_mesh.height = head_height
    spear_head.mesh = cone_mesh

    var head_material = StandardMaterial3D.new()
    head_material.albedo_color = Color(0.8, 0.6, 0.2, 1.0)
    spear_head.material_override = head_material

    spear_container.add_child(spear_head)
    spear_head.position = Vector3(0, head_height * 0.5, 0)

    spear_area = Area3D.new()
    spear_area.name = "SpearArea"
    spear_area.monitoring = true
    spear_area.monitorable = true
    spear_area.collision_layer = 0
    spear_area.collision_mask = 2
    spear_container.add_child(spear_area)
    spear_area.position = Vector3(0, head_height * 0.5, 0)

    spear_collision_shape = CollisionShape3D.new()
    var head_shape = CylinderShape3D.new()
    head_shape.radius = head_radius
    head_shape.height = head_height
    spear_collision_shape.shape = head_shape
    spear_area.add_child(spear_collision_shape)

    spear_rope_container = Node3D.new()
    spear_rope_container.name = "SpearRopeContainer"
    spear_container.add_child(spear_rope_container)
    spear_rope_container.position = Vector3.ZERO
    spear_rope_container.scale = Vector3.ONE

    spear_rope = MeshInstance3D.new()
    spear_rope.name = "SpearRope"
    var rope_mesh = CylinderMesh.new()
    rope_mesh.top_radius = rope_radius
    rope_mesh.bottom_radius = rope_radius
    rope_mesh.height = rope_base_length
    spear_rope.mesh = rope_mesh

    var rope_material = StandardMaterial3D.new()
    rope_material.albedo_color = Color(0.6, 0.4, 0.2, 1.0)
    spear_rope.material_override = rope_material

    spear_rope_container.add_child(spear_rope)
    spear_rope.position = Vector3(0, - rope_base_length * 0.5, 0)

func _orient_spear_once() -> void :
    if not spear_container:
        return

    var dir = spear_direction.normalized()
    var up = Vector3.UP

    if abs(dir.dot(up)) > 0.999:
        up = Vector3.FORWARD

    var right = up.cross(dir).normalized()
    var forward = right.cross(dir).normalized()
    var basis = Basis(right, dir, forward)

    spear_container.global_transform = Transform3D(basis, spear_start)

func _update_rope(travel_distance: float) -> void :
    if not spear_rope_container:
        return

    var scale_y = maxf(travel_distance / rope_base_length, 0.0001)
    spear_rope_container.scale = Vector3(1.0, scale_y, 1.0)

func _update_spear_position(travel_distance: float) -> void :
    if not spear_container:
        return

    spear_container.global_position = spear_current_pos
    _update_rope(travel_distance)

func _move_spear() -> void :
    if not is_moving:
        return

    var step = spear_speed * move_timer.wait_time
    var distance_to_destination = spear_current_pos.distance_to(spear_destination)

    if step >= distance_to_destination:
        spear_current_pos = spear_destination
        _update_spear_position(spear_start.distance_to(spear_current_pos))
        is_moving = false
        move_timer.stop()

        if has_hit_wall:
            stalker._on_start_dash(spear_start, spear_destination)
        transition.emit("IdleAttackState")
        return

    spear_current_pos += spear_direction * step
    _update_spear_position(spear_start.distance_to(spear_current_pos))

    if not _has_dealt_damage and spear_area:
        var bodies = spear_area.get_overlapping_bodies()
        for body in bodies:
            if body.is_in_group("player") and body.has_method("take_damage"):
                body.take_damage(spear_damage)
                _has_dealt_damage = true
                break

func _cleanup_spear() -> void :
    if spear_container and is_instance_valid(spear_container):
        spear_container.queue_free()

func retract_spear() -> void :
    is_moving = false
    if move_timer:
        move_timer.stop()
    _cleanup_spear()
    transition.emit("IdleAttackState")
