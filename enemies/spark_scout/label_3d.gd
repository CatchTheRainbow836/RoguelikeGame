extends Label3D

@onready var enemy_state_machine: StateMachine = $"../EnemyStateMachine"

@onready var attack_state_machine: StateMachine = $"../AttackStateMachine"


func _process(delta: float) -> void :
	text = "Spark Scout" + "\n" + enemy_state_machine.CURRENT_STATE.name + "\n" + attack_state_machine.CURRENT_STATE.name + "\n" + "can_see_player: " + str(enemy_state_machine.get_node("RunningEnemyState").can_see_player()) + "\n" + "alertness: " + str(LevelManager.get_alert_value(owner.global_position)) + "\n" + "alert timer: " + str(enemy_state_machine.get_node("RunningEnemyState").alert_timer)
