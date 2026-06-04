extends DefaultEnemyAttackState
class_name IdleGutterRatAttackState

var attack_range: float

func _ready() -> void :
    super._ready()
    await owner.ready
    var rat = owner as GutterRat
    if rat:
        attack_range = rat.attack_range
    await get_tree().process_frame

func physics_update(delta: float) -> void :
    if not PLAYER:
        return
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist <= attack_range and running_enemy_state.can_see_player():
        transition.emit("AttackingAttackState")
