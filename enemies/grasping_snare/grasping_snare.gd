extends CharacterBody3D
class_name GraspingSnare

@export var max_health: float = 30.0
@export var latch_range_horizontal: float = 1.5
@export var pull_speed: float = 0.5
@export var damage_interval: float = 0.5
@export var damage_per_tick: float = 5.0
@export var close_distance: float = 0.5

var current_health: float
var is_latched: bool = false
var rope_container: Node3D = null
var pull_tween: Tween = null
var damage_timer: Timer = null
var _animation_blocked: bool = false
var enemy_bottom_y: float = 0.0

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
@onready var collision_shape = $CollisionShape3D

func _ready() -> void :
    add_to_group("grasping_snare")
    current_health = max_health
    var shape_height = 0.5
    shape_height = collision_shape.shape.height
    enemy_bottom_y = 4.0 - shape_height
    global_position.y = enemy_bottom_y

func _process(delta: float) -> void :
    _update_animation()

func _update_animation() -> void :
    if _animation_blocked:
        return
    if animation_player.current_animation != "Fighting Idle":
        animation_player.play("Fighting Idle")

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
    if is_latched:
        _release_player()
    queue_free()

func _release_player() -> void :
    if not is_latched:
        return
    is_latched = false
    if pull_tween and pull_tween.is_valid():
        pull_tween.kill()
    if damage_timer:
        damage_timer.stop()
        damage_timer.queue_free()
    if rope_container:
        rope_container.queue_free()
        rope_container = null
