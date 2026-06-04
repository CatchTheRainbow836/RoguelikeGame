extends DefaultEnemyMovementState
class_name RunningMagmaVentState

var vent: MagmaVent
var turn_speed: float

func _ready() -> void :
    super._ready()
    await owner.ready
    vent = owner as MagmaVent
    if vent:
        turn_speed = vent.turn_speed
        view_distance = vent.attack_range

func physics_update(delta: float) -> void :
    _vision_timer -= delta
    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if is_player_visible:
        _look_at_player_smooth(delta)
    else:
        transition.emit("IdleEnemyState")
        return

    _velocity = Vector3.ZERO
    owner.velocity = _velocity
    owner.move_and_slide()
