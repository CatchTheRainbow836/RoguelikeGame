extends CharacterBody3D
class_name FungusBloom

@export var max_health: float = 50.0
@export var aoe_damage: float = 5.0
@export var aoe_interval: float = 0.5
@export var aoe_radius: float = 10
@export var attack_range: float = 8.0
@export var view_distance: float = 15.0
@export var underground_offset: float = 0.8

var current_health: float
var original_height: float = 0.0
var is_underground: bool = true
var _animation_blocked: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
@onready var collision_shape = $CollisionShape3D

func _ready() -> void :
    add_to_group("fungus_bloom")
    current_health = max_health
    original_height = collision_shape.shape.height

    underground_offset = original_height * 0.8
    global_position.y -= underground_offset

func _process(delta: float) -> void :
    _update_animation()

func _update_animation() -> void :
    if _animation_blocked:
        return

    var attack_state = $AttackStateMachine.CURRENT_STATE.name
    if attack_state == "AttackingAttackState":

        if animation_player.current_animation != "Swim_Idle":
            animation_player.play("Swim_Idle")
        return

    var movement_state = $EnemyStateMachine.CURRENT_STATE.name
    var anim_name = ""
    match movement_state:
        "IdleEnemyState":
            anim_name = "Fighting Idle"
        "WalkingEnemyState", "RunningEnemyState":
            anim_name = "Fighting Idle"
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

func pop_up() -> void :
    if not is_underground:
        return
    is_underground = false
    var tween = create_tween()
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_EXPO)
    tween.tween_property(self, "global_position:y", 0, 0.5)

func pop_down() -> void :
    if is_underground:
        return
    is_underground = true
    var tween = create_tween()
    tween.set_ease(Tween.EASE_IN)
    tween.set_trans(Tween.TRANS_EXPO)
    tween.tween_property(self, "global_position:y", - underground_offset, 0.5)
