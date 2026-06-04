extends EdenRemnantAttackState
class_name PhaseTwoIdleEdenRemnantAttackState

var attack_range: float
var splash_cooldown: float = 0.0
var boss: EdenRemnant
var attack_sm: StateMachine

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as EdenRemnant
    if boss:
        attack_range = boss.phase2_attack_range
    attack_sm = get_parent()

func physics_update(delta: float) -> void :
    if splash_cooldown > 0:
        splash_cooldown -= delta

    if not PLAYER:
        return

    var dist = owner.global_position.distance_to(PLAYER.global_position)

    if dist <= attack_range:
        transition.emit("AttackingAttackState")
    elif splash_cooldown <= 0.0:
        transition.emit("SplashAttackState")
