extends State
class_name PhaseStateMachine

func enter() -> void :
	print(self.name, " entered")
	for child in get_children():
		if child is StateMachine:
			child.set_process(true)
			child.set_physics_process(true)

func exit() -> void :
	print(self.name, " exited")
	for child in get_children():
		if child is StateMachine:
			child.set_process(false)
			child.set_physics_process(false)
	get_node("EnemyStateMachine").on_child_transition("IdleEnemyState")
	get_node("AttackStateMachine").on_child_transition("IdleAttackState")

func _ready() -> void :
	for child in get_children():
		if child is StateMachine:
			child.set_process(false)
			child.set_physics_process(false)
