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
	# ------------------------------------------------ trading cards (market "cards")
	{
		"id": "cardshow", "name": "Card Show", "slot": "hunt", "unlock": 1, "market": "cards",
		"blurb": "A hotel ballroom of folding tables, binders and bargain boxes. Dig the dollar bins.",
		"time": 4, "stock": 6, "price": [0.3, 0.95], "exact": false, "tier_boost": 0,
		"cond": [12, 40, 32, 12, 4], "haggle": 0.6, "cut": 0.7, "dig": 2, "dig_label": "Dig a dollar bin",
		"sell": 0.7, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("f2c230"),
	},
	{
		"id": "tradenight", "name": "Trade Night", "slot": "hunt", "unlock": 1, "market": "cards",
		"blurb": "Thursday at the game store. Kids with binders who don't know what they've got.",
		"time": 4, "stock": 5, "price": [0.2, 0.8], "exact": false, "tier_boost": 0,
		"cond": [25, 45, 20, 8, 2], "haggle": 0.7, "cut": 0.65, "dig": 2, "dig_label": "Flip another binder",
		"sell": 0.0, "lots": 1, "lot_size": 3, "lot_peek": 1,
		"color": Color("7ac74f"),
	},
	{
		"id": "cardshop", "name": "The Card Shop", "slot": "shop", "unlock": 1, "market": "cards",
		"blurb": "Glass cases of slabs, a wall of sealed boxes, a grading counter. Buys your pulls.",
		"time": 3, "stock": 6, "price": [1.0, 1.2], "exact": true, "tier_boost": 1,
		"cond": [0, 20, 45, 25, 10], "haggle": 0.35, "cut": 0.85, "dig": 1, "dig_label": "Check the back case",
		"sell": 0.6, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true, "bargain": 2,
		"color": Color("e05f5f"),
	},
	{
		"id": "tcgmarket", "name": "TCGrabber", "slot": "online", "unlock": 1, "market": "cards",
		"blurb": "The big card marketplace. Buy singles, bid on slabs, list your own.",
		"time": 4, "stock": 5, "price": [0.95, 1.25], "exact": true, "tier_boost": 1,
		"cond": [5, 30, 40, 18, 7], "haggle": 0.0, "cut": 1.0, "dig": 5, "dig_label": "Refresh listings",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 3, "bin": true, "list": [0.7, 1.6], "fee": 0.12,
		"color": Color("5f8fe0"),
	},
	# ------------------------------------------------ sports cards (market "sports")
	{
		"id": "ballroom", "name": "Hotel Ballroom Show", "slot": "hunt", "unlock": 1, "market": "sports",
		"blurb": "Sunday at the Ramadoh ballroom: chandeliers, folding tables, dime boxes and old men with loupes.",
		"time": 4, "stock": 6, "price": [0.3, 0.95], "exact": false, "tier_boost": 0,
		"cond": [12, 40, 32, 12, 4], "haggle": 0.6, "cut": 0.7, "dig": 2, "dig_label": "Dig a dime box",
		"sell": 0.7, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("3fae5a"),
	},
	{
		"id": "shoebox", "name": "Shoebox Sale", "slot": "hunt", "unlock": 1, "market": "sports",
		"blurb": "A dad's garage, three shoeboxes of 1980s cards and a sign that says ALL $1. Mostly junk wax. Mostly.",
		"time": 4, "stock": 5, "price": [0.15, 0.8], "exact": false, "tier_boost": 0,
		"cond": [28, 45, 18, 7, 2], "haggle": 0.7, "cut": 0.65, "dig": 2, "dig_label": "Open another shoebox",
		"sell": 0.0, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("c9a26a"),
	},
	{
		"id": "dugout", "name": "The Dugout", "slot": "shop", "unlock": 1, "market": "sports",
		"blurb": "Local card shop: wax on the wall, slabs in the case, a grading counter and a guy who remembers every price.",
		"time": 3, "stock": 6, "price": [1.0, 1.2], "exact": true, "tier_boost": 1,
		"cond": [0, 20, 45, 25, 10], "haggle": 0.35, "cut": 0.85, "dig": 1, "dig_label": "Check the back case",
		"sell": 0.6, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true, "bargain": 2,
		"color": Color("2f6fd0"),
	},
	{
		"id": "breaks", "name": "Breakz Live", "slot": "online", "unlock": 1, "market": "sports",
		"blurb": "Live box breaks and slab auctions on a stream with forty thousand people typing LFG.",
		"time": 4, "stock": 5, "price": [0.95, 1.25], "exact": true, "tier_boost": 1,
		"cond": [5, 30, 40, 18, 7], "haggle": 0.0, "cut": 1.0, "dig": 5, "dig_label": "Refresh the stream",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 3, "bin": true, "list": [0.7, 1.6], "fee": 0.12,
		"color": Color("e05fd0"),
	},
	# ------------------------------------------------ comics (market "comics")
	{
		"id": "comiccon", "name": "Comic Con Floor", "slot": "hunt", "unlock": 1, "market": "comics",
		"blurb": "Artist alley, cosplayers, and dealers' longboxes at five bucks a book. Dig the back rows.",
		"time": 4, "stock": 6, "price": [0.3, 0.95], "exact": false, "tier_boost": 0,
		"cond": [12, 40, 32, 12, 4], "haggle": 0.6, "cut": 0.7, "dig": 2, "dig_label": "Flip a longbox",
		"sell": 0.7, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("e04a3a"),
	},
	{
		"id": "atticfind", "name": "Attic Find", "slot": "hunt", "unlock": 1, "market": "comics",
		"blurb": "A dead grandpa's attic, boxes under the insulation and a family that wants them gone. Mice included.",
		"time": 4, "stock": 5, "price": [0.15, 0.8], "exact": false, "tier_boost": 0,
		"cond": [30, 45, 17, 6, 2], "haggle": 0.7, "cut": 0.65, "dig": 2, "dig_label": "Check under the insulation",
		"sell": 0.0, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("a8703a"),
	},
	{
		"id": "comicshop", "name": "Panel Hoppers", "slot": "shop", "unlock": 1, "market": "comics",
		"blurb": "A comic shop with a back-issue wall to the ceiling, bins by era and a counter that sends books for grading.",
		"time": 3, "stock": 6, "price": [1.0, 1.2], "exact": true, "tier_boost": 1,
		"cond": [0, 20, 45, 25, 10], "haggle": 0.35, "cut": 0.85, "dig": 1, "dig_label": "Ask about the wall books",
		"sell": 0.6, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true, "bargain": 2,
		"color": Color("3a7fd9"),
	},
	{
		"id": "comicauction", "name": "PanelLink", "slot": "online", "unlock": 1, "market": "comics",
		"blurb": "The comic auction site: slabbed keys, pedigree copies, live bidding and a buyer's premium.",
		"time": 4, "stock": 5, "price": [0.95, 1.25], "exact": true, "tier_boost": 1,
		"cond": [5, 30, 40, 18, 7], "haggle": 0.0, "cut": 1.0, "dig": 5, "dig_label": "Refresh the auctions",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 3, "bin": true, "list": [0.7, 1.6], "fee": 0.13,
		"color": Color("d9a43a"),
	},
	# ------------------------------------------------ rare books (market "books")
	{
		"id": "estatelib", "name": "Estate Library", "slot": "hunt", "unlock": 1, "market": "books",
		"blurb": "A late professor's house, books to the ceiling and heirs who price them by the yard. Check behind the front row.",
		"time": 4, "stock": 6, "price": [0.2, 0.85], "exact": false, "tier_boost": 0,
		"cond": [18, 40, 28, 11, 3], "haggle": 0.65, "cut": 0.7, "dig": 2, "dig_label": "Check behind the front row",
		"sell": 0.0, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("9a6a32"),
	},
	{
		"id": "booksale", "name": "Library Book Sale", "slot": "hunt", "unlock": 1, "market": "books",
		"blurb": "The Friends of the Library sale in the church hall: hardbacks a dollar, bag day at four. Dealers with phone scanners at the door.",
		"time": 4, "stock": 6, "price": [0.25, 0.9], "exact": false, "tier_boost": 0,
		"cond": [25, 42, 24, 7, 2], "haggle": 0.5, "cut": 0.75, "dig": 2, "dig_label": "Dig under the tables",
		"sell": 0.65, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("5a9a4a"),
	},
	{
		"id": "bookshop", "name": "Foxed & Folio", "slot": "shop", "unlock": 1, "market": "books",
		"blurb": "An antiquarian bookshop: rolling ladders, a glass case of firsts and a bookseller who sends books out for a proper description.",
		"time": 3, "stock": 6, "price": [1.0, 1.2], "exact": true, "tier_boost": 1,
		"cond": [0, 20, 45, 25, 10], "haggle": 0.35, "cut": 0.85, "dig": 1, "dig_label": "Ask about the locked case",
		"sell": 0.6, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true, "bargain": 2,
		"color": Color("8a3a48"),
	},
	{
		"id": "bookauction", "name": "Sothebids", "slot": "online", "unlock": 1, "market": "books",
		"blurb": "Fine books and manuscripts: catalogued lots, phone bidders, a hammer and a buyer's premium.",
		"time": 4, "stock": 5, "price": [0.95, 1.25], "exact": true, "tier_boost": 1,
		"cond": [5, 28, 40, 19, 8], "haggle": 0.0, "cut": 1.0, "dig": 5, "dig_label": "Turn the catalogue page",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 3, "bin": true, "list": [0.7, 1.6], "fee": 0.13,
		"color": Color("3a7a9a"),
	},
	# ------------------------------------------------ vinyl records (market "vinyl")
	{
		"id": "basementcrates", "name": "Basement Clear-Out", "slot": "hunt", "unlock": 1, "market": "vinyl",
		"blurb": "A late DJ's basement, crates to the rafters and a nephew who wants them gone by Sunday. Flip every crate.",
		"time": 4, "stock": 6, "price": [0.2, 0.85], "exact": false, "tier_boost": 0,
		"cond": [18, 40, 28, 11, 3], "haggle": 0.65, "cut": 0.7, "dig": 2, "dig_label": "Flip another crate",
		"sell": 0.0, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("9a5a3a"),
	},
	{
		"id": "recordfair", "name": "Record Fair", "slot": "hunt", "unlock": 1, "market": "vinyl",
		"blurb": "Trestle tables in a leisure centre, a hundred dealers and their dollar bins. The early birds have torches.",
		"time": 4, "stock": 6, "price": [0.25, 0.9], "exact": false, "tier_boost": 0,
		"cond": [22, 42, 25, 9, 2], "haggle": 0.5, "cut": 0.75, "dig": 2, "dig_label": "Dig the dollar bins",
		"sell": 0.65, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("e08a2a"),
	},
	{
		"id": "recordshop", "name": "Needle Drop Records", "slot": "shop", "unlock": 1, "market": "vinyl",
		"blurb": "A record shop: a wall of sleeves, a listening deck and an owner who sends the good stuff out to be graded.",
		"time": 3, "stock": 6, "price": [1.0, 1.2], "exact": true, "tier_boost": 1,
		"cond": [0, 20, 45, 25, 10], "haggle": 0.35, "cut": 0.85, "dig": 1, "dig_label": "Ask what's behind the counter",
		"sell": 0.6, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true, "bargain": 2,
		"color": Color("d94f8a"),
	},
	{
		"id": "diskogz", "name": "Diskogz", "slot": "online", "unlock": 1, "market": "vinyl",
		"blurb": "The record collectors' marketplace: matrix numbers, grading arguments and auctions that end at 3 a.m.",
		"time": 4, "stock": 5, "price": [0.95, 1.25], "exact": true, "tier_boost": 1,
		"cond": [5, 28, 40, 19, 8], "haggle": 0.0, "cut": 1.0, "dig": 5, "dig_label": "Load more listings",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 3, "bin": true, "list": [0.7, 1.6], "fee": 0.13,
		"color": Color("3a6ad9"),
	},
	# ------------------------------------------------ rare coins (market "coins")
	{
		"id": "coinshow", "name": "Coin Show", "slot": "hunt", "unlock": 1, "market": "coins",
		"blurb": "The bourse floor: rows of dealers, loupes, and trays of 2x2 flips.",
		"time": 4, "stock": 6, "price": [0.35, 1.0], "exact": false, "tier_boost": 1,
		"cond": [10, 45, 30, 12, 3], "haggle": 0.55, "cut": 0.75, "dig": 2, "dig_label": "Search a junk tray",
		"sell": 0.75, "lots": 1, "lot_size": 4, "lot_peek": 1,
		"color": Color("e8b923"),
	},
	{
		"id": "beach", "name": "Metal Detecting", "slot": "hunt", "unlock": 1, "market": "coins",
		"blurb": "A beach at dawn and a beeping detector. Mostly bottle caps. Mostly.",
		"time": 5, "stock": 4, "price": [0.05, 0.4], "exact": false, "tier_boost": 1,
		"cond": [45, 45, 8, 2, 0], "haggle": 0.0, "cut": 1.0, "dig": 3, "dig_label": "Swing the detector",
		"sell": 0.0, "lots": 1, "lot_size": 3, "lot_peek": 1,
		"color": Color("5fc4d9"),
	},
	{
		"id": "coinshop", "name": "Coin & Bullion", "slot": "shop", "unlock": 1, "market": "coins",
		"blurb": "A vault door, a scale, slabs in a case. Grades your coins and buys near full price.",
		"time": 3, "stock": 6, "price": [1.0, 1.15], "exact": true, "tier_boost": 1,
		"cond": [0, 25, 40, 25, 10], "haggle": 0.3, "cut": 0.88, "dig": 1, "dig_label": "Ask about the safe",
		"sell": 0.8, "lots": 0, "lot_size": 0, "lot_peek": 0, "grading": true, "bargain": 2,
		"color": Color("c9a227"),
	},
	{
		"id": "coinauction", "name": "Stax & Towers", "slot": "online", "unlock": 1, "market": "coins",
		"blurb": "The great coin auction house. Pedigreed rarities, live bidding, a 20% fee.",
		"time": 3, "stock": 3, "price": [1.0, 1.15], "exact": true, "tier_boost": 2,
		"cond": [0, 10, 35, 35, 20], "haggle": 0.0, "cut": 1.0, "dig": 0, "dig_label": "",
		"sell": 0.0, "lots": 0, "lot_size": 0, "lot_peek": 0,
		"auctions": 4, "bin": true, "list": [0.9, 1.8], "fee": 0.2,
		"color": Color("b0303a"),
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


## Venues open for a slot at this ante in this market, newest unlock last.
static func unlocked(slot: String, ante: int, market: String = "games") -> Array:
	var out: Array = []
	for d in LIST:
		if d["slot"] == slot and int(d["unlock"]) <= ante and String(d.get("market", "games")) == market:
			out.append(d)
	return out


static func market(id: String) -> String:
	return String(get_def(id).get("market", "games"))
