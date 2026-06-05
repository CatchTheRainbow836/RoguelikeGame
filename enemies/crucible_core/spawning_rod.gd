extends StaticBody3D
class_name SpawningRod

@export var max_health: int = 50
@export var max_spawned_enemies: int = 20

var current_health: int
var spawn_timer: Timer
var enemies_to_spawn: Array = []

func _ready() -> void :
	current_health = max_health
	enemies_to_spawn = [
		{"scene": preload("uid://cdpgbybnjn0nt"), "weight": 3, "count": 3}, 
		{"scene": preload("uid://cicny0lttecf2"), "weight": 2, "count": 2}, 
		{"scene": preload("uid://dweefp20aumai"), "weight": 1, "count": 1}, 
		{"scene": preload("uid://d0x8tljcdlxgt"), "weight": 1, "count": 1}
	]
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 5.0
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_spawn_enemies)
	add_child(spawn_timer)
	spawn_timer.start()

func _spawn_enemies() -> void :
	var spawned_count = get_tree().get_nodes_in_group("spawned_enemies").size()
	if spawned_count >= max_spawned_enemies:
		return

	var total_weight = 0
	for e in enemies_to_spawn:
		total_weight += e["weight"]
	var rand_val = randi_range(1, total_weight)
	var cumulative = 0
	var chosen = null
	for e in enemies_to_spawn:
		cumulative += e["weight"]
		if rand_val <= cumulative:
			chosen = e
			break
	if chosen:
		for i in range(chosen["count"]):
			if get_tree().get_nodes_in_group("spawned_enemies").size() >= max_spawned_enemies:
				break
			var enemy = chosen["scene"].instantiate()
			get_tree().current_scene.add_child(enemy)
			enemy.add_to_group("spawned_enemies")
			var offset = Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
			enemy.global_position = global_position + offset
			enemy.global_position.y = 0

func take_damage(amount: float) -> void :
	current_health -= amount
	if current_health <= 0:
		_die()

func _die() -> void :
	spawn_timer.stop()
	queue_free()

func is_alive() -> bool:
	return current_health > 0
