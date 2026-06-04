extends CrucibleCoreAttackState
class_name PhaseThreeIdleCrucibleCoreAttackState

var boss: CrucibleCore
var recorded_weapon: ItemDataWeapon
var bullets_loaded: int = 0
var is_reloading: bool = false
var reload_timer: Timer = null
var attack_cooldown: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as CrucibleCore
    recorded_weapon = boss.recorded_weapon
    if recorded_weapon:
        bullets_loaded = recorded_weapon.max_bullets_loaded

func enter() -> void :
    super.enter()
    if is_reloading:
        is_reloading = false
        if reload_timer:
            reload_timer.stop()
            reload_timer.queue_free()
            reload_timer = null

func physics_update(delta: float) -> void :
    if not recorded_weapon:
        return
    attack_cooldown -= delta

    var can_attack = false
    var weapon_type = recorded_weapon.type

    if weapon_type >= 200 and weapon_type < 300:
        if attack_cooldown <= 0.0:
            can_attack = true

    elif weapon_type >= 100 and weapon_type < 200:
        if bullets_loaded > 0 and not is_reloading:
            can_attack = true
        elif bullets_loaded <= 0 and not is_reloading and attack_cooldown <= 0.0:
            _start_reload()

    elif weapon_type >= 300 and weapon_type < 400:
        if attack_cooldown <= 0.0:
            can_attack = true

    if can_attack:
        transition.emit("AttackingAttackState")

func _start_reload() -> void :
    if is_reloading:
        return
    is_reloading = true
    reload_timer = Timer.new()
    reload_timer.wait_time = recorded_weapon.reload_time
    reload_timer.one_shot = true
    reload_timer.timeout.connect(_finish_reload)
    add_child(reload_timer)
    reload_timer.start()

func _finish_reload() -> void :
    bullets_loaded = recorded_weapon.max_bullets_loaded
    is_reloading = false
    if reload_timer:
        reload_timer.queue_free()
        reload_timer = null
