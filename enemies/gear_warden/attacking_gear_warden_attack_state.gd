extends DefaultEnemyAttackState
class_name AttackingGearWardenAttackState

var _attack_timer: float = 0.0

func enter() -> void:
	perform_melee_attack("Punch_Cross")
	_attack_timer = 0.0

func physics_update(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= attack_cooldown:
		perform_melee_attack("Punch_Cross")
		_attack_timer = 0.0
