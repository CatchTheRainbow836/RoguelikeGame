extends CrucibleCoreMovementState
class_name PhaseOneWalkingCrucibleCoreState

func physics_update(delta: float) -> void :
	await owner.ready
	transition.emit("RunningEnemyState")
	owner.velocity = _velocity
	owner.move_and_slide()
