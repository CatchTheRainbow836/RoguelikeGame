extends ArchonAttackState
class_name PhaseThreeIdleArchonAttackState

var boss: ArchonOfBlinding
var melee_cooldown: float = 0.0
var orb_cooldown: float = 0.0

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as ArchonOfBlinding

func physics_update(delta: float) -> void :
	melee_cooldown -= delta
	orb_cooldown -= delta
	var dist_to_player = owner.global_position.distance_to(PLAYER.global_position)
	if melee_cooldown <= 0.0 and dist_to_player <= boss.phase3_melee_range:
		transition.emit("MeleeAttackState")
		melee_cooldown = boss.phase3_melee_cooldown
	elif orb_cooldown <= 0.0:
		transition.emit("OrbAttackState")
		orb_cooldown = boss.phase3_orb_cooldown
