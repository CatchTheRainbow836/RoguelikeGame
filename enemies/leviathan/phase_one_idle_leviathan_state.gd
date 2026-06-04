extends LeviathanMovementState
class_name PhaseOneIdleLeviathanState

func physics_update(delta: float) -> void :
    transition.emit("RunningEnemyState")
    owner.velocity = _velocity
    owner.move_and_slide()
