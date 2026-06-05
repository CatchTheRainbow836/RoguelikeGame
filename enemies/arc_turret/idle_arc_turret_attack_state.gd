extends DefaultEnemyAttackState
class_name IdleArcTurretAttackState

var running_state: RunningArcTurretState

func _ready() -> void :
	super._ready()
	await owner.ready
	running_state = owner.get_node("EnemyStateMachine/RunningEnemyState") as RunningArcTurretState
	if running_state:
		running_state.connect("can_attack", _on_can_attack)

func _on_can_attack(active: bool) -> void :
	if active:
		transition.emit("AttackingAttackState")

func physics_update(delta: float) -> void :
	pass
