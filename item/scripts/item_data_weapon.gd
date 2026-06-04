extends ItemData
class_name ItemDataWeapon

@export var model_scene: PackedScene
@export var damage: int
@export var range: int
@export var type: int
@export var reload_time: float
@export var swing_forward_speed: float
@export var swing_backward_speed: float

@export var bullets_loaded: int = 0
@export var max_bullets_loaded: int

@export var sway_min: Vector2 = Vector2(-20, -20)
@export var sway_max: Vector2 = Vector2(20, 20)
@export_range(0, 0.2, 0.01) var sway_speed_position: float = 0.07
@export_range(0, 0.2, 0.01) var sway_speed_rotation: float = 0.1
@export_range(0, 0.25, 0.01) var sway_amount_position: float = 0.1
@export_range(0, 50, 0.1) var sway_amount_rotation: float = 30.0
@export var idle_sway_adjustment: float = 10
@export var idle_sway_rotation_strength: float = 300.0
@export_range(0.1, 10, 0.1) var random_sway_amount: float = 5.0
