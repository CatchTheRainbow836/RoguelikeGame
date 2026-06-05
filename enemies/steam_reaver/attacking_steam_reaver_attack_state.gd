extends DefaultEnemyAttackState
class_name AttackingSteamReaverAttackState

var attack_timer: Timer
var melee_damage: float
var attack_cooldown: float
var attack_range: float
var pivot: Node3D
var reaver: SteamReaver
var _charge_chance: float = 0.25

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	reaver = owner as SteamReaver
	if reaver:
		melee_damage = reaver.melee_damage
		attack_cooldown = reaver.attack_cooldown
		attack_range = reaver.attack_range
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	if attack_timer and attack_timer.is_inside_tree():
		attack_timer.queue_free()
	attack_timer = Timer.new()
	attack_timer.one_shot = false
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	owner.add_child(attack_timer)
	attack_timer.start()

	_on_attack_timer_timeout()

func exit() -> void :
	if attack_timer:
		attack_timer.stop()
		attack_timer.queue_free()

func physics_update(delta: float) -> void :
	if not PLAYER:
		transition.emit("IdleAttackState")
		return
	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist > attack_range or not running_enemy_state.can_see_player():
		transition.emit("IdleAttackState")

func _on_attack_timer_timeout() -> void :

	var should_charge = randf() < _charge_chance
	if should_charge:

		reaver.attack_state_machine.on_child_transition("ChargingAttackState")

		reaver.movement_state_machine.on_child_transition("ChargingEnemyState")
	else:
		perform_melee_attack()

func perform_melee_attack() -> void :
	if not is_instance_valid(owner) or not owner.is_inside_tree():
		return
	if not is_instance_valid(pivot) or not pivot.is_inside_tree():
		return

	var hitbox = Area3D.new()
	hitbox.name = "MeleeHitbox"
	hitbox.collision_mask = 2
	hitbox.collision_layer = 0

	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 1.0
	hitbox.add_child(shape)

	var damaged_once = false
	hitbox.body_entered.connect( func(body):
		if damaged_once:
			return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(melee_damage)
			damaged_once = true
	)

	owner.add_child(hitbox)

	var forward = - pivot.global_transform.basis.z.normalized()
	hitbox.global_position = pivot.global_position + forward * 1.5

	var anim_length = animation_player.get_animation("Punch_Cross").length
	animation_player.get_animation("Punch_Cross").loop_mode = Animation.LOOP_NONE
	animation_player.play("Punch_Cross")
	reaver.block_animation_for(anim_length)

	var remove_timer = Timer.new()
	remove_timer.one_shot = true
	remove_timer.wait_time = 0.2
	remove_timer.timeout.connect( func():
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	)
	hitbox.add_child(remove_timer)
	remove_timer.start()
