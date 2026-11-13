extends RefCounted
## Collector's Curse meta progression (no class_name: preload it).
## ESTATES = starting decks (who you inherit from). Winning a run frees the
## next sealed collector from the Buyer's vault and their estate unlocks.
## TIERS = grade tiers (Balatro stakes): each win unlocks the next, and each
## tier keeps the rules of the ones below it.
## BINDER = rewards for owning more different items across runs, plus page
## stamps: owning half of a console's binder page pays +$1 at every run start.

## cash: +/- starting cash. starters / cond: starting shelf. shelf: +/- slots.
## perks: perks you start with. perk_cap: +/- perk slots. interest: +/- cap.
const ESTATES := [
	{"id": "arlo", "name": "Great-Uncle Arlo", "short": "ARLO", "who": "male_adult_08",
		"line": "The one who got you into this.", "effect": "The standard run. 3 loose games, $25.",
		"loading": "Uncle Arlo's house. His shelf. His debt.",
		"letter": "Sorry for your loss. Your great-uncle Arlo and I had an arrangement. He collected for me for forty-one years. Now you will.\n\nMy appraiser will visit after every stop. Keep the shelf worth his time. You do not want to come up short.",
		"cash": 0, "starters": 3, "cond": "Loose", "shelf": 0, "perks": [], "perk_cap": 0, "interest": 0},
	{"id": "june", "name": "Aunt June", "short": "JUNE", "who": "female_adult_05",
		"line": "Ran a pawn shop for thirty years. Never paid full price.", "effect": "Starts with Silver Tongue and +$10. Only 2 starter games.",
		"loading": "Aunt June's back room. Everything has a tag.",
		"letter": "Welcome back to the hobby. Your Aunt June worked for me once. She haggled with my appraiser for nineteen years before he sealed her.\n\nYou've freed her. How sweet. Her debt is yours now.",
		"cash": 10, "starters": 2, "cond": "Loose", "shelf": 0, "perks": ["silver_tongue"], "perk_cap": 0, "interest": 0},
	{"id": "dale", "name": "Cousin Dale", "short": "DALE", "who": "male_adult_03",
		"line": "Never left his computer chair. Still hasn't.", "effect": "Starts with Power Seller (no online fees). $5 less.",
		"loading": "Cousin Dale's room. Seventeen tabs still open.",
		"letter": "Dale sold me everything he owned, one auction at a time. 100% positive feedback, to the very end.\n\nI left his chair warm for you.",
		"cash": -5, "starters": 3, "cond": "Loose", "shelf": 0, "perks": ["power_seller"], "perk_cap": 0, "interest": 0},
	{"id": "rose", "name": "Grandma Rose", "short": "ROSE", "who": "female_adult_14",
		"line": "Mint or nothing. She shrink-wrapped her own wedding cake.", "effect": "Starts with Box & Manual and 2 CIB games. $10 less.",
		"loading": "Grandma Rose's parlor. Plastic on every couch.",
		"letter": "Rose never opened a single thing she bought. Not a box. Not a letter. Not the door when my appraiser knocked.\n\nShe graded a 9.6. You'd do well to match her.",
		"cash": -10, "starters": 2, "cond": "CIB", "shelf": 0, "perks": ["box_and_manual"], "perk_cap": 0, "interest": 0},
	{"id": "hector", "name": "Uncle Hector", "short": "HECTOR", "who": "male_adult_14",
		"line": "Kept everything. The neighbors called it a fire hazard.", "effect": "Starts with Lucky Lots, +1 shelf slot and 4 games (2 damaged). Interest cap -$3.",
		"loading": "Uncle Hector's garage. Mind the stacks.",
		"letter": "Hector filled a three-car garage and still came up short. Quantity, not quality. A common mistake.\n\nHis stacks are yours. Try not to be buried under them.",
		"cash": 0, "starters": 4, "cond": "Loose", "damaged": 2, "shelf": 1, "perks": ["lucky_lots"], "perk_cap": 0, "interest": -3},
	{"id": "twins", "name": "The Pruitt Twins", "short": "TWINS", "who": "female_adult_08",
		"line": "Two of everything. One to play, one to keep.", "effect": "Starts with Completionist and +1 perk slot. $5 less.",
		"loading": "The Pruitt house. Two of every chair.",
		"letter": "The twins finished a set together. Then they argued over who got to keep it. I settled the matter. Two cases, side by side.\n\nTheir shelves are yours. Share nicely.",
		"cash": -5, "starters": 3, "cond": "Loose", "shelf": 0, "perks": ["completionist"], "perk_cap": 1, "interest": 0},
]

## Each tier adds its rule to all the ones below.
const TIERS := [
	{"name": "GRADE 9.0", "desc": "Standard rules.", "color": Color("b9b0cc")},
	{"name": "GRADE 9.5", "desc": "Targets +20%.", "color": Color("5fb3d9")},
	{"name": "GRADE 9.8", "desc": "Start with $10 less.", "color": Color("4fd9a0")},
	{"name": "GRADE 10", "desc": "The Buyer's terms apply at every stop.", "color": Color("ffcc33")},
	{"name": "BLACK LABEL", "desc": "One less shelf slot. Targets +45%.", "color": Color("ff6b6b")},
]

## [owned count, kind, value, label]. kind: perk (joins the shop), shelf, cash.
const BINDER := [
	[15, "perk", "plastic_wrap", "Plastic Wrap perk joins the shop"],
	[40, "perk", "dust_sheet", "Dust Sheet perk joins the shop"],
	[80, "shelf", 1, "+1 shelf slot in every run"],
	[130, "perk", "full_page", "Full Page perk joins the shop"],
	[200, "cash", 10, "+$10 at the start of every run"],
	[300, "perk", "slab_fan", "Slab Fan perk joins the shop"],
]
## A binder page stamp: own this share of a console's page for +$1 a run.
const PAGE_SHARE := 0.5


static func estate(id: String) -> Dictionary:
	for e in ESTATES:
		if String(e["id"]) == id:
			return e
	return ESTATES[0]


static func index_of(id: String) -> int:
	for i in ESTATES.size():
		if String(ESTATES[i]["id"]) == id:
			return i
	return 0


## Starting bonuses from the binder: {"perks": [...], "shelf": n, "cash": n,
## "stamps": pages stamped, "next": the next reward row or []}.
static func binder_rewards(owned: Dictionary) -> Dictionary:
	var out := {"perks": [], "shelf": 0, "cash": 0, "stamps": 0, "next": []}
	var n := owned.size()
	for r in BINDER:
		if n >= int(r[0]):
			match String(r[1]):
				"perk": (out["perks"] as Array).append(String(r[2]))
				"shelf": out["shelf"] = int(out["shelf"]) + int(r[2])
				"cash": out["cash"] = int(out["cash"]) + int(r[2])
		elif (out["next"] as Array).is_empty():
			out["next"] = r
	var per := {}
	var tot := {}
	for d in Catalog.ITEMS:
		var p := String(d["plat"])
		if p == "MISC":
			continue
		tot[p] = int(tot.get(p, 0)) + 1
		if owned.has(String(d["id"])):
			per[p] = int(per.get(p, 0)) + 1
	for p in tot.keys():
		if float(per.get(p, 0)) >= ceil(float(tot[p]) * PAGE_SHARE):
			out["stamps"] = int(out["stamps"]) + 1
	out["cash"] = int(out["cash"]) + int(out["stamps"])
	return out


## How many of a page you need for its stamp.
static func page_need(total: int) -> int:
	return int(ceil(float(total) * PAGE_SHARE))
