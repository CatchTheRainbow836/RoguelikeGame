extends DefaultEnemyMovementState
class_name IdleFungusBloomState

var fungus: FungusBloom
var exit_timer: float = 0.0

func _ready() -> void :
	super._ready()
	await owner.ready
	fungus = owner as FungusBloom
	if fungus:
		view_distance = fungus.view_distance
		fov_degrees = 360.0

func enter() -> void :
	exit_timer = 0.0

func exit() -> void :
	pass

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:
		var dist = owner.global_position.distance_to(PLAYER.global_position)
		if dist <= fungus.attack_range:
			transition.emit("RunningEnemyState")
			return

	if is_player_visible and PLAYER:
		_look_at_player_smooth(delta)

	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
