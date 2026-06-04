extends DefaultEnemyAttackState
class_name IdleDrillheadHuskAttackState

var husk: DrillheadHusk
var dash_cooldown: float = 0.0
var shrapnel_cooldown: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    husk = owner as DrillheadHusk

func physics_update(delta: float) -> void :
    dash_cooldown -= delta
    shrapnel_cooldown -= delta

    if dash_cooldown <= 0.0 and shrapnel_cooldown <= 0.0:
        if randf() < 0.5:
            transition.emit("DashAttackState")
            dash_cooldown = husk.dash_cooldown
        else:
            transition.emit("ShrapnelAttackState")
            shrapnel_cooldown = husk.shrapnel_cooldown
    elif dash_cooldown <= 0.0:
        transition.emit("DashAttackState")
        dash_cooldown = husk.dash_cooldown
    elif shrapnel_cooldown <= 0.0:
        transition.emit("ShrapnelAttackState")
        shrapnel_cooldown = husk.shrapnel_cooldown
