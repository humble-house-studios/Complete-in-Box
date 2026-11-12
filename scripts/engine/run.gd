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
var last_rewards: Dictionary = {}
var stats := {"bought": 0, "sold": 0, "best_flip": 0, "best_flip_name": "", "best_appraisal": 0, "profit": 0}

var _uid: int = 0


# ================================================================ setup

func start(p_seed: int = 0) -> void:
	seed_value = p_seed if p_seed != 0 else randi()
	rng.seed = seed_value
	phase = Phase.HOME
	ante = 1
	stop = 0
	_pick_active_platforms()
	for i in Balance.STARTER_ITEMS:
		var it := make_item(_pick_def(0), "Loose")
		it["paid"] = 0
		shelf.append(it)
	rumor = _random_platform()
	_roll_trends()
	_roll_boss()
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
	return Balance.target(ante, stop)


func is_boss_stop() -> bool:
	return stop == 2


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
func _pick_active_platforms() -> void:
	var counts := {}
	for d in Catalog.ITEMS:
		counts[d["plat"]] = int(counts.get(d["plat"], 0)) + 1
	var pool: Array = []
	for p in Catalog.PLATFORMS.keys():
		if not WILDCARD_PLATS.has(p) and int(counts.get(p, 0)) >= 8:
			pool.append(p)
	active_plats.clear()
	while active_plats.size() < mini(Balance.ACTIVE_PLATFORMS, pool.size()):
		var p: String = pool[rng.randi_range(0, pool.size() - 1)]
		if not active_plats.has(p):
			active_plats.append(p)


func is_active_plat(p: String) -> bool:
	return active_plats.is_empty() or active_plats.has(p) or WILDCARD_PLATS.has(p)


func _random_platform(exclude: Array = []) -> String:
	var options: Array = []
	for p in (active_plats if not active_plats.is_empty() else Catalog.PLATFORMS.keys()):
		if p != "MISC" and not exclude.has(p):
			options.append(p)
	return String(options[rng.randi_range(0, options.size() - 1)])


func _roll_boss() -> void:
	boss_id = String(Venues.BOSSES[rng.randi_range(0, Venues.BOSSES.size() - 1)]["id"])


# ================================================================ rolling stock

func _pick_def(tier: int) -> Dictionary:
	var pool := _active_pool(tier)
	while pool.is_empty() and tier > 0:
		tier -= 1
		pool = _active_pool(tier)
	return pool[rng.randi_range(0, pool.size() - 1)]


func _active_pool(tier: int) -> Array:
	var out: Array = []
	for d in Catalog.defs_of_tier(tier):
		if is_active_plat(String(d["plat"])):
			out.append(d)
	return out


func _roll_tier(boost: int) -> int:
	var w: Array = Balance.tier_weights(ante + boost)
	return _weighted(w)


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
	it["variant"] = Catalog.roll_variant(def, rng)
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
	var open := Venues.unlocked(Venues.SLOTS[stop], ante)
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
		if not perks.has(p["id"]):
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
	return _ok("Got %s." % Perks.get_def(id)["name"])


func sell_perk(id: String) -> Dictionary:
	if not perks.has(id):
		return _fail("You don't have that.")
	var back := int(Perks.get_def(id)["cost"]) / 2
	perks.erase(id)
	cash += back
	if id == "moms_basement":
		shelf_cap -= 2
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


# ================================================================ venue

func enter_venue(id: String) -> Dictionary:
	if phase != Phase.HOME:
		return _fail("Not at home.")
	if not venue_choices.has(id):
		return _fail("Can't go there now.")
	venue = Venues.get_def(id)
	phase = Phase.VENUE
	stops_played += 1
	time_left = int(venue["time"]) + time_bonus + (1 if has_perk("extra_hour") else 0)
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
	_roll_trends()
	_prepare_home()


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
		if int(it["tier"]) == 0 and has_perk("nostalgia"):
			v *= 2.0
			notes.append("Nostalgia x2")
		if it["kind"] == "acc" and has_perk("lunchbox"):
			v *= 3.0
			notes.append("Lunchbox x3")
		if boss_active("picky") and (cond == "Damaged" or cond == "Loose"):
			v *= 0.5
			notes.append("Picky x0.5")
		if has_perk("sticker_gun"):
			v += 8.0
			notes.append("Sticker +$8")
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
	# Grails.
	var grails := 0
	var consoles := 0
	var mint := 0
	var fun := 0
	var saga := 0
	for it in shelf:
		if int(it["tier"]) == 3:
			grails += 1
		if it["kind"] == "console":
			consoles += 1
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
	for b in bonuses:
		if b["label"] in ["Shrink Wrap Fan", "Hoarder", "Funtendo Kid", "Saga Does", "Console Wars"]:
			add += float(b["add"])
	if has_perk("curator") and per_plat.size() >= 5:
		times *= 2.0
		bonuses.append({"label": "Curator", "add": 0.0, "times": 2.0})
	var mult := (1.0 + add) * times
	var total := int(round(chips * mult))
	return {"items": items, "bonuses": bonuses, "chips": chips, "mult": snappedf(mult, 0.01), "total": total}


func _perk_add(bonuses: Array, id: String, amount: float, label: String) -> void:
	if has_perk(id) and amount > 0.0:
		bonuses.append({"label": label, "add": snappedf(amount, 0.01), "times": 1.0})


# ================================================================ helpers

func _ok(msg: String) -> Dictionary:
	changed.emit()
	return {"ok": true, "msg": msg}


func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}
