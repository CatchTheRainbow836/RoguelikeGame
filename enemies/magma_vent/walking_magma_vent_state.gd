extends DefaultEnemyMovementState
class_name WalkingMagmaVentState

func physics_update(delta: float) -> void :
	transition.emit("IdleEnemyState")
	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
