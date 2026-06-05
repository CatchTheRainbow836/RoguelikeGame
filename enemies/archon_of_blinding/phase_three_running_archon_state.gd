extends ArchonMovementState
class_name PhaseThreeRunningArchonState

var boss: ArchonOfBlinding
var preferred_distance: float
var orbit_angles: Array = []
var clones: Array = []
var clone_animation_players: Array = []
var boss_animation_player: AnimationPlayer
var clones_visible: bool = false
var clone_visible_range: float = 8.0

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as ArchonOfBlinding
	if boss:
		speed = boss.phase3_speed
		accel = boss.phase3_accel
		view_distance = boss.phase1_view_distance
		fov_degrees = boss.phase1_fov_degrees
		preferred_distance = boss.phase3_preferred_distance
		clone_visible_range = boss.phase3_clone_visible_range
		boss_animation_player = boss.get_node("Pivot/exported-model/AnimationPlayer")

func enter() -> void :
	super.enter()
	var original_model = boss.get_node("Pivot/exported-model")
	var clone_count = boss.phase3_clone_count
	orbit_angles = [0.0, PI / 2, PI, 3 * PI / 2]
	for i in range(1, 4):
		var clone = original_model.duplicate()
		clone.name = "Clone_" + str(i - 1)
		for child in clone.get_children():
			if child is CollisionShape3D or child is Area3D:
				child.queue_free()
		var clone_anim = clone.get_node("AnimationPlayer") if clone.has_node("AnimationPlayer") else null
		if clone_anim:
			clone_animation_players.append(clone_anim)
		else:
			clone_animation_players.append(null)
		boss.get_node("Pivot").add_child(clone)
		clone.visible = false
		clones.append(clone)

func exit() -> void :
	for clone in clones:
		if is_instance_valid(clone):
			clone.queue_free()
	clones.clear()
	clone_animation_players.clear()
	orbit_angles.clear()
	clones_visible = false

func physics_update(delta: float) -> void :
	if not PLAYER:
		return

	var dist_to_player = boss.global_position.distance_to(PLAYER.global_position)
	var should_be_visible = dist_to_player <= clone_visible_range
	if should_be_visible and not clones_visible:
		clones_visible = true
		for clone in clones:
			if is_instance_valid(clone):
				clone.visible = true
	elif not should_be_visible and clones_visible:
		clones_visible = false
		for clone in clones:
			if is_instance_valid(clone):
				clone.visible = false

	for i in range(orbit_angles.size()):
		orbit_angles[i] += boss.phase3_orbit_speed * delta

	var boss_angle = orbit_angles[0]
	var boss_offset = Vector3(cos(boss_angle) * preferred_distance, 0, sin(boss_angle) * preferred_distance)
	var boss_target = PLAYER.global_position + boss_offset
	boss_target.y = boss.global_position.y

	var move_dir = (boss_target - boss.global_position).normalized()
	_velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
	_velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
	boss.velocity = _velocity
	boss.move_and_slide()

	var boss_to_player = (PLAYER.global_position - boss.global_position).normalized()
	if boss_to_player.length_squared() > 0.001:
		var pivot = boss.get_node("Pivot")
		pivot.look_at(pivot.global_position + boss_to_player, Vector3.UP)

	for idx in range(clones.size()):
		var clone = clones[idx]
		if not is_instance_valid(clone):
			continue
		var angle = orbit_angles[idx + 1]
		var offset = Vector3(cos(angle) * preferred_distance, 0, sin(angle) * preferred_distance)
		var clone_target = PLAYER.global_position + offset
		clone_target.y = boss.global_position.y
		clone.global_position = clone_target

		var to_player = (PLAYER.global_position - clone.global_position).normalized()
		var desired_forward: Vector3
		if angle == PI:
			desired_forward = - to_player
		elif angle == PI / 2:
			desired_forward = Vector3( - to_player.z, 0, to_player.x).normalized()
		elif angle == 3 * PI / 2:
			desired_forward = Vector3(to_player.z, 0, - to_player.x).normalized()
		else:
			desired_forward = to_player

		if desired_forward.length_squared() > 0.001:
			var target_look_point = clone.global_position - desired_forward
			clone.look_at(target_look_point, Vector3.UP)

func _process(delta: float) -> void :
	if not boss_animation_player or boss_animation_player.current_animation == "":
		return
	if not clones_visible:
		return
	var current_anim = boss_animation_player.current_animation
	var current_pos = boss_animation_player.current_animation_position
	var current_speed = boss_animation_player.speed_scale
	for anim_player in clone_animation_players:
		if anim_player and is_instance_valid(anim_player):
			if anim_player.current_animation != current_anim:
				anim_player.play(current_anim)
			anim_player.seek(current_pos)
			anim_player.speed_scale = current_speed
