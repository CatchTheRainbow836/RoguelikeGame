extends DefaultEnemyMovementState
class_name WalkingNectarShadeState

var shade: NectarShade

func _ready() -> void :
    super._ready()
    await owner.ready
    shade = owner as NectarShade
    if shade:
        speed = shade.speed
        accel = shade.accel
        wander_radius = shade.wander_radius
        view_distance = shade.view_distance

func enter() -> void :
    _pick_new_wander_target()
    _wander_timer = wander_interval

func exit() -> void :
    pass

func physics_update(delta: float) -> void :
    _vision_timer -= delta
    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if is_player_visible and can_see_player():
        transition.emit("RunningEnemyState")
        return

    _wander_timer -= delta
    if navigation_agent_3d.is_navigation_finished() or _wander_timer <= 0.0:
        _pick_new_wander_target()
        _wander_timer = wander_interval

    if not navigation_agent_3d.is_navigation_finished():
        var next_pos = navigation_agent_3d.get_next_path_position()
        var move_dir = (next_pos - owner.global_transform.origin)
        move_dir.y = 0.0
        if move_dir.length() > 0.2:
            move_dir = move_dir.normalized()
            pivot.look_at(pivot.global_position + move_dir, Vector3.UP)
            _velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
            _velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
        else:
            _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
            _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)
    else:
        print("nectar shade: no path, stopped moving")
        _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
        _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    maintain_altitude(delta)

    owner.velocity = _velocity
    owner.move_and_slide()

func maintain_altitude(delta: float) -> void :
    if not shade:
        return
    var current_y = owner.global_position.y
    var target_y = shade.target_altitude + sin(shade.bob_phase) * shade.bob_amplitude
    shade.bob_phase += shade.bob_frequency * delta

    var y_error = target_y - current_y
    if abs(y_error) > shade.altitude_tolerance:
        _velocity.y = move_toward(_velocity.y, y_error * 5.0, accel * delta)
    else:
        _velocity.y = move_toward(_velocity.y, 0.0, accel * delta)
