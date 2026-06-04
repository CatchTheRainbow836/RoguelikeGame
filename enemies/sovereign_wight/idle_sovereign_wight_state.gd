extends DefaultEnemyMovementState
class_name IdleSovereignWightState

var wight: SovereignWight

func _ready() -> void :
    super._ready()
    await owner.ready
    wight = owner as SovereignWight
    if wight:
        speed = wight.speed
        accel = wight.accel
        wander_radius = wight.wander_radius
        view_distance = wight.view_distance
        fov_degrees = wight.fov_degrees

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
