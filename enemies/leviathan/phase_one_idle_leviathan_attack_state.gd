extends LeviathanAttackState
class_name PhaseOneIdleLeviathanAttackState

var boss: Leviathan
var attack_cooldown_timer: float = 0.0

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as Leviathan
	if boss:
		attack_cooldown_timer = 0.0

func physics_update(delta: float) -> void :
	attack_cooldown_timer -= delta
	if attack_cooldown_timer <= 0.0:
		transition.emit("SplashAttackState")
		attack_cooldown_timer = boss.phase1_attack_cooldown
