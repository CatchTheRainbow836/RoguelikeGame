extends FurnaceColossusMovementState
class_name PhaseTwoIdleFurnaceColossusState

var colossus: FurnaceColossus

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer
func enter() -> void :
	animation_player.get_animation("Fighting Idle").loop_mode = Animation.LOOP_LINEAR
	animation_player.play("Fighting Idle")

func exit() -> void :
	animation_player.stop()


func _ready() -> void :
	super._ready()
	await owner.ready
	colossus = owner as FurnaceColossus
	if colossus:
		speed = colossus.phase2_speed
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
		transition.emit("WalkingEnemyState")
	owner.velocity = _velocity
	owner.move_and_slide()
