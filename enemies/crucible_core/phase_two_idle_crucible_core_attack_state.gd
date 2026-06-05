extends CrucibleCoreAttackState
class_name PhaseTwoIdleCrucibleCoreAttackState

var boss: CrucibleCore
var attack_cooldown: float = 0.0
var attacks: Array = ["SweepingAttackState", "WreckingAttackState", "BurstAttackState", "DropAttackState"]

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as CrucibleCore

func physics_update(delta: float) -> void :
	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		var random_attack = attacks[randi() % attacks.size()]
		transition.emit(random_attack)
		attack_cooldown = 5.0
