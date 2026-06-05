extends LeviathanAttackState
class_name PhaseTwoIdleLeviathanAttackState

var boss: Leviathan
var attack_cooldown_timer: float = 0.0
var melee_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as Leviathan
	if boss:
		melee_range = boss.phase2_melee_range

func physics_update(delta: float) -> void :
	attack_cooldown_timer -= delta
	if attack_cooldown_timer <= 0.0:






		transition.emit("SlamAttackState")
		attack_cooldown_timer = boss.phase2_attack_cooldown
