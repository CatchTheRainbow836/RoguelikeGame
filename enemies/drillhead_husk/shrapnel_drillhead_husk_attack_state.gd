extends DefaultEnemyAttackState
class_name ShrapnelDrillheadHuskAttackState

var husk: DrillheadHusk
var shrapnel_damage: float
var shrapnel_range: float
var shrapnel_speed: float
var cone_radius: float
var cone_length: float
var pivot: Node3D

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	husk = owner as DrillheadHusk
	if husk:
		shrapnel_damage = husk.shrapnel_damage
		shrapnel_range = husk.shrapnel_range
		shrapnel_speed = husk.shrapnel_speed
		cone_radius = husk.cone_radius
		cone_length = husk.cone_length
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	_fire_cone()
	husk.block_animation_for(0.3)
	animation_player.play("Spell_Simple_Shoot")
	await get_tree().create_timer(0.3).timeout
	transition.emit("IdleAttackState")

func _fire_cone() -> void :
	if not PLAYER:
		return
	var from = pivot.global_position
	var to_player = PLAYER.global_position - from
	var distance = to_player.length()
	if distance > shrapnel_range:
		return
	var dir = to_player.normalized()
	dir.y = 0.0

	var cone = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = 0.0
	cylinder_mesh.bottom_radius = cone_radius
	cylinder_mesh.height = cone_length
	cone.mesh = cylinder_mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.5, 0.2, 1.0)
	cone.material_override = material
	owner.get_parent().add_child(cone)

	var spawn_pos = from + dir * (cone_length / 2)
	cone.global_position = spawn_pos

	var quat = Quaternion(Vector3.UP, dir.normalized())
	cone.rotation = quat.get_euler()

	var area = Area3D.new()
	area.collision_mask = 2
	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = cone_radius * 0.8
	shape.shape = sphere_shape
	area.add_child(shape)
	cone.add_child(area)

	area.position = Vector3(0, cone_length / 2, 0)

	var damaged = false
	area.body_entered.connect( func(body):
		if damaged: return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(shrapnel_damage)
			damaged = true
			cone.queue_free()
	)

	var move_timer = Timer.new()
	move_timer.wait_time = 0.016
	move_timer.one_shot = false
	var traveled = 0.0
	move_timer.timeout.connect( func():
		if not is_instance_valid(cone):
			move_timer.queue_free()
			return
		var step = shrapnel_speed * move_timer.wait_time
		traveled += step
		if traveled >= shrapnel_range:
			cone.queue_free()
			move_timer.queue_free()
			return
		cone.global_position += dir * step
	)
	owner.add_child(move_timer)
	move_timer.start()
