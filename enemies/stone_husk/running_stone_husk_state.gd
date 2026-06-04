extends DefaultEnemyMovementState
class_name RunningStoneHuskState

var attack_range: float
var turn_speed: float
var husk: StoneHusk
var alert_timer: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    husk = owner as StoneHusk
    if husk:
        attack_range = husk.attack_range
        turn_speed = husk.turn_speed
        view_distance = attack_range

func enter() -> void :
    super.enter()
    alert_timer = husk.alert_duration

func physics_update(delta: float) -> void :
    _vision_timer -= delta
    if _vision_timer <= 0.0:
        is_player_visible = can_see_player()
        _vision_timer = vision_check_interval

    if PLAYER:
        var dist = owner.global_position.distance_to(PLAYER.global_position)
        husk.is_player_close = dist <= husk.shield_range

    if is_player_visible:
        alert_timer = husk.alert_duration
        _look_at_player_smooth(delta)
    else:
        alert_timer -= delta
        if alert_timer <= 0.0:
            transition.emit("IdleEnemyState")
            return

    _velocity = Vector3.ZERO
    owner.velocity = _velocity
    owner.move_and_slide()
