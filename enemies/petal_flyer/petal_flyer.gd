extends CharacterBody3D
class_name PetalFlyer

@export var max_health: float = 20.0
@export var explosion_damage: float = 15.0
@export var explosion_radius: float = 3.0
@export var speed: float = 12.0
@export var accel: float = 15.0
@export var turn_speed: float = 3.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 25.0
@export var fov_degrees: float = 180.0
@export var alert_duration: float = 5.0

@export var target_altitude: float = 1.5
@export var altitude_tolerance: float = 0.3
@export var bob_amplitude: float = 0.2
@export var bob_frequency: float = 2.0

var current_health: float
var attack_state_machine: StateMachine
var movement_state_machine: StateMachine
var bob_phase: float = 0.0
var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    add_to_group("enemies")
    add_to_group("petal_flyer")
    current_health = max_health
    attack_state_machine = $AttackStateMachine
    movement_state_machine = $EnemyStateMachine
    bob_phase = randf_range(0, TAU)

    var self_destruct_timer = Timer.new()
    self_destruct_timer.wait_time = 20.0
    self_destruct_timer.one_shot = true
    self_destruct_timer.timeout.connect( func(c):
        owner.queue_free()
        print(name, " didn't move, self destructed")
        )
    self_destruct_timer.name = "SELF_DESTRUCT_TIMER"
    add_child(self_destruct_timer)
    self_destruct_timer.start()


func _process(delta: float) -> void :

    if velocity > Vector3.ZERO and get_node_or_null("SELF_DESTRUCT_TIMER"):
        get_node("SELF_DESTRUCT_TIMER").queue_free()

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
