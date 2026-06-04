extends DefaultEnemyMovementState
class_name RunningVeinHarvesterState

var harvester: VeinHarvester
var preferred_distance: float
var strafe_speed: float
var strafe_angle: float = 0.0
var alert_timer: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    harvester = owner as VeinHarvester
    if harvester:
        speed = harvester.speed
        accel = harvester.accel
        view_distance = harvester.view_distance
        fov_degrees = harvester.fov_degrees
        preferred_distance = harvester.preferred_distance
        strafe_speed = harvester.strafe_speed

func enter() -> void :
    super.enter()
    alert_timer = harvester.alert_duration

func physics_update(delta: float) -> void :
    _vision_timer -= delta
    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if is_player_visible:
        navigation_agent_3d.target_position = PLAYER.global_position
        alert_timer = harvester.alert_duration
    else:
        alert_timer -= delta
        if alert_timer <= 0.0:
            transition.emit("WalkingEnemyState")
            return

    var to_player = PLAYER.global_position - owner.global_position
    var dir_to_player = to_player.normalized()
    strafe_angle += delta * strafe_speed
    var right = Vector3(dir_to_player.z, 0, - dir_to_player.x).normalized()
    var strafe_offset = right * sin(strafe_angle) * (preferred_distance * 0.5)
    var desired_offset = - dir_to_player * preferred_distance
    var target_pos = PLAYER.global_position + desired_offset + strafe_offset
    target_pos.y = harvester.target_altitude
    var move_dir = (target_pos - owner.global_position)
    var horizontal_dist = Vector2(move_dir.x, move_dir.z).length()
    if horizontal_dist > 0.2:
        var hor_dir = Vector3(move_dir.x, 0, move_dir.z).normalized()
        _velocity.x = move_toward(_velocity.x, hor_dir.x * speed, accel * delta)
        _velocity.z = move_toward(_velocity.z, hor_dir.z * speed, accel * delta)
    else:
        _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
        _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    _velocity = harvester.maintain_altitude(delta, _velocity)
    _look_at_player_smooth(delta)
    owner.velocity = _velocity
    owner.move_and_slide()
