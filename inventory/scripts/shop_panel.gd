extends PanelContainer

const InventoryScene = preload("uid://c6wwmr7hja3t8")
const BuyItemEntry = preload("uid://ba066h8dwigr4")

@onready var sell_grid_container: GridContainer = $VBoxContainer / VSplitContainer / VBoxContainer / SellInventoryContainer / MarginContainer / SellItemGrid
@onready var total_sell_value_label: Label = $VBoxContainer / VSplitContainer / VBoxContainer / HBoxContainer / TotalSellValueLabel
@onready var sell_button: Button = $VBoxContainer / VSplitContainer / VBoxContainer / HBoxContainer / SellButton
@onready var buy_items_list: VBoxContainer = $VBoxContainer / VSplitContainer / PanelContainer / VBoxContainer / ScrollContainer / BuyItemsList

var current_shop: Node
var sell_inventory_control: Control

func setup_shop(shop_node: Node) -> void :
	current_shop = shop_node

	for child in sell_grid_container.get_children():
		child.queue_free()

	sell_inventory_control = InventoryScene.instantiate()
	sell_grid_container.add_child(sell_inventory_control)
	sell_inventory_control.set_inventory_data(current_shop.sell_inventory_data)

	var inventory_data = current_shop.sell_inventory_data
	if not inventory_data.inventory_interact.is_connected(_on_sell_inventory_interact):
		inventory_data.inventory_interact.connect(_on_sell_inventory_interact)

	if not inventory_data.inventory_updated.is_connected(_on_sell_inventory_updated):
		inventory_data.inventory_updated.connect(_on_sell_inventory_updated)

	if not sell_button.pressed.is_connected(_on_sell_button_pressed):
		sell_button.pressed.connect(_on_sell_button_pressed)

	_on_sell_inventory_updated(inventory_data)
	_refresh_buy_list()

func _on_sell_inventory_interact(inventory_data: InventoryData, index: int, button: int) -> void :
	var inventory_interface = get_parent()
	if inventory_interface and inventory_interface.has_method("on_inventory_interact"):
		inventory_interface.on_inventory_interact(inventory_data, index, button)

func _on_sell_inventory_updated(_inventory_data: InventoryData) -> void :
	var total = 0
	for slot_data in current_shop.sell_inventory_data.slot_datas:
		if slot_data and slot_data.item_data:
			var price = ShopMasterData.get_sell_price(slot_data.item_data)
			total += price * slot_data.quantity
	total_sell_value_label.text = str(total)

func _on_sell_button_pressed() -> void :
	var total_value = int(total_sell_value_label.text)
	if total_value <= 0:
		return

	var player = GlobalScript.player
	player.currency += total_value
	player.currency_changed.emit(player.currency)

	for i in range(current_shop.sell_inventory_data.slot_datas.size()):
		current_shop.sell_inventory_data.slot_datas[i] = null
	current_shop.sell_inventory_data.inventory_updated.emit(current_shop.sell_inventory_data)

	sell_button.release_focus()

	var inv_interface = get_parent()
	if inv_interface and inv_interface.grabbed_slot_data:
		inv_interface.grabbed_slot_data = null
		inv_interface.update_grabbed_slot()

func _refresh_buy_list() -> void :
	for child in buy_items_list.get_children():
		child.queue_free()

	for item in current_shop.sold_items:
		if item == null:
			continue
		if current_shop.is_item_available(item):
			var entry = BuyItemEntry.instantiate()
			buy_items_list.add_child(entry)
			entry.setup(item, self)
			entry.visible = true
			entry.set_size(Vector2(200, 40))

	buy_items_list.queue_sort()

func attempt_buy_item(item: ItemData) -> void :
	var player = GlobalScript.player
	var price = ShopMasterData.get_buy_price(item)

	if player.currency < price:
		print("Not enough currency")
		return

	var slot_data = SlotData.new()
	slot_data.item_data = item
	slot_data.quantity = 1

	if player.inventory_data.pick_up_slot_data(slot_data):
		player.currency -= price
		player.currency_changed.emit(player.currency)
		current_shop.record_purchase(item)
		_refresh_buy_list()
	else:
		print("Inventory full")

func _exit_tree() -> void :
	if current_shop and current_shop.sell_inventory_data:
		current_shop.sell_inventory_data.inventory_updated.disconnect(_on_sell_inventory_updated)
		current_shop.sell_inventory_data.inventory_interact.disconnect(_on_sell_inventory_interact)
