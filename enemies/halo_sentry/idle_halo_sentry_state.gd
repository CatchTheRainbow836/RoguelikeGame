extends DefaultEnemyMovementState
class_name IdleHaloSentryState

var sentry: HaloSentry

func _ready() -> void :
	super._ready()
	await owner.ready
	sentry = owner as HaloSentry

func enter() -> void :
	pass

func exit() -> void :
	pass

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:
		transition.emit("RunningEnemyState")
	else:
		transition.emit("WalkingEnemyState")

	if sentry:
		sentry.maintain_altitude(delta)
	else:
		_velocity.y = 0.0

	_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
	_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	owner.velocity = _velocity
	owner.move_and_slide()
