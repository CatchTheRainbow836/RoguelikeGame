extends DefaultEnemyAttackState
class_name AttackingNectarShadeAttackState

var heal_timer: Timer
var heal_amount: float
var heal_range: float
var heal_interval: float
var shade: NectarShade
var is_active: bool = false

func _ready() -> void :
	super._ready()
	await owner.ready
	shade = owner as NectarShade
	if shade:
		heal_amount = shade.heal_amount
		heal_range = shade.heal_range
		heal_interval = shade.heal_interval

func enter() -> void :
	super.enter()
	is_active = true
	if heal_timer and heal_timer.is_inside_tree():
		heal_timer.queue_free()
	heal_timer = Timer.new()
	heal_timer.one_shot = false
	heal_timer.wait_time = heal_interval
	heal_timer.timeout.connect(_on_heal_timer_timeout)
	owner.add_child(heal_timer)
	heal_timer.start()
	_perform_heal()

func exit() -> void :
	is_active = false
	if heal_timer:
		heal_timer.stop()
		heal_timer.queue_free()

func physics_update(delta: float) -> void :
	var enemies_in_range = false
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == owner:
			continue
		var is_enemy = enemy.is_in_group("enemies")
		if not is_enemy:
			continue
		var dist = owner.global_position.distance_to(enemy.global_position)
		if dist <= heal_range:
			enemies_in_range = true
			break

	if not enemies_in_range:
		transition.emit("IdleAttackState")

func _on_heal_timer_timeout() -> void :
	if not is_active:
		return
	_perform_heal()

func _perform_heal() -> void :
	if not is_active:
		return

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == owner:
			continue
		var is_enemy = enemy.is_in_group("enemies")
		if not is_enemy:
			continue
		var dist = owner.global_position.distance_to(enemy.global_position)
		if dist <= heal_range:
			if enemy.has_method("take_damage"):
				if enemy.current_health + heal_amount <= enemy.max_health:
					enemy.take_damage( - heal_amount)
				else:
					enemy.current_health = enemy.max_health
