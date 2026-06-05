class_name DefaultEnemyAttackState
extends State

var PLAYER

var running_enemy_state: Node

func _ready() -> void :
	await owner.ready
	PLAYER = get_tree().get_first_node_in_group("player")
	owner = get_parent().get_parent()

	owner.add_to_group("enemies")
	running_enemy_state = owner.get_node("EnemyStateMachine").get_node("RunningEnemyState")
