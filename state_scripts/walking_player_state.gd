class_name WalkingPlayerState
extends PlayerMovementState

@export var TOP_ANIM_SPEED: float = 2.2
func enter() -> void :
    ANIMATION.play("Walking", -1.0, 1.0)
    _speed = SPEED_DEFAULT

func update(delta):
    set_animation_speed(PLAYER.velocity.length())
    if PLAYER.velocity.length() == 0.0:
        print("Walking transitioning to Idle")
        transition.emit("IdlePlayerState")

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

func set_animation_speed(spd):
    var alpha = remap(spd, 0.0, SPEED_DEFAULT, 0.0, 1.0)
    ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

func handle_input(event: InputEvent) -> void :
    mouse_move(event)

    if event.is_action_pressed("run") and PLAYER.is_on_floor():
        print("Walking transitioning to Sprinting")
        ANIMATION.pause()
        transition.emit("SprintingPlayerState")

    if event.is_action_pressed("crouch") and PLAYER.is_on_floor():
        print("Walking transitioning to Crouch")
        ANIMATION.pause()
        transition.emit("CrouchPlayerState")

    if Input.is_action_just_pressed("interact"):
        interact()

    if Input.is_action_pressed("jump") and PLAYER.is_on_floor():
        ANIMATION.pause()
        transition.emit("JumpPlayerState")
