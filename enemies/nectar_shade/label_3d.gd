extends Label3D

@onready var enemy_state_machine: StateMachine = $"../EnemyStateMachine"

@onready var attack_state_machine: StateMachine = $"../AttackStateMachine"


func _process(delta: float) -> void :

	var target_enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	var best_enemy = null
	var best_path_length = INF

	var map = owner.get_node("NavigationAgent3D").get_navigation_map()
	var start = owner.global_position

	for enemy in enemies:
		if enemy == owner:
			continue
		var end = enemy.global_position
		var path = NavigationServer3D.map_get_path(map, start, end, true)
		var path_length = 0.0
		for i in range(path.size() - 1):
			path_length += path[i].distance_to(path[i + 1])
		if path_length < best_path_length:
			best_path_length = path_length
			best_enemy = enemy

	target_enemy = best_enemy

	text = "Nectar Shade" + "\n" + enemy_state_machine.CURRENT_STATE.name + "\n" + attack_state_machine.CURRENT_STATE.name + "\n" + "can_see_player: " + str(enemy_state_machine.get_node("RunningEnemyState").can_see_player()) + "\n" + "alertness: " + str(AlertnessManager.get_alert_value(owner.global_position)) + "\n" + "alert timer: " + str(enemy_state_machine.get_node("RunningEnemyState").alert_timer) + "\n" + "target enemy: " + str(target_enemy) + ", distance: " + str(best_path_length)
