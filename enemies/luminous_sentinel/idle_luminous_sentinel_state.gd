extends DefaultEnemyMovementState
class_name IdleLuminousSentinelState

var sentinel: LuminousSentinel

func _ready() -> void :
	super._ready()
	await owner.ready
	sentinel = owner as LuminousSentinel
	if sentinel:
		speed = sentinel.speed
		accel = sentinel.accel
		wander_radius = sentinel.wander_radius
		view_distance = sentinel.view_distance
		fov_degrees = sentinel.fov_degrees

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

	owner.velocity = _velocity
	owner.move_and_slide()
