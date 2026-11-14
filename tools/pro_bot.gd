extends RefCounted
## A stronger bot that plays like a decent human: it reads true values (as if
## it knew the market), buys what is underpriced, keeps the shelf's best items,
## turns spare junk into cash where someone pays, lists online, bids on
## auctions, grades its best pieces and buys perks that fit its shelf.
## Used by the balance sim ("SIM pro") to check that a good player can win.

var run: Run
var rng := RandomNumberGenerator.new()
var pivots := true
## The Home extras (off by default so "SIM pro" stays the same yardstick).
var use_supplies := false
var use_bags := false
var use_calls := false
## Balance probes: always take this deal when it's offered (and no other).
var force_call := ""
var only_supply := ""
var ban_call := ""
const SUPPLY_LIKES := ["spotlight", "cleaning_kit", "copier", "energy", "gift_card", "flyer", "lucky_penny"]

## Perks it likes, best first (mult and economy that work with any shelf).
const LIKES := ["price_guide", "curator", "completionist", "hoarder", "sticker_gun", "box_and_manual",
	"nostalgia", "moms_basement", "extra_hour", "whale", "shrink_wrap", "slab_fan", "full_page",
	"coupon", "silver_tongue", "power_seller", "flipper", "piggy_bank", "time_capsule", "grader_buddy",
	"lucky_lots", "early_bird", "holo_hunter", "console_wars"]


func _init(r: Run, seed_value: int = 1) -> void:
	run = r
	rng.seed = seed_value


func play_run(max_stops: int = 40) -> Dictionary:
	for i in max_stops:
		play_stop()
		if run.phase == Run.Phase.OVER or run.phase == Run.Phase.WON:
			break
		run.advance()
	return {"ante": run.ante, "stop": run.stop, "won": run.phase == Run.Phase.WON,
		"appraisal": int(run.last_appraisal.get("total", 0))}


func play_stop() -> Dictionary:
	if pivots and run.pivot_offer() != "":
		# Only flip markets when the shelf is weak for what's coming.
		if run.pivot_value() > 0 and score() < run.target() * 1.2:
			run.pivot(run.pivot_offer())
	if use_calls or force_call != "":
		_answer_call()
	_shop_home()
	if use_bags:
		_grab_bag()
	if use_supplies:
		_buy_supplies()
		_use_supplies_home()
	run.enter_venue(_pick_venue())
	if use_supplies:
		_use_supplies_venue()
	_play_venue()
	if use_supplies and run.supplies.has("spotlight") and score() < run.target() * 1.5:
		run.use_supply("spotlight")
	return run.end_stop()


# ---------------------------------------------------------------- home extras

func _reserve() -> int:
	return 8 + run.ante * 3


func _buy_supplies() -> void:
	for sid in SUPPLY_LIKES:
		if only_supply != "" and sid != only_supply:
			continue
		if run.supply_offers.has(sid) and run.supplies.size() < Balance.POCKET_SLOTS and run.cash - int(Perks.supply(sid)["cost"]) >= _reserve():
			run.buy_supply(sid)


## Best shelf target for a supply by score gained (tries it on a copy of the state).
func _best_target(id: String) -> Dictionary:
	var best := {}
	var best_gain := 0
	var now := score()
	for it in run.supply_targets(id):
		var gain := 0
		match id:
			"cleaning_kit":
				var c := String(it["cond"])
				it["cond"] = Catalog.CONDITIONS[Catalog.CONDITIONS.find(c) + 1]
				gain = score() - now
				it["cond"] = c
			"copier":
				gain = _score_with(it.duplicate(true)) - now
			"flyer":
				var p := String(it["plat"])
				var was_cold := run.cold.has(p)
				run.hot.append(p)
				run.cold.erase(p)
				gain = score() - now
				run.hot.erase(p)
				if was_cold:
					run.cold.append(p)
		if gain > best_gain:
			best_gain = gain
			best = it
	return best


func _use_supplies_home() -> void:
	for sid in ["cleaning_kit", "copier", "flyer"]:
		while run.supplies.has(sid) and run.supply_block(sid) == "":
			var t := _best_target(sid)
			if t.is_empty() or not bool(run.use_supply(sid, int(t["uid"]))["ok"]):
				break


func _use_supplies_venue() -> void:
	if run.supplies.has("energy"):
		run.use_supply("energy")
	if run.supplies.has("lucky_penny") and run.supply_block("lucky_penny") == "":
		run.use_supply("lucky_penny")
	if run.supplies.has("gift_card"):
		for o in run.stock:
			if int(o["price"]) >= 12 and int(o["price"]) / 2 <= run.cash:
				run.use_supply("gift_card")
				break


func _grab_bag() -> void:
	var b := run.bag_offer
	if b.is_empty():
		return
	if not bool(b["open"]):
		if run.cash - int(b["cost"]) < _reserve():
			return
		match String(b["id"]):
			"items":
				if run.free_slots() <= 0 and run.shelf.size() <= 3:
					return
			"supplies":
				if not use_supplies or run.supplies.size() >= Balance.POCKET_SLOTS:
					return
			"perks":
				if run.perks.size() >= run.perk_cap:
					return
		if not bool(run.buy_bag()["ok"]):
			return
	var picks: Array = run.bag_offer["picks"]
	var pick := 0
	match String(run.bag_offer["id"]):
		"items":
			var now := score()
			var best_gain := -999999999
			for i in picks.size():
				var g := (_score_with(picks[i]) if run.free_slots() > 0 else _score_with(picks[i], _worst())) - now
				if g > best_gain:
					best_gain = g
					pick = i
			if best_gain <= 0:
				run.bag_pick(-1)
				return
			if run.free_slots() <= 0:
				run.dump(int(_worst()["uid"]))
		"supplies":
			var br := 99
			for i in picks.size():
				var r := SUPPLY_LIKES.find(String(picks[i]))
				if r >= 0 and r < br:
					br = r
					pick = i
		"perks":
			var bp := 999
			for i in picks.size():
				var r2 := LIKES.find(String(picks[i]))
				if r2 < 0:
					r2 = 50
				if r2 < bp:
					bp = r2
					pick = i
	if not bool(run.bag_pick(pick)["ok"]):
		run.bag_pick(-1)


## How good a deal looks: > 0 = take it. Tries the shelf-changing ones for real.
func _call_value(id: String) -> float:
	var now := float(maxi(1, score()))
	var lead := now / float(maxi(1, run.target()))
	match id:
		"perk_slot": return 3.0
		"static": return 2.5
		"bulk_buyer": return 2.0
		"prize": return 1.8 if run.bag_offer.is_empty() or not bool(run.bag_offer.get("open", false)) else 0.0
		"night_owl": return 1.5
		"wide_shelf": return 1.2 if run.free_slots() <= 1 else 0.4
		"sealed_fate":
			var perk_add := 0.0
			for b in run.appraise()["bonuses"]:
				if b.get("perk", false):
					perk_add += float(b["add"])
			return perk_add - 0.6 if run.perks.size() < run.perk_cap else perk_add - 1.2
		"specialist":
			run.call_plat = run.call_plat_pick()
			var s := float(score())
			run.call_plat = ""
			return (s / now - 1.2) * 5.0
		"condition_snob":
			run.calls.append(id)
			var s2 := float(score())
			run.calls.erase(id)
			return (s2 / now - 1.2) * 5.0
		"collateral":
			var best := run.call_best_item()
			if best.is_empty():
				return -1.0
			return (float(_score_without(best)) * 1.5 / now - 1.1) * 5.0
		"advance": return 1.0 if lead > 1.8 else -1.0
		"double_nothing": return 0.8 if lead > 2.0 else -1.0
	return -1.0


func _answer_call() -> void:
	if run.call_offer.is_empty():
		return
	if force_call != "":
		if run.call_offer.has(force_call):
			run.call_take(force_call)
		else:
			run.call_hangup()
		return
	var best := ""
	var best_v := 0.0
	for id in run.call_offer:
		if String(id) == ban_call:
			continue
		var v := _call_value(String(id))
		if v > best_v:
			best_v = v
			best = String(id)
	if best != "":
		run.call_take(best)
		if best == "prize":
			_grab_bag()
	else:
		run.call_hangup()


func score() -> int:
	return int(run.appraise()["total"])


func _score_with(item: Dictionary, without: Dictionary = {}) -> int:
	var keep := run.shelf.duplicate()
	if not without.is_empty():
		run.shelf.erase(without)
	run.shelf.append(item)
	var s := score()
	run.shelf = keep
	return s


func _score_without(item: Dictionary) -> int:
	var keep := run.shelf.duplicate()
	run.shelf.erase(item)
	var s := score()
	run.shelf = keep
	return s


func _pick_venue() -> String:
	var best := ""
	var best_v := -1.0
	for id in run.venue_choices:
		var d := Venues.get_def(String(id))
		var v := float(d["tier_boost"]) * 2.0 + float(d["time"]) + float(d["stock"]) * 0.3 + float(d.get("sell", 0.0)) * 3.0
		if d["slot"] == "hunt":
			v += (1.0 - float(d["price"][0])) * 3.0
		if v > best_v:
			best_v = v
			best = String(id)
	return best


func _shop_home() -> void:
	# Perks: fill slots with liked ones while keeping some buying money.
	var reserve := 8 + run.ante * 3
	for pass_i in 2:
		var picked := ""
		var best_rank := 999
		for pid in run.perk_offers:
			var r := LIKES.find(String(pid))
			if r < 0:
				r = 50
			var cost := int(Perks.get_def(String(pid))["cost"])
			if r < best_rank and run.cash - cost >= reserve:
				best_rank = r
				picked = String(pid)
		if picked == "" or best_rank >= 50:
			break
		if run.perks.size() >= run.perk_cap:
			# Swap out the least liked perk if this one is clearly better.
			var worst := ""
			var worst_r := -1
			for p in run.perks:
				var r2 := LIKES.find(String(p))
				if r2 < 0:
					r2 = 60
				if r2 > worst_r:
					worst_r = r2
					worst = String(p)
			if worst_r > best_rank + 6:
				run.sell_perk(worst)
			else:
				break
		run.buy_perk(picked)
	if not run.upgrade_offer.is_empty():
		var uid := String(run.upgrade_offer["id"])
		if uid in ["shelf", "time", "perk_slot"] and run.cash - int(run.upgrade_offer["cost"]) >= reserve:
			run.buy_upgrade()


func _worst() -> Dictionary:
	var worst := {}
	var worst_loss := 1 << 30
	var now := score()
	for it in run.shelf:
		var loss := now - _score_without(it)
		if loss < worst_loss:
			worst_loss = loss
			worst = it
	return worst


func _free_one() -> bool:
	var w := _worst()
	if w.is_empty():
		return false
	if run.sell_rate() > 0.0:
		run.sell(int(w["uid"]))
	else:
		run.dump(int(w["uid"]))
	return true


func _play_venue() -> void:
	var guard := 0
	while guard < 80:
		guard += 1
		if not _step():
			break
	# Lots: buy when the price is fair for what's shown, with room.
	for i in run.lots.size():
		var l: Dictionary = run.lots[i]
		var worth := 0
		for it in l["items"]:
			worth += run.market_value(it)
		if not bool(l["bought"]) and run.cash >= int(l["price"]) and worth > int(l["price"]) * 1.2 and run.free_slots() >= 2:
			run.buy_lot(i)
	# Auctions: bid up to 90% of value.
	for i in run.auctions.size():
		var mv := run.market_value(run.auctions[i]["item"])
		var tries := 0
		while tries < 10 and not run.winning(i) and run.next_bid(i) <= mv * 0.95 and run.cash - 4 >= run.next_bid(i) - int(run.auctions[i]["my_max"]) and (run.free_slots() > 0 or int(run.auctions[i]["my_max"]) > 0):
			run.bid(i)
			tries += 1
	# Grading: send the best ungraded item when well ahead.
	if run.can_grade() and score() > run.target() * 1.6:
		var best := {}
		for it in run.shelf:
			if int(it["grade"]) == 0 and it["cond"] != "Damaged" and (best.is_empty() or run.market_value(it) > run.market_value(best)):
				best = it
		if not best.is_empty() and run.market_value(best) >= 40 and run.cash >= run.grade_cost(best) + 5 and _score_without(best) >= run.target() * 1.1:
			run.send_to_grading(int(best["uid"]))
	# Online: list weak items for cash if the shelf still clears the bar.
	if run.can_list():
		for k in 3:
			var w := _worst()
			if w.is_empty() or run.shelf.size() <= 3:
				break
			if _score_without(w) >= run.target() * 1.15 and int(w["paid"]) <= run.market_value(w):
				run.list_item(int(w["uid"]))
			else:
				break


func _step() -> bool:
	var now := score()
	var behind := now < run.target()
	# Best buy by score gained per dollar, among clearly underpriced items
	# (or anything that helps when behind).
	var best_i := -1
	var best_val := 0.0
	for i in run.stock.size():
		var o: Dictionary = run.stock[i]
		var price := int(o["price"])
		if price > run.cash:
			continue
		var mv := float(run.market_value(o["item"]))
		var margin := mv / maxf(1.0, float(price))
		var gain: int
		if run.free_slots() > 0:
			gain = _score_with(o["item"]) - now
		else:
			gain = _score_with(o["item"], _worst()) - now
		if gain <= 0:
			continue
		if margin < 1.15 and not behind:
			continue
		var v := float(gain) / float(price) * (1.0 + margin)
		if v > best_val:
			best_val = v
			best_i = i
	if best_i >= 0:
		if run.free_slots() <= 0:
			_free_one()
		if run.free_slots() > 0:
			run.buy(best_i)
			return true
	# Haggle items that would be good buys at a lower price.
	if run.time_left > 0 and float(run.venue["haggle"]) > 0.0:
		for i in run.stock.size():
			var o: Dictionary = run.stock[i]
			var mv2 := float(run.market_value(o["item"]))
			if not bool(o["haggled"]) and float(o["price"]) <= mv2 * 1.2 and float(o["price"]) > mv2 * 0.7 and int(o["price"]) * 0.8 <= run.cash:
				run.haggle(i)
				return true
	# Sell junk at shops when it funds better buys (keep the bar cleared).
	if run.time_left > 1 and int(run.venue["dig"]) > 0:
		run.dig()
		return true
	return false
