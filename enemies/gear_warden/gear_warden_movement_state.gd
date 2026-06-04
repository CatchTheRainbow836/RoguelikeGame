extends DefaultEnemyMovementState
class_name GearWardenMovementState

var warden: GearWarden

func _ready() -> void :
    super._ready()
    await owner.ready
    warden = owner as GearWarden
    if warden:
        speed = warden.speed
        accel = warden.accel
        wander_radius = warden.wander_radius
        view_distance = warden.view_distance
        fov_degrees = warden.fov_degrees
