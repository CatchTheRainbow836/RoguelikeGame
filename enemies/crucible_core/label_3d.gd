extends Label3D

@onready var crucible_core_state_machine: StateMachine = $"../CrucibleCoreStateMachine"

@onready var phase_one_state_machine: PhaseStateMachine = $"../CrucibleCoreStateMachine/PhaseOneStateMachine"
@onready var phase_two_state_machine: PhaseStateMachine = $"../CrucibleCoreStateMachine/PhaseTwoStateMachine"
@onready var phase_three_state_machine: PhaseStateMachine = $"../CrucibleCoreStateMachine/PhaseThreeStateMachine"

var printed_once: bool = false

func _process(delta: float) -> void :

	var current_state_machine
	match crucible_core_state_machine.CURRENT_STATE:
		phase_one_state_machine:
			current_state_machine = phase_one_state_machine
		phase_two_state_machine:
			current_state_machine = phase_two_state_machine
		phase_three_state_machine:
			current_state_machine = phase_three_state_machine

	if !printed_once:
		print("current_stat_machine: ", current_state_machine)
		print("phase_one_state_machine: ", phase_one_state_machine)
		print("phase_two_state_machine: ", phase_two_state_machine)
		print("phase_three_state_machine: ", phase_three_state_machine)

		printed_once = true

	text = "Phase: " + crucible_core_state_machine.CURRENT_STATE.name + "\n" + current_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + "\n" + current_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name + "\n" + "can see player: " + str(phase_one_state_machine.get_node("EnemyStateMachine").get_node("RunningEnemyState").can_see_player()) + "\n" + "alertness: " + str(LevelManager.get_alert_value(owner.global_position)) + "\n" + "Phase 1: " + phase_one_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + phase_one_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name + "\n" + "Phase 2: " + phase_two_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + phase_two_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name + "\n" + "Phase 3: " + phase_three_state_machine.get_node("EnemyStateMachine").CURRENT_STATE.name + phase_three_state_machine.get_node("AttackStateMachine").CURRENT_STATE.name
