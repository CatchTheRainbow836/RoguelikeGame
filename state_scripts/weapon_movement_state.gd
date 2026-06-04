class_name WeaponMovementState
extends State

signal weapon_fired
var PLAYER: Player
var pivot
var camera
var range
var inventoryinterface
var weaponinventory
var reload_label
var bullet_hole_sprite
var recoilposition
var weaponscene

var mouse_movement: Vector2
var random_sway_x
var random_sway_y
var random_sway_amount: float
var time: float = 0.0
var idle_sway_adjustment
var idle_sway_rotation_strength
var weapon_bob_amount: Vector2 = Vector2.ZERO
var sway_noise: NoiseTexture2D
var sway_speed: float = 1.2

var flash_time: float = 0.05

var muzzleflash
var light
var emitter

var recoil_amount: Vector3 = Vector3(0.01, 0.01, 1)
var snap_amount: float = 10.0
var recoil_speed: float = 20.0
var current_position: Vector3
var target_position: Vector3

var recoil_amount_pivot: Vector3 = Vector3(0.15, 0.05, 0.0)
var snap_amount_pivot: float = 8.0
var speed_pivot: float = 4.0

var current_rotation: Vector3
var target_rotation: Vector3

var _prev_current_rotation: Vector3 = Vector3.ZERO

var slot


func _ready() -> void :
    await owner.ready
    PLAYER = owner as Player
    pivot = PLAYER.get_node("Pivot") as Node3D
    camera = pivot.get_node("Camera3D") as Camera3D
    inventoryinterface = PLAYER.get_node("UI").get_node("InventoryInterface") as Control
    weaponinventory = inventoryinterface.get_node("WeaponInventory")
    reload_label = PLAYER.get_node("UI").get_node("ReloadLabel") as Label
    bullet_hole_sprite = preload("uid://d2k8ltlwqjwhj")
    recoilposition = camera.get_node("RecoilPosition")
    weaponscene = recoilposition.get_node("Weapon")
    muzzleflash = weaponscene.get_node("MuzzleFlash")
    light = muzzleflash.get_node("OmniLight3D")
    emitter = muzzleflash.get_node("GPUParticles3D")

    slot = PLAYER.weapon_inventory_data.slot_datas[0]


var current_weapon_item: ItemDataWeapon = null

func _update_weapon():
    if PLAYER and PLAYER.weapon_inventory_data:
        slot = PLAYER.weapon_inventory_data.slot_datas[0]
    else:
        slot = null

    var new_weapon_item = slot.item_data if slot and slot.item_data is ItemDataWeapon else null

    if current_weapon_item == new_weapon_item:
        return

    for child in weaponscene.get_children():
        if child.name not in ["MuzzleFlash", "OmniLight3D", "GPUParticles3D"]:
            child.queue_free()

    current_weapon_item = new_weapon_item

    if new_weapon_item:
        weaponscene.visible = true
        var weapon = new_weapon_item
        var weapon_inst = weapon.model_scene.instantiate()
        weapon_inst.scale.z = 0.4
        weaponscene.add_child(weapon_inst)

        range = weapon.range
        idle_sway_adjustment = weapon.idle_sway_adjustment
        idle_sway_rotation_strength = weapon.idle_sway_rotation_strength
        random_sway_amount = weapon.random_sway_amount

        if reload_label:
            reload_label.text = "%d / %d" % [weapon.bullets_loaded, weapon.max_bullets_loaded]
    else:
        weaponscene.visible = false
