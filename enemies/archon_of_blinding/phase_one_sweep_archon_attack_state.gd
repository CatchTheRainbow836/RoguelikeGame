extends ArchonAttackState
class_name PhaseOneSweepArchonAttackState

var boss: ArchonOfBlinding
var sweep_damage: float
var sweep_length: float
var sweep_radius: float
var sweep_height: float
var sweep_base_radius: float
var container: Node3D
var base_mesh: MeshInstance3D
var beam_mesh: MeshInstance3D
var beam_area: Area3D
var damaged: bool = false
var rotation_tween: Tween
var is_rotating: bool = false
var _ending: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as ArchonOfBlinding
    if boss:
        sweep_damage = boss.phase1_sweep_damage
        sweep_length = boss.phase1_sweep_length
        sweep_radius = boss.phase1_sweep_radius
        sweep_height = boss.phase1_sweep_height
        sweep_base_radius = boss.phase1_sweep_base_radius

func enter() -> void :
    super.enter()
    _ending = false
    container = Node3D.new()
    container.name = "SweepAttack"
    owner.get_parent().add_child(container)
    container.global_position = boss.arena_center + Vector3(0, -2.0, 0)

    base_mesh = MeshInstance3D.new()
    base_mesh.mesh = CylinderMesh.new()
    base_mesh.mesh.top_radius = sweep_base_radius
    base_mesh.mesh.bottom_radius = sweep_base_radius
    base_mesh.mesh.height = sweep_height
    var base_mat = StandardMaterial3D.new()
    base_mat.albedo_color = Color.WHITE
    base_mesh.material_override = base_mat
    container.add_child(base_mesh)
    base_mesh.position = Vector3(0, sweep_height / 2.0, 0)

    beam_mesh = MeshInstance3D.new()
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

    beam_area = Area3D.new()
    beam_area.collision_mask = 2
    var area_shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = sweep_radius
    cylinder_shape.height = sweep_length
    area_shape.shape = cylinder_shape
    beam_area.add_child(area_shape)
    beam_mesh.add_child(beam_area)
    beam_area.position = Vector3.ZERO

    beam_area.body_entered.connect( func(body):
        if damaged or _ending: return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(sweep_damage)
            damaged = true
            _end_attack()
    )

    var tween_up = create_tween()
    tween_up.set_ease(Tween.EASE_OUT)
    tween_up.set_trans(Tween.TRANS_EXPO)
    tween_up.tween_property(container, "global_position:y", boss.arena_center.y, 0.5)
    await tween_up.finished

    var tween_beam = create_tween()
    tween_beam.set_ease(Tween.EASE_OUT)
    tween_beam.set_trans(Tween.TRANS_EXPO)
    tween_beam.tween_property(beam_mesh.mesh, "height", sweep_length, 0.5)
    await tween_beam.finished

    is_rotating = true
    rotation_tween = create_tween().set_loops()
    rotation_tween.tween_property(beam_mesh, "rotation:y", TAU, 8.0)

    await get_tree().create_timer(8.0).timeout
    _end_attack()

func _end_attack() -> void :
    if _ending:
        return
    _ending = true

    if rotation_tween and rotation_tween.is_valid():
        rotation_tween.kill()
    is_rotating = false

    if is_instance_valid(beam_mesh) and beam_mesh.mesh:
        var tween_retract = create_tween()
        tween_retract.set_ease(Tween.EASE_OUT)
        tween_retract.set_trans(Tween.TRANS_EXPO)
        tween_retract.tween_property(beam_mesh.mesh, "height", 0.01, 0.5)
        await tween_retract.finished

    if is_instance_valid(container):
        var tween_down = create_tween()
        tween_down.set_ease(Tween.EASE_OUT)
        tween_down.set_trans(Tween.TRANS_EXPO)
        tween_down.tween_property(container, "global_position:y", boss.arena_center.y - 2.0, 0.5)
        await tween_down.finished
        container.queue_free()

    transition.emit("IdleAttackState")

func exit() -> void :
    if rotation_tween and rotation_tween.is_valid():
        rotation_tween.kill()
    if container and is_instance_valid(container):
        container.queue_free()
