extends DefaultEnemyMovementState
class_name RunningFungusBloomState

var fungus: FungusBloom
var is_popped: bool = false
var exit_timer: float = 0.0
var exit_delay: float = 0.01

func _ready() -> void :
	super._ready()
	await owner.ready
	fungus = owner as FungusBloom

func enter() -> void :
	super.enter()
	exit_timer = 0.0
	if not is_popped:
		fungus.pop_up()
		is_popped = true

func exit() -> void :
	super.exit()
	if is_popped:
		fungus.pop_down()
		is_popped = false

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	var dist = owner.global_position.distance_to(PLAYER.global_position) if PLAYER else INF
	var should_exit = false

	if not is_player_visible or dist > fungus.attack_range:
		exit_timer += delta
		if exit_timer >= exit_delay:
			should_exit = true
	else:
		exit_timer = 0.0

	if should_exit:
		transition.emit("IdleEnemyState")
		return

	if is_player_visible and PLAYER:
		_look_at_player_smooth(delta)

	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
