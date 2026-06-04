extends ArchonAttackState
class_name PhaseThreeMeleeArchonAttackState

var boss: ArchonOfBlinding
var melee_damage: float
var pivot: Node3D

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as ArchonOfBlinding
    if boss:
        melee_damage = boss.phase3_melee_damage
        pivot = owner.get_node("Pivot")

func enter() -> void :
    super.enter()
    perform_melee_attack()
    await get_tree().create_timer(0.5).timeout
    transition.emit("IdleAttackState")

func perform_melee_attack() -> void :
    var hitbox = Area3D.new()
    hitbox.name = "MeleeHitbox"
    hitbox.collision_mask = 2
    hitbox.collision_layer = 0
    var shape = CollisionShape3D.new()
    shape.shape = SphereShape3D.new()
    shape.shape.radius = 1.0
    hitbox.add_child(shape)
    var damaged_once = false
    hitbox.body_entered.connect( func(body):
        if damaged_once: return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(melee_damage)
            damaged_once = true
    )
    owner.add_child(hitbox)
    var forward = - pivot.global_transform.basis.z.normalized()
    hitbox.global_position = pivot.global_position + forward * 1.5
    animation_player.play("Punch_Cross")
    boss.block_animation_for(0.5)
    var remove_timer = Timer.new()
    remove_timer.one_shot = true
    remove_timer.wait_time = 0.2
    remove_timer.timeout.connect( func():
        if is_instance_valid(hitbox):
            hitbox.queue_free()
    )
    hitbox.add_child(remove_timer)
    remove_timer.start()
