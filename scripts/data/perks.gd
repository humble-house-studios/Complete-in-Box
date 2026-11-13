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
	{"id": "funtendo_kid", "market": "games", "name": "Funtendo Kid", "cost": 6, "desc": "+0.3 Mult per Funtendo item (FES, SFES, F64, PBOY, PBA, CUBE, DUO)."},
	{"id": "saga_does", "market": "games", "name": "Saga Does", "cost": 6, "desc": "+0.5 Mult per Saga item (GEN, DC, SAT)."},
	{"id": "disc_jockey", "market": "games", "name": "Disc Jockey", "cost": 6, "desc": "Disc games (PST, PST2, DC, SAT, CUBE, XBUX) appraise for x2."},
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
	{"id": "lunchbox", "market": "games", "name": "Lunchbox Display", "cost": 5, "desc": "Accessories appraise for x3."},
	{"id": "pack_rat", "market": ["cards", "sports", "comics"], "name": "Pack Rat", "cost": 7, "desc": "Sealed packs and boxes appraise for x2."},
	{"id": "holo_hunter", "name": "Shiny Hunter", "cost": 7, "desc": "+0.6 Mult per shiny copy: holo, 1st Edition, proof-like, cameo or toned."},
	{"id": "gold_bug", "market": "coins", "name": "Gold Bug", "cost": 7, "desc": "Gold coins appraise for x2."},
	{"id": "console_wars", "market": "games", "name": "Console Wars", "cost": 7, "desc": "+1 Mult per console on your shelf."},
	{"id": "glass_case", "name": "Glass Case", "cost": 6, "desc": "Items held 3+ stops appraise for x1.5."},
	{"id": "hot_streak", "name": "Hot Streak", "cost": 6, "desc": "+0.5 Mult per item from a HOT platform."},
	{"id": "dollar_bin", "name": "Dollar Bin Hero", "cost": 5, "desc": "Items you paid $3 or less for appraise +$10."},
	{"id": "haggle_king", "name": "Haggle King", "cost": 6, "desc": "Grows: +0.25 Mult for every haggle you win this run."},
	{"id": "oddity_hunter", "name": "Oddity Hunter", "cost": 7, "desc": "+0.4 Mult per variant copy (First Print, Misprint, Black Label...)."},
	{"id": "cursed_cart", "name": "Cursed Cartridge", "cost": 8, "desc": "x2 Mult, but -2 shelf slots. It hums at night."},
	# Binder rewards: only in the shop once your collection unlocks them ("lock").
	{"id": "plastic_wrap", "lock": "binder", "name": "Plastic Wrap", "cost": 6, "desc": "Sealed items appraise for x2."},
	{"id": "dust_sheet", "lock": "binder", "name": "Dust Sheet", "cost": 5, "desc": "Damaged items appraise for x2.5."},
	{"id": "full_page", "lock": "binder", "name": "Full Page", "cost": 8, "desc": "+1 Mult for each platform with 4+ items on your shelf."},
	{"id": "slab_fan", "lock": "binder", "name": "Slab Fan", "cost": 7, "desc": "+0.75 Mult per graded item on your shelf."},
	{"id": "archivist", "lock": "binder", "name": "Archivist", "cost": 6, "desc": "Items held 2+ stops appraise +$12."},
	{"id": "long_box", "lock": "binder", "name": "The Long Box", "cost": 7, "desc": "+1 shelf slot, and +0.1 Mult for every item on your shelf."},
	# Sports cards
	{"id": "rookie_fever", "market": "sports", "name": "Rookie Fever", "cost": 6, "desc": "+0.3 Mult per rookie card on your shelf."},
	# Comics
	{"id": "key_issue", "market": "comics", "name": "Key Issues", "cost": 6, "desc": "+0.3 Mult per key issue (a first appearance) on your shelf."},
	{"id": "golden_age", "market": "comics", "name": "Golden Age Guy", "cost": 7, "desc": "Comics from before 1970 appraise for x2."},
	{"id": "hall_of_fame", "market": "sports", "name": "Hall of Famer", "cost": 7, "desc": "Cards from before 1980 appraise for x2."},
]

## One-off upgrades offered at Home (Balatro's vouchers).
const UPGRADES := [
	{"id": "shelf", "name": "Shelf Expansion", "cost": 8, "desc": "+1 shelf slot for the rest of the run."},
	{"id": "time", "name": "Wristwatch", "cost": 10, "desc": "+1 Time at every stop."},
	{"id": "perk_slot", "name": "Bigger Backpack", "cost": 10, "desc": "+1 perk slot."},
	{"id": "interest", "name": "High-Yield Savings", "cost": 8, "desc": "+$3 interest cap."},
	{"id": "reroll", "name": "Coupon Book", "cost": 6, "desc": "Perk rerolls cost $1 less (min $0)."},
]

## Per-world names and text for the same perk (the effect never changes):
## THEMES[market][perk id] = [name, desc].
const THEMES := {
	"comics": {
		"box_and_manual": ["Bags & Boards", "Very Fine comics appraise for x1.5."],
		"shrink_wrap": ["High Grader", "+0.5 Mult for each Near Mint or Mint comic."],
		"completionist": ["Run Collector", "Era Set bonuses count double."],
		"curator": ["Every Era", "x2 Mult if your shelf spans all 5 eras."],
		"cursed_cart": ["Cursed Issue", "x2 Mult, but -2 shelf slots. The last page is always missing."],
		"plastic_wrap": ["Still Polybagged", "Mint comics and warehouse-find longboxes appraise for x2."],
		"dust_sheet": ["Reading Copies", "Poor comics appraise for x2.5."],
		"nostalgia": ["Back-Issue Bin Diver", "Common comics appraise for x2."],
		"pack_rat": ["Longbox Hoarder", "Longboxes appraise for x2."],
		"holo_hunter": ["Foil Fiend", "+0.6 Mult per shiny copy: foil and virgin covers."],
		"oddity_hunter": ["Variant Chaser", "+0.4 Mult per variant copy (newsstand, price variants, signed...)."],
		"full_page": ["Full Run", "+1 Mult for each era with 4+ comics on your shelf."],
		"hot_streak": ["Hot Book", "+0.5 Mult per comic from a HOT era."],
		"lucky_lots": ["Lucky Longboxes", "Mystery lots hold +1 item and roll a tier higher."],
		"slab_fan": ["Slab Fan", "+0.75 Mult per graded comic on your shelf."],
	},
	"sports": {
		"box_and_manual": ["Top-Loaders", "Near Mint cards appraise for x1.5."],
		"shrink_wrap": ["Gem Mint Fan", "+0.5 Mult for each Mint or Gem Mint piece."],
		"completionist": ["Team Collector", "Sport Set bonuses count double."],
		"curator": ["Multi-Sport Star", "x2 Mult if your shelf spans 5+ sports."],
		"cursed_cart": ["Cursed Card", "x2 Mult, but -2 shelf slots. It whispers stats at night."],
		"plastic_wrap": ["Gem Sealed", "Gem Mint cards and case-fresh wax appraise for x2."],
		"dust_sheet": ["Shoebox Special", "Creased cards appraise for x2.5."],
		"nostalgia": ["Junk Wax Kid", "Common cards appraise for x2."],
		"pack_rat": ["Wax Rat", "Wax packs and boxes appraise for x2."],
		"holo_hunter": ["Refractor Hunter", "+0.6 Mult per shiny copy: refractors, gold parallels, chrome."],
		"oddity_hunter": ["Parallel Chaser", "+0.4 Mult per variant copy (parallels, autos, patches...)."],
		"full_page": ["Full Team Page", "+1 Mult for each sport with 4+ cards on your shelf."],
		"hot_streak": ["Hot Hand", "+0.5 Mult per card from a HOT sport."],
		"lucky_lots": ["Lucky Repacks", "Repack lots hold +1 item and roll a tier higher."],
	},
}

static var _by_id: Dictionary = {}


static func get_def(id: String) -> Dictionary:
	if _by_id.is_empty():
		for d in LIST:
			_by_id[d["id"]] = d
		for d in UPGRADES:
			_by_id["up_" + str(d["id"])] = d
	return _by_id.get(id, {})


## The perk as it reads in this world (same effect, the world's own words).
static func label(id: String, market: String = "") -> Dictionary:
	var d := get_def(id)
	var t: Array = THEMES.get(market, {}).get(id, [])
	if t.is_empty():
		return d
	var out := d.duplicate()
	out["name"] = t[0]
	out["desc"] = t[1]
	return out


## Which worlds a perk shows up in ([] = every world).
static func markets(id: String) -> Array:
	var m = get_def(id).get("market", "")
	if m is Array:
		return m
	return [] if String(m) == "" else [String(m)]


static func upgrade(id: String) -> Dictionary:
	return get_def("up_" + id)
