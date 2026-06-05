class_name IdlePlayerState

extends PlayerMovementState

func enter() -> void :
	ANIMATION.pause()

func update(delta):
	var direction = get_direction()
	if direction and PLAYER.is_on_floor() and Input.is_action_pressed("run"):
		print("Idle transitioning to Running")
		transition.emit("SprintingPlayerState")
	elif direction and PLAYER.is_on_floor():
		print("Idle transitioning to Walking")
		transition.emit("WalkingPlayerState")

func handle_input(event: InputEvent) -> void :
	mouse_move(event)

	if event.is_action_pressed("crouch") and PLAYER.is_on_floor():

		print("Idle transitioning to Crouch")
		transition.emit("CrouchPlayerState")

	if Input.is_action_just_pressed("interact"):
		interact()

	if Input.is_action_pressed("jump") and PLAYER.is_on_floor():
		transition.emit("JumpPlayerState")


func physics_update(delta):

	apply_gravity(delta)
	sway_weapon(delta, true)
	var direction = get_direction()

	if direction:
		PLAYER.velocity.x = lerp(PLAYER.velocity.x, direction.x * _speed, ACCELERATION)
		PLAYER.velocity.z = lerp(PLAYER.velocity.z, direction.z * _speed, ACCELERATION)
	else:
		PLAYER.velocity.x = move_toward(PLAYER.velocity.x, 0, DECELERATION)
		PLAYER.velocity.z = move_toward(PLAYER.velocity.z, 0, DECELERATION)

	PLAYER.move_and_slide()
