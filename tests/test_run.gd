extends GutTest
## Rules of the run: data sanity, market math, venues, appraisal, flow.

const Bot := preload("res://tools/bot.gd")


func _new_run(seed_value: int = 42) -> Run:
	var r := Run.new()
	r.start(seed_value)
	return r


func _item(r: Run, id: String, cond: String = "Loose") -> Dictionary:
	return r.make_item(Catalog.get_def(id), cond)


# ---------------------------------------------------------------- data

func test_catalog_is_sane() -> void:
	var ids := {}
	for d in Catalog.ITEMS:
		assert_false(ids.has(d["id"]), "duplicate id " + d["id"])
		ids[d["id"]] = true
		assert_true(Catalog.PLATFORMS.has(d["plat"]), "bad platform on " + d["id"])
		assert_true(["game", "console", "acc", "misc", "card", "pack", "coin"].has(d["kind"]), "bad kind on " + d["id"])
		assert_between(int(d["tier"]), 0, 3)
		assert_gt(int(d["base"]), 0)
	for t in 4:
		assert_gt(Catalog.defs_of_tier(t).size(), 0, "tier %d has items" % t)


func test_every_perk_and_venue_has_what_the_ui_needs() -> void:
	for p in Perks.LIST:
		for k in ["id", "name", "cost", "desc"]:
			assert_true(p.has(k), "%s missing %s" % [p.get("id", "?"), k])
	for v in Venues.LIST:
		for k in ["id", "name", "slot", "unlock", "time", "stock", "price", "exact", "tier_boost", "cond", "haggle", "dig", "sell", "lots", "color"]:
			assert_true(v.has(k), "%s missing %s" % [v["id"], k])
		assert_eq((v["cond"] as Array).size(), Catalog.CONDITIONS.size())
	for slot in Venues.SLOTS:
		for m in ["cards", "coins"]:
			assert_gt(Venues.unlocked(slot, 5, m).size(), 0, "%s has a %s venue" % [m, slot])
		assert_eq(Venues.unlocked(slot, 1).size(), 1, "one %s venue at ante 1" % slot)
		assert_gt(Venues.unlocked(slot, 8).size(), 1, "more %s venues later" % slot)


func test_targets_climb() -> void:
	var last := 0
	for ante in range(1, 11):
		for stop in 3:
			var t := Balance.target(ante, stop)
			assert_gt(t, last, "target grows at ante %d stop %d" % [ante, stop])
			last = t


# ---------------------------------------------------------------- market

func test_condition_and_grade_raise_value() -> void:
	var r := _new_run()
	r.hot.clear()
	r.cold.clear()
	var loose := _item(r, "fes_zeldo", "Loose")
	var cib := _item(r, "fes_zeldo", "CIB")
	var sealed := _item(r, "fes_zeldo", "Sealed")
	assert_lt(r.market_value(loose), r.market_value(cib))
	assert_lt(r.market_value(cib), r.market_value(sealed))
	var graded := _item(r, "fes_zeldo", "CIB")
	graded["grade"] = 10
	assert_gt(r.market_value(graded), r.market_value(cib) * 2)


func test_hot_and_cold_trends() -> void:
	var r := _new_run()
	r.hot = ["F64"]
	r.cold = ["GEN"]
	var f := _item(r, "f64_conker")
	var g := _item(r, "gen_wrath2")
	assert_eq(r.market_value(f), int(round(60 * 1.5)))
	assert_eq(r.market_value(g), int(round(30 * 0.7)))


func test_collectibles_appreciate_and_fads_fade() -> void:
	var r := _new_run()
	r.hot.clear()
	r.cold.clear()
	var c := _item(r, "sfes_chrono", "CIB")
	var fad := _item(r, "fes_mitt", "Loose")
	var v0 := r.market_value(c)
	var f0 := r.market_value(fad)
	c["held"] = 5
	fad["held"] = 5
	assert_gt(r.market_value(c), v0)
	assert_lt(r.market_value(fad), f0)


# ---------------------------------------------------------------- appraisal

func test_appraisal_sums_items_and_applies_sets() -> void:
	var r := _new_run()
	r.hot.clear()
	r.cold.clear()
	r.shelf.clear()
	r.shelf.append(_item(r, "fes_plumber"))
	var ap := r.appraise()
	assert_eq(int(ap["total"]), 6)
	r.shelf.append(_item(r, "fes_duck"))
	r.shelf.append(_item(r, "fes_tetro"))
	ap = r.appraise()
	# 6 + 4 + 8 = 18, FES set (3 items) = +0.5 Mult.
	assert_eq(int(ap["chips"]), 18)
	assert_almost_eq(float(ap["mult"]), 1.5, 0.01)
	assert_eq(int(ap["total"]), 27)


func test_full_setup_multiplies() -> void:
	var r := _new_run()
	r.hot.clear()
	r.cold.clear()
	r.shelf = [_item(r, "fes_plumber"), _item(r, "fes_console"), _item(r, "fes_zapper")]
	var ap := r.appraise()
	# 6 + 45 + 7 = 58; set +0.5 -> 1.5; full setup x1.5 -> 2.25
	assert_almost_eq(float(ap["mult"]), 2.25, 0.01)
	assert_eq(int(ap["total"]), int(round(58 * 2.25)))


func test_perks_change_the_appraisal() -> void:
	var r := _new_run()
	r.hot.clear()
	r.cold.clear()
	r.shelf = [_item(r, "fes_plumber", "CIB")]
	var plain := int(r.appraise()["total"])
	r.perks = ["box_and_manual", "sticker_gun"]
	var boosted := int(r.appraise()["total"])
	assert_eq(boosted, int(round(plain * 1.5)) + 8)


func test_grails_add_mult() -> void:
	var r := _new_run()
	r.hot.clear()
	r.cold.clear()
	r.shelf = [_item(r, "fes_stadium")]
	assert_almost_eq(float(r.appraise()["mult"]), 2.0, 0.01)


# ---------------------------------------------------------------- venues

func test_garage_sale_flow() -> void:
	var r := _new_run(7)
	assert_eq(r.phase, Run.Phase.HOME)
	assert_eq(r.venue_choices, ["garage"])
	assert_true(r.enter_venue("garage")["ok"])
	assert_eq(r.phase, Run.Phase.VENUE)
	assert_eq(r.stock.size(), 6)
	assert_false(r.shows_exact(), "garage sale prices are guesswork")
	for o in r.stock:
		assert_eq((o["est"] as Array).size(), 2)
	r.cash = 1000
	var cash := r.cash
	var price := int(r.stock[0]["price"])
	var before := r.shelf.size()
	assert_true(r.buy(0)["ok"])
	assert_eq(r.cash, cash - price)
	assert_eq(r.shelf.size(), before + 1)
	assert_false(r.sell(int(r.shelf[0]["uid"]))["ok"], "garage sales don't buy from you")


func test_haggle_and_dig_cost_time() -> void:
	var r := _new_run(9)
	r.enter_venue("garage")
	var t := r.time_left
	var res := r.haggle(0)
	assert_true(res["ok"])
	assert_eq(r.time_left, t - 1)
	assert_false(r.haggle(0)["ok"], "one haggle per item")
	var n := r.stock.size()
	assert_true(r.dig()["ok"])
	assert_eq(r.stock.size(), n + 2)
	assert_eq(r.time_left, t - 2)


func test_shelf_cap_blocks_buying() -> void:
	var r := _new_run(3)
	r.enter_venue("garage")
	r.cash = 10000
	while r.free_slots() > 0 and not r.stock.is_empty():
		r.buy(0)
	assert_eq(r.free_slots(), 0)
	if not r.stock.is_empty():
		assert_false(r.buy(0)["ok"])


func test_mystery_lot_overflow_sells_extras() -> void:
	var r := _new_run(5)
	r.enter_venue("garage")
	r.cash = 10000
	while r.free_slots() > 1 and not r.stock.is_empty():
		r.buy(0)
	var cash := r.cash
	var res := r.buy_lot(0)
	assert_true(res["ok"])
	assert_eq(r.free_slots(), 0)
	assert_gt(r.cash, cash - int(r.lots[0]["price"]), "extras were sold for cash")


func test_shop_buys_grades_and_repairs() -> void:
	var r := _new_run(11)
	r.enter_venue("garage")
	r.end_stop()
	assert_eq(r.phase, Run.Phase.APPRAISAL if int(r.last_appraisal["total"]) >= Balance.target(1, 0) else Run.Phase.OVER)
	# Force our way to the shop regardless.
	r.phase = Run.Phase.APPRAISAL
	r.advance()
	assert_eq(r.stop, 1)
	assert_eq(r.venue_choices, ["retro"])
	r.enter_venue("retro")
	assert_true(r.shows_exact())
	r.cash = 1000
	var dmg := _item(r, "f64_conker", "Damaged")
	r.shelf.append(dmg)
	assert_false(r.send_to_grading(int(dmg["uid"]))["ok"], "fix it first")
	assert_true(r.repair(int(dmg["uid"]))["ok"])
	assert_eq(dmg["cond"], "Loose")
	assert_true(r.send_to_grading(int(dmg["uid"]))["ok"])
	assert_eq(r.grading.size(), 1)
	var other: Dictionary = r.shelf[0]
	var cash := r.cash
	var expected := r.sell_price(other)
	assert_true(r.sell(int(other["uid"]))["ok"])
	assert_eq(r.cash, cash + expected)


func test_grading_returns_next_stop() -> void:
	var r := _new_run(12)
	r.enter_venue("garage")
	r.venue = Venues.get_def("retro")
	r.cash = 1000
	var it := _item(r, "sfes_chrono", "CIB")
	r.shelf.append(it)
	assert_true(r.send_to_grading(int(it["uid"]))["ok"])
	r.shelf.append(_item(r, "fes_stadium", "Sealed"))  # make sure we pass
	r.end_stop()
	assert_eq(r.phase, Run.Phase.APPRAISAL)
	r.advance()
	r.enter_venue(r.venue_choices[0])
	assert_eq(r.grading.size(), 0)
	assert_between(int(it["grade"]), 6, 10)
	assert_true(r.shelf.has(it))


func test_online_listings_and_auctions_settle_at_end() -> void:
	var r := _new_run(21)
	r.stop = 2
	r.boss_id = "picky"
	r._prepare_home()
	assert_eq(r.venue_choices, ["ebay"])
	r.enter_venue("ebay")
	assert_eq(r.auctions.size(), 2)
	assert_true(r.can_list())
	r.cash = 5000
	r.shelf.append(_item(r, "fes_stadium", "Sealed"))
	var to_sell: Dictionary = r.shelf[0]
	assert_true(r.list_item(int(to_sell["uid"]))["ok"])
	assert_eq(r.listings.size(), 1)
	var mv := r.market_value(r.auctions[0]["item"])
	var guard := 0
	while r.next_bid(0) < mv * 3 and guard < 40:
		r.bid(0)
		guard += 1
	var cash_before := r.cash
	var res := r.end_stop()
	assert_eq(r.listings.size(), 0)
	assert_false(r.shelf.has(to_sell), "listed item sold")
	assert_gt(r.cash, cash_before, "got paid for the listing and refunds")
	assert_gt((res["events"] as Array).size(), 0)


func test_perk_shop() -> void:
	var r := _new_run(31)
	assert_eq(r.perk_offers.size(), Balance.PERK_OFFERS)
	r.cash = 100
	var id: String = r.perk_offers[0]
	assert_true(r.buy_perk(id)["ok"])
	assert_true(r.has_perk(id))
	assert_false(r.perk_offers.has(id))
	var cost := r.reroll_cost
	var cash := r.cash
	assert_true(r.reroll_perks()["ok"])
	assert_eq(r.cash, cash - cost)
	assert_true(r.sell_perk(id)["ok"])
	assert_false(r.has_perk(id))


func test_moms_basement_adds_slots() -> void:
	var r := _new_run(32)
	r.cash = 100
	r.perk_offers = ["moms_basement"]
	var cap := r.shelf_cap
	r.buy_perk("moms_basement")
	assert_eq(r.shelf_cap, cap + 2)


func test_failing_the_target_ends_the_run() -> void:
	var r := _new_run(4)
	r.enter_venue("garage")
	r.shelf.clear()
	var res := r.end_stop()
	assert_false(res["passed"])
	assert_eq(r.phase, Run.Phase.OVER)


func test_antes_advance_and_unlock_venues() -> void:
	var r := _new_run(8)
	for a in range(1, 6):
		for s in 3:
			assert_eq(r.ante, a)
			assert_eq(r.stop, s)
			r.phase = Run.Phase.APPRAISAL
			r.advance()
	assert_eq(r.ante, 6)
	assert_gt(r.venue_choices.size(), 1, "more hunt venues by ante 6")


func test_winning_after_ante_eight() -> void:
	var r := _new_run(10)
	r.ante = 8
	r.stop = 2
	r._prepare_home()
	r.enter_venue(r.venue_choices[0])
	for i in 6:
		r.shelf.append(_item(r, "misc_proto", "Sealed"))
	var res := r.end_stop()
	assert_true(res["passed"])
	assert_eq(r.phase, Run.Phase.WON)
	r.advance()
	assert_true(r.endless)
	assert_eq(r.ante, 9)


func test_same_seed_same_run() -> void:
	var a := _new_run(1234)
	var b := _new_run(1234)
	a.enter_venue("garage")
	b.enter_venue("garage")
	for i in a.stock.size():
		assert_eq(a.stock[i]["item"]["id"], b.stock[i]["item"]["id"])
		assert_eq(a.stock[i]["price"], b.stock[i]["price"])


func test_bot_plays_whole_runs_without_errors() -> void:
	for i in 20:
		var r := _new_run(500 + i)
		var res: Dictionary = Bot.new(r, i).play_run()
		assert_true(r.phase == Run.Phase.OVER or r.phase == Run.Phase.WON or r.phase == Run.Phase.HOME,
			"run %d ended cleanly at ante %d" % [i, res["ante"]])


func test_pity_brings_rares() -> void:
	var r := _new_run(7)
	var longest := 0
	for i in 400:
		var t := r._roll_tier(0)
		longest = maxi(longest, r.dry)
		assert_true(t >= 0 and t <= 3)
	assert_lt(longest, 60, "pity should end long dry streaks")


func test_variants_are_believable() -> void:
	for d in Catalog.ITEMS:
		var ws := Catalog.variant_weights(d)
		if int(d.get("year", 0)) > 2006:
			assert_false(ws.has("Rental Copy"), "no rentals after 2006: %s" % d["id"])
		assert_gt(ws.size(), 0)


func test_history_differs_between_items_and_copies() -> void:
	var a: Dictionary = Catalog.ITEMS[10]
	var b: Dictionary = Catalog.ITEMS[11]
	assert_ne(str(Flavor.history(a, {"uid": 1})), str(Flavor.history(b, {"uid": 1})))
	assert_ne(Flavor.provenance(a, {"uid": 1}, Flavor.facts(a)), Flavor.provenance(a, {"uid": 2}, Flavor.facts(a)))
	assert_eq(str(Flavor.facts(a)), str(Flavor.facts(a)), "facts are stable per item")


# ---------------------------------------------------------------- cards + coins

func test_card_and_coin_catalogs() -> void:
	assert_eq(Catalog.items_of("cards").size(), 250)
	assert_eq(Catalog.items_of("coins").size(), 250)
	for m in ["cards", "coins"]:
		for t in 4:
			assert_gt(Catalog.defs_of_tier(t, m).size(), 0, "%s tier %d" % [m, t])


func test_flip_into_cards_then_coins() -> void:
	var r := _new_run(11)
	assert_eq(r.pivot_offer(), "", "no flip at ante 1")
	r.ante = 5
	r._prepare_home()
	assert_eq(r.pivot_offer(), "cards")
	var cash := r.cash
	var worth := r.pivot_value()
	var res := r.pivot("cards")
	assert_true(bool(res["ok"]))
	assert_eq(r.market, "cards")
	assert_eq(r.cash, cash + worth)
	assert_eq(r.shelf.size(), Balance.PIVOT_STARTERS)
	for it in r.shelf:
		assert_eq(Catalog.market_of(String(it["plat"])), "cards")
	for id in r.venue_choices:
		assert_eq(Venues.market(String(id)), "cards")
	r.enter_venue(String(r.venue_choices[0]))
	for o in r.stock:
		assert_true(["card", "pack"].has(String(o["item"]["kind"])))
	r.phase = Run.Phase.HOME
	r.ante = 7
	r.stop = 0
	r._prepare_home()
	assert_eq(r.pivot_offer(), "coins")
	assert_true(bool(r.pivot("coins")["ok"]))
	r.enter_venue(String(r.venue_choices[0]))
	for o in r.stock:
		assert_eq(String(o["item"]["kind"]), "coin")


func test_ripping_a_pack() -> void:
	var r := _new_run(3)
	r.market = "cards"
	r.shelf.clear()
	r.shelf_cap = 20
	var pk := _item(r, "crit_base_set_booster_box", "CIB")
	r.shelf.append(pk)
	var res := r.open_pack(int(pk["uid"]))
	assert_true(bool(res["ok"]))
	assert_eq(r.shelf.size(), Balance.OPEN_BOX)
	for it in r.shelf:
		assert_eq(String(it["plat"]), "CRIT")
		assert_eq(String(it["kind"]), "card")


func test_curse_grade_follows_how_close_you_came() -> void:
	var r := Run.new()
	r.start(5)
	var tgt := r.target()
	r.last_appraisal = {"total": 0}
	assert_eq(String(r.curse_grade()["cond"]), "DAMAGED")
	assert_eq(String(r.curse_grade()["grade"]), "1.0")
	r.last_appraisal = {"total": int(tgt * 0.5)}
	assert_eq(String(r.curse_grade()["cond"]), "LOOSE")
	r.last_appraisal = {"total": int(tgt * 0.8)}
	assert_eq(String(r.curse_grade()["cond"]), "COMPLETE IN BOX")
	r.last_appraisal = {"total": int(ceil(tgt * 0.97))}
	assert_eq(String(r.curse_grade()["cond"]), "MINT")
	assert_eq(String(r.curse_grade()["grade"]), "9.8")
	assert_eq(Flavor.LETTERS.size(), Balance.ANTES_TO_WIN)
