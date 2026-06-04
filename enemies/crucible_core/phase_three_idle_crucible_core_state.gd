extends CrucibleCoreMovementState
class_name PhaseThreeIdleCrucibleCoreState

func physics_update(delta: float) -> void :
    transition.emit("RunningEnemyState")
    owner.velocity = _velocity
    owner.move_and_slide()
