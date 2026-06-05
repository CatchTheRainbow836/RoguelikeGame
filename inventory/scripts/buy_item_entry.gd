extends PanelContainer

@onready var icon: TextureRect = $HBoxContainer / TextureRect
@onready var name_label: Label = $HBoxContainer / ItemNameLabel
@onready var price_label: Label = $HBoxContainer / PriceLabel
@onready var buy_button: Button = $HBoxContainer / BuyButton

var item: ItemData
var shop_panel: Control

func setup(item_data: ItemData, panel: Control) -> void :
	item = item_data
	shop_panel = panel
	icon.texture = item.texture
	name_label.text = item.name
	price_label.text = str(ShopMasterData.get_buy_price(item))
	buy_button.pressed.connect(_on_buy_pressed)
	tooltip_text = "%s\n%s" % [item.name, item.description]

func _on_buy_pressed() -> void :
	shop_panel.attempt_buy_item(item)
