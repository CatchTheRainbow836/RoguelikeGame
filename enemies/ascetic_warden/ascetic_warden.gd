extends CharacterBody3D
class_name AsceticWarden

@export var max_health: float = 120.0
@export var attack_damage: float = 15.0
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 1.5
@export var speed: float = 4.0
@export var accel: float = 8.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 20.0
@export var fov_degrees: float = 90.0
@export var alert_duration: float = 5.0
@export var teleport_range: float = 8.0
@export var teleport_delay: float = 0.3

var current_health: float
var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
@onready var collision_shape = $CollisionShape3D

func _ready() -> void :
	add_to_group("ascetic_warden")
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
		"TeleportEnemyState":
			anim_name = "Fighting Idle"
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
