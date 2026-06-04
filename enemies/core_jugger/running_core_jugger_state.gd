extends DefaultEnemyMovementState
class_name RunningCoreJuggerState

var alert_duration: float
var alert_timer: float = 0.0
var attack_range: float
var jugger: CoreJugger

func _ready() -> void :
    super._ready()
    await owner.ready
    jugger = owner as CoreJugger
    if jugger:
        speed = jugger.speed
        accel = jugger.accel
        view_distance = jugger.view_distance
        fov_degrees = jugger.fov_degrees
        attack_range = jugger.attack_range
        alert_duration = jugger.alert_duration

func enter() -> void :
    super.enter()
    alert_timer = alert_duration

func exit() -> void :
    super.exit()

func physics_update(delta: float) -> void :
    _vision_timer -= delta
    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if is_player_visible:
        navigation_agent_3d.target_position = PLAYER.global_position
        alert_timer = alert_duration
    else:
        alert_timer -= delta
        if alert_timer <= 0.0:
            transition.emit("WalkingEnemyState")
            return

    var distance_to_player = owner.global_position.distance_to(PLAYER.global_position)
    if distance_to_player <= attack_range:
        _velocity = Vector3.ZERO
    else:
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

    _look_at_player_smooth(delta)

    owner.velocity = _velocity
    owner.move_and_slide()
