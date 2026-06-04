extends ArchonAttackState
class_name PhaseTwoSummonArchonAttackState

var boss: ArchonOfBlinding
var summon_count: int
var summon_radius: float
var halo_sentry_scene: PackedScene

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as ArchonOfBlinding
    if boss:
        summon_count = boss.phase2_summon_count
        summon_radius = boss.phase2_summon_radius
        halo_sentry_scene = boss.halo_sentry_scene

func enter() -> void :
    super.enter()
    if halo_sentry_scene:
        for i in range(summon_count):
            var angle = (TAU / summon_count) * i + randf_range(-0.3, 0.3)
            var dist = summon_radius + randf_range(-0.5, 0.5)
            var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
            var spawn_pos = owner.global_position + offset
            spawn_pos.y = 0
            var sentry = halo_sentry_scene.instantiate()
            owner.get_parent().add_child(sentry)
            sentry.global_position = spawn_pos
    boss.block_animation_for(1.0)
    boss.animation_player.play("Spell_Simple_Idle")
    await get_tree().process_frame
    transition.emit("IdleAttackState")
