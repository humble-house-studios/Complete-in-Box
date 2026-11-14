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
	{"id": "pack_rat", "market": ["cards", "sports", "comics", "books", "vinyl"], "name": "Pack Rat", "cost": 7, "desc": "Sealed packs and boxes appraise for x2."},
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
	# Rare books
	{"id": "debut_novel", "market": "books", "name": "First Novels", "cost": 6, "desc": "+0.3 Mult per author's debut on your shelf."},
	{"id": "antiquarian", "market": "books", "name": "Antiquarian", "cost": 7, "desc": "Books from before 1900 appraise for x2."},
	# Vinyl records
	{"id": "forty_five", "market": "vinyl", "name": "45 Collector", "cost": 6, "desc": "+0.3 Mult per single (a 45, a 78 or a 12-inch) on your shelf."},
	{"id": "golden_oldies", "market": "vinyl", "name": "Golden Oldies", "cost": 7, "desc": "Records from before 1970 appraise for x2."},
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

## One-use supplies (Balatro's consumables): bought at Home, carried in your
## pocket (Balance.POCKET_SLOTS), used whenever they fit. `when`: "venue" = only
## at a stop, "any" = Home too. `target` = pick a shelf item. Effects live in
## Run.use_supply.
const SUPPLIES := [
	{"id": "energy", "name": "Energy Drink", "cost": 3, "when": "venue", "desc": "+2 Time at this stop."},
	{"id": "loupe", "name": "Jeweler's Loupe", "cost": 3, "when": "venue", "desc": "See exact values for the rest of this stop."},
	{"id": "lucky_penny", "name": "Lucky Penny", "cost": 3, "when": "venue", "desc": "Your next haggle can't fail."},
	{"id": "gift_card", "name": "Gift Card", "cost": 5, "when": "venue", "desc": "Your next buy off the table is half price."},
	{"id": "cleaning_kit", "name": "Cleaning Kit", "cost": 4, "when": "any", "target": true, "desc": "One shelf item goes up a condition step (up to Mint)."},
	{"id": "flyer", "name": "Hype Flyer", "cost": 4, "when": "any", "target": true, "desc": "Pick a shelf item: its whole platform runs HOT through the next appraisal."},
	{"id": "copier", "name": "Shady Copier", "cost": 6, "when": "any", "target": true, "desc": "Copy a Common or Uncommon item on your shelf. Needs a free slot."},
	{"id": "spotlight", "name": "Display Spotlight", "cost": 4, "when": "any", "desc": "+1 Mult at your next appraisal."},
]

## Grab bags (Balatro's booster packs): one at Home each stop, pick 1 of the lot.
const BAGS := [
	{"id": "items", "name": "Garage Sale Box", "picks": 3, "desc": "Three finds from a stranger's garage. Keep one."},
	{"id": "supplies", "name": "Junk Drawer", "picks": 3, "cost": 4, "desc": "Three one-use supplies. Keep one."},
	{"id": "perks", "name": "Dusty Crate", "picks": 2, "cost": 5, "desc": "Two perks from the back of the attic. Keep one."},
]


## THE LANDLINE: the phone rings when a new ante starts. Three deals, take one
## (or hang up for a tip). They last the whole run and bend the rules; about
## half come with a catch. `caller`: buyer / stranger / arlo. `once` = never
## offered again once taken. `pitch` = card text, `desc` = the full terms,
## `quote` = what the voice says. Effects: search the id in run.gd.
const CALLS := [
	{"id": "wide_shelf", "caller": "stranger", "name": "Bigger Shelves", "pitch": "+2 shelf slots. Targets +10%.",
		"desc": "+2 shelf slots for the rest of the run. Every target is 10% higher.", "quote": "\"Shelving Depot, courtesy call. We deliver. He'll notice the extra space, though.\""},
	{"id": "specialist", "caller": "stranger", "once": true, "name": "The Specialist", "pitch": "One platform x2. All others half.",
		"desc": "%s items appraise for x2 for the rest of the run. Everything else appraises for half.", "quote": "\"Pick a lane, kid. Nobody respects a generalist.\""},
	{"id": "night_owl", "caller": "stranger", "name": "Night Owl", "pitch": "+2 Time every stop. Tables hold 1 less.",
		"desc": "+2 Time at every stop for the rest of the run. Every table starts with one item fewer.", "quote": "\"The good stuff's gone by nine. The patient stuff is still there at midnight.\""},
	{"id": "bulk_buyer", "caller": "stranger", "once": true, "name": "Bulk Buyer", "pitch": "Sets need 2 items, not 3.",
		"desc": "Platform Sets start at 2 items instead of 3 (and the big set at 4 instead of 5).", "quote": "\"Two's a pair. A pair's a set. That's what I tell the appraiser, anyway.\""},
	{"id": "perk_slot", "caller": "stranger", "name": "Wrong Number", "pitch": "+1 perk slot. No catch.",
		"desc": "+1 perk slot. They hang up before you can ask who Deborah is.", "quote": "\"Deborah? I left the backpack on your porch. ...This isn't Deborah.\""},
	{"id": "prize", "caller": "stranger", "name": "You've Won!", "pitch": "A free Garage Sale Box, opened.",
		"desc": "A free Garage Sale Box, already open: keep one of three finds.", "quote": "\"Congratulations! You are our ONE MILLIONTH caller. Please do not ask follow-up questions.\""},
	{"id": "condition_snob", "caller": "buyer", "once": true, "name": "Condition Snob", "pitch": "Mint + Sealed x2. Damaged + Loose $0.",
		"desc": "Your two best conditions appraise for x2 for the rest of the run. Your two worst appraise for nothing.", "quote": "\"I don't want it if it's been touched. You understand.\""},
	{"id": "advance", "caller": "buyer", "name": "An Advance", "pitch": "Cash now. This ante's targets +25%.",
		"desc": "+$%d right now. Every target this ante is 25%% higher.", "quote": "\"Consider it an investment. I always collect.\""},
	{"id": "collateral", "caller": "buyer", "name": "Collateral", "pitch": "He takes your best item. x1.5 Mult this ante.",
		"desc": "He takes %s off your shelf for good. In return: x1.5 Mult at every appraisal this ante.", "quote": "\"Leave it on the porch. My appraiser will be... generous.\""},
	{"id": "double_nothing", "caller": "buyer", "name": "Double or Nothing", "pitch": "Next stop: beat it by 50% for triple pay.",
		"desc": "At the next appraisal: beat the target by 50% and your payday is tripled. Pass by less and you're paid nothing.", "quote": "\"Let's make it interesting.\""},
	{"id": "sealed_fate", "caller": "buyer", "once": true, "name": "Sealed Fate", "pitch": "-1 perk slot. Perk Mult counts double.",
		"desc": "One perk slot is sealed shut for the rest of the run. Every +Mult your perks add counts double.", "quote": "\"Fewer things. Better things. That's all collecting is.\""},
	{"id": "static", "caller": "arlo", "name": "Static", "pitch": "Cash, and the want list pays double.",
		"desc": "+$%d, and this ante's want list reward is doubled.", "quote": "\"...kid? ...don't sell... what he asks for... he pays more than he... kssshh...\""},
]
const CALLERS := {
	"buyer": ["THE BUYER", Color("ff5a5a")], "stranger": ["UNKNOWN", Color("ffb84d")], "arlo": ["ARLO?", Color("7fe0ff")],
}


static func call_def(id: String) -> Dictionary:
	for c in CALLS:
		if c["id"] == id:
			return c
	return {}


static func supply(id: String) -> Dictionary:
	for s in SUPPLIES:
		if s["id"] == id:
			return s
	return {}


## Per-world names and text for the same perk (the effect never changes):
## THEMES[market][perk id] = [name, desc].
const THEMES := {
	"vinyl": {
		"box_and_manual": ["Inner Sleeves", "Very Good Plus records appraise for x1.5."],
		"shrink_wrap": ["Audiophile", "+0.5 Mult for each Near Mint or sealed record."],
		"completionist": ["Complete Discography", "Crate Set bonuses count double."],
		"curator": ["Every Crate", "x2 Mult if your shelf spans all 5 crates."],
		"cursed_cart": ["Cursed Acetate", "x2 Mult, but -2 shelf slots. It skips at the same bar every time."],
		"plastic_wrap": ["Still in Shrink", "Sealed records and dead-stock crates appraise for x2."],
		"dust_sheet": ["Party Copies", "Poor records appraise for x2.5."],
		"nostalgia": ["Dollar Bin Digger", "Common records appraise for x2."],
		"pack_rat": ["Crate Hoarder", "Crates appraise for x2."],
		"holo_hunter": ["Splatter Fan", "+0.6 Mult per shiny copy: coloured vinyl and picture discs."],
		"oddity_hunter": ["Pressing Nerd", "+0.4 Mult per variant copy (promos, mono, test pressings...)."],
		"full_page": ["Full Crate", "+1 Mult for each crate with 4+ records on your shelf."],
		"hot_streak": ["Heavy Rotation", "+0.5 Mult per record from a HOT crate."],
		"lucky_lots": ["Lucky Crates", "Mystery lots hold +1 item and roll a tier higher."],
		"slab_fan": ["Slabbed Sleeves", "+0.75 Mult per graded record on your shelf."],
	},
	"books": {
		"box_and_manual": ["Dust Jackets", "Very Good books appraise for x1.5."],
		"shrink_wrap": ["Fine Copies Only", "+0.5 Mult for each Near Fine or Fine book."],
		"completionist": ["Complete Shelf", "Shelf Set bonuses count double."],
		"curator": ["Every Shelf", "x2 Mult if your shelf spans all 5 shelves of the library."],
		"cursed_cart": ["Cursed Grimoire", "x2 Mult, but -2 shelf slots. The last chapter is always missing."],
		"plastic_wrap": ["Mylar Jackets", "Fine books and sealed-estate box lots appraise for x2."],
		"dust_sheet": ["Reading Copies", "Reading copies appraise for x2.5."],
		"nostalgia": ["Dollar Cart Diver", "Common books appraise for x2."],
		"pack_rat": ["Box Lot Hoarder", "Box lots appraise for x2."],
		"holo_hunter": ["Gilt Edge Fan", "+0.6 Mult per shiny copy: fine bindings and limited editions."],
		"oddity_hunter": ["Points Collector", "+0.4 Mult per variant copy (first state, signed, inscribed...)."],
		"full_page": ["Full Shelf", "+1 Mult for each shelf with 4+ books on your shelf."],
		"hot_streak": ["Bestseller List", "+0.5 Mult per book from a HOT shelf."],
		"lucky_lots": ["Lucky Box Lots", "Mystery lots hold +1 item and roll a tier higher."],
		"slab_fan": ["Clamshell Fan", "+0.75 Mult per described (graded) book on your shelf."],
	},
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
