extends DefaultEnemyAttackState
class_name AttackingBronzeStatueAttackState

var attack_timer: Timer
var attack_damage: float
var attack_range: float
var attack_cooldown: float
var pivot: Node3D
var statue: BronzeStatue
var _last_attack_time: float = 0.0

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	statue = owner as BronzeStatue
	if statue:
		attack_damage = statue.attack_damage
		attack_range = statue.attack_range
		attack_cooldown = statue.attack_cooldown
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	statue.set_vulnerable(true)

	if attack_timer and attack_timer.is_inside_tree():
		attack_timer.queue_free()
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_finished)
	owner.add_child(attack_timer)
	attack_timer.start()

	perform_melee_attack()

func exit() -> void :
	statue.set_vulnerable(false)
	if attack_timer:
		attack_timer.stop()
		attack_timer.queue_free()

func physics_update(delta: float) -> void :
	pass

func _on_attack_finished() -> void :
	transition.emit("IdleAttackState")

func perform_melee_attack() -> void :
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_attack_time < attack_cooldown:
		return

	_last_attack_time = current_time

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
			body.take_damage(attack_damage)
			damaged_once = true
	)

	owner.add_child(hitbox)

	var forward = - pivot.global_transform.basis.z.normalized()
	hitbox.global_position = pivot.global_position + forward * 1.5

	var anim_length = animation_player.get_animation("Punch_Cross").length
	animation_player.get_animation("Punch_Cross").loop_mode = Animation.LOOP_NONE
	animation_player.play("Punch_Cross")
	statue.block_animation_for(anim_length)

	var remove_timer = Timer.new()
	remove_timer.one_shot = true
	remove_timer.wait_time = 0.2
	remove_timer.timeout.connect( func():
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	)
	hitbox.add_child(remove_timer)
	remove_timer.start()
