extends RefCounted
## A simple greedy player, used by the balance sim and the smoke tests.
## Buys anything priced under what it (thinks it) is worth, haggles pricey
## stuff, digs while it has spare Time, and grabs affordable perks.

var run: Run
var rng := RandomNumberGenerator.new()
## Take the card / coin market flips when they're offered.
var pivots := true


func _init(r: Run, seed_value: int = 1) -> void:
	run = r
	rng.seed = seed_value


func _guess(o: Dictionary) -> float:
	if run.shows_exact():
		return float(run.market_value(o["item"]))
	var est: Array = o["est"]
	return (float(est[0]) + float(est[1])) * 0.5


## Plays from Home through the stop's appraisal. Returns end_stop()'s result.
func play_stop() -> Dictionary:
	if pivots and run.pivot_offer() != "":
		run.pivot(run.pivot_offer())
	_shop_home()
	var choice: String = run.venue_choices[rng.randi_range(0, run.venue_choices.size() - 1)]
	run.enter_venue(choice)
	_play_venue()
	return run.end_stop()


## Plays a whole run. Returns {"ante", "stop", "won", "appraisal"}.
func play_run(max_stops: int = 40) -> Dictionary:
	for i in max_stops:
		play_stop()
		if run.phase == Run.Phase.OVER or run.phase == Run.Phase.WON:
			break
		run.advance()
	return {"ante": run.ante, "stop": run.stop, "won": run.phase == Run.Phase.WON,
		"appraisal": int(run.last_appraisal.get("total", 0))}


func _shop_home() -> void:
	for pid in run.perk_offers.duplicate():
		var cost := int(Perks.get_def(pid)["cost"])
		if run.perks.size() < run.perk_cap and run.cash - cost >= 6:
			run.buy_perk(pid)
	if not run.upgrade_offer.is_empty() and run.cash - int(run.upgrade_offer["cost"]) >= 12:
		run.buy_upgrade()


func _play_venue() -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		if not _step():
			break
	# Lots.
	for i in run.lots.size():
		if not bool(run.lots[i]["bought"]) and run.cash >= int(run.lots[i]["price"]) and run.free_slots() >= 2:
			run.buy_lot(i)
	# Auctions: bid up to market value.
	for i in run.auctions.size():
		var mv := run.market_value(run.auctions[i]["item"])
		var tries := 0
		while tries < 8 and not run.winning(i) and run.next_bid(i) <= mv and run.cash >= run.next_bid(i) - int(run.auctions[i]["my_max"]):
			run.bid(i)
			tries += 1
	# Grade the best ungraded item if we can afford it and are comfortably ahead.
	if run.can_grade():
		var ap := int(run.appraise()["total"])
		if ap > run.target() * 1.4:
			var best := {}
			for it in run.shelf:
				if int(it["grade"]) == 0 and it["cond"] != "Damaged" and (best.is_empty() or run.market_value(it) > run.market_value(best)):
					best = it
			if not best.is_empty() and run.cash >= run.grade_cost(best) + 5:
				run.send_to_grading(int(best["uid"]))


## One decision. False when there's nothing worth doing.
func _step() -> bool:
	# Best value buy.
	var best_i := -1
	var best_gain := 0.0
	for i in run.stock.size():
		var o: Dictionary = run.stock[i]
		var gain := _guess(o) - float(o["price"])
		if int(o["price"]) <= run.cash and gain > best_gain:
			best_gain = gain
			best_i = i
	if best_i >= 0:
		if run.free_slots() > 0:
			run.buy(best_i)
			return true
		var worst := _worst_item()
		if not worst.is_empty() and run.market_value(worst) < _guess(run.stock[best_i]) * 0.7:
			if run.sell_rate() > 0.0:
				run.sell(int(worst["uid"]))
			else:
				run.dump(int(worst["uid"]))
			return true
	# Haggle something we'd like but can't justify.
	if run.time_left > 0 and float(run.venue["haggle"]) > 0.0:
		for i in run.stock.size():
			var o: Dictionary = run.stock[i]
			if not bool(o["haggled"]) and float(o["price"]) < _guess(o) * 1.3:
				run.haggle(i)
				return true
	# Dig with spare Time.
	if run.time_left > 1 and int(run.venue["dig"]) > 0 and run.free_slots() > 0:
		run.dig()
		return true
	return false


func _worst_item() -> Dictionary:
	var worst := {}
	for it in run.shelf:
		if worst.is_empty() or run.market_value(it) < run.market_value(worst):
			worst = it
	return worst
