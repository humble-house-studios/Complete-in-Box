class_name Perks
extends RefCounted
## Perks are the Jokers: bought at Home between stops, they bend the rules.
## The engine checks for them by id (Run.has_perk), so each perk's effect lives
## next to the rule it changes (search the id to find it).

const LIST := [
	{"id": "price_guide", "name": "Price Guide", "cost": 5, "desc": "See exact values at every sale, no guessing."},
	{"id": "silver_tongue", "name": "Silver Tongue", "cost": 6, "desc": "Haggles succeed 25% more often and never backfire."},
	{"id": "early_bird", "name": "Early Bird", "cost": 5, "desc": "+2 items on the table at Hunt stops."},
	{"id": "extra_hour", "name": "Extra Hour", "cost": 6, "desc": "+1 Time at every stop."},
	{"id": "box_and_manual", "name": "Box & Manual", "cost": 7, "desc": "CIB items appraise for x1.5."},
	{"id": "shrink_wrap", "name": "Shrink Wrap Fan", "cost": 8, "desc": "+0.5 Mult for each Mint or Sealed item."},
	{"id": "hoarder", "name": "Hoarder", "cost": 6, "desc": "+0.15 Mult for every item on your shelf."},
	{"id": "moms_basement", "name": "Mom's Basement", "cost": 6, "desc": "+2 shelf slots."},
	{"id": "power_seller", "name": "Power Seller", "cost": 6, "desc": "Online: no seller fees, your auctions sell 15% higher."},
	{"id": "sticker_gun", "name": "Price Sticker Gun", "cost": 4, "desc": "+$8 appraisal per item on your shelf."},
	{"id": "funtendo_kid", "name": "Funtendo Kid", "cost": 6, "desc": "+0.3 Mult per Funtendo item (FES, SFES, F64, PBOY)."},
	{"id": "saga_does", "name": "Saga Does", "cost": 6, "desc": "+0.5 Mult per Saga item (GEN, DC)."},
	{"id": "disc_jockey", "name": "Disc Jockey", "cost": 6, "desc": "Disc games (PST, DC) appraise for x2."},
	{"id": "completionist", "name": "Completionist", "cost": 8, "desc": "Platform Set bonuses count double."},
	{"id": "piggy_bank", "name": "Piggy Bank", "cost": 5, "desc": "Interest cap raised from $5 to $12."},
	{"id": "lucky_lots", "name": "Lucky Lots", "cost": 6, "desc": "Mystery lots hold +1 item and roll a tier higher."},
	{"id": "flipper", "name": "Flipper", "cost": 5, "desc": "+$3 every time you sell something for more than you paid."},
	{"id": "hype_beast", "name": "Hype Beast", "cost": 6, "desc": "Hot trends hit twice as hard; cold ones half as hard."},
	{"id": "time_capsule", "name": "Time Capsule", "cost": 7, "desc": "Held items appreciate twice as fast."},
	{"id": "grader_buddy", "name": "Grader Buddy", "cost": 6, "desc": "Grading is free and never comes back below an 8."},
	{"id": "bubble_wrap", "name": "Bubble Wrap", "cost": 4, "desc": "Online buys always arrive as described."},
	{"id": "nostalgia", "name": "Nostalgia Goggles", "cost": 7, "desc": "Common items appraise for x2."},
	{"id": "curator", "name": "Curator", "cost": 9, "desc": "x2 Mult if your shelf spans 5+ platforms."},
	{"id": "coupon", "name": "Coupon Clipper", "cost": 5, "desc": "Everything you buy is 15% cheaper."},
	{"id": "eagle_eye", "name": "Eagle Eye", "cost": 6, "desc": "Hunt items have a 25% chance to be a condition better."},
	{"id": "whale", "name": "Whale Watcher", "cost": 8, "desc": "+2 Mult per GRAIL on your shelf."},
	{"id": "lunchbox", "name": "Lunchbox Display", "cost": 5, "desc": "Accessories appraise for x3."},
	{"id": "console_wars", "name": "Console Wars", "cost": 7, "desc": "+1 Mult per console on your shelf."},
]

## One-off upgrades offered at Home (Balatro's vouchers).
const UPGRADES := [
	{"id": "shelf", "name": "Shelf Expansion", "cost": 8, "desc": "+1 shelf slot for the rest of the run."},
	{"id": "time", "name": "Wristwatch", "cost": 10, "desc": "+1 Time at every stop."},
	{"id": "perk_slot", "name": "Bigger Backpack", "cost": 10, "desc": "+1 perk slot."},
	{"id": "interest", "name": "High-Yield Savings", "cost": 8, "desc": "+$3 interest cap."},
	{"id": "reroll", "name": "Coupon Book", "cost": 6, "desc": "Perk rerolls cost $1 less (min $0)."},
]

static var _by_id: Dictionary = {}


static func get_def(id: String) -> Dictionary:
	if _by_id.is_empty():
		for d in LIST:
			_by_id[d["id"]] = d
		for d in UPGRADES:
			_by_id["up_" + str(d["id"])] = d
	return _by_id.get(id, {})


static func upgrade(id: String) -> Dictionary:
	return get_def("up_" + id)
