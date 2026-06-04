extends DefaultEnemyMovementState
class_name IdleMiddenSpitterState

var spitter: MiddenSpitter

func _ready() -> void :
    super._ready()
    await owner.ready
    spitter = owner as MiddenSpitter
    if spitter:
        speed = spitter.speed
        accel = spitter.accel
        view_distance = spitter.view_distance
        fov_degrees = spitter.fov_degrees
        wander_radius = spitter.wander_radius

func enter() -> void :
    pass

func exit() -> void :
    pass

func physics_update(delta: float) -> void :
    _vision_timer -= delta
    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if is_player_visible:
        transition.emit("RunningEnemyState")
    else:
        transition.emit("WalkingEnemyState")

    maintain_altitude(delta)
    _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
    _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    owner.velocity = _velocity
    owner.move_and_slide()

func maintain_altitude(delta: float) -> void :
    if not spitter:
        return
    var current_y = owner.global_position.y
    var target_y = spitter.target_altitude + sin(spitter.bob_phase) * spitter.bob_amplitude
    spitter.bob_phase += spitter.bob_frequency * delta

    var y_error = target_y - current_y
    if abs(y_error) > spitter.altitude_tolerance:
        _velocity.y = move_toward(_velocity.y, y_error * 5.0, accel * delta)
    else:
        _velocity.y = move_toward(_velocity.y, 0.0, accel * delta)
