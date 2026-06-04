extends DefaultEnemyAttackState
class_name IdleBloomHeraldAttackState

var attack_range: float
var attack_cooldown: float
var herald: BloomHerald

func _ready() -> void :
    super._ready()
    await owner.ready
    herald = owner as BloomHerald
    if herald:
        attack_range = herald.attack_range
        attack_cooldown = herald.attack_cooldown

func physics_update(delta: float) -> void :
    if not PLAYER:
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    var current_time = Time.get_ticks_msec() / 1000.0
    if dist <= attack_range and running_enemy_state.can_see_player() and current_time - herald.last_attack_time >= attack_cooldown:
        print("bloom herald transitioned to attacking, ready to attack")
        transition.emit("AttackingAttackState")

func enter() -> void :
    print("bloom herald entered idle state")

func exit() -> void :
    print("bloom herald exited idle state")
