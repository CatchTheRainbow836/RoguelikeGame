extends CrucibleCoreAttackState
class_name PhaseTwoBurstCrucibleCoreAttackState

var boss: CrucibleCore
var burst_damage: float
var burst_radius: float
var burst_height: float
var burst_duration: float
var active_cylinders: Array = []

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as CrucibleCore
	if boss:
		burst_damage = boss.burst_damage
		burst_radius = boss.burst_radius
		burst_height = boss.burst_height
		burst_duration = boss.burst_duration

func enter() -> void :
	super.enter()
	var elevated_positions = []
	for cube in boss.elevated_cubes.values():
		if cube.global_position.y >= 0:
			elevated_positions.append(cube.global_position)
	elevated_positions.shuffle()
	var selected = elevated_positions.slice(0, randi_range(3, 6))
	for pos in selected:
		_create_burst(pos)
	await get_tree().create_timer(burst_duration + 1.0).timeout
	_cleanup()
	transition.emit("IdleAttackState")

func _create_burst(pos: Vector3) -> void :
	var cylinder = MeshInstance3D.new()
	cylinder.mesh = CylinderMesh.new()
	cylinder.mesh.top_radius = burst_radius
	cylinder.mesh.bottom_radius = burst_radius
	cylinder.mesh.height = 0.1
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0, 0.6)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cylinder.material_override = material
	boss.get_parent().add_child(cylinder)
	cylinder.global_position = pos + Vector3(0, - burst_height, 0)

	var area = Area3D.new()
	area.collision_mask = 2
	var shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = burst_radius
	cylinder_shape.height = burst_height
	shape.shape = cylinder_shape
	area.add_child(shape)
	cylinder.add_child(area)
	area.position = Vector3(0, burst_height / 2, 0)

	var damaged = false
	area.body_entered.connect( func(body):
		if damaged: return
		if body.is_in_group("player"):
			damaged = true
			body.take_damage(burst_damage)
	)


	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	var target_y = pos.y + burst_height / 2.0
	tween.tween_property(cylinder, "global_position:y", target_y, 0.5)
	tween.parallel().tween_property(cylinder.mesh, "height", burst_height, 0.5)
	await tween.finished

	await get_tree().create_timer(burst_duration).timeout

	var tween_down = create_tween()
	tween_down.tween_property(cylinder, "global_position:y", pos.y - burst_height, 0.5)
	tween_down.parallel().tween_property(cylinder.mesh, "height", 0.1, 0.5)
	tween_down.tween_callback(cylinder.queue_free)
	active_cylinders.append(cylinder)

func _cleanup() -> void :
	for cyl in active_cylinders:
		if is_instance_valid(cyl):
			cyl.queue_free()
	active_cylinders.clear()
