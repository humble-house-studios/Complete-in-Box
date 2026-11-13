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
		assert_true(["game", "console", "acc", "misc", "card", "pack", "coin", "scard", "wax"].has(d["kind"]), "bad kind on " + d["id"])
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


func test_estates_change_the_start() -> void:
	var U := preload("res://scripts/data/unlocks.gd")
	for e in U.ESTATES:
		var r := Run.new()
		r.start(77, {"estate": e["id"]})
		assert_eq(r.estate_id, String(e["id"]))
		assert_eq(r.shelf.size(), int(e["starters"]), "%s starters" % e["id"])
		for pid in e["perks"]:
			assert_true(r.has_perk(String(pid)), "%s starts with %s" % [e["id"], pid])
			assert_false(Perks.get_def(String(pid)).is_empty())
		var perk_shelf := 0
		for pid in e["perks"]:
			perk_shelf += int({"moms_basement": 2, "cursed_cart": -2, "long_box": 1}.get(String(pid), 0))
		assert_eq(r.shelf_cap, Balance.START_SHELF + int(e["shelf"]) + perk_shelf)
	var rose := Run.new()
	rose.start(5, {"estate": "rose"})
	assert_eq(String(rose.shelf[0]["cond"]), "CIB")


func test_tiers_stack_up() -> void:
	var base := Run.new()
	base.start(9)
	var t1 := Run.new()
	t1.start(9, {"tier": 1})
	assert_gt(t1.target(), base.target())
	var t2 := Run.new()
	t2.start(9, {"tier": 2})
	assert_eq(t2.cash, base.cash - 10)
	var t3 := Run.new()
	t3.start(9, {"tier": 3})
	assert_true(t3.is_boss_stop(), "Buyer's terms at every stop from GRADE 10")
	assert_false(base.is_boss_stop())
	var t4 := Run.new()
	t4.start(9, {"tier": 4})
	assert_eq(t4.shelf_cap, base.shelf_cap - 1)
	assert_gt(t4.target(), t1.target())


func test_binder_perks_stay_locked_until_unlocked() -> void:
	for k in 30:
		var r := Run.new()
		r.start(100 + k)
		r._roll_perk_offers()
		for pid in r.perk_offers:
			assert_false(Perks.get_def(String(pid)).has("lock"), "%s offered while locked" % pid)
	var got := false
	for k in 60:
		var r2 := Run.new()
		r2.start(200 + k, {"perks_unlocked": ["plastic_wrap", "dust_sheet", "full_page", "slab_fan"]})
		r2._roll_perk_offers()
		for pid in r2.perk_offers:
			if Perks.get_def(String(pid)).has("lock"):
				got = true
	assert_true(got, "unlocked binder perks show up in the shop")


func test_binder_rewards_and_new_perks() -> void:
	var U := preload("res://scripts/data/unlocks.gd")
	var owned := {}
	assert_eq((U.binder_rewards(owned)["perks"] as Array).size(), 0)
	for d in Catalog.ITEMS.slice(0, 85):
		owned[String(d["id"])] = true
	var br: Dictionary = U.binder_rewards(owned)
	assert_true((br["perks"] as Array).has("plastic_wrap"))
	assert_true((br["perks"] as Array).has("dust_sheet"))
	assert_eq(int(br["shelf"]), 1)
	var r := Run.new()
	r.start(3)
	r.shelf.clear()
	var it := r.make_item(Catalog.get_def("fes_console"), "Damaged")
	r.shelf.append(it)
	var plain := int(r.appraise()["total"])
	r.perks.append("dust_sheet")
	assert_gt(int(r.appraise()["total"]), plain)


# ---------------------------------------------------------------- want list

func test_want_list_rolls_every_ante_and_pays_once() -> void:
	var r := _new_run(7)
	assert_false(r.want.is_empty(), "a request on day one")
	assert_ne(r.want_text(), "")
	# Force a request we can fill with a known item.
	r.want = {"id": "mint", "plat": "", "n": 1, "worth": 0, "done": false, "ante": 1, "reward": 9}
	assert_eq(int(r.want_progress()[0]), 0)
	r.shelf.append(_item(r, "fes_zeldo", "Sealed"))
	assert_eq(int(r.want_progress()[0]), 1)
	assert_true(r.wants(r.shelf[-1]))
	r.enter_venue(String(r.venue_choices[0]))
	var cash := r.cash
	var res := r.end_stop()
	assert_true(bool(res["passed"]))
	assert_eq(int(res["rewards"].get("want", 0)), 9)
	assert_eq(r.wants_done, 1)
	assert_true(bool(r.want["done"]))
	assert_gt(r.cash, cash)
	# A filled request doesn't pay twice.
	r.advance()
	r.enter_venue(String(r.venue_choices[0]))
	var res2 := r.end_stop()
	assert_false(res2["rewards"].has("want"))


func test_every_want_kind_has_text_and_a_note() -> void:
	var r := _new_run(3)
	for m in Run.WANT_KINDS:
		for k in Run.WANT_KINDS[m]:
			r.want = {"id": k, "plat": "FES", "n": 2, "worth": 50, "done": false, "ante": 1, "reward": 5}
			assert_ne(r.want_text(), "", k)
			assert_true(Flavor.WANT_NOTES.has(k), "note for " + k)
	# A new ante brings a new request.
	r.want = {}
	r.ante = 1
	r.stop = 2
	r.phase = Run.Phase.APPRAISAL
	r.advance()
	assert_false(r.want.is_empty())
	assert_eq(int(r.want["ante"]), 2)


func test_first_round_terms_are_mild() -> void:
	for s in 40:
		var r := _new_run(100 + s)
		assert_false(["picky", "skeptic"].has(r.boss_id), "ante 1 boss %s" % r.boss_id)


func test_doorbell_events_resolve_cleanly() -> void:
	var r := _new_run(11)
	r.enter_venue(String(r.venue_choices[0]))
	r.end_stop()
	r.phase = Run.Phase.APPRAISAL
	for ev in ["box", "trade", "collector", "leak", "diary"]:
		var it := _item(r, "fes_zeldo", "Loose")
		r.shelf.append(it)
		r.cash = 200
		match ev:
			"box": r.event = {"id": "box", "item": _item(r, "fes_robo2", "CIB"), "price": 10}
			"trade": r.event = {"id": "trade", "item": _item(r, "fes_robo2", "CIB"), "give": int(it["uid"])}
			"collector": r.event = {"id": "collector", "give": int(it["uid"]), "price": 50}
			"leak": r.event = {"id": "leak", "give": int(it["uid"]), "price": 5}
			"diary": r.event = {"id": "diary", "page": 0, "cash": 6}
		r.phase = Run.Phase.HOME
		var res := r.event_accept()
		assert_true(bool(res["ok"]), ev + ": " + String(res["msg"]))
		assert_true(r.event.is_empty(), ev + " cleared")
	# Letting the roof drip damages the item.
	var wet := _item(r, "fes_zeldo", "CIB")
	r.shelf.append(wet)
	r.event = {"id": "leak", "give": int(wet["uid"]), "price": 5}
	r.event_decline()
	assert_eq(String(wet["cond"]), "Damaged")
	assert_eq(r.diary_read, 1)


# ---------------------------------------------------------------- ten worlds

func test_sports_catalog_and_world_registry() -> void:
	var W := preload("res://scripts/data/worlds.gd")
	assert_eq(W.LIST.size(), 10, "ten worlds")
	assert_eq(Catalog.items_of("sports").size(), 100)
	for t in 4:
		assert_gt(Catalog.defs_of_tier(t, "sports").size(), 0, "sports tier %d" % t)
	for p in ["BASE", "HOOP", "GRID", "PUCK", "FUTB"]:
		assert_eq(Catalog.market_of(p), "sports")
		assert_gte(Catalog.items_of("sports").filter(func(d): return String(d["plat"]) == p).size(), 8, p)
	for d in Catalog.items_of("sports"):
		for k in ["name", "blurb", "year", "tier", "base", "tags"]:
			assert_true(d.has(k), "%s has %s" % [d["id"], k])
	for slot in Venues.SLOTS:
		assert_false(Venues.unlocked(slot, 1, "sports").is_empty(), "sports has a %s venue" % slot)
	var U := preload("res://scripts/data/unlocks.gd")
	var bits := {}
	for e in U.ESTATES:
		assert_false(bits.has(int(e["bit"])), "unique estate bit")
		bits[int(e["bit"])] = true
		assert_false(W.get_def(String(e["world"])).is_empty(), "%s has a world" % e["id"])
	assert_eq(U.open_worlds(U.START_MASK), ["games", "cards"], "retro and TCG from the start")


func test_rose_opens_in_sports_and_rips_wax() -> void:
	var r := Run.new()
	r.start(21, {"estate": "rose", "worlds": ["games", "cards", "sports"]})
	assert_eq(r.market, "sports")
	for it in r.shelf:
		assert_eq(Catalog.market_of(String(it["plat"])), "sports")
	r.enter_venue(String(r.venue_choices[0]))
	for o in r.stock:
		assert_true(["scard", "wax"].has(String(o["item"]["kind"])))
	r.phase = Run.Phase.HOME
	r.shelf.clear()
	r.shelf_cap = 30
	var box: Dictionary = {}
	for d in Catalog.items_of("sports"):
		if String(d["kind"]) == "wax" and (d["tags"] as Array).has("box"):
			box = d
			break
	var pk := r.make_item(box, "CIB")
	r.shelf.append(pk)
	assert_true(bool(r.open_pack(int(pk["uid"]))["ok"]))
	for it in r.shelf:
		assert_eq(String(it["kind"]), "scard")
		assert_eq(String(it["plat"]), String(box["plat"]))


func test_flip_into_any_open_world() -> void:
	var r := Run.new()
	r.start(11, {"worlds": ["games", "sports"]})
	r.ante = 5
	r._prepare_home()
	assert_eq(r.pivot_options(), ["sports"], "only opened worlds")
	assert_false(bool(r.pivot("coins")["ok"]), "coins not opened")
	assert_true(bool(r.pivot("sports")["ok"]))
	assert_eq(r.market, "sports")


func test_binder_stamps_capped_and_world_seals() -> void:
	var U := preload("res://scripts/data/unlocks.gd")
	var owned := {}
	for d in Catalog.ITEMS:
		owned[String(d["id"])] = true
	var br := U.binder_rewards(owned)
	assert_gt(int(br["stamps"]), U.STAMP_CAP)
	assert_eq(int(br["stamp_cash"]), U.STAMP_CAP)
	assert_true((br["worlds_done"] as Array).has("sports"))
	assert_eq(int(br["perk_slot"]), 1)
	assert_true((br["perks"] as Array).has("archivist"))


func test_rose_lore_is_complete() -> void:
	assert_eq(Flavor.letters("rose").size(), Balance.ANTES_TO_WIN)
	assert_eq(Flavor.diary("rose").size(), 4)
	assert_eq(Flavor.pass_lines("sports").size(), 12)
	assert_eq(Flavor.fail_lines("sports").size(), 12)
	for v in ["ballroom", "shoebox", "dugout", "breaks"]:
		assert_ne(Flavor.seller(v, 1), "", v)
	for e in ["box", "collector", "leak"]:
		assert_eq(Flavor.event_text("sports", e).size(), 2)
	assert_false(Flavor.curse("sports").is_empty())
	assert_false(Flavor.intro("sports").is_empty())
	var it: Dictionary = Catalog.items_of("sports")[0].duplicate()
	it["uid"] = 3
	assert_gt(Flavor.history(Catalog.items_of("sports")[0], it).size(), 2)
	assert_eq(Perks.label("box_and_manual", "sports")["name"], "Top-Loaders")
