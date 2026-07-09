extends CharacterBody3D
class_name GearWarden

var max_health: float
var current_health: float
var attack_damage: float
var attack_range: float
var attack_cooldown: float

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
var _animation_blocked: bool = false
var _is_shielding: bool = false

@onready var control_center: GearWardenControlCenter = $EnemyControlCenter

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("gear_wardens")
	control_center.setup(self)

func _process(delta: float) -> void:
	_update_animation()

func _update_animation() -> void:
	if _animation_blocked:
		return

	var attack_state = $AttackStateMachine.CURRENT_STATE.name
	if attack_state == "AttackingAttackState":
		_is_shielding = false
		return

	if attack_state == "ShieldingAttackState":
		if not _is_shielding:
			_is_shielding = true
		var shield_anim = "Idle_Shield"
		if animation_player.current_animation != shield_anim:
			animation_player.play(shield_anim)
		return

	_is_shielding = false
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

func block_animation_for(duration: float) -> void:
	_animation_blocked = true
	await get_tree().create_timer(duration).timeout
	_animation_blocked = false

func take_damage(amount: float) -> void:
	# Apply shield reduction if currently shielding
	if control_center and control_center.attack_state_machine.CURRENT_STATE.name == "ShieldingAttackState":
		amount *= control_center.shield_damage_multiplier
	current_health -= amount
	print(self, " took damage: ", amount, ", health left: ", current_health)
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
