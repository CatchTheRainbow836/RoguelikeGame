extends FurnaceColossusAttackState
class_name PhaseTwoSlamFurnaceColossusAttackState

var attack_timer: Timer
var slam_damage: float
var stun_duration: float
var pivot: Node3D
var is_active: bool = false
var running_state: PhaseTwoRunningFurnaceColossusState

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer


func _ready() -> void :
	super._ready()
	await owner.ready
	var colossus = owner as FurnaceColossus
	if colossus:
		slam_damage = colossus.slam_damage
		stun_duration = colossus.stun_duration
		pivot = owner.get_node("Pivot")
	var phase_sm = owner.top_state_machine.CURRENT_STATE
	if phase_sm:
		running_state = phase_sm.get_node("EnemyStateMachine/RunningEnemyState") as PhaseTwoRunningFurnaceColossusState
		if running_state:
			running_state.connect("can_attack", _on_can_attack)

func enter() -> void :
	print("entered SlamAttackState (phase2)")
	is_active = true
	if attack_timer and attack_timer.is_inside_tree():
		attack_timer.queue_free()
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.wait_time = owner.attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	owner.add_child(attack_timer)
	attack_timer.start()
	_on_attack_timer_timeout()

func exit() -> void :
	print("exited SlamAttackState")
	is_active = false
	if attack_timer:
		attack_timer.stop()
		attack_timer.queue_free()
		attack_timer = null

	animation_player.stop()

func _on_attack_timer_timeout() -> void :
	if not is_active:
		return
	perform_slam()
	if is_active and attack_timer:
		attack_timer.start()

func _on_can_attack(active: bool) -> void :
	if not is_active:
		return
	if not active:
		transition.emit("IdleAttackState")

func perform_slam() -> void :
	if not is_active:
		return
	if not is_instance_valid(owner) or not owner.is_inside_tree():
		return
	if not is_instance_valid(pivot) or not pivot.is_inside_tree():
		return

	var hitbox = Area3D.new()
	hitbox.name = "SlamHitbox"
	hitbox.collision_mask = 2
	hitbox.collision_layer = 0

	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 1.5
	hitbox.add_child(shape)

	var forward = - pivot.global_transform.basis.z.normalized()


	var damaged_once = false
	hitbox.body_entered.connect( func(body):
		if damaged_once:
			return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(slam_damage)
			damaged_once = true
			if body.has_method("stun"):
				body.stun(stun_duration)
	)

	owner.add_child(hitbox)
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

	animation_player.get_animation("OverhandThrow").loop_mode = Animation.LOOP_NONE
	animation_player.play("OverhandThrow")
