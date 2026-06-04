extends DefaultEnemyMovementState
class_name IdleMagmaVentState

var vent: MagmaVent
var _rotate_timer: float = 0.0
var _target_yaw: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    vent = owner as MagmaVent
    if vent:
        view_distance = vent.attack_range
        _target_yaw = pivot.rotation.y

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
        _rotate_timer -= delta
        if _rotate_timer <= 0.0:
            var current_yaw = pivot.rotation.y
            var max_delta = deg_to_rad(vent.idle_rotate_range)
            var new_yaw = current_yaw + randf_range( - max_delta, max_delta)
            _target_yaw = new_yaw
            _rotate_timer = vent.idle_rotate_interval

        var current_yaw = pivot.rotation.y
        var angle_diff = wrapf(_target_yaw - current_yaw, - PI, PI)
        var step = vent.idle_rotate_speed * delta
        if abs(angle_diff) > step:
            current_yaw += step * sign(angle_diff)
        else:
            current_yaw = _target_yaw
        pivot.rotation.y = current_yaw

    _velocity = Vector3.ZERO
    owner.velocity = _velocity
    owner.move_and_slide()
