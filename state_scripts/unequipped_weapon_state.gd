class_name UnequippedWeaponState
extends WeaponMovementState

var weapon

func handle_input(event: InputEvent) -> void :
    pass

func physics_update(delta: float) -> void :
    if PLAYER and PLAYER.weapon_inventory_data:
        slot = PLAYER.weapon_inventory_data.slot_datas[0]

    if slot and slot.item_data is ItemDataWeapon:
        weapon = slot.item_data as ItemDataWeapon
        weaponscene.visible = true

        var weapon_inst = weapon.model_scene.instantiate()
        weapon_inst.scale.z = 0.4
        weaponscene.add_child(weapon_inst)
        range = weapon.range

        idle_sway_adjustment = weapon.idle_sway_adjustment
        idle_sway_rotation_strength = weapon.idle_sway_rotation_strength
        random_sway_amount = weapon.random_sway_amount

        if reload_label:
            reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]

        transition.emit("IdleWeaponState")
        print("Uneqipped transitioning to Idle")
    elif not slot:
        weaponscene.visible = false
        for child in weaponscene.get_children():
            if child.name == "MuzzleFlash" or child.name == "OmniLight3D" or child.name == "GPUParticles3D":
                pass
            else:
                child.queue_free()

    _update_weapon()
