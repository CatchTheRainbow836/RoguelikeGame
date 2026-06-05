extends DefaultEnemyAttackState
class_name IdleHaloSentryAttackState

var sentry: HaloSentry
var melee_cooldown_timer: float = 0.0

func _ready() -> void :
	super._ready()
	await owner.ready
	sentry = owner as HaloSentry

func physics_update(delta: float) -> void :
	melee_cooldown_timer -= delta
	if sentry.shield_active and melee_cooldown_timer <= 0.0:
		var dist = owner.global_position.distance_to(PLAYER.global_position)
		if dist <= sentry.melee_range and running_enemy_state.can_see_player():
			transition.emit("MeleeAttackState")
			melee_cooldown_timer = sentry.melee_cooldown
