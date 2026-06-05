extends DefaultEnemyMovementState
class_name IdleVotiveWispState

var wisp: VotiveWisp
var hover_phase: float = 0.0
var original_y: float = 2.0

func _ready() -> void :
	super._ready()
	await owner.ready
	wisp = owner as VotiveWisp
	if wisp:
		speed = 0.0
		accel = 0.0

func enter() -> void :
	hover_phase = randf_range(0.0, TAU)
	original_y = 2.0
func physics_update(delta: float) -> void :
	hover_phase += wisp.hover_frequency * delta
	var y_offset = sin(hover_phase) * wisp.hover_amplitude
	owner.global_position.y = original_y + y_offset

	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
