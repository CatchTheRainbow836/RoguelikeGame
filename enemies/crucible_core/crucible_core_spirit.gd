extends CharacterBody3D
class_name CrucibleCoreSpirit

@export var speed: float = 12.0
@export var accel: float = 20.0
@export var wander_radius: float = 20.0
@export var avoid_player_radius: float = 10.0
@export var avoid_boss_radius: float = 5.0
@export var wander_interval: float = 2.5

var crucible_core: CrucibleCore
var PLAYER: CharacterBody3D
var _wander_timer: float = 0.0
var _velocity: Vector3 = Vector3.ZERO

var player_avoid_radius: float = 10

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

var navigation_region_3d: NavigationRegion3D

func _ready() -> void :
    add_to_group("enemies")
    add_to_group("crucible_core_spirit")
    crucible_core = get_tree().get_first_node_in_group("crucible_core")
    PLAYER = get_tree().get_first_node_in_group("player")
    navigation_region_3d = get_tree().root.get_node("Main").get_node("WorldStructures").get_node("NavigationRegion3D")
    navigation_agent_3d.set_navigation_map(navigation_region_3d.get_navigation_map())
    navigation_agent_3d.max_speed = speed

func _physics_process(delta: float) -> void :
    _wander_timer -= delta
    if navigation_agent_3d.is_navigation_finished() or _wander_timer <= 0.0:
        if _wander_timer <= 0.0:
            _pick_new_wander_target_avoid_player()
            _wander_timer = wander_interval

    if not navigation_agent_3d.is_navigation_finished():
        var next_pos = navigation_agent_3d.get_next_path_position()
        var move_dir = (next_pos - global_transform.origin)
        move_dir.y = 0.0
        if move_dir.length() > 0.2:
            move_dir = move_dir.normalized()
            look_at(global_position + move_dir, Vector3.UP)
            _velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
            _velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
        else:

            _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
            _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    velocity = _velocity
    move_and_slide()



func _pick_new_wander_target_avoid_player() -> void :
    if not navigation_agent_3d or not PLAYER:
        _pick_new_wander_target()
        return
    var origin = global_position
    var max_attempts = 20
    for attempt in range(max_attempts):
        var offset = Vector3(randf_range( - wander_radius, wander_radius), 0, randf_range( - wander_radius, wander_radius))
        var candidate = origin + offset
        if candidate.distance_to(PLAYER.global_position) >= player_avoid_radius:
            navigation_agent_3d.target_position = candidate
            if navigation_agent_3d.is_target_reachable():
                return
    _pick_new_wander_target()

func _pick_new_wander_target() -> void :
    if not navigation_agent_3d:
        return
    var origin = global_position
    var offset = Vector3(randf_range( - wander_radius, wander_radius), 0, randf_range( - wander_radius, wander_radius))
    var candidate = origin + offset
    for i in range(5):
        navigation_agent_3d.target_position = candidate
        if not navigation_agent_3d.is_target_reachable():
            offset = offset * 0.7
            candidate = origin + offset
        else:
            break
func take_damage(amount: float) -> void :
    if crucible_core:
        crucible_core.take_damage(amount)
