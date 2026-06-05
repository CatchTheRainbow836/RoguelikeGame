extends DefaultEnemyAttackState
class_name IdleSandStalkerAttackState

var attack_range: float
var attack_cooldown: float = 0.0

func _ready() -> void :
	super._ready()
	await owner.ready
	var stalker = owner as SandStalker
	if stalker:
		attack_range = stalker.attack_range
		attack_cooldown = 0.0

func physics_update(delta: float) -> void :
	if attack_cooldown > 0:
		attack_cooldown -= delta

	if not PLAYER:
		return

	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist <= attack_range and running_enemy_state.can_see_player() and attack_cooldown <= 0:
		transition.emit("AttackingAttackState")
