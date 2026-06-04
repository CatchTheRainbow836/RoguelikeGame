class_name ReloadingWeaponState
extends WeaponMovementState

@export var equip_reloading_buff: float = 1

func enter() -> void :
    if PLAYER and PLAYER.weapon_inventory_data:
        slot = PLAYER.weapon_inventory_data.slot_datas[0]

    if not slot or not slot.item_data is ItemDataWeapon:
        print("Reloading transitioning to Unequipped")
        transition.emit("UnequippedWeaponState")
        return
    await reload()
    if reload_label:
        var weapon: = slot.item_data as ItemDataWeapon
        reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]

    print("Reloading transitioning to Idle")
    transition.emit("IdleWeaponState")

func reload() -> void :
    if not slot or not slot.item_data is ItemDataWeapon:
        return

    var weapon: = slot.item_data as ItemDataWeapon



    var consumable_slot: = _get_weapon_consumable_slot(weapon.type)
    if consumable_slot == null:
        return
    var idx: int = PLAYER.inventory_data.slot_datas.find(consumable_slot)
    if idx == -1:
        return

    var consum_slot = PLAYER.inventory_data.slot_datas[idx]
    if consum_slot == null:
        return
    var available: = int(consum_slot.quantity)
    if available <= 0:
        PLAYER.inventory_data.slot_datas[idx] = null
        return

    var needed: = int(weapon.max_bullets_loaded - weapon.bullets_loaded)
    if needed <= 0:
        return

    var to_transfer: int = min(needed, available)
    if to_transfer <= 0:
        return

    weapon.reload_time *= equip_reloading_buff

    await get_tree().create_timer(weapon.reload_time).timeout

    weapon.reload_time /= equip_reloading_buff

    weapon.bullets_loaded += to_transfer
    consum_slot.quantity = max(0, available - to_transfer)

    if consum_slot.quantity <= 0:
        PLAYER.inventory_data.slot_datas[idx] = null

    PLAYER.inventory_data.inventory_updated.emit(PLAYER.inventory_data)
    return
func _get_weapon_consumable_slot(type: int) -> SlotData:
    for slot in PLAYER.inventory_data.slot_datas:
        if slot and slot.item_data is ItemDataWeaponConsumable:
            if (slot.item_data as ItemDataWeaponConsumable).type == type:
                return slot
    return null

func handle_input(event: InputEvent) -> void :
    pass

func physics_update(delta: float) -> void :
    if PLAYER and PLAYER.weapon_inventory_data:
        slot = PLAYER.weapon_inventory_data.slot_datas[0]
    if !slot:
        print("Reloading transitioning to Unequipped")
        transition.emit("UnequippedWeaponState")

    _update_weapon()
