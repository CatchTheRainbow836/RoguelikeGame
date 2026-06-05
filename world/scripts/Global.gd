class_name Global
extends Node

var player
var debug

func use_slot_data(slot_data: SlotData) -> void :
	slot_data.item_data.use(player)

func get_global_position() -> Vector3:
	return player.global_position
