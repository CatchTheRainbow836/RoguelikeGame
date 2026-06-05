extends CharacterBody3D
class_name SludgeCrawler

@export var max_health: float = 15.0
@export var trail_damage: float = 3.0
@export var trail_radius: float = 0.8
@export var trail_duration: float = 3.0
@export var trail_spawn_interval: float = 0.15
@export var attack_trigger_range: float = 12.0
@export var stop_distance: float = 2.5
@export var speed: float = 3.5
@export var accel: float = 8.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 20.0
@export var fov_degrees: float = 90.0
@export var alert_duration: float = 5.0

var current_health: float
var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	add_to_group("sludge_crawler")
	current_health = max_health

func _process(delta: float) -> void :
	_update_animation()

func _update_animation() -> void :
	if _animation_blocked:
		return

	var attack_state = $AttackStateMachine.CURRENT_STATE.name
	if attack_state == "AttackingAttackState":
		return

	var movement_state = $EnemyStateMachine.CURRENT_STATE.name
	var anim_name = ""
	match movement_state:
		"IdleEnemyState":
			anim_name = "Fighting Idle"
		"WalkingEnemyState":
			anim_name = "Walk"
		"RunningEnemyState":
			anim_name = "Sprint"
		_:
			return

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func block_animation_for(duration: float) -> void :
	_animation_blocked = true
	await get_tree().create_timer(duration).timeout
	_animation_blocked = false

func take_damage(amount: float) -> void :
	current_health -= amount
	print(self, " took damage: ", amount, ", health left: ", current_health)
	if current_health <= 0:
		die()

func die() -> void :
	queue_free()
