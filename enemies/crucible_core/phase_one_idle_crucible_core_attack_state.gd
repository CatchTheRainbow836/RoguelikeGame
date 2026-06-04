extends CrucibleCoreAttackState
class_name PhaseOneIdleCrucibleCoreAttackState

var spawned_once: bool = false

func enter() -> void :
    super.enter()
    if !spawned_once:
        _spawn_rods()
    await get_tree().process_frame
    transition.emit("AttackingAttackState")

func _spawn_rods() -> void :
    if spawned_once: return

    var boss = owner as CrucibleCore
    var half = boss.arena_half_size - 3
    var corners = [
        Vector3(boss.arena_center.x - half, 0, boss.arena_center.z - half), 
        Vector3(boss.arena_center.x + half, 0, boss.arena_center.z - half), 
        Vector3(boss.arena_center.x - half, 0, boss.arena_center.z + half), 
        Vector3(boss.arena_center.x + half, 0, boss.arena_center.z + half)
    ]
    var rod_scene = preload("uid://spu5tdkqx8jr") as PackedScene
    for pos in corners:
        var rod = rod_scene.instantiate()
        get_tree().current_scene.add_child(rod)
        rod.global_position = pos
        rod.global_position.y = 0
        boss.spawning_rods.append(rod)

    spawned_once = true
