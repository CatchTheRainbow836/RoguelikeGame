extends CrucibleCoreMovementState
class_name PhaseOneRunningCrucibleCoreState

func physics_update(delta: float) -> void :
    await owner.ready
    _velocity = Vector3.ZERO
    owner.velocity = _velocity
    owner.move_and_slide()
