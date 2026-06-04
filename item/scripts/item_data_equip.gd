extends ItemData
class_name ItemDataEquip

@export var type: int

func equip(target: Node) -> void :
    match type:
        0:
            print("equipped")
        1:
            use_leather_pauldrons(target, true)
        2:
            use_iron_soled_boots(target, true)
        3:
            use_duelists_gloves(target, true)
        4:
            use_marksmans_monocle(target, true)
        5:
            use_quicksilver_brooch(target, true)
        6:
            use_brigandine_vest(target, true)
        7:
            use_artillery_helmet(target, true)
        8:
            use_dowsing_rod(target, true)
        9:
            use_potion_belt(target, true)
        10:
            use_plague_doctors_mask(target, true)
        11:
            use_sappers_apron(target, true)
        12:
            use_runic_ward(target, true)
        13:
            use_cowl_of_the_unseen(target, true)
        14:
            use_boots_of_mercury(target, true)
        15:
            use_phantoms_hand(target, true)
        16:
            use_tithonus_curse(target, true)
        17:
            use_aegis_fragment(target, true)
func unequip(target: Node) -> void :
    match type:
        0:
            print("unequipped")
        1:
            use_leather_pauldrons(target, false)
        2:
            use_iron_soled_boots(target, false)
        3:
            use_duelists_gloves(target, false)
        4:
            use_marksmans_monocle(target, false)
        5:
            use_quicksilver_brooch(target, false)
        6:
            use_brigandine_vest(target, false)
        7:
            use_artillery_helmet(target, false)
        8:
            use_dowsing_rod(target, false)
        9:
            use_potion_belt(target, false)
        10:
            use_plague_doctors_mask(target, false)
        11:
            use_sappers_apron(target, false)
        12:
            use_runic_ward(target, false)
        13:
            use_cowl_of_the_unseen(target, false)
        14:
            use_boots_of_mercury(target, false)
        15:
            use_phantoms_hand(target, false)
        16:
            use_tithonus_curse(target, false)
        17:
            use_aegis_fragment(target, false)

func use_leather_pauldrons(player: Node, equipped: bool):
    if equipped:
        player.max_health += 5
    elif not equipped:
        player.max_health -= 5

func use_iron_soled_boots(player: Node, equipped: bool):
    if equipped:
        var connection = func(dmg: float):
            if dmg <= 15:
                player.equip_defense_buff = 0.8
        player.raw_damage.connect(connection)
        player.set_meta("iron_soled_boots_connection", connection)
    else:
        if player.has_meta("iron_soled_boots_connection"):
            var connection = player.get_meta("iron_soled_boots_connection")
            player.raw_damage.disconnect(connection)
            player.remove_meta("iron_soled_boots_connection")

func use_duelists_gloves(player: Node, equipped: bool):
    if equipped:
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_ranged_damage_buff = 1.1
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_melee_damage_buff = 1.1
    else:
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_ranged_damage_buff = 1.0
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_melee_damage_buff = 1.0

func use_marksmans_monocle(player: Node, equipped: bool):
    if equipped:
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_ranged_damage_buff = 1.2
    else:
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_ranged_damage_buff = 1.0

func use_quicksilver_brooch(player: Node, equipped: bool):
    if equipped:
        player.get_node("WeaponStateMachine").get_node("ReloadingWeaponState").equip_reloading_buff = 0.8
    else:
        player.get_node("WeaponStateMachine").get_node("ReloadingWeaponState").equip_reloading_buff = 1.0

func use_brigandine_vest(player: Node, equipped: bool):
    if equipped:
        player.equip_defense_buff = 0.9
    else:
        player.equip_defense_buff = 1.0

func use_artillery_helmet(player: Node, equipped: bool):
    if equipped:
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_projectile_damage_buff = 1.2
    else:
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_projectile_damage_buff = 1.0

func use_dowsing_rod(player: Node, equipped: bool):
    if equipped:
        var light = player.get_node_or_null("DowsingRodLight")
        if not light:
            light = OmniLight3D.new()
            light.name = "DowsingRodLight"
            light.light_energy = 0.0
            light.omni_range = 5.0
            light.light_color = Color(0, 1, 0)
            player.add_child(light)
        var timer = Timer.new()
        timer.name = "DowsingRodTimer"
        timer.wait_time = 0.5
        timer.one_shot = false
        timer.timeout.connect( func():
            if not is_instance_valid(player):
                timer.stop()
                return
            var chests = player.get_tree().get_nodes_in_group("chests")
            var in_range = false
            var player_pos = player.global_position
            for chest in chests:
                if player_pos.distance_to(chest.global_position) <= 40.0:
                    in_range = true
                    break
            var light_node = player.get_node_or_null("DowsingRodLight")
            if light_node:
                light_node.light_energy = 2.0 if in_range else 0.0
        )
        player.add_child(timer)
        timer.start()
        player.set_meta("dowsing_rod_light", light)
        player.set_meta("dowsing_rod_timer", timer)
    else:
        if player.has_meta("dowsing_rod_light"):
            var light = player.get_meta("dowsing_rod_light")
            if is_instance_valid(light):
                light.queue_free()
            player.remove_meta("dowsing_rod_light")
        if player.has_meta("dowsing_rod_timer"):
            var timer = player.get_meta("dowsing_rod_timer")
            if is_instance_valid(timer):
                timer.stop()
                timer.queue_free()
            player.remove_meta("dowsing_rod_timer")

func use_potion_belt(player: Node, equipped: bool):
    if equipped:
        var timer = Timer.new()
        timer.name = "PotionBeltTimer"
        timer.wait_time = 0.2
        timer.one_shot = false
        var was_below = false
        timer.timeout.connect( func():
            if not is_instance_valid(player):
                timer.stop()
                return
            var current_hp = player.current_health if "current_health" in player else 0
            var max_hp = player.max_health if "max_health" in player else 100
            var is_below = current_hp < max_hp * 0.5
            if is_below != was_below:
                was_below = is_below
                if is_below:
                    player.get_node("WeaponStateMachine").get_node("ReloadingWeaponState").equip_projectile_damage_buff = 1.35
                else:
                    player.get_node("WeaponStateMachine").get_node("ReloadingWeaponState").equip_projectile_damage_buff = 1.0
        )
        player.add_child(timer)
        timer.start()
        player.set_meta("potion_belt_timer", timer)
    else:
        if player.has_meta("potion_belt_timer"):
            var timer = player.get_meta("potion_belt_timer")
            if is_instance_valid(timer):
                timer.stop()
                timer.queue_free()
            player.remove_meta("potion_belt_timer")
        player.get_node("WeaponStateMachine").get_node("ReloadingWeaponState").equip_projectile_damage_buff = 1.0

func use_plague_doctors_mask(player: Node, equipped: bool):
    if equipped:
        var timer = Timer.new()
        timer.name = "PlagueDoctorMaskTimer"
        timer.wait_time = 0.2
        timer.one_shot = false
        timer.timeout.connect( func():
            if not is_instance_valid(player):
                timer.stop()
                return
            var is_max_health = abs(player.current_health - player.max_health) < 0.01
            if is_max_health:
                player.equip_defense_buff = 0.7
            else:
                player.equip_defense_buff = 1.0
        )
        player.add_child(timer)
        timer.start()
        player.set_meta("plague_doctor_mask_timer", timer)
    else:
        if player.has_meta("plague_doctor_mask_timer"):
            var timer = player.get_meta("plague_doctor_mask_timer")
            if is_instance_valid(timer):
                timer.stop()
                timer.queue_free()
            player.remove_meta("plague_doctor_mask_timer")
        player.equip_defense_buff = 1.0

func use_sappers_apron(player: Node, equipped: bool):
    if equipped:
        var timer = Timer.new()
        timer.name = "SappersApronTimer"
        timer.wait_time = 0.2
        timer.one_shot = false
        timer.timeout.connect( func():
            if not is_instance_valid(player):
                timer.stop()
                return
            var is_max_health = abs(player.health - player.max_health) < 0.01
            if is_max_health:
                player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_projectile_damage_buff = 1.35
            else:
                player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_projectile_damage_buff = 1.0
        )
        player.add_child(timer)
        timer.start()
        player.set_meta("sappers_apron_timer", timer)
    else:
        if player.has_meta("sappers_apron_timer"):
            var timer = player.get_meta("sappers_apron_timer")
            if is_instance_valid(timer):
                timer.stop()
                timer.queue_free()
            player.remove_meta("sappers_apron_timer")
        player.get_node("WeaponStateMachine").get_node("FiringWeaponState").equip_projectile_damage_buff = 1.0

func use_runic_ward(player: Node, equipped: bool):
    if equipped:
        var absorption = {
            "current": 30.0, 
            "max": 30.0, 
            "refill_timer": null, 
            "damage_connection": null
        }
        player.set_meta("runic_ward_absorption", absorption)

        var damage_handler = func(dmg: float):
            if not is_instance_valid(player) or not player.has_meta("runic_ward_absorption"):
                return
            var abs_data = player.get_meta("runic_ward_absorption")
            var current_abs = abs_data["current"]
            if current_abs <= 0:
                return
            if dmg <= current_abs:
                player.equip_defense_buff = 0.0
                abs_data["current"] = current_abs - dmg
            else:
                player.equip_defense_buff = 1.0 - (current_abs / dmg)
                abs_data["current"] = 0.0
            player.set_meta("runic_ward_absorption", abs_data)
        absorption["damage_connection"] = damage_handler
        player.raw_damage.connect(damage_handler)

        var refill_timer = Timer.new()
        refill_timer.name = "RunicWardRefillTimer"
        refill_timer.wait_time = 5.0
        refill_timer.one_shot = false
        refill_timer.timeout.connect( func():
            if not is_instance_valid(player) or not player.has_meta("runic_ward_absorption"):
                return
            var abs_data = player.get_meta("runic_ward_absorption")
            var new_abs = min(abs_data["current"] + 10.0, abs_data["max"])
            abs_data["current"] = new_abs
            player.set_meta("runic_ward_absorption", abs_data)
        )
        player.add_child(refill_timer)
        refill_timer.start()
        absorption["refill_timer"] = refill_timer
        player.set_meta("runic_ward_absorption", absorption)

    else:
        if player.has_meta("runic_ward_absorption"):
            var abs_data = player.get_meta("runic_ward_absorption")
            if abs_data["damage_connection"]:
                player.raw_damage.disconnect(abs_data["damage_connection"])
            if abs_data["refill_timer"] and is_instance_valid(abs_data["refill_timer"]):
                abs_data["refill_timer"].stop()
                abs_data["refill_timer"].queue_free()
            player.remove_meta("runic_ward_absorption")

func use_cowl_of_the_unseen(player: Node, equipped: bool):
    if equipped:
        var timer = Timer.new()
        timer.name = "CowlOfTheUnseenTimer"
        timer.wait_time = 0.1
        timer.one_shot = false

        timer.set_meta("idle_timer", 0.0)
        var is_invisible = false

        timer.timeout.connect( func():
            if not is_instance_valid(player):
                timer.stop()
                return

            var idle_timer = timer.get_meta("idle_timer")

            var movement_sm = player.get_node("PlayerStateMachine")
            var weapon_sm = player.get_node("WeaponStateMachine")
            var is_idle = true
            var idle_player_state = movement_sm.get_node("IdlePlayerState")
            var idle_weapon_state = weapon_sm.get_node("IdleWeaponState")
            var unequipped_weapon_state = weapon_sm.get_node("UnequippedWeaponState")
            if movement_sm.CURRENT_STATE == idle_player_state and (weapon_sm and weapon_sm.CURRENT_STATE == idle_weapon_state or weapon_sm and weapon_sm.CURRENT_STATE == unequipped_weapon_state):
                is_idle = true
            else:
                is_idle = false

            if is_idle:
                idle_timer += 0.1
                if idle_timer >= 1.0 and not is_invisible:
                    is_invisible = true
                    player.visible = false
            else:
                idle_timer = 0.0
                is_invisible = false
                player.visible = true

            timer.set_meta("idle_timer", idle_timer)

            if is_invisible:
                var space = player.get_world_3d().direct_space_state
                var shape = SphereShape3D.new()
                shape.radius = 7.5
                var params = PhysicsShapeQueryParameters3D.new()
                params.shape = shape
                params.transform = Transform3D(Basis(), player.global_position)
                params.collision_mask = 1 << 3
                var hits = space.intersect_shape(params)
                for hit in hits:
                    var enemy = hit.collider
                    var enemy_sm = enemy.get_node_or_null("EnemyStateMachine")
                    if enemy_sm:
                        var idle_enemy_state = enemy_sm.get_node_or_null("IdleEnemyState")
                        var walking_enemy_state = enemy_sm.get_node_or_null("WalkingEnemyState")
                        var running_enemy_state = enemy_sm.get_node_or_null("RunningEnemyState")
                        if idle_enemy_state:
                            idle_enemy_state.is_in_smoke = true
                        if walking_enemy_state:
                            walking_enemy_state.is_in_smoke = true
                        if running_enemy_state:
                            running_enemy_state.is_in_smoke = true
            else:
                var all_enemies = player.get_tree().get_nodes_in_group("enemies")
                for enemy in all_enemies:
                    var enemy_sm = enemy.get_node_or_null("EnemyStateMachine")
                    if enemy_sm:
                        var idle_enemy_state = enemy_sm.get_node_or_null("IdleEnemyState")
                        var walking_enemy_state = enemy_sm.get_node_or_null("WalkingEnemyState")
                        var running_enemy_state = enemy_sm.get_node_or_null("RunningEnemyState")
                        if idle_enemy_state:
                            idle_enemy_state.is_in_smoke = false
                        if walking_enemy_state:
                            walking_enemy_state.is_in_smoke = false
                        if running_enemy_state:
                            running_enemy_state.is_in_smoke = false
        )

        player.add_child(timer)
        timer.start()

        player.set_meta("cowl_timer", timer)

    else:
        if player.has_meta("cowl_timer"):
            var timer = player.get_meta("cowl_timer")
            if is_instance_valid(timer):
                timer.stop()
                timer.queue_free()
            player.remove_meta("cowl_timer")
        player.visible = true
        var all_enemies = player.get_tree().get_nodes_in_group("enemies")
        for enemy in all_enemies:
            var enemy_sm = enemy.get_node_or_null("EnemyStateMachine")
            if enemy_sm:
                var idle_enemy_state = enemy_sm.get_node_or_null("IdleEnemyState")
                var walking_enemy_state = enemy_sm.get_node_or_null("WalkingEnemyState")
                var running_enemy_state = enemy_sm.get_node_or_null("RunningEnemyState")
                if idle_enemy_state:
                    idle_enemy_state.is_in_smoke = false
                if walking_enemy_state:
                    walking_enemy_state.is_in_smoke = false
                if running_enemy_state:
                    running_enemy_state.is_in_smoke = false

func use_boots_of_mercury(player: Node, equipped: bool):
    if equipped:
        var player_sm = player.get_node("PlayerStateMachine")
        var walking_player_state = player_sm.get_node("WalkingPlayerState")
        var sprinting_player_state = player_sm.get_node("SprintingPlayerState")
        var crouch_player_state = player_sm.get_node("CrouchPlayerState")

        walking_player_state.SPEED_DEFAULT *= 1.5
        sprinting_player_state.SPEED_SPRINTING *= 1.5
        crouch_player_state.SPEED_CROUCH *= 1.5

        print("walking_player_state.SPEED_DEFAULT: ", walking_player_state.SPEED_DEFAULT)


    else:
        var player_sm = player.get_node("PlayerStateMachine")
        var walking_player_state = player_sm.get_node("WalkingPlayerState")
        var sprinting_player_state = player_sm.get_node("SprintingPlayerState")
        var crouch_player_state = player_sm.get_node("CrouchPlayerState")

        walking_player_state.SPEED_DEFAULT /= 1.5
        sprinting_player_state.SPEED_SPRINTING /= 1.5
        crouch_player_state.SPEED_CROUCH /= 1.5

func use_phantoms_hand(player: Node, equipped: bool) -> void :
    if equipped:
        var interact_ray = player.get_node("Pivot").get_node("Camera3D").get_node("InteractRay") as RayCast3D
        interact_ray.target_position = Vector3(0, 0, -10)
    else:
        var interact_ray = player.get_node("Pivot").get_node("Camera3D").get_node("InteractRay") as RayCast3D
        interact_ray.target_position = Vector3(0, 0, -2.5)

func use_tithonus_curse(player: Node, equipped: bool):
    if equipped:
        var handler = _tithonus_curse_trigger.bind(player)
        player.player_near_death.connect(handler)
        player.set_meta("tithonus_curse_handler", handler)
    else:
        if player.has_meta("tithonus_curse_handler"):
            var handler = player.get_meta("tithonus_curse_handler")
            if player.player_near_death.is_connected(handler):
                player.player_near_death.disconnect(handler)
            player.remove_meta("tithonus_curse_handler")

func _tithonus_curse_trigger(player: Node):
    if not is_instance_valid(player):
        return
    player.health = player.max_health
    player.max_health = max(1, player.max_health / 2)
    if player.health > player.max_health:
        player.health = player.max_health
    if player.equip_inventory_data and player.equip_inventory_data.slot_datas[0]:
        player.equip_inventory_data.slot_datas[0] = null
        player.equip_inventory_data.inventory_updated.emit(player.equip_inventory_data)
    if player.has_meta("tithonus_curse_handler"):
        var handler = player.get_meta("tithonus_curse_handler")
        if player.player_near_death.is_connected(handler):
            player.player_near_death.disconnect(handler)
        player.remove_meta("tithonus_curse_handler")

func use_aegis_fragment(player: Node, equipped: bool):
    if equipped:
        var handler = func(dmg: float):
            if randf() < 0.25:
                player.equip_defense_buff = 0.0
        player.raw_damage.connect(handler)
        player.set_meta("aegis_fragment_handler", handler)
    else:
        if player.has_meta("aegis_fragment_handler"):
            var handler = player.get_meta("aegis_fragment_handler")
            if player.raw_damage.is_connected(handler):
                player.raw_damage.disconnect(handler)
            player.remove_meta("aegis_fragment_handler")
