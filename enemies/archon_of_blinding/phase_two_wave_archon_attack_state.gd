extends ArchonAttackState
class_name PhaseTwoWaveArchonAttackState

var boss: ArchonOfBlinding
var wave_damage: float
var block_size: float
var wave_height: float
var tween_duration: float
var arena_center: Vector3
var arena_half_size: float = 28.0

var blocks: Dictionary = {}
var block_claims: Dictionary = {}
var block_areas: Dictionary = {}

var directions: Array = []
var wave_stripes: Dictionary = {}

var active_wave_count: int = 0
var _attack_token: int = 0
var _transitioned: bool = false


func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as ArchonOfBlinding
	if boss:
		wave_damage = boss.phase2_wave_damage
		block_size = boss.phase2_wave_block_size
		wave_height = boss.phase2_wave_height
		tween_duration = boss.phase2_wave_tween_duration
		arena_center = boss.arena_center


func enter() -> void :
	super.enter()

	_attack_token += 1
	_transitioned = false

	_cleanup_blocks()
	_create_blocks()

	var all_dirs = [
		"left_to_right", "right_to_left", "top_to_bottom", "bottom_to_top", 
		"top_right_to_bottom_left", "bottom_left_to_top_right", 
		"top_left_to_bottom_right", "bottom_right_to_top_left"
	]
	all_dirs.shuffle()
	directions = all_dirs.slice(0, 2)

	_setup_wave_stripes()

	active_wave_count = directions.size()
	for dir in directions:
		_process_wave(dir, _attack_token)


func _create_blocks() -> void :
	var start_x = arena_center.x - arena_half_size
	var start_z = arena_center.z - arena_half_size
	var grid_size = int(arena_half_size * 2.0 / block_size)

	for i in range(grid_size):
		for j in range(grid_size):
			var pos: = Vector2i(i, j)
			var x = start_x + i * block_size + block_size * 0.5
			var z = start_z + j * block_size + block_size * 0.5

			var block = MeshInstance3D.new()
			block.mesh = BoxMesh.new()
			block.mesh.size = Vector3(block_size, wave_height, block_size)

			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1, 1, 0, 0.6)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			block.material_override = material

			owner.get_parent().add_child(block)
			block.global_position = Vector3(x, -0.5, z)

			var light = OmniLight3D.new()
			light.omni_range = block_size
			light.light_color = Color.YELLOW
			light.light_energy = 3.0
			block.add_child(light)

			blocks[pos] = block
			block_claims[pos] = 0


func _setup_wave_stripes() -> void :
	var grid_size = int(arena_half_size * 2.0 / block_size)

	for dir in directions:
		var stripes: Array = []

		match dir:
			"left_to_right":
				for i in range(grid_size):
					var stripe: Array = []
					for j in range(grid_size):
						stripe.append(Vector2i(i, j))
					stripes.append(stripe)

			"right_to_left":
				for i in range(grid_size - 1, -1, -1):
					var stripe = []
					for j in range(grid_size):
						stripe.append(Vector2i(i, j))
					stripes.append(stripe)

			"top_to_bottom":
				for j in range(grid_size):
					var stripe = []
					for i in range(grid_size):
						stripe.append(Vector2i(i, j))
					stripes.append(stripe)

			"bottom_to_top":
				for j in range(grid_size - 1, -1, -1):
					var stripe = []
					for i in range(grid_size):
						stripe.append(Vector2i(i, j))
					stripes.append(stripe)

			"top_right_to_bottom_left":
				for s in range(grid_size * 2 - 1):
					var stripe = []
					for i in range(max(0, s - grid_size + 1), min(grid_size, s + 1)):
						var j = s - i
						if j >= 0 and j < grid_size:
							stripe.append(Vector2i(i, j))
					stripes.append(stripe)

			"bottom_left_to_top_right":
				for s in range(grid_size * 2 - 2, -1, -1):
					var stripe = []
					for i in range(max(0, s - grid_size + 1), min(grid_size, s + 1)):
						var j = s - i
						if j >= 0 and j < grid_size:
							stripe.append(Vector2i(i, j))
					stripes.append(stripe)

			"top_left_to_bottom_right":
				for d in range( - (grid_size - 1), grid_size):
					var stripe = []
					for i in range(grid_size):
						var j = i - d
						if j >= 0 and j < grid_size:
							stripe.append(Vector2i(i, j))
					stripes.append(stripe)

			"bottom_right_to_top_left":
				for d in range(grid_size - 1, - (grid_size - 1) - 1, -1):
					var stripe = []
					for i in range(grid_size):
						var j = i - d
						if j >= 0 and j < grid_size:
							stripe.append(Vector2i(i, j))
					stripes.append(stripe)

		wave_stripes[dir] = stripes


func _process_wave(dir: String, token: int) -> void :
	var stripes: Array = wave_stripes.get(dir, [])
	if stripes.is_empty():
		_wave_finished(token)
		return

	var delay_between: = 0.15
	var wave_width: = 2.0
	var stay_duration: = wave_width * delay_between

	for idx in range(stripes.size()):
		if token != _attack_token:
			return

		if idx > 0:
			await get_tree().create_timer(delay_between).timeout
			if token != _attack_token:
				return

		var stripe: Array = stripes[idx]
		_lift_stripe(stripe, token)
		_lower_stripe(stripe, stay_duration, token)

	await get_tree().create_timer(
		(stripes.size() - 1) * delay_between + stay_duration + tween_duration + 0.1
	).timeout

	if token != _attack_token:
		return

	_wave_finished(token)


func _wave_finished(token: int) -> void :
	if token != _attack_token:
		return

	active_wave_count -= 1
	if active_wave_count <= 0 and not _transitioned:
		_transitioned = true
		_cleanup_blocks()
		transition.emit("IdleAttackState")


func _lift_stripe(stripe: Array, token: int) -> void :
	if token != _attack_token:
		return

	for pos in stripe:
		var block: MeshInstance3D = blocks.get(pos)
		if not is_instance_valid(block):
			continue

		var claim_count: int = int(block_claims.get(pos, 0))
		block_claims[pos] = claim_count + 1

		if claim_count > 0:
			continue

		var area = Area3D.new()
		area.collision_mask = 2

		var shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(block_size, wave_height, block_size)
		shape.shape = box_shape

		area.add_child(shape)
		block.add_child(area)
		block_areas[pos] = area

		var damaged: = false
		area.body_entered.connect( func(body):
			if damaged:
				return
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(wave_damage)
				damaged = true
		)

		var tween = create_tween()
		tween.tween_property(block, "global_position:y", 0.0, tween_duration)


func _lower_stripe(stripe: Array, stay_duration: float, token: int) -> void :
	await get_tree().create_timer(stay_duration).timeout

	if token != _attack_token:
		return

	for pos in stripe:
		var block: MeshInstance3D = blocks.get(pos)
		if not is_instance_valid(block):
			continue

		var claim_count: int = int(block_claims.get(pos, 0))
		claim_count = maxi(claim_count - 1, 0)
		block_claims[pos] = claim_count

		if claim_count > 0:
			continue

		var tween = create_tween()
		tween.tween_property(block, "global_position:y", -0.5, tween_duration)

	await get_tree().create_timer(tween_duration).timeout

	if token != _attack_token:
		return

	for pos in stripe:
		var area: Area3D = block_areas.get(pos)
		if is_instance_valid(area):
			area.queue_free()
		block_areas.erase(pos)


func _cleanup_blocks() -> void :
	_attack_token += 1
	active_wave_count = 0
	directions.clear()
	wave_stripes.clear()
	block_claims.clear()
	block_areas.clear()

	for block in blocks.values():
		if is_instance_valid(block):
			block.queue_free()

	blocks.clear()


func exit() -> void :
	_cleanup_blocks()
