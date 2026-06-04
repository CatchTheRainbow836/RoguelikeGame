extends ArchonAttackState
class_name PhaseOneIdleArchonAttackState

var boss: ArchonOfBlinding
var sweep_cooldown: float = 0.0
var splash_cooldown: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    boss = owner as ArchonOfBlinding

func physics_update(delta: float) -> void :
    sweep_cooldown -= delta
    splash_cooldown -= delta
    if sweep_cooldown <= 0.0 and splash_cooldown <= 0.0:
        if randf() < 0.5:
            transition.emit("SweepAttackState")
            sweep_cooldown = boss.phase1_sweep_cooldown
        else:
            transition.emit("SplashAttackState")
            splash_cooldown = boss.phase1_splash_cooldown
    elif sweep_cooldown <= 0.0:
        transition.emit("SweepAttackState")
        sweep_cooldown = boss.phase1_sweep_cooldown
    elif splash_cooldown <= 0.0:
        transition.emit("SplashAttackState")
        splash_cooldown = boss.phase1_splash_cooldown
