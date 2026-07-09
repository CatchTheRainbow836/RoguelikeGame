extends DefaultEnemyMovementState
class_name WalkingArcTurretState

func physics_update(delta: float) -> void:
	transition.emit("IdleEnemyState")
