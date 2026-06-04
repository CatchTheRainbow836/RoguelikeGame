extends DefaultEnemyAttackState
class_name AttackingSludgeCrawlerAttackState

var trail_timer: Timer
var trail_damage: float
var trail_radius: float
var trail_duration: float
var trail_spawn_interval: float
var crawler: SludgeCrawler
var is_active: bool = false

func _ready() -> void :
    super._ready()
    await owner.ready
    crawler = owner as SludgeCrawler
    if crawler:
        trail_damage = crawler.trail_damage
        trail_radius = crawler.trail_radius
        trail_duration = crawler.trail_duration
        trail_spawn_interval = crawler.trail_spawn_interval

func enter() -> void :
    super.enter()
    is_active = true

    if trail_timer and trail_timer.is_inside_tree():
        trail_timer.queue_free()
    trail_timer = Timer.new()
    trail_timer.one_shot = false
    trail_timer.wait_time = trail_spawn_interval
    trail_timer.timeout.connect(_spawn_trail_segment)
    owner.add_child(trail_timer)
    trail_timer.start()

func exit() -> void :
    is_active = false
    if trail_timer:
        trail_timer.stop()
        trail_timer.queue_free()
        trail_timer = null

func physics_update(delta: float) -> void :
    if not PLAYER or not is_active:
        transition.emit("IdleAttackState")
        return

    var dist = owner.global_position.distance_to(PLAYER.global_position)
    if dist > crawler.attack_trigger_range * 1.2 or not running_enemy_state.can_see_player():
        transition.emit("IdleAttackState")

func _spawn_trail_segment() -> void :
    if not is_active or not is_instance_valid(owner):
        return

    var trail = Area3D.new()
    trail.name = "TrailSegment"
    trail.collision_mask = 2
    trail.collision_layer = 0

    var shape = CollisionShape3D.new()
    var cylinder_shape = CylinderShape3D.new()
    cylinder_shape.radius = trail_radius
    cylinder_shape.height = 0.2
    shape.shape = cylinder_shape
    trail.add_child(shape)

    var mesh = MeshInstance3D.new()
    var cylinder = CylinderMesh.new()
    cylinder.top_radius = trail_radius
    cylinder.bottom_radius = trail_radius
    cylinder.height = 0.1
    mesh.mesh = cylinder
    var material = StandardMaterial3D.new()
    material.albedo_color = Color(0.3, 0.6, 0.1, 0.7)
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh.material_override = material
    trail.add_child(mesh)

    var pos = owner.global_position
    pos.y = 0.05


    var damaged = false
    trail.body_entered.connect( func(body):
        if damaged:
            return
        if body.is_in_group("player") and body.has_method("take_damage"):
            body.take_damage(trail_damage)
            damaged = true
    )

    var remove_timer = Timer.new()
    remove_timer.one_shot = true
    remove_timer.wait_time = trail_duration
    remove_timer.timeout.connect( func():
        if is_instance_valid(trail):
            trail.queue_free()
    )
    trail.add_child(remove_timer)

    owner.get_parent().add_child(trail)
    remove_timer.start()

    trail.global_position = pos
