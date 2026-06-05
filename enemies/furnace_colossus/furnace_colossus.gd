extends CharacterBody3D
class_name FurnaceColossus


@export var max_health: float = 500.0
var current_health: float


@export var phase2_threshold: float = 0.5
@export var phase3_threshold: float = 0.25

@export var phase1_speed: float = 2.0
@export var phase2_speed: float = 2.0
@export var phase3_speed: float = 4.0
@export var accel: float = 8.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 10000.0
@export var fov_degrees: float = 360.0
@export var alert_duration: float = 20.0

@export var stomp_damage: float = 15.0
@export var sweep_damage: float = 20.0
@export var slam_damage: float = 25.0
@export var stun_duration: float = 1.0
@export var ranged_damage: float = 10.0
@export var splash_damage: float = 5.0
@export var attack_cooldown: float = 2.0
@export var attack_range: float = 3.0

@export var arc_turret_scene: PackedScene
@export var summon_count: int = 3
@export var summon_radius: float = 5.0

@export var splash_count: int = 4
@export var splash_radius: float = 0.75
@export var splash_duration: float = 5.0

var top_state_machine: StateMachine

var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer


func _ready() -> void :
	add_to_group("furnace_colossus")
	add_to_group("boss_enemies")
	current_health = max_health
	top_state_machine = $FurnaceColossusStateMachine
	top_state_machine.on_child_transition("PhaseOneStateMachine")

func take_damage(amount: float) -> void :
	current_health -= amount
	print("took damage: ", amount, ", current health: ", current_health)

	var health_percent = current_health / max_health
	if health_percent <= phase3_threshold:
		top_state_machine.on_child_transition("PhaseThreeStateMachine")
	elif health_percent <= phase2_threshold:
		top_state_machine.on_child_transition("PhaseTwoStateMachine")

	if current_health <= 0:
		die()

func die() -> void :
	queue_free()

func _update_animation() -> void :
	if _animation_blocked:
		return

	var phase_sm = top_state_machine.CURRENT_STATE
	if not phase_sm:
		return
	var attack_sm = phase_sm.get_node("AttackStateMachine")
	var attack_state = attack_sm.CURRENT_STATE.name if attack_sm else ""

	if attack_state == "AttackingAttackState" or attack_state == "SweepingAttackState" or \
attack_state == "SlamAttackState" or attack_state == "SummonAttackState" or \
attack_state == "SplashingAttackState":
		return

	var movement_sm = phase_sm.get_node("EnemyStateMachine")
	var movement_state = movement_sm.CURRENT_STATE.name if movement_sm else ""

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
