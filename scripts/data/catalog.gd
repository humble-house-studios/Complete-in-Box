class_name Catalog
extends RefCounted
## Everything you can find, buy, flip and hoard. Parody names on purpose, so the
## game can ship without licensing real brands.
##
## ITEMS = the hand-made items below (HANDMADE) + the generated one-to-one
## parody of the top 500 games and top 250 consoles/accessories
## (catalog_items.gd, built by tools/gen_catalog.py from docs/research/).
## Every item also carries card data: rank, year, publisher, genre, blurb,
## rating and print run. Each copy you find rolls a VARIANT (see VARIANTS).
##
## base = what a LOOSE copy is worth in an average market. Condition, grading,
## trends and how long you've held it all multiply that (see Market).
## tier: 0 common, 1 uncommon, 2 rare, 3 grail.
## kind: game / console / acc (accessory) / misc (no platform set).

const PLATFORMS := {
	"FES": {"name": "Funtendo FES", "short": "FES", "color": Color("d64545"), "family": "funtendo"},
	"FCUBE": {"name": "Funtendo FunCube", "short": "CUBE", "color": Color("7a5cc7"), "family": "funtendo"},
	"PBA": {"name": "PocketBoy Advance", "short": "PBA", "color": Color("5c6ad9"), "family": "funtendo"},
	"DUO": {"name": "Funtendo Duo", "short": "DUO", "color": Color("9aa3b5"), "family": "funtendo"},
	"PST2": {"name": "PlayStatia 2", "short": "PST2", "color": Color("3b5fc4"), "family": "statia"},
	"PSPK": {"name": "PlayStatia Pocket", "short": "PSPK", "color": Color("6b6b7a"), "family": "statia"},
	"XBX": {"name": "Microsloth Xbux", "short": "XBUX", "color": Color("4caf50"), "family": "xbux"},
	"SAT": {"name": "Saga Saturnine", "short": "SAT", "color": Color("7d8296"), "family": "saga"},
	"NEO": {"name": "Neon Geo", "short": "NEO", "color": Color("e0b13a"), "family": "snc"},
	"ODD": {"name": "Oddware", "short": "ODD", "color": Color("c0568a"), "family": "odd"},
	"SFES": {"name": "Super FES", "short": "SFES", "color": Color("8a5cd6"), "family": "funtendo"},
	"F64": {"name": "Funtendo 64", "short": "F64", "color": Color("3aa856"), "family": "funtendo"},
	"PBOY": {"name": "PocketBoy", "short": "PBOY", "color": Color("9bad3c"), "family": "funtendo"},
	"GEN": {"name": "Saga Genesys", "short": "GEN", "color": Color("3a6fd6"), "family": "saga"},
	"DC": {"name": "Saga Dreamcaster", "short": "DC", "color": Color("e8892e"), "family": "saga"},
	"PST": {"name": "PlayStatia", "short": "PST", "color": Color("8c96a8"), "family": "statia"},
	"A26": {"name": "Ataro 2600", "short": "A26", "color": Color("a8703a"), "family": "ataro"},
	"MISC": {"name": "Memorabilia", "short": "MISC", "color": Color("c9a227"), "family": "misc"},
	# Trading cards (the card-shop market, from ante 5 if you flip into it).
	"CRIT": {"name": "Pocket Critters TCG", "short": "CRIT", "color": Color("f2c230"), "family": "critco", "market": "cards"},
	"MAGI": {"name": "Magick: The Gatherening", "short": "MAGI", "color": Color("b5683a"), "family": "lizards", "market": "cards"},
	"YUGI": {"name": "Yu-Gi-Whoa!", "short": "YUGI", "color": Color("9a4fd6"), "family": "konamo", "market": "cards"},
	"ALT": {"name": "Other TCGs", "short": "ALT", "color": Color("3fb3a8"), "family": "tcg", "market": "cards"},
	# Rare coins (the coin market, from ante 7 if you flip into it).
	"CENT": {"name": "Copper & Nickel", "short": "CENT", "color": Color("c8743c"), "family": "usmint", "market": "coins"},
	"SILV": {"name": "US Silver", "short": "SILV", "color": Color("b9c3d1"), "family": "usmint", "market": "coins"},
	"GOLD": {"name": "US Gold", "short": "GOLD", "color": Color("e8b923"), "family": "usmint", "market": "coins"},
	"WRLD": {"name": "World Coins", "short": "WRLD", "color": Color("4f9ad9"), "family": "world", "market": "coins"},
	"ANCT": {"name": "Ancient Coins", "short": "ANCT", "color": Color("8f7a4a"), "family": "ancient", "market": "coins"},
	# Sports cards (Grandma Rose's world): one binder page per sport.
	"BASE": {"name": "Baseball", "short": "BASE", "color": Color("d64545"), "family": "sport", "market": "sports"},
	"HOOP": {"name": "Basketball", "short": "HOOP", "color": Color("e8892e"), "family": "sport", "market": "sports"},
	"GRID": {"name": "Football", "short": "GRID", "color": Color("6b4a2a"), "family": "sport", "market": "sports"},
	"PUCK": {"name": "Hockey", "short": "PUCK", "color": Color("4f9ad9"), "family": "sport", "market": "sports"},
	"FUTB": {"name": "Soccer & More", "short": "FUTB", "color": Color("3fae5a"), "family": "sport", "market": "sports"},
	# Comics (Uncle Hector's world): one binder page per era.
	"GLDN": {"name": "Golden Age", "short": "GOLDEN", "color": Color("d9a43a"), "family": "comics", "market": "comics"},
	"SLVR": {"name": "Silver Age", "short": "SILVER", "color": Color("8fa3c4"), "family": "comics", "market": "comics"},
	"BRNZ": {"name": "Bronze Age", "short": "BRONZE", "color": Color("b8743a"), "family": "comics", "market": "comics"},
	"MODN": {"name": "Modern Age", "short": "MODERN", "color": Color("d04a6a"), "family": "comics", "market": "comics"},
	"INDY": {"name": "Indie, Manga & Underground", "short": "INDIE", "color": Color("5abf8a"), "family": "indy", "market": "comics"},
	# Rare books (Professor Iris's world): one binder page per shelf of the library.
	"ANTQ": {"name": "Antiquarian", "short": "ANTIQ", "color": Color("9a6a32"), "family": "books", "market": "books"},
	"CLSC": {"name": "19th-Century Classics", "short": "CLASSIC", "color": Color("8a3a48"), "family": "books", "market": "books"},
	"MODF": {"name": "Modern Firsts", "short": "FIRSTS", "color": Color("3a7a9a"), "family": "books", "market": "books"},
	"GENR": {"name": "Genre Firsts", "short": "GENRE", "color": Color("5a9a4a"), "family": "books", "market": "books"},
	"KIDS": {"name": "Children's & Illustrated", "short": "KIDS", "color": Color("e0a838"), "family": "books", "market": "books"},
	# Vinyl records (Midnight Marv's world): one binder page per crate.
	"ROCK": {"name": "Rock & Pop", "short": "ROCK", "color": Color("d9493a"), "family": "vinyl", "market": "vinyl"},
	"JAZZ": {"name": "Jazz & Blues", "short": "JAZZ", "color": Color("3a6ad9"), "family": "vinyl", "market": "vinyl"},
	"SOUL": {"name": "Soul & Funk", "short": "SOUL", "color": Color("e08a2a"), "family": "vinyl", "market": "vinyl"},
	"PUNK": {"name": "Punk, Indie & Metal", "short": "PUNK", "color": Color("d94f8a"), "family": "vinyl", "market": "vinyl"},
	"HIPH": {"name": "Hip-Hop & Dance", "short": "HIP-HOP", "color": Color("8a5ad9"), "family": "vinyl", "market": "vinyl"},
}

## What the run deals in: one market per collecting world (worlds.gd).
## Every platform belongs to one (games unless it says).
const Worlds := preload("res://scripts/data/worlds.gd")
static var MARKETS: Dictionary = _build_markets()


static func _build_markets() -> Dictionary:
	var out := {}
	for w in Worlds.LIST:
		out[String(w["id"])] = {"name": w["name"], "short": w["short"], "color": w["color"]}
	return out


## Kinds per market: games use game/console/acc/misc, cards card/pack, coins coin.
const CC_KINDS := ["card", "pack", "coin", "scard", "wax", "comic", "longbox", "book", "booklot", "record", "crate"]
## Variants that count as "shiny" (Shiny Hunter, the want list).
const SHINY := ["Holo Foil", "Reverse Holo", "1st Edition", "Shadowless", "Proof-Like", "Deep Cameo", "Rainbow Toned", "Refractor", "Gold Parallel", "Tiffany", "Foil Cover", "Virgin Cover", "Fine Binding", "Limited Edition", "Colored Vinyl", "Picture Disc"]
const CC := preload("res://scripts/data/catalog_cc.gd")
const SPORTS := preload("res://scripts/data/catalog_sports.gd")
const COMICS := preload("res://scripts/data/catalog_comics.gd")
const BOOKS := preload("res://scripts/data/catalog_books.gd")
const VINYL := preload("res://scripts/data/catalog_vinyl.gd")

const TIER_NAMES := ["Common", "Uncommon", "Rare", "GRAIL"]
const TIER_COLORS := [Color("b8b8b8"), Color("5ec46a"), Color("4fa3ff"), Color("ffcc33")]

const HANDMADE := [
	# ---------------------------------------------------------------- Funtendo FES
	{"id": "fes_plumber", "name": "Super Plumber Bros.", "plat": "FES", "kind": "game", "tier": 0, "base": 6, "tags": []},
	{"id": "fes_duck", "name": "Duck Blaster", "plat": "FES", "kind": "game", "tier": 0, "base": 4, "tags": []},
	{"id": "fes_tetro", "name": "Tetrominoes", "plat": "FES", "kind": "game", "tier": 0, "base": 8, "tags": []},
	{"id": "fes_zeldo", "name": "Legend of Zeldo", "plat": "FES", "kind": "game", "tier": 1, "base": 28, "tags": []},
	{"id": "fes_robo2", "name": "Mega Robo Man 2", "plat": "FES", "kind": "game", "tier": 1, "base": 34, "tags": []},
	{"id": "fes_vein3", "name": "Castlevein III", "plat": "FES", "kind": "game", "tier": 1, "base": 40, "tags": []},
	{"id": "fes_samsin", "name": "Lil' Samsin", "plat": "FES", "kind": "game", "tier": 2, "base": 260, "tags": []},
	{"id": "fes_stadium", "name": "Stadium Happenings", "plat": "FES", "kind": "game", "tier": 3, "base": 1400, "tags": []},
	{"id": "fes_wcup", "name": "Funtendo World Cup Cart", "plat": "FES", "kind": "game", "tier": 3, "base": 2600, "tags": []},
	{"id": "fes_console", "name": "FES Console", "plat": "FES", "kind": "console", "tier": 1, "base": 45, "tags": []},
	{"id": "fes_zapper", "name": "FES Zapper Gun", "plat": "FES", "kind": "acc", "tier": 0, "base": 7, "tags": []},
	{"id": "fes_mitt", "name": "Power Mitt", "plat": "FES", "kind": "acc", "tier": 1, "base": 30, "tags": ["fad"]},
	# ---------------------------------------------------------------- Super FES
	{"id": "sfes_world", "name": "Super Plumber World", "plat": "SFES", "kind": "game", "tier": 0, "base": 12, "tags": []},
	{"id": "sfes_kongo", "name": "Donkey Kongo Country", "plat": "SFES", "kind": "game", "tier": 0, "base": 10, "tags": []},
	{"id": "sfes_metrood", "name": "Super Metrood", "plat": "SFES", "kind": "game", "tier": 1, "base": 38, "tags": []},
	{"id": "sfes_chrono", "name": "Chrono Triggered", "plat": "SFES", "kind": "game", "tier": 1, "base": 55, "tags": []},
	{"id": "sfes_fantasia", "name": "Final Fantasia III", "plat": "SFES", "kind": "game", "tier": 1, "base": 42, "tags": []},
	{"id": "sfes_earthbond", "name": "EarthBond", "plat": "SFES", "kind": "game", "tier": 2, "base": 140, "tags": []},
	{"id": "sfes_ninja", "name": "Steel Ninja Hagan", "plat": "SFES", "kind": "game", "tier": 2, "base": 220, "tags": []},
	{"id": "sfes_console", "name": "Super FES Console", "plat": "SFES", "kind": "console", "tier": 1, "base": 60, "tags": []},
	{"id": "sfes_pad", "name": "Super FES Controller", "plat": "SFES", "kind": "acc", "tier": 0, "base": 9, "tags": []},
	{"id": "sfes_bazooka", "name": "Super Bazooka", "plat": "SFES", "kind": "acc", "tier": 1, "base": 25, "tags": []},
	# ---------------------------------------------------------------- Funtendo 64
	{"id": "f64_plumber", "name": "Plumber 64", "plat": "F64", "kind": "game", "tier": 0, "base": 14, "tags": []},
	{"id": "f64_spy", "name": "GoldenSpy 00Heaven", "plat": "F64", "kind": "game", "tier": 0, "base": 11, "tags": []},
	{"id": "f64_thyme", "name": "Ocarina of Thyme", "plat": "F64", "kind": "game", "tier": 0, "base": 16, "tags": []},
	{"id": "f64_kablooie", "name": "Banjo-Kablooie", "plat": "F64", "kind": "game", "tier": 0, "base": 13, "tags": []},
	{"id": "f64_conker", "name": "Conker's Bad Fur Week", "plat": "F64", "kind": "game", "tier": 1, "base": 60, "tags": []},
	{"id": "f64_party3", "name": "Plumber Party 3", "plat": "F64", "kind": "game", "tier": 2, "base": 110, "tags": []},
	{"id": "f64_console", "name": "F64 Console", "plat": "F64", "kind": "console", "tier": 1, "base": 50, "tags": []},
	{"id": "f64_jungle", "name": "F64 Clear Jungle Green", "plat": "F64", "kind": "console", "tier": 2, "base": 150, "tags": []},
	{"id": "f64_pad", "name": "F64 Controller", "plat": "F64", "kind": "acc", "tier": 0, "base": 10, "tags": []},
	{"id": "f64_rumble", "name": "Rumble Brick", "plat": "F64", "kind": "acc", "tier": 0, "base": 5, "tags": []},
	# ---------------------------------------------------------------- PocketBoy
	{"id": "pboy_tetro", "name": "Tetrominoes Pocket", "plat": "PBOY", "kind": "game", "tier": 0, "base": 5, "tags": []},
	{"id": "pboy_critred", "name": "Pocket Critters Red", "plat": "PBOY", "kind": "game", "tier": 1, "base": 35, "tags": []},
	{"id": "pboy_wakening", "name": "Link's Wakening", "plat": "PBOY", "kind": "game", "tier": 1, "base": 24, "tags": []},
	{"id": "pboy_crystal", "name": "Pocket Critters Crystal", "plat": "PBOY", "kind": "game", "tier": 2, "base": 95, "tags": []},
	{"id": "pboy_dmg", "name": "PocketBoy Brick", "plat": "PBOY", "kind": "console", "tier": 1, "base": 40, "tags": []},
	{"id": "pboy_gold", "name": "PocketBoy Light Gold", "plat": "PBOY", "kind": "console", "tier": 2, "base": 240, "tags": []},
	{"id": "pboy_camera", "name": "PocketBoy Camera", "plat": "PBOY", "kind": "acc", "tier": 1, "base": 22, "tags": []},
	{"id": "pboy_link", "name": "Link Cable", "plat": "PBOY", "kind": "acc", "tier": 0, "base": 4, "tags": []},
	# ---------------------------------------------------------------- Saga Genesys
	{"id": "gen_sonik", "name": "Sonik the Hedgehog", "plat": "GEN", "kind": "game", "tier": 0, "base": 6, "tags": []},
	{"id": "gen_kumbat", "name": "Mortal Kumbat", "plat": "GEN", "kind": "game", "tier": 0, "base": 7, "tags": []},
	{"id": "gen_wrath2", "name": "Streets of Wrath 2", "plat": "GEN", "kind": "game", "tier": 1, "base": 30, "tags": []},
	{"id": "gen_starr", "name": "Phantasy Starr IV", "plat": "GEN", "kind": "game", "tier": 2, "base": 120, "tags": []},
	{"id": "gen_zapman", "name": "Zapman", "plat": "GEN", "kind": "game", "tier": 2, "base": 180, "tags": []},
	{"id": "gen_console", "name": "Genesys Model 1", "plat": "GEN", "kind": "console", "tier": 1, "base": 40, "tags": []},
	{"id": "gen_pad6", "name": "Genesys 6-Button Pad", "plat": "GEN", "kind": "acc", "tier": 0, "base": 8, "tags": []},
	# ---------------------------------------------------------------- Saga Dreamcaster
	{"id": "dc_adventure", "name": "Sonik Adventure", "plat": "DC", "kind": "game", "tier": 0, "base": 12, "tags": ["disc"]},
	{"id": "dc_shenmoo", "name": "Shenmoo", "plat": "DC", "kind": "game", "tier": 1, "base": 28, "tags": ["disc"]},
	{"id": "dc_jetset", "name": "Jet Set Radiant", "plat": "DC", "kind": "game", "tier": 1, "base": 36, "tags": ["disc"]},
	{"id": "dc_rock2", "name": "Power Rock 2", "plat": "DC", "kind": "game", "tier": 2, "base": 130, "tags": ["disc"]},
	{"id": "dc_ikaruka", "name": "Ikaruka", "plat": "DC", "kind": "game", "tier": 2, "base": 190, "tags": ["disc"]},
	{"id": "dc_console", "name": "Dreamcaster Console", "plat": "DC", "kind": "console", "tier": 1, "base": 55, "tags": []},
	{"id": "dc_vmd", "name": "Visual Memory Doohickey", "plat": "DC", "kind": "acc", "tier": 0, "base": 9, "tags": []},
	# ---------------------------------------------------------------- PlayStatia
	{"id": "pst_crash", "name": "Crash Bandicute", "plat": "PST", "kind": "game", "tier": 0, "base": 8, "tags": ["disc"]},
	{"id": "pst_ff7", "name": "Final Fantasia VII", "plat": "PST", "kind": "game", "tier": 0, "base": 14, "tags": ["disc"]},
	{"id": "pst_sneaky", "name": "Metal Gear Sneaky", "plat": "PST", "kind": "game", "tier": 0, "base": 12, "tags": ["disc"]},
	{"id": "pst_sotn", "name": "Castlevein: Night Symphony", "plat": "PST", "kind": "game", "tier": 1, "base": 45, "tags": ["disc"]},
	{"id": "pst_suiko2", "name": "Suiko Saga II", "plat": "PST", "kind": "game", "tier": 2, "base": 150, "tags": ["disc"]},
	{"id": "pst_tombo", "name": "Tombo!", "plat": "PST", "kind": "game", "tier": 2, "base": 90, "tags": ["disc"]},
	{"id": "pst_console", "name": "PlayStatia Console", "plat": "PST", "kind": "console", "tier": 0, "base": 25, "tags": []},
	{"id": "pst_memcard", "name": "Memory Card", "plat": "PST", "kind": "acc", "tier": 0, "base": 4, "tags": []},
	{"id": "pst_dualpad", "name": "Dual Rumble Pad", "plat": "PST", "kind": "acc", "tier": 0, "base": 9, "tags": []},
	# ---------------------------------------------------------------- Ataro 2600
	{"id": "a26_et", "name": "Extra-Terrible", "plat": "A26", "kind": "game", "tier": 0, "base": 5, "tags": ["fad"]},
	{"id": "a26_muncher", "name": "Pak-Muncher", "plat": "A26", "kind": "game", "tier": 0, "base": 3, "tags": []},
	{"id": "a26_pitfell", "name": "Pitfell!", "plat": "A26", "kind": "game", "tier": 0, "base": 6, "tags": []},
	{"id": "a26_skyraid", "name": "Sky Raid", "plat": "A26", "kind": "game", "tier": 3, "base": 1800, "tags": []},
	{"id": "a26_console", "name": "Ataro 2600 Woodgrain", "plat": "A26", "kind": "console", "tier": 1, "base": 45, "tags": []},
	{"id": "a26_paddle", "name": "Paddle Controllers", "plat": "A26", "kind": "acc", "tier": 0, "base": 6, "tags": []},
	# ---------------------------------------------------------------- Memorabilia
	{"id": "misc_guide", "name": "Strategy Guide", "plat": "MISC", "kind": "misc", "tier": 0, "base": 6, "tags": []},
	{"id": "misc_mag1", "name": "Funtendo Power #1", "plat": "MISC", "kind": "misc", "tier": 2, "base": 85, "tags": []},
	{"id": "misc_pogs", "name": "Slammer Caps Tube", "plat": "MISC", "kind": "misc", "tier": 0, "base": 3, "tags": ["fad"]},
	{"id": "misc_kiosk", "name": "Store Demo Kiosk", "plat": "MISC", "kind": "misc", "tier": 3, "base": 1200, "tags": []},
	{"id": "misc_proto", "name": "Funtendo PlayStatia Prototype", "plat": "MISC", "kind": "misc", "tier": 3, "base": 4000, "tags": []},
]

## Condition ladder, worst to best. mult multiplies an item's loose value.
const CONDITIONS := ["Damaged", "Loose", "CIB", "Mint", "Sealed"]
const COND_MULT := {"Damaged": 0.4, "Loose": 1.0, "CIB": 2.2, "Mint": 3.5, "Sealed": 7.0}
const COND_SHORT := {"Damaged": "DMG", "Loose": "LOOSE", "CIB": "CIB", "Mint": "MINT", "Sealed": "SEALED"}
const COND_COLORS := {"Damaged": Color("b04a4a"), "Loose": Color("9a9a9a"), "CIB": Color("4fa3ff"), "Mint": Color("5ee0b0"), "Sealed": Color("ffcc33")}
## The same five steps in each hobby's own words: [full name, short tag].
const COND_WORDS := {
	"card": {"Damaged": ["Creased", "CREASED"], "Loose": ["Played", "PLAYED"], "CIB": ["Near Mint", "NM"], "Mint": ["Gem Mint", "GEM"], "Sealed": ["Pack Fresh", "FRESH"]},
	"pack": {"Damaged": ["Crushed", "CRUSHED"], "Loose": ["Shelf Worn", "WORN"], "CIB": ["Sealed", "SEALED"], "Mint": ["Factory Sealed", "FACTORY"], "Sealed": ["Case Fresh", "CASE"]},
	"scard": {"Damaged": ["Creased", "CREASED"], "Loose": ["Very Good", "VG"], "CIB": ["Near Mint", "NM"], "Mint": ["Mint", "MINT"], "Sealed": ["Gem Mint", "GEM"]},
	"wax": {"Damaged": ["Torn Wax", "TORN"], "Loose": ["Shelf Worn", "WORN"], "CIB": ["Sealed Wax", "SEALED"], "Mint": ["BBCX Wrapped", "WRAPPED"], "Sealed": ["Case Fresh", "CASE"]},
	"comic": {"Damaged": ["Poor", "PR"], "Loose": ["Fine", "FN"], "CIB": ["Very Fine", "VF"], "Mint": ["Near Mint", "NM"], "Sealed": ["Mint", "MT"]},
	"longbox": {"Damaged": ["Water Damaged", "WET"], "Loose": ["Picked Over", "PICKED"], "CIB": ["Unsorted", "UNSORTED"], "Mint": ["Bagged & Boarded", "B&B"], "Sealed": ["Warehouse Find", "WAREHOUSE"]},
	"book": {"Damaged": ["Reading Copy", "READING"], "Loose": ["Good", "G"], "CIB": ["Very Good", "VG"], "Mint": ["Near Fine", "NF"], "Sealed": ["Fine", "F"]},
	"record": {"Damaged": ["Poor", "P"], "Loose": ["Very Good", "VG"], "CIB": ["Very Good Plus", "VG+"], "Mint": ["Near Mint", "NM"], "Sealed": ["Still Sealed", "SEALED"]},
	"crate": {"Damaged": ["Warped", "WARPED"], "Loose": ["Picked Over", "PICKED"], "CIB": ["Unflipped", "UNFLIPPED"], "Mint": ["DJ Stash", "STASH"], "Sealed": ["Dead Stock", "DEADSTOCK"]},
	"booklot": {"Damaged": ["Mildewed", "MILDEW"], "Loose": ["Picked Over", "PICKED"], "CIB": ["Uncatalogued", "UNSORTED"], "Mint": ["Library Clearance", "CLEARANCE"], "Sealed": ["Sealed Estate", "ESTATE"]},
	"coin": {"Damaged": ["Holed", "HOLED"], "Loose": ["Circulated", "CIRC"], "CIB": ["About Unc", "AU"], "Mint": ["Mint State", "MS"], "Sealed": ["Proof", "PROOF"]},
}

## Variants a copy can roll. mult = value multiplier, w = roll weight,
## kinds = which item kinds can get it. See variant_label() for family names.
const VARIANTS := {
	"Standard": {"mult": 1.0, "w": 70.0, "kinds": ["game", "console", "acc", "misc", "card", "pack", "coin", "scard", "wax", "comic", "longbox", "book", "booklot", "record", "crate"], "color": Color("9a93ab"), "desc": "The regular retail release."},
	"Player's Pick": {"mult": 0.8, "w": 9.0, "kinds": ["game"], "color": Color("e6d34a"), "desc": "Budget re-release with the coloured banner. Collectors shrug."},
	"Black Label": {"mult": 1.25, "w": 7.0, "kinds": ["game"], "color": Color("2b2b2b"), "desc": "Original print, before the budget re-releases."},
	"First Print": {"mult": 1.6, "w": 5.0, "kinds": ["game"], "color": Color("4fa3ff"), "desc": "From the very first production run."},
	"Japan Import": {"mult": 0.9, "w": 6.0, "kinds": ["game", "console", "card", "pack"], "color": Color("ff6b6b"), "desc": "Japanese release. Different art, same game."},
	"Rental Copy": {"mult": 0.6, "w": 4.0, "kinds": ["game"], "color": Color("3a6fd6"), "desc": "Blockbluster Video sticker on the front. Well loved."},
	"Collector's Edition": {"mult": 2.2, "w": 1.2, "kinds": ["game"], "color": Color("d4af37"), "desc": "Big box, art book, pin. The works."},
	"Signed by Dev": {"mult": 2.4, "w": 0.6, "kinds": ["game"], "color": Color("ff8a3d"), "desc": "Signed in silver marker by someone who made it."},
	"Misprint": {"mult": 3.5, "w": 0.8, "kinds": ["game", "card", "scard", "comic", "book", "record"], "color": Color("ff5577"), "desc": "Label printed wrong at the factory. Very few escaped."},
	"Test Cart": {"mult": 6.0, "w": 0.25, "kinds": ["game"], "color": Color("5ee08a"), "desc": "Pre-release test copy with a handwritten label."},
	"Launch Edition": {"mult": 1.4, "w": 8.0, "kinds": ["console"], "color": Color("4fa3ff"), "desc": "From the launch-day shipment."},
	"Boxed Bundle": {"mult": 1.3, "w": 8.0, "kinds": ["console", "acc"], "color": Color("e6d34a"), "desc": "Still with the bundle box and inserts."},
	"Refurbished": {"mult": 0.75, "w": 6.0, "kinds": ["console", "acc"], "color": Color("9a9a9a"), "desc": "Factory refurbished. Works fine, worth less."},
	"Limited Color": {"mult": 1.8, "w": 2.0, "kinds": ["console", "acc"], "color": Color("b07cff"), "desc": "Short-run colourway."},
	"Store Display": {"mult": 2.6, "w": 0.8, "kinds": ["console", "acc", "misc"], "color": Color("ff8a3d"), "desc": "Pulled from a store kiosk. Bolted down once."},
	"Prototype": {"mult": 7.0, "w": 0.15, "kinds": ["console", "acc"], "color": Color("5ee08a"), "desc": "Pre-production hardware. Probably shouldn't exist."},
	# Cards
	"1st Edition": {"mult": 2.2, "w": 6.0, "kinds": ["card", "pack"], "color": Color("2b2b2b"), "desc": "The black 1st Edition stamp. The first print run, and everyone knows it."},
	"Shadowless": {"mult": 1.6, "w": 4.0, "kinds": ["card"], "color": Color("9a93ab"), "desc": "Early print with no drop shadow on the art box."},
	"Holo Foil": {"mult": 1.5, "w": 9.0, "kinds": ["card"], "color": Color("b07cff"), "desc": "Foil art that throws rainbows under a lamp."},
	"Reverse Holo": {"mult": 1.15, "w": 9.0, "kinds": ["card"], "color": Color("4fa3ff"), "desc": "Shiny everywhere except the art. Nice, not wild."},
	"Promo Stamp": {"mult": 1.4, "w": 3.0, "kinds": ["card"], "color": Color("e6d34a"), "desc": "Event stamp in the corner. Handed out once, never again."},
	"Signed by Artist": {"mult": 2.4, "w": 0.6, "kinds": ["card"], "color": Color("ff8a3d"), "desc": "Signed in silver by the illustrator at a con."},
	"Playtest Card": {"mult": 6.0, "w": 0.25, "kinds": ["card"], "color": Color("5ee08a"), "desc": "Pre-release playtest print. Plain border, handwritten notes."},
	"Heavy Pack": {"mult": 1.6, "w": 4.0, "kinds": ["pack", "wax", "longbox", "booklot", "crate"], "color": Color("e6d34a"), "desc": "Weighs a gram heavier than the rest. Probably a holo inside."},
	"Resealed?": {"mult": 0.45, "w": 2.5, "kinds": ["pack", "wax", "longbox", "booklot", "crate"], "color": Color("b04a4a"), "desc": "The crimps look... glued. Buyer beware."},
	# Sports cards
	"Refractor": {"mult": 1.6, "w": 7.0, "kinds": ["scard"], "color": Color("7fe0ff"), "desc": "Chrome stock that splits light into a rainbow. Tilt it and grin."},
	"Gold Parallel": {"mult": 2.2, "w": 3.0, "kinds": ["scard"], "color": Color("e8b923"), "desc": "Gold border, serial-numbered to 50 on the back."},
	"Short Print": {"mult": 1.8, "w": 3.0, "kinds": ["scard"], "color": Color("4fa3ff"), "desc": "Printed in a fraction of the usual numbers. The checklist hides it."},
	"Tiffany": {"mult": 2.0, "w": 1.5, "kinds": ["scard"], "color": Color("f5f5ff"), "desc": "The glossy factory-set print run on white stock. Shines like a photo."},
	"O-Pee-Chee": {"mult": 0.9, "w": 5.0, "kinds": ["scard"], "color": Color("ff6b6b"), "desc": "The Canadian printing. Bilingual back, rougher card stock."},
	"On-Card Auto": {"mult": 3.0, "w": 1.0, "kinds": ["scard"], "color": Color("ff8a3d"), "desc": "Signed right on the card, not a sticker. Certified on the back."},
	"Patch Auto": {"mult": 4.5, "w": 0.4, "kinds": ["scard"], "color": Color("d4af37"), "desc": "A swatch of game-worn jersey and a signature. Thick as a coaster."},
	"Printing Plate 1/1": {"mult": 7.0, "w": 0.15, "kinds": ["scard"], "color": Color("5ee08a"), "desc": "The actual metal plate the card was printed from. One of one."},
	# Comics
	"Newsstand Edition": {"mult": 1.3, "w": 6.0, "kinds": ["comic"], "color": Color("e6d34a"), "desc": "Sold off a newsstand rack, barcode and all. Fewer survived than the shop copies."},
	"Price Variant": {"mult": 3.0, "w": 0.6, "kinds": ["comic"], "color": Color("ff8a3d"), "desc": "A test-market cover price, printed for a few cities only."},
	"UK Pence Copy": {"mult": 0.7, "w": 4.0, "kinds": ["comic"], "color": Color("ff6b6b"), "desc": "The British printing with the price in pence. Same story, smaller crowd."},
	"2nd Printing": {"mult": 0.6, "w": 5.0, "kinds": ["comic"], "color": Color("9a9a9a"), "desc": "Reprinted to meet demand. Collectors want the first."},
	"Signature Series": {"mult": 2.4, "w": 0.8, "kinds": ["comic"], "color": Color("ffcc33"), "desc": "Signed by the artist in front of a witness. Yellow label."},
	"Virgin Cover": {"mult": 1.8, "w": 1.5, "kinds": ["comic"], "color": Color("f5f5ff"), "desc": "No logo, no text. Just the art, edge to edge."},
	"Foil Cover": {"mult": 1.5, "w": 4.0, "kinds": ["comic"], "color": Color("b07cff"), "desc": "A chromium foil cover from the boom years. Shiny, and everywhere."},
	"1:100 Ratio Variant": {"mult": 2.6, "w": 0.6, "kinds": ["comic"], "color": Color("4fa3ff"), "desc": "One per hundred ordered. Shops sold them out the back door."},
	"Restored": {"mult": 0.4, "w": 3.0, "kinds": ["comic"], "color": Color("b07cc9"), "desc": "Colour touch and a pressed spine. Purple label, half the price."},
	# Rare books
	"Later Printing": {"mult": 0.5, "w": 8.0, "kinds": ["book"], "color": Color("9a9a9a"), "desc": "Not the first printing. Same words, a fraction of the money."},
	"Book Club Edition": {"mult": 0.35, "w": 4.0, "kinds": ["book"], "color": Color("6a8a6a"), "desc": "Smaller, cheaper, no price on the flap and a dot on the back board. Collectors wince."},
	"Ex-Library": {"mult": 0.4, "w": 4.0, "kinds": ["book"], "color": Color("7a6a9a"), "desc": "Stamped, stickered and card-pocketed by a public library. Well read."},
	"Price-Clipped": {"mult": 0.8, "w": 3.0, "kinds": ["book"], "color": Color("c08a5a"), "desc": "Someone snipped the price off the jacket flap before giving it as a gift."},
	"First State": {"mult": 1.8, "w": 3.0, "kinds": ["book"], "color": Color("4fa3ff"), "desc": "All the points: the typo, the right binding, the earliest copies off the press."},
	"Signed by the Author": {"mult": 2.4, "w": 0.9, "kinds": ["book"], "color": Color("ff8a3d"), "desc": "Signed on the title page in the author's own hand."},
	"Inscribed Copy": {"mult": 2.0, "w": 1.0, "kinds": ["book"], "color": Color("ffb36b"), "desc": "Inscribed to a friend: 'For Margaret, who knows why.'"},
	"Association Copy": {"mult": 4.0, "w": 0.3, "kinds": ["book"], "color": Color("5ee08a"), "desc": "Owned by someone who mattered to the author, with their notes in the margins."},
	"Advance Proof": {"mult": 2.2, "w": 0.8, "kinds": ["book"], "color": Color("e6d34a"), "desc": "Uncorrected proof in plain wrappers, sent to reviewers before the typos were fixed."},
	"Fine Binding": {"mult": 1.6, "w": 3.0, "kinds": ["book"], "color": Color("d4af37"), "desc": "Rebound in tooled morocco with gilt edges. Glitters on the shelf."},
	"Limited Edition": {"mult": 1.8, "w": 1.5, "kinds": ["book"], "color": Color("b07cff"), "desc": "Numbered, slipcased, printed on heavy paper for subscribers only."},
	# Vinyl records
	"Reissue": {"mult": 0.5, "w": 8.0, "kinds": ["record"], "color": Color("9a9a9a"), "desc": "A later pressing from new plates. Sounds fine, sells for a fraction."},
	"Record Club Pressing": {"mult": 0.4, "w": 4.0, "kinds": ["record"], "color": Color("6a8a6a"), "desc": "Pressed for the mail-order record club: a club code on the back and thinner vinyl."},
	"Cut-Out": {"mult": 0.6, "w": 4.0, "kinds": ["record"], "color": Color("c08a5a"), "desc": "Drilled or corner-clipped by the distributor to mark it as a bargain-bin remainder."},
	"White Label Promo": {"mult": 1.6, "w": 3.0, "kinds": ["record"], "color": Color("f0f0f0"), "desc": "A radio-station promo: plain white label, PROMOTIONAL COPY - NOT FOR SALE."},
	"First Pressing": {"mult": 1.8, "w": 3.0, "kinds": ["record"], "color": Color("4fa3ff"), "desc": "The original plates: the right matrix numbers scratched in the run-out groove."},
	"Mono Pressing": {"mult": 1.7, "w": 3.0, "kinds": ["record"], "color": Color("d4af37"), "desc": "The mono mix, before stereo took over. The band was in the room for this one."},
	"Japanese Pressing": {"mult": 1.4, "w": 3.0, "kinds": ["record"], "color": Color("e04a4a"), "desc": "Heavy, quiet vinyl with the paper obi strip still wrapped around the sleeve."},
	"Colored Vinyl": {"mult": 1.5, "w": 4.0, "kinds": ["record"], "color": Color("ff6ad5"), "desc": "Pressed on coloured vinyl. Hold it up to the light and grin."},
	"Picture Disc": {"mult": 1.4, "w": 2.0, "kinds": ["record"], "color": Color("b07cff"), "desc": "The art is pressed into the record itself. Sounds worse, looks amazing."},
	"Signed Sleeve": {"mult": 2.4, "w": 0.7, "kinds": ["record"], "color": Color("ff8a3d"), "desc": "Signed across the front in silver marker outside the stage door."},
	"Test Pressing": {"mult": 5.0, "w": 0.25, "kinds": ["record"], "color": Color("5ee08a"), "desc": "One of a handful pressed to check the sound. Plain white label, written on by hand."},
	# Coins
	"Proof-Like": {"mult": 1.6, "w": 5.0, "kinds": ["coin"], "color": Color("dfe8ff"), "desc": "Mirror fields from fresh dies. Shines like a proof."},
	"Rainbow Toned": {"mult": 1.5, "w": 6.0, "kinds": ["coin"], "color": Color("b07cff"), "desc": "Decades in an album gave it a rainbow. Collectors swoon."},
	"Deep Cameo": {"mult": 1.9, "w": 2.5, "kinds": ["coin"], "color": Color("f5f5ff"), "desc": "Frosted design on black mirror fields."},
	"Doubled Die": {"mult": 4.0, "w": 0.6, "kinds": ["coin"], "color": Color("ff5577"), "desc": "The die was struck twice off-line: the letters show double."},
	"Off-Center": {"mult": 2.2, "w": 1.0, "kinds": ["coin"], "color": Color("ff8a3d"), "desc": "Struck off-centre at the mint. A famous kind of error."},
	"Pedigree": {"mult": 2.5, "w": 0.8, "kinds": ["coin", "comic", "book", "record"], "color": Color("d4af37"), "desc": "From a famous old collection, named on the slab."},
	"Restrike": {"mult": 0.6, "w": 4.0, "kinds": ["coin"], "color": Color("9a9a9a"), "desc": "Struck later from the old dies. Real metal, not the real date."},
	"Pattern": {"mult": 7.0, "w": 0.15, "kinds": ["coin"], "color": Color("5ee08a"), "desc": "A trial design that was never adopted. Hardly any exist."},
}

static var _by_id: Dictionary = {}
static var _by_tier: Dictionary = {}
static var ITEMS: Array = _build_items()

const ERA := {"FES": [1985, 1994], "SFES": [1991, 1998], "F64": [1996, 2002], "PBOY": [1989, 2002], "PBA": [2001, 2008],
	"PST": [1995, 2004], "PST2": [2000, 2009], "PSPK": [2005, 2012], "FCUBE": [2001, 2007], "XBX": [2001, 2010],
	"DC": [1999, 2007], "GEN": [1989, 1997], "SAT": [1995, 1999], "NEO": [1990, 2006], "A26": [1977, 1990],
	"DUO": [2006, 2010], "ODD": [1991, 1998], "MISC": [1988, 2000]}
const MAKERS := {"funtendo": "Funtendo", "statia": "Sonny", "xbux": "Microsloth", "saga": "Saga", "snc": "SNC", "ataro": "Ataro", "odd": "Oddware Labs", "misc": "Various",
	"sport": "Toppz Co.", "critco": "Critter Co.", "lizards": "Lizards of the Coast", "konamo": "Konamo", "tcg": "Various", "usmint": "U.S. Mint", "world": "Various mints", "ancient": "Ancient mints"}


static func _build_items() -> Array:
	var out: Array = []
	for d in HANDMADE:
		var e: Dictionary = d.duplicate(true)
		var meta: Dictionary = CatalogItems.LEGACY_META.get(e["id"], {})
		if meta.is_empty():
			var era: Array = ERA.get(String(e["plat"]), [1990, 2000])
			var fam := String(PLATFORMS.get(String(e["plat"]), PLATFORMS["MISC"])["family"])
			var hsh := absi(hash(String(e["id"])))
			meta = {"rank": 0, "list": "", "year": int(era[0]) + hsh % (int(era[1]) - int(era[0]) + 1),
				"pub": MAKERS.get(fam, "Various"), "genre": "Hardware" if e["kind"] != "game" else ["Platformer", "Action", "Adventure", "Puzzle"][hsh % 4],
				"blurb": "A household favourite. Everybody had one of these.", "rating": "E" if e["kind"] == "game" else "",
				"run": [900000, 200000, 40000, 2000][int(e["tier"])] + hsh % 50000}
		e.merge(meta)
		out.append(e)
	for d in CatalogItems.ITEMS:
		out.append(d)
	for d in CC.CARDS:
		out.append(d)
	for d in CC.COINS:
		out.append(d)
	for d in SPORTS.ITEMS:
		out.append(d)
	for d in COMICS.ITEMS:
		out.append(d)
	for d in BOOKS.ITEMS:
		out.append(d)
	for d in VINYL.ITEMS:
		out.append(d)
	return out


## Which market a platform belongs to (games, cards or coins).
static func market_of(plat: String) -> String:
	return String(PLATFORMS.get(plat, PLATFORMS["MISC"]).get("market", "games"))


static func is_cc(item: Dictionary) -> bool:
	return CC_KINDS.has(String(item.get("kind", "game")))


static var _by_market: Dictionary = {}


## Every catalog def in one market.
static func items_of(market: String) -> Array:
	if _by_market.is_empty():
		for m in MARKETS:
			_by_market[m] = []
		for d in ITEMS:
			(_by_market[market_of(String(d["plat"]))] as Array).append(d)
	return _by_market.get(market, [])


## Condition in the item's own hobby words ("Near Mint", "Mint State"...).
static func cond_name(item: Dictionary) -> String:
	var c := String(item.get("cond", "Loose"))
	var w: Dictionary = COND_WORDS.get(String(item.get("kind", "game")), {})
	return String(w[c][0]) if w.has(c) else c


static func cond_short(item: Dictionary) -> String:
	var c := String(item.get("cond", "Loose"))
	var w: Dictionary = COND_WORDS.get(String(item.get("kind", "game")), {})
	return String(w[c][1]) if w.has(c) else String(COND_SHORT.get(c, c))


## Family-specific name for a variant (budget lines, demo discs...).
static func variant_label(item: Dictionary) -> String:
	var v := String(item.get("variant", "Standard"))
	var fam := String(platform(String(item["plat"]))["family"])
	if v == "Player's Pick":
		return {"funtendo": "Player's Pick", "statia": "Greatest Hiss", "saga": "Saga All-Stars", "xbux": "Plutonium Hits"}.get(fam, "Budget Line")
	if v == "Test Cart" and (item.get("tags", []) as Array).has("disc"):
		return "Demo Disc"
	if v == "Misprint" and String(item.get("kind", "")) == "card":
		return "Error Print"
	if v == "Misprint" and String(item.get("kind", "")) == "scard":
		return "Error Card"
	if v == "Misprint" and String(item.get("kind", "")) == "comic":
		return "Printing Error"
	if v == "Misprint" and String(item.get("kind", "")) == "book":
		return "Misbound Copy"
	if v == "Pedigree" and String(item.get("kind", "")) == "book":
		return "Famous Provenance"
	if v == "Misprint" and String(item.get("kind", "")) == "record":
		return "Wrong Label"
	if v == "Pedigree" and String(item.get("kind", "")) == "record":
		return "DJ's Own Copy"
	if String(item.get("kind", "")) in ["longbox", "booklot", "crate"]:
		if v == "Heavy Pack":
			return "Heavy Box"
		if v == "Resealed?":
			return "Pre-Picked?"
	if v == "Pedigree" and String(item.get("kind", "")) == "comic":
		return "Pedigree Copy"
	if v == "Japan Import" and is_cc(item):
		return "Japanese Print"
	return v


## Variant weights for one item, shaped by what's believable for it: budget
## re-releases only happen to big sellers, rental copies to the rental era,
## Japan imports to Japanese families, prototypes get likelier the rarer the
## item. ctx: {"slot": "hunt"/"shop"/"online"} nudges what each venue turns up.
static func variant_weights(def: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var kind := String(def.get("kind", "game"))
	var year := int(def.get("year", 0))
	var printed := int(def.get("run", 0))
	var tier := int(def.get("tier", 0))
	var fam := String(platform(String(def.get("plat", "MISC"))).get("family", ""))
	var slot := String(ctx.get("slot", ""))
	var out := {}
	for k in VARIANTS:
		if not (VARIANTS[k]["kinds"] as Array).has(kind):
			continue
		var w := float(VARIANTS[k]["w"])
		match k:
			"Player's Pick":
				if printed > 0:
					w *= clampf((printed - 250000.0) / 600000.0, 0.0, 2.0)
				if slot == "hunt":
					w *= 1.5
			"Black Label":
				w *= 1.4 if year > 0 and year < 2000 else 0.5
			"First Print":
				if printed > 0:
					w *= clampf(pow(200000.0 / float(printed), 0.3), 0.5, 2.2)
			"Japan Import":
				if not ["funtendo", "statia", "saga", "snc"].has(fam):
					w *= 0.15
			"Rental Copy":
				if year > 0 and (year < 1985 or year > 2006):
					w = 0.0
				if slot == "hunt":
					w *= 2.0
				elif slot == "online":
					w *= 0.6
			"Collector's Edition":
				if year > 0 and year < 1995:
					w *= 0.2
				if slot == "online":
					w *= 1.5
			"Signed by Dev":
				w *= 1.0 + 0.5 * tier
			"Test Cart", "Prototype":
				w *= 0.4 + 0.6 * tier
				if slot == "hunt":
					w *= 0.6
			"Store Display":
				if slot == "shop":
					w *= 1.8
			"Launch Edition":
				if year > 0 and year > 2003:
					w *= 0.7
			"1st Edition", "Shadowless":
				# Only the old Critter sets had 1st Edition / Shadowless runs.
				if fam != "critco" and fam != "konamo" or year > 2003:
					w *= 0.05 if k == "Shadowless" else 0.3
				if k == "Shadowless" and fam != "critco":
					w = 0.0
			"Newsstand Edition":
				if year > 0 and (year < 1979 or year > 2002):
					w *= 0.1
			"Price Variant":
				if year > 0 and (year < 1976 or year > 1983):
					w = 0.0
			"UK Pence Copy":
				if year > 0 and (year < 1959 or year > 1992) or fam == "indy":
					w = 0.0
			"2nd Printing", "Virgin Cover", "1:100 Ratio Variant":
				if year > 0 and year < 1985:
					w = 0.0
			"Foil Cover":
				if year > 0 and (year < 1990 or year > 1999):
					w *= 0.05
			"Book Club Edition", "Advance Proof":
				if year > 0 and year < 1926:
					w = 0.0
			"Price-Clipped":
				if String(def.get("binding", "")) != "jacket":
					w = 0.0
			"Signed by the Author", "Inscribed Copy", "Association Copy":
				if year > 0 and year < 1750 or String(def.get("author", "")).begins_with("Various"):
					w = 0.0
				w *= 1.0 + 0.4 * tier
			"Limited Edition":
				if year > 0 and year < 1900:
					w = 0.0
			"Fine Binding":
				if String(def.get("binding", "")) == "jacket":
					w *= 0.3
			"Mono Pressing":
				if year > 0 and year > 1968:
					w = 0.0
			"Colored Vinyl", "Picture Disc":
				if year > 0 and year < 1975:
					w *= 0.15
				if String(def.get("fmt", "")) == "78":
					w = 0.0
			"Record Club Pressing":
				if year > 0 and (year < 1955 or year > 1992) or String(def.get("fmt", "")) != "LP":
					w = 0.0
			"Cut-Out":
				if year > 0 and year < 1960:
					w = 0.0
			"Japanese Pressing":
				if year > 0 and year < 1958 or String(def.get("fmt", "")) == "78":
					w = 0.0
			"Signed Sleeve":
				if String(def.get("artist", "")).begins_with("Various") or String(def.get("fmt", "")) == "78":
					w = 0.0
				w *= 1.0 + 0.4 * tier
			"White Label Promo", "Test Pressing":
				if String(def.get("fmt", "")) == "78":
					w *= 0.2
			"Restored":
				if year > 0 and year > 1985:
					w *= 0.2
			"Refractor", "Gold Parallel":
				if year > 0 and year < (1993 if k == "Refractor" else 1995):
					w = 0.0  # no chrome before the 90s
			"Tiffany":
				if year > 0 and (year < 1984 or year > 1991):
					w = 0.0
			"O-Pee-Chee":
				# OPC printed hockey and baseball in Canada; their own sets never get it.
				var pl := String(def.get("plat", ""))
				if pl != "PUCK" and pl != "BASE" or String(def.get("set", "")).contains("O-Pee"):
					w = 0.0
			"Patch Auto":
				if year > 0 and year < 1997:
					w = 0.0
			"On-Card Auto", "Printing Plate 1/1":
				if year > 0 and year < 1990:
					w *= 0.15
				w *= 1.0 + 0.5 * tier
			"Holo Foil", "Reverse Holo":
				if year > 0 and year < 1995 and fam == "lizards":
					w = 0.0  # no foils in the early Magick sets
			"Rainbow Toned", "Proof-Like", "Deep Cameo":
				var metal := String(def.get("metal", ""))
				if not metal.contains("silver") and k != "Proof-Like":
					w *= 0.15
				if fam == "ancient":
					w = 0.0
			"Doubled Die", "Off-Center":
				if (def.get("tags", []) as Array).has("error"):
					w = 0.0  # already an error coin
				if fam == "ancient" and k == "Doubled Die":
					w = 0.0
			"Restrike":
				if fam == "usmint":
					w *= 0.2
			"Pedigree":
				if String(def.get("kind", "")) == "comic" and year > 1969:
					w = 0.0
				w *= 1.0 + 0.6 * tier
		if w > 0.0:
			out[k] = w
	if out.is_empty():
		out["Standard"] = 1.0
	return out


## Rolls a variant for a copy of def (see variant_weights).
static func roll_variant(def: Dictionary, rng: RandomNumberGenerator, ctx: Dictionary = {}) -> String:
	var ws := variant_weights(def, ctx)
	var total := 0.0
	for k in ws:
		total += float(ws[k])
	var r := rng.randf() * total
	for k in ws:
		r -= float(ws[k])
		if r <= 0.0:
			return k
	return "Standard"


## How common a def is inside its rarity tier: big print runs turn up more.
static func scarcity_weight(def: Dictionary) -> float:
	var printed := int(def.get("run", 0))
	if printed <= 0:
		return 1.0
	return clampf(pow(printed / 100000.0, 0.35), 0.05, 20.0)


static func variant_mult(item: Dictionary) -> float:
	return float(VARIANTS.get(String(item.get("variant", "Standard")), VARIANTS["Standard"])["mult"])


## Rough odds of pulling this exact copy (tier share x share inside the tier
## x variant share), for the card.
static func odds(item: Dictionary) -> int:
	var tier := int(item.get("tier", 0))
	var tier_share: float = [0.6, 0.3, 0.09, 0.01][tier]
	var def := get_def(String(item.get("id", "")))
	if def.is_empty():
		def = item
	var sum := 0.0
	for d in defs_of_tier(tier, market_of(String(def.get("plat", "MISC")))):
		sum += scarcity_weight(d)
	var in_tier := scarcity_weight(def) / maxf(sum, 0.001)
	var ws := variant_weights(def)
	var total := 0.0
	for k in ws:
		total += float(ws[k])
	var vw := float(ws.get(String(item.get("variant", "Standard")), 0.0)) / maxf(total, 0.001)
	return maxi(1, int(round(1.0 / (tier_share * in_tier * maxf(vw, 0.0005)))))


static func get_def(id: String) -> Dictionary:
	if _by_id.is_empty():
		for d in ITEMS:
			_by_id[d["id"]] = d
	return _by_id.get(id, {})


## Defs of one rarity tier, in one market ("" = every market).
static func defs_of_tier(tier: int, market: String = "") -> Array:
	if _by_tier.is_empty():
		for d in ITEMS:
			for k in ["", market_of(String(d["plat"]))]:
				var key := "%s%d" % [k, int(d["tier"])]
				if not _by_tier.has(key):
					_by_tier[key] = []
				(_by_tier[key] as Array).append(d)
	return _by_tier.get("%s%d" % [market, tier], [])


static func platform(code: String) -> Dictionary:
	return PLATFORMS.get(code, PLATFORMS["MISC"])
