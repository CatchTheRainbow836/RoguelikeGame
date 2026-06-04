extends CharacterBody3D

@onready var light: OmniLight3D = $Pivot / MuzzleFlash / OmniLight3D
@onready var emitter: GPUParticles3D = $Pivot / MuzzleFlash / GPUParticles3D
@export var flash_time: float = 0.05

@export var player_path: NodePath
@onready var player: Node3D = (
    get_node(player_path)
    if not player_path.is_empty()
    else get_tree().get_first_node_in_group("player")
)
@export var pivot_path: NodePath = NodePath("Pivot")
@onready var pivot: Node3D = get_node_or_null(pivot_path)
@onready var agent: NavigationAgent3D = $NavAgent

@export var fov_degrees: float = 90.0
@export var view_distance: float = 20.0
var range = view_distance
@export var vision_collision_mask: int = 1
@export var vision_check_interval: float = 0.2

@export var wander_radius: float = 8.0
@export var wander_interval: float = 2.5

@export var speed: float = 3.0
@export var accel: float = 10.0

@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

@export var bullet_hole_sprite: PackedScene

@export var spread: float = 0.02

@export var damage: float = 2

var _vision_timer: float = 0.0
var _wander_timer: float = 0.0
var _target_wander: Vector3 = Vector3.ZERO
var _velocity: Vector3 = Vector3.ZERO
var is_player_visible: bool = false

func _ready() -> void :
    add_to_group("enemies")
    await get_tree().process_frame

    agent.max_speed = speed if "max_speed" in agent else speed
    _wander_timer = 0.0
    _vision_timer = 0.0
    is_player_visible = false

func _physics_process(delta: float) -> void :
    _vision_timer -= delta

    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if is_player_visible:

        _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
        _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)
        _look_at_player_smooth(delta)

        agent.target_position = global_position
    else:
        _wander_timer -= delta

        if agent.is_navigation_finished() or _wander_timer <= 0.0:
            if _wander_timer <= 0.0:
                _pick_new_wander_target()
                _wander_timer = wander_interval

        if not agent.is_navigation_finished():
            var next_pos = agent.get_next_path_position()
            var move_dir = (next_pos - global_transform.origin)
            move_dir.y = 0.0

            if move_dir.length() > 0.2:
                move_dir = move_dir.normalized()
                pivot.look_at(global_position - move_dir, Vector3.UP)
                _velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
                _velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
            else:
                _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
                _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    velocity = _velocity
    move_and_slide()

func can_see_player() -> bool:
    if not player or not pivot:
        return false

    var to_player = player.global_transform.origin - pivot.global_transform.origin
    var dist = to_player.length()
    if dist > view_distance:
        return false

    var forward = pivot.global_transform.basis.z.normalized()
    var dir_norm = to_player.normalized()
    var angle_threshold = cos(deg_to_rad(fov_degrees * 0.5))
    if forward.dot(dir_norm) < angle_threshold:
        return false

    var space = get_world_3d().direct_space_state
    var params: = PhysicsRayQueryParameters3D.new()
    params.from = pivot.global_position + Vector3.UP * 0.5
    params.to = player.global_position + Vector3.UP * 1.0
    params.exclude = [self]
    params.collision_mask = 4294967295
    var res: Dictionary = space.intersect_ray(params)
    if res.size() == 0:
        return false

    var collider = res.get("collider")
    if collider == player:
        fire()
        add_muzzle_flash()
        return true

    return false

func _look_at_player_smooth(delta: float) -> void :
    if not pivot or not player:
        return

    var to_target = player.global_position - pivot.global_position
    to_target.y = 0.0

    if to_target.length_squared() > 0.001:
        var target_transform = pivot.global_transform.looking_at(
            pivot.global_position + to_target, 
            Vector3.UP, 
            true
        )

        pivot.global_transform.basis = pivot.global_transform.basis.slerp(
            target_transform.basis, 
            6.0 * delta
        )

func _pick_new_wander_target() -> void :
    if not agent:
        return

    var origin = global_position
    var offset = Vector3(
        randf_range( - wander_radius, wander_radius), 
        0, 
        randf_range( - wander_radius, wander_radius)
    )

    var candidate = origin + offset

    for i in range(5):
        agent.target_position = candidate
        if not agent.is_target_reachable():
            offset = offset * 0.7
            candidate = origin + offset
        else:
            break

func take_damage(damage_amount: float) -> void :
    queue_free()










func add_muzzle_flash() -> void :
    light.visible = true
    emitter.emitting = true
    await get_tree().create_timer(flash_time).timeout
    light.visible = false

func fire() -> void :
    var from: Vector3 = pivot.global_transform.origin
    var to_player = player.global_position - from


    var dir: Vector3 = to_player.normalized()
    var player_target_pos = player.global_position + Vector3(0, 1.5, 0)

    var to: Vector3 = from + dir * range
    var space = get_world_3d().direct_space_state

    var distance = to_player.length()
    var spread_distance = distance * spread
    var inaccurate_target = player_target_pos + Vector3(
        randf_range( - spread_distance, spread_distance), 
        randf_range( - spread_distance * 0.5, spread_distance * 0.5), 
        randf_range( - spread_distance, spread_distance)
    )

    var params: = PhysicsRayQueryParameters3D.new()
    params.from = from + dir * 0.1

    params.to = inaccurate_target
    params.exclude = [self]
    params.collision_mask = 4294967295
    var result: Dictionary = space.intersect_ray(params)

    if result.size() > 0:
        var hit_position = result.get("position")
        var collider = result.get("collider")
        create_bullet_hole(result)
        if collider:
            if collider == player or collider.is_in_group("player"):
                player.take_damage(2)
                print("hit player")

func create_bullet_hole(hit: Dictionary) -> void :
    if not bullet_hole_sprite or hit.is_empty():
        return
    var hole: = bullet_hole_sprite.instantiate() as Node3D
    get_tree().current_scene.add_child(hole)

    hole.global_position = hit.position
    hole.look_at(hit.position + hit.normal, Vector3.UP)
    hole.global_position += hit.normal * 0.01

    var tween: = get_tree().create_tween()
    tween.tween_property(hole, "modulate:a", 0.0, 1.0)
    tween.tween_callback(hole.queue_free)
