extends DefaultEnemyAttackState
class_name ShieldingGearWardenAttackState

var attack_range: float
var _exit_timer: Timer

func _ready() -> void :
    super._ready()
    await owner.ready
    var warden = owner as GearWarden
    if warden:
        attack_range = warden.attack_range

func enter() -> void :
    super.enter()
    if _exit_timer and _exit_timer.is_inside_tree():
        _exit_timer.queue_free()

func exit() -> void :
    if _exit_timer:
        _exit_timer.queue_free()

func physics_update(delta: float) -> void :
    if not PLAYER:
        transition.emit("IdleAttackState")
        return

    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist <= attack_range and running_enemy_state.can_see_player():
        transition.emit("AttackingAttackState")
    else:
        if running_enemy_state and running_enemy_state.alert_timer <= 0:
            transition.emit("IdleAttackState")
