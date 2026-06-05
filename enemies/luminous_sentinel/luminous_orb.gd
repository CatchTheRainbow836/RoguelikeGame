extends Node3D
class_name LuminousOrb

@export var speed: float = 2.5
@export var damage: float = 6.0
@export var lifetime: float = 10.0
@export var light_energy: float = 2.0

var target: CharacterBody3D = null
var elapsed: float = 0.0

@onready var mesh = $MeshInstance3D
@onready var light = $OmniLight3D
@onready var area = $Area3D
@onready var collision_shape = $CollisionShape3D

func _ready() -> void :
	target = get_tree().get_first_node_in_group("player")
	if not target:
		queue_free()
		return

	light.light_energy = light_energy
	mesh.rotate_y(randf_range(0, TAU))

	area.collision_mask = 2

func _process(delta: float) -> void :
	elapsed += delta
	if elapsed >= lifetime:
		_explode()
		queue_free()
		return

	if target and is_instance_valid(target):
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * speed * delta
		global_position.y = 1.0
		if direction.length_squared() > 0.01:
			look_at(global_position + direction, Vector3.UP)

func take_damage(_amount: float) -> void :
	_explode()
	queue_free()

func _explode() -> void :
	var tween = create_tween()
	tween.tween_property(mesh, "scale", Vector3.ZERO, 0.1)
	tween.parallel().tween_property(light, "light_energy", 0.0, 0.1)
	await tween.finished

func _on_area_3d_body_entered(body: Node3D) -> void :
	if body.is_in_group("player") and body.has_method("take_damage"):
		print("Orb hit player, dealing damage: ", damage)
		body.take_damage(damage)
		_explode()
		queue_free()
