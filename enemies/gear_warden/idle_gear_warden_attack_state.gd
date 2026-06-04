extends DefaultEnemyAttackState
class_name IdleGearWardenAttackState

var attack_range: float

func _ready() -> void :
    super._ready()
    await owner.ready
    var warden = owner as GearWarden
    if warden:
        attack_range = warden.attack_range

func physics_update(delta: float) -> void :
    if not PLAYER:
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist <= attack_range and running_enemy_state.can_see_player():
        transition.emit("AttackingAttackState")
    else:
        if running_enemy_state and running_enemy_state.alert_timer > 0:
            transition.emit("ShieldingAttackState")
