extends RefCounted
## Collector's Curse: the ten collecting worlds (no class_name: preload it).
## Each world is one hobby with its own items (platforms in Catalog with
## "market": id), venues ("market" in venues.gd), condition words, lore and an
## intro. Each one belongs to a collector the Buyer sealed in the vault: that
## collector is the world's ESTATE (unlocks.gd). Free the collector (win a run)
## and their world opens. Retro and trading cards are open from the start.
##
## id = the market id used everywhere (run.market, venues, catalog platforms).
## built = has items and venues; an unbuilt world shows as COMING SOON.
## intro = the Stage scene its first-visit intro flies through.
## pivot = [headline, pitch] for the mid-run flip offer.
## target = opening a run in this world scales that whole run's appraisal
## targets (richer worlds play easier early); tuned with tools/tune_worlds.gd
## so a plain opening wins about as often as retro for the greedy bot.

const LIST := [
	{"id": "games", "name": "Retro Games", "short": "GAMES", "color": Color("ffcc33"), "estate": "arlo", "built": true,
		"intro": "title", "music": "title",
		"pivot": ["THE RETRO GAME SCENE", "Carts, discs and big-box PC games. Garage sales, game stores and eBuy auctions."],
		"blurb": "Carts, discs, consoles. Where Arlo's curse began."},
	{"id": "cards", "name": "Trading Cards", "short": "CARDS", "color": Color("f2c230"), "estate": "twins", "target": 1.45, "built": true,
		"intro": "cardshop", "music": "shop",
		"pivot": ["THE CARD SHOPS", "Word is the card shops are booming: singles, slabs, sealed boxes you can rip open."],
		"blurb": "Critters, wizards and duelists. Rip packs, grade the hits."},
	{"id": "sports", "name": "Sports Cards", "short": "SPORTS", "color": Color("3fae5a"), "estate": "rose", "target": 1.5, "built": true,
		"intro": "ballroom", "music": "sports",
		"pivot": ["THE SPORTS CARD SHOWS", "Rookies, wax boxes and slabbed legends. The hotel ballrooms are packed every weekend."],
		"blurb": "Rookies, wax and slabbed legends. Grandma Rose's world."},
	{"id": "vinyl", "name": "Vinyl Records", "short": "VINYL", "color": Color("d94f8a"), "estate": "marv", "built": false,
		"intro": "", "music": "",
		"pivot": ["THE RECORD STORES", "First pressings, test pressings, basement crates nobody has flipped through in years."],
		"blurb": "First pressings and crate digs. The night DJ's world."},
	{"id": "comics", "name": "Comics", "short": "COMICS", "color": Color("e04a3a"), "estate": "hector", "built": false,
		"intro": "", "music": "",
		"pivot": ["THE BACK-ISSUE BINS", "Key issues, first appearances, longboxes in every attic."],
		"blurb": "Key issues and longboxes. Uncle Hector's world."},
	{"id": "coins", "name": "Rare Coins", "short": "COINS", "color": Color("e8b923"), "estate": "june", "target": 1.4, "built": true,
		"intro": "coinshop", "music": "shop",
		"pivot": ["THE RARE COIN TRADE", "Real money. Coin shows, dealers with vault doors, auction houses that sell pennies for millions."],
		"blurb": "Pennies, silver and gold. Aunt June's world."},
	{"id": "watches", "name": "Watches & Clocks", "short": "WATCHES", "color": Color("8fb3c9"), "estate": "elsa", "built": false,
		"intro": "", "music": "",
		"pivot": ["THE WATCH DEALERS", "Divers, chronographs and grandfather clocks. Everything ticks, some of it lies."],
		"blurb": "Movements and dials. The watchmaker's world."},
	{"id": "pop", "name": "Pop Culture", "short": "POP", "color": Color("ff8a3d"), "estate": "dale", "built": false,
		"intro": "", "music": "",
		"pivot": ["THE PROP HOUSES", "Carded figures, movie props and one-sheet posters."],
		"blurb": "Toys, props and posters. Cousin Dale's world."},
	{"id": "books", "name": "Rare Books", "short": "BOOKS", "color": Color("a8703a"), "estate": "iris", "built": false,
		"intro": "", "music": "",
		"pivot": ["THE ANTIQUARIAN TRADE", "First editions, signed copies, a reading room that smells of a hundred years."],
		"blurb": "First editions and signed copies. The professor's world."},
	{"id": "art", "name": "The Gallery", "short": "GALLERY", "color": Color("c9a2ff"), "estate": "buyer", "built": false,
		"intro": "", "music": "",
		"pivot": ["THE GALLERY", "The Buyer's own collection. The last painting is wrapped in plastic."],
		"blurb": "The Buyer's own collection. The finale."},
]

## Worlds a run can deal in when nobody says otherwise (tests, sims): the
## three that existed before the expansion.
const DEFAULT_OPEN := ["games", "cards", "coins"]

static var _by_id: Dictionary = {}


static func get_def(id: String) -> Dictionary:
	if _by_id.is_empty():
		for w in LIST:
			_by_id[String(w["id"])] = w
	return _by_id.get(id, {})


static func index_of(id: String) -> int:
	for i in LIST.size():
		if String(LIST[i]["id"]) == id:
			return i
	return 0


static func is_built(id: String) -> bool:
	return bool(get_def(id).get("built", false))


## Every world id in unlock order.
static func ids() -> Array:
	var out: Array = []
	for w in LIST:
		out.append(String(w["id"]))
	return out


## The world whose collector is this estate ("" = none).
static func of_estate(estate_id: String) -> String:
	for w in LIST:
		if String(w["estate"]) == estate_id:
			return String(w["id"])
	return ""
