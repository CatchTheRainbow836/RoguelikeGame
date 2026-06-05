extends DefaultEnemyAttackState
class_name AttackingVeinHarvesterAttackState

var harvester: VeinHarvester
var trap_damage: float
var trap_stun_duration: float
var trap_lifetime: float
var trap_fall_height: float
var trap_radius: float
var trap_fall_speed: float

func _ready() -> void :
	super._ready()
	await owner.ready
	harvester = owner as VeinHarvester
	if harvester:
		trap_damage = harvester.trap_damage
		trap_stun_duration = harvester.trap_stun_duration
		trap_lifetime = harvester.trap_lifetime
		trap_fall_height = harvester.trap_fall_height
		trap_radius = harvester.trap_radius
		trap_fall_speed = harvester.trap_fall_speed

func enter() -> void :
	super.enter()
	_drop_trap()
	await get_tree().process_frame
	transition.emit("IdleAttackState")

func _drop_trap() -> void :
	var trap = MeshInstance3D.new()
	trap.mesh = CylinderMesh.new()
	trap.mesh.top_radius = 0.3
	trap.mesh.bottom_radius = 0.3
	trap.mesh.height = 0.1
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.RED
	trap.material_override = material
	owner.get_parent().add_child(trap)
	trap.global_position = owner.global_position
	trap.global_position.y = owner.global_position.y

	var tween = trap.create_tween()
	tween.tween_property(trap, "global_position:y", 0.0, 0.5)
	await tween.finished

	var area = Area3D.new()
	area.collision_mask = 2
	var shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = 0.3
	cylinder_shape.height = 0.1
	shape.shape = cylinder_shape
	area.add_child(shape)
	trap.add_child(area)

	var activated = false
	area.body_entered.connect( func(body):
		if activated: return
		if body.is_in_group("player") and body.has_method("take_damage"):
			activated = true
			_spawn_falling_cylinder(trap.global_position)
			trap.queue_free()
	)

	var lifetime_timer = Timer.new()
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = trap_lifetime
	lifetime_timer.timeout.connect( func():
		if is_instance_valid(trap) and not activated:
			var fade = trap.create_tween()
			fade.tween_property(trap.material_override, "albedo_color:a", 0.0, 0.5)
			fade.tween_callback(trap.queue_free)
	)
	trap.add_child(lifetime_timer)
	lifetime_timer.start()

func _spawn_falling_cylinder(position: Vector3) -> void :
	var cylinder = MeshInstance3D.new()
	cylinder.mesh = CylinderMesh.new()
	cylinder.mesh.top_radius = trap_radius
	cylinder.mesh.bottom_radius = trap_radius
	cylinder.mesh.height = trap_fall_height
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.5, 0.5, 0.5, 1.0)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	cylinder.material_override = material
	owner.get_parent().add_child(cylinder)
	cylinder.global_position = position + Vector3(0, trap_fall_height, 0)

	var area = Area3D.new()
	area.collision_mask = 2
	var shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = trap_radius
	cylinder_shape.height = trap_fall_height
	shape.shape = cylinder_shape
	area.add_child(shape)
	cylinder.add_child(area)
	area.position = Vector3(0, - trap_fall_height / 2, 0)

	var damaged = false
	area.body_entered.connect( func(body):
		if damaged: return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(trap_damage)
			if body.has_method("stun"):
				body.stun(trap_stun_duration)
			damaged = true
	)

	var tween = cylinder.create_tween()
	tween.tween_property(cylinder, "global_position:y", position.y, trap_fall_height / trap_fall_speed)
	tween.tween_callback(cylinder.queue_free)
