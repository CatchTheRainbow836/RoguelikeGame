extends FurnaceColossusAttackState
class_name PhaseOneIdleFurnaceColossusAttackState

var running_state: PhaseOneRunningFurnaceColossusState
var attack_range

func _ready() -> void :
    super._ready()
    await owner.ready
    var colossus = owner as FurnaceColossus
    attack_range = colossus.attack_range


func _on_can_attack(active: bool) -> void :
    pass

func physics_update(delta: float) -> void :
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    var phase_sm = owner.top_state_machine.CURRENT_STATE
    if not phase_sm:
        return
    var running_state = phase_sm.get_node("EnemyStateMachine/RunningEnemyState")
    if dist <= attack_range and running_state and running_state.can_see_player():
        if randi_range(1, 3) < 2:
            transition.emit("SweepingAttackState")
        else:
            transition.emit("AttackingAttackState")
