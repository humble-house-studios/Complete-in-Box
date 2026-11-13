extends RefCounted
const Worlds := preload("res://scripts/data/worlds.gd")
## Collector's Curse meta progression (no class_name: preload it).
## ESTATES = starting decks (who you inherit from). Winning a run frees the
## next sealed collector from the Buyer's vault and their estate unlocks.
## TIERS = grade tiers (Balatro stakes): each win unlocks the next, and each
## tier keeps the rules of the ones below it.
## BINDER = rewards for owning more different items across runs, plus page
## stamps: owning half of a console's binder page pays +$1 at every run start.

## cash: +/- starting cash. starters / cond: starting shelf. shelf: +/- slots.
## perks: perks you start with. perk_cap: +/- perk slots. interest: +/- cap.
## bit: this estate's bit in the save's "estates" bitmask. Never change a bit:
## old saves keep their freed collectors (Arlo 0, June 1, Dale 2, Rose 3,
## Hector 4, Twins 5 from before the ten worlds; 6+ are new).
## world: the collecting world this collector belongs to (worlds.gd). The list
## is in unlock order: a win frees the first one still sealed.
const ESTATES := [
	{"id": "arlo", "bit": 0, "world": "games", "name": "Great-Uncle Arlo", "short": "ARLO", "who": "male_adult_08",
		"line": "The one who got you into this.", "effect": "The standard run. 3 loose games, $25.",
		"loading": "Uncle Arlo's house. His shelf. His debt.",
		"letter": "Sorry for your loss. Your great-uncle Arlo and I had an arrangement. He collected for me for forty-one years. Now you will.\n\nMy appraiser will visit after every stop. Keep the shelf worth his time. You do not want to come up short.",
		"cash": 0, "starters": 3, "cond": "Loose", "shelf": 0, "perks": [], "perk_cap": 0, "interest": 0},
	{"id": "twins", "bit": 5, "world": "cards", "name": "The Pruitt Twins", "short": "TWINS", "who": "female_adult_08",
		"line": "Two of everything. One to play, one to keep.", "effect": "Starts with Completionist and +1 perk slot. $5 less.",
		"loading": "The Pruitt house. Two of every binder.",
		"letter": "The twins finished a set together. Then they argued over who got to keep it. I settled the matter. Two cases, side by side.\n\nTheir binders are yours. Share nicely.",
		"cash": -5, "starters": 3, "cond": "Loose", "shelf": 0, "perks": ["completionist"], "perk_cap": 1, "interest": 0},
	{"id": "rose", "bit": 3, "world": "sports", "name": "Grandma Rose", "short": "ROSE", "who": "female_adult_14",
		"line": "Mint or nothing. She top-loaded her own wedding photos.", "effect": "Starts with Top-Loaders (Near Mint x1.5) and 2 Near Mint pieces. $10 less.",
		"loading": "Grandma Rose's parlor. Plastic on every couch, a slab on every shelf.",
		"letter": "Rose never opened a single thing she bought. Not a wax box. Not a letter. Not the door when my appraiser knocked.\n\nShe graded a 9.6. You'd do well to match her.",
		"cash": -10, "starters": 2, "cond": "CIB", "shelf": 0, "perks": ["box_and_manual"], "perk_cap": 0, "interest": 0},
	{"id": "marv", "bit": 6, "world": "vinyl", "name": "Midnight Marv Okafor", "short": "MARV", "who": "male_adult_05",
		"line": "Played records to nobody at 3 a.m. for thirty years. Kept every one.", "effect": "Starts with Extra Hour (+1 Time at every stop). $12 less.",
		"loading": "Marv's basement. The needle is still on the run-out groove.",
		"letter": "Marv spun records for an audience of one. Me. Every night, 3 a.m., he dedicated the last song to c0mplete_set.\n\nThe station is off the air now. His crates are yours.",
		"cash": -12, "starters": 3, "cond": "Loose", "shelf": 0, "perks": ["extra_hour"], "perk_cap": 0, "interest": 0},
	{"id": "hector", "bit": 4, "world": "comics", "name": "Uncle Hector", "short": "HECTOR", "who": "male_adult_14",
		"line": "Kept everything. The neighbors called it a fire hazard.", "effect": "Starts with Lucky Lots, +1 shelf slot and 4 pieces (2 damaged). $6 less, interest cap -$3.",
		"loading": "Uncle Hector's garage. Mind the longboxes.",
		"letter": "Hector filled a three-car garage with longboxes and still came up short. Quantity, not quality. A common mistake.\n\nHis stacks are yours. Try not to be buried under them.",
		"cash": -6, "starters": 4, "cond": "Loose", "damaged": 2, "shelf": 1, "perks": ["lucky_lots"], "perk_cap": 0, "interest": -3},
	{"id": "june", "bit": 1, "world": "coins", "name": "Aunt June", "short": "JUNE", "who": "female_adult_05",
		"line": "Ran a pawn shop for thirty years. Never paid full price.", "effect": "Starts with Silver Tongue. Only 2 starter pieces.",
		"loading": "Aunt June's back room. Everything has a tag.",
		"letter": "Welcome back to the hobby. Your Aunt June worked for me once. She haggled with my appraiser for nineteen years before he sealed her.\n\nYou've freed her. How sweet. Her debt is yours now.",
		"cash": 0, "starters": 2, "cond": "Loose", "shelf": 0, "perks": ["silver_tongue"], "perk_cap": 0, "interest": 0},
	{"id": "elsa", "bit": 7, "world": "watches", "name": "Elsa Brandt, Watchmaker", "short": "ELSA", "who": "female_adult_11",
		"line": "Fixed every clock in town. Saved every penny. Never once let her own clock run.", "effect": "Starts with Piggy Bank (interest cap $12). $10 less.",
		"loading": "Elsa's workshop. Four hundred clocks, all stopped at 4:51.",
		"letter": "Elsa repaired time for a living. She asked me for more of it. I gave her exactly what she asked for: a case where nothing moves.\n\nHer bench is yours. Mind the springs.",
		"cash": -10, "starters": 3, "cond": "Loose", "shelf": 0, "perks": ["piggy_bank"], "perk_cap": 0, "interest": 0},
	{"id": "dale", "bit": 2, "world": "pop", "name": "Cousin Dale", "short": "DALE", "who": "male_adult_03",
		"line": "Never left his computer chair. Still hasn't.", "effect": "Starts with Power Seller (no online fees). $5 less.",
		"loading": "Cousin Dale's room. Seventeen tabs still open.",
		"letter": "Dale sold me everything he owned, one auction at a time. 100% positive feedback, to the very end.\n\nI left his chair warm for you.",
		"cash": -5, "starters": 3, "cond": "Loose", "shelf": 0, "perks": ["power_seller"], "perk_cap": 0, "interest": 0},
	{"id": "iris", "bit": 8, "world": "books", "name": "Professor Iris Halloway", "short": "IRIS", "who": "female_adult_03",
		"line": "Catalogued every book she ever touched. In pencil, in the margins.", "effect": "Starts with Price Guide (exact values everywhere). $9 less.",
		"loading": "The professor's study. A bookmark in every book.",
		"letter": "The professor wrote me a letter once, asking what I wanted. Twelve pages. Footnoted. I answered in one word.\n\nHer library is yours. Return it on time.",
		"cash": -9, "starters": 3, "cond": "Loose", "shelf": 0, "perks": ["price_guide"], "perk_cap": 0, "interest": 0},
	{"id": "buyer", "bit": 9, "world": "art", "name": "c0mplete_set", "short": "BUYER", "who": "male_adult_08",
		"line": "The Buyer's own collection. You were always going to end up here.", "effect": "Starts with Cursed Cartridge (x2 Mult, -2 shelf). Another -1 shelf, one less perk slot, 2 starters, $12 less.",
		"loading": "The Gallery. Every painting faces the wall but one.",
		"letter": "You opened every case in my vault. All but one.\n\nCome to the Gallery. I've kept a frame for you.",
		"cash": -12, "starters": 2, "cond": "Loose", "shelf": -1, "perks": ["cursed_cart"], "perk_cap": -1, "interest": 0},
]
## Free from the very first launch: Arlo (retro) and the Pruitt Twins (TCG).
const START_MASK := (1 << 0) | (1 << 5)

## Each tier adds its rule to all the ones below.
const TIERS := [
	{"name": "GRADE 9.0", "desc": "Standard rules.", "color": Color("b9b0cc")},
	{"name": "GRADE 9.5", "desc": "Targets +20%.", "color": Color("5fb3d9")},
	{"name": "GRADE 9.8", "desc": "Start with $10 less.", "color": Color("4fd9a0")},
	{"name": "GRADE 10", "desc": "The Buyer's terms apply at every stop.", "color": Color("ffcc33")},
	{"name": "BLACK LABEL", "desc": "One less shelf slot. Targets +45%.", "color": Color("ff6b6b")},
]

## [owned count, kind, value, label]. kind: perk (joins the shop), shelf, cash,
## perk_slot (+1 perk slot every run).
const BINDER := [
	[15, "perk", "plastic_wrap", "Plastic Wrap perk joins the shop"],
	[40, "perk", "dust_sheet", "Dust Sheet perk joins the shop"],
	[80, "shelf", 1, "+1 shelf slot in every run"],
	[130, "perk", "full_page", "Full Page perk joins the shop"],
	[200, "cash", 10, "+$10 at the start of every run"],
	[300, "perk", "slab_fan", "Slab Fan perk joins the shop"],
	[500, "cash", 5, "+$5 more at the start of every run"],
	[800, "perk", "archivist", "Archivist perk joins the shop"],
	[1200, "perk_slot", 1, "+1 perk slot in every run"],
	[1800, "perk", "long_box", "The Long Box perk joins the shop"],
]
## A binder page stamp: own this share of a platform's page for +$1 a run,
## up to STAMP_CAP dollars in all (ten worlds have ~50 pages).
const PAGE_SHARE := 0.5
const STAMP_CAP := 15
## Own every item in a world: +$3 at the start of every run (per world).
const WORLD_DONE_CASH := 3


static func estate(id: String) -> Dictionary:
	for e in ESTATES:
		if String(e["id"]) == id:
			return e
	return ESTATES[0]


## Is this estate freed in the save's bitmask?
static func is_free(mask: int, i: int) -> bool:
	return (mask >> int(ESTATES[i]["bit"])) & 1 == 1


static func bit_of(i: int) -> int:
	return 1 << int(ESTATES[i]["bit"])


## World ids open to play with this bitmask (their collector freed and built).
static func open_worlds(mask: int) -> Array:
	var out: Array = []
	for i in ESTATES.size():
		var w := String(ESTATES[i]["world"])
		if is_free(mask, i) and Worlds.is_built(w):
			out.append(w)
	return out


static func index_of(id: String) -> int:
	for i in ESTATES.size():
		if String(ESTATES[i]["id"]) == id:
			return i
	return 0


## Starting bonuses from the binder: {"perks": [...], "shelf": n, "cash": n,
## "perk_slot": n, "stamps": pages stamped, "stamp_cash": what they pay (capped),
## "worlds_done": worlds fully owned, "next": the next reward row or []}.
static func binder_rewards(owned: Dictionary) -> Dictionary:
	var out := {"perks": [], "shelf": 0, "cash": 0, "perk_slot": 0, "stamps": 0, "stamp_cash": 0, "worlds_done": [], "next": []}
	var n := owned.size()
	for r in BINDER:
		if n >= int(r[0]):
			match String(r[1]):
				"perk": (out["perks"] as Array).append(String(r[2]))
				"shelf": out["shelf"] = int(out["shelf"]) + int(r[2])
				"cash": out["cash"] = int(out["cash"]) + int(r[2])
				"perk_slot": out["perk_slot"] = int(out["perk_slot"]) + int(r[2])
		elif (out["next"] as Array).is_empty():
			out["next"] = r
	var per := {}
	var tot := {}
	var w_tot := {}
	var w_got := {}
	for d in Catalog.ITEMS:
		var p := String(d["plat"])
		var m := Catalog.market_of(p)
		w_tot[m] = int(w_tot.get(m, 0)) + 1
		if owned.has(String(d["id"])):
			w_got[m] = int(w_got.get(m, 0)) + 1
		if p == "MISC":
			continue
		tot[p] = int(tot.get(p, 0)) + 1
		if owned.has(String(d["id"])):
			per[p] = int(per.get(p, 0)) + 1
	for p in tot.keys():
		if float(per.get(p, 0)) >= ceil(float(tot[p]) * PAGE_SHARE):
			out["stamps"] = int(out["stamps"]) + 1
	for m in w_tot.keys():
		if int(w_got.get(m, 0)) >= int(w_tot[m]):
			(out["worlds_done"] as Array).append(String(m))
	out["stamp_cash"] = mini(int(out["stamps"]), STAMP_CAP)
	out["cash"] = int(out["cash"]) + int(out["stamp_cash"]) + WORLD_DONE_CASH * (out["worlds_done"] as Array).size()
	return out


## How many of a page you need for its stamp.
static func page_need(total: int) -> int:
	return int(ceil(float(total) * PAGE_SHARE))
