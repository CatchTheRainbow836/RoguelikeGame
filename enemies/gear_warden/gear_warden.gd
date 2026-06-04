extends CharacterBody3D
class_name GearWarden

@export var max_health: float = 80.0
@export var attack_damage: float = 5.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.5
@export var speed: float = 4.0
@export var accel: float = 8.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 20.0
@export var fov_degrees: float = 90.0
@export var alert_duration: float = 5.0

var current_health: float
var attack_state_machine: StateMachine
var _animation_blocked: bool = false
var _is_shielding: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    add_to_group("enemies")
    add_to_group("gear_wardens")
    current_health = max_health
    attack_state_machine = $AttackStateMachine

func _process(delta: float) -> void :
    _update_animation()

func _update_animation() -> void :
    if _animation_blocked:
        return

    var attack_state = $AttackStateMachine.CURRENT_STATE.name
    match attack_state:
        "AttackingAttackState":
            return
        "ShieldingAttackState":
            if not _is_shielding:
                _is_shielding = true
            var shield_anim = "Idle_Shield"
            if animation_player.current_animation != shield_anim:
                animation_player.play(shield_anim)
            return

    _is_shielding = false
    var movement_state = $EnemyStateMachine.CURRENT_STATE.name
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

func block_animation_for(duration: float) -> void :
    _animation_blocked = true
    await get_tree().create_timer(duration).timeout
    _animation_blocked = false

func take_damage(amount: float) -> void :
    if attack_state_machine and attack_state_machine.CURRENT_STATE is ShieldingGearWardenAttackState:
        amount *= 0.25
    current_health -= amount
    print(self, "took damage: ", amount, ", health left: ", current_health)
    if current_health <= 0:
        die()

func die() -> void :
    queue_free()
