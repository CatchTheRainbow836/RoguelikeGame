class_name FiringWeaponState
extends WeaponMovementState

@export var equip_ranged_damage_buff: float = 1.0
@export var equip_melee_damage_buff: float = 1.0
@export var equip_projectile_damage_buff: float = 1.0

@export var ranged_damage_buff: float = 1.0
@export var melee_damage_buff: float = 1.0
@export var projectile_damage_buff: float = 1.0

func exit() -> void :
	if PLAYER and PLAYER.weapon_inventory_data:
		slot = PLAYER.weapon_inventory_data.slot_datas[0]

	if !slot:
		return
	var weapon: = slot.item_data as ItemDataWeapon

	if weapon.type == 100 or weapon.type == 101 or weapon.type == 102 or weapon.type == 103 or weapon.type == 104 or weapon.type == 105 or weapon.type == 106:
		weapon.damage = weapon.damage / ranged_damage_buff
		weapon.damage /= equip_ranged_damage_buff

	if weapon.type == 200 or weapon.type == 201:
		weapon.damage = weapon.damage / melee_damage_buff
		weapon.damage /= equip_melee_damage_buff

	if weapon.type == 300 or weapon.type == 301 or weapon.type == 302 or weapon.type == 303 or weapon.type == 304:
		weapon.damage = weapon.damage / projectile_damage_buff
		weapon.damage /= equip_projectile_damage_buff


func enter() -> void :
	if PLAYER and PLAYER.weapon_inventory_data:
		slot = PLAYER.weapon_inventory_data.slot_datas[0]

	if not slot or not slot.item_data is ItemDataWeapon:
		print("Firing transitioning to Unequipped")
		transition.emit("Unequipped")
		return
	var weapon: = slot.item_data as ItemDataWeapon

	print("weapon: ", weapon)

	if weapon.type == 100 or weapon.type == 101 or weapon.type == 102 or weapon.type == 103 or weapon.type == 104 or weapon.type == 105 or weapon.type == 106:
		weapon.damage *= equip_ranged_damage_buff
		weapon.damage = weapon.damage * ranged_damage_buff
	if weapon.type == 200 or weapon.type == 201:
		weapon.damage *= equip_melee_damage_buff
		weapon.damage = weapon.damage * melee_damage_buff
	if weapon.type == 300 or weapon.type == 301 or weapon.type == 302 or weapon.type == 303 or weapon.type == 304:
		weapon.damage *= equip_projectile_damage_buff
		weapon.damage = weapon.damage * projectile_damage_buff

	match weapon.type:
		100:
			if weapon.bullets_loaded == 0:
				print("Firing transitioning to Reloading")
				transition.emit("ReloadingWeaponState")
				return
			fire_gun()
			await get_tree().create_timer(0.2).timeout
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")
		101:
			if weapon.bullets_loaded == 0:
				print("Firing transitioning to Reloading")
				transition.emit("ReloadingWeaponState")
				return
			fire_gun()
			await get_tree().create_timer(0.2).timeout
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")
		102:
			if weapon.bullets_loaded == 0:
				print("Firing transitioning to Reloading")
				transition.emit("ReloadingWeaponState")
				return
			fire_gun()
			await get_tree().create_timer(0.2).timeout
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")

		103:
			if weapon.bullets_loaded == 0:
				print("Firing transitioning to Reloading")
				transition.emit("ReloadingWeaponState")
				return
			fire_blowpipe()
			await get_tree().create_timer(0.2).timeout
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")
		104:
			swing_scythe()
			if weapon.bullets_loaded == 0:
				print("Firing transitioning to Reloading")
				transition.emit("ReloadingWeaponState")
				return
			fire_gun()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")
		105:
			if weapon.bullets_loaded == 0:
				print("Firing transitioning to Reloading")
				transition.emit("ReloadingWeaponState")
				return
			fire_rocket()
			await get_tree().create_timer(0.2).timeout
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")

		106:
			if weapon.bullets_loaded == 0:
				print("Firing transitioning to Reloading")
				transition.emit("ReloadingWeaponState")
				return
			fire_machine_gun()
			await get_tree().create_timer(0.2).timeout

		200:
			swing_sword()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")

		201:
			swing_vorpal()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")

		300:
			throw_projectile()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")

		301:
			throw_smoke()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")

		302:
			throw_stun_grenade()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")
		303:
			throw_hammer()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")
		304:
			throw_spear()
			print("Firing transitioning to Idle")
			transition.emit("IdleWeaponState")

func physics_update(delta: float) -> void :
	if PLAYER and PLAYER.weapon_inventory_data:
		slot = PLAYER.weapon_inventory_data.slot_datas[0]
	if slot:
		var weapon: = slot.item_data as ItemDataWeapon
		idle_sway_adjustment = weapon.idle_sway_adjustment
		idle_sway_rotation_strength = weapon.idle_sway_rotation_strength
		random_sway_amount = weapon.random_sway_amount
	else:
		print("Firing transitioning to Unequipped")
		transition.emit("UnequippedWeaponState")

	_update_weapon()



func fire_gun():
	if not slot or not slot.item_data is ItemDataWeapon:
		return

	var weapon: = slot.item_data as ItemDataWeapon

	if weapon.bullets_loaded == 0:
		print("Firing transitioning to Reloading")
		transition.emit("ReloadingWeaponState")

	weapon_fired.emit()
	weapon.bullets_loaded -= 1
	if reload_label:
		reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]

	var from: Vector3 = camera.global_transform.origin
	var dir: Vector3 = - camera.global_transform.basis.z
	var to: Vector3 = from + dir * weapon.range
	var space = PLAYER.get_world_3d().direct_space_state

	var params_hole: = PhysicsRayQueryParameters3D.new()
	params_hole.from = from
	params_hole.to = to
	params_hole.collision_mask = 4294967295

	var hit: = space.intersect_ray(params_hole)
	if hit:
		create_bullet_hole(hit)


	var params: = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.collision_mask = 1 << 3
	var result: Dictionary = space.intersect_ray(params)
	if result.size() > 0:
		var enemy_hit = result.get("collider")
		if enemy_hit.has_method("enemy_resource"):
			enemy_hit.enemy_resource.current_health -= slot.item_data.damage
		elif enemy_hit.has_method("take_damage"):
			enemy_hit.take_damage(slot.item_data.damage)

	if inventoryinterface:
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)

	var hotbarinventory = PLAYER.get_parent().find_child("HotBarInventory")
	if hotbarinventory:
		hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

	reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]
	add_muzzle_flash()
	add_recoil()

	LevelManager.add_alert(owner.global_position, 3)

func create_bullet_hole(hit: Dictionary) -> void :
	if not bullet_hole_sprite or hit.is_empty():
		return
	var hole: = bullet_hole_sprite.instantiate() as Node3D
	get_tree().current_scene.add_child(hole)

	hole.global_position = hit.position
	hole.look_at(hit.position + hit.normal, Vector3.UP)
	hole.global_position += hit.normal * 0.01

	var tween: = get_tree().create_tween()
	tween.tween_property(hole, "modulate:a", 0.0, 1.0)
	tween.tween_callback(hole.queue_free)

func add_muzzle_flash() -> void :
	light.visible = true
	emitter.emitting = true
	await get_tree().create_timer(flash_time).timeout
	light.visible = false

func _process(delta: float) -> void :
	target_position = lerp(target_position, Vector3.ZERO, recoil_speed * delta)
	current_position = lerp(current_position, target_position, snap_amount * delta)
	recoilposition.position = current_position
	target_rotation = lerp(target_rotation, Vector3.ZERO, speed_pivot * delta)
	current_rotation = lerp(current_rotation, target_rotation, snap_amount * delta)
	var delta_rot: = current_rotation - _prev_current_rotation
	if pivot:
		pivot.rotation += delta_rot

	_prev_current_rotation = current_rotation

func add_recoil() -> void :
	target_position += Vector3(
		randf_range(recoil_amount.x, recoil_amount.x * 2.0), 
		randf_range(recoil_amount.y, recoil_amount.y * 2), 
		randf_range(0, recoil_amount.z)
	)
	target_rotation += Vector3(
		recoil_amount_pivot.x, 
		randf_range( - recoil_amount_pivot.y, recoil_amount_pivot.y), 
		randf_range( - recoil_amount_pivot.z, recoil_amount_pivot.z)
	)


func handle_input(event: InputEvent) -> void :
	pass

func swing_sword():
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	weapon_fired.emit()

	LevelManager.add_alert(owner.global_position, 1.5)

	var sword_model = weaponscene

	var original_pos = sword_model.position
	var original_rot = sword_model.rotation

	var target_pos = original_pos + Vector3(
		-1.2, 
		-0.2, 
		0.8
	)

	var target_rot = original_rot + Vector3(
		deg_to_rad(-30), 
		deg_to_rad(60), 
		0
	)

	var tween = create_tween()
	tween.tween_property(sword_model, "position", target_pos, weapon.swing_forward_speed)
	tween.parallel().tween_property(sword_model, "rotation", target_rot, weapon.swing_forward_speed)
	tween.tween_property(sword_model, "position", original_pos, weapon.swing_backward_speed)
	tween.parallel().tween_property(sword_model, "rotation", original_rot, weapon.swing_backward_speed)
	var space = PLAYER.get_world_3d().direct_space_state
	var shape = BoxShape3D.new()
	shape.size = Vector3(weapon.range * 1.8, weapon.range * 0.5, weapon.range)

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1 << 3
	var forward = - camera.global_transform.basis.z
	var right = camera.global_transform.basis.x
	var shape_pos = camera.global_transform.origin + forward * weapon.range * 0.9 + right * -0.6
	params.transform = Transform3D(Basis(), shape_pos)

	var hits = space.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider.has_method("enemy_resource"):
			collider.enemy_resource.current_health -= weapon.damage
		elif collider.has_method("take_damage"):
			collider.take_damage(weapon.damage)

	await tween.finished

	transition.emit("IdleWeaponState")

func throw_projectile():
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	if slot.quantity <= 0:
		return
	slot.quantity -= 1

	if slot.quantity - 1 <= 0:
		PLAYER.weapon_inventory_data.slot_datas[0] = null

	PLAYER.weapon_inventory_data.inventory_updated.emit(PLAYER.weapon_inventory_data)

	PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
	if reload_label:
		reload_label.text = str(slot.quantity if slot else 0)

	if inventoryinterface:
		print("inventoryinterface")
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)

		var hotbarinventory = PLAYER.get_node("UI").get_node("HotBarInventory")
		if hotbarinventory:
			hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

		var weapon_inventory = inventoryinterface.get_node("WeaponInventory")
		weapon_inventory.call("populate_item_grid", PLAYER.weapon_inventory_data)

	var last_grenade = (slot.quantity <= 0)



	var projectile = weapon.model_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var start_pos = camera.global_transform.origin
	projectile.global_position = start_pos

	var forward = - camera.global_transform.basis.z
	var up = Vector3.UP
	var throw_force = 20.0
	var vertical_force = 12.0
	var velocity = forward * throw_force + up * vertical_force

	var gravity = 25.0
	var time_step = 0.016
	var max_time = 20.0
	var elapsed = 0.0
	var hit = null

	var explosion_radius = 5

	while elapsed < max_time:
		await get_tree().create_timer(time_step).timeout
		elapsed += time_step

		velocity.y -= gravity * time_step

		var space = PLAYER.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = projectile.global_position
		query.to = projectile.global_position + velocity * time_step
		query.collision_mask = 4294967295
		query.exclude = [PLAYER]

		var result = space.intersect_ray(query)
		if result:
			projectile.global_position = result.position
			_explode(projectile.global_position, weapon.damage, explosion_radius)
			projectile.queue_free()
			hit = true
			break
		projectile.global_position += velocity * time_step
		if projectile.global_position.distance_to(start_pos) > weapon.range:
			_explode(projectile.global_position, weapon.damage, explosion_radius)
			projectile.queue_free()
			hit = true
			break
	if not hit:
		_explode(projectile.global_position, weapon.damage, explosion_radius)
		projectile.queue_free()


	if last_grenade:
		weaponscene.visible = false
		transition.emit("UnequippedWeaponState")
	else:
		transition.emit("IdleWeaponState")

func _explode(position: Vector3, damage: float, radius: float):
	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.mesh.radius = radius
	sphere.mesh.height = radius * 2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	material.cull_mode = BaseMaterial3D.CullMode.CULL_DISABLED
	sphere.material_override = material
	get_tree().current_scene.add_child(sphere)
	sphere.global_position = position

	var light = OmniLight3D.new()
	light.omni_range = radius * 2
	light.light_color = Color.YELLOW
	light.light_energy = 20
	get_tree().current_scene.add_child(light)
	light.global_position = position

	LevelManager.add_alert(position, 5)

	var tween = create_tween()
	tween.parallel().tween_property(sphere, "scale", Vector3.ZERO, 0.5)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)
	tween.tween_callback(sphere.queue_free)
	tween.tween_callback(light.queue_free)

	var space = PLAYER.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = radius
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), position)
	params.collision_mask = 1 << 3

	var hits = space.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider.has_method("enemy_resource"):
			collider.enemy_resource.current_health -= damage
		elif collider.has_method("take_damage"):
			collider.take_damage(damage)

func throw_smoke():
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	if slot.quantity <= 0:
		return
	slot.quantity -= 1

	if slot.quantity - 1 <= 0:
		PLAYER.weapon_inventory_data.slot_datas[0] = null

	PLAYER.weapon_inventory_data.inventory_updated.emit(PLAYER.weapon_inventory_data)

	PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
	if reload_label:
		reload_label.text = str(slot.quantity if slot else 0)

	if inventoryinterface:
		print("inventoryinterface")
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)

		var hotbarinventory = PLAYER.get_node("UI").get_node("HotBarInventory")
		if hotbarinventory:
			hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

		var weapon_inventory = inventoryinterface.get_node("WeaponInventory")
		weapon_inventory.call("populate_item_grid", PLAYER.weapon_inventory_data)
	var last_grenade = (slot.quantity <= 0)

	var projectile = weapon.model_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var start_pos = camera.global_transform.origin
	projectile.global_position = start_pos

	var forward = - camera.global_transform.basis.z
	var up = Vector3.UP
	var throw_force = 20.0
	var vertical_force = 12.0
	var velocity = forward * throw_force + up * vertical_force

	var gravity = 25.0
	var time_step = 0.016
	var max_time = 20.0
	var elapsed = 0.0
	var hit = null

	while elapsed < max_time:
		await get_tree().create_timer(time_step).timeout
		elapsed += time_step

		velocity.y -= gravity * time_step

		var space = PLAYER.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = projectile.global_position
		query.to = projectile.global_position + velocity * time_step
		query.collision_mask = 4294967295
		query.exclude = [PLAYER]

		var result = space.intersect_ray(query)
		if result:
			projectile.global_position = result.position
			_create_smoke_cloud(projectile.global_position, weapon)
			projectile.queue_free()
			hit = true
			break
		projectile.global_position += velocity * time_step
		if projectile.global_position.distance_to(start_pos) > weapon.range:
			_create_smoke_cloud(projectile.global_position, weapon)
			projectile.queue_free()
			hit = true
			break
	if not hit:
		_create_smoke_cloud(projectile.global_position, weapon)
		projectile.queue_free()

	if last_grenade:
		weaponscene.visible = false
		transition.emit("UnequippedWeaponState")
	else:
		transition.emit("IdleWeaponState")

func _create_smoke_cloud(position: Vector3, weapon: ItemDataWeapon):
	var smoke_area = Area3D.new()
	smoke_area.name = "SmokeCloud"
	smoke_area.collision_mask = 1 << 3
	smoke_area.collision_layer = 0

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 5
	sphere.height = 5 * 2
	mesh.mesh = sphere
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 0, 0, 0.8)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CullMode.CULL_DISABLED
	mesh.material_override = material
	smoke_area.add_child(mesh)

	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = weapon.range
	shape.shape = sphere_shape
	smoke_area.add_child(shape)


	get_tree().current_scene.add_child(smoke_area)
	smoke_area.global_position = position

	LevelManager.add_alert(position, 0.4)

	smoke_area.body_entered.connect( func(body):
		var enemy_state_machine = body.get_node_or_null("EnemyStateMachine") as StateMachine
		if enemy_state_machine:
			enemy_state_machine.get_node("IdleEnemyState").is_in_smoke = true
			enemy_state_machine.get_node("WalkingEnemyState").is_in_smoke = true
			enemy_state_machine.get_node("RunningEnemyState").is_in_smoke = true
	)

	smoke_area.body_exited.connect( func(body):
		var enemy_state_machine = body.get_node_or_null("EnemyStateMachine") as StateMachine
		if enemy_state_machine:
			enemy_state_machine.get_node("IdleEnemyState").is_in_smoke = false
			enemy_state_machine.get_node("WalkingEnemyState").is_in_smoke = false
			enemy_state_machine.get_node("RunningEnemyState").is_in_smoke = false
	)

	var timer = Timer.new()
	timer.wait_time = 8.0
	timer.one_shot = true
	timer.timeout.connect( func():
		smoke_area.queue_free()
	)
	smoke_area.add_child(timer)
	timer.start()

func throw_stun_grenade():
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	if slot.quantity <= 0:
		return
	slot.quantity -= 1

	if slot.quantity - 1 <= 0:
		PLAYER.weapon_inventory_data.slot_datas[0] = null

	PLAYER.weapon_inventory_data.inventory_updated.emit(PLAYER.weapon_inventory_data)

	PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
	if reload_label:
		reload_label.text = str(slot.quantity if slot else 0)

	if inventoryinterface:
		print("inventoryinterface")
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)

		var hotbarinventory = PLAYER.get_node("UI").get_node("HotBarInventory")
		if hotbarinventory:
			hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

		var weapon_inventory = inventoryinterface.get_node("WeaponInventory")
		weapon_inventory.call("populate_item_grid", PLAYER.weapon_inventory_data)

	var last_grenade = (slot.quantity <= 0)

	var projectile = weapon.model_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var start_pos = camera.global_transform.origin
	projectile.global_position = start_pos

	var forward = - camera.global_transform.basis.z
	var up = Vector3.UP
	var throw_force = 20.0
	var vertical_force = 12.0
	var velocity = forward * throw_force + up * vertical_force

	var gravity = 25.0
	var time_step = 0.016
	var max_time = 20.0
	var elapsed = 0.0
	var hit = null

	while elapsed < max_time:
		await get_tree().create_timer(time_step).timeout
		elapsed += time_step

		velocity.y -= gravity * time_step

		var space = PLAYER.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = projectile.global_position
		query.to = projectile.global_position + velocity * time_step
		query.collision_mask = 4294967295
		query.exclude = [PLAYER]

		var result = space.intersect_ray(query)
		if result:
			projectile.global_position = result.position
			_stun_explode(projectile.global_position, weapon)
			projectile.queue_free()
			hit = true
			break
		projectile.global_position += velocity * time_step
		if projectile.global_position.distance_to(start_pos) > weapon.range:
			_stun_explode(projectile.global_position, weapon)
			projectile.queue_free()
			hit = true
			break
	if not hit:
		_stun_explode(projectile.global_position, weapon)
		projectile.queue_free()

	if last_grenade:
		weaponscene.visible = false
		transition.emit("UnequippedWeaponState")
	else:
		transition.emit("IdleWeaponState")

func _stun_explode(position: Vector3, weapon: ItemDataWeapon):
	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.mesh.radius = 5
	sphere.mesh.height = 5 * 2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	material.cull_mode = BaseMaterial3D.CullMode.CULL_DISABLED
	sphere.material_override = material
	get_tree().current_scene.add_child(sphere)
	sphere.global_position = position

	var light = OmniLight3D.new()
	light.omni_range = 5 * 2
	light.light_color = Color.YELLOW
	light.light_energy = 20
	get_tree().current_scene.add_child(light)
	light.global_position = position

	LevelManager.add_alert(position, 3.5)

	var tween = create_tween()
	tween.parallel().tween_property(sphere, "scale", Vector3.ZERO, 0.5)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)
	tween.tween_callback(sphere.queue_free)
	tween.tween_callback(light.queue_free)

	var space = PLAYER.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = weapon.range
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), position)
	params.collision_mask = 1 << 3

	var hits = space.intersect_shape(params)
	for hit in hits:
		var enemy = hit.collider
		var enemy_state_machine = enemy.get_node_or_null("EnemyStateMachine")
		var attack_state_machine = enemy.get_node_or_null("AttackStateMachine")
		if enemy_state_machine and attack_state_machine:
			var idle_enemy_state = enemy_state_machine.get_node("IdleEnemyState")
			var idle_attack_state = attack_state_machine.get_node("IdleAttackState")

			var stun_timer: Timer = Timer.new()
			stun_timer.wait_time = 0.001
			stun_timer.one_shot = false
			stun_timer.timeout.connect( func():
				enemy_state_machine.CURRENT_STATE = idle_enemy_state
				attack_state_machine.CURRENT_STATE = idle_attack_state
				)

			var remove_timer: Timer = Timer.new()
			remove_timer.wait_time = 3
			remove_timer.one_shot = true
			remove_timer.timeout.connect( func():
				stun_timer.queue_free()
				remove_timer.queue_free()
			)

			enemy.add_child(stun_timer)
			enemy.add_child(remove_timer)
			stun_timer.start()
			remove_timer.start()

func fire_blowpipe():
	if not slot or not slot.item_data is ItemDataWeapon:
		return

	var weapon: = slot.item_data as ItemDataWeapon

	if weapon.bullets_loaded == 0:
		print("Firing transitioning to Reloading")
		transition.emit("ReloadingWeaponState")
		return

	weapon_fired.emit()
	weapon.bullets_loaded -= 1
	if reload_label:
		reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]

	var from: Vector3 = camera.global_transform.origin
	var dir: Vector3 = - camera.global_transform.basis.z
	var to: Vector3 = from + dir * weapon.range
	var space = PLAYER.get_world_3d().direct_space_state

	var params_hole: = PhysicsRayQueryParameters3D.new()
	params_hole.from = from
	params_hole.to = to
	params_hole.collision_mask = 4294967295

	var hit: = space.intersect_ray(params_hole)
	if hit:
		create_bullet_hole(hit)

	var params: = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.collision_mask = 1 << 3
	var result: Dictionary = space.intersect_ray(params)
	if result.size() > 0:
		var enemy_hit = result.get("collider")
		if enemy_hit.has_method("enemy_resource"):
			enemy_hit.enemy_resource.current_health -= slot.item_data.damage
			_apply_poison(enemy_hit)
		elif enemy_hit.has_method("take_damage"):
			enemy_hit.take_damage(slot.item_data.damage)
			_apply_poison(enemy_hit)

	if inventoryinterface:
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)

	var hotbarinventory = PLAYER.get_parent().find_child("HotBarInventory")
	if hotbarinventory:
		hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

	reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]
	add_muzzle_flash()
	add_recoil()

	LevelManager.add_alert(owner.global_position, 1.5)

func _apply_poison(enemy: Node):
	var poison_timer = Timer.new()
	poison_timer.wait_time = 1.0
	poison_timer.one_shot = false
	poison_timer.timeout.connect( func():
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(5.0)
	)
	enemy.add_child(poison_timer)
	poison_timer.start()

	var remove_timer = Timer.new()
	remove_timer.wait_time = 6.0
	remove_timer.one_shot = true
	remove_timer.timeout.connect( func():
		if is_instance_valid(poison_timer):
			poison_timer.stop()
			poison_timer.queue_free()
		if is_instance_valid(remove_timer):
			remove_timer.queue_free()
	)
	enemy.add_child(remove_timer)
	remove_timer.start()


func throw_hammer():
	print("throw_hammer")
	if not slot or not slot.item_data is ItemDataWeapon:
		print("not slot or not slot.item_data is ItemDataWeapon")
		return
	var weapon: = slot.item_data as ItemDataWeapon
	if slot.quantity <= 0:
		print("slot.quantity <= 0")
		return

	print("slot.quantity: ", slot.quantity)

	slot.quantity -= 1
	var last_hammer = (slot.quantity <= 0)
	var new_quantity = slot.quantity
	if last_hammer:
		PLAYER.weapon_inventory_data.slot_datas[0] = null

	PLAYER.weapon_inventory_data.inventory_updated.emit(PLAYER.weapon_inventory_data)
	PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
	if reload_label:
		reload_label.text = str(new_quantity)

	if inventoryinterface:
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)

		var hotbarinventory = PLAYER.get_node("UI").get_node("HotBarInventory")
		if hotbarinventory:
			hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

		var weapon_inventory = inventoryinterface.get_node("WeaponInventory")
		weapon_inventory.call("populate_item_grid", PLAYER.weapon_inventory_data)



	var hammer = weapon.model_scene.instantiate()
	get_tree().current_scene.add_child(hammer)

	var area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	hammer.add_child(area)

	var start_pos = camera.global_transform.origin
	hammer.global_position = start_pos
	var dir = - camera.global_transform.basis.z.normalized()

	var speed = 30.0
	var return_speed = 20.0
	var range = weapon.range
	var time_step = 0.016
	var max_time = 20.0
	var elapsed = 0.0

	var outbound = true
	var enemies_hit_outbound = {}
	var enemies_hit_inbound = {}

	while elapsed < max_time:
		await get_tree().create_timer(time_step).timeout
		elapsed += time_step

		if outbound:
			var new_pos = hammer.global_position + dir * speed * time_step
			var space = PLAYER.get_world_3d().direct_space_state
			var params = PhysicsShapeQueryParameters3D.new()
			params.shape = sphere_shape
			params.transform = Transform3D(Basis(), new_pos)
			params.collision_mask = 4294967295
			params.exclude = [PLAYER, hammer]
			var results = space.intersect_shape(params)

			var wall_hit = false
			for result in results:
				var collider = result.collider
				if collider.has_method("take_damage"):
					if not enemies_hit_outbound.has(collider):
						collider.take_damage(weapon.damage)
						enemies_hit_outbound[collider] = true
				else:
					wall_hit = true

			hammer.global_position = new_pos

			LevelManager.add_alert(new_pos, 1.5)

			if wall_hit or hammer.global_position.distance_to(start_pos) > range:
				outbound = false

		else:
			var to_player = PLAYER.global_position - hammer.global_position
			var dist_to_player = to_player.length()
			var move_dir = to_player.normalized() if dist_to_player > 0 else Vector3.ZERO

			var new_pos = hammer.global_position + move_dir * return_speed * time_step

			var space = PLAYER.get_world_3d().direct_space_state
			var params = PhysicsShapeQueryParameters3D.new()
			params.shape = sphere_shape
			params.transform = Transform3D(Basis(), new_pos)
			params.collision_mask = 4294967295
			params.exclude = [PLAYER, hammer]
			var results = space.intersect_shape(params)

			for result in results:
				var collider = result.collider
				if collider.has_method("take_damage"):
					if not enemies_hit_inbound.has(collider):
						collider.take_damage(weapon.damage)
						enemies_hit_inbound[collider] = true

			hammer.global_position = new_pos

			LevelManager.add_alert(new_pos, 1.5)


			var pickup_radius = 2.0
			if hammer.global_position.distance_to(PLAYER.global_position) <= pickup_radius:
				var added = false
				if PLAYER.weapon_inventory_data.slot_datas[0] == null:
					print("added to weapon inventory")
					var new_slot = SlotData.new()
					new_slot.item_data = weapon
					new_slot.quantity = 1
					PLAYER.weapon_inventory_data.slot_datas[0] = new_slot
					added = true
					PLAYER.weapon_inventory_data.inventory_updated.emit(PLAYER.weapon_inventory_data)
					break
				for i in range(PLAYER.inventory_data.slot_datas.size()):
					if PLAYER.inventory_data.slot_datas[i] == null:
						var new_slot = SlotData.new()
						new_slot.item_data = weapon
						new_slot.quantity = 1
						PLAYER.inventory_data.slot_datas[i] = new_slot
						added = true
						break
				if added:
					PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
					if reload_label:
						reload_label.text = str(slot.quantity if slot else 0)
					hammer.queue_free()
					break
				else:
					var angle = elapsed * 2.0
					var offset = Vector3(cos(angle), 0, sin(angle)) * pickup_radius
					hammer.global_position = PLAYER.global_position + offset
			else:
				pass

	if hammer and is_instance_valid(hammer):
		hammer.queue_free()

	if last_hammer:
		weaponscene.visible = false
		transition.emit("UnequippedWeaponState")
	else:
		transition.emit("IdleWeaponState")

func swing_scythe():
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	weapon_fired.emit()

	LevelManager.add_alert(owner.global_position, 1.5)


	var sword_model = weaponscene

	var original_pos = sword_model.position
	var original_rot = sword_model.rotation

	var target_pos = original_pos + Vector3(
		-1.2, 
		-0.2, 
		0.8
	)

	var target_rot = original_rot + Vector3(
		deg_to_rad(-30), 
		deg_to_rad(60), 
		0
	)



	var tween = create_tween()
	tween.tween_property(sword_model, "position", target_pos, weapon.swing_forward_speed)
	tween.parallel().tween_property(sword_model, "rotation", target_rot, weapon.swing_forward_speed)
	tween.tween_property(sword_model, "position", original_pos, weapon.swing_backward_speed)
	tween.parallel().tween_property(sword_model, "rotation", original_rot, weapon.swing_backward_speed)
	var space = PLAYER.get_world_3d().direct_space_state
	var shape = BoxShape3D.new()
	shape.size = Vector3(5 * 1.8, 5 * 0.5, 5)

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1 << 3
	var forward = - camera.global_transform.basis.z
	var right = camera.global_transform.basis.x
	var shape_pos = camera.global_transform.origin + forward * 5 * 0.9 + right * -0.6
	params.transform = Transform3D(Basis(), shape_pos)

	var hits = space.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider.has_method("enemy_resource"):
			collider.enemy_resource.current_health -= weapon.damage
		elif collider.has_method("take_damage"):
			collider.take_damage(weapon.damage)

	await tween.finished
	transition.emit("IdleWeaponState")

func swing_vorpal():
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	weapon_fired.emit()

	LevelManager.add_alert(owner.global_position, 1.5)

	var sword_model = weaponscene

	var original_pos = sword_model.position
	var original_rot = sword_model.rotation

	var target_pos = original_pos + Vector3(
		-1.2, 
		-0.2, 
		0.8
	)

	var target_rot = original_rot + Vector3(
		deg_to_rad(-30), 
		deg_to_rad(60), 
		0
	)

	var tween = create_tween()
	tween.tween_property(sword_model, "position", target_pos, weapon.swing_forward_speed)
	tween.parallel().tween_property(sword_model, "rotation", target_rot, weapon.swing_forward_speed)
	tween.tween_property(sword_model, "position", original_pos, weapon.swing_backward_speed)
	tween.parallel().tween_property(sword_model, "rotation", original_rot, weapon.swing_backward_speed)
	var space = PLAYER.get_world_3d().direct_space_state
	var shape = BoxShape3D.new()
	shape.size = Vector3(weapon.range * 1.8, weapon.range * 0.5, weapon.range)

	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.collision_mask = 1 << 3
	var forward = - camera.global_transform.basis.z
	var right = camera.global_transform.basis.x
	var shape_pos = camera.global_transform.origin + forward * weapon.range * 0.9 + right * -0.6
	params.transform = Transform3D(Basis(), shape_pos)

	var hits = space.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider.has_method("enemy_resource"):
			if randi_range(0, 100) <= 15:
				collider.enemy_resource.current_health -= weapon.damage + 60
			else:
				collider.enemy_resource.current_health -= weapon.damage
		elif collider.has_method("take_damage"):
			if randi_range(0, 100) <= 15:
				collider.take_damage(weapon.damage + 60)
			else:
				collider.take_damage(weapon.damage)

	await tween.finished
	transition.emit("IdleWeaponState")

func fire_rocket():
	if not slot or not slot.item_data is ItemDataWeapon:
		return

	var weapon: = slot.item_data as ItemDataWeapon

	if weapon.bullets_loaded == 0:
		print("Firing transitioning to Reloading")
		transition.emit("ReloadingWeaponState")
		return

	weapon_fired.emit()
	weapon.bullets_loaded -= 1
	if reload_label:
		reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]

	var from: Vector3 = camera.global_transform.origin
	var dir: Vector3 = - camera.global_transform.basis.z
	var to: Vector3 = from + dir * weapon.range
	var space = PLAYER.get_world_3d().direct_space_state

	var params_hole: = PhysicsRayQueryParameters3D.new()
	params_hole.from = from
	params_hole.to = to
	params_hole.collision_mask = 4294967295
	var hit: = space.intersect_ray(params_hole)
	if hit:
		create_bullet_hole(hit)

	var impact_point = hit.get("position", to)

	_rocket_explode(impact_point, weapon)

	if inventoryinterface:
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)

	var hotbarinventory = PLAYER.get_parent().find_child("HotBarInventory")
	if hotbarinventory:
		hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

	reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]
	add_muzzle_flash()
	add_recoil()

	LevelManager.add_alert(owner.global_position, 3)

func _rocket_explode(position: Vector3, weapon: ItemDataWeapon):
	var radius = 5.0

	var sphere = MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.mesh.radius = radius
	sphere.mesh.height = radius * 2
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.3
	material.cull_mode = BaseMaterial3D.CullMode.CULL_DISABLED
	sphere.material_override = material
	get_tree().current_scene.add_child(sphere)
	sphere.global_position = position

	var light = OmniLight3D.new()
	light.omni_range = radius * 2
	light.light_color = Color.YELLOW
	light.light_energy = 20
	get_tree().current_scene.add_child(light)
	light.global_position = position

	LevelManager.add_alert(owner.global_position, 5)

	var tween = create_tween()
	tween.parallel().tween_property(sphere, "scale", Vector3.ZERO, 0.5)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)
	tween.tween_callback(sphere.queue_free)
	tween.tween_callback(light.queue_free)

	var space = PLAYER.get_world_3d().direct_space_state
	var shape = SphereShape3D.new()
	shape.radius = radius
	var params = PhysicsShapeQueryParameters3D.new()
	params.shape = shape
	params.transform = Transform3D(Basis(), position)
	params.collision_mask = 1 << 3

	var hits = space.intersect_shape(params)
	for hit in hits:
		var collider = hit.collider
		if collider.has_method("enemy_resource"):
			collider.enemy_resource.current_health -= weapon.damage
		elif collider.has_method("take_damage"):
			collider.take_damage(weapon.damage)

func throw_spear():
	print("throw_spear")
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	if slot.quantity <= 0:
		return

	slot.quantity -= 1
	var last_spear = (slot.quantity <= 0)
	var new_quantity = slot.quantity
	if last_spear:
		PLAYER.weapon_inventory_data.slot_datas[0] = null

	PLAYER.weapon_inventory_data.inventory_updated.emit(PLAYER.weapon_inventory_data)
	PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
	if reload_label:
		reload_label.text = str(new_quantity)

	if inventoryinterface:
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)
		var hotbarinventory = PLAYER.get_node("UI").get_node("HotBarInventory")
		if hotbarinventory:
			hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)
		var weapon_inventory = inventoryinterface.get_node("WeaponInventory")
		weapon_inventory.call("populate_item_grid", PLAYER.weapon_inventory_data)

	var spear = weapon.model_scene.instantiate()
	get_tree().current_scene.add_child(spear)

	var area = Area3D.new()
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	spear.add_child(area)

	var start_pos = camera.global_transform.origin
	spear.global_position = start_pos
	var dir = - camera.global_transform.basis.z.normalized()

	var speed = 30.0
	var return_speed = 20.0
	var range = weapon.range
	var time_step = 0.016
	var max_time = 20.0
	var elapsed = 0.0

	var outbound = true
	var enemies_hit_outbound = {}
	var enemies_hit_inbound = {}

	var homing_radius = 2.5

	while elapsed < max_time:
		await get_tree().create_timer(time_step).timeout
		elapsed += time_step

		if outbound:
			var space = PLAYER.get_world_3d().direct_space_state
			var homing_params = PhysicsShapeQueryParameters3D.new()
			var homing_shape = SphereShape3D.new()
			homing_shape.radius = homing_radius
			homing_params.shape = homing_shape
			homing_params.transform = Transform3D(Basis(), spear.global_position)
			homing_params.collision_mask = 1 << 3
			homing_params.exclude = [PLAYER, spear]
			var nearby = space.intersect_shape(homing_params)

			if nearby.size() > 0:
				var closest = null
				var closest_dist = INF
				for hit in nearby:
					var enemy = hit.collider
					if enemy and enemy.has_method("take_damage"):
						var dist = spear.global_position.distance_to(enemy.global_position)
						if dist < closest_dist:
							closest_dist = dist
							closest = enemy
				if closest:
					var to_enemy = (closest.global_position - spear.global_position).normalized()
					var blend = 0.5
					var new_dir = (dir * (1 - blend) + to_enemy * blend).normalized()
					dir = new_dir

			var new_pos = spear.global_position + dir * speed * time_step

			var damage_params = PhysicsShapeQueryParameters3D.new()
			damage_params.shape = sphere_shape
			damage_params.transform = Transform3D(Basis(), new_pos)
			damage_params.collision_mask = 4294967295
			damage_params.exclude = [PLAYER, spear]
			var damage_results = space.intersect_shape(damage_params)

			var wall_hit = false
			for result in damage_results:
				var collider = result.collider
				if collider.has_method("take_damage"):
					if not enemies_hit_outbound.has(collider):
						collider.take_damage(weapon.damage)
						enemies_hit_outbound[collider] = true
				else:
					wall_hit = true

			spear.global_position = new_pos

			LevelManager.add_alert(new_pos, 1.5)

			if dir.length_squared() > 0.001:
				spear.look_at(spear.global_position + dir, Vector3.UP)

			if wall_hit or spear.global_position.distance_to(start_pos) > range:
				outbound = false

		else:
			var to_player = PLAYER.global_position - spear.global_position
			var dist_to_player = to_player.length()
			var move_dir = to_player.normalized() if dist_to_player > 0 else Vector3.ZERO

			var new_pos = spear.global_position + move_dir * return_speed * time_step

			var space = PLAYER.get_world_3d().direct_space_state
			var params = PhysicsShapeQueryParameters3D.new()
			params.shape = sphere_shape
			params.transform = Transform3D(Basis(), new_pos)
			params.collision_mask = 4294967295
			params.exclude = [PLAYER, spear]
			var results = space.intersect_shape(params)

			for result in results:
				var collider = result.collider
				if collider.has_method("take_damage"):
					if not enemies_hit_inbound.has(collider):
						collider.take_damage(weapon.damage)
						enemies_hit_inbound[collider] = true

			spear.global_position = new_pos

			LevelManager.add_alert(new_pos, 1.5)

			if move_dir.length_squared() > 0.001:
				spear.look_at(spear.global_position + move_dir, Vector3.UP)


			var pickup_radius = 2.0
			if spear.global_position.distance_to(PLAYER.global_position) <= pickup_radius:
				var added = false
				if PLAYER.weapon_inventory_data.slot_datas[0] == null:
					var new_slot = SlotData.new()
					new_slot.item_data = weapon
					new_slot.quantity = 1
					PLAYER.weapon_inventory_data.slot_datas[0] = new_slot
					added = true
					PLAYER.weapon_inventory_data.inventory_updated.emit(PLAYER.weapon_inventory_data)
				else:
					for i in range(PLAYER.inventory_data.slot_datas.size()):
						if PLAYER.inventory_data.slot_datas[i] == null:
							var new_slot = SlotData.new()
							new_slot.item_data = weapon
							new_slot.quantity = 1
							PLAYER.inventory_data.slot_datas[i] = new_slot
							added = true
							break
				if added:
					PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
					if reload_label:
						reload_label.text = str(slot.quantity if slot else 0)
					spear.queue_free()
					break
				else:
					var angle = elapsed * 2.0
					var offset = Vector3(cos(angle), 0, sin(angle)) * pickup_radius
					spear.global_position = PLAYER.global_position + offset
			else:
				pass

	if spear and is_instance_valid(spear):
		spear.queue_free()

	if last_spear:
		weaponscene.visible = false
		transition.emit("UnequippedWeaponState")
	else:
		transition.emit("IdleWeaponState")

func fire_machine_gun():
	if not slot or not slot.item_data is ItemDataWeapon:
		return
	var weapon: = slot.item_data as ItemDataWeapon
	if weapon.bullets_loaded == 0:
		transition.emit("ReloadingWeaponState")
		return

	if has_node("MachineGunTimer"):
		var old_timer = get_node("MachineGunTimer")
		old_timer.stop()
		old_timer.queue_free()

	var timer = Timer.new()
	timer.name = "MachineGunTimer"
	timer.wait_time = 0.1
	timer.one_shot = false
	timer.timeout.connect(_machine_gun_fire.bind(weapon))
	add_child(timer)
	timer.start()

func _machine_gun_fire(weapon: ItemDataWeapon):
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_stop_machine_gun()
		transition.emit("IdleWeaponState")
		return
	if weapon.bullets_loaded == 0:
		_stop_machine_gun()
		transition.emit("ReloadingWeaponState")
		return

	weapon_fired.emit()
	weapon.bullets_loaded -= 1
	if reload_label:
		reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]

	var from: Vector3 = camera.global_transform.origin
	var dir: Vector3 = - camera.global_transform.basis.z
	var to: Vector3 = from + dir * weapon.range
	var space = PLAYER.get_world_3d().direct_space_state

	var params_hole = PhysicsRayQueryParameters3D.new()
	params_hole.from = from
	params_hole.to = to
	params_hole.collision_mask = 4294967295
	var hit = space.intersect_ray(params_hole)
	if hit:
		create_bullet_hole(hit)

	var params = PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.collision_mask = 1 << 3
	var result = space.intersect_ray(params)
	if result.size() > 0:
		var enemy_hit = result.get("collider")
		if enemy_hit.has_method("enemy_resource"):
			enemy_hit.enemy_resource.current_health -= weapon.damage
		elif enemy_hit.has_method("take_damage"):
			enemy_hit.take_damage(weapon.damage)

	if inventoryinterface:
		var player_panel = inventoryinterface.get_node_or_null("PlayerInventory")
		if player_panel and player_panel.has_method("populate_item_grid"):
			player_panel.call("populate_item_grid", PLAYER.inventory_data)
	var hotbarinventory = PLAYER.get_parent().find_child("HotBarInventory")
	if hotbarinventory:
		hotbarinventory.call("populate_hot_bar", PLAYER.inventory_data)

	reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]
	add_muzzle_flash()
	add_recoil()

	LevelManager.add_alert(owner.global_position, 3.5)

func _stop_machine_gun():
	if has_node("MachineGunTimer"):
		var timer = get_node("MachineGunTimer")
		timer.stop()
		timer.queue_free()
