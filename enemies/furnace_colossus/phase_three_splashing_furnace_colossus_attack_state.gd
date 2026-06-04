extends FurnaceColossusAttackState
class_name PhaseThreeSplashingFurnaceColossusAttackState

var splash_count: int
var splash_radius: float
var splash_damage: float
var splash_duration: float
var is_active: bool = false
var running_state: PhaseThreeRunningFurnaceColossusState

@onready var animation_player = owner.get_node("Pivot/exported-model/AnimationPlayer") as AnimationPlayer

func _ready() -> void :
    super._ready()
    await owner.ready
    var colossus = owner as FurnaceColossus
    if colossus:
        splash_count = colossus.splash_count
        splash_radius = colossus.splash_radius
        splash_damage = colossus.splash_damage
        splash_duration = colossus.splash_duration
    var phase_sm = owner.top_state_machine.CURRENT_STATE
    if phase_sm:
        running_state = phase_sm.get_node("EnemyStateMachine/RunningEnemyState") as PhaseThreeRunningFurnaceColossusState
        if running_state:
            running_state.connect("can_attack", _on_can_attack)

func enter() -> void :
    print("entered SplashingAttackState")
    is_active = true
    create_splashes()
    transition.emit("IdleAttackState")

func exit() -> void :
    is_active = false

    animation_player.stop()

func _on_can_attack(active: bool) -> void :
    pass

func create_splashes() -> void :
    for i in splash_count:

        var angle = randf_range(0, TAU)
        var dist = randf_range(1.0, 3.0)
        var offset = Vector3(cos(angle) * dist, 0, sin(angle) * dist)
        var pos = owner.global_position + offset
        pos.y = 0.05

        var splash = Area3D.new()
        splash.name = "SplashArea"
        splash.collision_mask = 2
        splash.collision_layer = 0

        var shape = CollisionShape3D.new()
        shape.shape = CylinderShape3D.new()
        shape.shape.radius = splash_radius
        shape.shape.height = 0.1
        splash.add_child(shape)

        var mesh = MeshInstance3D.new()
        var cylinder = CylinderMesh.new()
        cylinder.top_radius = splash_radius
        cylinder.bottom_radius = splash_radius
        cylinder.height = 0.1
        mesh.mesh = cylinder
        var material = StandardMaterial3D.new()
        material.albedo_color = Color(1, 0.5, 0, 0.5)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
        mesh.material_override = material
        splash.add_child(mesh)

        var bodies_in_splash = []
        splash.body_entered.connect( func(body):
            if body.is_in_group("player") and not bodies_in_splash.has(body):
                bodies_in_splash.append(body)
        )
        splash.body_exited.connect( func(body):
            bodies_in_splash.erase(body)
        )

        var damage_timer = Timer.new()
        damage_timer.one_shot = false
        damage_timer.wait_time = 1.0
        damage_timer.timeout.connect( func():
            for body in bodies_in_splash:
                if is_instance_valid(body) and body.has_method("take_damage"):
                    body.take_damage(splash_damage)
        )
        splash.add_child(damage_timer)

        var remove_timer = Timer.new()
        remove_timer.one_shot = true
        remove_timer.wait_time = splash_duration
        remove_timer.timeout.connect( func():
            if is_instance_valid(splash):
                splash.queue_free()
        )
        splash.add_child(remove_timer)


        owner.get_parent().add_child(splash)

        splash.global_position = pos
        damage_timer.start()
        remove_timer.start()

    animation_player.get_animation("Crawl").loop_mode = Animation.LOOP_NONE
    animation_player.play("Crawl")
