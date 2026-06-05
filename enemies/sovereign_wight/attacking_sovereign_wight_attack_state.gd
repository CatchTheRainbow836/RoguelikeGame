extends DefaultEnemyAttackState
class_name AttackingSovereignWightAttackState

var slam_damage: float
var stun_duration: float
var slam_radius: float
var wight: SovereignWight
var recovery_timer: Timer
var is_active: bool = false

func _ready() -> void :
	super._ready()
	await owner.ready
	wight = owner as SovereignWight
	if wight:
		slam_damage = wight.slam_damage
		stun_duration = wight.stun_duration
		slam_radius = wight.slam_radius

func enter() -> void :
	super.enter()
	is_active = true
	perform_slam()

	recovery_timer = Timer.new()
	recovery_timer.one_shot = true
	recovery_timer.wait_time = 3
	recovery_timer.timeout.connect(_on_recovery_finished)
	owner.add_child(recovery_timer)
	recovery_timer.start()

func exit() -> void :
	is_active = false
	if recovery_timer:
		recovery_timer.stop()
		recovery_timer.queue_free()

func physics_update(delta: float) -> void :
	pass

func _on_recovery_finished() -> void :
	if is_active:
		transition.emit("IdleAttackState")

func perform_slam() -> void :
	if not is_active:
		return

	var space = owner.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = slam_radius
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), owner.global_position)
	params.collision_mask = 2
	params.exclude = [owner]

	var hits = space.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider == PLAYER:
			collider.take_damage(slam_damage)
			if collider.has_method("stun"):
				collider.stun(stun_duration)

	var sphere_mesh = MeshInstance3D.new()
	sphere_mesh.mesh = SphereMesh.new()
	sphere_mesh.mesh.radius = slam_radius
	sphere_mesh.mesh.height = slam_radius * 2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sphere_mesh.material_override = material
	owner.get_parent().add_child(sphere_mesh)
	sphere_mesh.global_position = owner.global_position
	var tween = create_tween()
	tween.tween_property(sphere_mesh, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(sphere_mesh.queue_free)

	wight.block_animation_for(0.3)
