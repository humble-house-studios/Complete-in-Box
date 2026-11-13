extends SceneTree
## Lets a person (or Claude) play the real game from the shell, one command at
## a time, with screenshots. Start it in the background:
##   xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/play_driver.gd -- DIR [landscape] [fresh]
## then write commands into DIR/cmd.txt (one per line) and wait for DIR/done.txt:
##   list               visible buttons in the top layer (index, rect, text)
##   tap TEXT [n]       mouse-click the nth button whose text/labels contain TEXT
##   tapi N             click button N from the last list
##   click X Y          click a screen point
##   wait SECONDS
##   shot NAME          save DIR/NAME.png
##   eval EXPR          run an expression on the game node (prints the result)
##   state              cash, ante, stop, phase, shelf, target, appraisal
## Output for each batch goes to DIR/out.txt.

var dir := ""
var game: Control
var _buttons: Array = []
var _out: PackedStringArray = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	dir = args[0] if args.size() > 0 else "/tmp/play"
	DirAccess.make_dir_recursive_absolute(dir)
	if args.has("landscape"):
		DisplayServer.window_set_size(Vector2i(1280, 720))
	else:
		DisplayServer.window_set_size(Vector2i(720, 1280))
	if args.has("fresh"):
		for f in ["user://save.cfg", "user://collection.cfg"]:
			if FileAccess.file_exists(f):
				DirAccess.remove_absolute(f)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	_loop.call_deferred()


func _loop() -> void:
	var cmd_path := dir.path_join("cmd.txt")
	while true:
		await process_frame
		if not FileAccess.file_exists(cmd_path):
			continue
		var txt := FileAccess.get_file_as_string(cmd_path)
		DirAccess.remove_absolute(cmd_path)
		_out = []
		for line in txt.split("\n"):
			line = line.strip_edges()
			if line == "":
				continue
			_out.append("> " + line)
			await _run(line)
		var f := FileAccess.open(dir.path_join("out.txt"), FileAccess.WRITE)
		f.store_string("\n".join(_out) + "\n")
		f.close()
		var d := FileAccess.open(dir.path_join("done.txt"), FileAccess.WRITE)
		d.store_string("ok")
		d.close()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _texts(n: Node, out: Array) -> void:
	if n is Button and (n as Button).text != "":
		out.append((n as Button).text.replace("\n", " / "))
	elif n is Label and (n as Label).text != "" and (n as Label).is_visible_in_tree():
		out.append((n as Label).text.replace("\n", " / "))
	for c in n.get_children():
		_texts(c, out)


func _collect(all := false) -> Array:
	var layer: Control = game._pad_layer()
	var out: Array = []
	for b in game._focusables(layer):
		var c := b as Control
		var r := c.get_global_rect()
		var vr := root.get_visible_rect()
		if not all and not vr.intersects(r):
			continue
		var t: Array = []
		_texts(c, t)
		out.append({"node": c, "rect": r, "text": " | ".join(t)})
	return out


func _click_at(p: Vector2) -> void:
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	m.position = p
	m.global_position = p
	m.pressed = true
	root.push_input(m)
	await _frames(2)
	var u := m.duplicate() as InputEventMouseButton
	u.pressed = false
	root.push_input(u)
	await _frames(6)


func _press(c: Control) -> void:
	var r := c.get_global_rect()
	# Clicks land on scrolled-off buttons poorly: scroll it into view first.
	var sc: ScrollContainer = game._scroll_of(c) if game.has_method("_scroll_of") else null
	if sc != null:
		sc.ensure_control_visible(c)
		await _frames(3)
		r = c.get_global_rect()
	var vr := root.get_visible_rect()
	var p := r.get_center()
	p.x = clampf(p.x, vr.position.x + 2, vr.end.x - 2)
	p.y = clampf(p.y, vr.position.y + 2, vr.end.y - 2)
	await _click_at(p)


func _run(line: String) -> void:
	var parts := line.split(" ", false)
	var cmd := parts[0]
	var rest := line.substr(cmd.length()).strip_edges()
	match cmd:
		"list", "listall":
			_buttons = _collect(cmd == "listall")
			for i in _buttons.size():
				var b: Dictionary = _buttons[i]
				var r: Rect2 = b["rect"]
				_out.append("[%d] (%d,%d %dx%d) %s" % [i, r.position.x, r.position.y, r.size.x, r.size.y, String(b["text"]).left(160)])
		"tap":
			var n := 0
			var needle := rest
			var last := rest.rfind(" ")
			if last > 0 and rest.substr(last + 1).is_valid_int():
				n = int(rest.substr(last + 1))
				needle = rest.substr(0, last)
			_buttons = _collect(true)
			var hits: Array = []
			for b in _buttons:
				if String(b["text"]).to_lower().contains(needle.to_lower()):
					hits.append(b)
			if hits.size() <= n:
				_out.append("!! no button matching '%s' (%d hits)" % [needle, hits.size()])
				return
			_out.append("tapping: " + String(hits[n]["text"]).left(120))
			await _press(hits[n]["node"])
		"tapi":
			var i := int(rest)
			if i < 0 or i >= _buttons.size() or not is_instance_valid(_buttons[i]["node"]):
				_out.append("!! bad index")
				return
			_out.append("tapping: " + String(_buttons[i]["text"]).left(120))
			await _press(_buttons[i]["node"])
		"click":
			await _click_at(Vector2(float(parts[1]), float(parts[2])))
		"wait":
			var t := float(rest)
			var end := Time.get_ticks_msec() + int(t * 1000.0)
			while Time.get_ticks_msec() < end:
				await process_frame
		"shot":
			await _frames(4)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(dir.path_join(rest + ".png"))
			_out.append("saved " + rest)
		"eval":
			var e := Expression.new()
			if e.parse(rest) != OK:
				_out.append("!! parse: " + e.get_error_text())
				return
			var v = e.execute([], game)
			if e.has_execute_failed():
				_out.append("!! exec: " + e.get_error_text())
			else:
				_out.append(str(v))
		"state":
			var r: Run = game.run
			if r == null:
				_out.append("no run; screen=" + game.screen)
				return
			_out.append("screen=%s phase=%d ante=%d stop=%d cash=%d time=%d target=%d shelf=%d/%d perks=%s" % [game.screen, r.phase, r.ante, r.stop, r.cash, r.time_left, r.target(), r.slots_used(), r.shelf_cap, str(r.perks)])
			var ap := r.appraise()
			_out.append("appraisal now: chips=%d mult=%s total=%d" % [ap["chips"], str(ap["mult"]), ap["total"]])
			for it in r.shelf:
				_out.append("  shelf: %s [%s %s t%d %s] mv=$%d paid=$%d" % [it["name"], it["plat"], it["cond"], it["tier"], it["variant"], r.market_value(it), it["paid"]])
			for i in r.stock.size():
				var o: Dictionary = r.stock[i]
				_out.append("  stock%d: %s [%s %s t%d] price=$%d mv=$%d est=%s" % [i, o["item"]["name"], o["item"]["plat"], o["item"]["cond"], o["item"]["tier"], o["price"], r.market_value(o["item"]), str(o["est"])])
			for i in r.lots.size():
				var l: Dictionary = r.lots[i]
				_out.append("  lot%d: price=$%d bought=%s n=%d" % [i, l["price"], str(l["bought"]), (l["items"] as Array).size()])
			for i in r.auctions.size():
				var a: Dictionary = r.auctions[i]
				_out.append("  auction%d: %s bid=$%d rival=$%d mine=$%d mv=$%d" % [i, a["item"]["name"], a["bid"], a["rival"], a["my_max"], r.market_value(a["item"])])
		"bot":
			# Fast-forward: the pro bot plays N stops from Home, then back to Home.
			var Pro = load("res://tools/pro_bot.gd")
			var r: Run = game.run
			var bot = Pro.new(r, 3)
			for k in int(rest):
				if r.phase != Run.Phase.HOME:
					break
				var res: Dictionary = bot.play_stop()
				_out.append("  stop A%d S%d: %d / %d %s cash=%d" % [r.ante, r.stop + 1, res["appraisal"]["total"], r.target(), "PASS" if res["passed"] else "FAIL", r.cash])
				if r.phase == Run.Phase.APPRAISAL:
					r.advance()
				else:
					break
			game.screen = "home" if r.phase == Run.Phase.HOME else ("over" if r.phase == Run.Phase.OVER else "won")
			game.request_refresh()
			await _frames(30)
		_:
			_out.append("!! unknown command")
