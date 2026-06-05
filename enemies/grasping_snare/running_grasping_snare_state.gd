extends DefaultEnemyMovementState
class_name RunningGraspingSnareState

var snare: GraspingSnare

func _ready() -> void :
	super._ready()
	await owner.ready
	snare = owner as GraspingSnare

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval
	if not is_player_visible:
		transition.emit("IdleEnemyState")
	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
