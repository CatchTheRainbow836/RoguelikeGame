extends CharacterBody3D
class_name DrillheadHusk

@export var max_health: float = 50.0

@export var dash_damage: float = 15.0
@export var dash_speed: float = 18.0
@export var dash_range: float = 8.0
@export var dash_cooldown: float = 4.0

@export var shrapnel_damage: float = 8.0
@export var shrapnel_cooldown: float = 2.0
@export var shrapnel_range: float = 12.0
@export var shrapnel_speed: float = 20.0
@export var cone_radius: float = 0.5
@export var cone_length: float = 1.0

@export var speed: float = 5.0
@export var accel: float = 8.0
@export var turn_speed: float = 6.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 20.0
@export var fov_degrees: float = 90.0
@export var alert_duration: float = 5.0
@export var preferred_distance: float = 7.0
@export var strafe_speed: float = 2.0

var current_health: float
var _animation_blocked: bool = false
var is_dashing: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	add_to_group("drillhead_husk")
	current_health = max_health

func _process(delta: float) -> void :
	_update_animation()

func _update_animation() -> void :
	if _animation_blocked:
		return

	var attack_state = $AttackStateMachine.CURRENT_STATE.name
	if attack_state == "DashAttackState" or attack_state == "ShrapnelAttackState":
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
		"DashingEnemyState":
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
