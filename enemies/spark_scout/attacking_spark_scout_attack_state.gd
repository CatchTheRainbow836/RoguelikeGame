extends DefaultEnemyAttackState
class_name AttackingSparkScoutAttackState

var attack_timer: Timer
#var attack_damage: float
#var attack_range: float
#var attack_cooldown: float
var spread: float
var pivot: Node3D
#var _last_attack_time: float = 0.0

#@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	var scout = owner as SparkScout
	if scout:
		attack_damage = scout.attack_damage
		attack_range = scout.attack_range
		attack_cooldown = scout.attack_cooldown
		spread = scout.spread
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


	perform_ranged_attack()

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
	perform_ranged_attack()

func perform_ranged_attack() -> void :
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_attack_time < attack_cooldown:
		return

	_last_attack_time = current_time

	if not is_instance_valid(pivot) or not pivot.is_inside_tree():
		return

	var player = PLAYER
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

	var anim = "Flying Forward Super"
	var anim_length = animation_player.get_animation(anim).length
	animation_player.get_animation(anim).loop_mode = Animation.LOOP_NONE
	animation_player.play(anim)
	owner.block_animation_for(anim_length)
