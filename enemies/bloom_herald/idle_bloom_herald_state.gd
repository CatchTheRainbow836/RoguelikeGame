extends DefaultEnemyMovementState
class_name IdleBloomHeraldState

var herald: BloomHerald

func _ready() -> void :
	super._ready()
	await owner.ready
	herald = owner as BloomHerald
	if herald:
		speed = herald.speed
		accel = herald.accel
		wander_radius = herald.wander_radius
		view_distance = herald.view_distance
		fov_degrees = herald.fov_degrees

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
