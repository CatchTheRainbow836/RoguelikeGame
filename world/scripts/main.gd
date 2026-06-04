extends Node
@onready var player: CharacterBody3D = $Player
var inventory_interface: Control
var hot_bar_inventory: PanelContainer
var health_bar: TextureProgressBar
var reload_label: Label
var currency_label: Label


const PickUp = preload("uid://buxhkapuyehvt")

func _ready() -> void :
    inventory_interface = player.get_node("UI").get_node("InventoryInterface") as Control
    hot_bar_inventory = player.get_node("UI").get_node("HotBarInventory") as PanelContainer
    health_bar = player.get_node("UI").get_node("HBoxContainer").get_node("HealthBar") as TextureProgressBar
    reload_label = player.get_node("UI").get_node("ReloadLabel") as Label
    currency_label = player.get_node("UI").get_node("InventoryInterface").get_node("CurrencyLabel") as Label

    player.toggle_inventory.connect(toggle_inventory_interface)

    inventory_interface.set_player_inventory_data(player.inventory_data)
    inventory_interface.set_equip_inventory_data(player.equip_inventory_data)
    inventory_interface.set_weapon_inventory_data(player.weapon_inventory_data)
    inventory_interface.force_close.connect(toggle_inventory_interface)
    inventory_interface.drop_slot_data.connect(_on_inventory_interface_drop_slot_data)
    hot_bar_inventory.set_inventory_data(player.inventory_data)



    for node in get_tree().get_nodes_in_group("external_inventory"):
        node.toggle_inventory.connect(toggle_inventory_interface)


func toggle_inventory_interface(external_inventory_owner = null) -> void :
    inventory_interface.visible = not inventory_interface.visible

    if inventory_interface.visible:
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
        hot_bar_inventory.hide()
        health_bar.hide()
        reload_label.hide()
        currency_label.show()
    else:
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
        hot_bar_inventory.show()
        health_bar.show()
        reload_label.show()
        currency_label.hide()

    if external_inventory_owner and inventory_interface.visible:
        inventory_interface.set_external_inventory(external_inventory_owner)
    else:
        inventory_interface.clear_external_inventory()


func _on_inventory_interface_drop_slot_data(slot_data: SlotData) -> void :
    var pick_up = PickUp.instantiate()
    pick_up.slot_data = slot_data
    pick_up.position = player.get_drop_position()
    add_child(pick_up)
