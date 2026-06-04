extends DefaultEnemyMovementState
class_name TeleportAsceticWardenState

var warden: AsceticWarden
var original_y: float
var teleport_cylinder: MeshInstance3D
var cylinder_material: StandardMaterial3D
var is_teleporting: bool = false

const CYLINDER_HEIGHT = 4.0
const CYLINDER_RADIUS = 0.6
const CYLINDER_OFFSET_Y = -2.5

func _ready() -> void :
    super._ready()
    await owner.ready
    warden = owner as AsceticWarden

func enter() -> void :
    super.enter()
    is_teleporting = true
    original_y = owner.global_position.y

    _create_cylinder(owner.global_position)
    teleport_cylinder.global_position.y = owner.global_position.y + CYLINDER_OFFSET_Y
    teleport_cylinder.visible = true

    var tween_up = create_tween()
    tween_up.set_ease(Tween.EASE_OUT)
    tween_up.set_trans(Tween.TRANS_EXPO)
    tween_up.tween_property(teleport_cylinder, "global_position:y", owner.global_position.y, 0.3)
    tween_up.parallel().tween_property(cylinder_material, "albedo_color:a", 1.0, 0.3)
    await tween_up.finished

    owner.visible = false

    var tween_fade = create_tween()
    tween_fade.tween_property(cylinder_material, "albedo_color:a", 0.0, 0.2)
    await tween_fade.finished
    teleport_cylinder.queue_free()

    if PLAYER:
        var target_dir = (PLAYER.global_position - owner.global_position).normalized()
        var teleport_pos = PLAYER.global_position - target_dir * warden.attack_range
        teleport_pos.y = original_y
        owner.global_position = teleport_pos

    _create_cylinder(owner.global_position)
    teleport_cylinder.global_position.y = owner.global_position.y + CYLINDER_OFFSET_Y
    teleport_cylinder.visible = true

    var tween_up2 = create_tween()
    tween_up2.set_ease(Tween.EASE_OUT)
    tween_up2.set_trans(Tween.TRANS_EXPO)
    tween_up2.tween_property(teleport_cylinder, "global_position:y", owner.global_position.y, 0.3)
    tween_up2.parallel().tween_property(cylinder_material, "albedo_color:a", 1.0, 0.3)
    await tween_up2.finished

    owner.visible = true

    var tween_fade2 = create_tween()
    tween_fade2.tween_property(cylinder_material, "albedo_color:a", 0.0, 0.2)
    await tween_fade2.finished
    teleport_cylinder.queue_free()

    transition.emit("RunningEnemyState")
    is_teleporting = false

func exit() -> void :
    if teleport_cylinder and is_instance_valid(teleport_cylinder):
        teleport_cylinder.queue_free()
    owner.visible = true
    is_teleporting = false

func physics_update(delta: float) -> void :

    _velocity = Vector3.ZERO
    owner.velocity = _velocity
    owner.move_and_slide()

func _create_cylinder(position: Vector3) -> void :
    teleport_cylinder = MeshInstance3D.new()
    teleport_cylinder.mesh = CylinderMesh.new()
    (teleport_cylinder.mesh as CylinderMesh).top_radius = CYLINDER_RADIUS
    (teleport_cylinder.mesh as CylinderMesh).bottom_radius = CYLINDER_RADIUS
    (teleport_cylinder.mesh as CylinderMesh).height = CYLINDER_HEIGHT

    cylinder_material = StandardMaterial3D.new()
    cylinder_material.albedo_color = Color(0.3, 0.0, 0.4, 0.0)
    cylinder_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    teleport_cylinder.material_override = cylinder_material

    owner.get_parent().add_child(teleport_cylinder)
    teleport_cylinder.global_position = position
    teleport_cylinder.visible = false
