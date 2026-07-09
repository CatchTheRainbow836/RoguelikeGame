class_name DefaultEnemyAttackState
extends State

var owner_enemy: CharacterBody3D
var control_center: DefaultEnemyControlCenter
var animation_player: AnimationPlayer

var attack_damage: float
var attack_range: float
var attack_cooldown: float

var melee_hitbox: Area3D
var melee_shape: CollisionShape3D
var _last_attack_time: float = 0.0
var _attack_hit_done: bool = false

###Legacy
var PLAYER
var running_enemy_state
###

func _ready() -> void:
	await owner.ready
	owner_enemy = owner as CharacterBody3D
	if owner_enemy.has_node("EnemyControlCenter"):
		control_center = owner_enemy.get_node("EnemyControlCenter")
		attack_damage = control_center.attack_damage
		attack_range = control_center.attack_range
		attack_cooldown = control_center.attack_cooldown
	animation_player = owner_enemy.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

	if not melee_hitbox:
		melee_hitbox = Area3D.new()
		melee_hitbox.name = "MeleeHitbox"
		melee_hitbox.collision_mask = 2
		melee_hitbox.collision_layer = 0
		melee_shape = CollisionShape3D.new()
		melee_shape.shape = SphereShape3D.new()
		melee_shape.shape.radius = 1.0
		melee_hitbox.add_child(melee_shape)
		owner_enemy.add_child(melee_hitbox)
		melee_hitbox.monitoring = false
		melee_hitbox.monitorable = false
		melee_shape.disabled = true
		melee_hitbox.body_entered.connect(_on_melee_hit)

func perform_melee_attack(anim_name: String = "Punch_Cross") -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_attack_time < attack_cooldown:
		return
	_last_attack_time = current_time
	_attack_hit_done = false

	var pivot_node = owner_enemy.get_node("Pivot")
	var forward = -pivot_node.global_transform.basis.z.normalized()
	melee_hitbox.global_position = pivot_node.global_position + forward * 1.5
	melee_shape.disabled = false
	melee_hitbox.monitoring = true

	if animation_player:
		var original_length = animation_player.get_animation(anim_name).length
		var target_duration = attack_cooldown / 2.0
		var speed_scale = original_length / target_duration
		animation_player.speed_scale = speed_scale
		animation_player.play(anim_name)
		var actual_duration = original_length / speed_scale
		owner_enemy.block_animation_for(actual_duration)

		var disable_timer = get_tree().create_timer(0.2)
		disable_timer.timeout.connect(func():
			if is_instance_valid(melee_hitbox):
				melee_hitbox.monitoring = false
				melee_shape.disabled = true
		)

		var reset_timer = get_tree().create_timer(actual_duration)
		reset_timer.timeout.connect(func():
			if is_instance_valid(animation_player):
				animation_player.speed_scale = 1.0
		)

func _on_melee_hit(body: Node3D) -> void:
	if _attack_hit_done:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(attack_damage)
		_attack_hit_done = true
