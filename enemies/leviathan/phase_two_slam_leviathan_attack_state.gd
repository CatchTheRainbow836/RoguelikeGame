extends LeviathanAttackState
class_name PhaseTwoSlamLeviathanAttackState

var boss: Leviathan
var slam_damage: float
var stun_duration: float
var slam_radius: float
var pivot: Node3D
var is_active: bool = false

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as Leviathan
	if boss:
		slam_damage = boss.phase2_slam_damage
		stun_duration = boss.phase2_stun_duration
		slam_radius = boss.phase2_slam_radius
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	is_active = true

	await boss.surface_for_slam()

	perform_slam()
	boss.block_animation_for(0.5)
	boss.animation_player.play("OverhandThrow")

	await get_tree().create_timer(0.5).timeout

	await boss.dive_after_slam()

	transition.emit("IdleAttackState")

func exit() -> void :
	is_active = false

func perform_slam() -> void :
	var hitbox = Area3D.new()
	hitbox.name = "SlamHitbox"
	hitbox.collision_mask = 2
	hitbox.collision_layer = 0
	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = slam_radius
	hitbox.add_child(shape)
	var damaged_once = false
	hitbox.body_entered.connect( func(body):
		if damaged_once: return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(slam_damage)
			if body.has_method("stun"):
				body.stun(stun_duration)
			damaged_once = true
	)
	owner.add_child(hitbox)
	var forward = - pivot.global_transform.basis.z.normalized()
	hitbox.global_position = pivot.global_position + forward * 2.0
	var remove_timer = Timer.new()
	remove_timer.one_shot = true
	remove_timer.wait_time = 0.2
	remove_timer.timeout.connect( func():
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	)
	hitbox.add_child(remove_timer)
	remove_timer.start()
