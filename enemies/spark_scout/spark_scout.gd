extends CharacterBody3D
class_name SparkScout

var max_health: float
var current_health: float
var attack_damage: float
var attack_range: float
var attack_cooldown: float

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
var _animation_blocked: bool = false

@onready var control_center: SparkScoutControlCenter = $EnemyControlCenter

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("spark_scouts")
	control_center.setup(self)

func _process(delta: float) -> void:
	_update_animation()

func _update_animation() -> void:
	if _animation_blocked:
		return
	var attack_state = $AttackStateMachine.CURRENT_STATE.name
	if attack_state == "AttackingAttackState":
		return
	var movement_state = $EnemyStateMachine.CURRENT_STATE.name
	var anim_name = ""
	match movement_state:
		"IdleEnemyState", "WalkingEnemyState":
			anim_name = "Flying Forward"
		"RunningEnemyState":
			anim_name = "Flying Forward Super"
		_:
			return
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func block_animation_for(duration: float) -> void:
	_animation_blocked = true
	await get_tree().create_timer(duration).timeout
	_animation_blocked = false

func take_damage(amount: float) -> void:
	current_health -= amount
	print(self, " took damage: ", amount, ", health left: ", current_health)
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
