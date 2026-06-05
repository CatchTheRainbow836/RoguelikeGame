extends DefaultEnemyAttackState
class_name ChargingSteamReaverAttackState

var charge_damage: float
var charge_hitbox_radius: float
var trail_damage: float
var trail_duration: float
var pivot: Node3D
var reaver: SteamReaver
var hitbox: Area3D
var trail_timer: Timer
var is_active: bool = false

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	super._ready()
	await owner.ready
	reaver = owner as SteamReaver
	if reaver:
		charge_damage = reaver.melee_damage * reaver.charge_damage_multiplier
		charge_hitbox_radius = reaver.charge_hitbox_radius
		trail_damage = reaver.trail_damage
		trail_duration = reaver.trail_duration
		pivot = owner.get_node("Pivot")

func enter() -> void :
	super.enter()
	is_active = true

	hitbox = Area3D.new()
	hitbox.name = "ChargeHitbox"
	hitbox.collision_mask = 2
	hitbox.collision_layer = 0

	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = charge_hitbox_radius
	hitbox.add_child(shape)

	var damaged_once = false
	hitbox.body_entered.connect( func(body):
		if not is_active or damaged_once:
			return
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(charge_damage)
			damaged_once = true
			var charging_state = reaver.movement_state_machine.get_node("ChargingEnemyState") as ChargingSteamReaverState
			if charging_state:
				var push_dir = charging_state.dash_direction
				body.velocity += push_dir * 20.0
	)

	owner.add_child(hitbox)

	trail_timer = Timer.new()
	trail_timer.one_shot = false
	trail_timer.wait_time = 0.1
	trail_timer.timeout.connect(_create_trail_segment)
	owner.add_child(trail_timer)
	trail_timer.start()

	var exit_timer = Timer.new()
	exit_timer.one_shot = true
	exit_timer.wait_time = reaver.charge_duration + 0.1
	exit_timer.timeout.connect(_on_charge_finished)
	owner.add_child(exit_timer)
	exit_timer.start()

	var anim_length = animation_player.get_animation("Sword_Dash_RM").length
	animation_player.get_animation("Sword_Dash_RM").loop_mode = Animation.LOOP_NONE
	animation_player.play("Sword_Dash_RM")
	reaver.block_animation_for(anim_length)

func _on_charge_finished() -> void :
	if not is_active:
		return
	is_active = false

	if hitbox and is_instance_valid(hitbox):
		hitbox.queue_free()
		hitbox = null

	if trail_timer and is_instance_valid(trail_timer):
		trail_timer.stop()
		trail_timer.queue_free()
		trail_timer = null

	transition.emit("IdleAttackState")

func _create_trail_segment() -> void :
	if not is_instance_valid(owner) or not owner.is_inside_tree():
		return

	var trail = Area3D.new()
	trail.name = "TrailSegment"
	trail.collision_mask = 2
	trail.collision_layer = 0

	var mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = charge_hitbox_radius
	cylinder.bottom_radius = charge_hitbox_radius
	cylinder.height = 0.1
	mesh.mesh = cylinder
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.YELLOW
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.7
	mesh.material_override = material
	trail.add_child(mesh)

	var shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = charge_hitbox_radius
	cylinder_shape.height = 0.1
	shape.shape = cylinder_shape
	trail.add_child(shape)

	var pos = owner.global_position
	pos.y = 0.05

	var bodies_in_trail = []
	trail.body_entered.connect( func(body):
		if body.is_in_group("player") and not bodies_in_trail.has(body):
			bodies_in_trail.append(body)
	)
	trail.body_exited.connect( func(body):
		bodies_in_trail.erase(body)
	)

	var damage_timer = Timer.new()
	damage_timer.one_shot = false
	damage_timer.wait_time = 1.0
	damage_timer.timeout.connect( func():
		for body in bodies_in_trail:
			if is_instance_valid(body) and body.has_method("take_damage"):
				body.take_damage(trail_damage)
	)
	trail.add_child(damage_timer)

	var remove_timer = Timer.new()
	remove_timer.one_shot = true
	remove_timer.wait_time = trail_duration
	remove_timer.timeout.connect( func():
		if is_instance_valid(trail):
			trail.queue_free()
	)
	trail.add_child(remove_timer)

	owner.get_parent().add_child(trail)
	trail.global_position = pos
	damage_timer.start()
	remove_timer.start()

func exit() -> void :
	is_active = false
	if hitbox and is_instance_valid(hitbox):
		hitbox.queue_free()
	if trail_timer and is_instance_valid(trail_timer):
		trail_timer.stop()
		trail_timer.queue_free()
