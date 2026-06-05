extends DefaultEnemyMovementState
class_name RunningBronzeStatueState

var statue: BronzeStatue
var attack_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	statue = owner as BronzeStatue
	if statue:
		attack_range = statue.attack_range
		view_distance = attack_range

func enter() -> void :
	super.enter()

func exit() -> void :
	super.exit()

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if not is_player_visible:
		transition.emit("IdleEnemyState")
		return

	_look_at_player_smooth(delta)

	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist <= attack_range and can_see_player():
		owner.attack_state_machine.on_child_transition("AttackingAttackState")
		return

	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
