extends DefaultEnemyAttackState
class_name IdleSludgeCrawlerAttackState

var attack_trigger_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	var crawler = owner as SludgeCrawler
	if crawler:
		attack_trigger_range = crawler.attack_trigger_range

func physics_update(delta: float) -> void :
	if not PLAYER:
		return
	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist <= attack_trigger_range and running_enemy_state.can_see_player():
		transition.emit("AttackingAttackState")
