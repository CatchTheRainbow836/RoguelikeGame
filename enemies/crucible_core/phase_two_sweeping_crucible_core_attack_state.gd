extends CrucibleCoreAttackState
class_name PhaseTwoSweepCrucibleCoreAttackState

var boss: CrucibleCore
var sweep_damage: float
var sweep_length: float
var sweep_radius: float
var sweep_height: float
var sweep_base_radius: float
var containers: Array = []
var rotation_tweens: Array = []
var _ending: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as CrucibleCore
    if boss:
        sweep_damage = boss.sweep_damage
        sweep_length = boss.sweep_length
        sweep_radius = boss.sweep_radius
        sweep_height = boss.sweep_height
        sweep_base_radius = boss.sweep_base_radius

func enter() -> void :
    super.enter()
    _ending = false
    var half = boss.arena_half_size - 5
    var corners = [
        Vector3(boss.arena_center.x - half, 0, boss.arena_center.z - half), 
        Vector3(boss.arena_center.x + half, 0, boss.arena_center.z - half), 
        Vector3(boss.arena_center.x - half, 0, boss.arena_center.z + half), 
        Vector3(boss.arena_center.x + half, 0, boss.arena_center.z + half)
    ]
    for pos in corners:
        _create_sweep_at(pos)
    await get_tree().create_timer(8.5).timeout
    _end_attack()
    transition.emit("IdleAttackState")

func _create_sweep_at(center: Vector3) -> void :
    var container = Node3D.new()
    boss.get_parent().add_child(container)
    container.global_position = center

    var base_mesh = MeshInstance3D.new()
    base_mesh.mesh = CylinderMesh.new()
    base_mesh.mesh.top_radius = sweep_base_radius
    base_mesh.mesh.bottom_radius = sweep_base_radius
    base_mesh.mesh.height = sweep_height
    var base_mat = StandardMaterial3D.new()
    base_mat.albedo_color = Color.WHITE
    base_mesh.material_override = base_mat
    container.add_child(base_mesh)
    base_mesh.position = Vector3(0, sweep_height / 2, 0)

    var beam_mesh = MeshInstance3D.new()
    beam_mesh.mesh = CylinderMesh.new()
    beam_mesh.mesh.top_radius = sweep_radius
    beam_mesh.mesh.bottom_radius = sweep_radius
    beam_mesh.mesh.height = 0.01
    var beam_mat = StandardMaterial3D.new()
    beam_mat.albedo_color = Color(1, 1, 1, 0.6)
    beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    beam_mesh.material_override = beam_mat
    container.add_child(beam_mesh)
    beam_mesh.position = Vector3(0, 1.0, 0)
    beam_mesh.rotation = Vector3(PI / 2, 0, 0)

    var area = Area3D.new()
    area.collision_mask = 2
    var area_shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = sweep_radius
    cylinder_shape.height = sweep_length
    area_shape.shape = cylinder_shape
    area.add_child(area_shape)
    beam_mesh.add_child(area)
    area.position = Vector3.ZERO

    var damaged = false
    area.body_entered.connect( func(body):
        if damaged or _ending: return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(sweep_damage)
            damaged = true
    )

    var tween_beam = create_tween()
    tween_beam.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
    tween_beam.tween_property(beam_mesh.mesh, "height", sweep_length, 0.5)
    await tween_beam.finished

    var rotation_tween = create_tween().set_loops()
    rotation_tween.tween_property(beam_mesh, "rotation:y", TAU, 8.0)
    rotation_tweens.append(rotation_tween)
    containers.append(container)

func _end_attack() -> void :
    if _ending:
        return
    _ending = true

    for tween in rotation_tweens:
        if tween and tween.is_valid():
            tween.kill()
    rotation_tweens.clear()

    for container in containers:
        if not is_instance_valid(container):
            continue
        var beam_mesh = container.get_child(1)
        if beam_mesh and beam_mesh.mesh:
            var tween_retract = create_tween()
            tween_retract.tween_property(beam_mesh.mesh, "height", 0.01, 0.5)
            await tween_retract.finished
        container.queue_free()
    containers.clear()
