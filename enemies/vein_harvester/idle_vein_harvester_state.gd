extends DefaultEnemyMovementState
class_name IdleVeinHarvesterState

var harvester: VeinHarvester

func _ready() -> void :
    super._ready()
    await owner.ready
    harvester = owner as VeinHarvester

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

    if harvester:
        _velocity = harvester.maintain_altitude(delta, _velocity)

    owner.velocity = _velocity
    owner.move_and_slide()
