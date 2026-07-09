extends CharacterBody3D
class_name ArcTurret

var max_health: float
var current_health: float
var attack_damage: float
var attack_range: float
var attack_cooldown: float

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
var _animation_blocked: bool = false

@onready var control_center: ArcTurretControlCenter = $EnemyControlCenter

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("arc_turrets")
	control_center.setup(self)

func _process(delta: float) -> void:
	_update_animation()

func _update_animation() -> void:
	if _animation_blocked:
		return
	var attack_state = $AttackStateMachine.CURRENT_STATE.name
	if attack_state == "AttackingAttackState":
		return
	if animation_player.current_animation != "Fighting Idle":
		animation_player.play("Fighting Idle")

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
