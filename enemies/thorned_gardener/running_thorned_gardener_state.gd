extends DefaultEnemyMovementState
class_name RunningThornedGardenerState

var alert_duration: float
var alert_timer: float = 0.0
var attack_range: float
var preferred_distance: float
var turn_speed: float
var gardener: ThornedGardener
var strafe_angle: float = 0.0
var strafe_speed: float = 2.0

func _ready() -> void :
    super._ready()
    await owner.ready
    gardener = owner as ThornedGardener
    if gardener:
        speed = gardener.speed
        accel = gardener.accel
        view_distance = gardener.view_distance
        fov_degrees = gardener.fov_degrees
        attack_range = gardener.attack_range
        preferred_distance = gardener.preferred_distance
        turn_speed = gardener.turn_speed
        alert_duration = gardener.alert_duration

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

    var to_player = PLAYER.global_position - owner.global_position
    var dist = to_player.length()
    var dir_to_player = to_player.normalized()

    strafe_angle += delta * strafe_speed
    var right = Vector3(dir_to_player.z, 0, - dir_to_player.x).normalized()
    var strafe_offset = right * sin(strafe_angle) * (preferred_distance * 0.5)

    var desired_offset = - dir_to_player * preferred_distance
    var target_pos = PLAYER.global_position + desired_offset + strafe_offset
    target_pos.y = owner.global_position.y

    var move_dir = (target_pos - owner.global_position)
    move_dir.y = 0.0
    if move_dir.length() > 0.2:
        move_dir = move_dir.normalized()
        _velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
        _velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
    else:
        _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
        _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    _look_at_player_smooth(delta)

    owner.velocity = _velocity
    owner.move_and_slide()
