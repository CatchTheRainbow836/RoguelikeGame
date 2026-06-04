extends CharacterBody3D
class_name SandStalker

@export var max_health: float = 40.0
@export var spear_damage: float = 5.0
@export var dash_damage: float = 20.0
@export var attack_range: float = 12.0
@export var attack_cooldown: float = 4.0
@export var speed: float = 6.0
@export var accel: float = 10.0
@export var dash_speed: float = 25.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 20.0
@export var fov_degrees: float = 90.0
@export var alert_duration: float = 5.0

var current_health: float
var _animation_blocked: bool = false
var is_dashing: bool = false

signal start_dash(spear_start: Vector3, spear_end: Vector3)

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    add_to_group("sand_stalker")
    current_health = max_health

    start_dash.connect(_on_start_dash)

func _process(delta: float) -> void :
    _update_animation()

func _update_animation() -> void :
    if _animation_blocked:
        return

    var attack_state = $AttackStateMachine.CURRENT_STATE.name
    if attack_state == "AttackingAttackState":
        return

    var movement_state = $EnemyStateMachine.CURRENT_STATE.name
    var anim_name = ""
    match movement_state:
        "IdleEnemyState":
            anim_name = "Fighting Idle"
        "WalkingEnemyState":
            anim_name = "Walk"
        "RunningEnemyState":
            anim_name = "Sprint"
        "DashingEnemyState":
            anim_name = "Sword_Dash_RM"
        _:
            return

    if animation_player.current_animation != anim_name:
        animation_player.play(anim_name)

func block_animation_for(duration: float) -> void :
    _animation_blocked = true
    await get_tree().create_timer(duration).timeout
    _animation_blocked = false

func take_damage(amount: float) -> void :
    current_health -= amount
    print(self, " took damage: ", amount, ", health left: ", current_health)
    if current_health <= 0:
        die()
    else:
        if is_dashing:
            $AttackStateMachine.get_node("AttackingAttackState").retract_spear()
            $EnemyStateMachine.on_child_transition("RunningEnemyState")
            is_dashing = false

func die() -> void :
    queue_free()

func _on_start_dash(spear_start: Vector3, spear_end: Vector3) -> void :
    var dashing_state = $EnemyStateMachine.get_node("DashingEnemyState")
    dashing_state.dash_start = spear_start
    dashing_state.dash_end = spear_end
    $EnemyStateMachine.on_child_transition("DashingEnemyState")
