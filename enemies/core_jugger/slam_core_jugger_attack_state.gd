extends DefaultEnemyAttackState
class_name SlamCoreJuggerAttackState

var attack_timer: Timer
var slam_damage: float
var stun_duration: float
var attack_cooldown: float
var attack_range: float
var pivot: Node3D
var jugger: CoreJugger
var _normal_chance: float = 0.25

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    jugger = owner as CoreJugger
    if jugger:
        slam_damage = jugger.slam_damage
        stun_duration = jugger.stun_duration
        attack_cooldown = jugger.attack_cooldown
        attack_range = jugger.attack_range
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
    _on_attack_timer_timeout()

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
    var should_normal = randf() < _normal_chance
    if should_normal:
        transition.emit("AttackingAttackState")
    else:
        perform_slam()

func perform_slam() -> void :
    if not is_instance_valid(owner) or not owner.is_inside_tree():
        return
    if not is_instance_valid(pivot) or not pivot.is_inside_tree():
        return
    if not running_enemy_state.can_see_player():
        return

    var hitbox = Area3D.new()
    hitbox.name = "SlamHitbox"
    hitbox.collision_mask = 2
    hitbox.collision_layer = 0

    var shape = CollisionShape3D.new()
    shape.shape = SphereShape3D.new()
    shape.shape.radius = 1.5
    hitbox.add_child(shape)

    var damaged_once = false
    hitbox.body_entered.connect( func(body):
        if damaged_once:
            return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(slam_damage)
            damaged_once = true
            if body.has_method("stun"):
                body.stun(stun_duration)
    )

    owner.add_child(hitbox)

    var forward = - pivot.global_transform.basis.z.normalized()
    hitbox.global_position = pivot.global_position + forward * 2.0

    var anim_length = animation_player.get_animation("OverhandThrow").length
    animation_player.get_animation("OverhandThrow").loop_mode = Animation.LOOP_NONE
    animation_player.play("OverhandThrow")
    jugger.block_animation_for(anim_length)

    var remove_timer = Timer.new()
    remove_timer.one_shot = true
    remove_timer.wait_time = 0.2
    remove_timer.timeout.connect( func():
        if is_instance_valid(hitbox):
            hitbox.queue_free()
    )
    hitbox.add_child(remove_timer)
    remove_timer.start()
