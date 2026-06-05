extends CrucibleCoreAttackState
class_name PhaseOneAttackingCrucibleCoreAttackState

var boss: CrucibleCore
var damage_dealt: bool = false

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as CrucibleCore

func _process(delta: float) -> void :
	var all_dead: bool = true
	for rod in boss.spawning_rods:
		if is_instance_valid(rod) and rod.has_method("is_alive") and rod.is_alive():
			all_dead = false
			break
	if all_dead and not damage_dealt:
		var spawned_enemies = get_tree().get_nodes_in_group("spawned_enemies")
		for enemy in spawned_enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()

		boss.take_damage(boss.max_health * 0.4)
		damage_dealt = true
		for rod in boss.spawning_rods:
			if is_instance_valid(rod):
				rod.queue_free()
		boss.spawning_rods.clear()
		await get_tree().process_frame
		boss.top_state_machine.on_child_transition("PhaseTwoStateMachine")
		boss.setup_phase2_environment()

func enter() -> void :
	super.enter()
