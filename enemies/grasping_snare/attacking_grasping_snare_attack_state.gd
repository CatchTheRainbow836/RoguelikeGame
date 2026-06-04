extends DefaultEnemyAttackState
class_name AttackingGraspingSnareAttackState

var snare: GraspingSnare
var pull_speed: float
var damage_interval: float
var damage_per_tick: float
var close_distance: float
var rope_cylinder: MeshInstance3D
var rope_container: Node3D
var update_timer: Timer
var is_holding: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    snare = owner as GraspingSnare
    if snare:
        pull_speed = snare.pull_speed
        damage_interval = snare.damage_interval
        damage_per_tick = snare.damage_per_tick
        close_distance = snare.close_distance

func enter() -> void :
    super.enter()
    if snare.is_latched:
        transition.emit("IdleAttackState")
        return
    snare.is_latched = true
    var player = PLAYER
    if not player:
        transition.emit("IdleAttackState")
        return

    rope_container = Node3D.new()
    rope_container.name = "Rope"
    owner.get_parent().add_child(rope_container)
    rope_cylinder = MeshInstance3D.new()
    rope_cylinder.mesh = CylinderMesh.new()
    rope_cylinder.mesh.top_radius = 0.1
    rope_cylinder.mesh.bottom_radius = 0.1
    rope_cylinder.mesh.height = 0.1
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.5, 0.3, 0.1)
    rope_cylinder.material_override = material
    rope_container.add_child(rope_cylinder)

    player.global_position.x = owner.global_position.x
    player.global_position.z = owner.global_position.z

    var start_y = player.global_position.y
    var target_y = 2
    var tween = create_tween()
    tween.tween_property(player, "global_position:y", target_y, (target_y - start_y) / pull_speed)
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_LINEAR)
    snare.pull_tween = tween

    update_timer = Timer.new()
    update_timer.wait_time = 0.016
    update_timer.one_shot = false
    update_timer.timeout.connect(_update_rope_and_position)
    owner.add_child(update_timer)
    update_timer.start()

    await tween.finished
    update_timer.queue_free()

    is_holding = true

    snare.damage_timer = Timer.new()
    snare.damage_timer.wait_time = damage_interval
    snare.damage_timer.one_shot = false
    snare.damage_timer.timeout.connect(_deal_damage)
    owner.add_child(snare.damage_timer)
    snare.damage_timer.start()

    update_timer = Timer.new()
    update_timer.wait_time = 0.016
    update_timer.one_shot = false
    update_timer.timeout.connect(_update_rope_and_position)
    owner.add_child(update_timer)
    update_timer.start()

func exit() -> void :
    is_holding = false
    if update_timer and update_timer.is_inside_tree():
        update_timer.stop()
        update_timer.queue_free()

func _update_rope_and_position() -> void :
    if not is_instance_valid(rope_container) or not PLAYER:
        return
    var enemy_pos = owner.global_position
    PLAYER.global_position.x = enemy_pos.x
    PLAYER.global_position.z = enemy_pos.z

    if is_holding:
        PLAYER.global_position.y = 2.0

    var start = Vector3(enemy_pos.x, owner.global_position.y, enemy_pos.z)
    var end = PLAYER.global_position + Vector3(0, 2.0, 0)
    var distance = start.distance_to(end)
    rope_cylinder.mesh.height = distance
    var mid = (start + end) / 2
    rope_cylinder.global_position = mid
    var dir = (end - start).normalized()
    if dir.length_squared() > 0.001:
        var up_dir = Vector3.UP
        if abs(dir.dot(up_dir)) > 0.9999:
            up_dir = Vector3.RIGHT
        rope_cylinder.look_at(end, up_dir)

func _deal_damage() -> void :
    if not is_instance_valid(PLAYER):
        return
    PLAYER.take_damage(damage_per_tick)
