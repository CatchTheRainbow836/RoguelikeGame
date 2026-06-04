extends DefaultEnemyAttackState
class_name IdleVeinHarvesterAttackState

var harvester: VeinHarvester
var trap_cooldown: float = 0.0
var grenade_cooldown: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    harvester = owner as VeinHarvester

func physics_update(delta: float) -> void :
    trap_cooldown -= delta
    grenade_cooldown -= delta
    if trap_cooldown <= 0.0 and grenade_cooldown <= 0.0:
        if randf() < 0.5:
            transition.emit("AttackingAttackState")
            trap_cooldown = harvester.trap_cooldown
        else:
            transition.emit("ExplodeAttackState")
            grenade_cooldown = harvester.grenade_cooldown
    elif trap_cooldown <= 0.0:
        transition.emit("AttackingAttackState")
        trap_cooldown = harvester.trap_cooldown
    elif grenade_cooldown <= 0.0:
        transition.emit("ExplodeAttackState")
        grenade_cooldown = harvester.grenade_cooldown
