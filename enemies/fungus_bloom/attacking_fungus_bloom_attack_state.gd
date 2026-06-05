extends DefaultEnemyAttackState
class_name AttackingFungusBloomAttackState

var damage_timer: Timer
var aoe_damage: float
var aoe_interval: float
var aoe_radius: float
var fungus: FungusBloom
var damage_area: Area3D
var is_active: bool = false
var attack_range: float

func _ready() -> void :
	super._ready()
	await owner.ready
	fungus = owner as FungusBloom
	if fungus:
		aoe_damage = fungus.aoe_damage
		aoe_interval = fungus.aoe_interval
		aoe_radius = fungus.aoe_radius
		attack_range = fungus.attack_range

func enter() -> void :
	super.enter()
	is_active = true

	damage_area = Area3D.new()
	damage_area.name = "AoeDamageArea"
	damage_area.collision_mask = 2
	damage_area.collision_layer = 0

	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = aoe_radius
	shape.shape = sphere_shape
	damage_area.add_child(shape)

	var visual_sphere = MeshInstance3D.new()
	visual_sphere.mesh = SphereMesh.new()
	visual_sphere.mesh.radius = aoe_radius
	visual_sphere.mesh.height = aoe_radius * 2
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.2, 0.8, 0.2, 0.4)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual_sphere.material_override = material
	damage_area.add_child(visual_sphere)

	owner.add_child(damage_area)
	damage_area.global_position = owner.global_position

	damage_timer = Timer.new()
	damage_timer.one_shot = false
	damage_timer.wait_time = aoe_interval
	damage_timer.timeout.connect(_apply_damage)
	owner.add_child(damage_timer)
	damage_timer.start()

func exit() -> void :
	is_active = false
	if damage_timer:
		damage_timer.stop()
		damage_timer.queue_free()
	if damage_area and is_instance_valid(damage_area):
		damage_area.queue_free()

func physics_update(delta: float) -> void :
	if not is_active:
		return
	if damage_area:
		damage_area.global_position = owner.global_position

	if not PLAYER:
		transition.emit("IdleAttackState")
		return

	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist > attack_range or not running_enemy_state.can_see_player():
		transition.emit("IdleAttackState")

func _apply_damage() -> void :
	if not is_active or not damage_area:
		return
	var bodies = damage_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(aoe_damage)
