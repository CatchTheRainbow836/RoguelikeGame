extends CrucibleCoreAttackState
class_name PhaseThreeAttackingCrucibleCoreAttackState

var boss: CrucibleCore
var recorded_weapon: ItemDataWeapon
var bullets_loaded: int
var pivot: Node3D
var _machine_gun_timer: Timer = null
var _machine_gun_active: bool = false
@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

var _is_throwing: bool = false
var _is_throwing_spear: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as CrucibleCore
    recorded_weapon = boss.recorded_weapon
    pivot = owner.get_node("Pivot")

func enter() -> void :
    super.enter()
    if not recorded_weapon:
        transition.emit("IdleAttackState")
        return

    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        bullets_loaded = idle_state.bullets_loaded

    _is_throwing = false
    _is_throwing_spear = false

    match recorded_weapon.type:
        100, 101, 102:
            _fire_gun()
            await get_tree().create_timer(0.2).timeout
            transition.emit("IdleAttackState")
        103:
            _fire_blowpipe()
            await get_tree().create_timer(0.2).timeout
            transition.emit("IdleAttackState")
        104:
            _swing_scythe()
            _fire_gun()
            transition.emit("IdleAttackState")
        105:
            _fire_rocket()
            await get_tree().create_timer(0.2).timeout
            transition.emit("IdleAttackState")
        106:
            _fire_machine_gun()
            _machine_gun_active = true
            _machine_gun_timer = Timer.new()
            _machine_gun_timer.wait_time = 0.1
            _machine_gun_timer.one_shot = false
            _machine_gun_timer.timeout.connect(_machine_gun_continuous_fire)
            add_child(_machine_gun_timer)
            _machine_gun_timer.start()
        200:
            _swing_sword()
            await get_tree().create_timer(recorded_weapon.swing_forward_speed + recorded_weapon.swing_backward_speed).timeout
            transition.emit("IdleAttackState")
        201:
            _swing_vorpal()
            await get_tree().create_timer(recorded_weapon.swing_forward_speed + recorded_weapon.swing_backward_speed).timeout
            transition.emit("IdleAttackState")
        300:
            _throw_projectile()
        301:
            _throw_smoke()
        302:
            _throw_stun_grenade()
        303:
            _throw_hammer()
        304:
            _throw_spear()
        _:
            await get_tree().process_frame
            transition.emit("IdleAttackState")

func exit() -> void :
    if _machine_gun_timer:
        _machine_gun_timer.stop()
        _machine_gun_timer.queue_free()
        _machine_gun_timer = null
    _machine_gun_active = false

func _get_aim_point() -> Vector3:
    if not PLAYER:
        return Vector3.ZERO
    return PLAYER.global_position + Vector3(0, 1.0, 0)

func _rotate_weapon_to_aim() -> void :
    if not boss.weapon_model_instance:
        return
    var aim_point = _get_aim_point()
    var direction = (aim_point - boss.weapon_model_instance.global_position).normalized()
    boss.weapon_model_instance.look_at(boss.weapon_model_instance.global_position + direction, Vector3.UP)

func _fire_gun() -> void :
    if bullets_loaded <= 0:
        return
    bullets_loaded -= 1

    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.bullets_loaded = bullets_loaded

    var from = _get_weapon_fire_position()
    var aim_point = _get_aim_point()
    var dir = (aim_point - from).normalized()
    var to = from + dir * recorded_weapon.range
    var space = owner.get_world_3d().direct_space_state

    var params_hole = PhysicsRayQueryParameters3D.new()
    params_hole.from = from
    params_hole.to = to
    params_hole.collision_mask = 4294967295
    var hit = space.intersect_ray(params_hole)
    if hit:
        _create_bullet_hole(hit)

    var params = PhysicsRayQueryParameters3D.new()
    params.from = from
    params.to = to
    params.collision_mask = 2
    var result = space.intersect_ray(params)
    if result.size() > 0:
        var player_hit = result.get("collider")
        if player_hit.is_in_group("player") and player_hit.has_method("take_damage"):
            player_hit.take_damage(recorded_weapon.damage)

    AlertnessManager.add_alert(owner.global_position, 3)
    _add_muzzle_flash()
    _add_recoil()
    _rotate_weapon_to_aim()

func _fire_blowpipe() -> void :
    if bullets_loaded <= 0:
        return
    bullets_loaded -= 1
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.bullets_loaded = bullets_loaded

    var from = _get_weapon_fire_position()
    var aim_point = _get_aim_point()
    var dir = (aim_point - from).normalized()
    var to = from + dir * recorded_weapon.range
    var space = owner.get_world_3d().direct_space_state

    var params_hole = PhysicsRayQueryParameters3D.new()
    params_hole.from = from
    params_hole.to = to
    params_hole.collision_mask = 4294967295
    var hit = space.intersect_ray(params_hole)
    if hit:
        _create_bullet_hole(hit)

    var params = PhysicsRayQueryParameters3D.new()
    params.from = from
    params.to = to
    params.collision_mask = 2
    var result = space.intersect_ray(params)
    if result.size() > 0:
        var player_hit = result.get("collider")
        if player_hit.is_in_group("player") and player_hit.has_method("take_damage"):
            player_hit.take_damage(recorded_weapon.damage)
            _apply_poison(player_hit)

    _add_muzzle_flash()
    _add_recoil()
    AlertnessManager.add_alert(owner.global_position, 1.5)
    _rotate_weapon_to_aim()

func _apply_poison(enemy: Node) -> void :
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
        remove_timer.queue_free()
    )
    enemy.add_child(remove_timer)
    remove_timer.start()

func _fire_rocket() -> void :
    if bullets_loaded <= 0:
        return
    bullets_loaded -= 1
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.bullets_loaded = bullets_loaded

    var from = _get_weapon_fire_position()
    var aim_point = _get_aim_point()
    var dir = (aim_point - from).normalized()
    var to = from + dir * recorded_weapon.range
    var space = owner.get_world_3d().direct_space_state

    var params = PhysicsRayQueryParameters3D.new()
    params.from = from
    params.to = to
    params.collision_mask = 4294967295
    params.exclude = [owner.get_rid()]
    var result = space.intersect_ray(params)
    var impact_point = result.get("position", to)
    _rocket_explode(impact_point)
    _add_muzzle_flash()
    _add_recoil()
    AlertnessManager.add_alert(owner.global_position, 5)
    _rotate_weapon_to_aim()

func _rocket_explode(position: Vector3) -> void :
    var radius = 5.0
    var sphere = MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = radius
    sphere.mesh.height = radius * 2
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.YELLOW
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.3
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    sphere.material_override = material
    get_tree().current_scene.add_child(sphere)
    sphere.global_position = position
    var light = OmniLight3D.new()
    light.omni_range = radius * 2
    light.light_color = Color.YELLOW
    light.light_energy = 20
    get_tree().current_scene.add_child(light)
    light.global_position = position
    var tween = create_tween()
    tween.parallel().tween_property(sphere, "scale", Vector3.ZERO, 0.5)
    tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)
    tween.tween_callback(sphere.queue_free)
    tween.tween_callback(light.queue_free)

    var space = owner.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = radius
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), position)
    params.collision_mask = 2
    var hits = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider.is_in_group("player") and collider.has_method("take_damage"):
            collider.take_damage(recorded_weapon.damage)

func _fire_machine_gun() -> void :
    _machine_gun_continuous_fire()

func _machine_gun_continuous_fire() -> void :
    if not _machine_gun_active:
        return
    if bullets_loaded <= 0:
        _machine_gun_active = false
        if _machine_gun_timer:
            _machine_gun_timer.stop()
        transition.emit("IdleAttackState")
        return
    bullets_loaded -= 1
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.bullets_loaded = bullets_loaded

    var from = _get_weapon_fire_position()
    var aim_point = _get_aim_point()
    var dir = (aim_point - from).normalized()
    var to = from + dir * recorded_weapon.range
    var space = owner.get_world_3d().direct_space_state

    var params_hole = PhysicsRayQueryParameters3D.new()
    params_hole.from = from
    params_hole.to = to
    params_hole.collision_mask = 4294967295
    var hit = space.intersect_ray(params_hole)
    if hit:
        _create_bullet_hole(hit)

    var params = PhysicsRayQueryParameters3D.new()
    params.from = from
    params.to = to
    params.collision_mask = 2
    var result = space.intersect_ray(params)
    if result.size() > 0:
        var player_hit = result.get("collider")
        if player_hit.is_in_group("player") and player_hit.has_method("take_damage"):
            player_hit.take_damage(recorded_weapon.damage)

    _add_muzzle_flash()
    _add_recoil()
    AlertnessManager.add_alert(owner.global_position, 3.5)
    _rotate_weapon_to_aim()

func _swing_sword() -> void :
    var from = _get_weapon_fire_position()
    var forward = - pivot.global_transform.basis.z.normalized()
    var right = pivot.global_transform.basis.x
    var range = recorded_weapon.range
    var shape = BoxShape3D.new()
    shape.size = Vector3(range * 1.8, range * 0.5, range)
    var space = owner.get_world_3d().direct_space_state
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.collision_mask = 2
    var shape_pos = from + forward * range * 0.9 + right * -0.6
    params.transform = Transform3D(Basis(), shape_pos)
    var hits = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider.is_in_group("player") and collider.has_method("take_damage"):
            collider.take_damage(recorded_weapon.damage)
    AlertnessManager.add_alert(owner.global_position, 1.5)
    _play_swing_animation()
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.attack_cooldown = 0.8

func _swing_vorpal() -> void :
    var from = _get_weapon_fire_position()
    var forward = - pivot.global_transform.basis.z.normalized()
    var right = pivot.global_transform.basis.x
    var range = recorded_weapon.range
    var shape = BoxShape3D.new()
    shape.size = Vector3(range * 1.8, range * 0.5, range)
    var space = owner.get_world_3d().direct_space_state
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.collision_mask = 2
    var shape_pos = from + forward * range * 0.9 + right * -0.6
    params.transform = Transform3D(Basis(), shape_pos)
    var hits = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider.is_in_group("player") and collider.has_method("take_damage"):
            if randi_range(0, 100) <= 15:
                collider.take_damage(recorded_weapon.damage + 60)
            else:
                collider.take_damage(recorded_weapon.damage)
    AlertnessManager.add_alert(owner.global_position, 1.5)
    _play_swing_animation()
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.attack_cooldown = 0.8

func _swing_scythe() -> void :
    var from = _get_weapon_fire_position()
    var forward = - pivot.global_transform.basis.z.normalized()
    var right = pivot.global_transform.basis.x
    var range = recorded_weapon.range
    var shape = BoxShape3D.new()
    shape.size = Vector3(range * 1.8, range * 0.5, range)
    var space = owner.get_world_3d().direct_space_state
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.collision_mask = 2
    var shape_pos = from + forward * range * 0.9 + right * -0.6
    params.transform = Transform3D(Basis(), shape_pos)
    var hits = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider.is_in_group("player") and collider.has_method("take_damage"):
            collider.take_damage(recorded_weapon.damage)
    AlertnessManager.add_alert(owner.global_position, 1.5)
    _play_swing_animation()

func _throw_projectile() -> void :
    if _is_throwing:
        return
    _is_throwing = true

    var projectile = recorded_weapon.model_scene.instantiate()
    get_tree().current_scene.add_child(projectile)
    var start_pos = _get_weapon_fire_position()
    projectile.global_position = start_pos
    var aim_point = _get_aim_point()
    var forward = (aim_point - start_pos).normalized()
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
        var space = owner.get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.new()
        query.from = projectile.global_position
        query.to = projectile.global_position + velocity * time_step
        query.collision_mask = 4294967295
        query.exclude = [owner]
        var result = space.intersect_ray(query)
        if result:
            projectile.global_position = result.position
            _explode(projectile.global_position, recorded_weapon.damage, explosion_radius)
            projectile.queue_free()
            hit = true
            break
        projectile.global_position += velocity * time_step
        if projectile.global_position.distance_to(start_pos) > recorded_weapon.range:
            _explode(projectile.global_position, recorded_weapon.damage, explosion_radius)
            projectile.queue_free()
            hit = true
            break
    if not hit:
        _explode(projectile.global_position, recorded_weapon.damage, explosion_radius)
        projectile.queue_free()

    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.attack_cooldown = 1.0
    _rotate_weapon_to_aim()
    _is_throwing = false
    transition.emit("IdleAttackState")

func _throw_smoke() -> void :
    if _is_throwing:
        return
    _is_throwing = true

    var projectile = recorded_weapon.model_scene.instantiate()
    get_tree().current_scene.add_child(projectile)
    var start_pos = _get_weapon_fire_position()
    projectile.global_position = start_pos
    var aim_point = _get_aim_point()
    var forward = (aim_point - start_pos).normalized()
    var up = Vector3.UP
    var throw_force = 20.0
    var vertical_force = 12.0
    var velocity = forward * throw_force + up * vertical_force
    var gravity = 25.0
    var time_step = 0.016
    var max_time = 20.0
    var elapsed = 0.0
    while elapsed < max_time:
        await get_tree().create_timer(time_step).timeout
        elapsed += time_step
        velocity.y -= gravity * time_step
        var space = owner.get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.new()
        query.from = projectile.global_position
        query.to = projectile.global_position + velocity * time_step
        query.collision_mask = 4294967295
        query.exclude = [owner]
        var result = space.intersect_ray(query)
        if result:
            projectile.global_position = result.position
            _create_smoke_cloud(projectile.global_position)
            projectile.queue_free()
            break
        projectile.global_position += velocity * time_step
        if projectile.global_position.distance_to(start_pos) > recorded_weapon.range:
            _create_smoke_cloud(projectile.global_position)
            projectile.queue_free()
            break
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.attack_cooldown = 1.0
    _rotate_weapon_to_aim()
    _is_throwing = false
    transition.emit("IdleAttackState")

func _throw_stun_grenade() -> void :
    if _is_throwing:
        return
    _is_throwing = true

    var projectile = recorded_weapon.model_scene.instantiate()
    get_tree().current_scene.add_child(projectile)
    var start_pos = _get_weapon_fire_position()
    projectile.global_position = start_pos
    var aim_point = _get_aim_point()
    var forward = (aim_point - start_pos).normalized()
    var up = Vector3.UP
    var throw_force = 20.0
    var vertical_force = 12.0
    var velocity = forward * throw_force + up * vertical_force
    var gravity = 25.0
    var time_step = 0.016
    var max_time = 20.0
    var elapsed = 0.0
    while elapsed < max_time:
        await get_tree().create_timer(time_step).timeout
        elapsed += time_step
        velocity.y -= gravity * time_step
        var space = owner.get_world_3d().direct_space_state
        var query = PhysicsRayQueryParameters3D.new()
        query.from = projectile.global_position
        query.to = projectile.global_position + velocity * time_step
        query.collision_mask = 4294967295
        query.exclude = [owner]
        var result = space.intersect_ray(query)
        if result:
            projectile.global_position = result.position
            _stun_explode(projectile.global_position)
            projectile.queue_free()
            break
        projectile.global_position += velocity * time_step
        if projectile.global_position.distance_to(start_pos) > recorded_weapon.range:
            _stun_explode(projectile.global_position)
            projectile.queue_free()
            break
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.attack_cooldown = 1.0
    _rotate_weapon_to_aim()
    _is_throwing = false
    transition.emit("IdleAttackState")

func _throw_hammer() -> void :
    if _is_throwing:
        return
    _is_throwing = true

    var hammer = recorded_weapon.model_scene.instantiate()
    get_tree().current_scene.add_child(hammer)
    var area = Area3D.new()
    var collision_shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = 0.5
    collision_shape.shape = sphere_shape
    area.add_child(collision_shape)
    hammer.add_child(area)
    var start_pos = _get_weapon_fire_position()
    hammer.global_position = start_pos
    var aim_point = _get_aim_point()
    var dir = (aim_point - start_pos).normalized()
    var speed = 30.0
    var return_speed = 20.0
    var range = recorded_weapon.range
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
            var space = owner.get_world_3d().direct_space_state
            var params = PhysicsShapeQueryParameters3D.new()
            params.shape = sphere_shape
            params.transform = Transform3D(Basis(), new_pos)
            params.collision_mask = 4294967295
            params.exclude = [owner, hammer]
            var results = space.intersect_shape(params)
            var wall_hit = false
            for result in results:
                var collider = result.collider
                if collider.is_in_group("player") and collider.has_method("take_damage"):
                    if not enemies_hit_outbound.has(collider):
                        collider.take_damage(recorded_weapon.damage)
                        enemies_hit_outbound[collider] = true
                else:
                    wall_hit = true
            hammer.global_position = new_pos
            AlertnessManager.add_alert(new_pos, 1.5)
            if wall_hit or hammer.global_position.distance_to(start_pos) > range:
                outbound = false
        else:
            var to_player = PLAYER.global_position - hammer.global_position
            var move_dir = to_player.normalized() if to_player.length() > 0 else Vector3.ZERO
            var new_pos = hammer.global_position + move_dir * return_speed * time_step
            var space = owner.get_world_3d().direct_space_state
            var params = PhysicsShapeQueryParameters3D.new()
            params.shape = sphere_shape
            params.transform = Transform3D(Basis(), new_pos)
            params.collision_mask = 4294967295
            params.exclude = [owner, hammer]
            var results = space.intersect_shape(params)
            for result in results:
                var collider = result.collider
                if collider.is_in_group("player") and collider.has_method("take_damage"):
                    if not enemies_hit_inbound.has(collider):
                        collider.take_damage(recorded_weapon.damage)
                        enemies_hit_inbound[collider] = true
            hammer.global_position = new_pos
            AlertnessManager.add_alert(new_pos, 1.5)
            var pickup_radius = 2.0
            if hammer.global_position.distance_to(PLAYER.global_position) <= pickup_radius:
                hammer.queue_free()
                break
    if hammer and is_instance_valid(hammer):
        hammer.queue_free()
    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.attack_cooldown = 1.0
    _rotate_weapon_to_aim()
    _is_throwing = false
    transition.emit("IdleAttackState")

func _throw_spear() -> void :
    if _is_throwing_spear:
        return
    _is_throwing_spear = true

    var spear = recorded_weapon.model_scene.instantiate()
    get_tree().current_scene.add_child(spear)

    var area = Area3D.new()
    var collision_shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = 0.5
    collision_shape.shape = sphere_shape
    area.add_child(collision_shape)
    spear.add_child(area)

    var start_pos = _get_weapon_fire_position()
    spear.global_position = start_pos
    var aim_point = _get_aim_point()
    var dir = (aim_point - start_pos).normalized()
    var speed = 30.0
    var return_speed = 20.0
    var range = recorded_weapon.range
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
            var space = owner.get_world_3d().direct_space_state

            var homing_params = PhysicsShapeQueryParameters3D.new()
            var homing_shape = SphereShape3D.new()
            homing_shape.radius = homing_radius
            homing_params.shape = homing_shape
            homing_params.transform = Transform3D(Basis(), spear.global_position)
            homing_params.collision_mask = 2
            homing_params.exclude = [owner, spear]
            var nearby = space.intersect_shape(homing_params)

            if nearby.size() > 0:
                var closest = null
                var closest_dist = INF
                for hit in nearby:
                    var target = hit.collider
                    if target and target.is_in_group("player"):
                        var dist = spear.global_position.distance_to(target.global_position)
                        if dist < closest_dist:
                            closest_dist = dist
                            closest = target
                if closest:
                    var to_target = (closest.global_position - spear.global_position).normalized()
                    var blend = 0.5
                    var new_dir = (dir * (1 - blend) + to_target * blend).normalized()
                    dir = new_dir

            var new_pos = spear.global_position + dir * speed * time_step

            var ray_params = PhysicsRayQueryParameters3D.new()
            ray_params.from = spear.global_position
            ray_params.to = new_pos
            ray_params.collision_mask = 4294967295
            ray_params.exclude = [owner, spear]
            var ray_result = space.intersect_ray(ray_params)

            var wall_hit = false
            if ray_result:
                var collider = ray_result.collider
                if not collider.is_in_group("player"):
                    wall_hit = true
                    new_pos = ray_result.position
                    dir = Vector3.ZERO

            var damage_params = PhysicsShapeQueryParameters3D.new()
            damage_params.shape = sphere_shape
            damage_params.transform = Transform3D(Basis(), new_pos)
            damage_params.collision_mask = 2
            damage_params.exclude = [owner, spear]
            var damage_results = space.intersect_shape(damage_params)

            for result in damage_results:
                var collider = result.collider
                if collider.is_in_group("player") and collider.has_method("take_damage"):
                    if not enemies_hit_outbound.has(collider):
                        collider.take_damage(recorded_weapon.damage)
                        enemies_hit_outbound[collider] = true

            spear.global_position = new_pos
            AlertnessManager.add_alert(new_pos, 1.5)

            if dir.length_squared() > 0.001:
                spear.look_at(spear.global_position + dir, Vector3.UP)

            if wall_hit or spear.global_position.distance_to(start_pos) > range:
                outbound = false

        else:
            var to_owner = owner.global_position - spear.global_position
            var move_dir = to_owner.normalized() if to_owner.length() > 0 else Vector3.ZERO
            var new_pos = spear.global_position + move_dir * return_speed * time_step

            var space = owner.get_world_3d().direct_space_state
            var params = PhysicsShapeQueryParameters3D.new()
            params.shape = sphere_shape
            params.transform = Transform3D(Basis(), new_pos)
            params.collision_mask = 2
            params.exclude = [owner, spear]
            var results = space.intersect_shape(params)

            for result in results:
                var collider = result.collider
                if collider.is_in_group("player") and collider.has_method("take_damage"):
                    if not enemies_hit_inbound.has(collider):
                        collider.take_damage(recorded_weapon.damage)
                        enemies_hit_inbound[collider] = true

            spear.global_position = new_pos
            AlertnessManager.add_alert(new_pos, 1.5)

            if move_dir.length_squared() > 0.001:
                spear.look_at(spear.global_position + move_dir, Vector3.UP)

            var return_radius = 2.0
            if spear.global_position.distance_to(owner.global_position) <= return_radius:
                spear.queue_free()
                break

    if spear and is_instance_valid(spear):
        spear.queue_free()

    var idle_state = get_parent().get_node("IdleAttackState") as PhaseThreeIdleCrucibleCoreAttackState
    if idle_state:
        idle_state.attack_cooldown = 1.0
    _rotate_weapon_to_aim()
    _is_throwing_spear = false
    transition.emit("IdleAttackState")

func _get_weapon_fire_position() -> Vector3:
    if boss.weapon_model_instance:
        return boss.weapon_model_instance.global_position
    return pivot.global_position + Vector3(0.311, 1.572, -0.95)

func _create_bullet_hole(hit: Dictionary) -> void :
    pass

func _add_muzzle_flash() -> void :
    pass

func _add_recoil() -> void :
    pass

func _play_swing_animation() -> void :
    if recorded_weapon.type == 200:
        animation_player.play("Punch_Cross")
    elif recorded_weapon.type == 201:
        animation_player.play("Punch_Cross")
    boss.block_animation_for(0.5)

func _explode(position: Vector3, damage: float, radius: float) -> void :
    var sphere = MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = radius
    sphere.mesh.height = radius * 2
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.YELLOW
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.3
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    sphere.material_override = material
    get_tree().current_scene.add_child(sphere)
    sphere.global_position = position
    var light = OmniLight3D.new()
    light.omni_range = radius * 2
    light.light_color = Color.YELLOW
    light.light_energy = 20
    get_tree().current_scene.add_child(light)
    light.global_position = position
    var tween = create_tween()
    tween.parallel().tween_property(sphere, "scale", Vector3.ZERO, 0.5)
    tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)
    tween.tween_callback(sphere.queue_free)
    tween.tween_callback(light.queue_free)

    var space = owner.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = radius
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), position)
    params.collision_mask = 2
    var hits = space.intersect_shape(params)
    for hit in hits:
        var collider = hit.collider
        if collider.is_in_group("player") and collider.has_method("take_damage"):
            collider.take_damage(damage)

func _create_smoke_cloud(position: Vector3) -> void :
    var smoke_area = Area3D.new()
    smoke_area.name = "SmokeCloud"
    smoke_area.collision_mask = 2
    smoke_area.collision_layer = 0
    var mesh = MeshInstance3D.new()
    var sphere = SphereMesh.new()
    sphere.radius = 5
    sphere.height = 5 * 2
    mesh.mesh = sphere
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0, 0, 0, 0.8)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = material
    smoke_area.add_child(mesh)
    var shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = recorded_weapon.range
    shape.shape = sphere_shape
    smoke_area.add_child(shape)
    get_tree().current_scene.add_child(smoke_area)
    smoke_area.global_position = position
    AlertnessManager.add_alert(position, 0.4)
    smoke_area.body_entered.connect( func(body):
        if body.is_in_group("enemies"):
            var enemy_state_machine = body.get_node_or_null("EnemyStateMachine") as StateMachine
            if enemy_state_machine:
                enemy_state_machine.get_node("IdleEnemyState").is_in_smoke = true
                enemy_state_machine.get_node("WalkingEnemyState").is_in_smoke = true
                enemy_state_machine.get_node("RunningEnemyState").is_in_smoke = true
    )
    smoke_area.body_exited.connect( func(body):
        if body.is_in_group("enemies"):
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

func _stun_explode(position: Vector3) -> void :
    var radius = recorded_weapon.range
    var sphere = MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = radius
    sphere.mesh.height = radius * 2
    var material = StandardMaterial3D.new()
    material.albedo_color = Color.YELLOW
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    material.albedo_color.a = 0.3
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    sphere.material_override = material
    get_tree().current_scene.add_child(sphere)
    sphere.global_position = position
    var light = OmniLight3D.new()
    light.omni_range = radius * 2
    light.light_color = Color.YELLOW
    light.light_energy = 20
    get_tree().current_scene.add_child(light)
    light.global_position = position
    var tween = create_tween()
    tween.parallel().tween_property(sphere, "scale", Vector3.ZERO, 0.5)
    tween.parallel().tween_property(light, "light_energy", 0.0, 0.5)
    tween.tween_callback(sphere.queue_free)
    tween.tween_callback(light.queue_free)

    var space = owner.get_world_3d().direct_space_state
    var shape = SphereShape3D.new()
    shape.radius = radius
    var params = PhysicsShapeQueryParameters3D.new()
    params.shape = shape
    params.transform = Transform3D(Basis(), position)
    params.collision_mask = 2
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
                enemy_state_machine.CURRENT_STATE = idle_enemy_state
                attack_state_machine.CURRENT_STATE = idle_attack_state
            )
            var remove_timer = Timer.new()
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
