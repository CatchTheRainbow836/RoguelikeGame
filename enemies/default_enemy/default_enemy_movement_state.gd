class_name DefaultEnemyMovementState
extends State

var mesh_instance_3d: MeshInstance3D
var collision_shape_3d: CollisionShape3D
var pivot: Node3D
var navigation_agent_3d: NavigationAgent3D

var PLAYER: CharacterBody3D

@export var fov_degrees: float = 90.0
@export var view_distance: float = 20.0
@export var vision_check_interval: float = 0.2

@export var wander_radius: float = 8.0
@export var wander_interval: float = 2.5

@export var speed: float = 3.0
@export var accel: float = 10.0

@export var alertness_threshold: float = 0.5

var _vision_timer: float = 0.0
var _wander_timer: float = 0.0
var _target_wander: Vector3 = Vector3.ZERO
var _velocity: Vector3 = Vector3.ZERO
var is_player_visible: bool = false
var is_in_smoke: bool = false

func _ready() -> void :
    await owner.ready
    PLAYER = get_tree().get_first_node_in_group("player")
    owner = get_parent().get_parent()
    mesh_instance_3d = owner.get_node("MeshInstance3D")
    collision_shape_3d = owner.get_node("CollisionShape3D")
    pivot = owner.get_node("Pivot")
    navigation_agent_3d = owner.get_node("NavigationAgent3D")

    owner.add_to_group("enemies")

    await get_tree().process_frame

    navigation_agent_3d.max_speed = speed if "max_speed" in navigation_agent_3d else speed
    _wander_timer = 0.0
    _vision_timer = 0.0
    is_player_visible = false

func can_see_player() -> bool:
    if not PLAYER or not pivot:
        return false

    var visual_detected = false
    if not is_in_smoke:
        var to_player = PLAYER.global_transform.origin - pivot.global_transform.origin
        var dist = to_player.length()
        if dist <= view_distance:
            var forward = - pivot.global_transform.basis.z.normalized()
            var dir_norm = to_player.normalized()
            var angle_threshold = cos(deg_to_rad(fov_degrees * 0.5))
            if forward.dot(dir_norm) >= angle_threshold:
                var space = owner.get_world_3d().direct_space_state
                var params: = PhysicsRayQueryParameters3D.new()
                params.from = pivot.global_position + Vector3.UP * 0.5
                params.to = PLAYER.global_position + Vector3.UP * 1.0
                params.exclude = [owner, pivot]
                params.collision_mask = 4294967295
                var res: Dictionary = space.intersect_ray(params)
                if res.size() > 0 and res.get("collider") == PLAYER:
                    visual_detected = true

    var alertness = AlertnessManager.get_alert_value(owner.global_position)
    var sound_detected = alertness >= alertness_threshold

    return visual_detected or sound_detected

func _look_at_player_smooth(delta: float) -> void :
    if not pivot or not PLAYER:
        return

    var to_target = PLAYER.global_position - pivot.global_position
    to_target.y = 0.0

    if to_target.length_squared() > 0.001:
        var target_transform = pivot.global_transform.looking_at(
            pivot.global_position - to_target, 
            Vector3.UP, 
            true
        )

        pivot.global_transform.basis = pivot.global_transform.basis.slerp(
            target_transform.basis, 
            6.0 * delta
        )

func _pick_new_wander_target() -> void :
    if not navigation_agent_3d:
        return

    var origin = owner.global_position
    var offset = Vector3(
        randf_range( - wander_radius, wander_radius), 
        0, 
        randf_range( - wander_radius, wander_radius)
    )

    var candidate = origin + offset

    for i in range(5):
        navigation_agent_3d.target_position = candidate
        if not navigation_agent_3d.is_target_reachable():
            offset = offset * 0.7
            candidate = origin + offset
        else:
            break

func take_damage(damage_amount: float) -> void :
    pass
