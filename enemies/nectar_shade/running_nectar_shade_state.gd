extends DefaultEnemyMovementState
class_name RunningNectarShadeState

var alert_duration: float
var alert_timer: float = 0.0
var shade: NectarShade
var target_enemy: Node = null
var pathfinding_update_timer: float = 0.0
var pathfinding_update_interval: float = 0.5

func _ready() -> void :
    super._ready()
    await owner.ready
    shade = owner as NectarShade
    if shade:
        speed = shade.speed
        accel = shade.accel
        view_distance = shade.view_distance
        fov_degrees = shade.fov_degrees
        alert_duration = shade.alert_duration

func enter() -> void :
    super.enter()
    alert_timer = alert_duration
    _find_nearest_enemy_by_path()

func exit() -> void :
    super.exit()
    target_enemy = null

func physics_update(delta: float) -> void :
    _vision_timer -= delta
    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if not is_player_visible:
        alert_timer -= delta
        if alert_timer <= 0.0:
            transition.emit("WalkingEnemyState")
            return
    else:
        alert_timer = alert_duration

    pathfinding_update_timer -= delta
    if pathfinding_update_timer <= 0.0:
        _find_nearest_enemy_by_path()
        pathfinding_update_timer = pathfinding_update_interval

    if target_enemy and is_instance_valid(target_enemy):
        navigation_agent_3d.target_position = target_enemy.global_position

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
            var move_dir = (target_enemy.global_position - owner.global_position)
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
        print("nectar shade: no valid enemy, stopped moving")
        _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
        _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    _velocity.y = 0.0

    owner.velocity = _velocity
    owner.move_and_slide()

func _find_nearest_enemy_by_path() -> void :
    var enemies = get_tree().get_nodes_in_group("enemies")
    var best_enemy = null
    var best_path_length = INF

    var map = navigation_agent_3d.get_navigation_map()
    var start = owner.global_position

    for enemy in enemies:
        if enemy == owner:
            continue
        var end = enemy.global_position
        var path = NavigationServer3D.map_get_path(map, start, end, true)
        var path_length = 0.0
        for i in range(path.size() - 1):
            path_length += path[i].distance_to(path[i + 1])
        if path_length < best_path_length:
            best_path_length = path_length
            best_enemy = enemy

    target_enemy = best_enemy
