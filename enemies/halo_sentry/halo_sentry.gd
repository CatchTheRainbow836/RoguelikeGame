extends CharacterBody3D
class_name HaloSentry

@export var max_health: float = 50.0
@export var melee_damage: float = 12.0
@export var explosion_damage: float = 20.0
@export var explosion_radius: float = 3.0
@export var melee_range: float = 5
@export var preferred_distance: float = 2.0
@export var melee_cooldown: float = 3.0
@export var shield_regen_time: float = 8.0
@export var speed: float = 5.0
@export var accel: float = 10.0
@export var turn_speed: float = 6.0
@export var wander_radius: float = 8.0
@export var view_distance: float = 20.0
@export var fov_degrees: float = 360.0
@export var alert_duration: float = 5.0

@export var target_altitude: float = 1.5
@export var altitude_tolerance: float = 0.3
@export var bob_amplitude: float = 0.2
@export var bob_frequency: float = 2.0

@export var ring_count: int = 3

var current_health: float
var shield_active: bool = true
var shield_mesh: MeshInstance3D
var rings: Array[MeshInstance3D] = []
var ring_rotations: Array[Vector3] = []
var ring_rotate_speed: float = 1.2
var _animation_blocked: bool = false
var bob_phase: float = 0.0
var shield_regenerating: bool = false

@onready var animation_player = $Pivot.get_node("exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
	add_to_group("halo_sentry")
	current_health = max_health
	bob_phase = randf_range(0, TAU)
	_create_shield()
	_create_rings()

func _process(delta: float) -> void :
	_update_animation()
	_rotate_rings(delta)

func _update_animation() -> void :
	if _animation_blocked:
		return

	var attack_state = $AttackStateMachine.CURRENT_STATE.name
	if attack_state == "MeleeAttackState" or attack_state == "ExplodeAttackState":
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

func _create_shield() -> void :
	shield_mesh = MeshInstance3D.new()
	shield_mesh.mesh = SphereMesh.new()
	shield_mesh.mesh.radius = 0.5
	shield_mesh.mesh.height = 1.0
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.8, 1.0, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shield_mesh.material_override = material
	$Pivot.add_child(shield_mesh)
	shield_mesh.position = Vector3.ZERO

func _create_rings() -> void :
	for old_ring in rings:
		if is_instance_valid(old_ring):
			old_ring.queue_free()
	rings.clear()

	var count: int = max(ring_count, 1)
	for i in range(count):
		var ring = MeshInstance3D.new()
		ring.mesh = TorusMesh.new()
		ring.mesh.inner_radius = 0.6
		ring.mesh.outer_radius = 0.65

		var ring_material = StandardMaterial3D.new()
		ring_material.albedo_color = Color(0.4, 0.7, 1.0, 1.0)
		ring.material_override = ring_material

		$Pivot.add_child(ring)
		ring.rotation = Vector3.ZERO

		var ring_ratio: = 0.0
		if count > 1:
			ring_ratio = float(i) / float(count - 1)

		ring.set_meta("phase", TAU * float(i) / float(count))
		ring.set_meta("spin_speed", ring_rotate_speed * (0.8 + ring_ratio * 0.35))
		ring.set_meta("orbit_speed", ring_rotate_speed * (0.35 + ring_ratio * 0.25))
		ring.set_meta("tilt_amount", lerp(deg_to_rad(20.0), deg_to_rad(65.0), ring_ratio))
		ring.set_meta("spin_axis", "x" if i % 2 == 0 else "z")

		rings.append(ring)

func _rotate_rings(delta: float) -> void :
	var time: = Time.get_ticks_msec() * 0.001

	for ring in rings:
		if not is_instance_valid(ring):
			continue

		var phase: = ring.get_meta("phase") as float
		var spin_speed: = ring.get_meta("spin_speed") as float
		var orbit_speed: = ring.get_meta("orbit_speed") as float
		var tilt_amount: = ring.get_meta("tilt_amount") as float
		var spin_axis: = ring.get_meta("spin_axis") as String

		var orbit_t: = time * orbit_speed + phase
		var spin_t: = time * spin_speed

		var x_tilt: = sin(orbit_t) * tilt_amount
		var z_tilt: = cos(orbit_t) * tilt_amount

		if spin_axis == "x":
			ring.rotation = Vector3(x_tilt + spin_t, 0.0, z_tilt)
		else:
			ring.rotation = Vector3(x_tilt, 0.0, z_tilt + spin_t)

func break_shield() -> void :
	if not shield_active:
		return

	shield_active = false

	var tween = create_tween()
	tween.tween_property(shield_mesh.material_override, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback( func():
		shield_mesh.visible = false
	)

	$AttackStateMachine.on_child_transition("ExplodeAttackState")

func regenerate_shield() -> void :
	if shield_active:
		return

	shield_active = true
	shield_mesh.visible = true

	var material = shield_mesh.material_override.duplicate()
	material.albedo_color.a = 0.0
	shield_mesh.material_override = material

	var tween = create_tween()
	tween.tween_property(material, "albedo_color:a", 0.4, 0.5)

func take_damage(amount: float) -> void :
	if shield_active:
		break_shield()
		return

	current_health -= amount
	print(self, " took damage: ", amount, ", health left: ", current_health)
	if current_health <= 0:
		die()

func die() -> void :
	queue_free()

func maintain_altitude(delta: float) -> void :
	var current_y = global_position.y
	var target_y = target_altitude + sin(bob_phase) * bob_amplitude
	bob_phase += bob_frequency * delta
	var y_error = target_y - current_y
	if abs(y_error) > altitude_tolerance:
		velocity.y = move_toward(velocity.y, y_error * 5.0, accel * delta)
	else:
		velocity.y = move_toward(velocity.y, 0.0, accel * delta)

func start_shield_regen() -> void :
	if shield_regenerating or shield_active:
		return
	shield_regenerating = true
	await get_tree().create_timer(shield_regen_time).timeout
	regenerate_shield()
