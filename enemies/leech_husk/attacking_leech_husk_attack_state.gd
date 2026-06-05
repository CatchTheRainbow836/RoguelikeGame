extends DefaultEnemyAttackState
class_name AttackingLeechHuskAttackState

var leech_timer: Timer
var leech_damage: float
var leech_heal: float
var leech_interval: float
var leech_range: float
var husk: LeechHusk
var leech_area: Area3D
var is_active: bool = false

func _ready() -> void :
	super._ready()
	await owner.ready
	husk = owner as LeechHusk
	if husk:
		leech_damage = husk.leech_damage
		leech_heal = husk.leech_heal
		leech_interval = husk.leech_interval
		leech_range = husk.leech_range

func enter() -> void :
	super.enter()
	is_active = true

	leech_area = Area3D.new()
	leech_area.name = "LeechArea"
	leech_area.collision_mask = 2
	leech_area.collision_layer = 0

	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = leech_range
	shape.shape = sphere_shape
	leech_area.add_child(shape)

	owner.add_child(leech_area)
	leech_area.global_position = owner.global_position

	if leech_timer and leech_timer.is_inside_tree():
		leech_timer.queue_free()
	leech_timer = Timer.new()
	leech_timer.one_shot = false
	leech_timer.wait_time = leech_interval
	leech_timer.timeout.connect(_on_leech_timer_timeout)
	owner.add_child(leech_timer)
	leech_timer.start()

	husk.block_animation_for(0.2)

func exit() -> void :
	is_active = false
	if leech_timer:
		leech_timer.stop()
		leech_timer.queue_free()
	if leech_area and is_instance_valid(leech_area):
		leech_area.queue_free()

func physics_update(delta: float) -> void :
	if not PLAYER or not is_active:
		transition.emit("IdleAttackState")
		return

	if leech_area:
		leech_area.global_position = owner.global_position

	var dist = owner.global_position.distance_to(PLAYER.global_position)
	if dist > leech_range or not running_enemy_state.can_see_player():
		transition.emit("IdleAttackState")

func _on_leech_timer_timeout() -> void :
	if not is_active:
		return

	if not leech_area:
		return

	var bodies = leech_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(leech_damage)
			husk.heal(leech_heal)
			break
