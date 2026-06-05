extends ArchonAttackState
class_name PhaseTwoIdleArchonAttackState

var boss: ArchonOfBlinding
var summon_cooldown: float = 0.0
var wave_cooldown: float = 0.0

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as ArchonOfBlinding

func physics_update(delta: float) -> void :
	summon_cooldown -= delta
	wave_cooldown -= delta















	if wave_cooldown <= 0.0:
		transition.emit("WaveAttackState")
		wave_cooldown = boss.phase2_wave_cooldown
