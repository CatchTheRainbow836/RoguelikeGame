extends StaticBody3D

signal toggle_inventory(external_inventory_owner)

@export var inventory_data: InventoryData

func player_interact() -> void :
    toggle_inventory.emit(self)

func _ready() -> void :
    add_to_group("chests")
