extends CharacterBody3D
class_name CrucibleCore

@export var max_health: float = 1200.0
@export var phase2_threshold: float = 0.6
@export var phase3_threshold: float = 0.3

@export var arena_half_size: float = 28.0
@export var cube_size: float = 2.0
@export var cube_height: float = 1.0
@export var damaging_floor_damage: float = 0.5

@export var sweep_damage: float = 20.0
@export var sweep_length: float = 70
@export var sweep_radius: float = 0.25
@export var sweep_height: float = 1.5
@export var sweep_base_radius: float = 0.5
@export var sweep_cooldown: float = 5.0

@export var ram_damage: float = 25.0
@export var ram_radius: float = 1.0
@export var ram_height: float = 6.0
@export var ram_speed: float = 25.0
@export var ram_push_distance: float = 8.0
@export var ram_cooldown: float = 5.0

@export var burst_damage: float = 10.0
@export var burst_radius: float = 1.0
@export var burst_height: float = 4.0
@export var burst_duration: float = 2.0
@export var burst_cooldown: float = 5.0

@export var drop_damage: float = 30.0
@export var drop_ball_radius: float = 1.0
@export var drop_fall_speed: float = 8.0
@export var drop_cooldown: float = 5.0

@export var spirit_scale: float = 0.5
@export var spirit_speed: float = 5.0
@export var spirit_accel: float = 8.0
@export var spirit_wander_radius: float = 20.0
@export var spirit_avoid_radius: float = 10.0

var spirit_scene: PackedScene = preload("uid://cj68v6clpu0gh")

var current_health: float
var top_state_machine: StateMachine
var arena_center: Vector3 = Vector3.ZERO
var shields: Array = []
var spawning_rods: Array = []
var phase2_initialized: bool = false
var elevated_cubes: Dictionary = {}
var damaging_floor: MeshInstance3D = null
var damaging_floor_area: Area3D = null
var spirit: CharacterBody3D = null
var _animation_blocked: bool = false
var damaging_floor_enabled: bool = false

@export var back_up_weapons: Array[ItemDataWeapon]
var recorded_weapon: ItemDataWeapon = null
var weapon_model_instance: Node3D = null
var is_phase3_active: bool = false

var PLAYER: Player

var navigation_region_3d: NavigationRegion3D = null
var obstacles_container: StaticBody3D = null
var obstacles_list: Array = []

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func update_weapon_rotation() -> void :
    if not weapon_model_instance or not PLAYER:
        return
    var aim_point = PLAYER.global_position + Vector3(0, 1.0, 0)
    var direction = (aim_point - $Pivot.global_position).normalized()
    weapon_model_instance.look_at(weapon_model_instance.global_position + direction, Vector3.UP)

func _process(delta: float) -> void :
    if damaging_floor_enabled and damaging_floor_area:
        var bodies = damaging_floor_area.get_overlapping_bodies()
        for body in bodies:
            if body.is_in_group("player") and body.has_method("take_damage"):
                body.take_damage(damaging_floor_damage)

func _ready() -> void :
    add_to_group("crucible_core")
    add_to_group("boss_enemies")
    current_health = max_health
    top_state_machine = $CrucibleCoreStateMachine
    top_state_machine.on_child_transition("PhaseOneStateMachine")

    PLAYER = get_tree().get_first_node_in_group("player")

    var world_structures = get_tree().root.get_node("Main").get_node("WorldStructures")
    if world_structures:
        var nav_region = world_structures.get_node("NavigationRegion3D")
        if nav_region and nav_region.has_method("get_arena_center_position"):
            arena_center = nav_region.get_arena_center_position()
            navigation_region_3d = nav_region
    arena_center.y = 0

    global_position = arena_center

    _create_shields()
    _push_player_away()

    _record_player_weapon()

func _record_player_weapon() -> void :
    recorded_weapon = PLAYER.weapon_inventory_data.slot_datas[0].item_data as ItemDataWeapon if PLAYER.weapon_inventory_data.slot_datas[0] else null
    if recorded_weapon:
        print("Crucible Core recorded weapon: ", recorded_weapon.name, " type: ", recorded_weapon.type)
    else:
        recorded_weapon = back_up_weapons[randi_range(0, back_up_weapons.size() - 1)]
        print("Crucible Core recorded back up weapon: ", recorded_weapon.name, " type: ", recorded_weapon.type)

func _create_shields() -> void :
    var inner_mesh = MeshInstance3D.new()
    inner_mesh.mesh = CylinderMesh.new()
    inner_mesh.mesh.top_radius = 4.0
    inner_mesh.mesh.bottom_radius = 4.0
    inner_mesh.mesh.height = 4.0
    var inner_mat = StandardMaterial3D.new()
    inner_mat.albedo_color = Color(0.5, 0.7, 1.0, 0.4)
    inner_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    inner_mesh.material_override = inner_mat
    add_child(inner_mesh)
    inner_mesh.position = Vector3(0, 2, 0)

    var inner_collision = CollisionShape3D.new()
    var inner_shape = CylinderShape3D.new()
    inner_shape.radius = 4.0
    inner_shape.height = 4.0
    inner_collision.shape = inner_shape
    add_child(inner_collision)
    inner_collision.position = Vector3(0, 2, 0)

    var outer_mesh = MeshInstance3D.new()
    outer_mesh.mesh = CylinderMesh.new()
    outer_mesh.mesh.top_radius = 6.0
    outer_mesh.mesh.bottom_radius = 6.0
    outer_mesh.mesh.height = 4.0
    var outer_mat = StandardMaterial3D.new()
    outer_mat.albedo_color = Color(0.5, 0.7, 1.0, 0.4)
    outer_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    outer_mesh.material_override = outer_mat
    add_child(outer_mesh)
    outer_mesh.position = Vector3(0, 2, 0)

    var outer_collision = CollisionShape3D.new()
    var outer_shape = CylinderShape3D.new()
    outer_shape.radius = 6.0
    outer_shape.height = 4.0
    outer_collision.shape = outer_shape
    add_child(outer_collision)
    outer_collision.position = Vector3(0, 2, 0)

    shields = [inner_mesh, outer_mesh, inner_collision, outer_collision]

func _push_player_away() -> void :
    var player = get_tree().get_first_node_in_group("player")
    if not player:
        return
    var dist = global_position.distance_to(player.global_position)
    if dist < 6.5:
        var dir = (player.global_position - global_position).normalized()
        player.global_position = global_position + dir * 6.5

func take_damage(amount: float) -> void :
    current_health -= amount
    print("Crucible Core took damage: ", amount, ", health left: ", current_health)

    var health_percent = current_health / max_health
    if not is_phase3_active and health_percent <= phase3_threshold:
        enter_phase3()
    elif not phase2_initialized and health_percent <= phase2_threshold:
        enter_phase2()

    if current_health <= 0:
        die()

func enter_phase2() -> void :
    if phase2_initialized:
        return
    setup_phase2_environment()
    top_state_machine.on_child_transition("PhaseTwoStateMachine")

func enter_phase3() -> void :
    if is_phase3_active:
        return
    is_phase3_active = true
    cleanup_phase2_environment()
    if shields[0] and is_instance_valid(shields[0]):
        shields[0].queue_free()
    if shields[2] and is_instance_valid(shields[2]):
        shields[2].queue_free()
    _spawn_weapon_model()
    setup_phase3_arena()
    top_state_machine.on_child_transition("PhaseThreeStateMachine")

func _spawn_weapon_model() -> void :
    if not recorded_weapon or not recorded_weapon.model_scene:
        return
    weapon_model_instance = recorded_weapon.model_scene.instantiate()
    $Pivot.add_child(weapon_model_instance)
    weapon_model_instance.position = Vector3(0.311, 1.512, -0.95)

func die() -> void :

    if obstacles_container and is_instance_valid(obstacles_container):
        obstacles_container.queue_free()
    obstacles_list.clear()
    queue_free()

func block_animation_for(duration: float) -> void :
    _animation_blocked = true
    await get_tree().create_timer(duration).timeout
    _animation_blocked = false

func setup_phase2_environment() -> void :
    if phase2_initialized:
        return
    phase2_initialized = true

    var spawned_enemies = get_tree().get_nodes_in_group("spawned_enemies")
    for enemy in spawned_enemies:
        if is_instance_valid(enemy):
            enemy.queue_free()

    if shields[1] and is_instance_valid(shields[1]):
        shields[1].queue_free()
    if shields[3] and is_instance_valid(shields[3]):
        shields[3].queue_free()
    _create_elevated_cubes()
    _spawn_spirit()
    await get_tree().create_timer(2.0).timeout
    _create_damaging_floor()

func _create_elevated_cubes() -> void :
    var start_x: = arena_center.x - arena_half_size
    var start_z: = arena_center.z - arena_half_size
    var grid_size: = int(arena_half_size * 2.0 / cube_size)

    var base_y: = -1.5
    var elevated_y: = 0.0

    var ring1_min: = 4.0 * cube_size
    var ring1_max: = 6.0 * cube_size
    var ring2_min: = 8.0 * cube_size
    var ring2_max: = 10.0 * cube_size

    for i in range(grid_size):
        for j in range(grid_size):
            var x: = start_x + i * cube_size + cube_size * 0.5
            var z: = start_z + j * cube_size + cube_size * 0.5

            var dist: float = max(abs(x - arena_center.x), abs(z - arena_center.z))
            var is_ring1: = dist >= ring1_min and dist < ring1_max
            var is_ring2: = dist >= ring2_min and dist < ring2_max
            var y_target: = elevated_y if (is_ring1 or is_ring2) else base_y

            var container: = Node3D.new()
            container.name = "Cube_%d_%d" % [i, j]
            add_child(container)
            container.global_position = Vector3(x, y_target, z)

            var cube_mesh: = MeshInstance3D.new()
            var box_mesh: = BoxMesh.new()
            box_mesh.size = Vector3(cube_size, cube_height, cube_size)
            cube_mesh.mesh = box_mesh

            var material: = StandardMaterial3D.new()
            material.albedo_color = Color(0.6, 0.6, 0.6, 1.0)
            cube_mesh.material_override = material
            container.add_child(cube_mesh)
            cube_mesh.position = Vector3(0, cube_height * 0.5, 0)

            var static_body: = StaticBody3D.new()
            static_body.name = "CubeCollision"
            container.add_child(static_body)

            var collision: = CollisionShape3D.new()
            var box_shape: = BoxShape3D.new()
            box_shape.size = Vector3(cube_size, cube_height, cube_size)
            collision.shape = box_shape
            static_body.add_child(collision)
            collision.position = Vector3(0, cube_height * 0.5, 0)

            elevated_cubes[Vector2(i, j)] = container

func _create_damaging_floor() -> void :
    damaging_floor = MeshInstance3D.new()
    damaging_floor.mesh = BoxMesh.new()
    damaging_floor.mesh.size = Vector3(arena_half_size * 2, 0.1, arena_half_size * 2)
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(1, 0, 0, 0.8)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    damaging_floor.material_override = material
    add_child(damaging_floor)
    damaging_floor.global_position = arena_center
    damaging_floor.global_position.y = 0.05

    damaging_floor_area = Area3D.new()
    damaging_floor_area.collision_mask = 2
    var floor_shape = CollisionShape3D.new()
    var box_shape = BoxShape3D.new()
    box_shape.size = Vector3(arena_half_size * 2, 0.2, arena_half_size * 2)
    floor_shape.shape = box_shape
    damaging_floor_area.add_child(floor_shape)
    add_child(damaging_floor_area)
    damaging_floor_area.global_position = arena_center
    damaging_floor_area.global_position.y = 0.1

    damaging_floor_enabled = true

func _spawn_spirit() -> void :
    if not spirit_scene:
        print("Spirit scene not assigned!")
        return
    spirit = spirit_scene.instantiate()
    var offset_angle = randf_range(0, TAU)
    var offset_dist = randf_range(10, 12)
    var offset = Vector3(cos(offset_angle) * offset_dist, 0, sin(offset_angle) * offset_dist)
    get_parent().add_child(spirit)
    spirit.global_position = global_position + offset
    spirit.add_to_group("crucible_core_spirit")
    var nav = spirit.get_node_or_null("NavigationAgent3D")
    if not nav:
        nav = NavigationAgent3D.new()
        spirit.add_child(nav)
        nav.owner = spirit
    nav.avoidance_enabled = true

func cleanup_phase2_environment() -> void :
    if damaging_floor:
        damaging_floor.queue_free()
    if damaging_floor_area:
        damaging_floor_area.queue_free()
    for cube in elevated_cubes.values():
        if is_instance_valid(cube):
            var tween = create_tween()
            tween.tween_property(cube, "global_position:y", -2.0, 0.5)
            tween.tween_callback(cube.queue_free)
    elevated_cubes.clear()
    if spirit and is_instance_valid(spirit):
        spirit.queue_free()
        spirit = null
    damaging_floor_enabled = false


func setup_phase3_arena() -> void :
    if not navigation_region_3d:
        print("NavigationRegion3D not found, cannot place obstacles.")
        return

    obstacles_container = StaticBody3D.new()
    obstacles_container.name = "Phase3Obstacles"
    navigation_region_3d.add_child(obstacles_container)

    var obstacle_size = Vector3(6.0, 4.0, 1.0)
    var half_obstacle_len = obstacle_size.x / 2.0
    var wall_margin = 3.0
    var min_distance_between = 6.0

    var max_attempts = 1000
    var placed_positions = []

    for i in range(10):
        var attempts = 0
        var placed = false
        while not placed and attempts < max_attempts:
            var rand_x = randf_range(arena_center.x - arena_half_size + wall_margin, arena_center.x + arena_half_size - wall_margin)
            var rand_z = randf_range(arena_center.z - arena_half_size + wall_margin, arena_center.z + arena_half_size - wall_margin)
            var pos = Vector3(rand_x, obstacle_size.y / 2.0, rand_z)

            var too_close = false
            for p in placed_positions:
                if p.distance_to(pos) < min_distance_between:
                    too_close = true
                    break
            if not too_close:
                placed = true
                placed_positions.append(pos)

                var obstacle_mesh = MeshInstance3D.new()
                var box_mesh = BoxMesh.new()
                box_mesh.size = obstacle_size
                obstacle_mesh.mesh = box_mesh
                var material = StandardMaterial3D.new()
                material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
                obstacle_mesh.material_override = material
                obstacles_container.add_child(obstacle_mesh)
                obstacle_mesh.position = pos

                var collision = CollisionShape3D.new()
                var box_shape = BoxShape3D.new()
                box_shape.size = obstacle_size
                collision.shape = box_shape
                obstacles_container.add_child(collision)
                collision.position = pos

                var rand_rot_y = randf_range(0, TAU)
                obstacle_mesh.rotation = Vector3(0, rand_rot_y, 0)
                collision.rotation = Vector3(0, rand_rot_y, 0)

                obstacles_list.append(obstacle_mesh)
                obstacles_list.append(collision)
            attempts += 1
        if not placed:
            print("Warning: Could not place obstacle ", i, " after ", max_attempts, " attempts")


    if navigation_region_3d.has_method("bake_navigation_mesh"):
        navigation_region_3d.bake_navigation_mesh()
    else:
        print("NavigationRegion3D does not have bake_navigation_mesh method.")
