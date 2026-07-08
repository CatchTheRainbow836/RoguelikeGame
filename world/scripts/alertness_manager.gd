extends Node

const FALLOFF_DISTANCE: float = 5.0
const UPDATE_INTERVAL: float = 0.01

const DEFAULT_LIFETIME: float = 0.02
const DETECTION_THRESHOLD: float = 0.5
const EPSILON: float = 0.01

const PLAYER_ALERT_INTERVAL: float = 0.01

@export var visual_grid_radius: float = 15.0
@export var max_cubes: int = 2500

var _alerts: Array = []
var _update_timer: Timer
var _visual_holder: Node3D
var _visual_update_counter: int = 0
const VISUAL_UPDATE_STEP: int = 0

func _ready() -> void :
	_visual_holder = Node3D.new()
	_visual_holder.name = "AlertVisuals"
	add_child(_visual_holder)

	_update_timer = Timer.new()
	_update_timer.wait_time = UPDATE_INTERVAL
	_update_timer.autostart = true
	_update_timer.timeout.connect(_on_update_timer)
	add_child(_update_timer)

func add_alert(position: Vector3, intensity: float) -> void :
	_alerts.append({
		"position": position, 
		"intensity": intensity, 
		"lifetime": DEFAULT_LIFETIME
	})

func get_alert_value(position: Vector3) -> float:
	var total: float = 0.0
	for alert in _alerts:
		var dist = position.distance_to(alert.position)
		var contribution = alert.intensity * exp( - dist / FALLOFF_DISTANCE)
		total += contribution
	return total

func _on_update_timer() -> void :
	_expire_old_alerts()


func _expire_old_alerts() -> void :
	for i in range(_alerts.size() - 1, -1, -1):
		_alerts[i].lifetime -= UPDATE_INTERVAL
		if _alerts[i].lifetime <= 0.0:
			_alerts.remove_at(i)

func _radius_for_alert(intensity: float, target_value: float) -> float:
	if intensity <= 0.0 or target_value <= 0.0:
		return 0.0

	var ratio = target_value / intensity
	if ratio >= 1.0:
		return 0.0
	return - FALLOFF_DISTANCE * log(ratio)

func _update_visuals() -> void :
	for child in _visual_holder.get_children():
		child.queue_free()

	if _alerts.is_empty():
		return

	var centroid = Vector3.ZERO
	for alert in _alerts:
		centroid += alert.position
	centroid /= _alerts.size()

	var max_red_radius = 0.0
	var max_yellow_radius = 0.0

	for alert in _alerts:
		var red_r = _radius_for_alert(alert.intensity, DETECTION_THRESHOLD)
		var yellow_r = _radius_for_alert(alert.intensity, EPSILON)

		var dist_from_centroid = centroid.distance_to(alert.position)
		max_red_radius = max(max_red_radius, dist_from_centroid + red_r)
		max_yellow_radius = max(max_yellow_radius, dist_from_centroid + yellow_r)

	max_red_radius += 0.5
	max_yellow_radius += 0.5

	if max_red_radius > 0.0:
		var red_cylinder = _create_cylinder_mesh(max_red_radius, Color.RED, 0.3)
		red_cylinder.position = centroid
		_visual_holder.add_child(red_cylinder)

	if max_yellow_radius > 0.0 and max_yellow_radius > max_red_radius + 0.2:
		var yellow_cylinder = _create_cylinder_mesh(max_yellow_radius, Color.YELLOW, 0.1)
		yellow_cylinder.position = centroid
		_visual_holder.add_child(yellow_cylinder)

func _create_cylinder_mesh(radius: float, color: Color, alpha: float) -> MeshInstance3D:
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = 0.1
	cylinder_mesh.radial_segments = 32

	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.albedo_color.a = alpha
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = cylinder_mesh
	mesh_instance.material_override = material
	return mesh_instance
