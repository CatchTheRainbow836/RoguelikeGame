extends DefaultEnemyMovementState
class_name IdleCoreJuggerState

var jugger: CoreJugger

func _ready() -> void :
    super._ready()
    await owner.ready
    jugger = owner as CoreJugger
    if jugger:
        speed = jugger.speed
        accel = jugger.accel
        wander_radius = jugger.wander_radius
        view_distance = jugger.view_distance
        fov_degrees = jugger.fov_degrees

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
