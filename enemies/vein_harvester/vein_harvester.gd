extends CharacterBody3D
class_name VeinHarvester

@export var max_health: float = 45.0

@export var speed: float = 6.0
@export var accel: float = 8.0
@export var turn_speed: float = 5.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 20.0
@export var fov_degrees: float = 90.0
@export var alert_duration: float = 5.0
@export var preferred_distance: float = 8.0
@export var strafe_speed: float = 1.0

@export var target_altitude: float = 1.5
@export var altitude_tolerance: float = 0.3
@export var bob_amplitude: float = 0.2
@export var bob_frequency: float = 2.0

@export var trap_damage: float = 20.0
@export var trap_stun_duration: float = 1.5
@export var trap_lifetime: float = 8.0
@export var trap_cooldown: float = 5.0
@export var trap_fall_height: float = 4.0
@export var trap_radius: float = 2.0
@export var trap_fall_speed: float = 6.0

@export var grenade_damage: float = 12.0
@export var grenade_cooldown: float = 2.5
@export var grenade_bounce_count: int = 3
@export var grenade_speed: float = 10.0
@export var grenade_radius: float = 0.05

var current_health: float
var bob_phase: float = 0.0
var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    add_to_group("vein_harvester")
    current_health = max_health
    bob_phase = randf_range(0, TAU)

func _process(delta: float) -> void :
    _update_animation()

func _update_animation() -> void :
    if _animation_blocked:
        return
    var attack_state = $AttackStateMachine.CURRENT_STATE.name
    if attack_state == "AttackingAttackState" or attack_state == "ExplodeAttackState":
        return
    var movement_state = $EnemyStateMachine.CURRENT_STATE.name
    var anim_name = ""
    match movement_state:
        "IdleEnemyState", "WalkingEnemyState":
            anim_name = "Flying Forward"
        "RunningEnemyState":
            anim_name = "Flying Forward Super"
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

func die() -> void :
    queue_free()

func maintain_altitude(delta: float, velocity_ref: Vector3) -> Vector3:
    var current_y = global_position.y
    var target_y = target_altitude + sin(bob_phase) * bob_amplitude
    bob_phase += bob_frequency * delta
    var y_error = target_y - current_y
    if abs(y_error) > altitude_tolerance:
        velocity_ref.y = move_toward(velocity_ref.y, y_error * 5.0, accel * delta)
    else:
        velocity_ref.y = move_toward(velocity_ref.y, 0.0, accel * delta)
    return velocity_ref
