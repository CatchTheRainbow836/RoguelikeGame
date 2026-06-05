extends DefaultEnemyAttackState
class_name AttackingTidebearerAttackState

var attack_timer: Timer
var attack_damage: float
var attack_range: float
var attack_cooldown: float
var bearer: Tidebearer
var wall_speed: float
var wall_max_distance: float
var wall_width: float
var wall_height: float
var wall_thickness: float
var push_distance: float
var _last_attack_time: float = 0.0

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	bearer = owner as Tidebearer
	if bearer:
		attack_damage = bearer.attack_damage
		attack_range = bearer.attack_range
		attack_cooldown = bearer.attack_cooldown
		wall_speed = bearer.wall_speed
		wall_max_distance = bearer.wall_max_distance
		wall_width = bearer.wall_width
		wall_height = bearer.wall_height
		wall_thickness = bearer.wall_thickness
		push_distance = bearer.push_distance

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

	_cast_wall()

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
	_cast_wall()

func _cast_wall() -> void :
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - _last_attack_time < attack_cooldown:
		return

	if not running_enemy_state.PLAYER:
		return

	_last_attack_time = current_time

	var player = running_enemy_state.PLAYER
	var from = owner.global_position
	var direction = (player.global_position - from).normalized()
	direction.y = 0.0

	if direction.length() < 0.001:
		direction = - owner.get_node("Pivot").global_transform.basis.z.normalized()

	var wall_container = Node3D.new()
	wall_container.name = "WallContainer"
	owner.get_parent().add_child(wall_container)

	var wall_mesh = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(wall_width, wall_height, wall_thickness)
	wall_mesh.mesh = box_mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.2)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mesh.material_override = material
	wall_container.add_child(wall_mesh)
	wall_mesh.position = Vector3.ZERO

	var area = Area3D.new()
	area.collision_mask = 2
	area.collision_layer = 0
	area.monitoring = true
	area.monitorable = true

	var collision_shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(wall_width, wall_height, wall_thickness)
	collision_shape.shape = box_shape
	area.add_child(collision_shape)
	wall_container.add_child(area)
	area.position = Vector3.ZERO

	var spawn_offset = direction * (wall_thickness / 2.0 + 0.5)
	wall_container.global_position = from + spawn_offset
	wall_container.global_position.y = wall_height / 2.0

	var target_point = wall_container.global_position + direction
	if target_point.distance_to(wall_container.global_position) > 0.001:
		wall_container.look_at(target_point, Vector3.UP)

	var has_damaged: = false
	var pushed_by_id: Dictionary = {}
	var tracked_bodies: Dictionary = {}
	var travel_dist: = 0.0
	var push_duration: float = (push_distance * 2.0) / max(wall_speed, 0.001)

	area.body_entered.connect( func(body):
		if not body.is_in_group("player"):
			return

		tracked_bodies[body.get_instance_id()] = body

		if not has_damaged and body.has_method("take_damage"):
			body.take_damage(attack_damage)
			has_damaged = true
	)

	area.body_exited.connect( func(body):
		tracked_bodies.erase(body.get_instance_id())
	)

	var move_timer = Timer.new()
	move_timer.wait_time = 0.016
	move_timer.one_shot = false

	move_timer.timeout.connect( func():
		if not is_instance_valid(wall_container):
			move_timer.queue_free()
			return

		var dt: float = move_timer.wait_time
		var step = wall_speed * dt
		travel_dist += step

		wall_container.global_position += direction * step

		for id in tracked_bodies.keys():
			var body = tracked_bodies[id]
			if not is_instance_valid(body):
				tracked_bodies.erase(id)
				pushed_by_id.erase(id)
				continue

			if not body.is_in_group("player"):
				continue

			var state: Dictionary = pushed_by_id.get(id, {"elapsed": 0.0, "distance": 0.0})
			state["elapsed"] = float(state["elapsed"]) + dt

			var t: float = clamp(float(state["elapsed"]) / push_duration, 0.0, 1.0)
			var target_distance: float = push_distance * (2.0 * t - t * t)
			var pushed_so_far: float = float(state["distance"])
			var push_step: float = target_distance - pushed_so_far

			if push_step <= 0.0:
				pushed_by_id[id] = state
				continue

			push_step = min(push_step, push_distance - pushed_so_far)
			var push_vec: Vector3 = direction * push_step

			if body is CharacterBody3D:
				body.global_position += push_vec
			elif body is RigidBody3D:
				body.apply_central_impulse(push_vec / max(dt, 0.001))

			state["distance"] = pushed_so_far + push_step
			pushed_by_id[id] = state

		if travel_dist >= wall_max_distance:
			var fade_tween = create_tween()
			fade_tween.tween_property(material, "albedo_color:a", 0.0, 0.3)
			fade_tween.tween_callback(wall_container.queue_free)
			move_timer.queue_free()
			return
	)

	owner.add_child(move_timer)
	move_timer.start()

	var anim_length = animation_player.get_animation("Spell_Simple_Shoot").length
	animation_player.get_animation("Spell_Simple_Shoot").loop_mode = Animation.LOOP_NONE
	animation_player.play("Spell_Simple_Shoot")
	bearer.block_animation_for(anim_length)
