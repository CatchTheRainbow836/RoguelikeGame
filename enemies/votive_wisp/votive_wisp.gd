extends CharacterBody3D
class_name VotiveWisp


@export var max_health: float = 1.0
@export var explosion_damage: float = 15.0
@export var explosion_radius: float = 2.5

@export var knockback_force: float = 12.0
@export var post_shield_knockback_force: float = 100.0

@export var knockback_decay: float = 0.95

@export var max_chase_speed: float = 18.0
@export var chase_acceleration: float = 8.0
@export var hover_amplitude: float = 0.5
@export var hover_frequency: float = 0.5

var current_health: float
var shield_broken: bool = false

var current_velocity: Vector3 = Vector3.ZERO
var knockback_velocity: Vector3 = Vector3.ZERO
var chase_speed: float = 0.0
var initial_knockback_active: bool = false

var _animation_blocked: bool = false
var shield_sphere: MeshInstance3D

@onready var animation_player: = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer
@onready var pivot: = $Pivot


func _ready() -> void :
    add_to_group("votive_wisp")
    current_health = max_health
    shield_broken = false
    _create_shield_sphere()


func _create_shield_sphere() -> void :
    shield_sphere = MeshInstance3D.new()
    shield_sphere.mesh = SphereMesh.new()
    (shield_sphere.mesh as SphereMesh).radius = 0.6
    (shield_sphere.mesh as SphereMesh).height = 1.2

    var material: = StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.9, 0.5, 0.3)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    shield_sphere.material_override = material

    pivot.add_child(shield_sphere)
    shield_sphere.position = Vector3.ZERO


func _process(delta: float) -> void :
    _update_animation()


func _update_animation() -> void :
    if _animation_blocked:
        return
    if animation_player.current_animation != "Flying Forward":
        animation_player.play("Flying Forward")


func block_animation_for(duration: float) -> void :
    _animation_blocked = true
    await get_tree().create_timer(duration).timeout
    _animation_blocked = false


func _get_knockback_direction(hit_direction: Vector3) -> Vector3:
    if hit_direction.length_squared() > 1e-06:
        return hit_direction.normalized()

    var player: = get_tree().get_first_node_in_group("player")
    if player is Node3D:
        var away_from_player: = global_position - (player as Node3D).global_position
        if away_from_player.length_squared() > 1e-06:
            return away_from_player.normalized()

    return - global_transform.basis.z.normalized()


func _apply_knockback(hit_direction: Vector3, force: float) -> void :
    var dir: = _get_knockback_direction(hit_direction)
    knockback_velocity = dir * force
    current_velocity = knockback_velocity
    velocity = current_velocity


func take_damage(amount: float, hit_direction: Vector3 = Vector3.ZERO, is_parry: bool = false) -> void :
    if shield_broken:
        var force: float = max(post_shield_knockback_force, max_chase_speed * 1.25)
        initial_knockback_active = false
        _apply_knockback(hit_direction, force)
        return

    shield_broken = true
    initial_knockback_active = true

    if is_instance_valid(shield_sphere):
        shield_sphere.queue_free()

    chase_speed = 0.0
    _apply_knockback(hit_direction, knockback_force)

    $EnemyStateMachine.on_child_transition("RunningEnemyState")
    $AttackStateMachine.on_child_transition("AttackingAttackState")


func die() -> void :
    queue_free()
