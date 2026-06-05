extends FurnaceColossusAttackState
class_name PhaseTwoIdleFurnaceColossusAttackState

var running_state: PhaseTwoRunningFurnaceColossusState

func _ready() -> void :
	super._ready()
	await owner.ready
	var phase_sm = owner.top_state_machine.CURRENT_STATE
	if phase_sm:
		running_state = phase_sm.get_node("EnemyStateMachine/RunningEnemyState") as PhaseTwoRunningFurnaceColossusState
		if running_state:
			running_state.connect("can_attack", _on_can_attack)

func _on_can_attack(active: bool) -> void :
	pass
