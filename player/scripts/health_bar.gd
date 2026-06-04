extends TextureProgressBar


@onready var player: Player = $"../../.."

func _ready() -> void :
    min_value = 0
    max_value = player.max_health
    value = clamp(player.health, min_value, max_value)

func _physics_process(delta: float) -> void :
    value = clamp(player.health, min_value, max_value)
