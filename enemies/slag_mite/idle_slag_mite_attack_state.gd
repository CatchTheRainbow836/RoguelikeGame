extends DefaultEnemyAttackState
class_name IdleSlagMiteAttackState

var attack_range: float

func _ready() -> void :
    super._ready()
    await owner.ready
    var mite = owner as SlagMite
    if mite:
        attack_range = mite.attack_range
    await get_tree().process_frame

func physics_update(delta: float) -> void :
    if owner.is_dying:
        return
    if not PLAYER:
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist <= attack_range and running_enemy_state.can_see_player():
        transition.emit("AttackingAttackState")
