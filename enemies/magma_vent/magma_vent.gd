extends CharacterBody3D
class_name MagmaVent

@export var max_health: float = 70.0
@export var attack_damage: float = 8.0
@export var attack_range: float = 12.0
@export var cone_radius: float = 1.0
@export var cone_offset: float = 0.5
@export var turn_speed: float = 6.0

@export var idle_rotate_speed: float = 2.0
@export var idle_rotate_interval: float = 3.0
@export var idle_rotate_range: float = 180.0

var current_health: float
var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	add_to_group("magma_vent")
	current_health = max_health

func _process(delta: float) -> void :
	_update_animation()

func _update_animation() -> void :
	if _animation_blocked:
		return

	var attack_state = $AttackStateMachine.CURRENT_STATE.name
	if attack_state == "AttackingAttackState":
		return

	var anim_name = "Fighting Idle"
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
