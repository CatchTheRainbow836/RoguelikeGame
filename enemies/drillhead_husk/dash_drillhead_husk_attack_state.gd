extends DefaultEnemyAttackState
class_name DashDrillheadHuskAttackState

var husk: DrillheadHusk
var dash_damage: float
var has_damaged: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    husk = owner as DrillheadHusk
    if husk:
        dash_damage = husk.dash_damage

func enter() -> void :
    super.enter()
    has_damaged = false
    husk.get_node("EnemyStateMachine").on_child_transition("DashingEnemyState")
    await get_tree().create_timer(0.5).timeout
    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist < 2.0 and not has_damaged:
        PLAYER.take_damage(dash_damage)
        has_damaged = true
    transition.emit("IdleAttackState")

func physics_update(delta: float) -> void :
    if not has_damaged and PLAYER:
        var dist = owner.global_position.distance_to(PLAYER.global_position)
        if dist < 1.5:
            PLAYER.take_damage(dash_damage)
            has_damaged = true
