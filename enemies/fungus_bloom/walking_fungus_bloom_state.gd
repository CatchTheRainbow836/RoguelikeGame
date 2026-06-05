extends DefaultEnemyMovementState
class_name WalkingFungusBloomState

func physics_update(delta: float) -> void :
	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
