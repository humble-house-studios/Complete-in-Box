class_name Run
extends RefCounted
## One run of Complete In Box: all the rules, no UI. The UI calls the action
## methods (buy, haggle, sell, ...) and redraws from the state; every action
## returns {"ok": bool, "msg": String} plus anything extra it produced.
##
## Loop: Home (perk shop, pick venue) -> Venue (buy/sell/flip, Time runs down)
## -> end_stop() appraises your shelf against the target -> advance() -> Home.
## Three stops per ante, eight antes to win, endless after that.

signal changed

const Unlocks := preload("res://scripts/data/unlocks.gd")

enum Phase { HOME, VENUE, APPRAISAL, OVER, WON }

var phase: int = Phase.HOME
var seed_value: int = 0
var rng := RandomNumberGenerator.new()

var ante: int = 1
var stop: int = 0  # 0 hunt, 1 shop, 2 online
var stops_played: int = 0
var endless: bool = false

var cash: int = Balance.START_CASH
var shelf: Array = []  # item dicts that count toward appraisal
var shelf_cap: int = Balance.START_SHELF
var perks: Array = []  # perk ids
var perk_cap: int = Balance.START_PERK_SLOTS
var time_bonus: int = 0
var interest_cap: int = Balance.START_INTEREST_CAP
var reroll_discount: int = 0

## Off the shelf but still taking up a slot.
var grading: Array = []  # {item, returns_at}
var listings: Array = []  # your items up for auction this stop

## Market
var hot: Array = []
var cold: Array = []
var rumor: String = ""
## The platforms this run's market deals in (a different scene every run).
var active_plats: Array = []
var boss_id: String = ""
## What this run deals in: "games", then maybe "cards" (ante 5+), "coins" (ante 7+).
var market: String = "games"
## Extra Time at the first stop after flipping into a new market.
var pivot_time: int = 0

## Home
var venue_choices: Array = []
var perk_offers: Array = []
var upgrade_offer: Dictionary = {}
var reroll_cost: int = Balance.REROLL_START

## Current venue
var venue: Dictionary = {}
var time_left: int = 0
var stock: Array = []  # {item, price, est, haggled, bargain, bin}
var lots: Array = []  # {items, price, peek, bought}
var auctions: Array = []  # {item, bid, rival, my_max, won}

var last_appraisal: Dictionary = {}
## The Buyer's want list: one request per ante ({id, plat, n, reward, done}).
## Fill it at any appraisal this ante for a bonus; fill all eight in one run
## for the true ending. wants_done counts the filled ones.
var want: Dictionary = {}
var wants_done: int = 0
## Someone at the door when you get home (stops 2 and 3): a choice to take or
## leave ({id, ...}, see _roll_event). diary_read = Arlo's diary pages found.
var event: Dictionary = {}
var diary_read: int = 0
## Collector's Curse: how many of the Buyer's letters you've opened (one per ante).
var letters_read: int = 0
## Meta progression: which estate you inherited, the grade tier (0..4, each
## keeps the rules below it) and perks the binder has unlocked for the shop.
var estate_id: String = "arlo"
var tier: int = 0
var unlocked_perks: Array = []
var last_rewards: Dictionary = {}
var stats := {"bought": 0, "sold": 0, "best_flip": 0, "best_flip_name": "", "best_appraisal": 0, "profit": 0}

var _uid: int = 0
## Pull luck: offers since the last rare+ (pity builds), and a cool-down after
## a grail so they stay special.
var dry: int = 0
var grail_cool: int = 0


# ================================================================ setup

## opts (all optional): estate (id), tier (0..4), perks_unlocked (binder perks
## for the shop), bonus_cash, bonus_shelf (binder rewards).
func start(p_seed: int = 0, opts: Dictionary = {}) -> void:
	seed_value = p_seed if p_seed != 0 else randi()
	Flavor.reset_claims()
	rng.seed = seed_value
	phase = Phase.HOME
	ante = 1
	stop = 0
	var est := Unlocks.estate(String(opts.get("estate", "arlo")))
	estate_id = String(est["id"])
	tier = clampi(int(opts.get("tier", 0)), 0, Unlocks.TIERS.size() - 1)
	unlocked_perks = (opts.get("perks_unlocked", []) as Array).duplicate()
	cash += int(est["cash"]) + int(opts.get("bonus_cash", 0)) - (10 if tier >= 2 else 0)
	cash = maxi(cash, 5)
	shelf_cap += int(est["shelf"]) + int(opts.get("bonus_shelf", 0)) - (1 if tier >= 4 else 0)
	perk_cap += int(est["perk_cap"])
	interest_cap = maxi(0, interest_cap + int(est["interest"]))
	for pid in est["perks"]:
		perks.append(String(pid))
	_pick_active_platforms()
	var n_start := int(est["starters"]) if opts.has("estate") else Balance.STARTER_ITEMS
	for i in n_start:
		var it := make_item(_pick_def(0), "Damaged" if i < int(est.get("damaged", 0)) else String(est["cond"]))
		it["paid"] = 0
		shelf.append(it)
	rumor = _random_platform()
	_roll_trends()
	_roll_boss()
	_roll_want()
	_prepare_home()


func make_item(def: Dictionary, cond: String) -> Dictionary:
	_uid += 1
	return {
		"uid": _uid, "id": def["id"], "name": def["name"], "plat": def["plat"],
		"kind": def["kind"], "tier": int(def["tier"]), "base": int(def["base"]),
		"tags": def["tags"], "cond": cond, "grade": 0, "held": 0, "paid": 0,
		"variant": "Standard", "serial": 100000 + (_uid * 7919) % 900000,
	}


func has_perk(id: String) -> bool:
	return perks.has(id)


func target() -> int:
	var t := Balance.target(ante, stop)
	if tier >= 4:
		return int(round(t * 1.45))
	if tier >= 1:
		return int(round(t * 1.2))
	return t


## The Buyer's terms (boss twist) hit the Online stop, or every stop at GRADE 10+.
func is_boss_stop() -> bool:
	return stop == 2 or tier >= 3


func boss_active(id: String) -> bool:
	return is_boss_stop() and boss_id == id


func slots_used() -> int:
	return shelf.size() + grading.size() + listings.size()


func free_slots() -> int:
	return maxi(0, shelf_cap - slots_used())


func slot_name() -> String:
	return Venues.SLOT_NAMES[Venues.SLOTS[stop]]


# ================================================================ market

func market_value(item: Dictionary) -> int:
	var v := float(item["base"]) * float(Catalog.COND_MULT[item["cond"]])
	if int(item["grade"]) > 0:
		v *= _grade_mult(int(item["grade"]))
	v *= trend_mult(String(item["plat"]))
	v *= age_mult(item)
	v *= Catalog.variant_mult(item)
	return maxi(1, int(round(v)))


func trend_mult(plat: String) -> float:
	var hype := has_perk("hype_beast")
	if hot.has(plat):
		return 1.0 + (Balance.HOT - 1.0) * (2.0 if hype else 1.0)
	if cold.has(plat):
		return 1.0 - (1.0 - Balance.COLD) * (0.5 if hype else 1.0)
	return 1.0


func age_mult(item: Dictionary) -> float:
	var held := float(item["held"])
	var speed := 2.0 if has_perk("time_capsule") else 1.0
	if (item["tags"] as Array).has("fad"):
		return maxf(Balance.FAD_FLOOR, 1.0 - Balance.FAD_DECAY * held)
	var rate := Balance.APPRECIATE_COMMON
	var cond := String(item["cond"])
	if int(item["tier"]) >= 1 or cond == "Mint" or cond == "Sealed":
		rate = Balance.APPRECIATE_COLLECTIBLE
	if cond == "Sealed":
		rate += Balance.APPRECIATE_SEALED_EXTRA
	return 1.0 + rate * speed * held


func _grade_mult(grade: int) -> float:
	for g in Balance.GRADES:
		if int(g[0]) == grade:
			return float(g[2])
	return 1.0


func _roll_trends() -> void:
	hot.clear()
	cold.clear()
	var h := rumor if rng.randf() < Balance.RUMOR_ACCURACY else _random_platform()
	hot.append(h)
	var c := _random_platform([h])
	cold.append(c)
	rumor = _random_platform()


## Platforms that show up as wildcards in every run (few items, no sets).
const WILDCARD_PLATS := ["MISC", "ODD", "DUO", "PSPK"]


## Each run deals in its own mix of platforms, so the finds feel different.
## Cards and coins have only a handful of categories: those markets use them all.
func _pick_active_platforms() -> void:
	var counts := {}
	for d in Catalog.items_of(market):
		counts[d["plat"]] = int(counts.get(d["plat"], 0)) + 1
	var pool: Array = []
	for p in Catalog.PLATFORMS.keys():
		if not WILDCARD_PLATS.has(p) and int(counts.get(p, 0)) >= 8 and Catalog.market_of(p) == market:
			pool.append(p)
	active_plats.clear()
	while active_plats.size() < mini(Balance.ACTIVE_PLATFORMS, pool.size()):
		var p: String = pool[rng.randi_range(0, pool.size() - 1)]
		if not active_plats.has(p):
			active_plats.append(p)


func is_active_plat(p: String) -> bool:
	if Catalog.market_of(p) != market:
		return false
	return active_plats.is_empty() or active_plats.has(p) or WILDCARD_PLATS.has(p)


func _random_platform(exclude: Array = []) -> String:
	var options: Array = []
	for p in (active_plats if not active_plats.is_empty() else Catalog.PLATFORMS.keys()):
		if p != "MISC" and not exclude.has(p):
			options.append(p)
	return String(options[rng.randi_range(0, options.size() - 1)])


func _roll_boss() -> void:
	# The first round's terms are mild: the ones that cut your score wait.
	var opts: Array = []
	for b in Venues.BOSSES:
		if ante > 1 or not ["picky", "skeptic"].has(String(b["id"])):
			opts.append(String(b["id"]))
	boss_id = String(opts[rng.randi_range(0, opts.size() - 1)])


# ================================================================ rolling stock

func _pick_def(tier: int) -> Dictionary:
	var pool := _active_pool(tier)
	while pool.is_empty() and tier > 0:
		tier -= 1
		pool = _active_pool(tier)
	var cum := _pool_cum(tier, pool)
	var held := {}
	for o in stock:
		held[String(o["item"]["id"])] = 0.9
	for it in shelf:
		held[String(it["id"])] = maxf(float(held.get(String(it["id"]), 0.0)), 0.5)
	var d: Dictionary
	# Rarely the same thing twice on one table, less often what you own.
	for attempt in 4:
		var r := rng.randf() * float(cum[-1])
		var lo := 0
		var hi := cum.size() - 1
		while lo < hi:
			var mid := (lo + hi) / 2
			if float(cum[mid]) <= r:
				lo = mid + 1
			else:
				hi = mid
		d = pool[lo]
		if rng.randf() >= float(held.get(String(d["id"]), 0.0)):
			break
	return d


var _cum_cache: Dictionary = {}

## Running totals of _def_weight over a pool, cached per tier, venue type and
## market mood (so a pull is a quick binary search).
func _pool_cum(tier: int, pool: Array) -> Array:
	var key := "%d|%s|%s|%s|%d|%s" % [tier, String(venue.get("slot", "")), ",".join(hot), ",".join(cold), pool.size(), market]
	if _cum_cache.has(key):
		return _cum_cache[key]
	var cum: Array = []
	var t := 0.0
	for d in pool:
		t += _def_weight(d)
		cum.append(t)
	_cum_cache[key] = cum
	return cum


## How likely a def is to turn up right here, right now (inside its tier).
func _def_weight(d: Dictionary) -> float:
	var w := Catalog.scarcity_weight(d)
	var slot := String(venue.get("slot", ""))
	var year := int(d.get("year", 0))
	var kind := String(d.get("kind", "game"))
	# Garages turn up old stuff, shops stock hardware, online has the newer.
	if slot == "hunt":
		if year > 0 and year <= 1996:
			w *= Balance.HUNT_OLD_BIAS
		if kind == "acc":
			w *= 1.3
	elif slot == "shop":
		if kind != "game":
			w *= Balance.SHOP_HW_BIAS
	elif slot == "online":
		if year >= 1998:
			w *= Balance.ONLINE_NEW_BIAS
	# Hot platforms get picked over; cold ones flood the market.
	var plat := String(d.get("plat", ""))
	if hot.has(plat):
		w *= Balance.HOT_SUPPLY
	elif cold.has(plat):
		w *= Balance.COLD_SUPPLY
	return w


func _active_pool(tier: int) -> Array:
	var out: Array = []
	for d in Catalog.defs_of_tier(tier, market):
		if is_active_plat(String(d["plat"])):
			out.append(d)
	return out


## Current rarity weights [common, uncommon, rare, grail] for a pull with this
## boost, pity and grail cooldown included (the slot reel shows these odds).
func pull_odds(boost: int) -> Array:
	var w: Array = (Balance.tier_weights(ante + boost) as Array).duplicate()
	# Pity: every dry pull nudges the rare and grail odds up a little.
	var p := mini(dry, Balance.PITY_CAP)
	w[2] = float(w[2]) + p * Balance.PITY_RARE
	w[3] = float(w[3]) + p * Balance.PITY_GRAIL * (1.0 if ante >= 2 else 0.0)
	if grail_cool > 0:
		w[3] = float(w[3]) * Balance.GRAIL_COOL_MULT
	return w


func _roll_tier(boost: int) -> int:
	var t := _weighted(pull_odds(boost))
	if t >= 2:
		dry = 0
	else:
		dry += 1
	if t == 3:
		grail_cool = Balance.GRAIL_COOL
	elif grail_cool > 0:
		grail_cool -= 1
	return t


func _weighted(weights: Array) -> int:
	var total := 0.0
	for x in weights:
		total += float(x)
	var r := rng.randf() * total
	for i in weights.size():
		r -= float(weights[i])
		if r < 0.0:
			return i
	return weights.size() - 1


func roll_item(boost: int, cond_weights: Array, hunt: bool = false) -> Dictionary:
	var def := _pick_def(_roll_tier(boost))
	var ci := _weighted(cond_weights)
	if hunt and has_perk("eagle_eye") and rng.randf() < 0.25:
		ci = mini(ci + 1, Catalog.CONDITIONS.size() - 1)
	var it := make_item(def, Catalog.CONDITIONS[ci])
	it["variant"] = Catalog.roll_variant(def, rng, {"slot": String(venue.get("slot", ""))})
	return it


func _price_for(item: Dictionary, lo: float, hi: float) -> int:
	var p := float(market_value(item)) * rng.randf_range(lo, hi)
	if has_perk("coupon"):
		p *= 0.85
	return maxi(1, int(round(p)))


func _make_offer(boost_extra: int = 0) -> Dictionary:
	var hunt: bool = venue["slot"] == "hunt"
	var item := roll_item(int(venue["tier_boost"]) + boost_extra, venue["cond"], hunt)
	var pr: Array = venue["price"]
	var price := _price_for(item, float(pr[0]), float(pr[1]))
	if hunt:
		# Yard-sale sellers don't know a misprint from a rental copy.
		price = maxi(1, int(round(price / Catalog.variant_mult(item))))
	var is_bin: bool = venue.get("bin", false)
	if is_bin and boss_active("shipping"):
		price = int(round(price * 1.3))
	var offer := {"item": item, "price": price, "haggled": false, "bargain": false, "bin": is_bin, "est": []}
	if not shows_exact():
		var mv := float(market_value(item)) / (Catalog.variant_mult(item) if hunt else 1.0)
		offer["est"] = [
			maxi(1, int(round(mv * rng.randf_range(Balance.EST_LOW[0], Balance.EST_LOW[1])))),
			maxi(2, int(round(mv * rng.randf_range(Balance.EST_HIGH[0], Balance.EST_HIGH[1])))),
		]
	return offer


func shows_exact() -> bool:
	return venue.is_empty() or bool(venue["exact"]) or has_perk("price_guide")


func _make_lot() -> Dictionary:
	var size := int(venue["lot_size"])
	var boost := int(venue["tier_boost"])
	if has_perk("lucky_lots"):
		size += 1
		boost += 1
	var items: Array = []
	var worth := 0
	for i in size:
		var it := roll_item(boost, venue["cond"], true)
		if int(it["tier"]) >= 3 and ante < 6:
			# A grail in an early lot prices the whole box out of reach: hold it back.
			var swap := make_item(_pick_def(2), String(it["cond"]))
			it = swap
		items.append(it)
		worth += market_value(it)
	var pr: Array = Balance.LOT_PRICE if venue["id"] != "storage" else venue["price"]
	var price := maxi(1, int(round(worth * rng.randf_range(float(pr[0]), float(pr[1])))))
	if has_perk("coupon"):
		price = maxi(1, int(round(price * 0.85)))
	return {"items": items, "price": price, "peek": int(venue["lot_peek"]), "bought": false}


func _make_auction() -> Dictionary:
	var item := roll_item(int(venue["tier_boost"]), venue["cond"])
	var mv := float(market_value(item))
	var rival := mv * rng.randf_range(Balance.RIVAL_RANGE[0], Balance.RIVAL_RANGE[1])
	if boss_active("snipers"):
		rival *= 1.3
	return {"item": item, "bid": maxi(1, int(round(mv * Balance.OPENING_BID))),
		"rival": int(round(rival)), "my_max": 0}


# ================================================================ home

func _prepare_home() -> void:
	phase = Phase.HOME
	venue = {}
	var open := Venues.unlocked(Venues.SLOTS[stop], ante, market)
	venue_choices.clear()
	if open.size() <= 3:
		for d in open:
			venue_choices.append(d["id"])
	else:
		var newest: Dictionary = open[-1]
		venue_choices.append(newest["id"])
		var rest := open.slice(0, open.size() - 1)
		while venue_choices.size() < 3 and not rest.is_empty():
			var i := rng.randi_range(0, rest.size() - 1)
			venue_choices.insert(0, rest[i]["id"])
			rest.remove_at(i)
	reroll_cost = maxi(0, Balance.REROLL_START - reroll_discount)
	_roll_perk_offers()
	var up: Dictionary = Perks.UPGRADES[rng.randi_range(0, Perks.UPGRADES.size() - 1)]
	upgrade_offer = up.duplicate()
	changed.emit()


func _roll_perk_offers() -> void:
	perk_offers.clear()
	var pool: Array = []
	for p in Perks.LIST:
		if not perks.has(p["id"]) and perk_fits(String(p["id"])) and (not p.has("lock") or unlocked_perks.has(String(p["id"]))):
			pool.append(p["id"])
	while perk_offers.size() < Balance.PERK_OFFERS and not pool.is_empty():
		var i := rng.randi_range(0, pool.size() - 1)
		perk_offers.append(pool[i])
		pool.remove_at(i)


func buy_perk(id: String) -> Dictionary:
	if not perk_offers.has(id):
		return _fail("Not on offer.")
	if perks.size() >= perk_cap:
		return _fail("Perk slots full. Sell one first.")
	var cost := int(Perks.get_def(id)["cost"])
	if cash < cost:
		return _fail("Need $%d." % cost)
	cash -= cost
	perks.append(id)
	perk_offers.erase(id)
	if id == "moms_basement":
		shelf_cap += 2
	if id == "cursed_cart":
		shelf_cap -= 2
	return _ok("Got %s." % Perks.get_def(id)["name"])


func sell_perk(id: String) -> Dictionary:
	if not perks.has(id):
		return _fail("You don't have that.")
	var back := int(Perks.get_def(id)["cost"]) / 2
	perks.erase(id)
	cash += back
	if id == "moms_basement":
		shelf_cap -= 2
	if id == "cursed_cart":
		shelf_cap += 2
	return _ok("Sold %s for $%d." % [Perks.get_def(id)["name"], back])


func reroll_perks() -> Dictionary:
	if cash < reroll_cost:
		return _fail("Need $%d." % reroll_cost)
	cash -= reroll_cost
	reroll_cost += 1
	_roll_perk_offers()
	return _ok("Fresh perks.")


func buy_upgrade() -> Dictionary:
	if upgrade_offer.is_empty():
		return _fail("Already bought.")
	var cost := int(upgrade_offer["cost"])
	if cash < cost:
		return _fail("Need $%d." % cost)
	cash -= cost
	match String(upgrade_offer["id"]):
		"shelf": shelf_cap += 1
		"time": time_bonus += 1
		"perk_slot": perk_cap += 1
		"interest": interest_cap += 3
		"reroll":
			reroll_discount += 1
			reroll_cost = maxi(0, reroll_cost - 1)
	var name := String(upgrade_offer["name"])
	upgrade_offer = {}
	return _ok("Got %s." % name)


# ================================================================ changing markets

## The new scene on offer right now: "cards" at Home before ante 5, "coins"
## before ante 7 (from games or cards), else "".
func pivot_offer() -> String:
	if phase != Phase.HOME or stop != 0 or endless:
		return ""
	if ante == Balance.PIVOT_CARDS_ANTE and market == "games":
		return "cards"
	if ante == Balance.PIVOT_COINS_ANTE and market != "coins":
		return "coins"
	return ""


## What the dealer pays for your whole shelf (and anything at the grader).
func pivot_value() -> int:
	var total := 0
	for it in shelf:
		total += maxi(1, int(round(market_value(it) * Balance.PIVOT_RATE)))
	for g in grading:
		total += maxi(1, int(round(market_value(g["item"]) * Balance.PIVOT_RATE)))
	return total


## Sells everything you own and moves the run into a new market: new venues,
## new platforms, new trends. The dealer throws in a few starter pieces and
## you get extra Time at the first stop to rebuild.
func pivot(to: String) -> Dictionary:
	if to == "" or pivot_offer() != to:
		return _fail("Not on offer right now.")
	var total := pivot_value()
	var n := shelf.size() + grading.size()
	for it in shelf:
		_record_sale(it, maxi(1, int(round(market_value(it) * Balance.PIVOT_RATE))))
	for g in grading:
		_record_sale(g["item"], maxi(1, int(round(market_value(g["item"]) * Balance.PIVOT_RATE))))
	shelf.clear()
	grading.clear()
	cash += total
	market = to
	_cum_cache.clear()
	dry = 0
	_pick_active_platforms()
	rumor = _random_platform()
	_roll_trends()
	_roll_want()
	var starters: Array = []
	for i in Balance.PIVOT_STARTERS:
		var it := make_item(_pick_def(1 if i == 0 else 0), "CIB" if i == 0 else "Loose")
		it["variant"] = "Standard"
		shelf.append(it)
		starters.append(it["name"])
	pivot_time = Balance.PIVOT_TIME
	var perks_before := perk_offers.duplicate()
	var up_before := upgrade_offer.duplicate()
	_prepare_home()
	perk_offers = perks_before.filter(func(p): return perk_fits(String(p)))
	upgrade_offer = up_before
	stats["pivots"] = int(stats.get("pivots", 0)) + 1
	var res := _ok("Sold %d item%s for $%d. Welcome to %s!" % [n, "" if n == 1 else "s", total, Catalog.MARKETS[to]["name"]])
	res["total"] = total
	res["starters"] = starters
	return res


## Perks tied to one hobby only show up in the shop while you deal in it.
func perk_fits(id: String) -> bool:
	var m := String(Perks.get_def(id).get("market", ""))
	return m == "" or m == market


## How many cards a sealed product holds when you rip it (0 = can't).
func pack_size(item: Dictionary) -> int:
	if String(item.get("kind", "")) != "pack":
		return 0
	var tags: Array = item.get("tags", [])
	if tags.has("box"):
		return Balance.OPEN_BOX
	if tags.has("deck"):
		return Balance.OPEN_DECK
	return Balance.OPEN_PACK


## Rips a sealed pack or box: it's gone, and its cards land on your shelf.
## Pure gamble: boxes roll higher, heavy packs higher still.
func open_pack(uid: int) -> Dictionary:
	if phase != Phase.HOME and phase != Phase.VENUE:
		return _fail("Not now.")
	var i := _shelf_index(uid)
	if i < 0:
		return _fail("Not on your shelf.")
	var pk: Dictionary = shelf[i]
	var n := pack_size(pk)
	if n <= 0:
		return _fail("Nothing to open.")
	if pk["cond"] == "Damaged":
		return _fail("Too crushed to trust. Sell it as is.")
	if free_slots() < n - 1:
		return _fail("Need %d free shelf slots for the pulls." % (n - 1))
	shelf.remove_at(i)
	var plat := String(pk["plat"])
	var boost := int(pk["tier"]) + (2 if (pk["tags"] as Array).has("box") else 0)
	if String(pk.get("variant", "")) == "Heavy Pack":
		boost += 2
	elif String(pk.get("variant", "")) == "Resealed?":
		boost -= 3
	var pool: Array = []
	for d in Catalog.items_of(market):
		if String(d["plat"]) == plat and String(d["kind"]) == "card":
			pool.append(d)
	var pulls: Array = []
	var each := int(pk.get("paid", 0)) / maxi(1, n)
	for k in n:
		var t := _roll_tier(maxi(0, boost))
		var cands := pool.filter(func(d): return int(d["tier"]) == t)
		while cands.is_empty() and t > 0:
			t -= 1
			cands = pool.filter(func(d): return int(d["tier"]) == t)
		var def: Dictionary = cands[rng.randi_range(0, cands.size() - 1)]
		var it := make_item(def, Catalog.CONDITIONS[_weighted(Balance.PULL_COND)])
		it["variant"] = Catalog.roll_variant(def, rng, {"slot": "shop"})
		if String(pk.get("variant", "")) == "1st Edition" and Catalog.variant_weights(def).has("1st Edition"):
			it["variant"] = "1st Edition"
		it["paid"] = each
		shelf.append(it)
		pulls.append(it)
	pulls.sort_custom(func(a, b): return market_value(a) > market_value(b))
	var worth := 0
	for it in pulls:
		worth += market_value(it)
	var res := _ok("Ripped %s: %d cards worth $%d (it was worth $%d sealed)." % [pk["name"], n, worth, market_value(pk)])
	res["pulls"] = pulls
	res["worth"] = worth
	res["was"] = market_value(pk)
	return res


# ================================================================ venue

func enter_venue(id: String) -> Dictionary:
	if phase != Phase.HOME:
		return _fail("Not at home.")
	if not venue_choices.has(id):
		return _fail("Can't go there now.")
	venue = Venues.get_def(id)
	phase = Phase.VENUE
	stops_played += 1
	time_left = int(venue["time"]) + time_bonus + (1 if has_perk("extra_hour") else 0) + pivot_time
	pivot_time = 0
	if is_boss_stop() and boss_id == "crash":
		cold.append(_random_platform(hot + cold))
	stock.clear()
	lots.clear()
	auctions.clear()
	listings.clear()
	var n := int(venue["stock"])
	if venue["slot"] == "hunt" and has_perk("early_bird") and n > 0:
		n += 2
	for i in n:
		stock.append(_make_offer())
	var bargains := int(venue.get("bargain", 0))
	for i in mini(bargains, stock.size()):
		var o: Dictionary = stock[i]
		o["bargain"] = true
		o["price"] = maxi(1, int(round(market_value(o["item"]) * rng.randf_range(0.5, 0.75))))
	for i in int(venue["lots"]):
		lots.append(_make_lot())
	for i in int(venue.get("auctions", 0)):
		auctions.append(_make_auction())
	var back := _return_grading()
	var msg := "Welcome to the %s." % venue["name"]
	if not back.is_empty():
		msg = "Back from grading: " + ", ".join(back)
	return _ok(msg)


func _return_grading() -> Array:
	var back: Array = []
	var keep: Array = []
	for g in grading:
		if int(g["returns_at"]) <= stops_played:
			var item: Dictionary = g["item"]
			item["grade"] = _roll_grade()
			shelf.append(item)
			back.append("%s got a %d" % [item["name"], item["grade"]])
		else:
			keep.append(g)
	grading = keep
	return back


func _roll_grade() -> int:
	var options: Array = []
	var weights: Array = []
	for g in Balance.GRADES:
		if has_perk("grader_buddy") and int(g[0]) < 8:
			continue
		options.append(int(g[0]))
		weights.append(int(g[1]))
	return int(options[_weighted(weights)])


func buy(index: int) -> Dictionary:
	if phase != Phase.VENUE or index < 0 or index >= stock.size():
		return _fail("Nothing there.")
	var o: Dictionary = stock[index]
	var price := int(o["price"])
	if cash < price:
		return _fail("Need $%d." % price)
	if free_slots() <= 0:
		return _fail("Shelf's full. Sell or dump something.")
	cash -= price
	stock.remove_at(index)
	var item: Dictionary = o["item"]
	item["paid"] = price
	stats["bought"] += 1
	var msg := "Bought %s for $%d." % [item["name"], price]
	if bool(o["bin"]) and not has_perk("bubble_wrap"):
		var risk := Balance.SCAM_RISK if boss_active("scams") else Balance.DAMAGE_RISK
		if rng.randf() < risk:
			var ci := maxi(0, Catalog.CONDITIONS.find(item["cond"]) - 1)
			msg = "%s arrived %s, not %s. Ugh." % [item["name"], Catalog.CONDITIONS[ci], item["cond"]]
			item["cond"] = Catalog.CONDITIONS[ci]
	shelf.append(item)
	var res := _ok(msg)
	res["item"] = item
	res["value"] = market_value(item)
	return res


func haggle(index: int) -> Dictionary:
	if phase != Phase.VENUE or index < 0 or index >= stock.size():
		return _fail("Nothing there.")
	if float(venue["haggle"]) <= 0.0:
		return _fail("No haggling here.")
	var o: Dictionary = stock[index]
	if bool(o["haggled"]):
		return _fail("They won't go lower.")
	if time_left <= 0:
		return _fail("Out of Time.")
	time_left -= 1
	o["haggled"] = true
	var chance := float(venue["haggle"]) + (0.25 if has_perk("silver_tongue") else 0.0)
	var old := int(o["price"])
	if rng.randf() < chance:
		o["price"] = maxi(1, int(round(old * float(venue["cut"]))))
		stats["haggles"] = int(stats.get("haggles", 0)) + 1
		var res := _ok("Deal! $%d -> $%d." % [old, o["price"]])
		res["success"] = true
		return res
	if has_perk("silver_tongue"):
		var r2 := _ok("They won't budge. Still $%d." % old)
		r2["success"] = false
		return r2
	o["price"] = int(ceil(old * 1.15))
	var r3 := _ok("Insulted! Now it's $%d." % o["price"])
	r3["success"] = false
	return r3


func dig() -> Dictionary:
	if phase != Phase.VENUE:
		return _fail("Not at a venue.")
	var n := int(venue["dig"])
	if n <= 0:
		return _fail("Nothing to dig through.")
	if time_left <= 0:
		return _fail("Out of Time.")
	time_left -= 1
	if venue.get("bin", false):
		stock.clear()
		for i in n:
			stock.append(_make_offer())
		return _ok("New listings.")
	var boost := 1 if venue["slot"] == "shop" else 0
	for i in n:
		stock.append(_make_offer(boost))
	return _ok("Found %d more." % n)


func buy_lot(index: int) -> Dictionary:
	if phase != Phase.VENUE or index < 0 or index >= lots.size():
		return _fail("Nothing there.")
	var lot: Dictionary = lots[index]
	if bool(lot["bought"]):
		return _fail("Already yours.")
	var price := int(lot["price"])
	if cash < price:
		return _fail("Need $%d." % price)
	cash -= price
	lot["bought"] = true
	stats["bought"] += 1
	var kept: Array = []
	var sold_extra := 0
	var extra_cash := 0
	var items: Array = lot["items"]
	var share := int(round(float(price) / float(maxi(1, items.size()))))
	for it in items:
		it["paid"] = share
		if free_slots() > 0:
			shelf.append(it)
			kept.append(it)
		else:
			var c := maxi(1, int(round(market_value(it) * Balance.OVERFLOW_SELL)))
			extra_cash += c
			sold_extra += 1
	cash += extra_cash
	var total := 0
	for it in items:
		total += market_value(it)
	var msg := "Lot worth $%d!" % total
	if sold_extra > 0:
		msg += " No room: sold %d extra for $%d." % [sold_extra, extra_cash]
	var res := _ok(msg)
	res["items"] = items
	res["worth"] = total
	return res


func sell_rate() -> float:
	if venue.is_empty():
		return 0.0
	return float(venue["sell"])


func sell_price(item: Dictionary) -> int:
	return maxi(1, int(round(market_value(item) * sell_rate())))


## How much an item's value has moved since you bought it.
func gain(item: Dictionary) -> int:
	return market_value(item) - int(item.get("paid", 0))


## Profit (or loss) if you sold it right here, right now. 0 where nobody buys.
func flip_now(item: Dictionary) -> int:
	if sell_rate() <= 0.0:
		return 0
	return sell_price(item) - int(item.get("paid", 0))


func sell(uid: int) -> Dictionary:
	if phase != Phase.VENUE or sell_rate() <= 0.0:
		return _fail("They don't buy here.")
	var i := _shelf_index(uid)
	if i < 0:
		return _fail("Not on your shelf.")
	var item: Dictionary = shelf[i]
	var price := sell_price(item)
	shelf.remove_at(i)
	cash += price
	var msg := "Sold %s for $%d." % [item["name"], price]
	msg += _record_sale(item, price)
	return _ok(msg)


func _record_sale(item: Dictionary, price: int) -> String:
	stats["sold"] += 1
	var flip := price - int(item["paid"])
	stats["profit"] += flip
	if flip > int(stats["best_flip"]):
		stats["best_flip"] = flip
		stats["best_flip_name"] = item["name"]
	if flip > 0 and has_perk("flipper"):
		cash += 3
		return " Flipper +$3."
	return ""


func dump(uid: int) -> Dictionary:
	var i := _shelf_index(uid)
	if i < 0:
		return _fail("Not on your shelf.")
	var item: Dictionary = shelf[i]
	shelf.remove_at(i)
	cash += Balance.DUMP_VALUE
	return _ok("Dumped %s for $%d." % [item["name"], Balance.DUMP_VALUE])


## Takes an item off the shelf for good (it goes to your permanent Wall).
func retire(uid: int) -> Dictionary:
	var i := _shelf_index(uid)
	if i < 0:
		return {}
	var item: Dictionary = shelf[i]
	shelf.remove_at(i)
	return item


func can_list() -> bool:
	return phase == Phase.VENUE and venue.has("list")


func list_item(uid: int) -> Dictionary:
	if not can_list():
		return _fail("Can't list here.")
	var i := _shelf_index(uid)
	if i < 0:
		return _fail("Not on your shelf.")
	var item: Dictionary = shelf[i]
	shelf.remove_at(i)
	listings.append(item)
	return _ok("Listed %s. Sells when the stop ends." % item["name"])


## What a listing of this item should net you here: [low, high] after fees.
func list_range(item: Dictionary) -> Array:
	var listed: Array = venue.get("list", [0.6, 1.5])
	var fee := float(venue.get("fee", 0.13))
	if boss_active("fees"):
		fee = 0.25
	var m := float(market_value(item))
	if has_perk("power_seller"):
		fee = 0.0
		m *= 1.15
	if boss_active("lowball"):
		m *= 0.6
	return [maxi(1, int(round(m * float(listed[0]) * (1.0 - fee)))), maxi(1, int(round(m * float(listed[1]) * (1.0 - fee))))]


func unlist(uid: int) -> Dictionary:
	for i in listings.size():
		if int(listings[i]["uid"]) == uid:
			var item: Dictionary = listings[i]
			listings.remove_at(i)
			shelf.append(item)
			return _ok("Pulled %s back." % item["name"])
	return _fail("Not listed.")


func next_bid(index: int) -> int:
	var a: Dictionary = auctions[index]
	var base := maxi(int(a["bid"]), int(a["my_max"]))
	return int(ceil(base * Balance.BID_STEP)) + 1


func bid(index: int) -> Dictionary:
	if phase != Phase.VENUE or index < 0 or index >= auctions.size():
		return _fail("No such auction.")
	var a: Dictionary = auctions[index]
	var amount := next_bid(index)
	var extra := amount - int(a["my_max"])
	if cash < extra:
		return _fail("Need $%d." % extra)
	if int(a["my_max"]) == 0 and free_slots() <= 0:
		return _fail("No shelf space if you win.")
	cash -= extra  # held until the auction ends
	a["my_max"] = amount
	var rival := int(a["rival"])
	if amount >= rival:
		a["bid"] = mini(amount, rival + 1)
		return _ok("You're winning at $%d (your max $%d)." % [a["bid"], amount])
	a["bid"] = mini(rival, amount + 1)
	return _ok("Outbid! It's at $%d now." % a["bid"])


func winning(index: int) -> bool:
	var a: Dictionary = auctions[index]
	return int(a["my_max"]) > 0 and int(a["my_max"]) >= int(a["rival"])


func can_grade() -> bool:
	return phase == Phase.VENUE and bool(venue.get("grading", false))


func grade_cost(item: Dictionary) -> int:
	if has_perk("grader_buddy"):
		return 0
	return Balance.GRADE_FEE + int(round(market_value(item) * Balance.GRADE_FEE_SHARE))


func send_to_grading(uid: int) -> Dictionary:
	if not can_grade():
		return _fail("No grading here.")
	var i := _shelf_index(uid)
	if i < 0:
		return _fail("Not on your shelf.")
	var item: Dictionary = shelf[i]
	if int(item["grade"]) > 0:
		return _fail("Already graded.")
	if item["cond"] == "Damaged":
		return _fail("Repair it first.")
	var cost := grade_cost(item)
	if cash < cost:
		return _fail("Need $%d." % cost)
	cash -= cost
	shelf.remove_at(i)
	grading.append({"item": item, "returns_at": stops_played + 1})
	return _ok("Sent %s to grading. Back next stop." % item["name"])


func can_repair() -> bool:
	return phase == Phase.VENUE and bool(venue.get("repair", false))


func repair_cost(item: Dictionary) -> int:
	return Balance.REPAIR_FEE + int(round(float(item["base"]) * Balance.REPAIR_SHARE))


func repair(uid: int) -> Dictionary:
	if not can_repair():
		return _fail("No repairs here.")
	var i := _shelf_index(uid)
	if i < 0:
		return _fail("Not on your shelf.")
	var item: Dictionary = shelf[i]
	if item["cond"] != "Damaged":
		return _fail("Nothing to fix.")
	var cost := repair_cost(item)
	if cash < cost:
		return _fail("Need $%d." % cost)
	cash -= cost
	item["cond"] = "Loose"
	return _ok("Fixed up %s." % item["name"])


func _shelf_index(uid: int) -> int:
	for i in shelf.size():
		if int(shelf[i]["uid"]) == uid:
			return i
	return -1


func find_item(uid: int) -> Dictionary:
	var i := _shelf_index(uid)
	return shelf[i] if i >= 0 else {}


# ================================================================ ending a stop

## Settles auctions and listings, appraises the shelf and pays out.
## Returns {"passed", "appraisal", "events", "rewards"}.
func end_stop() -> Dictionary:
	if phase != Phase.VENUE:
		return _fail("Not at a venue.")
	var events: Array = []
	# Auctions you bid on.
	for a in auctions:
		var mine := int(a["my_max"])
		if mine <= 0:
			continue
		var rival := int(a["rival"])
		if rng.randf() < Balance.SNIPE_CHANCE:
			rival = int(round(rival * Balance.SNIPE_BOOST))
		var item: Dictionary = a["item"]
		if mine >= rival:
			var pay := mini(mine, rival + 1)
			cash += mine - pay
			item["paid"] = pay
			shelf.append(item)
			stats["bought"] += 1
			events.append("Won %s for $%d!" % [item["name"], pay])
		else:
			cash += mine
			events.append("Sniped on %s at the last second." % item["name"])
	# Your listings.
	var listed: Array = venue.get("list", [0.6, 1.5])
	var fee := float(venue.get("fee", 0.13))
	if boss_active("fees"):
		fee = 0.25
	if has_perk("power_seller"):
		fee = 0.0
	for item in listings:
		var sale := float(market_value(item)) * rng.randf_range(float(listed[0]), float(listed[1]))
		if has_perk("power_seller"):
			sale *= 1.15
		if boss_active("lowball"):
			sale *= 0.6
		var gross := maxi(1, int(round(sale)))
		var net := gross - int(round(gross * fee))
		cash += net
		var extra := _record_sale(item, net)
		events.append("%s sold for $%d (you keep $%d).%s" % [item["name"], gross, net, extra])
	listings.clear()
	# Appraise.
	var ap := appraise()
	last_appraisal = ap
	var passed := int(ap["total"]) >= target()
	stats["best_appraisal"] = maxi(int(stats["best_appraisal"]), int(ap["total"]))
	var rewards := {}
	if passed:
		var interest := mini(cash / Balance.INTEREST_PER, effective_interest_cap())
		var base := int(Balance.STOP_REWARD[stop]) + ante
		var tl := time_left * Balance.TIME_LEFT_REWARD
		rewards = {"base": base, "interest": interest, "time": tl, "total": base + interest + tl}
		var wp := want_progress()
		if not want.is_empty() and not bool(want["done"]) and int(wp[0]) >= int(wp[1]):
			want["done"] = true
			wants_done += 1
			rewards["want"] = int(want["reward"])
			rewards["total"] = int(rewards["total"]) + int(want["reward"])
		cash += int(rewards["total"])
		for it in shelf:
			it["held"] = int(it["held"]) + 1
		for g in grading:
			g["item"]["held"] = int(g["item"]["held"]) + 1
		phase = Phase.APPRAISAL
		if ante >= Balance.ANTES_TO_WIN and stop == 2 and not endless:
			phase = Phase.WON
	else:
		phase = Phase.OVER
	last_rewards = rewards
	changed.emit()
	return {"ok": true, "msg": "", "passed": passed, "appraisal": ap, "events": events, "rewards": rewards}


func effective_interest_cap() -> int:
	return interest_cap + (7 if has_perk("piggy_bank") else 0)


## After a passed appraisal: on to the next stop (or ante) and back Home.
func advance() -> void:
	if phase == Phase.WON:
		endless = true
	elif phase != Phase.APPRAISAL:
		return
	stop += 1
	if stop > 2:
		stop = 0
		ante += 1
		_roll_boss()
		_roll_want()
	_roll_trends()
	_prepare_home()
	_roll_event()


# ================================================================ appraisal

## Balatro-style: every item adds its value (chips), bonuses add or multiply Mult.
## Returns {"items": [{uid, name, value, notes}], "bonuses": [{label, add, times}],
##          "chips", "mult", "total"}.
func appraise() -> Dictionary:
	var items: Array = []
	var chips := 0
	var per_plat := {}
	var kinds := {}
	var add := 0.0
	var times := 1.0
	var bonuses: Array = []
	for it in shelf:
		var v := float(market_value(it))
		var notes: Array = []
		var cond := String(it["cond"])
		if cond == "CIB" and has_perk("box_and_manual"):
			v *= 1.5
			notes.append("Box & Manual x1.5")
		if (it["tags"] as Array).has("disc") and has_perk("disc_jockey"):
			v *= 2.0
			notes.append("Disc Jockey x2")
		if cond == "Sealed" and has_perk("plastic_wrap"):
			v *= 2.0
			notes.append("Plastic Wrap x2")
		if cond == "Damaged" and has_perk("dust_sheet"):
			v *= 2.5
			notes.append("Dust Sheet x2.5")
		if int(it["tier"]) == 0 and has_perk("nostalgia"):
			v *= 2.0
			notes.append("Nostalgia x2")
		if it["kind"] == "acc" and has_perk("lunchbox"):
			v *= 3.0
			notes.append("Lunchbox x3")
		if it["kind"] == "pack" and has_perk("pack_rat"):
			v *= 2.0
			notes.append("Pack Rat x2")
		if it["kind"] == "coin" and has_perk("gold_bug") and String(Catalog.get_def(String(it["id"])).get("metal", "")) == "gold":
			v *= 2.0
			notes.append("Gold Bug x2")
		if boss_active("picky") and (cond == "Damaged" or cond == "Loose"):
			v *= 0.5
			notes.append("Picky x0.5")
		if int(it["held"]) >= 3 and has_perk("glass_case"):
			v *= 1.5
			notes.append("Glass Case x1.5")
		if has_perk("sticker_gun"):
			v += 8.0
			notes.append("Sticker +$8")
		if has_perk("dollar_bin") and int(it.get("paid", 0)) <= 3:
			v += 10.0
			notes.append("Dollar Bin +$10")
		if String(it.get("variant", "Standard")) != "Standard":
			notes.append("%s x%s" % [Catalog.variant_label(it), str(snappedf(Catalog.variant_mult(it), 0.01))])
		var iv := maxi(0, int(round(v)))
		chips += iv
		items.append({"uid": it["uid"], "name": it["name"], "value": iv, "notes": notes})
		var p := String(it["plat"])
		if p != "MISC":
			per_plat[p] = int(per_plat.get(p, 0)) + 1
			if not kinds.has(p):
				kinds[p] = {}
			kinds[p][it["kind"]] = true
			if String(it["kind"]) == "coin":
				kinds[p]["d:" + String(Catalog.get_def(String(it["id"])).get("denom", ""))] = true
	# Sets.
	if not boss_active("skeptic"):
		var set_scale := 2.0 if has_perk("completionist") else 1.0
		for p in per_plat.keys():
			var n := int(per_plat[p])
			if n >= 3:
				var b := (1.0 if n >= 5 else 0.5) * set_scale
				add += b
				bonuses.append({"label": "%s Set (%d)" % [Catalog.platform(p)["short"], n], "add": b, "times": 1.0})
			var k: Dictionary = kinds[p]
			if k.has("console") and k.has("game") and k.has("acc"):
				times *= 1.5
				bonuses.append({"label": "%s Full Setup" % Catalog.platform(p)["short"], "add": 0.0, "times": 1.5})
			elif k.has("card") and k.has("pack") and n >= 3:
				times *= 1.5
				bonuses.append({"label": "%s Singles + Sealed" % Catalog.platform(p)["short"], "add": 0.0, "times": 1.5})
			elif k.has("coin"):
				var denoms := 0
				for kk in k:
					if String(kk).begins_with("d:"):
						denoms += 1
				if denoms >= 3:
					times *= 1.5
					bonuses.append({"label": "%s Type Set" % Catalog.platform(p)["short"], "add": 0.0, "times": 1.5})
	# Grails.
	var grails := 0
	var shiny := 0
	var consoles := 0
	var mint := 0
	var fun := 0
	var saga := 0
	for it in shelf:
		if int(it["tier"]) == 3:
			grails += 1
		if it["kind"] == "console":
			consoles += 1
		if ["Holo Foil", "Reverse Holo", "1st Edition", "Shadowless", "Proof-Like", "Deep Cameo", "Rainbow Toned"].has(String(it.get("variant", ""))):
			shiny += 1
		if it["cond"] == "Mint" or it["cond"] == "Sealed":
			mint += 1
		var fam := String(Catalog.platform(String(it["plat"]))["family"])
		if fam == "funtendo":
			fun += 1
		elif fam == "saga":
			saga += 1
	if grails > 0:
		var per := 1.0 + (2.0 if has_perk("whale") else 0.0)
		add += per * grails
		bonuses.append({"label": "GRAIL x%d" % grails, "add": per * grails, "times": 1.0})
	_perk_add(bonuses, "shrink_wrap", 0.5 * mint, "Shrink Wrap Fan")
	_perk_add(bonuses, "hoarder", 0.15 * shelf.size(), "Hoarder")
	_perk_add(bonuses, "funtendo_kid", 0.3 * fun, "Funtendo Kid")
	_perk_add(bonuses, "saga_does", 0.5 * saga, "Saga Does")
	_perk_add(bonuses, "console_wars", 1.0 * consoles, "Console Wars")
	var big_plats := 0
	for p in per_plat.keys():
		if int(per_plat[p]) >= 4:
			big_plats += 1
	_perk_add(bonuses, "full_page", 1.0 * big_plats, "Full Page")
	var slabs := 0
	for it in shelf:
		if int(it.get("grade", 0)) > 0:
			slabs += 1
	_perk_add(bonuses, "slab_fan", 0.75 * slabs, "Slab Fan")
	_perk_add(bonuses, "holo_hunter", 0.6 * shiny, "Shiny Hunter")
	var hot_n := 0
	var odd := 0
	for it in shelf:
		if hot.has(String(it["plat"])):
			hot_n += 1
		if String(it.get("variant", "Standard")) != "Standard":
			odd += 1
	_perk_add(bonuses, "hot_streak", 0.5 * hot_n, "Hot Streak")
	_perk_add(bonuses, "oddity_hunter", 0.4 * odd, "Oddity Hunter")
	_perk_add(bonuses, "haggle_king", 0.25 * int(stats.get("haggles", 0)), "Haggle King")
	for b in bonuses:
		if b["label"] in ["Shrink Wrap Fan", "Hoarder", "Funtendo Kid", "Saga Does", "Console Wars", "Shiny Hunter", "Full Page", "Slab Fan", "Hot Streak", "Oddity Hunter", "Haggle King"]:
			add += float(b["add"])
	if has_perk("curator") and per_plat.size() >= 5:
		times *= 2.0
		bonuses.append({"label": "Curator", "add": 0.0, "times": 2.0})
	if has_perk("cursed_cart"):
		times *= 2.0
		bonuses.append({"label": "Cursed Cartridge", "add": 0.0, "times": 2.0})
	var mult := (1.0 + add) * times
	var total := int(round(chips * mult))
	return {"items": items, "bonuses": bonuses, "chips": chips, "mult": snappedf(mult, 0.01), "total": total}


func _perk_add(bonuses: Array, id: String, amount: float, label: String) -> void:
	if has_perk(id) and amount > 0.0:
		bonuses.append({"label": label, "add": snappedf(amount, 0.01), "times": 1.0})


# ================================================================ the want list

const WANT_KINDS := {
	"games": ["plat", "plat", "setup", "mint", "rare", "graded", "acc", "worth"],
	"cards": ["plat", "plat", "pack", "mint", "rare", "graded", "shiny", "worth"],
	"coins": ["plat", "plat", "mint", "rare", "graded", "gold", "worth"],
}


## A new request from the Buyer for this ante, picked to be doable but not free.
func _roll_want() -> void:
	var kinds: Array = WANT_KINDS.get(market, WANT_KINDS["games"])
	var k := String(kinds[rng.randi_range(0, kinds.size() - 1)])
	if ante <= 1 and (k == "graded" or k == "rare"):
		k = "plat"
	var w := {"id": k, "plat": "", "n": 1, "worth": 0, "done": false, "ante": ante}
	match k:
		"plat":
			# Lean towards a platform you already own a piece of.
			var owned: Array = []
			for it in shelf:
				var p := String(it["plat"])
				if is_active_plat(p) and not WILDCARD_PLATS.has(p) and not owned.has(p):
					owned.append(p)
			w["plat"] = String(owned[rng.randi_range(0, owned.size() - 1)]) if not owned.is_empty() and rng.randf() < 0.6 else _random_platform(WILDCARD_PLATS)
			w["n"] = clampi(2 + ante / 3, 2, 4)
		"mint":
			w["n"] = 1 if ante < 4 else 2
		"acc":
			w["n"] = 2 if ante < 5 else 3
		"worth":
			w["worth"] = maxi(20, int(round(target() * 0.22 / 5.0)) * 5)
	w["reward"] = 4 + ante * 3
	want = w


## [have, need] for the current request on this shelf.
func want_progress() -> Array:
	if want.is_empty():
		return [0, 1]
	var have := 0
	var need := int(want.get("n", 1))
	match String(want["id"]):
		"setup":
			var kinds := {}
			for it in shelf:
				var p := String(it["plat"])
				if not kinds.has(p):
					kinds[p] = {}
				kinds[p][String(it["kind"])] = true
			for p in kinds:
				var kk: Dictionary = kinds[p]
				have = maxi(have, int(kk.has("console")) + int(kk.has("game")))
			need = 2
		_:
			for it in shelf:
				if wants(it):
					have += 1
	return [mini(have, need), need]


## True when this item counts towards the Buyer's request.
func wants(item: Dictionary) -> bool:
	if want.is_empty() or bool(want.get("done", false)):
		return false
	var cond := String(item.get("cond", ""))
	match String(want["id"]):
		"plat": return String(item["plat"]) == String(want["plat"])
		"setup": return String(item["kind"]) == "console" or String(item["kind"]) == "game"
		"mint": return cond == "Mint" or cond == "Sealed"
		"rare": return int(item["tier"]) >= 2
		"graded": return int(item.get("grade", 0)) > 0
		"acc": return String(item["kind"]) == "acc"
		"pack": return String(item["kind"]) == "pack"
		"shiny": return ["Holo Foil", "Reverse Holo", "1st Edition", "Shadowless"].has(String(item.get("variant", "")))
		"gold": return String(Catalog.get_def(String(item["id"])).get("metal", "")) == "gold"
		"worth": return market_value(item) >= int(want["worth"])
	return false


## What the Buyer is asking for, in a few words.
func want_text() -> String:
	if want.is_empty():
		return ""
	var n := int(want.get("n", 1))
	match String(want["id"]):
		"plat": return "%d %s pieces" % [n, Catalog.platform(String(want["plat"]))["short"]]
		"setup": return "a console + a game for it"
		"mint": return ("something Mint or Sealed" if n == 1 else "%d Mint or Sealed pieces" % n)
		"rare": return "anything Rare or better"
		"graded": return "a graded slab"
		"acc": return "%d accessories" % n
		"pack": return "a sealed pack or box"
		"shiny": return "a shiny card (holo / 1st Ed.)"
		"gold": return "a gold coin"
		"worth": return "one piece worth $%d+" % int(want["worth"])
	return ""


## The Buyer's note that goes with the request (story flavour).
func want_note() -> String:
	return Flavor.pick(Flavor.WANT_NOTES.get(String(want.get("id", "")), Flavor.WANT_NOTES["plat"]), seed_value + ante)


# ================================================================ doorbell

const EVENT_CHANCE := 0.55
const BOX_CONDS := [15, 45, 25, 10, 5]


## Maybe someone knocks while you're home between stops. Arlo's diary pages
## turn up regularly (one every few stops) until all eight are found.
func _roll_event() -> void:
	event = {}
	if stop == 0 or endless:
		return
	var diary_due := diary_read < Flavor.DIARY.size() and diary_read < ante and rng.randf() < 0.6
	if not diary_due and rng.randf() > EVENT_CHANCE:
		return
	if diary_due:
		event = {"id": "diary", "page": diary_read, "cash": 4 + ante * 2}
		return
	var kinds := ["box", "box", "trade", "collector", "leak"]
	for tries in 6:
		var k: String = kinds[rng.randi_range(0, kinds.size() - 1)]
		match k:
			"box":
				var it := roll_item(1, BOX_CONDS)
				it["variant"] = Catalog.roll_variant(Catalog.get_def(String(it["id"])), rng, {"slot": "hunt"})
				var price := maxi(2, int(round(market_value(it) * rng.randf_range(0.35, 1.15))))
				if price <= cash:
					event = {"id": "box", "item": it, "price": price}
					return
			"trade":
				if shelf.size() >= 2:
					var worst: Dictionary = shelf[0]
					for s in shelf:
						if market_value(s) < market_value(worst):
							worst = s
					var theirs := roll_item(1, [5, 40, 35, 15, 5])
					event = {"id": "trade", "item": theirs, "give": int(worst["uid"])}
					return
			"collector":
				var pool: Array = shelf.filter(func(s): return market_value(s) >= 10)
				if not pool.is_empty():
					var pick: Dictionary = pool[rng.randi_range(0, pool.size() - 1)]
					event = {"id": "collector", "give": int(pick["uid"]), "price": int(round(market_value(pick) * rng.randf_range(1.3, 1.7)))}
					return
			"leak":
				var wet: Array = shelf.filter(func(s): return s["cond"] == "Loose" or s["cond"] == "CIB")
				if not wet.is_empty():
					var pick2: Dictionary = wet[rng.randi_range(0, wet.size() - 1)]
					var fee := maxi(3, int(round(market_value(pick2) * 0.3)))
					if fee <= cash:
						event = {"id": "leak", "give": int(pick2["uid"]), "price": fee}
						return


## Say yes to whoever's at the door.
func event_accept() -> Dictionary:
	if event.is_empty() or phase != Phase.HOME:
		return _fail("Nobody's there.")
	var e := event
	match String(e["id"]):
		"diary":
			diary_read += 1
			cash += int(e["cash"])
			event = {}
			return _ok("Tucked in the page: $%d in old bills." % int(e["cash"]))
		"box":
			if cash < int(e["price"]):
				return _fail("Need $%d." % int(e["price"]))
			if free_slots() <= 0:
				return _fail("Shelf's full. Make room first.")
			cash -= int(e["price"])
			var it: Dictionary = e["item"]
			it["paid"] = int(e["price"])
			shelf.append(it)
			stats["bought"] += 1
			event = {}
			var res := _ok("Inside: %s (worth $%d)." % [it["name"], market_value(it)])
			res["item"] = it
			return res
		"trade":
			var i := _shelf_index(int(e["give"]))
			if i < 0:
				event = {}
				return _fail("You don't have that anymore.")
			var mine: Dictionary = shelf[i]
			var theirs: Dictionary = e["item"]
			theirs["paid"] = int(mine["paid"])
			shelf[i] = theirs
			event = {}
			var r2 := _ok("Swapped %s for %s." % [mine["name"], theirs["name"]])
			r2["item"] = theirs
			return r2
		"collector":
			var j := _shelf_index(int(e["give"]))
			if j < 0:
				event = {}
				return _fail("You don't have that anymore.")
			var sold: Dictionary = shelf[j]
			shelf.remove_at(j)
			cash += int(e["price"])
			var extra := _record_sale(sold, int(e["price"]))
			event = {}
			return _ok("Sold %s for $%d.%s" % [sold["name"], int(e["price"]), extra])
		"leak":
			if cash < int(e["price"]):
				return _fail("Need $%d." % int(e["price"]))
			cash -= int(e["price"])
			event = {}
			return _ok("Tarp's up. Everything stays dry.")
	return _fail("?")


## Say no (or shut the door).
func event_decline() -> Dictionary:
	if event.is_empty():
		return _fail("Nobody's there.")
	var e := event
	event = {}
	if String(e["id"]) == "leak":
		var i := _shelf_index(int(e["give"]))
		if i >= 0:
			shelf[i]["cond"] = "Damaged"
			return _ok("Drip. Drip. %s is Damaged now." % shelf[i]["name"])
	if String(e["id"]) == "diary":
		diary_read += 1
	return _ok("You close the door.")


# ================================================================ the curse

## When you come up short you get boxed and graded: the closer you came to
## the target, the better your condition. Returns {"grade", "cond", "ratio"}.
func curse_grade() -> Dictionary:
	var total := int(last_appraisal.get("total", 0))
	var ratio := clampf(float(total) / maxf(1.0, float(target())), 0.0, 1.0)
	var g := clampf(snappedf(1.0 + ratio * ratio * 8.8, 0.5), 1.0, 9.8)
	if ratio >= 0.95:
		g = 9.8
	var cond := "DAMAGED"
	if ratio >= 0.9:
		cond = "MINT"
	elif ratio >= 0.7:
		cond = "COMPLETE IN BOX"
	elif ratio >= 0.4:
		cond = "LOOSE"
	return {"grade": ("%.1f" % g), "cond": cond, "ratio": ratio}


# ================================================================ helpers

func _ok(msg: String) -> Dictionary:
	changed.emit()
	return {"ok": true, "msg": msg}


func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}
