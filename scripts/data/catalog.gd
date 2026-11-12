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
}

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

## Variants a copy can roll. mult = value multiplier, w = roll weight,
## kinds = which item kinds can get it. See variant_label() for family names.
const VARIANTS := {
	"Standard": {"mult": 1.0, "w": 70.0, "kinds": ["game", "console", "acc", "misc"], "color": Color("9a93ab"), "desc": "The regular retail release."},
	"Player's Pick": {"mult": 0.8, "w": 9.0, "kinds": ["game"], "color": Color("e6d34a"), "desc": "Budget re-release with the coloured banner. Collectors shrug."},
	"Black Label": {"mult": 1.25, "w": 7.0, "kinds": ["game"], "color": Color("2b2b2b"), "desc": "Original print, before the budget re-releases."},
	"First Print": {"mult": 1.6, "w": 5.0, "kinds": ["game"], "color": Color("4fa3ff"), "desc": "From the very first production run."},
	"Japan Import": {"mult": 0.9, "w": 6.0, "kinds": ["game", "console"], "color": Color("ff6b6b"), "desc": "Japanese release. Different art, same game."},
	"Rental Copy": {"mult": 0.6, "w": 4.0, "kinds": ["game"], "color": Color("3a6fd6"), "desc": "Blockbluster Video sticker on the front. Well loved."},
	"Collector's Edition": {"mult": 2.2, "w": 1.2, "kinds": ["game"], "color": Color("d4af37"), "desc": "Big box, art book, pin. The works."},
	"Signed by Dev": {"mult": 2.4, "w": 0.6, "kinds": ["game"], "color": Color("ff8a3d"), "desc": "Signed in silver marker by someone who made it."},
	"Misprint": {"mult": 3.5, "w": 0.8, "kinds": ["game"], "color": Color("ff5577"), "desc": "Label printed wrong at the factory. Very few escaped."},
	"Test Cart": {"mult": 6.0, "w": 0.25, "kinds": ["game"], "color": Color("5ee08a"), "desc": "Pre-release test copy with a handwritten label."},
	"Launch Edition": {"mult": 1.4, "w": 8.0, "kinds": ["console"], "color": Color("4fa3ff"), "desc": "From the launch-day shipment."},
	"Boxed Bundle": {"mult": 1.3, "w": 8.0, "kinds": ["console", "acc"], "color": Color("e6d34a"), "desc": "Still with the bundle box and inserts."},
	"Refurbished": {"mult": 0.75, "w": 6.0, "kinds": ["console", "acc"], "color": Color("9a9a9a"), "desc": "Factory refurbished. Works fine, worth less."},
	"Limited Color": {"mult": 1.8, "w": 2.0, "kinds": ["console", "acc"], "color": Color("b07cff"), "desc": "Short-run colourway."},
	"Store Display": {"mult": 2.6, "w": 0.8, "kinds": ["console", "acc", "misc"], "color": Color("ff8a3d"), "desc": "Pulled from a store kiosk. Bolted down once."},
	"Prototype": {"mult": 7.0, "w": 0.15, "kinds": ["console", "acc"], "color": Color("5ee08a"), "desc": "Pre-production hardware. Probably shouldn't exist."},
}

static var _by_id: Dictionary = {}
static var _by_tier: Dictionary = {}
static var ITEMS: Array = _build_items()

const ERA := {"FES": [1985, 1994], "SFES": [1991, 1998], "F64": [1996, 2002], "PBOY": [1989, 2002], "PBA": [2001, 2008],
	"PST": [1995, 2004], "PST2": [2000, 2009], "PSPK": [2005, 2012], "FCUBE": [2001, 2007], "XBX": [2001, 2010],
	"DC": [1999, 2007], "GEN": [1989, 1997], "SAT": [1995, 1999], "NEO": [1990, 2006], "A26": [1977, 1990],
	"DUO": [2006, 2010], "ODD": [1991, 1998], "MISC": [1988, 2000]}
const MAKERS := {"funtendo": "Funtendo", "statia": "Sonny", "xbux": "Microsloth", "saga": "Saga", "snc": "SNC", "ataro": "Ataro", "odd": "Oddware Labs", "misc": "Various"}


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
	return out


## Family-specific name for a variant (budget lines, demo discs...).
static func variant_label(item: Dictionary) -> String:
	var v := String(item.get("variant", "Standard"))
	var fam := String(platform(String(item["plat"]))["family"])
	if v == "Player's Pick":
		return {"funtendo": "Player's Pick", "statia": "Greatest Hiss", "saga": "Saga All-Stars", "xbux": "Plutonium Hits"}.get(fam, "Budget Line")
	if v == "Test Cart" and (item.get("tags", []) as Array).has("disc"):
		return "Demo Disc"
	return v


## Rolls a variant for a copy of def, weighted by VARIANTS.
static func roll_variant(def: Dictionary, rng: RandomNumberGenerator) -> String:
	var kind := String(def["kind"])
	var total := 0.0
	for k in VARIANTS:
		if (VARIANTS[k]["kinds"] as Array).has(kind):
			total += float(VARIANTS[k]["w"])
	var r := rng.randf() * total
	for k in VARIANTS:
		if (VARIANTS[k]["kinds"] as Array).has(kind):
			r -= float(VARIANTS[k]["w"])
			if r <= 0.0:
				return k
	return "Standard"


static func variant_mult(item: Dictionary) -> float:
	return float(VARIANTS.get(String(item.get("variant", "Standard")), VARIANTS["Standard"])["mult"])


## Rough odds of pulling this exact copy (tier share x variant share), for the card.
static func odds(item: Dictionary) -> int:
	var tier := int(item.get("tier", 0))
	var tier_share: float = [0.6, 0.3, 0.09, 0.01][tier]
	var n := float(defs_of_tier(tier).size())
	var kind := String(item["kind"])
	var total := 0.0
	for k in VARIANTS:
		if (VARIANTS[k]["kinds"] as Array).has(kind):
			total += float(VARIANTS[k]["w"])
	var vw := float(VARIANTS.get(String(item.get("variant", "Standard")), VARIANTS["Standard"])["w"]) / maxf(total, 1.0)
	return maxi(1, int(round(n / tier_share / maxf(vw, 0.0001))))


static func get_def(id: String) -> Dictionary:
	if _by_id.is_empty():
		for d in ITEMS:
			_by_id[d["id"]] = d
	return _by_id.get(id, {})


static func defs_of_tier(tier: int) -> Array:
	if _by_tier.is_empty():
		for t in 4:
			_by_tier[t] = []
		for d in ITEMS:
			(_by_tier[int(d["tier"])] as Array).append(d)
	return _by_tier.get(tier, [])


static func platform(code: String) -> Dictionary:
	return PLATFORMS.get(code, PLATFORMS["MISC"])
