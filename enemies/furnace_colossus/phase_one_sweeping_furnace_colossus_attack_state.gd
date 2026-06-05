extends FurnaceColossusAttackState
class_name PhaseOneSweepingFurnaceColossusAttackState

var sweep_damage: float
var pivot: Node3D
var is_active: bool = false
var running_state: PhaseOneRunningFurnaceColossusState
var beam: Area3D
var rotation_timer: Timer
var sweep_duration: float = 2.0
var damaged_once: bool = false
var current_angle: float = 0.0

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer



func _ready() -> void :
	super._ready()
	await owner.ready
	var colossus = owner as FurnaceColossus
	if colossus:
		sweep_damage = colossus.sweep_damage
		pivot = owner.get_node("Pivot")
	var phase_sm = owner.top_state_machine.CURRENT_STATE
	if phase_sm:
		running_state = phase_sm.get_node("EnemyStateMachine/RunningEnemyState") as PhaseOneRunningFurnaceColossusState
		if running_state:
			running_state.connect("can_attack", _on_can_attack)

func enter() -> void :
	print("entered SweepingAttackState")
	is_active = true
	damaged_once = false
	current_angle = 0.0
	create_beam()
	rotation_timer = Timer.new()
	rotation_timer.one_shot = false
	rotation_timer.wait_time = 0.02
	rotation_timer.timeout.connect(rotate_beam)
	add_child(rotation_timer)
	rotation_timer.start()

func exit() -> void :
	print("exited SweepingAttackState")
	is_active = false
	if rotation_timer:
		rotation_timer.stop()
		rotation_timer.queue_free()
		rotation_timer = null
	if beam and is_instance_valid(beam):
		beam.queue_free()
		beam = null

	animation_player.stop()

func _on_can_attack(active: bool) -> void :
	if not is_active:
		return
	if not active:
		transition.emit("IdleAttackState")

func create_beam() -> void :
	beam = Area3D.new()
	beam.name = "SweepBeam"
	beam.collision_mask = 2
	beam.collision_layer = 0

	var collision_shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = 0.25
	cylinder_shape.height = 5.0
	collision_shape.shape = cylinder_shape
	beam.add_child(collision_shape)

	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.25
	cylinder_mesh.bottom_radius = 0.25
	cylinder_mesh.height = 5.0
	mesh_instance.mesh = cylinder_mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0, 0.7)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	beam.add_child(mesh_instance)


	var forward = - pivot.global_transform.basis.z.normalized()

	beam.rotate_object_local(Vector3.RIGHT, PI / 2)


	owner.get_parent().add_child(beam)
	beam.global_position = pivot.global_position + forward * 2.5


	beam.body_entered.connect( func(body):
		if damaged_once:
			return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(sweep_damage)
			damaged_once = true
	)

	animation_player.get_animation("TPose").loop_mode = Animation.LOOP_NONE
	animation_player.play("TPose")


func rotate_beam() -> void :
	if not is_active or not beam:
		return

	var angle_step = (2 * PI) / (sweep_duration / 0.02)
	current_angle += angle_step
	if current_angle >= 2 * PI:

		exit()
		transition.emit("AttackingAttackState")
		return


	var dir = Vector3(sin(current_angle), 0, cos(current_angle)).normalized()

	beam.global_position = pivot.global_position + dir * 2.5

	var up = Vector3.UP
	var z_axis = up.cross(dir).normalized()
	var x_axis = dir.cross(z_axis).normalized()
	beam.global_transform.basis = Basis(x_axis, dir, z_axis)
