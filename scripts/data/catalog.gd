class_name Catalog
extends RefCounted
## Everything you can find, buy, flip and hoard. Parody names on purpose, so the
## game can ship without licensing real brands.
##
## base = what a LOOSE copy is worth in an average market. Condition, grading,
## trends and how long you've held it all multiply that (see Market).
## tier: 0 common, 1 uncommon, 2 rare, 3 grail.
## kind: game / console / acc (accessory) / misc (no platform set).

const PLATFORMS := {
	"FES": {"name": "Funtendo FES", "short": "FES", "color": Color("d64545"), "family": "funtendo"},
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

const ITEMS := [
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

static var _by_id: Dictionary = {}


static func get_def(id: String) -> Dictionary:
	if _by_id.is_empty():
		for d in ITEMS:
			_by_id[d["id"]] = d
	return _by_id.get(id, {})


static func defs_of_tier(tier: int) -> Array:
	var out: Array = []
	for d in ITEMS:
		if int(d["tier"]) == tier:
			out.append(d)
	return out


static func platform(code: String) -> Dictionary:
	return PLATFORMS.get(code, PLATFORMS["MISC"])
