extends FurnaceColossusMovementState
class_name PhaseOneRunningFurnaceColossusState

var attack_range: float
var preferred_distance: float
var is_attacking_emitted: bool = false
var colossus: FurnaceColossus

signal can_attack(active: bool)

func _ready() -> void :
    super._ready()
    await owner.ready
    colossus = owner as FurnaceColossus
    if colossus:
        speed = colossus.phase3_speed
        accel = colossus.accel
        view_distance = colossus.view_distance
        fov_degrees = colossus.fov_degrees
        attack_range = colossus.attack_range
        preferred_distance = attack_range * 0.8

func enter() -> void :
    super.enter()
    can_attack.emit(true)

func exit() -> void :
    super.exit()
    is_attacking_emitted = false
    can_attack.emit(false)

func physics_update(delta: float) -> void :
    navigation_agent_3d.target_position = PLAYER.global_position

    var to_player = PLAYER.global_position - owner.global_position
    var dist = to_player.length()
    var dir_to_player = to_player.normalized()
    var target_pos = PLAYER.global_position - dir_to_player * preferred_distance
    target_pos.y = owner.global_position.y

    var move_dir = (target_pos - owner.global_position)
    move_dir.y = 0.0
    if move_dir.length() > 0.2:
        move_dir = move_dir.normalized()
        _velocity.x = move_toward(_velocity.x, move_dir.x * speed, accel * delta)
        _velocity.z = move_toward(_velocity.z, move_dir.z * speed, accel * delta)
    else:
        _velocity.x = move_toward(_velocity.x, 0.0, accel * delta)
        _velocity.z = move_toward(_velocity.z, 0.0, accel * delta)

    if dist <= attack_range:
        if not is_attacking_emitted:
            var attack_type = randi() % 3
            if attack_type < 2:
                colossus.top_state_machine.CURRENT_STATE.get_node("AttackStateMachine").on_child_transition("AttackingAttackState")
            else:
                colossus.top_state_machine.CURRENT_STATE.get_node("AttackStateMachine").on_child_transition("SweepingAttackState")
            is_attacking_emitted = true
    else:
        if is_attacking_emitted:
            can_attack.emit(false)
            is_attacking_emitted = false

    _look_at_player_smooth(delta)

    owner.velocity = _velocity
    owner.move_and_slide()
