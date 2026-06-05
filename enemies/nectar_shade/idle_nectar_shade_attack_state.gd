extends DefaultEnemyAttackState
class_name IdleNectarShadeAttackState

var heal_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	var shade = owner as NectarShade
	if shade:
		heal_range = shade.heal_range

func physics_update(delta: float) -> void :
	var enemies_in_range = false
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == owner:
			continue
		var is_enemy = enemy.is_in_group("enemies")
		if not is_enemy:
			continue
		var dist = owner.global_position.distance_to(enemy.global_position)
		if dist <= heal_range:
			enemies_in_range = true
			break

	if enemies_in_range:
		transition.emit("AttackingAttackState")
