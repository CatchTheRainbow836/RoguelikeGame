extends DefaultEnemyAttackState
class_name IdleTidebearerAttackState

var attack_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	var bearer = owner as Tidebearer
	if bearer:
		attack_range = bearer.attack_range

func physics_update(delta: float) -> void :
	if not PLAYER:
		return
	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist <= attack_range and running_enemy_state.can_see_player():
		transition.emit("AttackingAttackState")
