extends FurnaceColossusMovementState
class_name PhaseThreeWalkingFurnaceColossusState

var colossus: FurnaceColossus

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer
func enter() -> void :
	animation_player.get_animation("Walk").loop_mode = Animation.LOOP_LINEAR
	animation_player.play("Walk")

func exit() -> void :
	animation_player.stop()

func _ready() -> void :
	super._ready()
	await owner.ready
	colossus = owner as FurnaceColossus
	if colossus:
		speed = colossus.phase3_speed
		accel = colossus.accel
		wander_radius = colossus.wander_radius
		view_distance = colossus.view_distance
		fov_degrees = colossus.fov_degrees

func physics_update(delta: float) -> void :
	_vision_timer -= delta

	if _vision_timer <= 0.0:
		is_player_visible = can_see_player()
		_vision_timer = vision_check_interval

	if is_player_visible:
		transition.emit("RunningEnemyState")
	else:
		_wander_timer -= delta
		if navigation_agent_3d.is_navigation_finished() or _wander_timer <= 0.0:
			if _wander_timer <= 0.0:
				_pick_new_wander_target()
				_wander_timer = wander_interval

		if not navigation_agent_3d.is_navigation_finished():
			var next_pos = navigation_agent_3d.get_next_path_position()
			var move_dir = (next_pos - owner.global_transform.origin)
			move_dir.y = 0.0

			if move_dir.length() > 0.2:
				move_dir = move_dir.normalized()
				pivot.look_at(owner.global_position + move_dir, Vector3.UP)
				_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
				_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
			else:
				_velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
				_velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

	owner.velocity = _velocity
	owner.move_and_slide()
