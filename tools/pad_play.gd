extends SceneTree
## Plays whole runs with nothing but simulated Xbox pad presses and reports
## anything that feels wrong: buttons the D-pad can't reach, focus lost or
## off screen, presses that do nothing, B that doesn't back out.
##   godot --headless -s res://tools/pad_play.gd -- [landscape] [runs=N] [seed=N]
## Prints a step log and a PROBLEMS list at the end (exit code 1 if any).

var game: Control
var problems: Array = []
var log_on := true
var steps := 0
var runs := 1
var seed_value := 77


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("runs="):
			runs = int(a.get_slice("=", 1))
		if a.begins_with("seed="):
			seed_value = int(a.get_slice("=", 1))
		if a == "quiet":
			log_on = false
	if args.has("landscape"):
		DisplayServer.window_set_size(Vector2i(1280, 720))
	else:
		DisplayServer.window_set_size(Vector2i(720, 1280))
	# Fresh profile: guide on, no collection.
	for f in ["user://save.cfg", "user://collection.cfg"]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(f)
	if not args.has("3d"):
		# Same layout, much quicker: skip the 3D rooms and painted art.
		Lite._ready = true
		Lite.no3d = true
		Lite.noart = true
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	_go.call_deferred()


# ---------------------------------------------------------------- input

func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _press(btn: int, settle: int = 10) -> void:
	steps += 1
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	Input.parse_input_event(e)
	await _frames(2)
	var u := InputEventJoypadButton.new()
	u.button_index = btn
	u.pressed = false
	Input.parse_input_event(u)
	await _frames(settle)


func _hold_axis(axis: int, val: float, frames: int) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = val
	Input.parse_input_event(e)
	await _frames(frames)
	var z := InputEventJoypadMotion.new()
	z.axis = axis
	z.axis_value = 0.0
	Input.parse_input_event(z)
	await _frames(10)


## Wait until no transition veil / busy animation is running.
func _settle(max_s: float = 12.0) -> void:
	var t0 := Time.get_ticks_msec()
	await _frames(4)
	while Time.get_ticks_msec() - t0 < max_s * 1000.0:
		var v = game.get("_veil")
		if (v == null or not is_instance_valid(v)) and not game._busy:
			break
		await process_frame
	await _frames(6)


# ---------------------------------------------------------------- looking

func _fo() -> Control:
	return root.gui_get_focus_owner()


func _text(c: Node) -> String:
	if c == null:
		return "<none>"
	if c is Button and (c as Button).text != "":
		return (c as Button).text.replace("\n", " ")
	var bits: Array = []
	_collect(c, bits)
	return ("[" + " / ".join(bits.slice(0, 2)) + "]") if not bits.is_empty() else "[" + c.name + "]"


func _collect(n: Node, out: Array) -> void:
	for ch in n.get_children():
		if ch is Label and (ch as Label).text.strip_edges().length() > 1 and (ch as Label).is_visible_in_tree():
			out.append((ch as Label).text.replace("\n", " ").left(28))
		_collect(ch, out)


func _layer() -> Control:
	return game._pad_layer()


func _buttons() -> Array:
	return game._focusables(_layer())


func _where() -> String:
	var s: String = game.screen
	if game.sheet_open():
		s += "+sheet"
	if game._overlay.get_node_or_null("Reveal") != null:
		s += "+reveal"
	if game._overlay.get_node_or_null("Appraisal") != null:
		s += "+appraisal"
	if game.screen == "home":
		s += "(%s%s)" % [game._home_tab, ",showcase" if game._showcase else ""]
	if game.screen == "venue":
		s += "(%s)" % game._venue_tab
	return s


func _say(tag: String) -> void:
	if log_on:
		print("  %-26s %-28s focus=%s" % [tag, _where(), _text(_fo())])


func _problem(msg: String) -> void:
	var m := "[%s] %s (focus=%s)" % [_where(), msg, _text(_fo())]
	if not problems.has(m):
		problems.append(m)
	print("  !! " + m)


## Focus sanity after anything happens.
func _check_focus(tag: String) -> void:
	var fo := _fo()
	var list := _buttons()
	if list.is_empty():
		return
	if fo == null:
		_problem(tag + ": nothing has focus")
		return
	if not fo.is_visible_in_tree():
		_problem(tag + ": focus is on a hidden control")
		return
	if not list.has(fo):
		_problem(tag + ": focus is outside the top layer")
		return
	var vr: Rect2 = game.get_viewport_rect()
	var r := fo.get_global_rect()
	if not vr.intersects(r):
		_problem(tag + ": focused button is off screen %s" % r)
		return
	# Inside a scroll list: at least half of it should be in view.
	var n: Node = fo.get_parent()
	while n != null:
		if n is ScrollContainer:
			var sr := (n as Control).get_global_rect()
			var inter := sr.intersection(r)
			if inter.get_area() < r.get_area() * 0.45:
				_problem(tag + ": focused button is scrolled out of view")
			break
		n = n.get_parent()


# ---------------------------------------------------------------- moving

func _find(pred: Callable) -> Control:
	for b in _buttons():
		if pred.call(b):
			return b
	return null


func _has_text(s: String) -> Callable:
	return func(b: Control) -> bool: return _all_text(b).to_lower().contains(s.to_lower())


func _all_text(c: Node) -> String:
	var bits: Array = []
	if c is Button:
		bits.append((c as Button).text)
	_collect(c, bits)
	return " ".join(bits)


## Walk the highlight to the first button matching pred with the D-pad only.
func _nav(pred: Callable, what: String) -> bool:
	var target := _find(pred)
	if target == null:
		var have: Array = []
		for b in _buttons():
			have.append(_text(b).left(22))
		_problem("wanted '%s' but it isn't on screen" % what)
		print("     buttons: ", ", ".join(have))
		return false
	var seen := {}
	for step in 60:
		var fo := _fo()
		if fo == target or (fo != null and pred.call(fo)):
			return true
		if fo == null:
			await _press(JOY_BUTTON_DPAD_DOWN)
			continue
		var a := fo.get_global_rect()
		var b := target.get_global_rect()
		var d := b.get_center() - a.get_center()
		var dirs: Array = []
		var vert := JOY_BUTTON_DPAD_DOWN if d.y > 0 else JOY_BUTTON_DPAD_UP
		var hor := JOY_BUTTON_DPAD_RIGHT if d.x > 0 else JOY_BUTTON_DPAD_LEFT
		var overlap_y := minf(a.end.y, b.end.y) - maxf(a.position.y, b.position.y)
		var overlap_x := minf(a.end.x, b.end.x) - maxf(a.position.x, b.position.x)
		if overlap_y > 0.0:
			dirs = [hor, vert]
		elif overlap_x > 0.0:
			dirs = [vert, hor]
		else:
			dirs = [vert, hor] if absf(d.y) >= absf(d.x) else [hor, vert]
		var moved := false
		for dir in dirs:
			var key := "%s|%d" % [str(fo.get_instance_id()), dir]
			if seen.has(key):
				continue
			seen[key] = true
			await _press(dir, 4)
			if _fo() != fo:
				moved = true
				break
		if not moved:
			_problem("D-pad can't reach '%s' from here" % what)
			return false
		target = _find(pred) if not is_instance_valid(target) or not target.is_visible_in_tree() else target
		if target == null:
			return false
	_problem("D-pad took 60+ presses toward '%s'" % what)
	return false


func _nav_press(pred: Callable, what: String) -> bool:
	if not await _nav(pred, what):
		return false
	_say("A on " + what)
	await _press(JOY_BUTTON_A)
	await _settle()
	_check_focus("after A on " + what)
	return true


## Every button on this layer must be reachable with the D-pad from the start.
func _reach_all(tag: String) -> void:
	var start := _fo()
	if start == null:
		return
	var list := _buttons()
	var seen := {start: true}
	var frontier: Array = [start]
	var guard := 0
	while not frontier.is_empty() and guard < 260:
		var c: Control = frontier.pop_front()
		for dir in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]:
			guard += 1
			if not is_instance_valid(c) or not c.is_visible_in_tree():
				continue
			c.grab_focus()
			await _frames(1)
			var ev := InputEventJoypadButton.new()
			ev.button_index = dir
			ev.pressed = true
			Input.parse_input_event(ev)
			await _frames(1)
			var u := InputEventJoypadButton.new()
			u.button_index = dir
			Input.parse_input_event(u)
			await _frames(1)
			var n := _fo()
			if n != null and not seen.has(n) and list.has(n):
				seen[n] = true
				frontier.append(n)
	var missing: Array = []
	for b in list:
		if not seen.has(b):
			missing.append(_text(b))
	if not missing.is_empty():
		_problem("%s: D-pad can never reach %s" % [tag, ", ".join(missing.slice(0, 5))])
	if is_instance_valid(start):
		start.grab_focus()
	await _frames(6)


# ---------------------------------------------------------------- B / Y checks

func _expect_b_closes(tag: String) -> void:
	var before: bool = game.sheet_open()
	await _press(JOY_BUTTON_B)
	await _settle()
	if before and game.sheet_open():
		_problem(tag + ": B didn't close the sheet")
	_check_focus("after B on " + tag)


# ---------------------------------------------------------------- the run

func _go() -> void:
	await _frames(30)
	print("viewport ", game.get_viewport_rect().size, " landscape=", game.is_landscape())
	_say("boot")
	# Intro: any face button picks a gate choice; Start skips.
	if game._intro != null:
		await _press(JOY_BUTTON_A)
		await create_timer(1.0).timeout
		_say("after gate A")
		await _press(JOY_BUTTON_START)
		await create_timer(2.0).timeout
		if game._intro != null:
			_problem("Start didn't skip the intro")
	await _settle()
	_say("title")
	_check_focus("title")
	await _reach_all("title")
	# Title extras: credits sheet, collection and back.
	if await _nav_press(_has_text("CREDITS"), "CREDITS"):
		await _expect_b_closes("credits")
	if await _nav_press(_has_text("COLLECTION"), "COLLECTION"):
		_say("collection")
		await _reach_all("collection")
		await _press(JOY_BUTTON_X)
		await _settle()
		_say("X -> binder")
		_check_focus("binder")
		await _press(JOY_BUTTON_RIGHT_SHOULDER)
		await _settle()
		_say("RB binder page")
		_check_focus("binder RB")
		await _reach_all("binder")
		var tile := _find(func(b): return not _text(b).begins_with("WALL") and not _text(b).begins_with("BINDER") and not _text(b).begins_with("<") and not _text(b).begins_with("BACK"))
		await _press(JOY_BUTTON_B)
		await _settle()
		if game.screen != "title":
			_problem("B in the collection didn't go back to the title")
	for r in runs:
		print("=== RUN %d ===" % (r + 1))
		await _play_run(r)
	print("\n%d presses." % steps)
	print("PROBLEMS (%d):" % problems.size())
	for p in problems:
		print("  - " + p)
	quit(1 if not problems.is_empty() else 0)


func _play_run(r: int) -> void:
	if game.screen != "title":
		_problem("expected the title before a new run")
	# Y = main button = NEW RUN.
	await _press(JOY_BUTTON_Y)
	await _settle()
	_say("Y new run")
	if game.sheet_open():
		# How-to-play guide: RB pages forward, LB back, A on NEXT.
		await _reach_all("guide")
		await _press(JOY_BUTTON_RIGHT_SHOULDER)
		await _press(JOY_BUTTON_LEFT_SHOULDER)
		var guard := 0
		while game.sheet_open() and guard < 20:
			guard += 1
			await _press(JOY_BUTTON_A)
		await _settle()
	if game.screen != "home":
		_problem("guide didn't lead Home")
		return
	game.run.rng.seed = seed_value + r
	var guard := 0
	while guard < 40:
		guard += 1
		match game.screen:
			"home":
				await _home()
			"venue":
				await _venue()
			"appraisal":
				await _appraisal()
			"over", "won":
				await _end()
				return
			_:
				_problem("unexpected screen " + game.screen)
				return


func _home() -> void:
	_say("home ante %d stop %d $%d" % [game.run.ante, game.run.stop, game.run.cash])
	_check_focus("home")
	await _reach_all("home " + game._home_tab)
	# Pause menu opens and B closes it.
	await _press(JOY_BUTTON_START)
	await _settle()
	if not game.sheet_open():
		_problem("Start didn't open the pause menu at Home")
	else:
		_check_focus("pause")
		await _expect_b_closes("pause")
	# Perk shop: RB to the perks tab, buy what we can afford.
	var land: bool = game.is_landscape()
	if not land:
		await _press(JOY_BUTTON_RIGHT_SHOULDER)
		await _settle()
		_say("RB -> " + game._home_tab)
		if game._home_tab != "perks":
			_problem("RB didn't move to PERK SHOP")
	_check_focus("perk tab")
	for pid in game.run.perk_offers.duplicate():
		var d: Dictionary = Perks.get_def(pid)
		if game.run.perks.size() < game.run.perk_cap and game.run.cash - int(d["cost"]) >= 6:
			var nm := String(d["name"])
			if await _nav_press(_has_text(nm), "perk " + nm):
				_say("perk sheet")
				if not game.sheet_open():
					_problem("A on a perk card didn't open it")
					continue
				# Y = the sheet's main action (Buy).
				var cash: int = game.run.cash
				await _press(JOY_BUTTON_Y)
				await _settle()
				if game.run.cash == cash:
					_problem("Y on the perk sheet didn't buy it")
					await _press(JOY_BUTTON_B)
					await _settle()
				_check_focus("after perk buy")
	# Shelf tab and the 3D shelf view.
	await _press(JOY_BUTTON_X)
	await _settle()
	_say("X -> " + game._home_tab)
	if game._home_tab != "shelf":
		_problem("X didn't switch to the shelf at Home")
	_check_focus("shelf tab")
	if await _nav_press(_has_text("VIEW YOUR SHELF"), "VIEW YOUR SHELF"):
		_say("showcase")
		if not game._showcase:
			_problem("VIEW YOUR SHELF didn't open the 3D shelf")
		await _reach_all("showcase")
		await _press(JOY_BUTTON_DPAD_RIGHT)
		_check_focus("showcase right")
		await _press(JOY_BUTTON_B)
		await _settle()
		if game._showcase:
			_problem("B didn't leave the 3D shelf")
		_check_focus("after showcase")
	# Back to the route; pick a venue with the D-pad, then Y to go.
	if not land:
		await _press(JOY_BUTTON_LEFT_SHOULDER)
		await _press(JOY_BUTTON_LEFT_SHOULDER)
		await _settle()
		_say("LB LB -> " + game._home_tab)
		if game._home_tab != "route":
			_problem("LB didn't step back to ROUTE")
	var choices: Array = game.run.venue_choices
	var pick := String(choices[game.run.rng.randi() % choices.size()])
	var vname := String(Venues.get_def(pick)["name"])
	if await _nav(_has_text(vname), "venue " + vname):
		var was: String = game._dest
		await _press(JOY_BUTTON_A)
		await _settle(15)
		_say("A picks " + vname)
		if was == pick and game.screen != "venue":
			_problem("A on the selected venue card didn't go there")
		elif was != pick and game._dest != pick:
			_problem("A on a venue card didn't select it")
	if game.screen == "home":
		await _press(JOY_BUTTON_Y)
		await _settle(15)
		_say("Y head to")
	if game.screen != "venue":
		_problem("Y didn't head to the venue")
		game.go_to_venue(game._dest)
		await _settle(15)


func _guess(o: Dictionary) -> float:
	var run: Run = game.run
	if run.shows_exact():
		return float(run.market_value(o["item"]))
	var est: Array = o["est"]
	return (float(est[0]) + float(est[1])) * 0.5


func _show_sale() -> void:
	if not game.is_landscape() and game._venue_tab != "sale":
		await _press(JOY_BUTTON_X)
		await _settle()
		if game._venue_tab != "sale":
			_problem("X didn't switch to FOR SALE")


func _show_shelf() -> void:
	if not game.is_landscape() and game._venue_tab != "shelf":
		await _press(JOY_BUTTON_X)
		await _settle()
		if game._venue_tab != "shelf":
			_problem("X didn't switch to YOUR SHELF")


func _venue() -> void:
	var run: Run = game.run
	_say("venue %s time %d" % [run.venue["id"], run.time_left])
	_check_focus("venue")
	await _reach_all("venue " + game._venue_tab)
	# Sticks: scroll a bit, highlight should stay in view.
	await _hold_axis(JOY_AXIS_LEFT_Y, 1.0, 20)
	await _frames(20)
	_check_focus("after left stick")
	await _hold_axis(JOY_AXIS_RIGHT_Y, 1.0, 20)
	await _frames(20)
	_check_focus("after right stick")
	await _hold_axis(JOY_AXIS_LEFT_Y, -1.0, 40)
	await _hold_axis(JOY_AXIS_RIGHT_Y, -1.0, 40)
	await _frames(20)
	var guard := 0
	var inspected := false
	while guard < 14 and game.screen == "venue":
		guard += 1
		var best_i := -1
		var best_gain := 0.0
		for i in run.stock.size():
			var o: Dictionary = run.stock[i]
			var gain := _guess(o) - float(o["price"])
			if int(o["price"]) <= run.cash and gain > best_gain:
				best_gain = gain
				best_i = i
		if best_i < 0 or run.free_slots() <= 0:
			break
		await _show_sale()
		var nm := String(run.stock[best_i]["item"]["name"])
		if not await _nav_press(_has_text(nm), "offer " + nm):
			break
		if not game.sheet_open():
			_problem("A on an offer didn't open its card")
			break
		_say("offer card")
		if not inspected:
			inspected = true
			await _reach_all("item card")
			# Left stick turns the model, right stick scrolls info: no focus jumps.
			var f0 := _fo()
			await _hold_axis(JOY_AXIS_LEFT_X, 1.0, 10)
			await _hold_axis(JOY_AXIS_RIGHT_Y, 1.0, 10)
			if _fo() != f0:
				_problem("sticks on the item card moved the highlight")
		var cash: int = run.cash
		var n0: int = run.shelf.size()
		await _press(JOY_BUTTON_Y)
		await _settle()
		_say("Y buy")
		if run.cash == cash and run.shelf.size() == n0:
			_problem("Y on the offer card didn't buy")
			if game.sheet_open():
				await _expect_b_closes("offer")
			break
		_check_focus("after buy")
	# Haggle once if the venue allows it (via the card's second button).
	if float(run.venue["haggle"]) > 0.0 and run.time_left > 0 and not run.stock.is_empty():
		await _show_sale()
		var o: Dictionary = run.stock[0]
		if not bool(o["haggled"]):
			if await _nav_press(_has_text(String(o["item"]["name"])), "offer to haggle"):
				if await _nav_press(_has_text("Haggle"), "Haggle"):
					_say("haggled")
					if not game.sheet_open():
						_problem("haggle should re-open the offer card")
				if game.sheet_open():
					await _expect_b_closes("offer after haggle")
	# Dig once.
	if int(run.venue["dig"]) > 0 and run.time_left > 0:
		await _show_sale()
		var t: int = run.time_left
		if await _nav_press(_has_text(String(run.venue["dig_label"])), "dig"):
			if run.time_left == t:
				_problem("A on dig did nothing")
			if game.sheet_open():
				await _expect_b_closes("dig result")
	# Lots.
	for i in run.lots.size():
		if not bool(run.lots[i]["bought"]) and run.cash >= int(run.lots[i]["price"]) and run.free_slots() >= 2:
			await _show_sale()
			if await _nav_press(_has_text("LOT") if run.venue["id"] != "storage" else _has_text("STORAGE UNIT #%d" % (i + 1)), "lot"):
				await _press(JOY_BUTTON_Y)
				await create_timer(0.3).timeout
				# A during the reveal should skip ahead.
				await _press(JOY_BUTTON_A)
				await _settle()
				_say("lot reveal")
				if game._overlay.get_node_or_null("Reveal") != null:
					await _press(JOY_BUTTON_A)
					await _settle()
					if game._overlay.get_node_or_null("Reveal") != null:
						_problem("A didn't close the lot reveal")
				_check_focus("after lot")
			break
	# Auctions: one bid.
	if not run.auctions.is_empty() and run.cash >= run.next_bid(0):
		await _show_sale()
		if await _nav_press(_has_text(String(run.auctions[0]["item"]["name"])), "auction"):
			await _press(JOY_BUTTON_Y)
			await _settle()
			_say("bid")
			if game.sheet_open():
				await _expect_b_closes("auction")
	# Shelf: open an item, sell / list / grade if the stop allows.
	if not run.shelf.is_empty():
		await _show_shelf()
		var it: Dictionary = run.shelf[0]
		if await _nav_press(_has_text(String(it["name"])), "shelf item"):
			_say("shelf card")
			if not game.sheet_open():
				_problem("A on a shelf item didn't open it")
			else:
				await _reach_all("shelf card")
				if run.can_list():
					await _nav_press(_has_text("List for"), "List")
				elif run.can_grade() and run.cash > 80 and int(run.appraise()["total"]) > run.target() * 1.4:
					await _nav_press(_has_text("grading"), "Grade")
				else:
					await _expect_b_closes("shelf card")
				if game.sheet_open():
					await _expect_b_closes("shelf card 2")
	# Leave: Y = APPRAISE & LEAVE.
	await _press(JOY_BUTTON_Y)
	await _settle()
	_say("Y appraise")
	if game.screen == "venue" and game.sheet_open():
		# Short of the target: confirm.
		_check_focus("confirm leave")
		await _press(JOY_BUTTON_Y)
		await _settle()
	if game.screen != "appraisal":
		_problem("Y didn't start the appraisal")
		game.finish_stop()
	await _frames(10)


func _appraisal() -> void:
	await create_timer(0.4).timeout
	# A skips the count-up.
	await _press(JOY_BUTTON_A)
	var t0 := Time.get_ticks_msec()
	while game._busy and Time.get_ticks_msec() - t0 < 20000:
		await process_frame
	var took := Time.get_ticks_msec() - t0
	if took > 1500:
		_problem("A didn't skip the appraisal count (%d ms)" % took)
	await _frames(10)
	_say("appraisal done")
	if game.screen != "appraisal":
		return
	_check_focus("appraisal")
	await _press(JOY_BUTTON_Y)
	await _settle(15)
	_say("Y continue")
	if game.screen == "appraisal":
		_problem("Y didn't continue from the appraisal")
		game._after_appraisal_now()
		await _settle()


func _end() -> void:
	_say("END " + game.screen + " ante %d" % game.run.ante)
	_check_focus("end")
	await _reach_all("end screen")
	if await _nav_press(_has_text("WALL"), "wall pick"):
		_say("wall pick sheet")
		if game.sheet_open():
			await _reach_all("wall pick")
			await _press(JOY_BUTTON_A)
			await _settle()
			if game.sheet_open():
				await _expect_b_closes("wall pick")
	await _nav_press(_has_text("TITLE") if game.screen == "over" else _has_text("NEW RUN"), "back to title")
	await _settle()
	if game.screen != "title":
		if game.sheet_open():
			await _press(JOY_BUTTON_B)
		game.show_title()
		await _settle()
