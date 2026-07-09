extends Node

# Constants from NavigationRegion3D
const W: int = 8
const WALL_HEIGHT: int = 4
const GRID_SIZE: int = 20
const ARENA_RADIUS: int = 3

# Constants from TestSpawner
const RENDER_DISTANCE_STEPS: int = 15

# Enemy Preloads
const SCRAP_CRAWLER = preload("uid://c3edd0nr0blp6")
"""
const SPARK_SCOUT = preload("uid://c60lmfg5ysnad")
const GEAR_WARDEN = preload("uid://c5aofok1mcuvb")
const ARC_TURRET = preload("uid://dj54fnm4b1khp")
const STEAM_REAVER = preload("uid://3ta633hexlh1")
const CORE_JUGGER = preload("uid://oxwpi0r4aasv")
const FURNACE_COLOSSUS = preload("uid://k717v1s4pymn")

const THORNED_GARDENER = preload("uid://cae3q18ilresa")
const PETAL_FLYER = preload("uid://2klbrijsf4n8")
const NECTAR_SHADE = preload("uid://dtjibidtcmvi4")
const BRONZE_STATUE = preload("uid://dev7cn4bffq23")
const BLOOM_HERALD = preload("uid://dis5wn068wwr")
const SOVEREIGN_WIGHT = preload("uid://doya48sf5n632")
const EDEN_REMNANT = preload("uid://b3ps66ppclemw")

const GUTTER_RAT = preload("uid://co088hvpj8355")
const SLUDGE_CRAWLER = preload("uid://d2xjifqwdrrbk")
const LEECH_HUSK = preload("uid://cp2de42611kw1")
const MIDDEN_SPITTER = preload("uid://dar5wa3t6d2qf")
const FUNGUS_BLOOM = preload("uid://bx6nvxmoag1p8")
const TIDEBEARER = preload("uid://cre0yjtinf5h2")
const LEVIATHAN = preload("uid://vdoackdtn5fx")

const VOTIVE_WISP = preload("uid://c1fgdj26ij1u3")
const LUMINOUS_SENTINEL = preload("uid://cnox0xq1pu13m")
const SAND_STALKER = preload("uid://ciydi5vmpodea")
const STONE_HUSK = preload("uid://2ak10c36ibld")
const HALO_SENTRY = preload("uid://1y1x1ql7w5uj")
const ASCETIC_WARDEN = preload("uid://cik1qq7h7eaqg")
const ARCHON_OF_BLINDING = preload("uid://c5ks8rdcp1b78")

const GRASPING_SNARE = preload("uid://d276f423ceud3")
const SLAG_MITE = preload("uid://cdpgbybnjn0nt")
const MAGMA_VENT = preload("uid://cc5nct3p37kux")
const DRILLHEAD_HUSK = preload("uid://cicny0lttecf2")
const STEAMCRAG_BEHEMOTH = preload("uid://dweefp20aumai")
const VEIN_HARVESTER = preload("uid://d0x8tljcdlxgt")
const CRUCIBLE_CORE = preload("uid://duvfjokukixcv")
"""

const INDICATOR_SCENE = preload("uid://bnny3ninl1l72")

# Exported Variables
@export var wall_scene: PackedScene = preload("uid://b31dsd0jxadqv")
@export var floor_scene: PackedScene = preload("uid://c6p6jsidjwune")
@export var roof_scene: PackedScene = preload("uid://usbhsma4k6fu")
@export var button_scene: PackedScene = preload("uid://bkj57vle36mp")

const DIRECT_FALLOFF_FACTOR: float = 5.0
const INDIRECT_FALLOFF_FACTOR: float = 2.5
const INDIRECT_INTENSITY_RATIO: float = 0.3
const DETECTION_THRESHOLD: float = 0.5
const ALERT_LIFETIME_SCALE: float = 1.0
const ALERT_MIN_LIFETIME: float = 0.2
const ALERT_EXPIRE_UPDATE_INTERVAL: float = 0.1
const PLAYER_ALERT_INTERVAL: float = 0.1

const ALERT_CUBE_HEIGHT: float = 0.1
const ALERT_CUBE_Y_OFFSET: float = 0.05
const ALERT_VISUAL_UPDATE_INTERVAL: float = 0.1

var _alerts: Array = []
var _alert_grids_dirty: bool = true

var _direct_grid: Dictionary = {}    # cell -> max direct value
var _indirect_grid: Dictionary = {}  # cell -> max indirect value
var _combined_grid: Dictionary = {}  # cell -> max combined value

var _alert_visual_holder: Node3D = null
var _alert_cubes: Dictionary = {}    # cell -> MeshInstance3D (only for cells currently above threshold)
var _visual_update_timer: float = 0.0
var _expire_update_timer: float = 0.0

# ------------------------------------------------------------
# Original Level Manager State
# ------------------------------------------------------------

# Navigation State
var grid: Array = []
var visited: Array = []
var stack: Array = []
var solution: Dictionary = {}
var adj: Dictionary = {}

var walls: Dictionary = {}
var floors: Dictionary = {}
var roofs: Dictionary = {}

var player: CharacterBody3D = null
var player_start_cell: Vector2 = Vector2(0, 0)

var current_elevator: Dictionary = {}
var can_ascend: bool = false
var arena_center_cell: Vector2 = Vector2(-1, -1)
var is_boss_spawned: bool = false

# Spawner State
enum Floor {
	RUSTWORKS,
	SHOP,
	TWILIGHT_GARDENS,
	FLOODED_SEWERS,
	SUN_SCORCHED_LABYRINTH,
	SMOLDERING_TUNNELS
}

var floor_data: Dictionary = {
	Floor.RUSTWORKS: {
		"type": "combat",
		"low_tier": [SCRAP_CRAWLER]
	}
}

"""
var floor_data: Dictionary = {
	Floor.RUSTWORKS: {
		"type": "combat",
		"low_tier": [SCRAP_CRAWLER, SPARK_SCOUT],
		"mid_tier": [GEAR_WARDEN, ARC_TURRET],
		"upper_tier": [STEAM_REAVER, CORE_JUGGER],
		"boss_tier": [FURNACE_COLOSSUS]
	},
	Floor.SHOP: {
		"type": "shop",
		"low_tier": [],
		"mid_tier": [],
		"upper_tier": [],
		"boss_tier": []
	},
	Floor.TWILIGHT_GARDENS: {
		"type": "combat",
		"low_tier": [THORNED_GARDENER, PETAL_FLYER],
		"mid_tier": [NECTAR_SHADE, BRONZE_STATUE],
		"upper_tier": [BLOOM_HERALD, SOVEREIGN_WIGHT],
		"boss_tier": [EDEN_REMNANT]
	},
	Floor.FLOODED_SEWERS: {
		"type": "combat",
		"low_tier": [GUTTER_RAT, SLUDGE_CRAWLER],
		"mid_tier": [LEECH_HUSK, MIDDEN_SPITTER],
		"upper_tier": [FUNGUS_BLOOM, TIDEBEARER],
		"boss_tier": [LEVIATHAN]
	},
	Floor.SUN_SCORCHED_LABYRINTH: {
		"type": "combat",
		"low_tier": [VOTIVE_WISP, LUMINOUS_SENTINEL],
		"mid_tier": [SAND_STALKER, STONE_HUSK],
		"upper_tier": [HALO_SENTRY, ASCETIC_WARDEN],
		"boss_tier": [ARCHON_OF_BLINDING]
	},
	Floor.SMOLDERING_TUNNELS: {
		"type": "combat",
		"low_tier": [GRASPING_SNARE, SLAG_MITE],
		"mid_tier": [MAGMA_VENT, DRILLHEAD_HUSK],
		"upper_tier": [STEAMCRAG_BEHEMOTH, VEIN_HARVESTER],
		"boss_tier": [CRUCIBLE_CORE]
	}
}
"""
var current_floor: Floor = Floor.RUSTWORKS
var current_floor_type: String = "combat"
var low_tier: Array = []
var mid_tier: Array = []
var upper_tier: Array = []
var boss_tier: Array = []

var max_enemies: int = 30
var current_enemy_count: int = 0
var navigation_ready: bool = false
var update_timer: float = 0.0
var update_interval: float = 0.5
var active_cells: Array = []
var departure_nodes

var spawner_node: Node = null
var boss_fight_active: bool = false
var enemy_spawning_locked: bool = false
var current_button_cell: Vector2 = Vector2(-1, -1)
var current_boss: Node3D = null
var current_indicator: Node3D = null

# Active References
var nav_region: NavigationRegion3D = null
var world_root: Node = null 

signal button_destroyed(cell: Vector2)
signal maze_changed()

func _ready() -> void:
	randomize()
	call_deferred("deferred_init")

func deferred_init() -> void:
	print("LevelManager: Starting deferred initialization...")
	var main = get_tree().current_scene
	if not main:
		push_error("LevelManager: No current scene found!")
		return

	# Locate critical nodes with more robust searching
	world_root = main.find_child("WorldStructures", true, false)
	if not world_root:
		printerr("LevelManager: WorldStructures node not found!")
		return
	
	nav_region = world_root.find_child("NavigationRegion3D", true, false)
	if not nav_region:
		printerr("LevelManager: NavigationRegion3D not found!")
		return

	spawner_node = main.find_child("Spawner", true, false)
	if not spawner_node:
		printerr("LevelManager: Spawner node not found!")
		return

	player = get_tree().get_first_node_in_group("player")
	print("LevelManager: Found critical nodes. Initializing floor...")

	# Initialize floor
	set_floor(Floor.RUSTWORKS)
	
	# Build initial maze
	build_grid(0, 0)
	carve_out_maze(Vector2(0, 0))
	build_3d_maze()
	print("LevelManager: Maze geometry built.")
	
	await get_tree().process_frame
	
	setup_initial_elevator()
	print("LevelManager: Elevator setup triggered.")
	if current_elevator.is_empty():
		printerr("LevelManager: CRITICAL ERROR - Elevator setup failed to populate current_elevator!")
	else:
		print("LevelManager: Elevator confirmed at cell: ", current_elevator["cell"])
	
	await get_tree().process_frame
	
	rebake_navigation()
	await nav_region.bake_finished
	navigation_ready = true
	print("LevelManager: Navigation mesh baked.")
	
	# Start spawner logic
	if current_floor_type == "combat":
		print("LevelManager: Spawning initial enemies...")
		for i in range(max_enemies):
			spawn_enemy_if_needed()
			
	# --- Alert system setup ---
	_setup_alert_system()
	
	print("LevelManager: Initialization finished.")
	
func _process(delta: float) -> void:
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_active_enemies()

	if boss_fight_active:
		return

	if current_floor_type == "combat" and get_child_count() < max_enemies:
		spawn_enemy_if_needed()
		
	# Alert updates (no timers, uses delta directly)
	_update_alerts_expiry(delta)
	_update_alert_visuals(delta)

# ------------------------------------------------------------
# Alert System Implementation
# ------------------------------------------------------------
func _setup_alert_system() -> void:
	# Visual holder
	_alert_visual_holder = Node3D.new()
	_alert_visual_holder.name = "AlertVisuals"
	add_child(_alert_visual_holder)
	# Grids start empty
	_clear_alert_grids()

func add_alert(position: Vector3, intensity: float, lifetime: float = -1.0) -> void:
	var cell = get_cell_from_world(position)
	if lifetime < 0:
		lifetime = max(intensity * ALERT_LIFETIME_SCALE, ALERT_MIN_LIFETIME)
	
	# Precompute direct sound reachable cells via BFS
	var direct_vals = _precompute_direct(cell, intensity)
	
	_alerts.append({
		"cell": cell,
		"intensity": intensity,
		"lifetime": lifetime,
		"direct_values": direct_vals
	})
	_alert_grids_dirty = true

func get_alert_value(world_position: Vector3) -> float:
	var target_cell = get_cell_from_world(world_position)
	if _alert_grids_dirty:
		_rebuild_alert_grids()
	var val = _combined_grid.get(target_cell, 0.0)
	if val >= DETECTION_THRESHOLD:
		return val
	return 0.0

func _precompute_direct(origin_cell: Vector2, intensity: float) -> Dictionary:
	var direct_vals = {}
	var falloff_dist = intensity * DIRECT_FALLOFF_FACTOR
	if falloff_dist <= 0:
		return direct_vals
	# BFS to find shortest steps to all reachable cells
	var visited = {}
	var queue = [origin_cell]
	visited[origin_cell] = 0
	while queue.size() > 0:
		var current = queue.pop_front()
		var steps = visited[current]
		var dist = steps * W
		var val = intensity * exp(-dist / falloff_dist)
		if val >= DETECTION_THRESHOLD:
			direct_vals[current] = val
		# continue BFS to neighbours even if value is below threshold? No, we can stop expanding if current value already below threshold, but since value decays, neighbours will be even lower. So we break expansion for this branch.
		if val < DETECTION_THRESHOLD:
			continue
		for neighbor in adj.get(current, []):
			if not visited.has(neighbor):
				visited[neighbor] = steps + 1
				queue.append(neighbor)
	return direct_vals

func _rebuild_alert_grids() -> void:
	_direct_grid.clear()
	_indirect_grid.clear()
	_combined_grid.clear()
	
	# Iterate active alerts
	for alert in _alerts:
		var origin_cell = alert["cell"]
		var intensity = alert["intensity"]
		var direct_vals = alert["direct_values"]
		# Direct contributions
		for cell in direct_vals:
			var val = direct_vals[cell]
			if val > _direct_grid.get(cell, 0.0):
				_direct_grid[cell] = val
		
		# Indirect contributions: compute for all cells within a radius where value > threshold
		var indirect_intensity = intensity * INDIRECT_INTENSITY_RATIO
		var falloff_dist = intensity * INDIRECT_FALLOFF_FACTOR
		if falloff_dist > 0:
			# Determine max distance from threshold: value = indirect_intensity * exp(-dist/falloff_dist) > DETECTION_THRESHOLD
			# => dist < -falloff_dist * ln(DETECTION_THRESHOLD/indirect_intensity)
			# but only if indirect_intensity > threshold. If not, no indirect at all.
			if indirect_intensity > DETECTION_THRESHOLD:
				var max_dist = -falloff_dist * log(DETECTION_THRESHOLD / indirect_intensity)
				# Search all grid cells within max_dist in world-space (Euclidean)
				for target_cell in grid:
					var dx = target_cell.x - origin_cell.x
					var dz = target_cell.y - origin_cell.y
					var dist = sqrt(dx*dx + dz*dz)
					if dist <= max_dist:
						var val = indirect_intensity * exp(-dist / falloff_dist)
						if val > _indirect_grid.get(target_cell, 0.0):
							_indirect_grid[target_cell] = val
	
	# Combine
	for cell in grid:
		var d = _direct_grid.get(cell, 0.0)
		var i = _indirect_grid.get(cell, 0.0)
		_combined_grid[cell] = max(d, i)
	
	_alert_grids_dirty = false

func _update_alerts_expiry(delta: float) -> void:
	_expire_update_timer += delta
	if _expire_update_timer < ALERT_EXPIRE_UPDATE_INTERVAL:
		return
	_expire_update_timer = 0.0
	var changed = false
	for i in range(_alerts.size() - 1, -1, -1):
		_alerts[i].lifetime -= ALERT_EXPIRE_UPDATE_INTERVAL
		if _alerts[i].lifetime <= 0.0:
			_alerts.remove_at(i)
			changed = true
	if changed:
		_alert_grids_dirty = true

func _clear_alerts() -> void:
	_alerts.clear()
	_clear_alert_grids()
	_clear_all_alert_cubes()

func _clear_alert_grids() -> void:
	_direct_grid.clear()
	_indirect_grid.clear()
	_combined_grid.clear()
	_alert_grids_dirty = false

# ------------------------------------------------------------
# Alert Visualisation
# ------------------------------------------------------------
func _update_alert_visuals(delta: float) -> void:
	_visual_update_timer += delta
	if _visual_update_timer < ALERT_VISUAL_UPDATE_INTERVAL:
		return
	_visual_update_timer = 0.0
	
	if _alert_grids_dirty:
		_rebuild_alert_grids()
	
	# Determine which cells currently need cubes (value >= threshold)
	var needed_cells = {}
	for cell in _combined_grid:
		if _combined_grid[cell] >= DETECTION_THRESHOLD:
			needed_cells[cell] = _combined_grid[cell]
	
	# Remove cubes for cells that are no longer above threshold
	for cell in _alert_cubes.keys():
		if not needed_cells.has(cell):
			var cube = _alert_cubes[cell]
			if is_instance_valid(cube):
				cube.queue_free()
			# Use safer deletion from dict by marking, then loop after
			_alert_cubes.erase(cell)  # Will modify dict during iteration? We're iterating keys, safe to erase inside? Godot allows, but we'll collect keys to delete.
	
	# We'll re-iterate properly: collect to_remove first
	var to_remove = []
	for cell in _alert_cubes:
		if not needed_cells.has(cell):
			to_remove.append(cell)
	for cell in to_remove:
		var cube = _alert_cubes[cell]
		if is_instance_valid(cube):
			cube.queue_free()
		_alert_cubes.erase(cell)
	
	# Add or update cubes for needed cells
	for cell in needed_cells:
		var value = needed_cells[cell]
		if not _alert_cubes.has(cell):
			# Create new cube
			var cube = MeshInstance3D.new()
			var box = BoxMesh.new()
			box.size = Vector3(W, ALERT_CUBE_HEIGHT, W)
			cube.mesh = box
			cube.position = Vector3(cell.x, ALERT_CUBE_Y_OFFSET, cell.y)
			var mat = StandardMaterial3D.new()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			cube.material_override = mat
			_alert_visual_holder.add_child(cube)
			_alert_cubes[cell] = cube
		# Update color
		var cube = _alert_cubes[cell]
		if is_instance_valid(cube):
			cube.visible = true
			# Map value from threshold up to some max (clamp) for alpha
			# Use intensity scaling: max expected value around intensity of alert, but we can map relative to 2.0 for bright red
			var intensity = clamp((value - DETECTION_THRESHOLD) / 2.0, 0.0, 1.0)
			var alpha = lerp(0.2, 1.0, intensity)
			cube.material_override.albedo_color = Color(1, 0, 0, alpha)
	
	# Hide any cubes that remain in _alert_cubes but not in needed_cells? Should be none after removal.
	# For safety, iterate and hide if not needed
	for cell in _alert_cubes:
		if not needed_cells.has(cell):
			var cube = _alert_cubes[cell]
			if is_instance_valid(cube):
				cube.visible = false

func _clear_all_alert_cubes() -> void:
	for cube in _alert_cubes.values():
		if is_instance_valid(cube):
			cube.queue_free()
	_alert_cubes.clear()

# ------------------------------------------------------------
# Rest of original Level Manager (unchanged except maze change clean‑up)
# ------------------------------------------------------------
func rebake_navigation() -> void:
	if not nav_region:
		printerr("LevelManager: Cannot bake - nav_region is null!")
		return
	
	if not nav_region.navigation_mesh:
		print("LevelManager: NavigationMesh missing, creating new one.")
		nav_region.navigation_mesh = NavigationMesh.new()
	
	print("LevelManager: Navigation bake function reached!")
	navigation_ready = false
	
	await get_tree().process_frame
	
	print("LevelManager: Baking started...")
	nav_region.bake_navigation_mesh(false)
	await nav_region.bake_finished
	print("LevelManager: Baking completed.")
	
	navigation_ready = true
	
	var map_rid: RID = nav_region.get_navigation_map()
	var enemies: = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var nav_agent: = enemy.get_node_or_null("NavAgent")
		if nav_agent:
			nav_agent.set_navigation_map(map_rid)
			nav_agent.call_deferred("get_next_path_position")

func get_arena_center_position() -> Vector3:
	if arena_center_cell == Vector2(-1, -1):
		return Vector3.ZERO
	return Vector3(arena_center_cell.x, 0.0, arena_center_cell.y)

func build_grid(x_start: int, y_start: int) -> void:
	var y = y_start
	for i in range(GRID_SIZE):
		var x = x_start
		for j in range(GRID_SIZE):
			var cell = Vector2(x, y)
			grid.append(cell)
			adj[cell] = []
			x += W
		y += W

func remove_wall(a: Vector2, b: Vector2) -> void:
	adj[a].append(b)
	adj[b].append(a)

func carve_out_maze(start: Vector2) -> void:
	var x = start.x
	var y = start.y
	stack.append(start)
	visited.append(start)
	while stack.size() > 0:
		var cell_dirs: = []
		var right = Vector2(x + W, y)
		var left = Vector2(x - W, y)
		var down = Vector2(x, y + W)
		var up = Vector2(x, y - W)
		if not visited.has(right) and grid.has(right): cell_dirs.append("right")
		if not visited.has(left) and grid.has(left): cell_dirs.append("left")
		if not visited.has(down) and grid.has(down): cell_dirs.append("down")
		if not visited.has(up) and grid.has(up): cell_dirs.append("up")
		if cell_dirs.size() > 0:
			var chosen = cell_dirs[randi() % cell_dirs.size()]
			var nx = x
			var ny = y
			if chosen == "right": nx += W
			elif chosen == "left": nx -= W
			elif chosen == "down": ny += W
			elif chosen == "up": ny -= W
			var from = Vector2(x, y)
			var to = Vector2(nx, ny)
			remove_wall(from, to)
			solution[to] = from
			x = nx
			y = ny
			visited.append(to)
			stack.append(to)
		else:
			var back = stack.pop_back()
			x = back.x
			y = back.y

func build_3d_maze() -> void:
	var effective_roof_scene = roof_scene if roof_scene else floor_scene
	for cell in grid:
		if floor_scene:
			var f = floor_scene.instantiate()
			f.position = Vector3(cell.x, 0, cell.y)
			nav_region.add_child(f)
			f.add_to_group("maze")
			floors[cell] = f

		if effective_roof_scene:
			var r = effective_roof_scene.instantiate()
			r.position = Vector3(cell.x, WALL_HEIGHT, cell.y)
			nav_region.add_child(r)
			r.add_to_group("maze")
			roofs[cell] = r
		var dirs = {
			"right": Vector2(W, 0), 
			"left": Vector2( - W, 0), 
			"down": Vector2(0, W), 
			"up": Vector2(0, - W)
		}
		for d in dirs.keys():
			var neighbor = cell + dirs[d]
			if not adj[cell].has(neighbor):
				spawn_wall(cell, d)

func spawn_wall(cell: Vector2, dir: String) -> void:
	if not wall_scene: return
	var w = wall_scene.instantiate()
	var pos: = Vector3(cell.x, WALL_HEIGHT / 2, cell.y)
	if dir == "right":
		pos.x += W / 2
		w.scale = Vector3(0.2, WALL_HEIGHT, W)
	elif dir == "left":
		pos.x -= W / 2
		w.scale = Vector3(0.2, WALL_HEIGHT, W)
	elif dir == "down":
		pos.z += W / 2
		w.scale = Vector3(W, WALL_HEIGHT, 0.2)
	elif dir == "up":
		pos.z -= W / 2
		w.scale = Vector3(W, WALL_HEIGHT, 0.2)
	w.position = pos
	
	var mesh_instance: MeshInstance3D = null
	if w is MeshInstance3D:
		mesh_instance = w
	else:
		for child in w.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	if mesh_instance:
		var source_mat: Material = null
		if mesh_instance.material_override:
			source_mat = mesh_instance.material_override
		else:
			var mesh = mesh_instance.mesh
			if mesh and mesh.get_surface_count() > 0:
				source_mat = mesh.surface_get_material(0)
		if source_mat:
			var mat: = source_mat.duplicate()
			mesh_instance.material_override = mat
			if mat is StandardMaterial3D:
				var base_uv: = Vector3(3, 2, 3)
				if dir == "right" or dir == "left":
					mat.uv1_scale = Vector3(base_uv.x * w.scale.z, base_uv.y * w.scale.y, base_uv.z * w.scale.x)
				else:
					mat.uv1_scale = Vector3(base_uv.x * w.scale.x, base_uv.y * w.scale.y, base_uv.z * w.scale.z)
	nav_region.add_child(w)
	w.add_to_group("maze")
	if not walls.has(cell):
		walls[cell] = {}
	walls[cell][dir] = w

func setup_initial_elevator() -> void:
	var min_x = ARENA_RADIUS * W
	var max_x = (GRID_SIZE - 1 - ARENA_RADIUS) * W
	var min_y = ARENA_RADIUS * W
	var max_y = (GRID_SIZE - 1 - ARENA_RADIUS) * W

	var candidates = []
	for cell in grid:
		if cell.x >= min_x and cell.x <= max_x and cell.y >= min_y and cell.y <= max_y:
			if cell.distance_squared_to(player_start_cell) >= 4:
				candidates.append(cell)

	if candidates.is_empty():
		candidates = grid

	var chosen = candidates[randi() % candidates.size()]
	create_elevator_at(chosen)

func create_elevator_at(cell: Vector2) -> void:
	print("Creating elevator at cell: ", cell)
	var area = Area3D.new()
	area.collision_mask = 2
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(W, 1, W)
	collision.shape = shape
	area.add_child(collision)
	area.position = Vector3(cell.x, 0.5, cell.y)
	world_root.add_child(area)
	area.monitoring = false
	area.body_entered.connect(_on_elevator_entered.bind(area, cell))

	var visual = create_elevator_visual(cell)
	world_root.add_child(visual)
	visual.add_to_group("elevator_visual")

	if button_scene:
		var button = button_scene.instantiate()
		button.position = Vector3(cell.x, 0.5, cell.y)
		world_root.add_child(button)
		button.add_to_group("elevator_button")
		if button.has_signal("died"):
			button.died.connect(_on_button_died.bind(cell))
		else:
			button.tree_exited.connect(_on_button_died.bind(cell))
		current_elevator = {"area": area, "cell": cell, "visual": visual, "button": button}
	else:
		push_error("No button scene assigned!")
		current_elevator = {"area": area, "cell": cell, "visual": visual}

	can_ascend = false

func _on_button_died(cell: Vector2) -> void:
	print("Button destroyed at ", cell)
	current_elevator.erase("button")
	button_destroyed.emit(cell)
	
	# Pass through to spawner logic
	_on_button_destroyed_in_manager(cell)

func _on_elevator_entered(body: Node, area: Area3D, cell: Vector2) -> void:
	if not can_ascend:
		print("Elevator not ready – defeat the boss first!")
		return
	print("elevator entered successfully by player")
	
	# Clean up indicators
	var indicators = get_tree().get_nodes_in_group("elevator_indicator")
	for ind in indicators:
		if is_instance_valid(ind):
			ind.queue_free()
	
	# Transition to next floor
	await transition_to_next_floor()

func transition_to_next_floor() -> void:
	print("LevelManager: Starting level transition...")
	
	# 5-second elevator ride
	print("LevelManager: Elevator ride started (5s)...")
	await get_tree().create_timer(5.0).timeout
	print("LevelManager: Elevator ride finished.")
	
	# Clear alerts (issue 8)
	_clear_alerts()
	
	# 1. Clear All Extraneous Entities
	print("LevelManager: Clearing old enemies...")
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_enemy_count = 0
	
	# 2. Clear the Existing Maze Geometry
	print("LevelManager: Clearing old maze...")
	clear_maze()
	
	# Reset state
	grid.clear()
	adj.clear()
	visited.clear()
	stack.clear()
	solution.clear()
	walls.clear()
	floors.clear()
	roofs.clear()
	boss_fight_active = false
	current_elevator.clear()
	
	await get_tree().process_frame
	
	# 3. Progress and Regenerate the New Maze
	print("LevelManager: Advancing to next floor...")
	var next_floor = (current_floor + 1) % floor_data.size()
	set_floor(next_floor)
	
	print("LevelManager: Starting next floor generation...")
	build_grid(0, 0)
	carve_out_maze(Vector2(0, 0))
	build_3d_maze()
	
	await get_tree().process_frame
	
	setup_initial_elevator()
	rebake_navigation()
	await nav_region.bake_finished
	
	if current_floor_type == "combat":
		for i in range(max_enemies):
			spawn_enemy_if_needed()
			
	print("LevelManager: Transition complete.")

func create_departure_enclosure(cell: Vector2) -> Array:
	var nodes = []
	if floor_scene:
		var f = floor_scene.instantiate()
		f.position = Vector3(cell.x, 0, cell.y)
		world_root.add_child(f)
		f.add_to_group("temp_elevator")
		nodes.append(f)
	var effective_roof = roof_scene if roof_scene else floor_scene
	if effective_roof:
		var r = effective_roof.instantiate()
		r.position = Vector3(cell.x, WALL_HEIGHT, cell.y)
		world_root.add_child(r)
		r.add_to_group("temp_elevator")
		nodes.append(r)
	var dirs = ["right", "left", "down", "up"]
	for d in dirs:
		var w = create_temp_wall(cell, d)
		if w:
			nodes.append(w)
	return nodes

func create_arrival_walls(cell: Vector2, adj_data: Dictionary) -> Array:
	var nodes = []
	var dirs = {
		"right": Vector2(W, 0), 
		"left": Vector2( - W, 0), 
		"down": Vector2(0, W), 
		"up": Vector2(0, - W)
	}
	for d in dirs.keys():
		var neighbor = cell + dirs[d]
		if grid.has(neighbor) and adj_data[cell].has(neighbor):
			var w = create_temp_wall(cell, d)
			if w:
				nodes.append(w)
	return nodes

func create_temp_wall(cell: Vector2, dir: String) -> Node3D:
	if not wall_scene:
		return null
	var w = wall_scene.instantiate()
	var pos: = Vector3(cell.x, WALL_HEIGHT / 2, cell.y)
	if dir == "right":
		pos.x += W / 2
		w.scale = Vector3(0.2, WALL_HEIGHT, W)
	elif dir == "left":
		pos.x -= W / 2
		w.scale = Vector3(0.2, WALL_HEIGHT, W)
	elif dir == "down":
		pos.z += W / 2
		w.scale = Vector3(W, WALL_HEIGHT, 0.2)
	elif dir == "up":
		pos.z -= W / 2
		w.scale = Vector3(W, WALL_HEIGHT, 0.2)
	w.position = pos
	world_root.add_child(w)
	w.add_to_group("temp_elevator")
	apply_wall_texture_scaling(w, dir)
	return w

func clear_maze():
	var maze_nodes = get_tree().get_nodes_in_group("maze")
	for node in maze_nodes:
		if is_instance_valid(node):
			node.queue_free()
	walls.clear()
	floors.clear()
	roofs.clear()

func pick_random_cell(exclude: Array = []) -> Vector2:
	var candidates = grid.duplicate()
	if not exclude.is_empty():
		candidates = candidates.filter( func(c): return c not in exclude)
	return candidates[randi() % candidates.size()]


func apply_wall_texture_scaling(wall_node: Node3D, dir: String) -> void:
	var mesh_instance: MeshInstance3D = null
	if wall_node is MeshInstance3D:
		mesh_instance = wall_node
	else:
		for child in wall_node.get_children():
			if child is MeshInstance3D:
				mesh_instance = child
				break
	if not mesh_instance:
		return
	var source_mat: Material = null
	if mesh_instance.material_override:
		source_mat = mesh_instance.material_override
	else:
		var mesh = mesh_instance.mesh
		if mesh and mesh.get_surface_count() > 0:
			source_mat = mesh.surface_get_material(0)
	if source_mat:
		var mat: = source_mat.duplicate()
		mesh_instance.material_override = mat
		if mat is StandardMaterial3D:
			var base_uv: = Vector3(3, 2, 3)
			var scale = wall_node.scale
			if dir == "right" or dir == "left":
				mat.uv1_scale = Vector3(base_uv.x * scale.z, base_uv.y * scale.y, base_uv.z * scale.x)
			else:
				mat.uv1_scale = Vector3(base_uv.x * scale.x, base_uv.y * scale.y, base_uv.z * scale.z)

func get_elevator_cell() -> Vector2:
	return current_elevator.get("cell", Vector2(-1, -1))

func get_cell_from_world(world_pos: Vector3) -> Vector2:
	var cell_x = round(world_pos.x / W) * W
	var cell_z = round(world_pos.z / W) * W
	return Vector2(cell_x, cell_z)

func get_arena_cells(center_cell: Vector2, radius: int) -> Array:
	var cells = []
	for dx in range( - radius, radius + 1):
		for dy in range( - radius, radius + 1):
			var c = center_cell + Vector2(dx * W, dy * W)
			if grid.has(c):
				cells.append(c)
	return cells

func remove_arena_walls(center_cell: Vector2, radius: int) -> void:
	arena_center_cell = center_cell
	var cells_in_arena = get_arena_cells(center_cell, radius)
	var dir_vectors = {
		"right": Vector2(W, 0), 
		"left": Vector2( - W, 0), 
		"down": Vector2(0, W), 
		"up": Vector2(0, - W)
	}
	for cell in cells_in_arena:
		for dir in dir_vectors.keys():
			var neighbor = cell + dir_vectors[dir]
			if neighbor in cells_in_arena:
				if not adj[cell].has(neighbor):
					if walls.has(cell) and walls[cell].has(dir):
						var wall_node = walls[cell][dir]
						if is_instance_valid(wall_node):
							wall_node.queue_free()
						walls[cell].erase(dir)
					var opposite_dir = {"right": "left", "left": "right", "down": "up", "up": "down"}[dir]
					if walls.has(neighbor) and walls[neighbor].has(opposite_dir):
						var wall_node2 = walls[neighbor][opposite_dir]
						if is_instance_valid(wall_node2):
							wall_node2.queue_free()
						walls[neighbor].erase(opposite_dir)
					remove_wall(cell, neighbor)
	for cell in cells_in_arena:
		for dir in dir_vectors.keys():
			var neighbor = cell + dir_vectors[dir]
			if neighbor not in cells_in_arena:
				if adj[cell].has(neighbor):
					adj[cell].erase(neighbor)
					if adj.has(neighbor):
						adj[neighbor].erase(cell)
					if not (walls.has(cell) and walls[cell].has(dir)):
						spawn_wall(cell, dir)
					var opposite_dir = {"right": "left", "left": "right", "down": "up", "up": "down"}[dir]
					if grid.has(neighbor) and not (walls.has(neighbor) and walls[neighbor].has(opposite_dir)):
						spawn_wall(neighbor, opposite_dir)
	await get_tree().process_frame
	rebake_navigation()

func enable_elevator() -> void:
	can_ascend = true
	if current_elevator.has("area") and is_instance_valid(current_elevator["area"]):
		current_elevator["area"].monitoring = true

func disable_elevator_area() -> void:
	if current_elevator.has("area") and is_instance_valid(current_elevator["area"]):
		current_elevator["area"].monitoring = false
		can_ascend = false

func _set_node_collision_enabled(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D:
		node.disabled = not enabled
	if node is CollisionPolygon3D:
		node.disabled = not enabled
	if node is Area3D:
		node.monitoring = enabled
		node.monitorable = enabled
	for child in node.get_children():
		_set_node_collision_enabled(child, enabled)

func set_maze_visibility(active_cells_list: Array) -> void:
	for cell in floors:
		var visible_val = cell in active_cells_list
		if boss_fight_active:
			visible_val = true
		if is_instance_valid(floors[cell]):
			floors[cell].visible = visible_val
			_set_node_collision_enabled(floors[cell], visible_val)
	for cell in roofs:
		var visible_val = cell in active_cells_list
		if boss_fight_active:
			visible_val = true
		if is_instance_valid(roofs[cell]):
			roofs[cell].visible = visible_val
			_set_node_collision_enabled(roofs[cell], visible_val)
	for cell in walls:
		# Rendering Override: If boss fight is active, force visibility for arena walls
		var visible_val = cell in active_cells_list
		if boss_fight_active:
			visible_val = true
			
		for dir in walls[cell]:
			if is_instance_valid(walls[cell][dir]):
				walls[cell][dir].visible = visible_val
				_set_node_collision_enabled(walls[cell][dir], visible_val)
				
func get_cells_in_render_distance(start_cell: Vector2, max_steps: int) -> Array:
	if max_steps < 0:
		return []
	var visited_cells = {}
	var queue = [start_cell]
	visited_cells[start_cell] = true
	var distance = {start_cell: 0}
	var result = [start_cell]
	while queue:
		var current = queue.pop_front()
		var current_dist = distance[current]
		if current_dist >= max_steps:
			continue
		for neighbor in adj.get(current, []):
			if not visited_cells.has(neighbor):
				visited_cells[neighbor] = true
				distance[neighbor] = current_dist + 1
				queue.append(neighbor)
				result.append(neighbor)
	return result

func find_path(start: Vector2, end: Vector2) -> Array:
	if start == end:
		return [start]
	var queue = [start]
	var visited_cells = {start: true}
	var parent = {}
	while queue:
		var current = queue.pop_front()
		for neighbor in adj.get(current, []):
			if not visited_cells.has(neighbor):
				visited_cells[neighbor] = true
				parent[neighbor] = current
				if neighbor == end:
					var path = [end]
					var p = end
					while p != start:
						p = parent[p]
						path.append(p)
					path.reverse()
					return path
				queue.append(neighbor)
	return []

func spawn_enemy_if_needed() -> void:
	if boss_fight_active or enemy_spawning_locked:
		return
	if get_tree().get_nodes_in_group("enemies").size() >= max_enemies:
		return
	if not current_elevator.has("cell"):
		return
	var elevator_cell = current_elevator["cell"]
	var player_cell = get_cell_from_world(player.global_position)
	var path = find_path(player_cell, elevator_cell)
	if path.is_empty():
		if low_tier.size() > 0:
			spawn_enemy_of_tier(low_tier)
		return
	var cell_x = (randi() % GRID_SIZE) * W
	var cell_z = (randi() % GRID_SIZE) * W
	var spawn_cell = Vector2(cell_x, cell_z)
	var min_dist = INF
	for p in path:
		var d = abs(p.x - spawn_cell.x) + abs(p.y - spawn_cell.y)
		if d < min_dist:
			min_dist = d
	var tier
	if min_dist <= 4:
		tier = low_tier
	elif min_dist <= 10:
		tier = mid_tier
	else:
		tier = upper_tier
	if tier.size() > 0:
		spawn_enemy_of_tier(tier, spawn_cell)

func spawn_enemy_of_tier(tier: Array, cell: Vector2 = Vector2(-1, -1)) -> void:
	if cell == Vector2(-1, -1):
		var rand_idx = randi() % grid.size()
		cell = grid[rand_idx]
		print("spawn_enemy_of_tier: Using fallback cell: ", cell)
	else:
		print("spawn_enemy_of_tier: Using calculated cell: ", cell)
	
	var enemy_scene = tier[randi() % tier.size()]
	var enemy = enemy_scene.instantiate()
	var offset_x = randf_range(-1.0, 1.0)
	var offset_z = randf_range(-1.0, 1.0)
	var spawn_pos = Vector3(cell.x + offset_x, 0 , cell.y + offset_z)
	enemy.position = spawn_pos
	
	if spawner_node:
		spawner_node.add_child(enemy)
		print("spawn_enemy_of_tier: Parented to Spawner at ", spawn_pos)
	else:
		world_root.add_child(enemy)
		print("spawn_enemy_of_tier: Parented to WorldRoot at ", spawn_pos)
		
	_make_materials_unique(enemy)
	enemy.add_to_group("enemies")
	current_enemy_count += 1
	enemy.tree_exited.connect(func(): current_enemy_count -= 1)

func _make_materials_unique(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		var material = mesh_instance.get_surface_override_material(0)
		if not material:
			var mesh = mesh_instance.mesh
			if mesh and mesh.surface_get_material(0):
				material = mesh.surface_get_material(0)
		if material:
			var unique_material = material.duplicate()
			mesh_instance.set_surface_override_material(0, unique_material)
	for child in node.get_children():
		_make_materials_unique(child)

func update_active_enemies() -> void:
	if not nav_region or not player:
		return
	var player_cell = get_cell_from_world(player.global_position)
	active_cells = get_cells_in_render_distance(player_cell, RENDER_DISTANCE_STEPS)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == current_boss or enemy == current_indicator:
			continue
		var enemy_cell = get_cell_from_world(enemy.global_position)
		var should_be_active = enemy_cell in active_cells
		set_enemy_active(enemy, should_be_active)
	set_maze_visibility(active_cells)

func set_enemy_active(enemy: Node, active: bool) -> void:
	var target_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if enemy.process_mode != target_mode:
		enemy.process_mode = target_mode
		enemy.visible = active
	_set_collision_enabled(enemy, active)

func _set_collision_enabled(node: Node, enabled: bool) -> void:
	if node is CollisionShape3D:
		node.disabled = not enabled
	if node is CollisionPolygon3D:
		node.disabled = not enabled
	if node is Area3D:
		node.monitoring = enabled
		node.monitorable = enabled
	for child in node.get_children():
		_set_collision_enabled(child, enabled)

var walls_to_animate = []
func _on_button_destroyed_in_manager(cell: Vector2) -> void:
	print("Button destroyed at cell ", cell)
	if current_floor_type == "combat":
		# 1. Immediate Floor Enemy Purge
		print("Purging all enemies...")
		for enemy in get_tree().get_nodes_in_group("enemies").duplicate():
			if is_instance_valid(enemy):
				enemy.queue_free()
		
		print("Starting boss fight")
		boss_fight_active = true
		current_button_cell = cell
		
		# 2. Collect internal walls (exclude perimeter)
		var arena_cells = get_arena_cells(cell, 3)
		for c in arena_cells:
			# Check if cell is on the perimeter (radius 3)
			var dx = abs(c.x - cell.x) / W
			var dy = abs(c.y - cell.y) / W
			if dx < 3 and dy < 3:
				if walls.has(c):
					for dir in walls[c]:
						var w = walls[c][dir]
						if is_instance_valid(w):
							# 3. Group Swap for Rendering Override
							w.remove_from_group("walls")
							w.add_to_group("walls_to_remove")
							walls_to_animate.append(w)
		
	await remove_arena_walls_keep_internal(cell, 3)
	
	await animate_arena_walls_falling(cell, walls_to_animate)
	
	var radius = 3
	var dir_vectors = {
		"right": Vector2(W, 0), 
		"left": Vector2(-W, 0), 
		"down": Vector2(0, W), 
		"up": Vector2(0, -W)
	}
	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if abs(dx) == radius or abs(dy) == radius:
				var border_cell = cell + Vector2(dx * W, dy * W)
				if grid.has(border_cell):
					for dir in dir_vectors:
						var neighbor = border_cell + dir_vectors[dir]
						if not grid.has(neighbor):
							# Check if wall exists in this direction
							var wall_exists = walls.has(border_cell) and walls[border_cell].has(dir) and is_instance_valid(walls[border_cell][dir])
							if not wall_exists:
								print("Generating missing perimeter wall at: ", border_cell, " dir: ", dir)
								spawn_wall(border_cell, dir)
		
		if is_boss_spawned:
			return
		is_boss_spawned = true
		print("Spawning boss...")
		var spawn_cells = get_arena_cells(cell, 2)
		spawn_cells.erase(cell)
		if spawn_cells.is_empty():
			spawn_cells = [cell]
		var spawn_cell = spawn_cells[randi() % spawn_cells.size()]
		if boss_tier and boss_tier.size() > 0:
			var boss = boss_tier[0].instantiate()
			boss.position = Vector3(spawn_cell.x, 0.0, spawn_cell.y)
			world_root.add_child(boss)
			boss.add_to_group("boss")
			current_boss = boss
			if boss.has_signal("died"):
				boss.died.connect(_on_boss_defeated)
			else:
				boss.tree_exited.connect(_on_boss_defeated)
		else:
			push_error("No boss scene assigned for this floor!")
			enable_elevator()
			boss_fight_active = false


func remove_arena_walls_keep_internal(center_cell: Vector2, radius: int) -> void:
	var cells_in_arena = get_arena_cells(center_cell, radius)
	var dir_vectors = {
		"right": Vector2(W, 0), 
		"left": Vector2( - W, 0), 
		"down": Vector2(0, W), 
		"up": Vector2(0, - W)
	}
	for cell in cells_in_arena:
		for dir in dir_vectors.keys():
			var neighbor = cell + dir_vectors[dir]
			if neighbor not in cells_in_arena:
				if walls.has(cell) and walls[cell].has(dir):
					var wall_node = walls[cell][dir]
					if is_instance_valid(wall_node):
						wall_node.queue_free()
					walls[cell].erase(dir)
	await get_tree().process_frame

func animate_arena_walls_falling(center_cell: Vector2, walls_to_animate: Array) -> void:
	print("LevelManager: Animating arena walls falling...")
	var center_pos = Vector3(center_cell.x, 0.0, center_cell.y)
	var max_delay = 0.0
	var delay_multiplier = 0.05
	
	for w in walls_to_animate:
		if not is_instance_valid(w): continue
		var dist = w.global_position.distance_to(center_pos)
		var delay = dist * delay_multiplier
		if delay > max_delay:
			max_delay = delay
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_QUINT)
		tween.tween_interval(delay)
		tween.tween_property(w, "position:y", -WALL_HEIGHT, 1.0)
		tween.tween_callback(w.queue_free)
	
	await get_tree().create_timer(max_delay + 1.0).timeout
	print("LevelManager: Arena walls cleared.")

func _on_boss_defeated() -> void:
	print("Boss defeated")
	boss_fight_active = false
	current_boss = null
	var elevator_cell = get_elevator_cell()
	if elevator_cell == Vector2(-1, -1):
		push_error("Elevator cell not found!")
		return
	if INDICATOR_SCENE:
		var indicator = INDICATOR_SCENE.instantiate()
		indicator.position = Vector3(elevator_cell.x, 0.2, elevator_cell.y)
		world_root.add_child(indicator)
		indicator.add_to_group("elevator_indicator")
		current_indicator = indicator
	else:
		push_error("No indicator scene assigned!")
	enable_elevator()

func set_floor(floor_id: Floor) -> void:
	current_floor = floor_id
	var f = floor_data[floor_id]
	current_floor_type = f.get("type", "combat")
	low_tier = f.get("low_tier", [])
	mid_tier = f.get("mid_tier", [])
	upper_tier = f.get("upper_tier", [])
	boss_tier = f.get("boss_tier", [])
	print("Switched to floor: ", floor_id, " (type: ", current_floor_type, ")")

func _on_maze_changed() -> void:
	# Clear alerts on maze change (issue 8)
	_clear_alerts()
	
	for child in get_children():
		if child.is_in_group("enemies") or child.is_in_group("boss") or child.is_in_group("elevator_indicator"):
			child.queue_free()
	current_boss = null
	current_indicator = null
	boss_fight_active = false
	var new_floor = randi() % floor_data.size()
	set_floor(new_floor)
	if current_floor_type == "combat":
		for i in range(max_enemies):
			spawn_enemy_if_needed()

	build_grid(0, 0)
	carve_out_maze(Vector2(0, 0))
	build_3d_maze()
	await get_tree().process_frame
	rebake_navigation()

	var receiver_cell = pick_random_cell()
	var arrival_walls = create_arrival_walls(receiver_cell, adj)
	if player:
		player.global_position = Vector3(receiver_cell.x, 0.0, receiver_cell.y)
	await get_tree().create_timer(10.0).timeout
	for node in arrival_walls:
		if is_instance_valid(node):
			node.queue_free()
	var exclude = [receiver_cell]
	var new_elevator_cell = pick_random_cell(exclude)
	create_elevator_at(new_elevator_cell)
	for node in departure_nodes:
		if is_instance_valid(node):
			node.queue_free()

	maze_changed.emit()

func create_path_marker(cell: Vector2) -> MeshInstance3D:
	var mesh: = MeshInstance3D.new()
	var box: = BoxMesh.new()
	box.size = Vector3(2.0, 0.1, 2.0)
	var material: = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 0, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = material
	mesh.mesh = box
	mesh.position = Vector3(cell.x, 0.1, cell.y)
	return mesh

func create_elevator_visual(cell: Vector2) -> MeshInstance3D:
	var mesh: = MeshInstance3D.new()
	var box: = BoxMesh.new()
	box.size = Vector3(W * 0.8, 0.5, W * 0.8)
	var material: = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 0, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	box.material = material
	mesh.mesh = box
	mesh.position = Vector3(cell.x, 0.5, cell.y)
	return mesh

func show_path_to_elevator() -> void:
	if not player or current_elevator.is_empty():
		return
	var player_cell = get_cell_from_world(player.global_position)
	var elevator_cell = current_elevator.get("cell", Vector2(-1, -1))
	if player_cell == Vector2(-1, -1) or elevator_cell == Vector2(-1, -1):
		return
	var path = find_path(player_cell, elevator_cell)
	if path.is_empty():
		print("No path found to elevator!")
		return
	clear_path_markers()
	for cell in path:
		var marker = create_path_marker(cell)
		if marker:
			world_root.add_child(marker)
			marker.add_to_group("path_markers")
	print("Path marked with ", path.size(), " markers")

func clear_path_markers() -> void:
	var markers = get_tree().get_nodes_in_group("path_markers")
	for m in markers:
		m.queue_free()

func draw_navmesh_debug() -> void:
	if not nav_region or nav_region.navigation_mesh == null:
		return
	var nav_mesh: NavigationMesh = nav_region.navigation_mesh
	var vertices: PackedVector3Array = nav_mesh.get_vertices()
	if vertices.is_empty():
		print("LevelManager: Debug draw aborted - mesh vertices empty.")
		return
	var mesh: = ArrayMesh.new()
	var final_vertices: = PackedVector3Array()
	for p in range(nav_mesh.get_polygon_count()):
		var poly: PackedInt32Array = nav_mesh.get_polygon(p)
		for i in range(1, poly.size() - 1):
			var v0 = vertices[poly[0]]
			var v1 = vertices[poly[i]]
			var v2 = vertices[poly[i + 1]]
			final_vertices.append(v0)
			final_vertices.append(v1)
			final_vertices.append(v2)
	var arrays: = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = final_vertices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mesh_instance: = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.position.y += 0.05
	var mat: = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0, 1, 0, 0.4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = mat
	world_root.add_child(mesh_instance)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("elevatorhelp"):
		show_path_to_elevator()
	if event.is_action_pressed("debug_elevator"):
		print("Current elevator: ", current_elevator)
		if current_elevator.has("area") and is_instance_valid(current_elevator["area"]):
			print("  area position: ", current_elevator["area"].position)
			print("  area monitoring: ", current_elevator["area"].monitoring)
	if event.is_action_pressed("nav_mesh_debug"):
		draw_navmesh_debug()
	if event.is_action_pressed("tp_to_elevator"):
		if player and current_elevator.has("area") and is_instance_valid(current_elevator["area"]):
			player.global_position = Vector3(current_elevator["area"].global_position.x, 0, current_elevator["area"].global_position.z)
