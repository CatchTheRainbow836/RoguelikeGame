extends DefaultEnemyMovementState
class_name IdleGearWardenState

var warden: GearWarden

func _ready() -> void :
	super._ready()
	await owner.ready
	warden = owner as GearWarden
	if warden:
		speed = warden.speed
		accel = warden.accel
		wander_radius = warden.wander_radius
		view_distance = warden.view_distance
		fov_degrees = warden.fov_degrees

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
