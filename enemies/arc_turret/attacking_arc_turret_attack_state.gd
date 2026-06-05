extends DefaultEnemyAttackState
class_name AttackingArcTurretAttackState

var attack_timer: Timer
var attack_damage: float
var attack_range: float
var spread: float
var pivot: Node3D
var is_active: bool = false
var running_state: RunningArcTurretState

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	var turret = owner as ArcTurret
	if turret:
		attack_damage = turret.attack_damage
		attack_range = turret.attack_range
		spread = turret.spread
		pivot = owner.get_node("Pivot")
	running_state = owner.get_node("EnemyStateMachine/RunningEnemyState") as RunningArcTurretState
	if running_state:
		running_state.connect("can_attack", _on_can_attack)

func enter() -> void :
	super.enter()
	is_active = true
	if attack_timer and attack_timer.is_inside_tree():
		attack_timer.queue_free()
	attack_timer = Timer.new()
	attack_timer.one_shot = false
	attack_timer.wait_time = owner.attack_cooldown
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	owner.add_child(attack_timer)
	attack_timer.start()

	fire()

func exit() -> void :
	is_active = false
	if attack_timer:
		attack_timer.stop()
		attack_timer.queue_free()
		attack_timer = null

func _on_attack_timer_timeout() -> void :
	if not is_active:
		return
	fire()

func _on_can_attack(active: bool) -> void :
	if not is_active:
		return
	if not active:
		transition.emit("IdleAttackState")

func fire() -> void :
	if not is_active:
		return
	if not is_instance_valid(pivot) or not pivot.is_inside_tree():
		return
	if not running_state or not running_state.PLAYER:
		return

	var player = running_state.PLAYER
	var from: Vector3 = pivot.global_transform.origin
	var to_player = player.global_position - from
	var distance = to_player.length()
	if distance > attack_range:
		return

	var dir: Vector3 = to_player.normalized()
	var player_target_pos = player.global_position + Vector3(0, 1.5, 0)

	var spread_distance = distance * spread
	var inaccurate_target = player_target_pos + Vector3(
		randf_range( - spread_distance, spread_distance), 
		randf_range( - spread_distance * 0.5, spread_distance * 0.5), 
		randf_range( - spread_distance, spread_distance)
	)

	var space = owner.get_world_3d().direct_space_state
	var params: = PhysicsRayQueryParameters3D.new()
	params.from = from + dir * 0.1
	params.to = inaccurate_target
	params.exclude = [owner, pivot]
	params.collision_mask = 4294967295

	var result: Dictionary = space.intersect_ray(params)

	if result.size() > 0:
		var collider = result.get("collider")
		if collider == player or (collider is Node and collider.is_in_group("player")):
			player.take_damage(attack_damage)

	var anim_length = animation_player.get_animation("Spell_Simple_Shoot").length
	animation_player.get_animation("Spell_Simple_Shoot").loop_mode = Animation.LOOP_NONE
	animation_player.play("Spell_Simple_Shoot")
	owner.block_animation_for(anim_length)
