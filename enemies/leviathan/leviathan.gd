extends CharacterBody3D
class_name Leviathan

@export var max_health: float = 1000.0
@export var phase2_threshold: float = 0.6
@export var phase3_threshold: float = 0.3

@export var phase1_speed: float = 6.0
@export var phase1_accel: float = 10.0
@export var phase1_wander_radius: float = 15.0
@export var phase1_view_distance: float = 40.0
@export var phase1_fov_degrees: float = 360.0
@export var phase1_attack_cooldown: float = 5.0
@export var phase1_player_avoid_radius: float = 8.0

@export var phase1_splash_damage: float = 10
@export var phase1_splash_radius: float = 5
@export var phase1_splash_count: int = 12
@export var phase1_splash_area_radius: float = 50

@export var phase2_speed: float = 5.0
@export var phase2_accel: float = 8.0

var phase2_original_y: float
@export var phase2_melee_range: float = 3.0
@export var phase2_slam_damage: float = 25.0
@export var phase2_stun_duration: float = 2.0
@export var phase2_slam_radius: float = 3.5
@export var phase2_attack_cooldown: float = 6.0

@export var phase2_shrapnel_damage: float = 15.0
@export var phase2_shrapnel_count: int = 20
@export var phase2_shrapnel_radius: float = 0.5
@export var phase2_shrapnel_height: float = 2
@export var phase2_shrapnel_arc_height: float = 4.0
@export var phase2_shrapnel_speed: float = 12.0
@export var phase2_shrapnel_range: float = 12.0

@export var phase3_speed: float = 5.0
@export var phase3_accel: float = 8.0
@export var phase3_wander_radius: float = 20.0
@export var phase3_player_avoid_radius: float = 10.0
@export var phase3_attack_cooldown: float = 4.0

@export var phase3_wall_width: float = 10.0
@export var phase3_wall_height: float = 3.0
@export var phase3_wall_thickness: float = 1.0
@export var phase3_wall_speed: float = 20.0
@export var phase3_wall_max_distance: float = 15.0
@export var phase3_push_distance: float = 6
@export var phase3_wall_color: Color = Color(0.6, 0.8, 1.0, 0.2)

@export var phase3_max_tidebearers: int = 6
@export var phase3_summon_count: int = 3
@export var phase3_summon_radius: float = 5.0
@export var tidebearer_scene: PackedScene

var current_health: float
var top_state_machine: StateMachine
var _animation_blocked: bool = false

signal surface_requested
signal dive_requested

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
@onready var collision_shape = $CollisionShape3D

func _ready() -> void :
	add_to_group("leviathan")
	add_to_group("boss_enemies")
	current_health = max_health
	top_state_machine = $LeviathanStateMachine
	top_state_machine.on_child_transition("PhaseOneStateMachine")

func _process(delta: float) -> void :
	_update_animation()

func _update_animation() -> void :
	if _animation_blocked:
		return

	var phase_sm = top_state_machine.CURRENT_STATE
	if not phase_sm:
		return

	var movement_sm = phase_sm.get_node("EnemyStateMachine") as StateMachine
	if not movement_sm:
		return
	var movement_state_name = movement_sm.CURRENT_STATE.name

	var anim_name = ""
	match movement_state_name:
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

var has_transitioned_to_phase_two: bool = false
func take_damage(amount: float) -> void :
	current_health -= amount
	print("Leviathan took damage: ", amount, ", health left: ", current_health)
	var health_percent = current_health / max_health
	if health_percent <= phase3_threshold:
		top_state_machine.on_child_transition("PhaseThreeStateMachine")
	elif health_percent <= phase2_threshold:
		if not has_transitioned_to_phase_two:
			await _enter_phase_two()
			has_transitioned_to_phase_two = true
		top_state_machine.on_child_transition("PhaseTwoStateMachine")
	if current_health <= 0:
		die()

func die() -> void :
	queue_free()

func block_animation_for(duration: float) -> void :
	_animation_blocked = true
	await get_tree().create_timer(duration).timeout
	_animation_blocked = false

func tween_to_ground(target_y: float, duration: float = 0.5) -> void :
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "global_position:y", target_y, duration)
	await tween.finished



func _enter_phase_two() -> void :
	phase2_original_y = global_position.y
	var target_y = phase2_original_y - (collision_shape.shape.height + 0.5)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "global_position:y", target_y, 0.5)
	await tween.finished

func _exit_phase_two() -> void :
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "global_position:y", phase2_original_y, 0.5)
	await tween.finished

func surface_for_slam() -> void :
	var target_y = 0
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "global_position:y", target_y, 5.0)
	await tween.finished

func dive_after_slam() -> void :
	var target_y = - (collision_shape.shape.height + 0.5)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.tween_property(self, "global_position:y", target_y, 5.0)
	await tween.finished
