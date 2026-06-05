extends DefaultEnemyMovementState
class_name JumpingSovereignWightState

var jump_duration: float = 0.8
var jump_timer: float = 0.0
var start_pos: Vector3
var target_pos: Vector3
var jump_height: float = 3.0
var wight: SovereignWight

func _ready() -> void :
	super._ready()
	await owner.ready
	wight = owner as SovereignWight

func enter() -> void :
	super.enter()
	start_pos = owner.global_position
	if PLAYER:
		target_pos = PLAYER.global_position
	else:
		target_pos = start_pos + Vector3.FORWARD * wight.jump_range
	target_pos.y = 0

	jump_timer = 0.0
	var anim_length = wight.animation_player.get_animation("OverhandThrow").length
	wight.animation_player.play("OverhandThrow")
	wight.block_animation_for(anim_length)

func exit() -> void :
	super.exit()

func physics_update(delta: float) -> void :
	jump_timer += delta
	var t = clamp(jump_timer / jump_duration, 0.0, 1.0)

	var horizontal = start_pos.lerp(target_pos, t)
	var y = start_pos.y + (jump_height * 4 * t * (1 - t))
	owner.global_position = Vector3(horizontal.x, y, horizontal.z)

	var move_dir = (target_pos - start_pos).normalized()
	if move_dir.length_squared() > 0.01:
		pivot.look_at(pivot.global_position + move_dir, Vector3.UP)

	if t >= 1.0:
		owner.attack_state_machine.on_child_transition("AttackingAttackState")
		transition.emit("RunningEnemyState")

	_velocity = Vector3.ZERO
	owner.velocity = _velocity
	owner.move_and_slide()
