extends FurnaceColossusAttackState
class_name PhaseOneAttackingFurnaceColossusAttackState

var attack_timer: Timer
var stomp_damage: float
var attack_cooldown: float
var attack_range: float
var pivot: Node3D
var is_active: bool = false
var running_state: PhaseOneRunningFurnaceColossusState
var colossus: FurnaceColossus
@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer


func _ready() -> void :
    super._ready()
    await owner.ready
    colossus = owner as FurnaceColossus
    if colossus:
        stomp_damage = colossus.stomp_damage
        attack_cooldown = colossus.attack_cooldown
        attack_range = colossus.attack_range
        pivot = owner.get_node("Pivot")
func enter() -> void :
    super.enter()
    is_active = true
    if attack_timer and attack_timer.is_inside_tree():
        attack_timer.queue_free()
    attack_timer = Timer.new()
    attack_timer.one_shot = true
    attack_timer.wait_time = owner.attack_cooldown
    attack_timer.timeout.connect(_on_attack_timer_timeout)
    owner.add_child(attack_timer)
    attack_timer.start()
    _on_attack_timer_timeout()

func exit() -> void :
    is_active = false
    if attack_timer:
        attack_timer.stop()
        attack_timer.queue_free()
        attack_timer = null

    animation_player.stop()

func physics_update(delta: float) -> void :
    if not PLAYER:
        transition.emit("IdleAttackState")
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist > attack_range:
        transition.emit("IdleAttackState")

func _on_attack_timer_timeout() -> void :
    if not is_active:
        return
    if randf() < 0.25:
        transition.emit("SweepingAttackState")
    else:
        perform_stomp()
        colossus.block_animation_for(attack_cooldown)
        if is_active and attack_timer:
            attack_timer.start()

func _on_can_attack(active: bool) -> void :
    if not is_active:
        return
    if not active:
        transition.emit("IdleAttackState")

func perform_stomp() -> void :
    if not is_active:
        return
    if not is_instance_valid(owner) or not owner.is_inside_tree():
        return
    if not is_instance_valid(pivot) or not pivot.is_inside_tree():
        return

    var hitbox = Area3D.new()
    hitbox.name = "StompHitbox"
    hitbox.collision_mask = 2
    hitbox.collision_layer = 0

    var shape = CollisionShape3D.new()
    shape.shape = SphereShape3D.new()
    shape.shape.radius = 1.0
    hitbox.add_child(shape)

    var forward = - pivot.global_transform.basis.z.normalized()


    var damaged_once = false
    hitbox.body_entered.connect( func(body):
        if damaged_once:
            return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(stomp_damage)
            damaged_once = true
    )

    owner.add_child(hitbox)
    hitbox.global_position = pivot.global_position + forward * 2.0

    var remove_timer = Timer.new()
    remove_timer.one_shot = true
    remove_timer.wait_time = 0.2
    remove_timer.timeout.connect( func():
        if is_instance_valid(hitbox):
            hitbox.queue_free()
    )
    hitbox.add_child(remove_timer)
    remove_timer.start()

    animation_player.get_animation("Punch_Cross").loop_mode = Animation.LOOP_NONE
    animation_player.play("Punch_Cross")
