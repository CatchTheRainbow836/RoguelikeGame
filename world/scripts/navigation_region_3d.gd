extends NavigationRegion3D

const W: = 8
const WALL_HEIGHT: = 4
const GRID_SIZE: = 20

var grid: = []
var visited: = []
var stack: = []
var solution: = {}
var adj: = {}

var walls: Dictionary = {}
var floors: Dictionary = {}
var roofs: Dictionary = {}

@export var wall_scene: PackedScene
@export var floor_scene: PackedScene
@export var roof_scene: PackedScene
@export var button_scene: PackedScene

var player: CharacterBody3D = null
var player_start_cell = Vector2(0, 0)

var current_elevator: Dictionary = {}
var can_ascend: bool = false

const ARENA_RADIUS = 3

var arena_center_cell: Vector2 = Vector2(-1, -1)

signal button_destroyed(cell: Vector2)

signal maze_changed()

func rebake_navigation() -> void :
	if is_baking():
		return
	bake_navigation_mesh()
	await bake_finished

func get_arena_center_position() -> Vector3:
	if arena_center_cell == Vector2(-1, -1):
		return Vector3.ZERO
	return Vector3(arena_center_cell.x, 0.0, arena_center_cell.y)

func _ready() -> void :
	randomize()
	build_grid(0, 0)
	carve_out_maze(Vector2(0, 0))
	build_3d_maze()

	player = get_tree().get_first_node_in_group("player")
	print("Player found: ", player)

	setup_initial_elevator()

	add_to_group("navigation_region")
	bake_finished.connect(_on_bake_finished)
	await get_tree().create_timer(0.0).timeout
	bake_navigation_mesh()

func _on_bake_finished() -> void :
	var map_rid: RID = get_navigation_map()
	var enemies: = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		var nav_agent: = enemy.get_node_or_null("NavAgent")
		if nav_agent:
			nav_agent.set_navigation_map(map_rid)
			nav_agent.call_deferred("get_next_path_position")

func build_grid(x_start: int, y_start: int):
	var y = y_start
	for i in range(GRID_SIZE):
		var x = x_start
		for j in range(GRID_SIZE):
			var cell = Vector2(x, y)
			grid.append(cell)
			adj[cell] = []
			x += W
		y += W

func remove_wall(a: Vector2, b: Vector2):
	adj[a].append(b)
	adj[b].append(a)

func carve_out_maze(start: Vector2):
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

func build_3d_maze():
	var effective_roof_scene = roof_scene if roof_scene else floor_scene
	for cell in grid:

		if floor_scene:
			var f = floor_scene.instantiate()
			f.position = Vector3(cell.x, 0, cell.y)
			add_child(f)
			f.add_to_group("maze")
			floors[cell] = f


		if effective_roof_scene:
			var r = effective_roof_scene.instantiate()
			r.position = Vector3(cell.x, WALL_HEIGHT, cell.y)
			add_child(r)
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

func spawn_wall(cell: Vector2, dir: String):
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
	add_child(w)
	w.add_to_group("maze")
	if not walls.has(cell):
		walls[cell] = {}
	walls[cell][dir] = w

func setup_initial_elevator():
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

func create_elevator_at(cell: Vector2):
	print("Creating elevator at cell: ", cell)
	var area = Area3D.new()
	area.collision_mask = 2
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(W, 1, W)
	collision.shape = shape
	area.add_child(collision)
	area.position = Vector3(cell.x, 0.5, cell.y)
	add_child(area)
	area.monitoring = false
	area.body_entered.connect(_on_elevator_entered.bind(area, cell))

	var visual = create_elevator_visual(cell)
	add_child(visual)
	visual.add_to_group("elevator_visual")

	if button_scene:
		var button = button_scene.instantiate()
		button.position = Vector3(cell.x, 0.5, cell.y)
		add_child(button)
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

func _on_button_died(cell: Vector2):
	print("Button destroyed at ", cell)
	current_elevator.erase("button")
	button_destroyed.emit(cell)


func _on_elevator_entered(body: Node, area: Area3D, cell: Vector2):
	if not can_ascend:
		print("Elevator not ready – defeat the boss first!")
		return
	print("elevator entered successfully by player")
	area.set_deferred("monitoring", false)
	area.queue_free()
	if current_elevator.has("visual") and is_instance_valid(current_elevator["visual"]):
		current_elevator["visual"].queue_free()
	current_elevator.clear()

	var departure_nodes = create_departure_enclosure(cell)
	clear_maze()
	await get_tree().process_frame

	grid.clear()
	adj.clear()
	visited.clear()
	stack.clear()
	solution.clear()
	walls.clear()
	floors.clear()
	roofs.clear()

	build_grid(0, 0)
	carve_out_maze(Vector2(0, 0))
	build_3d_maze()
	bake_navigation_mesh()

	var receiver_cell = pick_random_cell()
	var arrival_walls = create_arrival_walls(receiver_cell, adj)
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

func pick_random_cell(exclude: Array = []) -> Vector2:
	var candidates = grid.duplicate()
	if not exclude.is_empty():
		candidates = candidates.filter( func(c): return c not in exclude)
	return candidates[randi() % candidates.size()]

func clear_maze():
	var maze_nodes = get_tree().get_nodes_in_group("maze")
	for node in maze_nodes:
		if is_instance_valid(node):
			node.queue_free()
	walls.clear()
	floors.clear()
	roofs.clear()

func create_departure_enclosure(cell: Vector2) -> Array:
	var nodes = []
	if floor_scene:
		var f = floor_scene.instantiate()
		f.position = Vector3(cell.x, 0, cell.y)
		add_child(f)
		f.add_to_group("temp_elevator")
		nodes.append(f)
	var effective_roof = roof_scene if roof_scene else floor_scene
	if effective_roof:
		var r = effective_roof.instantiate()
		r.position = Vector3(cell.x, WALL_HEIGHT, cell.y)
		add_child(r)
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
	add_child(w)
	w.add_to_group("temp_elevator")
	apply_wall_texture_scaling(w, dir)
	return w

func apply_wall_texture_scaling(wall_node: Node3D, dir: String):
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

func remove_arena_walls(center_cell: Vector2, radius: int):

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
	bake_navigation_mesh()

func enable_elevator():
	can_ascend = true
	if current_elevator.has("area") and is_instance_valid(current_elevator["area"]):
		current_elevator["area"].monitoring = true

func disable_elevator_area():
	if current_elevator.has("area") and is_instance_valid(current_elevator["area"]):
		current_elevator["area"].monitoring = false
		can_ascend = false

func _set_node_collision_enabled(node: Node, enabled: bool):

	if node is CollisionShape3D:
		node.disabled = not enabled

	if node is CollisionPolygon3D:
		node.disabled = not enabled

	if node is Area3D:
		node.monitoring = enabled
		node.monitorable = enabled

	for child in node.get_children():
		_set_node_collision_enabled(child, enabled)

func set_maze_visibility(active_cells: Array):

	for cell in floors:
		var visible = cell in active_cells
		if is_instance_valid(floors[cell]):
			floors[cell].visible = visible
			_set_node_collision_enabled(floors[cell], visible)

	for cell in roofs:
		var visible = cell in active_cells
		if is_instance_valid(roofs[cell]):
			roofs[cell].visible = visible
			_set_node_collision_enabled(roofs[cell], visible)

	for cell in walls:
		var visible = cell in active_cells
		for dir in walls[cell]:
			if is_instance_valid(walls[cell][dir]):
				walls[cell][dir].visible = visible
				_set_node_collision_enabled(walls[cell][dir], visible)

func get_cells_in_render_distance(start_cell: Vector2, max_steps: int) -> Array:

	if max_steps < 0:
		return []
	var visited = {}
	var queue = [start_cell]
	visited[start_cell] = true
	var distance = {start_cell: 0}
	var result = [start_cell]

	while queue:
		var current = queue.pop_front()
		var current_dist = distance[current]
		if current_dist >= max_steps:
			continue
		for neighbor in adj.get(current, []):
			if not visited.has(neighbor):
				visited[neighbor] = true
				distance[neighbor] = current_dist + 1
				queue.append(neighbor)
				result.append(neighbor)
	return result


func _input(event: InputEvent) -> void :
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
		player.global_position = Vector3(current_elevator["area"].global_position.x, 0, current_elevator["area"].global_position.z)

func draw_navmesh_debug():
	var region: = self as NavigationRegion3D
	if region == null or region.navigation_mesh == null:
		return

	var nav_mesh: NavigationMesh = region.navigation_mesh

	var vertices: PackedVector3Array = nav_mesh.get_vertices()
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

	add_child(mesh_instance)

func show_path_to_elevator() -> void :
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
			add_child(marker)
			marker.add_to_group("path_markers")
	print("Path marked with ", path.size(), " markers")

func find_path(start: Vector2, end: Vector2) -> Array:
	if start == end:
		return [start]
	var queue = [start]
	var visited = {start: true}
	var parent = {}
	while queue:
		var current = queue.pop_front()
		for neighbor in adj.get(current, []):
			if not visited.has(neighbor):
				visited[neighbor] = true
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

func clear_path_markers() -> void :
	var markers = get_tree().get_nodes_in_group("path_markers")
	for m in markers:
		m.queue_free()

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
