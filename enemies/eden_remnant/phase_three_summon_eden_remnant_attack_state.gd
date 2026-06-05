extends EdenRemnantAttackState
class_name PhaseThreeSummonEdenRemnantAttackState

var boss: EdenRemnant
var summon_count: int
var summon_radius: float
var petal_flyer_scene: PackedScene
var is_active: bool = false

func _ready() -> void :
	super._ready()
	await owner.ready
	boss = owner as EdenRemnant
	if boss:
		summon_count = boss.phase3_summon_count
		summon_radius = boss.phase3_summon_radius
		petal_flyer_scene = boss.petal_flyer_scene

func enter() -> void :
	super.enter()
	is_active = true
	perform_summon()
	boss.block_animation_for(1.0)
	boss.animation_player.play("Spell_Simple_Idle")
	transition.emit("IdleAttackState")

func exit() -> void :
	is_active = false

func perform_summon() -> void :
	if not petal_flyer_scene:
		print("No Petal Flyer scene assigned!")
		return
	for i in range(summon_count):
		var angle = (TAU / summon_count) * i + randf_range(-0.3, 0.3)
		var dist = summon_radius + randf_range(-0.5, 0.5)
		var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		var spawn_pos = owner.global_position + offset
		spawn_pos.y = 0
		var flyer = petal_flyer_scene.instantiate()
		owner.get_parent().add_child(flyer)
		flyer.global_position = spawn_pos
