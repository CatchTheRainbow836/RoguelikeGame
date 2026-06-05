extends DefaultEnemyAttackState
class_name IdleFungusBloomAttackState

var attack_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	var fungus = owner as FungusBloom
	if fungus:
		attack_range = fungus.attack_range

func physics_update(delta: float) -> void :
	if not PLAYER:
		return
	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist <= attack_range and running_enemy_state.can_see_player():
		transition.emit("AttackingAttackState")
