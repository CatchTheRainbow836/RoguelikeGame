extends FurnaceColossusAttackState
class_name PhaseTwoSummonFurnaceColossusAttackState

var summon_count: int
var summon_radius: float
var arc_turret_scene: PackedScene
var is_active: bool = false
var running_state: PhaseTwoRunningFurnaceColossusState

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer


func _ready() -> void :
    super._ready()
    await owner.ready
    var colossus = owner as FurnaceColossus
    if colossus:
        summon_count = colossus.summon_count
        summon_radius = colossus.summon_radius
        arc_turret_scene = colossus.arc_turret_scene
    var phase_sm = owner.top_state_machine.CURRENT_STATE
    if phase_sm:
        running_state = phase_sm.get_node("EnemyStateMachine/RunningEnemyState") as PhaseTwoRunningFurnaceColossusState
        if running_state:
            running_state.connect("can_attack", _on_can_attack)

func enter() -> void :
    print("entered SummonAttackState")
    is_active = true
    perform_summon()
    transition.emit("IdleAttackState")

func exit() -> void :
    is_active = false

    animation_player.stop()

func _on_can_attack(active: bool) -> void :
    pass

func perform_summon() -> void :
    if not arc_turret_scene:
        print("No Arc Turret scene assigned!")
        return
    for i in summon_count:
        var angle = randf_range(0, TAU)
        var dist = randf_range(0, summon_radius)
        var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
        var spawn_pos = owner.global_position + offset
        spawn_pos.y = 0
        var turret = arc_turret_scene.instantiate()
        owner.get_parent().add_child(turret)
        turret.global_position = spawn_pos

    animation_player.get_animation("Swim_Idle").loop_mode = Animation.LOOP_NONE
    animation_player.play("Swim_Idle")
