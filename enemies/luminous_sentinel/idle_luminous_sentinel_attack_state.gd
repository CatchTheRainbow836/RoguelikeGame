extends DefaultEnemyAttackState
class_name IdleLuminousSentinelAttackState

var attack_range: float
var attack_cooldown: float = 3.0
var cooldown_timer: float = 0.0
var sentinel: LuminousSentinel

func _ready() -> void :
    super._ready()
    await owner.ready
    sentinel = owner as LuminousSentinel
    if sentinel:
        attack_range = sentinel.attack_range
        attack_cooldown = sentinel.attack_cooldown

func enter() -> void :
    pass

func physics_update(delta: float) -> void :
    if cooldown_timer > 0:
        cooldown_timer -= delta
        return

    if not PLAYER:
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist <= attack_range and running_enemy_state.can_see_player():
        transition.emit("AttackingAttackState")

func start_cooldown() -> void :
    cooldown_timer = attack_cooldown
