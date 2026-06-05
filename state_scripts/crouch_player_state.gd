class_name CrouchPlayerState
extends PlayerMovementState

@export var TOP_ANIM_SPEED: float = 2.2

func enter() -> void :
	ANIMATION.play("Crouch", 0, CROUCH_SPEED)
	_speed = SPEED_CROUCH
	shape_cast_3d.add_exception(PLAYER)

func handle_input(event: InputEvent) -> void :
	mouse_move(event)

	if event.is_action_released("crouch") and await uncrouch_check() == true:
		ANIMATION.play("Crouch", 0, - CROUCH_SPEED, true)
		print("Crouch transitioning to Walking")
		transition.emit("WalkingPlayerState")

	if Input.is_action_just_pressed("interact"):
		interact()

func uncrouch_check() -> bool:
	if shape_cast_3d.is_colliding() == false:
		return true
	if shape_cast_3d.is_colliding() == true:
		await get_tree().create_timer(0.1).timeout
		uncrouch_check()
	return false

func physics_update(delta):

	apply_gravity(delta)
	sway_weapon(delta, false)
	var direction = get_direction()

	if direction:
		PLAYER.velocity.x = lerp(PLAYER.velocity.x, direction.x * _speed, ACCELERATION)
		PLAYER.velocity.z = lerp(PLAYER.velocity.z, direction.z * _speed, ACCELERATION)

	else:
		PLAYER.velocity.x = move_toward(PLAYER.velocity.x, 0, DECELERATION)
		PLAYER.velocity.z = move_toward(PLAYER.velocity.z, 0, DECELERATION)

	PLAYER.move_and_slide()
