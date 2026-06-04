extends ArchonMovementState
class_name PhaseTwoRunningArchonState

var boss: ArchonOfBlinding
var player_avoid_radius: float

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as ArchonOfBlinding
    if boss:
        speed = boss.phase2_speed
        accel = boss.phase2_accel
        view_distance = boss.phase1_view_distance
        fov_degrees = boss.phase1_fov_degrees
        wander_radius = boss.phase2_wander_radius
        player_avoid_radius = boss.phase1_player_avoid_radius

func physics_update(delta: float) -> void :
    _wander_timer -= delta
    if navigation_agent_3d.is_navigation_finished() or _wander_timer <= 0.0:
        if _wander_timer <= 0.0:
            _pick_new_wander_target_avoid_player()
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

    owner.velocity = _velocity
    owner.move_and_slide()

func _pick_new_wander_target_avoid_player() -> void :
    if not navigation_agent_3d or not PLAYER:
        _pick_new_wander_target()
        return
    var origin = owner.global_position
    var max_attempts = 20
    for attempt in range(max_attempts):
        var offset = Vector3(randf_range( - wander_radius, wander_radius), 0, randf_range( - wander_radius, wander_radius))
        var candidate = origin + offset
        if candidate.distance_to(PLAYER.global_position) >= player_avoid_radius:
            navigation_agent_3d.target_position = candidate
            if navigation_agent_3d.is_target_reachable():
                return
    _pick_new_wander_target()
