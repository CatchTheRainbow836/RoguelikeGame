extends ItemData
class_name ItemDataConsumable

@export var type: int

func use(target) -> void :
    match type:
        0:
            target.heal(20)
        1:
            use_soldiers_medallion(target)
        2:
            use_elixir_of_heracles(target)
        3:
            use_world_eaters_tooth(target)
        4:
            use_vial_of_starlight(target)
        5:
            use_hags_fingernail(target)
        6:
            use_goblin_fire_oil(target)
        7:
            use_krakens_ink(target)
        8:
            use_stone_giants_pebble(target)
        9:
            use_lifeblood_syrette(target)
        10:
            use_sirens_locket(target)
        11:
            use_will_o_the_wisps(target)
        12:
            use_pandoras_box(target)
        13:
            use_clockwork_scarab(target)
        14:
            use_echo_of_valhalla(target)
        15:
            use_ambrosia_of_the_gods(target)
        16:
            use_puzzle_box_of_yggdrasil(target)

func use_soldiers_medallion(player: Node) -> void :
    var spirit = Node3D.new()
    spirit.name = "SoldiersMedallionSpirit"
    player.get_tree().current_scene.add_child(spirit)

    var mesh = MeshInstance3D.new()
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = 0.25
    sphere_mesh.height = 0.5
    mesh.mesh = sphere_mesh
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.PALE_GREEN
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.6
    mesh.material_override = material
    spirit.add_child(mesh)

    var light = OmniLight3D.new()
    light.light_color = Color.PALE_GREEN
    light.light_energy = 2.0
    light.omni_range = 1.0
    spirit.add_child(light)

    var area = Area3D.new()
    area.collision_mask = 1 << 3
    area.collision_layer = 0
    var shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = 0.25
    shape.shape = sphere_shape
    area.add_child(shape)
    spirit.add_child(area)

    var nav_agent = NavigationAgent3D.new()
    nav_agent.radius = 0.2
    nav_agent.max_speed = 10.0
    spirit.add_child(nav_agent)
    spirit.global_position = player.global_position + Vector3.UP * 2.25

    var timer = Timer.new()
    timer.wait_time = 0.02
    timer.one_shot = false
    timer.timeout.connect( func():
        var nearest = null
        var nearest_dist = INF
        for enemy in player.get_tree().get_nodes_in_group("enemies"):
            var dist = spirit.global_position.distance_to(enemy.global_position)
            if dist < 10 and dist < nearest_dist:
                nearest = enemy
                nearest_dist = dist

        if nearest:
            nav_agent.target_position = nearest.global_position

            var move_dir = Vector3.ZERO
            if not nav_agent.is_navigation_finished():
                var next_pos = nav_agent.get_next_path_position()
                move_dir = (next_pos - spirit.global_position).normalized()
            else:
                move_dir = (nearest.global_position - spirit.global_position).normalized()

            spirit.global_position += move_dir * nav_agent.max_speed * 0.02

            if move_dir.length_squared() > 0.01:
                spirit.look_at(spirit.global_position + move_dir, Vector3.UP)

            if spirit.global_position.distance_to(nearest.global_position) < 0.5:
                if nearest.has_method("take_damage"):
                    nearest.take_damage(20)
                spirit.queue_free()
                return
        else:
            var target_pos = player.global_position + Vector3.UP * 2.25
            spirit.global_position = spirit.global_position.lerp(target_pos, 0.1)
    )
    spirit.add_child(timer)
    timer.start()

    var cleanup_timer = Timer.new()
    cleanup_timer.wait_time = 15.0
    cleanup_timer.one_shot = true
    cleanup_timer.timeout.connect( func():
        if spirit and is_instance_valid(spirit):
            spirit.queue_free()
    )
    spirit.add_child(cleanup_timer)
    cleanup_timer.start()

func use_elixir_of_heracles(player: Node) -> void :
    if player.has_node("ElixirOfHeraclesTimer"):
        var old = player.get_node("ElixirOfHeraclesTimer")
        old.stop()
        old.queue_free()

    player.get_node("WeaponStateMachine").get_node("FiringWeaponState").melee_damage_buff = 1.5

    var timer = Timer.new()
    timer.name = "ElixirOfHeraclesTimer"
    timer.wait_time = 10.0
    timer.one_shot = true
    timer.timeout.connect( func():
        if is_instance_valid(player):
            player.get_node("WeaponStateMachine").get_node("FiringWeaponState").melee_damage_buff = 1.0
        timer.queue_free()
    )
    player.add_child(timer)
    timer.start()

func _cleanup_world_eaters(player: Node, callback: Callable) -> void :
    if player.took_damage.is_connected(callback):
        player.took_damage.disconnect(callback)
    player.remove_meta("world_eaters_callback")
    var timer = player.get_node_or_null("WorldEatersToothTimer")
    if timer:
        timer.queue_free()

func _reflect_damage(player: Node, dmg: float) -> void :
    var space = player.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = 2.5
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), player.global_position)
    params.collision_mask = 1 << 3
    var hits = space.intersect_shape(params)
    for hit in hits:
        var enemy = hit.collider
        if enemy.has_method("take_damage"):
            enemy.take_damage(dmg)

    var callback = player.get_meta("world_eaters_callback", null)
    if callback:
        _cleanup_world_eaters(player, callback)

func use_world_eaters_tooth(player: Node) -> void :
    if player.has_node("WorldEatersToothTimer"):
        return

    var reflect_callback = func(dmg: float):
        _reflect_damage(player, dmg)

    player.set_meta("world_eaters_callback", reflect_callback)
    player.took_damage.connect(reflect_callback)

    var timer = Timer.new()
    timer.name = "WorldEatersToothTimer"
    timer.wait_time = 15.0
    timer.one_shot = true
    timer.timeout.connect( func():
        var callback = player.get_meta("world_eaters_callback", null)
        if callback:
            _cleanup_world_eaters(player, callback)
        timer.queue_free()
    )
    player.add_child(timer)
    timer.start()

func use_vial_of_starlight(player: Node) -> void :
    var sphere = MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = 2.5
    sphere.mesh.height = 5.0
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.WHITE
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.8
    sphere.material_override = material
    player.get_parent().add_child(sphere)
    sphere.global_position = player.global_position

    var light = OmniLight3D.new()
    light.light_color = Color.WHITE
    light.light_energy = 10.0
    light.omni_range = 10.0
    player.get_parent().add_child(light)
    light.global_position = player.global_position

    var tween = player.create_tween()
    tween.parallel().tween_property(sphere, "scale", Vector3.ZERO, 0.2)
    tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.2)
    tween.parallel().tween_property(light, "light_energy", 0.0, 0.2)
    tween.tween_callback(sphere.queue_free)
    tween.tween_callback(light.queue_free)

    var space = player.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = 2.5
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), player.global_position)
    params.collision_mask = 1 << 3
    var hits = space.intersect_shape(params)

    for hit in hits:
        var enemy = hit.collider
        var enemy_state_machine = enemy.get_node_or_null("EnemyStateMachine")
        var attack_state_machine = enemy.get_node_or_null("AttackStateMachine")
        if enemy_state_machine and attack_state_machine:
            var idle_enemy_state = enemy_state_machine.get_node("IdleEnemyState")
            var idle_attack_state = attack_state_machine.get_node("IdleAttackState")

            var stun_timer = Timer.new()
            stun_timer.wait_time = 0.001
            stun_timer.one_shot = false
            stun_timer.timeout.connect( func():
                if is_instance_valid(enemy_state_machine) and is_instance_valid(attack_state_machine):
                    enemy_state_machine.CURRENT_STATE = idle_enemy_state
                    attack_state_machine.CURRENT_STATE = idle_attack_state
            )

            var remove_timer = Timer.new()
            remove_timer.wait_time = 3.0
            remove_timer.one_shot = true
            remove_timer.timeout.connect( func():
                if is_instance_valid(stun_timer):
                    stun_timer.stop()
                    stun_timer.queue_free()
                if is_instance_valid(remove_timer):
                    remove_timer.queue_free()
            )

            enemy.add_child(stun_timer)
            enemy.add_child(remove_timer)
            stun_timer.start()
            remove_timer.start()

func use_hags_fingernail(player: Node) -> void :
    if player.has_node("HagsFingernailDamageTimer"):
        var old = player.get_node("HagsFingernailDamageTimer")
        old.stop()
        old.queue_free()
    if player.has_node("HagsFingernailCleanupTimer"):
        var old = player.get_node("HagsFingernailCleanupTimer")
        old.stop()
        old.queue_free()

    player.get_node("WeaponStateMachine").get_node("FiringWeaponState").ranged_damage_buff = 1.75
    player.get_node("WeaponStateMachine").get_node("FiringWeaponState").melee_damage_buff = 1.75
    player.get_node("WeaponStateMachine").get_node("FiringWeaponState").projectile_damage_buff = 1.75

    var damage_timer = Timer.new()
    damage_timer.name = "HagsFingernailDamageTimer"
    damage_timer.wait_time = 1.0
    damage_timer.one_shot = false
    damage_timer.timeout.connect( func():
        if is_instance_valid(player):
            player.take_damage(5.0)
    )
    player.add_child(damage_timer)
    damage_timer.start()

    var cleanup_timer = Timer.new()
    cleanup_timer.name = "HagsFingernailCleanupTimer"
    cleanup_timer.wait_time = 10.0
    cleanup_timer.one_shot = true
    cleanup_timer.timeout.connect( func():
        if is_instance_valid(player):
            player.get_node("WeaponStateMachine").get_node("FiringWeaponState").ranged_damage_buff = 1.0
            player.get_node("WeaponStateMachine").get_node("FiringWeaponState").melee_damage_buff = 1.0
            player.get_node("WeaponStateMachine").get_node("FiringWeaponState").projectile_damage_buff = 1.0
        if damage_timer and is_instance_valid(damage_timer):
            damage_timer.stop()
            damage_timer.queue_free()
        cleanup_timer.queue_free()
    )
    player.add_child(cleanup_timer)
    cleanup_timer.start()

func use_goblin_fire_oil(player: Node) -> void :
    var cylinder = Node3D.new()
    cylinder.name = "GoblinFireOil"
    player.get_tree().current_scene.add_child(cylinder)

    var mesh = MeshInstance3D.new()
    var cylinder_mesh = CylinderMesh.new()
    cylinder_mesh.top_radius = 2.0
    cylinder_mesh.bottom_radius = 2.0
    cylinder_mesh.height = 0.1
    mesh.mesh = cylinder_mesh
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.5, 0.0, 0.75)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material_override = material
    cylinder.add_child(mesh)

    var area = Area3D.new()
    area.collision_mask = 4294967295
    area.collision_layer = 0
    var collision_shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = 2.0
    cylinder_shape.height = 0.1
    collision_shape.shape = cylinder_shape
    area.add_child(collision_shape)
    cylinder.add_child(area)

    cylinder.global_position = player.global_position
    cylinder.global_position.y = 0.05

    var damage_timer = Timer.new()
    damage_timer.wait_time = 1.0
    damage_timer.one_shot = false
    damage_timer.timeout.connect( func():
        var space = player.get_world_3d().direct_space_state
        var shape = CylinderShape3D.new()
        shape.radius = 2.0
        shape.height = 0.1
        var params = PhysicsShapeQueryParameters3D.new()
        params.shape = shape
        params.transform = Transform3D(Basis(), cylinder.global_position)
        params.collision_mask = 1 << 3
        var hits = space.intersect_shape(params)
        for hit in hits:
            var enemy = hit.collider
            if enemy.has_method("take_damage"):
                enemy.take_damage(5.0)

        var player_pos = player.global_position
        var dist = cylinder.global_position.distance_to(player_pos)
        if dist <= 2.0:
            player.take_damage(2.0)
    )
    cylinder.add_child(damage_timer)
    damage_timer.start()

    var cleanup_timer = Timer.new()
    cleanup_timer.wait_time = 6.0
    cleanup_timer.one_shot = true
    cleanup_timer.timeout.connect( func():
        if is_instance_valid(cylinder):
            cylinder.queue_free()
    )
    cylinder.add_child(cleanup_timer)
    cleanup_timer.start()

func use_krakens_ink(player: Node) -> void :
    var cylinder = Node3D.new()
    cylinder.name = "KrakensInk"
    player.get_tree().current_scene.add_child(cylinder)

    var mesh = MeshInstance3D.new()
    var cylinder_mesh = CylinderMesh.new()
    cylinder_mesh.top_radius = 1.5
    cylinder_mesh.bottom_radius = 1.5
    cylinder_mesh.height = 0.1
    mesh.mesh = cylinder_mesh
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.BLACK
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.95
    mesh.material_override = material
    cylinder.add_child(mesh)

    var area = Area3D.new()
    area.collision_mask = 1 << 3
    area.collision_layer = 0
    var collision_shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = 1.5
    cylinder_shape.height = 0.1
    collision_shape.shape = cylinder_shape
    area.add_child(collision_shape)
    cylinder.add_child(area)

    cylinder.global_position = player.global_position
    cylinder.global_position.y = 0.05

    var effect_timer = Timer.new()
    effect_timer.wait_time = 0.01
    effect_timer.one_shot = false
    effect_timer.timeout.connect( func():
        var space = player.get_world_3d().direct_space_state
        var shape = CylinderShape3D.new()
        shape.radius = 1.5
        shape.height = 0.1
        var params = PhysicsShapeQueryParameters3D.new()
        params.shape = shape
        params.transform = Transform3D(Basis(), cylinder.global_position)
        params.collision_mask = 1 << 3
        var hits = space.intersect_shape(params)
        for hit in hits:
            var enemy = hit.collider
            if enemy is CharacterBody3D:
                enemy.velocity *= 0.6
            var movement_state_machine = enemy.get_node("EnemyStateMachine")
            var walking_enemy_state = movement_state_machine.get_node("WalkingEnemyState")
            movement_state_machine.CURRENT_STATE = walking_enemy_state
            var attack_state_machine = enemy.get_node("AttackStateMachine")
            var idle_attack_state = attack_state_machine.get_node("IdleAttackState")
            attack_state_machine.CURRENT_STATE = idle_attack_state
    )
    cylinder.add_child(effect_timer)
    effect_timer.start()

    var cleanup_timer = Timer.new()
    cleanup_timer.wait_time = 5.0
    cleanup_timer.one_shot = true
    cleanup_timer.timeout.connect( func():
        if is_instance_valid(cylinder):
            cylinder.queue_free()
    )
    cylinder.add_child(cleanup_timer)
    cleanup_timer.start()

func use_stone_giants_pebble(player: Node) -> void :
    var camera = player.get_node("Pivot").get_node("Camera3D")
    var forward = - camera.global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()

    var spawn_pos = player.global_position + forward * 2.0
    spawn_pos.y = 0.0

    var block = StaticBody3D.new()
    block.name = "StoneGiantPebble"
    player.get_tree().current_scene.add_child(block)
    block.global_position = spawn_pos

    var mesh_instance = MeshInstance3D.new()
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(1.0, 6.0, 3.0)
    mesh_instance.mesh = box_mesh
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.5, 0.5, 0.5)
    mesh_instance.material_override = material
    block.add_child(mesh_instance)

    var collision = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(1.0, 6.0, 3.0)
    collision.shape = box_shape
    block.add_child(collision)

    var dir_to_player = (player.global_position - spawn_pos).normalized()
    dir_to_player.y = 0.0
    if dir_to_player.length() < 0.001:
        dir_to_player = Vector3.FORWARD
    dir_to_player = dir_to_player.normalized()

    var up = Vector3.UP
    var z_axis = up.cross(dir_to_player).normalized()
    var x_axis = dir_to_player
    var y_axis = up
    block.global_transform.basis = Basis(x_axis, y_axis, z_axis)

    var timer = Timer.new()
    timer.wait_time = 10.0
    timer.one_shot = true
    timer.timeout.connect( func():
        if is_instance_valid(block):
            block.queue_free()
    )
    block.add_child(timer)
    timer.start()

func use_lifeblood_syrette(player: Node) -> void :
    if player.has_node("LifebloodSyretteTimer"):
        var old_timer = player.get_node("LifebloodSyretteTimer")
        old_timer.stop()
        old_timer.queue_free()
    else:
        player.max_health += 20

        if player.health > player.max_health:
            player.health = player.max_health

    var timer = Timer.new()
    timer.name = "LifebloodSyretteTimer"
    timer.wait_time = 10.0
    timer.one_shot = true
    timer.timeout.connect( func():
        if is_instance_valid(player):
            player.max_health -= 20
            player.take_damage(50)
        timer.queue_free()
    )
    player.add_child(timer)
    timer.start()

func use_sirens_locket(player: Node) -> void :
    if player.has_node("SirensLocketTimer"):
        return

    var effect_timer = Timer.new()
    effect_timer.name = "SirensLocketTimer"
    effect_timer.wait_time = 0.001
    effect_timer.one_shot = false
    effect_timer.timeout.connect( func():
        var space = player.get_world_3d().direct_space_state
        var shape = SphereShape3D.new()
        shape.radius = 7.0
        var params = PhysicsShapeQueryParameters3D.new()
        params.shape = shape
        params.transform = Transform3D(Basis(), player.global_position)
        params.collision_mask = 1 << 3
        var hits = space.intersect_shape(params)

        for hit in hits:
            var enemy = hit.collider
            if not enemy.has_method("take_damage"):
                continue

            var movement_sm = enemy.get_node_or_null("EnemyStateMachine")
            if movement_sm and movement_sm.has_node("IdleEnemyState"):
                var idle_state = movement_sm.get_node("IdleEnemyState")
                movement_sm.CURRENT_STATE = idle_state

            var attack_sm = enemy.get_node_or_null("AttackStateMachine")
            if attack_sm and attack_sm.has_node("IdleAttackState"):
                var idle_attack = attack_sm.get_node("IdleAttackState")
                attack_sm.CURRENT_STATE = idle_attack

            var dist = enemy.global_position.distance_to(player.global_position)
            if dist > 1.5:
                var target_pos = player.global_position
                target_pos.y = enemy.global_position.y
                enemy.global_position = enemy.global_position.lerp(target_pos, 0.1)
    )
    player.add_child(effect_timer)
    effect_timer.start()

    var cleanup_timer = Timer.new()
    cleanup_timer.wait_time = 5.0
    cleanup_timer.one_shot = true
    cleanup_timer.timeout.connect( func():
        if effect_timer and is_instance_valid(effect_timer):
            effect_timer.stop()
            effect_timer.queue_free()
        cleanup_timer.queue_free()
    )
    player.add_child(cleanup_timer)
    cleanup_timer.start()


func use_will_o_the_wisps(player: Node) -> void :
    print("use_will_o_the_wisps")
    var nav_region = player.get_parent().get_node("WorldStructures").get_node("NavigationRegion3D") as NavigationRegion3D
    if not nav_region:
        return

    var player_cell = nav_region.get_cell_from_world(player.global_position)
    var elevator_cell = nav_region.current_elevator.get("cell", Vector2(-1, -1))
    if player_cell == Vector2(-1, -1) or elevator_cell == Vector2(-1, -1):
        return

    var full_path = nav_region.find_path(player_cell, elevator_cell)
    if full_path.is_empty():
        return

    var max_markers = 25
    var limited_path = full_path.slice(0, min(max_markers, full_path.size()))

    var markers = player.get_tree().get_nodes_in_group("wisp_markers")
    for m in markers:
        if is_instance_valid(m):
            m.queue_free()

    var created_markers = []
    for cell in limited_path:
        var marker = _create_wisp_marker(cell, true)
        if marker:
            nav_region.add_child(marker)
            marker.add_to_group("wisp_markers")
            created_markers.append(marker)

    var spawn_state = {"index": 0}
    var spawn_timer = Timer.new()
    spawn_timer.wait_time = 0.2
    spawn_timer.one_shot = false
    spawn_timer.timeout.connect( func():
        if spawn_state.index < created_markers.size():
            var marker = created_markers[spawn_state.index]
            if is_instance_valid(marker):
                var tween = marker.create_tween()
                tween.tween_property(marker, "position:y", 0.1, 0.2)
                tween.parallel().tween_property(marker, "scale", Vector3.ONE, 0.2)
            spawn_state.index += 1
        else:
            spawn_timer.stop()
            spawn_timer.queue_free()
    )
    player.add_child(spawn_timer)
    spawn_timer.start()

    var cleanup_timer = Timer.new()
    cleanup_timer.wait_time = 5.0
    cleanup_timer.one_shot = true
    cleanup_timer.timeout.connect( func():
        if spawn_timer and is_instance_valid(spawn_timer):
            spawn_timer.stop()
            spawn_timer.queue_free()

        var remove_state = {"index": 0}
        var remove_timer = Timer.new()
        remove_timer.wait_time = 0.2
        remove_timer.one_shot = false
        remove_timer.timeout.connect( func():
            if remove_state.index < created_markers.size():
                var marker = created_markers[remove_state.index]
                if is_instance_valid(marker):
                    marker.queue_free()
                remove_state.index += 1
            else:
                remove_timer.stop()
                remove_timer.queue_free()
        )
        player.add_child(remove_timer)
        remove_timer.start()
        cleanup_timer.queue_free()
    )
    player.add_child(cleanup_timer)
    cleanup_timer.start()

func _create_wisp_marker(cell: Vector2, below_ground: bool = false) -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(8.0, 0.05, 8.0)
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 1.0, 0.5, 0.5)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    box.material = material
    mesh.mesh = box
    var y_pos = -0.5 if below_ground else 0.1
    mesh.position = Vector3(cell.x, y_pos, cell.y)

    var light = OmniLight3D.new()
    light.light_color = Color(1.0, 1.0, 0.5)
    light.light_energy = 1.0
    light.omni_range = 2.0
    mesh.add_child(light)

    return mesh

func use_pandoras_box(player: Node) -> void :
    var space = player.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = 1.0
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), player.global_position)
    params.collision_mask = 1 << 3
    var hits = space.intersect_shape(params)
    for hit in hits:
        var enemy = hit.collider
        if not enemy:
            continue

        var damage = enemy.current_health * 0.2
        enemy.take_damage(damage)

func use_clockwork_scarab(player: Node) -> void :
    var bosses = player.get_tree().get_nodes_in_group("boss_enemies")
    if bosses.is_empty():
        return
    var boss = bosses[0]

    var scarab = Node3D.new()
    scarab.name = "ClockworkScarab"
    player.get_tree().current_scene.add_child(scarab)

    var mesh = MeshInstance3D.new()
    var box_mesh = BoxMesh.new()
    box_mesh.size = Vector3(0.25, 0.25, 0.25)
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.8, 0.2)
    mesh.material_override = material
    mesh.mesh = box_mesh
    scarab.add_child(mesh)

    var area = Area3D.new()
    area.collision_mask = 1 << 3
    area.collision_layer = 0
    var shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(0.25, 0.25, 0.25)
    shape.shape = box_shape
    area.add_child(shape)
    scarab.add_child(area)

    var start_pos = player.global_position
    start_pos.y = 0.05
    scarab.global_position = start_pos

    var speed = 5.0
    var step = 0.016
    var elapsed = 0.0
    var max_time = 10.0

    var hit = false
    var move_timer = Timer.new()
    move_timer.wait_time = step
    move_timer.one_shot = false
    move_timer.timeout.connect( func():
        if hit:
            return
        elapsed += step
        if elapsed > max_time:
            scarab.queue_free()
            move_timer.queue_free()
            return

        if boss == null: return
        var to_boss = boss.global_position - scarab.global_position
        to_boss.y = 0.0
        var dist = to_boss.length()
        if dist < 0.1:
            hit = true
            _explode_scarab(scarab, boss)
            return

        var dir = to_boss.normalized()
        var new_pos = scarab.global_position + dir * speed * step
        new_pos.y = 0.05
        scarab.global_position = new_pos

        if dir.length_squared() > 0:
            scarab.look_at(scarab.global_position + dir, Vector3.UP)

        if dist < 0.25:
            hit = true
            _explode_scarab(scarab, boss)
    )
    scarab.add_child(move_timer)
    move_timer.start()

    area.body_entered.connect( func(body):
        if not hit and body == boss:
            hit = true
            _explode_scarab(scarab, boss)
    )

func _explode_scarab(scarab: Node, boss: Node) -> void :
    var explosion = MeshInstance3D.new()
    var sphere_mesh = SphereMesh.new()
    sphere_mesh.radius = 1
    sphere_mesh.height = 2.0
    explosion.mesh = sphere_mesh
    var mat = StandardMaterial3D.new()
    mat.albedo_color = Color(1.0, 0.5, 0.0, 0.8)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    explosion.material_override = mat
    scarab.get_tree().current_scene.add_child(explosion)
    explosion.global_position = scarab.global_position

    var tween = explosion.create_tween()
    tween.parallel().tween_property(explosion, "scale", Vector3.ZERO, 0.5)
    tween.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.5)
    tween.tween_callback(explosion.queue_free)

    if boss.has_method("take_damage"):
        boss.take_damage(60)
    elif boss.has_method("enemy_resource") and boss.enemy_resource.has_method("take_damage"):
        boss.enemy_resource.take_damage(60)

    if scarab and is_instance_valid(scarab):
        scarab.queue_free()

func use_echo_of_valhalla(player: Node) -> void :
    if player.has_node("EchoOfValhallaTimer"):
        var old = player.get_node("EchoOfValhallaTimer")
        old.stop()
        old.queue_free()
    else:
        player.defense_buff = 0.6

    var timer = Timer.new()
    timer.name = "EchoOfValhallaTimer"
    timer.wait_time = 10.0
    timer.one_shot = true
    timer.timeout.connect( func():
        if is_instance_valid(player):
            player.defense_buff = 1.0
        timer.queue_free()
    )
    player.add_child(timer)
    timer.start()

func use_ambrosia_of_the_gods(player: Node) -> void :
    player.health = player.max_health

    if player.has_node("AmbrosiaTimer"):
        var old = player.get_node("AmbrosiaTimer")
        old.stop()
        old.queue_free()
    else:
        player.defense_buff = 0.0

    var timer = Timer.new()
    timer.name = "AmbrosiaTimer"
    timer.wait_time = 4.0
    timer.one_shot = true
    timer.timeout.connect( func():
        if is_instance_valid(player):
            player.defense_buff = 1.0
        timer.queue_free()
    )
    player.add_child(timer)
    timer.start()

func use_puzzle_box_of_yggdrasil(player: Node) -> void :
    if player.has_node("YggdrasilUpdateTimer"):
        var old_timer = player.get_node("YggdrasilUpdateTimer")
        old_timer.stop()
        old_timer.queue_free()
    if player.has_meta("yggdrasil_markers"):
        var markers = player.get_meta("yggdrasil_markers")
        for marker in markers.values():
            if is_instance_valid(marker):
                marker.queue_free()
    player.remove_meta("yggdrasil_markers")

    var nav_region = player.get_parent().get_node("WorldStructures").get_node("NavigationRegion3D") as NavigationRegion3D
    if not nav_region:
        return

    var player_cell = nav_region.get_cell_from_world(player.global_position)
    var elevator_cell = nav_region.current_elevator.get("cell", Vector2(-1, -1))
    if player_cell == Vector2(-1, -1) or elevator_cell == Vector2(-1, -1):
        return

    var path = nav_region.find_path(player_cell, elevator_cell)
    if path.is_empty():
        return

    var current_markers = {}
    player.set_meta("yggdrasil_markers", current_markers)

    for cell in path:
        var marker = _create_path_marker(cell, true)
        if marker:
            nav_region.add_child(marker)
            marker.add_to_group("yggdrasil_path")
            current_markers[cell] = marker

    var spawn_state = {"index": 0}
    var path_list = path
    var spawn_timer = Timer.new()
    spawn_timer.wait_time = 0.05
    spawn_timer.one_shot = false
    spawn_timer.timeout.connect( func():
        if spawn_state.index < path_list.size():
            var cell = path_list[spawn_state.index]
            var marker = current_markers.get(cell)
            if is_instance_valid(marker):
                var tween = marker.create_tween()
                tween.tween_property(marker, "position:y", 0.1, 0.2)
            spawn_state.index += 1
        else:
            spawn_timer.stop()
            spawn_timer.queue_free()
    )
    player.add_child(spawn_timer)
    spawn_timer.start()

    var update_timer = Timer.new()
    update_timer.name = "YggdrasilUpdateTimer"
    update_timer.wait_time = 0.2
    update_timer.one_shot = false
    update_timer.timeout.connect( func():
        if not is_instance_valid(player):
            update_timer.stop()
            update_timer.queue_free()
            return
        var new_player_cell = nav_region.get_cell_from_world(player.global_position)
        if new_player_cell == Vector2(-1, -1):
            return
        var new_path = nav_region.find_path(new_player_cell, elevator_cell)
        if new_path.is_empty():
            return

        var old_cells = current_markers.keys()
        var new_cells = new_path
        var to_add = []
        var to_remove = []

        for cell in new_cells:
            if not current_markers.has(cell):
                to_add.append(cell)
        for cell in old_cells:
            if not new_cells.has(cell):
                to_remove.append(cell)

        for cell in to_add:
            var marker = _create_path_marker(cell, true)
            if marker:
                nav_region.add_child(marker)
                marker.add_to_group("yggdrasil_path")
                current_markers[cell] = marker
                var tween = marker.create_tween()
                tween.tween_property(marker, "position:y", 0.1, 0.2)

        for cell in to_remove:
            var marker = current_markers.get(cell)
            if is_instance_valid(marker):
                var tween = marker.create_tween()
                tween.tween_property(marker, "position:y", -0.5, 0.2)
                tween.finished.connect( func():
                    if is_instance_valid(marker):
                        marker.queue_free()
                )
                current_markers.erase(cell)
    )
    player.add_child(update_timer)
    update_timer.start()

func _create_path_marker(cell: Vector2, below_ground: bool = false) -> MeshInstance3D:
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(8.0, 0.05, 8.0)
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 1.0, 0.5, 0.5)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    box.material = material
    mesh.mesh = box
    var y_pos = -0.5 if below_ground else 0.1
    mesh.position = Vector3(cell.x, y_pos, cell.y)

    var light = OmniLight3D.new()
    light.light_color = Color(1.0, 1.0, 0.5)
    light.light_energy = 1.0
    light.omni_range = 2.0
    mesh.add_child(light)

    return mesh
