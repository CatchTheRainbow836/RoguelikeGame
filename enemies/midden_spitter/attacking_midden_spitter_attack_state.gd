extends DefaultEnemyAttackState
class_name AttackingMiddenSpitterAttackState

var attack_timer: Timer
var attack_damage: float
var attack_range: float
var attack_cooldown: float
var spread: float
var pivot: Node3D
var spitter: MiddenSpitter
var projectile_speed: float
var aoe_radius: float
var aoe_duration: float
var _last_attack_time: float = 0.0

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    spitter = owner as MiddenSpitter
    if spitter:
        attack_damage = spitter.attack_damage
        attack_range = spitter.attack_range
        attack_cooldown = spitter.attack_cooldown
        spread = spitter.spread
        projectile_speed = spitter.projectile_speed
        aoe_radius = spitter.aoe_radius
        aoe_duration = spitter.aoe_duration
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

    _fire_projectile()

func exit() -> void :
    if attack_timer:
        attack_timer.stop()
        attack_timer.queue_free()

func physics_update(delta: float) -> void :
    if not PLAYER:
        transition.emit("IdleAttackState")
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist > attack_range or not running_enemy_state.can_see_player():
        transition.emit("IdleAttackState")

func _on_attack_timer_timeout() -> void :
    _fire_projectile()

func _fire_projectile() -> void :
    var current_time = Time.get_ticks_msec() / 1000.0
    if current_time - _last_attack_time < attack_cooldown:
        return

    if not is_instance_valid(pivot) or not pivot.is_inside_tree():
        return
    if not running_enemy_state.PLAYER:
        return

    _last_attack_time = current_time

    var player = running_enemy_state.PLAYER
    var from = pivot.global_transform.origin
    var to_player = player.global_position - from
    var distance = to_player.length()
    if distance > attack_range:
        return

    var dir = to_player.normalized()
    var player_target_pos = player.global_position + Vector3(0, 1.0, 0)
    var spread_distance = distance * spread
    var inaccurate_target = player_target_pos + Vector3(
        randf_range( - spread_distance, spread_distance), 
        randf_range( - spread_distance * 0.5, spread_distance * 0.5), 
        randf_range( - spread_distance, spread_distance)
    )
    var final_dir = (inaccurate_target - from).normalized()

    var projectile = MeshInstance3D.new()
    projectile.mesh = SphereMesh.new()
    projectile.mesh.radius = 0.3
    projectile.mesh.height = 0.6
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.8, 0.2, 1.0)
    material.metallic = 0.0
    material.roughness = 0.4
    projectile.material_override = material
    owner.get_parent().add_child(projectile)
    projectile.global_position = from + final_dir * 0.5

    var area = Area3D.new()
    area.collision_mask = 4294967295
    area.collision_layer = 0
    var collision_shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    sphere_shape.radius = 0.3
    collision_shape.shape = sphere_shape
    area.add_child(collision_shape)
    projectile.add_child(area)

    var velocity = final_dir * projectile_speed
    var hit_detected = false

    var update_timer = Timer.new()
    update_timer.wait_time = 0.016
    update_timer.one_shot = false
    update_timer.timeout.connect( func():
        if not is_instance_valid(projectile):
            update_timer.queue_free()
            return
        if hit_detected:
            return
        projectile.global_position += velocity * update_timer.wait_time
        var space = owner.get_world_3d().direct_space_state
        var params = PhysicsRayQueryParameters3D.new()
        params.from = projectile.global_position - velocity * update_timer.wait_time
        params.to = projectile.global_position
        params.exclude = [owner, pivot, projectile]
        params.collision_mask = 4294967295
        var result = space.intersect_ray(params)
        if result:
            hit_detected = true
            var hit_point = result.position
            var ground_pos = Vector3(hit_point.x, 0, hit_point.z)
            _create_aoe_circle(ground_pos)
            projectile.queue_free()
            update_timer.queue_free()
        if projectile.global_position.distance_to(from) > 100.0:
            projectile.queue_free()
            update_timer.queue_free()
    )
    owner.add_child(update_timer)
    update_timer.start()

    var anim_length = animation_player.get_animation("OverhandThrow").length
    animation_player.play("OverhandThrow")
    spitter.block_animation_for(anim_length)

func _create_aoe_circle(center: Vector3) -> void :
    var circle = MeshInstance3D.new()
    circle.mesh = CylinderMesh.new()
    circle.mesh.top_radius = aoe_radius
    circle.mesh.bottom_radius = aoe_radius
    circle.mesh.height = 0.1
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.2, 0.8, 0.2, 0.6)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    circle.material_override = material
    owner.get_parent().add_child(circle)
    circle.global_position = center + Vector3(0, 0.05, 0)

    var area = Area3D.new()
    area.collision_mask = 2
    area.collision_layer = 0
    var shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = aoe_radius
    cylinder_shape.height = 0.2
    shape.shape = cylinder_shape
    area.add_child(shape)
    circle.add_child(area)
    area.global_position = Vector3.ZERO

    var damaged = false
    area.body_entered.connect( func(body):
        if damaged:
            return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(attack_damage)
            damaged = true
    )

    var tween = create_tween()
    tween.tween_property(material, "albedo_color:a", 0.0, aoe_duration)
    tween.parallel().tween_property(circle.mesh, "top_radius", 0.0, aoe_duration)
    tween.parallel().tween_property(circle.mesh, "bottom_radius", 0.0, aoe_duration)
    tween.tween_callback(circle.queue_free)
