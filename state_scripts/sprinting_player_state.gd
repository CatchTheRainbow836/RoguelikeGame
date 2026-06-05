class_name SprintingPlayerState
extends PlayerMovementState

@export var TOP_ANIM_SPEED: float = 1.6



func enter() -> void :
	ANIMATION.play("Sprinting", 0.5, 1.0)
	_speed = SPEED_SPRINTING

func update(delta):
	set_animation_speed(PLAYER.velocity.length())

func set_animation_speed(spd):
	var alpha = remap(spd, 0.0, SPEED_SPRINTING, 0.0, 1.0)
	ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func handle_input(event: InputEvent) -> void :
	mouse_move(event)

	if event.is_action_released("run"):
		print("Sprinting transitioning to Walking")
		ANIMATION.pause()
		transition.emit("WalkingPlayerState")

	if event.is_action_pressed("crouch") and PLAYER.is_on_floor():
		print("Sprinting transitioning to Crouching")
		ANIMATION.pause()
		transition.emit("CrouchPlayerState")

	if Input.is_action_just_pressed("interact"):
		interact()

	if Input.is_action_pressed("jump") and PLAYER.is_on_floor():
		ANIMATION.pause()
		transition.emit("JumpPlayerState")

func physics_update(delta):

	apply_gravity(delta)
	sway_weapon(delta, false)
	var direction = get_direction()

	if direction:
		PLAYER.velocity.x = lerp(PLAYER.velocity.x, direction.x * _speed * 2, ACCELERATION)
		PLAYER.velocity.z = lerp(PLAYER.velocity.z, direction.z * _speed * 2, ACCELERATION)

	else:
		PLAYER.velocity.x = move_toward(PLAYER.velocity.x, 0, DECELERATION)
		PLAYER.velocity.z = move_toward(PLAYER.velocity.z, 0, DECELERATION)


	PLAYER.move_and_slide()
