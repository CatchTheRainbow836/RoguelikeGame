extends EdenRemnantAttackState
class_name PhaseTwoAttackingEdenRemnantAttackState

var attack_timer: Timer
var melee_damage: float
var attack_range: float
var attack_cooldown: float
var pivot: Node3D
var boss: EdenRemnant
var _last_attack_time: float = 0.0

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as EdenRemnant
	if boss:
		melee_damage = boss.phase2_melee_damage
		attack_range = boss.phase2_attack_range
		attack_cooldown = boss.phase2_attack_cooldown
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	if attack_timer and attack_timer.is_inside_tree():
		attack_timer.queue_free()
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = attack_cooldown
	attack_timer.timeout.connect(_on_attack_finished)
	owner.add_child(attack_timer)
	attack_timer.start()
	perform_melee_attack()
	boss.block_animation_for(0.5)
	animation_player.play("Punch_Cross")

func exit() -> void :
	if attack_timer:
		attack_timer.stop()
		attack_timer.queue_free()

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
		if damaged_once: return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(melee_damage)
			damaged_once = true
	)
	owner.add_child(hitbox)
	var forward = - pivot.global_transform.basis.z.normalized()
	hitbox.global_position = pivot.global_position + forward * 1.5
	var remove_timer = Timer.new()
	remove_timer.one_shot = true
	remove_timer.wait_time = 0.2
	remove_timer.timeout.connect( func():
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	)
	hitbox.add_child(remove_timer)
	remove_timer.start()
