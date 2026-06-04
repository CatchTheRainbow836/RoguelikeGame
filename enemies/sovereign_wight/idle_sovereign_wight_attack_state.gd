extends DefaultEnemyAttackState
class_name IdleSovereignWightAttackState

var attack_cooldown: float
var last_attack_time: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    var wight = owner as SovereignWight
    if wight:
        attack_cooldown = wight.attack_cooldown

func physics_update(delta: float) -> void :
    pass
