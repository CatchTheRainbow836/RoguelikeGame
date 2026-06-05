extends Node
const AEGIS_FRAGMENT = preload("uid://5hau8gtkyho7")
const AMBROSIA_OF_THE_GODS = preload("uid://httbfpwnvooj")
const ARTILLERY_HELMET = preload("uid://l2300hvme0a0")
const BLACKSMITH_S_SLEDGE = preload("uid://dgo4ir2seo4jq")
const BLOW_PIPE = preload("uid://04nvosa4pjq4")
const BLUE_BOOK = preload("uid://dhg70g3wh6rht")
const BOOTS_OF_MERCURY = preload("uid://bhqwjid0gcsuy")
const BRIGANDINE_VEST = preload("uid://bpbrbavfvg3c1")
const BULLET_1 = preload("uid://b2bo053xnmtpy")
const BULLET_2 = preload("uid://dws75647lcq3m")
const BULLET_3 = preload("uid://c0lw56mqgpq1v")
const BULLET_4 = preload("uid://d2u7xdknxl637")
const BULLET_5 = preload("uid://0c25ednalgrd")
const BULLET_6 = preload("uid://bdre0legeyxgc")
const BULLET_7 = preload("uid://l5p4fpthncf8")
const CLOCKWORK_SCARAB = preload("uid://01fc4p8ufcm2")
const COWL_OF_THE_UNSEEN = preload("uid://ylloisufo4x2")
const CRACKED_REINFORCED_SHIELD = preload("uid://b4ylgkbmp0ccj")
const CRESCENT_ROSE = preload("uid://b44u6ds026q0p")
const DOWSING_ROD = preload("uid://n1sih737j66f")
const DUELIST_S_GLOVES = preload("uid://cfpqnwvsg6s4o")
const ECHO_OF_VALHALLA = preload("uid://7lfdigs4brni")
const ELIXIR_OF_HERACLES = preload("uid://cg3vy7ppxwa1d")
const FLINTLOCK_PISTOL = preload("uid://con7r58gt6t8o")
const FRAGMENTATION_GRENADE = preload("uid://o3pn013b16i5")
const GJALLARHORN = preload("uid://ddx8gpwibe6a0")
const GOBLIN_FIRE_OIL = preload("uid://cbbmwrky0f8hu")
const GRENADE = preload("uid://duryrnpi4iik6")
const GUNGNIR = preload("uid://dsfju0fy7nidg")
const HAG_S_FINGERNAIL = preload("uid://kwlc5ddnb21e")
const HEALTH_POTION = preload("uid://dkgsqn13h6g4h")
const HUNTING_RIFLE = preload("uid://b6rp2p4vcjwud")
const IRON_HELM = preload("uid://bcb1lhfj54hc4")
const IRON_SOLED_BOOTS = preload("uid://vd4f1c4704r5")
const KRAKEN_S_INK = preload("uid://cdr4txlrjxgk4")
const LEATHER_PAULDRONS = preload("uid://c022piqa3m5gx")
const LIFEBLOOD_SYRETTE = preload("uid://bsm62yvs0rwd")
const MARKSMAN_S_MONOCLE = preload("uid://cxtfcc3lm1svb")
const MJOLNIR_S_REPLICA = preload("uid://q52d35xxg4jg")
const PANDORA_S_BOX = preload("uid://ble73w3e6yw7c")
const PHANTOM_S_HAND = preload("uid://jjh6rfrgj51g")
const PISTOL = preload("uid://chwwxs1bnov8h")
const PLAGUE_DOCTOR_S_MASK = preload("uid://bw6b1w3jh4k0s")
const POTION_BELT = preload("uid://cudnc23ov7qs3")
const PUZZLE_BOX_OF_YGGDRASIL = preload("uid://djkwmbd8ck0mq")
const QUICKSILVER_BROOCH = preload("uid://c187o12d2cup4")
const REPEATING_CROSSBOW = preload("uid://df7x8jsy82tjf")
const RUNIC_WARD = preload("uid://uckuy50plvho")
const SAPPER_S_APRON = preload("uid://csbcwc6j755rt")
const SCRAP_METAL_GAUNTLET = preload("uid://bgogwvhg0x872")
const SIREN_S_LOCKET = preload("uid://b3dljyipkgu3t")
const SMOKE_GRENADE = preload("uid://b14umoh0p1gb3")
const SOLDIER_S_MEDALLION = preload("uid://dmx5xvmvkjjmc")
const STANDARD_ISSUE_SABER = preload("uid://4yuiaj8od33a")
const STONE_GIANT_S_PEBBLE = preload("uid://beukcvrnnhofh")
const STUN_GRENADE = preload("uid://7omtdo8r1q6s")
const SWORD = preload("uid://70d4mo5nxqhl")
const TITHONUS__CURSE = preload("uid://cy2f2vkaugs3v")
const VIAL_OF_STARLIGHT = preload("uid://brir3b2ykkvjy")
const VORPAL_BLADE = preload("uid://bg3c50gl3ywmo")
const VULCAN_S_FURY = preload("uid://cc22woekywaya")
const WILL_O__THE_WISPS = preload("uid://d3g4qqgeqlvw0")
const WORLD_EATER_S_TOOTH = preload("uid://dr6il3y1c67co")

static var master_data = {
	SOLDIER_S_MEDALLION.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	ELIXIR_OF_HERACLES.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {}
	}, 
	WORLD_EATER_S_TOOTH.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {}
	}, 
	VIAL_OF_STARLIGHT.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {}
	}, 
	HAG_S_FINGERNAIL.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {}
	}, 
	GOBLIN_FIRE_OIL.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {}
	}, 
	KRAKEN_S_INK.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {}
	}, 
	STONE_GIANT_S_PEBBLE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	LIFEBLOOD_SYRETTE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	SIREN_S_LOCKET.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "consumable", 
		"unlock_conditions": {}
	}, 
	WILL_O__THE_WISPS.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_category_counts": {
				"consumable": 7
			}
		}
	}, 
	PANDORA_S_BOX.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_category_counts": {
				"consumable": 7
			}
		}
	}, 
	CLOCKWORK_SCARAB.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_category_counts": {
				"consumable": 7
			}
		}
	}, 
	ECHO_OF_VALHALLA.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_category_counts": {
				"consumable": 7
			}
		}
	}, 
	AMBROSIA_OF_THE_GODS.resource_path: {
		"sell_price": 750, 
		"buy_price": 1000, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_category_counts": {
				"consumable": 12
			}, 
			"requires_total_purchases": 40
		}
	}, 
	PUZZLE_BOX_OF_YGGDRASIL.resource_path: {
		"sell_price": 750, 
		"buy_price": 1000, 
		"category": "consumable", 
		"unlock_conditions": {
			"requires_category_counts": {
				"consumable": 12
			}, 
			"requires_total_purchases": 40
		}
	}, 
	LEATHER_PAULDRONS.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	IRON_SOLED_BOOTS.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	DUELIST_S_GLOVES.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	MARKSMAN_S_MONOCLE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	QUICKSILVER_BROOCH.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	BRIGANDINE_VEST.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	ARTILLERY_HELMET.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	DOWSING_ROD.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	POTION_BELT.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	PLAGUE_DOCTOR_S_MASK.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {}
	}, 
	SAPPER_S_APRON.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	RUNIC_WARD.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_category_counts": {
				"equipment": 7
			}
		}
	}, 
	COWL_OF_THE_UNSEEN.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_category_counts": {
				"equipment": 7
			}
		}
	}, 
	BOOTS_OF_MERCURY.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_category_counts": {
				"equipment": 7
			}
		}
	}, 
	PHANTOM_S_HAND.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_category_counts": {
				"equipment": 7
			}
		}
	}, 
	TITHONUS__CURSE.resource_path: {
		"sell_price": 750, 
		"buy_price": 1000, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_category_counts": {
				"equipment": 12
			}, 
			"requires_total_purchases": 40
		}
	}, 
	AEGIS_FRAGMENT.resource_path: {
		"sell_price": 750, 
		"buy_price": 1000, 
		"category": "equipment", 
		"unlock_conditions": {
			"requires_category_counts": {
				"equipment": 12
			}, 
			"requires_total_purchases": 40
		}
	}, 
	STANDARD_ISSUE_SABER.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	REPEATING_CROSSBOW.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	FRAGMENTATION_GRENADE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	BLACKSMITH_S_SLEDGE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	HUNTING_RIFLE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	SMOKE_GRENADE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	CRACKED_REINFORCED_SHIELD.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	FLINTLOCK_PISTOL.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {}
	}, 
	STUN_GRENADE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	SCRAP_METAL_GAUNTLET.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	BLOW_PIPE.resource_path: {
		"sell_price": 100, 
		"buy_price": 250, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_total_purchases": 6
		}
	}, 
	MJOLNIR_S_REPLICA.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_category_counts": {
				"weapon": 7
			}
		}
	}, 
	CRESCENT_ROSE.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_category_counts": {
				"weapon": 7
			}
		}
	}, 
	VORPAL_BLADE.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_category_counts": {
				"weapon": 7
			}
		}
	}, 
	GJALLARHORN.resource_path: {
		"sell_price": 250, 
		"buy_price": 500, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_category_counts": {
				"weapon": 7
			}
		}
	}, 
	GUNGNIR.resource_path: {
		"sell_price": 750, 
		"buy_price": 1000, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_category_counts": {
				"weapon": 12
			}, 
			"requires_total_purchases": 40
		}
	}, 
	VULCAN_S_FURY.resource_path: {
		"sell_price": 750, 
		"buy_price": 1000, 
		"category": "weapon", 
		"unlock_conditions": {
			"requires_category_counts": {
				"weapon": 12
			}, 
			"requires_total_purchases": 40
		}
	}, 
	BULLET_1.resource_path: {
		"sell_price": 1, 
		"buy_price": 1, 
		"category": "weapon_consumable", 
		"unlock_conditions": {}
	}, 
	BULLET_2.resource_path: {
		"sell_price": 1, 
		"buy_price": 1, 
		"category": "weapon_consumable", 
		"unlock_conditions": {}
	}, 
	BULLET_3.resource_path: {
		"sell_price": 1, 
		"buy_price": 1, 
		"category": "weapon_consumable", 
		"unlock_conditions": {}
	}, 
	BULLET_4.resource_path: {
		"sell_price": 2, 
		"buy_price": 2, 
		"category": "weapon_consumable", 
		"unlock_conditions": {
			"requires_items": [BLOW_PIPE.resource_path]
		}
	}, 
	BULLET_5.resource_path: {
		"sell_price": 1, 
		"buy_price": 1, 
		"category": "weapon_consumable", 
		"unlock_conditions": {
			"requires_items": [CRESCENT_ROSE.resource_path]
		}
	}, 
	BULLET_6.resource_path: {
		"sell_price": 5, 
		"buy_price": 5, 
		"category": "weapon_consumable", 
		"unlock_conditions": {
			"requires_items": [GJALLARHORN.resource_path]
		}
	}, 
	BULLET_7.resource_path: {
		"sell_price": 1, 
		"buy_price": 1, 
		"category": "weapon_consumable", 
		"unlock_conditions": {
			"requires_items": [VULCAN_S_FURY.resource_path]
		}
	}, 
}

static func get_sell_price(item: ItemData) -> int:
	var data = master_data.get(item.resource_path)
	return data["sell_price"] if data else 0

static func get_buy_price(item: ItemData) -> int:
	var data = master_data.get(item.resource_path)
	return data["buy_price"] if data else 0

static func get_category(item: ItemData) -> String:
	var data = master_data.get(item.resource_path)
	return data["category"] if data else ""

static func get_unlock_conditions(item: ItemData) -> Dictionary:
	var data = master_data.get(item.resource_path)
	return data["unlock_conditions"] if data else {}
