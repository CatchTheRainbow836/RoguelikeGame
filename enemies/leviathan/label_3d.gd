extends Label3D
@onready var leviathan_state_machine: StateMachine = $"../LeviathanStateMachine"
@onready var phase_one_state_machine: PhaseStateMachine = $"../LeviathanStateMachine/PhaseOneStateMachine"
@onready var phase_two_state_machine: PhaseStateMachine = $"../LeviathanStateMachine/PhaseTwoStateMachine"
@onready var phase_three_state_machine: PhaseStateMachine = $"../LeviathanStateMachine/PhaseThreeStateMachine"


func _process(delta: float) -> void :

	var current_state_machine
	match leviathan_state_machine.CURRENT_STATE:
		phase_one_state_machine:
			current_state_machine = phase_one_state_machine
		phase_two_state_machine:
			current_state_machine = phase_two_state_machine
		phase_three_state_machine:
			current_state_machine = phase_three_state_machine

	text = "Phase: " + leviathan_state_machine.CURRENT_STATE.name + "\n" + current_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + "\n" + current_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name + "\n" + "can see player: " + str(phase_one_state_machine.get_node("EnemyStateMachine").get_node("RunningEnemyState").can_see_player()) + "\n" + "alertness: " + str(LevelManager.get_alert_value(owner.global_position)) + "\n" + "Phase 1: " + phase_one_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + phase_one_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name + "\n" + "Phase 2: " + phase_two_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + phase_two_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name + "\n" + "Phase 3: " + phase_three_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + phase_three_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name
