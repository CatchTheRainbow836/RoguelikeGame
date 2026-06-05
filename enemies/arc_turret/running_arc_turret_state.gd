extends DefaultEnemyMovementState
class_name RunningArcTurretState

var attack_range: float
var turn_speed: float
var is_attacking_emitted: bool = false
var turret: ArcTurret

signal can_attack(active: bool)

func _ready() -> void :
	super._ready()
	await owner.ready
	turret = owner as ArcTurret
	if turret:
		attack_range = turret.attack_range
		turn_speed = turret.turn_speed
		view_distance = attack_range

func enter() -> void :
	navigation_agent_3d.target_position = owner.global_position
	is_attacking_emitted = false

func exit() -> void :
	if is_attacking_emitted:
		can_attack.emit(false)
		is_attacking_emitted = false

func physics_update(delta: float) -> void :
	_vision_timer -= delta
	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:
		_look_at_player_smooth(delta)

		var dist = owner.global_position.distance_to(PLAYER.global_position)
		if dist <= attack_range and can_see_player():
			if not is_attacking_emitted:
				can_attack.emit(true)
				is_attacking_emitted = true
		else:
			if is_attacking_emitted:
				can_attack.emit(false)
				is_attacking_emitted = false
	else:
		transition.emit("IdleEnemyState")
		return

	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
