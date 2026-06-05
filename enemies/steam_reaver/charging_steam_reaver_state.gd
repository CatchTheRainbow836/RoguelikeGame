extends DefaultEnemyMovementState
class_name ChargingSteamReaverState

var charge_speed: float
var charge_duration: float
var charge_timer: float = 0.0
var dash_direction: Vector3
var reaver: SteamReaver

func _ready() -> void :
	super._ready()
	await owner.ready
	reaver = owner as SteamReaver
	if reaver:
		charge_speed = reaver.charge_speed
		charge_duration = reaver.charge_duration

func enter() -> void :
	if PLAYER:
		var to_player = PLAYER.global_position - owner.global_position
		to_player.y = 0.0
		if to_player.length() > 0:
			dash_direction = to_player.normalized()
		else:
			dash_direction = Vector3.FORWARD
		pivot.look_at(pivot.global_position + dash_direction, Vector3.UP)
	charge_timer = charge_duration

func exit() -> void :
	pass

func physics_update(delta: float) -> void :
	charge_timer -= delta
	if charge_timer <= 0.0:

		transition.emit("RunningEnemyState")
		return

	_velocity.x = dash_direction.x * charge_speed
	_velocity.z = dash_direction.z * charge_speed
	_velocity.y = 0.0

	owner.velocity = _velocity
	owner.move_and_slide()
