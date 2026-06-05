extends ArchonAttackState
class_name PhaseOneSplashArchonAttackState

var boss: ArchonOfBlinding
var splash_damage: float
var splash_radius: float
var cylinder_height: float
var splash_count: int
var area_radius: float
var attack_duration: float = 2.0
var attack_timer: float = 0.0
var warning_cylinders: Array = []
var damage_cylinders: Array = []
var is_active: bool = false
var cylinder_positions: Array = []
func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as ArchonOfBlinding
	if boss:
		splash_damage = boss.phase1_splash_damage
		splash_radius = boss.phase1_splash_radius
		cylinder_height = boss.phase1_splash_cylinder_height
		splash_count = boss.phase1_splash_count
		area_radius = boss.phase1_splash_area_radius

func enter() -> void :
	super.enter()
	is_active = true
	attack_timer = 0.0
	cylinder_positions = _generate_positions()
	_spawn_warning_cylinders()
	boss.block_animation_for(attack_duration)
	boss.animation_player.play("Swim_Idle")

func exit() -> void :
	is_active = false
	_fade_out_and_cleanup()

func physics_update(delta: float) -> void :
	if not is_active:
		return
	attack_timer += delta
	if attack_timer >= 0.5 and warning_cylinders.size() > 0:
		_cleanup_warning_cylinders()
		_spawn_damage_cylinders()
	if attack_timer >= 2.0:
		transition.emit("IdleAttackState")

func _generate_positions() -> Array:
	var positions: Array = []
	var min_distance = splash_radius * 2.0
	var max_attempts = 100



	for i in range(splash_count):
		var attempts = 0
		var valid_position = false
		var new_pos = Vector3.ZERO

		while not valid_position and attempts < max_attempts:
			var angle = randf_range(0, TAU)
			var dist = randf_range(0, area_radius)
			var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
			new_pos = boss.arena_center + offset
			new_pos.y = 0

			valid_position = true
			for pos in positions:
				if new_pos.distance_to(pos) < min_distance:
					valid_position = false
					break
			attempts += 1

		positions.append(new_pos)

	return positions

func _spawn_warning_cylinders() -> void :
	for pos in cylinder_positions:
		var cylinder = MeshInstance3D.new()
		cylinder.mesh = CylinderMesh.new()
		cylinder.mesh.top_radius = 0.1
		cylinder.mesh.bottom_radius = 0.1
		cylinder.mesh.height = cylinder_height
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 0, 0.0)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		cylinder.material_override = material
		owner.get_parent().add_child(cylinder)
		cylinder.global_position = pos + Vector3(0, 0, 0)

		var light = OmniLight3D.new()
		light.omni_range = 0.1
		light.light_color = Color.YELLOW
		light.light_energy = 3
		cylinder.add_child(light)
		light.position = Vector3(0, 0, 0)

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_property(cylinder.mesh, "top_radius", splash_radius, 0.5)
		tween.parallel().tween_property(cylinder.mesh, "bottom_radius", splash_radius, 0.5)
		tween.parallel().tween_property(material, "albedo_color:a", 0.3, 0.5)
		tween.parallel().tween_property(light, "omni_range", splash_radius, 0.5)

		warning_cylinders.append({"mesh": cylinder, "light": light, "material": material})

func _spawn_damage_cylinders() -> void :
	for pos in cylinder_positions:
		var cylinder = MeshInstance3D.new()
		cylinder.mesh = CylinderMesh.new()
		cylinder.mesh.top_radius = splash_radius
		cylinder.mesh.bottom_radius = splash_radius
		cylinder.mesh.height = cylinder_height
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 1, 0, 0.7)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		cylinder.material_override = material
		owner.get_parent().add_child(cylinder)
		cylinder.global_position = pos + Vector3(0, cylinder_height, 0)

		var light = OmniLight3D.new()
		light.omni_range = splash_radius * 2
		light.light_color = Color.YELLOW
		light.light_energy = 30
		cylinder.add_child(light)
		light.position = Vector3(0, 0, 0)

		var area = Area3D.new()
		area.collision_mask = 2
		var shape = CollisionShape3D.new()
		var cylinder_shape = CylinderShape3D.new()
		cylinder_shape.radius = splash_radius
		cylinder_shape.height = cylinder_height
		shape.shape = cylinder_shape
		area.add_child(shape)
		cylinder.add_child(area)
		area.position = Vector3(0, 0, 0)

		var damaged = false
		area.body_entered.connect( func(body):
			if damaged: return
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(splash_damage)
				damaged = true
		)

		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_EXPO)
		tween.tween_property(cylinder, "position:y", pos.y, 0.5)

		damage_cylinders.append({"mesh": cylinder, "light": light, "area": area, "damaged": damaged})

func _cleanup_warning_cylinders() -> void :
	for item in warning_cylinders:
		if is_instance_valid(item.mesh):
			item.mesh.queue_free()
	warning_cylinders.clear()

func _fade_out_and_cleanup() -> void :
	var all_items = warning_cylinders + damage_cylinders
	if all_items.size() == 0:
		return

	var tween = create_tween()
	for item in all_items:
		if is_instance_valid(item.mesh):
			var material = item.mesh.material_override
			if material:
				tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.3)
		if item.has("light") and is_instance_valid(item.light):
			tween.parallel().tween_property(item.light, "light_energy", 0.0, 0.3)

	tween.tween_callback(_queue_free_all_cylinders)

func _queue_free_all_cylinders() -> void :
	for item in warning_cylinders:
		if is_instance_valid(item.mesh):
			item.mesh.queue_free()
	for item in damage_cylinders:
		if is_instance_valid(item.mesh):
			item.mesh.queue_free()
	warning_cylinders.clear()
	damage_cylinders.clear()
