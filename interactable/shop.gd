extends StaticBody3D

signal toggle_inventory(external_inventory_owner)

@export var sold_items: Array[ItemData]

@export var sell_inventory_data: InventoryData

var purchased_items: Dictionary = {}

func player_interact() -> void :
	toggle_inventory.emit(self)

func _ready() -> void :
	add_to_group("external_inventory")
	add_to_group("shop")
	if not sell_inventory_data:
		sell_inventory_data = InventoryData.new()
		sell_inventory_data.slot_datas.resize(18)

func is_item_available(item: ItemData) -> bool:
	var conditions = ShopMasterData.get_unlock_conditions(item)
	return can_buy_item(item.resource_path, conditions)

func can_buy_item(item_id: String, conditions: Dictionary) -> bool:
	if conditions.is_empty():
		return true
	if conditions.has("requires_items"):
		for req_id in conditions["requires_items"]:
			if purchased_items.get(req_id, 0) == 0:
				return false
	if conditions.has("requires_total_purchases"):
		var total = 0
		for cnt in purchased_items.values():
			total += cnt
		if total < conditions["requires_total_purchases"]:
			return false
	if conditions.has("requires_category_counts"):
		var cat_counts = conditions["requires_category_counts"]
		for cat in cat_counts:
			var needed = cat_counts[cat]
			var have = purchased_items.get("__cat_" + cat, 0)
			if have < needed:
				return false
	return true

func record_purchase(item: ItemData) -> void :
	var item_id = item.resource_path
	var category = ShopMasterData.get_category(item)
	purchased_items[item_id] = purchased_items.get(item_id, 0) + 1
	var cat_key = "__cat_" + category
	purchased_items[cat_key] = purchased_items.get(cat_key, 0) + 1
