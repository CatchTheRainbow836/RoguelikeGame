extends Control

signal drop_slot_data(slot_data: SlotData)
signal force_close

var grabbed_slot_data: SlotData
var external_inventory_owner

var current_shop: Node = null

@onready var player_inventory: PanelContainer = $PlayerInventory
@onready var grabbed_slot: PanelContainer = $GrabbedSlot
@onready var external_inventory: PanelContainer = $ExternalInventory
@onready var equip_inventory: PanelContainer = $EquipInventory
@onready var weapon_inventory: PanelContainer = $WeaponInventory
@onready var shop_panel: PanelContainer = $ShopPanel

func _physics_process(delta: float) -> void :
    if grabbed_slot.visible:
        grabbed_slot.global_position = get_global_mouse_position() + Vector2(5, 5)

    if external_inventory_owner\
and external_inventory_owner.global_position.distance_to(GlobalScript.get_global_position()) > abs(GlobalScript.player.get_node("Pivot").get_node("Camera3D").get_node("InteractRay").target_position.z * 1.5):
        force_close.emit()

func set_player_inventory_data(inventory_data: InventoryData) -> void :
    inventory_data.inventory_interact.connect(on_inventory_interact)
    player_inventory.set_inventory_data(inventory_data)

func set_equip_inventory_data(inventory_data: InventoryData) -> void :
    inventory_data.inventory_interact.connect(on_inventory_interact)
    equip_inventory.set_inventory_data(inventory_data)

func set_weapon_inventory_data(inventory_data: InventoryData) -> void :
    inventory_data.inventory_interact.connect(on_inventory_interact)
    weapon_inventory.set_inventory_data(inventory_data)

func set_external_inventory(_external_inventory_owner) -> void :
    external_inventory_owner = _external_inventory_owner

    if external_inventory_owner.is_in_group("shop"):
        current_shop = external_inventory_owner
        shop_panel.setup_shop(external_inventory_owner)
        shop_panel.show()
        external_inventory.hide()

    else:
        current_shop = null
        shop_panel.hide()

        var inventory_data = external_inventory_owner.inventory_data

        inventory_data.inventory_interact.connect(on_inventory_interact)
        external_inventory.set_inventory_data(inventory_data)

        external_inventory.show()

func clear_external_inventory() -> void :
    if external_inventory_owner:
        if not current_shop:
            var inventory_data = external_inventory_owner.inventory_data
            if inventory_data.inventory_interact.is_connected(on_inventory_interact):
                inventory_data.inventory_interact.disconnect(on_inventory_interact)
            external_inventory.clear_inventory_data(inventory_data)
        external_inventory.hide()
        shop_panel.hide()
        external_inventory_owner = null
        current_shop = null

func on_inventory_interact(inventory_data: InventoryData, 
         index: int, button: int) -> void :

    match [grabbed_slot_data, button]:
        [null, MOUSE_BUTTON_LEFT]:
            grabbed_slot_data = inventory_data.grab_slot_data(index)
        [_, MOUSE_BUTTON_LEFT]:
            grabbed_slot_data = inventory_data.drop_slot_data(grabbed_slot_data, index)
        [null, MOUSE_BUTTON_RIGHT]:
            inventory_data.use_slot_data(index)
        [_, MOUSE_BUTTON_RIGHT]:
            grabbed_slot_data = inventory_data.drop_single_slot_data(grabbed_slot_data, index)

    update_grabbed_slot()

func update_grabbed_slot() -> void :
    if grabbed_slot_data:
        grabbed_slot.show()
        grabbed_slot.set_slot_data(grabbed_slot_data)
    else:
        grabbed_slot.hide()


func _on_gui_input(event: InputEvent) -> void :
    if event is InputEventMouseButton\
and event.is_pressed()\
and grabbed_slot_data:
        match event.button_index:
            MOUSE_BUTTON_LEFT:
                drop_slot_data.emit(grabbed_slot_data)
                grabbed_slot_data = null
            MOUSE_BUTTON_RIGHT:
                drop_slot_data.emit(grabbed_slot_data.create_single_slot_data())
                if grabbed_slot_data.quantity < 1:
                    grabbed_slot = null
        update_grabbed_slot()


func _on_visibility_changed() -> void :
    if not visible and grabbed_slot_data:
        drop_slot_data.emit(grabbed_slot_data)
        grabbed_slot_data = null
        update_grabbed_slot()
