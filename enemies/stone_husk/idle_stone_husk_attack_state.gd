extends DefaultEnemyAttackState
class_name IdleStoneHuskAttackState

var husk: StoneHusk
var attack_range: float

func _ready() -> void :
    super._ready()
    await owner.ready
    husk = owner as StoneHusk
    if husk:
        attack_range = husk.attack_range

func physics_update(delta: float) -> void :
    if not PLAYER:
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    var can_attack = dist <= attack_range and not husk.is_player_close and running_enemy_state.can_see_player()
    if can_attack:
        transition.emit("AttackingAttackState")
