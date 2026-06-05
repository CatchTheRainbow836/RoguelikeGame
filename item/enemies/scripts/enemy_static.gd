extends StaticBody3D

@export var enemy_resource: Resource
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D


func _ready() -> void :
	mesh_instance_3d.mesh = enemy_resource.mesh
	collision_shape_3d.shape = enemy_resource.collision_shape

func _physics_process(delta: float) -> void :
	if enemy_resource.current_health <= 0:
		visible = false
		await get_tree().create_timer(10).timeout
		enemy_resource.current_health = 10
		visible = true
