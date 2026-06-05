extends State
class_name ArchonAttackState

var PLAYER: CharacterBody3D

func _ready() -> void :
	await owner.ready
	PLAYER = get_tree().get_first_node_in_group("player")
