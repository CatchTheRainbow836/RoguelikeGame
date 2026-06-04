extends DefaultEnemyMovementState
class_name DashingDrillheadHuskState

var dash_speed: float
var dash_duration: float = 0.8
var dash_timer: float = 0.0
var dash_direction: Vector3
var husk: DrillheadHusk

func _ready() -> void :
    super._ready()
    await owner.ready
    husk = owner as DrillheadHusk
    if husk:
        dash_speed = husk.dash_speed

func enter() -> void :
    super.enter()
    if PLAYER:
        var to_player = PLAYER.global_position - owner.global_position
        to_player.y = 0.0
        if to_player.length() > 0:
            dash_direction = to_player.normalized()
        else:
            dash_direction = Vector3.FORWARD
        pivot.look_at(pivot.global_position + dash_direction, Vector3.UP)
    dash_timer = dash_duration

func exit() -> void :
    super.exit()

func physics_update(delta: float) -> void :
    dash_timer -= delta
    if dash_timer <= 0.0:
        transition.emit("RunningEnemyState")
        return

    _velocity.x = dash_direction.x * dash_speed
    _velocity.z = dash_direction.z * dash_speed
    _velocity.y = 0.0

    owner.velocity = _velocity
    owner.move_and_slide()
