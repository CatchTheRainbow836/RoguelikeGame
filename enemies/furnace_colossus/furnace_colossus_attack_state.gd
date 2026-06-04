extends DefaultEnemyAttackState
class_name FurnaceColossusAttackState

func _ready() -> void :
    var root = owner
    while root and not root is FurnaceColossus:
        root = root.get_parent()
    if not root:
        push_error("FurnaceColossusAttackState: Could not find FurnaceColossus root")
        return
    var enemy = root as FurnaceColossus

    PLAYER = get_tree().get_first_node_in_group("player")
    owner = enemy

    enemy.add_to_group("enemies")
