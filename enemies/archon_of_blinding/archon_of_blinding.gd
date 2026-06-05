extends CharacterBody3D
class_name ArchonOfBlinding

@export var max_health: float = 1200.0
@export var phase2_threshold: float = 0.6
@export var phase3_threshold: float = 0.3

@export var phase1_speed: float = 6.0
@export var phase1_accel: float = 10.0
@export var phase1_wander_radius: float = 15.0
@export var phase1_view_distance: float = 40.0
@export var phase1_fov_degrees: float = 360.0
@export var phase1_player_avoid_radius: float = 8.0

@export var phase1_sweep_cooldown: float = 8.0
@export var phase1_splash_cooldown: float = 6.0

@export var phase1_sweep_damage: float = 15.0
@export var phase1_sweep_length: float = 80.0
@export var phase1_sweep_radius: float = 0.25
@export var phase1_sweep_height: float = 1.5
@export var phase1_sweep_base_radius: float = 0.5

@export var phase1_splash_damage: float = 12.0
@export var phase1_splash_radius: float = 5.0
@export var phase1_splash_cylinder_height: float = 8.0
@export var phase1_splash_count: int = 12
@export var phase1_splash_area_radius: float = 50.0

@export var phase2_speed: float = 6.0
@export var phase2_accel: float = 10.0
@export var phase2_wander_radius: float = 15.0

@export var phase2_summon_count: int = 3
@export var phase2_summon_radius: float = 5.0
@export var halo_sentry_scene: PackedScene

@export var phase2_wave_damage: float = 10.0
@export var phase2_wave_block_size: float = 4.0
@export var phase2_wave_height: float = 0.3
@export var phase2_wave_tween_duration: float = 0.2
@export var phase2_wave_cooldown: float = 10.0

@export var phase3_speed: float = 5.0
@export var phase3_accel: float = 8.0
@export var phase3_preferred_distance: float = 2.0
@export var phase3_melee_damage: float = 20.0
@export var phase3_melee_cooldown: float = 1.0
@export var phase3_melee_range: float = 3
@export var phase3_orb_damage: float = 12.0
@export var phase3_orb_cooldown: float = 5.0
@export var phase3_orb_radius: float = 1.0
@export var phase3_orb_speed: float = 8.0
@export var phase3_clone_count: int = 3
@export var phase3_orbit_speed: float = 1.5
@export var phase3_clone_visible_range: float = 3.0

var current_health: float
var top_state_machine: StateMachine
var _animation_blocked: bool = false
var arena_center: Vector3 = Vector3.ZERO

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	add_to_group("archon_of_blinding")
	add_to_group("boss_enemies")
	current_health = max_health
	top_state_machine = $ArchonStateMachine
	top_state_machine.on_child_transition("PhaseOneStateMachine")
	var world_structures = get_tree().root.get_node("Main").get_node("WorldStructures")
	if world_structures:
		var nav_region = world_structures.get_node("NavigationRegion3D")
		if nav_region and nav_region.has_method("get_arena_center_position"):
			arena_center = nav_region.get_arena_center_position()
	arena_center.y = 0

func _process(delta: float) -> void :
	_update_animation()

func _update_animation() -> void :
	if _animation_blocked:
		return

	var phase_sm = top_state_machine.CURRENT_STATE
	if not phase_sm:
		return

	var movement_sm = phase_sm.get_node("EnemyStateMachine")
	var movement_state = movement_sm.CURRENT_STATE.name if movement_sm else ""

	var anim_name = ""
	match movement_state:
		"IdleEnemyState":
			anim_name = "Fighting Idle"
		"WalkingEnemyState":
			anim_name = "Walk"
		"RunningEnemyState":
			anim_name = "Sprint"
		_:
			return

	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func take_damage(amount: float) -> void :
	current_health -= amount
	print("Archon of Blinding took damage: ", amount, ", health left: ", current_health)
	var health_percent = current_health / max_health
	if health_percent <= phase3_threshold:
		top_state_machine.on_child_transition("PhaseThreeStateMachine")
	elif health_percent <= phase2_threshold:
		top_state_machine.on_child_transition("PhaseTwoStateMachine")
	if current_health <= 0:
		die()

func die() -> void :
	queue_free()

func block_animation_for(duration: float) -> void :
	_animation_blocked = true
	await get_tree().create_timer(duration).timeout
	_animation_blocked = false
