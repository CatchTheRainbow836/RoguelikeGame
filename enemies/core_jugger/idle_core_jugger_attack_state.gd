extends DefaultEnemyAttackState
class_name IdleCoreJuggerAttackState

var attack_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	var jugger = owner as CoreJugger
	if jugger:
		attack_range = jugger.attack_range

func physics_update(delta: float) -> void :
	if not PLAYER:
		return
	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist <= attack_range and running_enemy_state.can_see_player():
		transition.emit("AttackingAttackState")
