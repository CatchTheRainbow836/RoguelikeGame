extends Node3D

const W = 8
const GRID_SIZE = 20
const RENDER_DISTANCE_STEPS = 15

const SCRAP_CRAWLER = preload("uid://c3edd0nr0blp6")
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

const INDICATOR_SCENE = preload("uid://bnny3ninl1l72")

enum Floor{
	RUSTWORKS, 
	SHOP, 
	TWILIGHT_GARDENS, 
	FLOODED_SEWERS, 
	SUN_SCORCHED_LABYRINTH, 
	SMOLDERING_TUNNELS
}

var floors = {
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

var current_floor: Floor = Floor.RUSTWORKS
var current_floor_type: String = "combat"
var low_tier = floors[Floor.RUSTWORKS].low_tier
var mid_tier = floors[Floor.RUSTWORKS].mid_tier
var upper_tier = floors[Floor.RUSTWORKS].upper_tier
var boss_tier = floors[Floor.RUSTWORKS].boss_tier

var max_enemies = 30

var nav_region: NavigationRegion3D
var player: CharacterBody3D

var update_timer: float = 0.0
var update_interval: float = 0.5
var active_cells: Array = []

var boss_fight_active: bool = false
var current_button_cell: Vector2 = Vector2(-1, -1)
var current_boss: Node3D = null
var current_indicator: Node3D = null

func _ready():
	nav_region = get_parent().get_node("WorldStructures").get_node("NavigationRegion3D") as NavigationRegion3D
	if not nav_region:
		push_error("Navigation region not found!")
		return
	nav_region.button_destroyed.connect(_on_button_destroyed)
	nav_region.maze_changed.connect(_on_maze_changed)

	player = get_tree().get_first_node_in_group("player")

	set_floor(Floor.RUSTWORKS)





	if current_floor_type == "combat":
		for i in range(max_enemies):
			spawn_enemy_if_needed()

func _process(delta):
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_active_enemies()

	if boss_fight_active:
		return

	if current_floor_type == "combat" and get_child_count() < max_enemies:
		spawn_enemy_if_needed()

func spawn_enemy_if_needed():
	if get_child_count() >= max_enemies:
		return
	if not nav_region or not player:
		return

	if not nav_region.current_elevator.has("cell"):
		return
	var elevator_cell = nav_region.current_elevator["cell"]
	var player_cell = nav_region.get_cell_from_world(player.global_position)

	var path = nav_region.find_path(player_cell, elevator_cell)
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

func spawn_enemy_of_tier(tier: Array, cell: Vector2 = Vector2(-1, -1)):
	if cell == Vector2(-1, -1):
		cell.x = (randi() % GRID_SIZE) * W
		cell.y = (randi() % GRID_SIZE) * W

	var enemy_scene = tier[randi() % tier.size()]
	var enemy = enemy_scene.instantiate()

	var offset_x = randf_range(-1.0, 1.0)
	var offset_z = randf_range(-1.0, 1.0)
	enemy.position = Vector3(cell.x + offset_x, 0, cell.y + offset_z)

	add_child(enemy)
	_make_materials_unique(enemy)

func _make_materials_unique(node: Node) -> void :
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

func update_active_enemies():
	if not nav_region or not player:
		return
	var player_cell = nav_region.get_cell_from_world(player.global_position)
	active_cells = nav_region.get_cells_in_render_distance(player_cell, RENDER_DISTANCE_STEPS)

	for enemy in get_children():
		if enemy == current_boss or enemy == current_indicator:
			continue
		var enemy_cell = nav_region.get_cell_from_world(enemy.global_position)
		var should_be_active = enemy_cell in active_cells
		set_enemy_active(enemy, should_be_active)

	nav_region.set_maze_visibility(active_cells)

func set_enemy_active(enemy: Node, active: bool):
	var target_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if enemy.process_mode != target_mode:
		enemy.process_mode = target_mode
		enemy.visible = active

	_set_collision_enabled(enemy, active)

func _set_collision_enabled(node: Node, enabled: bool):
	if node is CollisionShape3D:
		node.disabled = not enabled
	if node is CollisionPolygon3D:
		node.disabled = not enabled
	if node is Area3D:
		node.monitoring = enabled
		node.monitorable = enabled
	for child in node.get_children():
		_set_collision_enabled(child, enabled)

func _on_button_destroyed(cell: Vector2):
	print("Button destroyed at cell ", cell)

	if current_floor_type == "combat":
		print("Starting boss fight")
		boss_fight_active = true
		current_button_cell = cell

		await nav_region.remove_arena_walls(cell, 3)

		var arena_cells = nav_region.get_arena_cells(cell, 2)
		arena_cells.erase(cell)
		if arena_cells.is_empty():
			arena_cells = [cell]
		var spawn_cell = arena_cells[randi() % arena_cells.size()]
		if boss_tier and boss_tier.size() > 0:
			var boss = boss_tier[0].instantiate()
			boss.position = Vector3(spawn_cell.x, 0.0, spawn_cell.y)
			add_child(boss)
			boss.add_to_group("boss")
			current_boss = boss
			if boss.has_signal("died"):
				boss.died.connect(_on_boss_defeated)
			else:
				boss.tree_exited.connect(_on_boss_defeated)
		else:
			push_error("No boss scene assigned for this floor!")
			nav_region.enable_elevator()
			boss_fight_active = false
	elif current_floor_type == "shop":
		print("Shop floor – elevator activated")
		nav_region.enable_elevator()
	else:
		print("Unknown floor - elevator activated")
		nav_region.enable_elevator()

func _on_boss_defeated():
	print("Boss defeated")
	boss_fight_active = false
	current_boss = null

	var elevator_cell = nav_region.get_elevator_cell()
	if elevator_cell == Vector2(-1, -1):
		push_error("Elevator cell not found!")
		return
	if INDICATOR_SCENE:
		var indicator = INDICATOR_SCENE.instantiate()
		indicator.position = Vector3(elevator_cell.x, 0.2, elevator_cell.y)
		add_child(indicator)
		indicator.add_to_group("elevator_indicator")
		current_indicator = indicator
	else:
		push_error("No indicator scene assigned!")

	nav_region.enable_elevator()

func set_floor(floor_id: Floor):
	current_floor = floor_id
	var f = floors[floor_id]
	current_floor_type = f.get("type", "combat")
	low_tier = f.get("low_tier", [])
	mid_tier = f.get("mid_tier", [])
	upper_tier = f.get("upper_tier", [])
	boss_tier = f.get("boss_tier", [])
	print("Switched to floor: ", floor_id, " (type: ", current_floor_type, ")")

func _on_maze_changed():
	for child in get_children():
		child.queue_free()
	current_boss = null
	current_indicator = null
	boss_fight_active = false

	var new_floor = randi() % floors.size()
	set_floor(new_floor)

	if current_floor_type == "combat":
		for i in range(max_enemies):
			spawn_enemy_if_needed()
