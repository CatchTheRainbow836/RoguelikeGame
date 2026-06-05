extends CrucibleCoreMovementState
class_name PhaseTwoRunningCrucibleCoreState

func physics_update(delta: float) -> void :
	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
