extends LeviathanAttackState
class_name PhaseThreeSummonLeviathanAttackState

var boss: Leviathan
var summon_count: int
var summon_radius: float
var tidebearer_scene: PackedScene

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as Leviathan
	if boss:
		summon_count = boss.phase3_summon_count
		summon_radius = boss.phase3_summon_radius
		tidebearer_scene = boss.tidebearer_scene

func enter() -> void :
	super.enter()
	var current_count = get_tree().get_nodes_in_group("tidebearer").size()
	if current_count < boss.phase3_max_tidebearers:
		perform_summon()
	else:
		pass
	await get_tree().process_frame
	transition.emit("IdleAttackState")

func perform_summon() -> void :
	if not tidebearer_scene:
		print("No Tidebearer scene assigned!")
		return
	for i in range(summon_count):
		var angle = (TAU / summon_count) * i + randf_range(-0.3, 0.3)
		var dist = summon_radius + randf_range(-0.5, 0.5)
		var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		var spawn_pos = owner.global_position + offset
		spawn_pos.y = 0
		var bearer = tidebearer_scene.instantiate()
		bearer.add_to_group("tidebearer")
		owner.get_parent().add_child(bearer)
		bearer.global_position = spawn_pos
	boss.block_animation_for(1.0)
	boss.animation_player.play("Spell_Simple_Idle")
