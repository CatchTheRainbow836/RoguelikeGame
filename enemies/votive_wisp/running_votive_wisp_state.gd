extends DefaultEnemyMovementState
class_name RunningVotiveWispState

var wisp: VotiveWisp

const INITIAL_KNOCKBACK_GAP: = 0.03


func _ready() -> void :
	super._ready()
	await owner.ready
	wisp = owner as VotiveWisp


func physics_update(delta: float) -> void :
	if not wisp.shield_broken:
		transition.emit("IdleEnemyState")
		return

	wisp.knockback_velocity *= pow(wisp.knockback_decay, delta * 60.0)
	if wisp.knockback_velocity.length_squared() < 1e-06:
		wisp.knockback_velocity = Vector3.ZERO
		if wisp.initial_knockback_active:
			wisp.initial_knockback_active = false

	var chase_velocity: = Vector3.ZERO

	if PLAYER:
		var target_position: = PLAYER.global_position
		target_position.y = 1.0

		var to_player: Vector3 = target_position - owner.global_position
		if to_player.length_squared() > 1e-06:
			var chase_dir: = to_player.normalized()
			wisp.chase_speed = move_toward(wisp.chase_speed, wisp.max_chase_speed, wisp.chase_acceleration * delta)
			chase_velocity = chase_dir * wisp.chase_speed
	else:
		wisp.chase_speed = move_toward(wisp.chase_speed, 0.0, wisp.chase_acceleration * delta)

	wisp.current_velocity = chase_velocity + wisp.knockback_velocity
	owner.velocity = wisp.current_velocity
	owner.move_and_slide()

	if wisp.initial_knockback_active:
		_stop_initial_knockback_before_wall()

	if wisp.current_velocity.length_squared() > 0.01:
		var dir: = wisp.current_velocity.normalized()
		pivot.look_at(pivot.global_position + dir, Vector3.UP)


func _stop_initial_knockback_before_wall() -> void :
	var pushed_out: = Vector3.ZERO
	var had_wall_contact: = false

	var count: int = owner.get_slide_collision_count()
	for i in range(count):
		var collision: KinematicCollision3D = owner.get_slide_collision(i)
		if collision == null:
			continue

		var normal: = collision.get_normal()
		if abs(normal.y) < 0.75:
			had_wall_contact = true
			pushed_out += normal
			wisp.knockback_velocity = wisp.knockback_velocity.slide(normal) * 0.2

	if had_wall_contact and pushed_out.length_squared() > 1e-06:
		owner.global_position += pushed_out.normalized() * INITIAL_KNOCKBACK_GAP
