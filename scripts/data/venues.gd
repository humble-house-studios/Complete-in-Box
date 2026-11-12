class_name Venues
extends RefCounted
## Every ante has three stops, like Balatro's small blind / big blind / boss:
##   1. THE HUNT   - cheap, messy, guesswork (garage sale and friends)
##   2. THE SHOP   - fair prices, real services, they buy from you
##   3. ONLINE     - auctions, listings, and a boss twist every ante
## Each slot starts with one venue; more unlock as the run goes on and you pick
## which one to visit from Home.
##
## price: what they ask, as a multiple of true market value (random in range).
## exact: false = you only see an estimate range until you own it.
## tier_boost: added to the ante when rolling how rare the stock is.
## cond: weights for Damaged / Loose / CIB / Mint / Sealed.
## haggle: chance a haggle works (0 = no haggling). cut: price multiplier on success.
## dig: items added by spending Time to dig (0 = can't).
## sell: what they pay for your stuff as a share of market (0 = they don't buy).
## lots: mystery lots on offer, lot_size items each, lot_peek of them shown.
## auctions / bin: online auction lots and Buy It Now listings.
## list: you can list your own items for auction here: [low, high] of market, fee.

const SLOTS := ["hunt", "shop", "online"]
const SLOT_NAMES := {"hunt": "The Hunt", "shop": "The Shop", "online": "Online"}

const LIST := [
	{
		"id": "garage", "name": "Garage Sale", "slot": "hunt", "unlock": 1,
		"blurb": "Folding tables, masking-tape prices, zero clue what any of it is worth.",
		"time": 4, "stock": 6, "price": [0.15, 0.9], "exact": false, "tier_boost": 0,
		"cond": [25, 55, 15, 4, 1], "haggle": 0.65, "cut": 0.65, "dig": 2, "dig_label": "Dig a box",
		"sell": 0.0, "lots": 1, "lot_size": 3, "lot_peek": 1,
		"color": Color("e0a84a"),
	},
	{
		"id": "flea", "name": "Flea Market", "slot": "hunt", "unlock": 2,
		"blurb": "Rows of tables, a guy named Rick, and a booth you can sell from.",
		"time": 4, "stock": 7, "price": [0.35, 1.05], "exact": false, "tier_boost": 1,
		"cond": [15, 50, 25, 8, 2], "haggle": 0.6, "cut": 0.7, "dig": 2, "dig_label": "Next row",
		"sell": 0.75, "lots": 1, "lot_size": 3, "lot_peek": 1,
		"color": Color("d98c5f"),
	},
	{
		"id": "estate", "name": "Estate Sale", "slot": "hunt", "unlock": 4,
		"blurb": "A lifetime collection, priced by the grandkids. Fewer items, bigger finds.",
		"time": 3, "stock": 5, "price": [0.3, 0.85], "exact": false, "tier_boost": 2,
		"cond": [5, 35, 35, 17, 8], "haggle": 0.45, "cut": 0.75, "dig": 1, "dig_label": "Check the attic",
		"sell": 0.0, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("b38f6a"),
	},
	{
		"id": "storage", "name": "Storage Unit Auction", "slot": "hunt", "unlock": 6,
		"blurb": "Peek through the door, pay up, pray. Units only.",
		"time": 2, "stock": 0, "price": [0.5, 0.9], "exact": false, "tier_boost": 2,
		"cond": [20, 45, 22, 9, 4], "haggle": 0.0, "cut": 1.0, "dig": 0, "dig_label": "",
		"sell": 0.0, "lots": 3, "lot_size": 5, "lot_peek": 2,
		"color": Color("8a8f99"),
	},
	{
		"id": "retro", "name": "Retro Game Store", "slot": "shop", "unlock": 1,
		"blurb": "Glass cases, fair-ish prices. Buys your stuff, grades and repairs it.",
		"time": 3, "stock": 6, "price": [1.0, 1.2], "exact": true, "tier_boost": 1,
		"cond": [0, 40, 40, 15, 5], "haggle": 0.35, "cut": 0.85, "dig": 1, "dig_label": "Check the back",
		"sell": 0.55, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true, "repair": true,
		"bargain": 2,
		"color": Color("5fb3d9"),
	},
	{
		"id": "pawn", "name": "Pawn Shop", "slot": "shop", "unlock": 3,
		"blurb": "Prices all over the place. Steals and rip-offs side by side. Haggle hard.",
		"time": 4, "stock": 6, "price": [0.55, 1.45], "exact": true, "tier_boost": 1,
		"cond": [15, 50, 25, 8, 2], "haggle": 0.75, "cut": 0.8, "dig": 1, "dig_label": "Ask what's in back",
		"sell": 0.45, "lots": 0, "lot_size": 0, "lot_peek": 0, "repair": true,
		"color": Color("c2c25a"),
	},
	{
		"id": "convention", "name": "Collector Con", "slot": "shop", "unlock": 5,
		"blurb": "Graded slabs, sealed grails, collectors with deep pockets who buy high.",
		"time": 3, "stock": 5, "price": [1.0, 1.2], "exact": true, "tier_boost": 3,
		"cond": [0, 15, 40, 30, 15], "haggle": 0.3, "cut": 0.85, "dig": 1, "dig_label": "Walk the floor",
		"sell": 0.7, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true,
		"color": Color("d95fa8"),
	},
	{
		"id": "ebay", "name": "eBuy", "slot": "online", "unlock": 1,
		"blurb": "Buy It Now, bid on auctions, list your own. Everything settles when the stop ends.",
		"time": 4, "stock": 5, "price": [0.95, 1.25], "exact": true, "tier_boost": 1,
		"cond": [5, 40, 35, 15, 5], "haggle": 0.0, "cut": 1.0, "dig": 5, "dig_label": "Refresh search",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 2, "bin": true, "list": [0.6, 1.5], "fee": 0.13,
		"color": Color("4fd9a0"),
	},
	{
		"id": "heritage", "name": "Heritage Auction House", "slot": "online", "unlock": 6,
		"blurb": "White gloves, paddles, graded grails. Auctions only, big fees, bigger buyers.",
		"time": 3, "stock": 0, "price": [1.0, 1.0], "exact": true, "tier_boost": 3,
		"cond": [0, 5, 30, 35, 30], "haggle": 0.0, "cut": 1.0, "dig": 0, "dig_label": "",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 4, "bin": false, "list": [0.9, 1.8], "fee": 0.2,
		"color": Color("e6c35c"),
	},
]

## The online stop's boss twist, one per ante (Balatro's boss blinds).
const BOSSES := [
	{"id": "snipers", "name": "Sniper Season", "desc": "Rival bidders go 30% higher."},
	{"id": "shipping", "name": "Shipping Strike", "desc": "Buy It Now prices +30%."},
	{"id": "scams", "name": "Scam Wave", "desc": "35% of online buys arrive a condition worse."},
	{"id": "fees", "name": "Fee Hike", "desc": "Seller fees are 25%."},
	{"id": "lowball", "name": "Lowballers", "desc": "Your listings sell for 40% less."},
	{"id": "picky", "name": "Picky Appraiser", "desc": "Damaged and Loose items appraise at half."},
	{"id": "skeptic", "name": "Set Skeptic", "desc": "No Platform Set bonuses this stop."},
	{"id": "crash", "name": "Market Crash", "desc": "Two platforms go cold at once."},
]

static var _by_id: Dictionary = {}


static func get_def(id: String) -> Dictionary:
	if _by_id.is_empty():
		for d in LIST:
			_by_id[d["id"]] = d
		for b in BOSSES:
			_by_id["boss_" + str(b["id"])] = b
	return _by_id.get(id, {})


static func boss(id: String) -> Dictionary:
	return get_def("boss_" + id)


## Venues open for a slot at this ante, newest unlock last.
static func unlocked(slot: String, ante: int) -> Array:
	var out: Array = []
	for d in LIST:
		if d["slot"] == slot and int(d["unlock"]) <= ante:
			out.append(d)
	return out
