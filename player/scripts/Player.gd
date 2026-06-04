class_name Player
extends CharacterBody3D

signal toggle_inventory()

@export var inventory_data: InventoryData
@export var equip_inventory_data: InventoryDataEquip
@export var weapon_inventory_data: InventoryDataWeapon
@onready var currency_label: Label = $UI / InventoryInterface / CurrencyLabel

var max_health: float = 100
var health: float = 100
var total_score: int = 0

var currency: int = 0
signal currency_changed(new_amount: int)

var is_stunned: bool = false
var stun_timer: float = 0.0

var defense_buff: float = 1
var equip_defense_buff: float = 1
var current_equipment: ItemDataEquip = null

signal took_damage(dmg: float)
signal raw_damage(dmg: float)
signal player_near_death

var _alert_timer: float = 0.0
const MAX_ALERT_INTENSITY: float = 1.6
const MAX_SPEED_FOR_ALERT: float = 7 * 1.5

func _ready() -> void :
    add_to_group("player")
    GlobalScript.player = self
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    var enemies = get_tree().get_nodes_in_group("enemies")

    currency_changed.connect(_update_currency_label)
    _update_currency_label(currency)

func _update_currency_label(new_amount: int):
    currency_label.text = "Currency: %d" % new_amount

func _unhandled_input(event: InputEvent) -> void :
    if Input.is_action_just_pressed("inventory"):
        toggle_inventory.emit()

func stun(duration: float) -> void :
    print("stun")
    is_stunned = true
    stun_timer = duration

func _physics_process(delta: float) -> void :
    if is_stunned:
        stun_timer -= delta
        if stun_timer <= 0.0:
            is_stunned = false
        velocity = Vector3.ZERO
        var player_state_machine = get_node("PlayerStateMachine")
        player_state_machine.on_child_transition("IdlePlayerState")
        move_and_slide()
        return

    var speed = velocity.length()
    if speed > 0.1 and not is_stunned:
        _alert_timer -= delta
        if _alert_timer <= 0.0:
            var intensity = clamp(speed / MAX_SPEED_FOR_ALERT, 0.0, 1.0) * MAX_ALERT_INTENSITY
            AlertnessManager.add_alert(global_position, intensity)
            _alert_timer = AlertnessManager.PLAYER_ALERT_INTERVAL
    else:
        _alert_timer = 0.0

    var enemies = get_tree().get_nodes_in_group("enemies")

    var equip_slot = equip_inventory_data.slot_datas[0].item_data as ItemDataEquip if equip_inventory_data.slot_datas[0] else null
    if equip_slot != current_equipment:
        if current_equipment != null:
            current_equipment.unequip(self)
        if equip_slot != null:
            equip_slot.equip(self)
        current_equipment = equip_slot

    check_health()

func check_health() -> void :
    if health <= 0:
        player_near_death.emit()
        if health > 0: return
        die()

var has_died: = false
func die() -> void :
    if not has_died:
        push_error("player died")
        has_died = true

func heal(heal_value: float) -> void :
    if health + heal_value <= max_health:
        health += heal_value
    else:
        health = max_health

func take_damage(dmg: float) -> void :
    raw_damage.emit(dmg)
    dmg *= equip_defense_buff
    equip_defense_buff = 1.0
    dmg *= defense_buff
    took_damage.emit(dmg)
    health -= dmg

func add_score(score: int) -> void :
    total_score += score
    print(total_score)

@onready var camera_3d: Camera3D = $Pivot / Camera3D

func get_drop_position() -> Vector3:
    var direction = - camera_3d.global_transform.basis.z
    return camera_3d.global_position + direction
