extends DefaultEnemyAttackState
class_name AttackingBloomHeraldAttackState

var summon_count: int
var summon_radius: float
var herald: BloomHerald
var transition_timer: Timer

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    herald = owner as BloomHerald
    if herald:
        summon_count = herald.summon_count
        summon_radius = herald.summon_radius

func enter() -> void :
    super.enter()
    print("bloom herald entered attacking state")

    perform_summon()

    herald.last_attack_time = Time.get_ticks_msec() / 1000.0

    transition_timer = Timer.new()
    transition_timer.one_shot = true
    transition_timer.wait_time = 0.1
    transition_timer.timeout.connect(_on_transition_timer_timeout)
    owner.add_child(transition_timer)
    transition_timer.start()

func exit() -> void :
    print("bloom herald exited attacking state")
    if transition_timer and transition_timer.is_inside_tree():
        transition_timer.stop()
        transition_timer.queue_free()
    animation_player.stop()

func physics_update(delta: float) -> void :
    pass

func _on_transition_timer_timeout() -> void :
    print("bloom herald transitioning to idle attack state")
    transition.emit("IdleAttackState")

func perform_summon() -> void :
    if not herald.thorned_gardener_scene:
        print("No Thorned Gardener scene assigned to Bloom Herald!")
        return

    for i in summon_count:
        var angle = (TAU / summon_count) * i + randf_range(-0.3, 0.3)
        var dist = summon_radius + randf_range(-0.5, 0.5)
        var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
        var spawn_pos = owner.global_position + offset
        spawn_pos.y = 0
        var gardener = herald.thorned_gardener_scene.instantiate()
        owner.get_parent().add_child(gardener)
        gardener.global_position = spawn_pos

    print("bloom herald summoned ", summon_count, " thorned gardeners")

    var anim_name = "Swim_Idle"
    if animation_player.has_animation(anim_name):
        animation_player.play(anim_name)
        herald.block_animation_for(animation_player.get_animation(anim_name).length)
