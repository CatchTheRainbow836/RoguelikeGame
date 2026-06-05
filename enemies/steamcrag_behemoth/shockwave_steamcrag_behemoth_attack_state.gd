extends DefaultEnemyAttackState
class_name ShockwaveSteamcragBehemothAttackState

var behemoth: SteamcragBehemoth
var shockwave_damage: float
var shockwave_range: float
var shockwave_speed: float
var torus_thickness: float
var torus_start_radius: float
var torus_spacing: float
var toruses: Array = []

func _ready() -> void :
	super._ready()
	await owner.ready
	behemoth = owner as SteamcragBehemoth
	if behemoth:
		shockwave_damage = behemoth.shockwave_damage
		shockwave_range = behemoth.shockwave_range
		shockwave_speed = behemoth.shockwave_speed
		torus_thickness = behemoth.torus_thickness
		torus_start_radius = behemoth.torus_start_radius
		torus_spacing = behemoth.torus_spacing

func enter() -> void :
	super.enter()

	for i in range(3):
		var torus = MeshInstance3D.new()
		torus.mesh = TorusMesh.new()
		torus.mesh.inner_radius = torus_start_radius
		torus.mesh.outer_radius = torus_start_radius + torus_thickness
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.4, 0.1, 0.8)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		torus.material_override = material
		owner.get_parent().add_child(torus)
		torus.global_position = owner.global_position
		torus.global_position.y = 0.1
		var delay = i * torus_spacing / shockwave_speed
		toruses.append({
			"mesh": torus, 
			"material": material, 
			"delay": delay, 
			"active": true
		})


	var max_duration = 0.0
	for t in toruses:
		var start_radius = torus_start_radius
		var target_radius = shockwave_range
		var duration = (shockwave_range - start_radius) / shockwave_speed
		var total_time = t.delay + duration
		if total_time > max_duration:
			max_duration = total_time

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(t.mesh, "mesh:inner_radius", target_radius, duration).set_delay(t.delay)
		tween.tween_property(t.mesh, "mesh:outer_radius", target_radius + torus_thickness, duration).set_delay(t.delay)
		tween.tween_property(t.material, "albedo_color:a", 0.0, 0.3).set_delay(t.delay + duration - 0.3)
		tween.tween_callback(_on_wave_finished.bind(t)).set_delay(t.delay + duration)


		var area = Area3D.new()
		area.collision_mask = 2
		var shape = CollisionShape3D.new()
		var cylinder_shape = CylinderShape3D.new()
		cylinder_shape.radius = start_radius
		cylinder_shape.height = 0.2
		shape.shape = cylinder_shape
		area.add_child(shape)
		t.mesh.add_child(area)
		area.position = Vector3.ZERO
		var damaged = false
		area.body_entered.connect( func(body):
			if damaged: return
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(shockwave_damage)
				damaged = true
				if t.active:
					t.active = false
					t.mesh.queue_free()
		)

		var shape_tween = create_tween()
		shape_tween.tween_property(cylinder_shape, "radius", target_radius, duration).set_delay(t.delay)


	await get_tree().create_timer(max_duration + 0.2).timeout
	transition.emit("IdleAttackState")

func exit() -> void :
	for t in toruses:
		if is_instance_valid(t.mesh):
			t.mesh.queue_free()
	toruses.clear()

func _on_wave_finished(t: Dictionary) -> void :
	if is_instance_valid(t.mesh):
		t.mesh.queue_free()
	t.active = false
