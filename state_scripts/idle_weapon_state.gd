class_name IdleWeaponState
extends WeaponMovementState

func handle_input(event: InputEvent) -> void :
    if event.is_action_pressed("fire") and weaponscene.visible == true and inventoryinterface.visible == false:
        print("Idle transitioning to Firing")
        transition.emit("FiringWeaponState")

    if event.is_action_pressed("reload") and weaponscene.visible == true and inventoryinterface.visible == false:
        print("Idle transitioning to Reloading")
        transition.emit("ReloadingWeaponState")

    if event is InputEventMouseMotion and inventoryinterface.visible == false:
        mouse_movement = event.relative

func physics_update(delta: float) -> void :
    if PLAYER and PLAYER.weapon_inventory_data:
        slot = PLAYER.weapon_inventory_data.slot_datas[0]
    if !slot:
        print("Idle transitioning to Unequipped")
        transition.emit("UnequippedWeaponState")


    _update_weapon()
