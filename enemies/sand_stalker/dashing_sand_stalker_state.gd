extends DefaultEnemyMovementState
class_name DashingSandStalkerState

var stalker: SandStalker
var dash_start: Vector3
var dash_end: Vector3
var dash_direction: Vector3
var dash_distance: float
var traveled: float = 0.0
var dash_speed: float
var has_damaged_player: bool = false
var original_collision_mask: int
var stop_offset: float = 0.5

func _ready() -> void :
	super._ready()
	await owner.ready
	stalker = owner as SandStalker
	if stalker:
		dash_speed = stalker.dash_speed

func enter() -> void :
	super.enter()
	stalker.is_dashing = true

	owner.set_collision_layer_value.call_deferred(1, false)

	traveled = 0.0
	has_damaged_player = false
	original_collision_mask = owner.collision_mask
	owner.collision_mask = 0
	owner.set_collision_mask_value(2, false)

	dash_start.y = 0.0
	dash_end.y = 0.0

	var direction = (dash_end - dash_start).normalized()
	var adjusted_end = dash_end - direction * stop_offset
	if adjusted_end.distance_to(dash_start) < 0.1:
		adjusted_end = dash_end
	dash_end = adjusted_end

	dash_direction = (dash_end - dash_start).normalized()
	dash_distance = dash_start.distance_to(dash_end)

func exit() -> void :
	stalker.is_dashing = false

	owner.set_collision_layer_value.call_deferred(1, true)

	owner.set_collision_mask_value(2, true)
	owner.collision_mask = original_collision_mask
	_velocity = Vector3.ZERO
	owner.velocity = _velocity

func physics_update(delta: float) -> void :
	if dash_distance <= 0.0:
		transition.emit("RunningEnemyState")
		return

	var step = dash_speed * delta
	traveled += step
	var t = traveled / dash_distance
	if t >= 1.0:
		transition.emit("RunningEnemyState")
		return

	var current_pos = dash_start.lerp(dash_end, t)
	current_pos.y = 0.0
	owner.global_position = current_pos

	if not has_damaged_player and PLAYER:
		var to_player = owner.global_position - PLAYER.global_position
		var dist = to_player.length()
		if dist < 1.5:
			PLAYER.take_damage(stalker.dash_damage)
			has_damaged_player = true

	if dash_direction.length_squared() > 0.01:
		pivot.look_at(pivot.global_position + dash_direction, Vector3.UP)

	_velocity = dash_direction * dash_speed
	owner.velocity = _velocity
	owner.move_and_slide()
