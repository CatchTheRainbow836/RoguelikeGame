extends DefaultEnemyAttackState
class_name IdleSteamcragBehemothAttackState

var behemoth: SteamcragBehemoth
var melee_cooldown: float = 0.0
var shockwave_cooldown: float = 0.0

func _ready() -> void :
    super._ready()
    await owner.ready
    behemoth = owner as SteamcragBehemoth

func physics_update(delta: float) -> void :
    melee_cooldown -= delta
    shockwave_cooldown -= delta

    var dist_to_player = owner.global_position.distance_to(PLAYER.global_position) if PLAYER else INF

    if melee_cooldown <= 0.0 and dist_to_player <= behemoth.melee_range:
        transition.emit("AttackingAttackState")
        melee_cooldown = behemoth.melee_cooldown
    elif shockwave_cooldown <= 0.0:
        transition.emit("ShockwaveAttackState")
        shockwave_cooldown = behemoth.shockwave_cooldown
