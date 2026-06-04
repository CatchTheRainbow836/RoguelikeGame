extends CharacterBody3D
class_name EdenRemnant

@export var max_health: float = 800.0
@export var phase2_threshold: float = 0.6
@export var phase3_threshold: float = 0.3

@export var phase1_speed: float = 8.0
@export var phase1_accel: float = 12.0
@export var phase1_wander_radius: float = 12.0
@export var phase1_view_distance: float = 30.0
@export var phase1_fov_degrees: float = 360.0

@export var phase2_speed: float = 5.0
@export var phase2_accel: float = 10.0
@export var phase2_melee_damage: float = 20.0
@export var phase2_attack_range: float = 2.5
@export var phase2_attack_cooldown: float = 2.0

@export var phase2_splash_damage: float = 10.0
@export var phase2_splash_radius: float = 5
@export var phase2_splash_count: int = 12
@export var phase2_splash_area_radius: float = 50.0

@export var phase3_speed: float = 3.0
@export var phase3_accel: float = 5.0
@export var phase3_preferred_distance: float = 10.0
@export var phase3_strafe_speed: float = 1.5

@export var phase3_summon_count: int = 6
@export var phase3_summon_radius: float = 4.0
@export var petal_flyer_scene: PackedScene

@export var phase3_splash_damage: float = 15.0
@export var phase3_splash_radius: float = 5
@export var phase3_splash_cylinder_height: float = 8.0
@export var phase3_splash_count: int = 12
@export var phase3_splash_area_radius: float = 50.0

@export var phase1_vine_damage: float = 12.0
@export var phase1_vine_count: int = 50
@export var phase1_vine_spread_degrees: float = 45
@export var phase1_attack_cooldown: float = 5.0

@export var alert_duration: float = 5

var current_health: float
var top_state_machine: StateMachine
var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    add_to_group("eden_remnant")
    add_to_group("boss_enemies")
    current_health = max_health
    top_state_machine = $EdenRemnantStateMachine
    top_state_machine.on_child_transition("PhaseOneStateMachine")

func _process(delta: float) -> void :
    _update_animation()

func _update_animation() -> void :
    if _animation_blocked:
        return

    var current_phase = top_state_machine.CURRENT_STATE
    if not current_phase:
        return

    var attack_sm = current_phase.get_node("AttackStateMachine")
    var attack_state = attack_sm.CURRENT_STATE.name if attack_sm else ""
    if attack_state == "AttackingAttackState" or attack_state == "SplashAttackState" or attack_state == "SummonAttackState":
        return

    var movement_sm = current_phase.get_node("EnemyStateMachine")
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
    print("Eden's Remnant took damage: ", amount, ", health left: ", current_health)

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
