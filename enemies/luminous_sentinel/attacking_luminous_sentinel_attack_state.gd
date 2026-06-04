extends DefaultEnemyAttackState
class_name AttackingLuminousSentinelAttackState

@export var orb_scene: PackedScene

var sentinel: LuminousSentinel
var orb_count: int

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    sentinel = owner as LuminousSentinel
    if sentinel:
        orb_count = sentinel.orb_count

func enter() -> void :
    super.enter()
    _spawn_orbs()
    var idle_state = get_parent().get_node("IdleAttackState") as IdleLuminousSentinelAttackState
    if idle_state:
        idle_state.start_cooldown()
        await get_tree().process_frame
    transition.emit("IdleAttackState")

func _spawn_orbs() -> void :
    if not orb_scene:
        print("No orb scene assigned to Luminous Sentinel!")
        return
    for i in range(orb_count):
        var orb = orb_scene.instantiate()
        owner.get_parent().add_child(orb)
        var offset = Vector3(randf_range(-0.8, 0.8), randf_range(-0.5, 0.5), randf_range(-0.8, 0.8))
        orb.global_position = owner.global_position + offset
        orb.global_position.y = 1.0

    var anim_length = animation_player.get_animation("Spell_Simple_Shoot").length
    animation_player.play("Spell_Simple_Shoot")
    sentinel.block_animation_for(anim_length)
