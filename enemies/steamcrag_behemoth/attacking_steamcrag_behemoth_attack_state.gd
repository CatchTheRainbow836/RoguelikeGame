extends DefaultEnemyAttackState
class_name AttackingSteamcragBehemothAttackState

var behemoth: SteamcragBehemoth
var melee_damage: float
var push_force: float
var push_distance: float
var pivot: Node3D

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	behemoth = owner as SteamcragBehemoth
	if behemoth:
		melee_damage = behemoth.melee_damage
		push_force = behemoth.push_force
		push_distance = behemoth.push_distance
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	perform_melee_attack()
	await get_tree().create_timer(0.5).timeout
	transition.emit("IdleAttackState")

func perform_melee_attack() -> void :
	var hitbox = Area3D.new()
	hitbox.name = "MeleeHitbox"
	hitbox.collision_mask = 2
	hitbox.collision_layer = 0
	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = 1.0
	hitbox.add_child(shape)

	var damaged = false
	hitbox.body_entered.connect( func(body):
		if damaged:
			return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(melee_damage)
			damaged = true
			var direction = (body.global_position - owner.global_position).normalized()
			direction.y = 0.0
			if direction.length() < 0.001:
				direction = - pivot.global_transform.basis.z.normalized()
			_push_player(body, direction)
	)

	owner.add_child(hitbox)
	var forward = - pivot.global_transform.basis.z.normalized()
	hitbox.global_position = pivot.global_position + forward * 1.5

	animation_player.play("Punch_Cross")
	behemoth.block_animation_for(0.5)

	var remove_timer = Timer.new()
	remove_timer.one_shot = true
	remove_timer.wait_time = 0.2
	remove_timer.timeout.connect( func():
		if is_instance_valid(hitbox):
			hitbox.queue_free()
	)
	hitbox.add_child(remove_timer)
	remove_timer.start()

func _push_player(player: CharacterBody3D, direction: Vector3) -> void :
	var target_pos = player.global_position + direction * push_distance
	var space = owner.get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.new()
	params.from = player.global_position
	params.to = target_pos
	params.exclude = [player, owner]
	var result = space.intersect_ray(params)
	if result:
		var hit_point = result.position
		var safe_distance = 0.2
		var new_dir = (hit_point - player.global_position).normalized()
		target_pos = hit_point - new_dir * safe_distance
	var tween = create_tween()
	tween.tween_property(player, "global_position", target_pos, 0.1)
