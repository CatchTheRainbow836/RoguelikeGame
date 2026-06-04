extends DefaultEnemyAttackState
class_name AttackingThornedGardenerAttackState

var attack_timer: Timer
var attack_damage: float
var attack_range: float
var attack_cooldown: float
var spread: float
var pivot: Node3D
var gardener: ThornedGardener
var _last_attack_time: float = 0.0

var active_spears: Array = []

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    gardener = owner as ThornedGardener
    if gardener:
        attack_damage = gardener.attack_damage
        attack_range = gardener.attack_range
        attack_cooldown = gardener.attack_cooldown
        spread = gardener.spread
        pivot = owner.get_node("Pivot")

func enter() -> void :
    super.enter()
    if attack_timer and attack_timer.is_inside_tree():
        attack_timer.queue_free()
    attack_timer = Timer.new()
    attack_timer.one_shot = false
    attack_timer.wait_time = attack_cooldown
    attack_timer.timeout.connect(_on_attack_timer_timeout)
    owner.add_child(attack_timer)
    attack_timer.start()

    perform_ranged_attack()

func exit() -> void :
    if attack_timer:
        attack_timer.stop()
        attack_timer.queue_free()
    for spear_data in active_spears:
        if is_instance_valid(spear_data.spear):
            spear_data.spear.queue_free()
    active_spears.clear()

func physics_update(delta: float) -> void :
    if not PLAYER:
        transition.emit("IdleAttackState")
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist > attack_range or not running_enemy_state.can_see_player():
        transition.emit("IdleAttackState")

    var space_state = owner.get_world_3d().direct_space_state

    for i in range(active_spears.size() - 1, -1, -1):
        var spear_data = active_spears[i]
        if not is_instance_valid(spear_data.spear):
            active_spears.remove_at(i)
            continue

        var prev_pos = spear_data.prev_pos
        var new_pos = spear_data.spear.global_position + spear_data.direction * spear_data.speed * delta

        var query = PhysicsRayQueryParameters3D.new()
        query.from = prev_pos
        query.to = new_pos
        query.exclude = [owner, pivot]
        query.collision_mask = 4294967295

        var result = space_state.intersect_ray(query)

        if result:
            var collider = result.collider
            if collider == PLAYER or (collider is Node and collider.is_in_group("player")):
                PLAYER.take_damage(attack_damage)
            spear_data.spear.queue_free()
            active_spears.remove_at(i)
            continue

        spear_data.spear.global_position = new_pos
        spear_data.prev_pos = new_pos

        spear_data.lifetime -= delta
        if spear_data.lifetime <= 0.0:
            spear_data.spear.queue_free()
            active_spears.remove_at(i)

func _on_attack_timer_timeout() -> void :
    perform_ranged_attack()

func perform_ranged_attack() -> void :
    var current_time = Time.get_ticks_msec() / 1000.0
    if current_time - _last_attack_time < attack_cooldown:
        return

    if not is_instance_valid(pivot) or not pivot.is_inside_tree():
        return
    if not running_enemy_state.PLAYER:
        return

    _last_attack_time = current_time

    var player = running_enemy_state.PLAYER
    var from: Vector3 = pivot.global_transform.origin
    var to_player = player.global_position - from
    var distance = to_player.length()
    if distance > attack_range:
        return

    var dir: Vector3 = to_player.normalized()
    var player_target_pos = player.global_position + Vector3(0, 1.0, 0)
    var spread_distance = distance * spread
    var inaccurate_target = player_target_pos + Vector3(
        randf_range( - spread_distance, spread_distance), 
        randf_range( - spread_distance * 0.5, spread_distance * 0.5), 
        randf_range( - spread_distance, spread_distance)
    )
    var final_dir = (inaccurate_target - from).normalized()

    var spear = Area3D.new()
    spear.name = "SpearProjectile"
    spear.collision_mask = 4294967295
    spear.collision_layer = 0

    var collision_shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = 0.3
    collision_shape.shape = sphere_shape
    spear.add_child(collision_shape)

    var mesh_instance = MeshInstance3D.new()
    var cylinder_mesh = CylinderMesh.new()
    cylinder_mesh.top_radius = 0.0
    cylinder_mesh.bottom_radius = 0.25
    cylinder_mesh.height = 0.5
    mesh_instance.mesh = cylinder_mesh

    var quat = Quaternion(Vector3.UP, final_dir.normalized())
    mesh_instance.rotation = quat.get_euler()

    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.6, 0.4, 0.1)
    mesh_instance.material_override = material
    spear.add_child(mesh_instance)

    var spawn_offset = final_dir.normalized() * 1.0
    owner.get_parent().add_child(spear)

    spear.global_position = pivot.global_position + spawn_offset
    spear.global_position.y += 0.5

    var hit_registered = false
    spear.body_entered.connect( func(body):
        if hit_registered:
            return
        if body == player or (body is Node and body.is_in_group("player")):
            player.take_damage(attack_damage)
            hit_registered = true
            spear.queue_free()
        else:
            spear.queue_free()
    )

    var spear_speed = 25.0
    var lifetime = 3.0
    active_spears.append({
        "spear": spear, 
        "direction": final_dir, 
        "speed": spear_speed, 
        "lifetime": lifetime, 
        "prev_pos": spear.global_position
    })

    var anim_length = animation_player.get_animation("Spell_Simple_Shoot").length if animation_player.has_animation("Throw_Spear") else 0.5
    animation_player.play("Spell_Simple_Shoot")
    gardener.block_animation_for(anim_length)
