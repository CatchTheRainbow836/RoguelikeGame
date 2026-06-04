extends DefaultEnemyAttackState
class_name AttackingDefaultEnemyAttackState

func enter() -> void :
    pass


func _ready() -> void :
    await owner.ready
    running_enemy_state = owner.get_node("EnemyStateMachine").get_node("RunningEnemyState")
    running_enemy_state.connect("can_attack", tranfer_to_attack)

func tranfer_to_attack(active: bool):
    if active == false:
        transition.emit("IdleAttackState")
