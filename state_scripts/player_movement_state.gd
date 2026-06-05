class_name PlayerMovementState

extends State

var pivot
var camera
var interact_ray
var recoilposition
var weaponscene

var mouse_movement: Vector2
var random_sway_x
var random_sway_y
var random_sway_amount: float
var time: float = 0.0
var idle_sway_adjustment
var idle_sway_rotation_strength
var weapon_bob_amount: Vector2 = Vector2.ZERO
var sway_noise: NoiseTexture2D
var sway_speed: float = 1.2

@export var SPEED_SPRINTING: float = 7.0
@export var SPEED_DEFAULT: float = 5.0
@export var SPEED_CROUCH: float = 2.0
@export var JUMP_VELOCITY = 4.5

var _speed: float


var shape_cast_3d: ShapeCast3D
@export_range(5, 10, 0.1) var CROUCH_SPEED: float = 7.0

@export var ACCELERATION: float = 0.1
@export var DECELERATION: float = 0.25

var PLAYER: Player
var ANIMATION: AnimationPlayer

func _ready() -> void :
	await owner.ready
	PLAYER = owner as Player
	ANIMATION = PLAYER.get_node("AnimationPlayer") as AnimationPlayer
	pivot = PLAYER.get_node("Pivot") as Node3D
	camera = pivot.get_node("Camera3D") as Camera3D
	interact_ray = camera.get_node("InteractRay") as RayCast3D
	shape_cast_3d = PLAYER.get_node("ShapeCast3D") as ShapeCast3D
	recoilposition = camera.get_node("RecoilPosition")
	weaponscene = recoilposition.get_node("Weapon")

	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_VALUE
	noise.frequency = 0.1
	noise.seed = randi()

	sway_noise = NoiseTexture2D.new()
	sway_noise.noise = noise

func get_direction() -> Vector3:
	var input_dir: = Input.get_vector("left", "right", "forward", "backward")
	var direction = (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	return direction

func _process(delta: float) -> void :
	pass

func mouse_move(event: InputEvent):
	if event is InputEventMouseMotion:
		pivot.rotate_y( - event.relative.x * 0.01)
		camera.rotate_x( - event.relative.y * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(70))

func interact() -> void :
	if interact_ray.is_colliding():
		interact_ray.get_collider().player_interact()


func sway_weapon(delta, IsIdle: bool) -> void :
	if not PLAYER or not PLAYER.weapon_inventory_data:
		return
	var weapon_slot = PLAYER.weapon_inventory_data.slot_datas[0]
	if not weapon_slot or not weapon_slot.item_data is ItemDataWeapon:
		return
	var weapon: = weapon_slot.item_data as ItemDataWeapon

	mouse_movement = mouse_movement.clamp(weapon.sway_min, weapon.sway_max)

	idle_sway_adjustment = weapon.idle_sway_adjustment
	idle_sway_rotation_strength = weapon.idle_sway_rotation_strength
	random_sway_amount = weapon.random_sway_amount

	var sway_random: float = get_sway_noise()
	var sway_random_adjusted: float = sway_random * idle_sway_adjustment

	time += delta * (sway_speed * sway_random)
	random_sway_x = sin(time * 1.5 * sway_random_adjusted) / random_sway_amount
	random_sway_y = sin(time - sway_random_adjusted) / random_sway_amount

	if IsIdle:
		weaponscene.position.x = lerp(weaponscene.position.x, weaponscene.position.x - (mouse_movement.x * weapon.sway_amount_position + random_sway_x) * delta, weapon.sway_speed_position)
		weaponscene.position.y = lerp(weaponscene.position.y, weaponscene.position.y + (mouse_movement.y * weapon.sway_amount_position + random_sway_y) * delta, weapon.sway_speed_position)
		weaponscene.rotation_degrees.y = lerp(weaponscene.rotation_degrees.y, weaponscene.rotation.y + (mouse_movement.x * weapon.sway_amount_rotation + (random_sway_y * idle_sway_rotation_strength)) * delta, weapon.sway_speed_rotation)
		weaponscene.rotation_degrees.x = lerp(weaponscene.rotation_degrees.x, weaponscene.rotation.x + (mouse_movement.y * weapon.sway_amount_rotation + (random_sway_y * idle_sway_rotation_strength)) * delta, weapon.sway_speed_rotation)

	else:

		weaponscene.position.x = lerp(weaponscene.position.x, weaponscene.position.x - (mouse_movement.x * weapon.sway_amount_position + weapon_bob_amount.x) * delta, weapon.sway_speed_position)
		weaponscene.position.y = lerp(weaponscene.position.y, weaponscene.position.y + (mouse_movement.y * weapon.sway_amount_position + weapon_bob_amount.y) * delta, weapon.sway_speed_position)
		weaponscene.rotation_degrees.y = lerp(weaponscene.rotation_degrees.y, weaponscene.rotation.y + (mouse_movement.x * weapon.sway_amount_rotation) * delta, weapon.sway_speed_rotation)
		weaponscene.rotation_degrees.x = lerp(weaponscene.rotation_degrees.x, weaponscene.rotation.x + (mouse_movement.y * weapon.sway_amount_rotation) * delta, weapon.sway_speed_rotation)


		_weapon_bob(delta, 5, 5, 2)

func _weapon_bob(delta, bob_speed: float, hbob_amount: float, vbob_amount: float) -> void :
	time += delta

	weapon_bob_amount.x = sin(time * bob_speed) * hbob_amount
	weapon_bob_amount.y = cos(2.0 * time * bob_speed) * vbob_amount


func get_sway_noise() -> float:
	if PLAYER == null:
		return 0
	var player_position: Vector3 = Vector3.ZERO

	player_position = PLAYER.position

	var noise_location: float = sway_noise.noise.get_noise_2d(player_position.x, player_position.y)
	return noise_location

@onready var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func apply_gravity(delta: float) -> void :
	if not PLAYER.is_on_floor():
		PLAYER.velocity.y -= GRAVITY * delta
	elif PLAYER.velocity.y < 0.0:
		PLAYER.velocity.y = 0.0
