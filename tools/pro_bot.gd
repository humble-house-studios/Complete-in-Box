extends RefCounted
## A stronger bot that plays like a decent human: it reads true values (as if
## it knew the market), buys what is underpriced, keeps the shelf's best items,
## turns spare junk into cash where someone pays, lists online, bids on
## auctions, grades its best pieces and buys perks that fit its shelf.
## Used by the balance sim ("SIM pro") to check that a good player can win.

var run: Run
var rng := RandomNumberGenerator.new()
var pivots := true

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
	_shop_home()
	run.enter_venue(_pick_venue())
	_play_venue()
	return run.end_stop()


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
