extends PanelContainer

signal hot_bar_use(index: int)

const Slot = preload("uid://dqfi7apfvykwy")
@onready var h_box_container: HBoxContainer = $MarginContainer / HBoxContainer
const WeaponMovementState = preload("uid://7q0t5e4srcg6")



var main_inventory_data: InventoryData

func _unhandled_key_input(event: InputEvent) -> void :
	if not visible or not event.is_pressed():
		return
	if range(KEY_1, KEY_7).has(event.keycode):


		hot_bar_use.emit(event.keycode - KEY_1)

func set_inventory_data(inventory_data: InventoryData) -> void :
	inventory_data.inventory_updated.connect(populate_hot_bar)
	populate_hot_bar(inventory_data)

	main_inventory_data = inventory_data
	hot_bar_use.connect(_on_hot_bar_use)

func populate_hot_bar(inventory_data: InventoryData) -> void :
	for child in h_box_container.get_children():
		child.queue_free()


	for slot_data in inventory_data.slot_datas.slice(0, 6):
		var slot = Slot.instantiate()
		h_box_container.add_child(slot)

		if slot_data:
			slot.set_slot_data(slot_data)


func _on_hot_bar_use(index: int) -> void :
	if not main_inventory_data:
		return
	var slot_data = main_inventory_data.slot_datas[index]

	if slot_data and slot_data.item_data is ItemDataWeapon:
		print("use weapon")
		var player = owner
		if not player:
			return
		var weapon_inv_data = player.weapon_inventory_data
		if not weapon_inv_data:
			return
		var weapon_slot = weapon_inv_data.grab_slot_data(0)
		var main_slot = main_inventory_data.grab_slot_data(index)
		var leftover = weapon_inv_data.drop_slot_data(main_slot, 0)
		if leftover:
			main_inventory_data.drop_slot_data(leftover, index)
		else:
			if weapon_slot:
				main_inventory_data.drop_slot_data(weapon_slot, index)

	else:
		main_inventory_data.use_slot_data(index)
