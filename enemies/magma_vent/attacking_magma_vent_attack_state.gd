extends DefaultEnemyAttackState
class_name AttackingMagmaVentAttackState

var vent: MagmaVent
var attack_damage: float
var attack_range: float
var cone_radius: float
var cone_offset: float
var pivot: Node3D
var cone_container: Node3D
var cone_mesh: MeshInstance3D
var cone_area: Area3D
var damage_timer: Timer
var is_active: bool = false


func _ready() -> void :
    super._ready()
    await owner.ready

    vent = owner as MagmaVent
    if vent:
        attack_damage = vent.attack_damage
        attack_range = vent.attack_range
        cone_radius = vent.cone_radius
        cone_offset = vent.cone_offset
        pivot = owner.get_node("Pivot") as Node3D


func _get_flame_origin() -> Vector3:
    if pivot:
        return pivot.global_position
    return owner.global_position


func enter() -> void :
    super.enter()
    is_active = true

    cone_container = Node3D.new()
    cone_container.name = "FlameCone"
    owner.get_parent().add_child(cone_container)
    cone_container.global_position = _get_flame_origin()

    cone_mesh = MeshInstance3D.new()
    var cylinder_mesh: = CylinderMesh.new()
    cylinder_mesh.top_radius = 0.0
    cylinder_mesh.bottom_radius = cone_radius
    cylinder_mesh.height = 1.0
    cone_mesh.mesh = cylinder_mesh

    var material: = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0.4, 0, 0.6)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    cone_mesh.material_override = material

    cone_mesh.rotation_degrees = Vector3(90, 0, 0)
    cone_container.add_child(cone_mesh)

    cone_area = Area3D.new()
    cone_area.collision_mask = 2

    var area_shape: = CollisionShape3D.new()
    var cylinder_shape: = CylinderShape3D.new()
    cylinder_shape.radius = cone_radius
    cylinder_shape.height = 1.0
    area_shape.shape = cylinder_shape

    area_shape.rotation_degrees = Vector3(90, 0, 0)
    cone_area.add_child(area_shape)
    cone_container.add_child(cone_area)

    damage_timer = Timer.new()
    damage_timer.wait_time = 0.2
    damage_timer.one_shot = false
    damage_timer.timeout.connect(_apply_damage)
    owner.add_child(damage_timer)
    damage_timer.start()

    set_process(true)


func exit() -> void :
    is_active = false
    set_process(false)

    if damage_timer:
        damage_timer.stop()
        damage_timer.queue_free()

    if cone_container:
        cone_container.queue_free()


func _process(delta: float) -> void :
    if not is_active:
        return

    if not PLAYER:
        transition.emit("IdleAttackState")
        return

    var origin: = _get_flame_origin()
    var target_pos: Vector3 = PLAYER.global_position
    target_pos.y = 1.0
    var to_player: Vector3 = target_pos - origin

    var dist: = to_player.length()
    if dist > attack_range or not running_enemy_state.can_see_player():
        transition.emit("IdleAttackState")
        return

    if dist < 0.001:
        return

    var target_length: float = min(dist + cone_offset, attack_range)

    cone_container.global_position = origin
    cone_container.look_at(target_pos, Vector3.UP)

    cone_mesh.scale = Vector3.ONE
    (cone_mesh.mesh as CylinderMesh).height = target_length
    cone_mesh.position = Vector3(0, 0, - target_length * 0.5)

    var area_shape_node: = cone_area.get_child(0) as CollisionShape3D
    if area_shape_node and area_shape_node.shape is CylinderShape3D:
        (area_shape_node.shape as CylinderShape3D).height = target_length

    cone_area.position = Vector3(0, 0, - target_length * 0.5)


func _apply_damage() -> void :
    if not is_active:
        return
    if not PLAYER:
        return

    var bodies: = cone_area.get_overlapping_bodies()
    for body in bodies:
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(attack_damage * damage_timer.wait_time)
