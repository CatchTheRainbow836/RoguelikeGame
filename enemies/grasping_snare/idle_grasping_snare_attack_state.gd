extends DefaultEnemyAttackState
class_name IdleGraspingSnareAttackState

var snare: GraspingSnare
var latch_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	snare = owner as GraspingSnare
	if snare:
		latch_range = snare.latch_range_horizontal

func physics_update(delta: float) -> void :
	if not PLAYER:
		return
	var dist_horizontal = Vector2(owner.global_position.x - PLAYER.global_position.x, 
								   owner.global_position.z - PLAYER.global_position.z).length()
	if dist_horizontal <= latch_range and not snare.is_latched:
		transition.emit("AttackingAttackState")
