extends LeviathanAttackState
class_name PhaseThreeIdleLeviathanAttackState

var boss: Leviathan
var attack_cooldown_timer: float = 0.0

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as Leviathan

func physics_update(delta: float) -> void :
	attack_cooldown_timer -= delta
	if attack_cooldown_timer <= 0.0:
		var tidebearer_count = 0
		var enemies = get_tree().get_nodes_in_group("tidebearer")
		tidebearer_count = enemies.size()

		if tidebearer_count >= boss.phase3_max_tidebearers:
			transition.emit("PushAttackState")
		else:
			if randf() < 0.5:
				transition.emit("PushAttackState")
			else:
				transition.emit("SummonAttackState")
		attack_cooldown_timer = boss.phase3_attack_cooldown
