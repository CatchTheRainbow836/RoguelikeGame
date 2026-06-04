extends DefaultEnemyMovementState
class_name IdleTidebearerState

var bearer: Tidebearer

func _ready() -> void :
    super._ready()
    await owner.ready
    bearer = owner as Tidebearer
    if bearer:
        speed = bearer.speed
        accel = bearer.accel
        wander_radius = bearer.wander_radius
        view_distance = bearer.view_distance
        fov_degrees = bearer.fov_degrees

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
        transition.emit("WalkingEnemyState")

    owner.velocity = _velocity
    owner.move_and_slide()
