class_name JumpPlayerState
extends PlayerMovementState

@export var TOP_ANIM_SPEED: float = 2.2

func enter() -> void :
    AlertnessManager.add_alert(PLAYER.global_position, 1)

    PLAYER.velocity.y = JUMP_VELOCITY
    var horiz_speed: = Vector2(PLAYER.velocity.x, PLAYER.velocity.z).length()
    if Input.is_action_pressed("run"):
        _speed = SPEED_SPRINTING * 2
    elif horiz_speed > SPEED_DEFAULT:
        _speed = horiz_speed
    else:
        _speed = SPEED_DEFAULT

func update(delta):
    set_animation_speed(PLAYER.velocity.length())
    if PLAYER.is_on_floor() and Input.is_action_pressed("run"):
        print("Jump transitioning to Running")
        transition.emit("SprintingPlayerState")
    elif PLAYER.is_on_floor():
        print("Jump transitioning to Idle")
        transition.emit("IdlePlayerState")

func set_animation_speed(spd):
    var alpha = remap(spd, 0.0, SPEED_DEFAULT, 0.0, 1.0)
    ANIMATION.speed_scale = lerp(0.0, TOP_ANIM_SPEED, alpha)

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

func handle_input(event: InputEvent) -> void :
    mouse_move(event)

    if Input.is_action_just_pressed("interact"):
        interact()
