extends DefaultEnemyAttackState
class_name AttackingArcTurretAttackState

var _attack_timer: float = 0.0

func enter() -> void:
	_attack_timer = 0.0

func physics_update(delta: float) -> void:
	_attack_timer += delta
	if _attack_timer >= attack_cooldown:
		perform_ranged_attack("Spell_Simple_Shoot", control_center.spread if control_center else 0.0)
		_attack_timer = 0.0
