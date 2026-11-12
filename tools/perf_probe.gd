extends SceneTree
## Frame-time probe in TV performance mode: plays the intro and a few screen
## changes and prints every frame slower than 40 ms with what was happening.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-driver opengl3 -s res://tools/perf_probe.gd

var game: Control
var phase := "boot"
var last := 0
var spikes: Array = []
var frames := {}


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(1280, 720))
	Lite.set_level(1)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	process_frame.connect(_tick)
	_go.call_deferred()


func _tick() -> void:
	var now := Time.get_ticks_usec()
	if last > 0:
		var ms := (now - last) / 1000.0
		frames[phase] = frames.get(phase, []) + [ms]
		if ms > 40.0:
			spikes.append("%s %.0fms" % [phase, ms])
	last = now


func _wait(sec: float) -> void:
	await create_timer(sec).timeout


func _go() -> void:
	phase = "gate"
	await _wait(1.0)
	phase = "intro"
	game._gate_pick(false)
	await _wait(30.0)
	phase = "new_run"
	game._save["guide_off"] = 1
	game.start_new_run(99)
	await _wait(3.0)
	phase = "to_venue"
	game.go_to_venue(String(game.run.venue_choices[0]))
	await _wait(3.0)
	phase = "appraise"
	game.finish_stop()
	await _wait(6.0)
	phase = "after"
	game._after_appraisal()
	await _wait(3.0)
	# CPU cost of the pieces of a screen change.
	for sc in ["title", "home", "garage", "flea", "retro", "online"]:
		var t0 := Time.get_ticks_usec()
		game._stage.show_scene(sc, game.run.shelf)
		print("COST show_scene %-8s %6.1fms" % [sc, (Time.get_ticks_usec() - t0) / 1000.0])
		await process_frame
	for sc in ["home", "venue"]:
		game.screen = sc
		if sc == "venue":
			game.run.enter_venue(String(game.run.venue_choices[0]))
		var t1 := Time.get_ticks_usec()
		game._do_refresh()
		print("COST ui rebuild %-8s %6.1fms" % [sc, (Time.get_ticks_usec() - t1) / 1000.0])
		await process_frame
	# Painting one box cover (CPU side: building the Controls).
	var c := Control.new()
	root.add_child(c)
	var t2 := Time.get_ticks_usec()
	for i in 10:
		var d: Dictionary = Catalog.ITEMS[i * 37].duplicate()
		d["cond"] = "CIB"
		BoxArt.paint_front(c, d)
		for ch in c.get_children():
			ch.free()
	print("COST paint_front x10 %6.1fms" % ((Time.get_ticks_usec() - t2) / 1000.0))
	var t3 := Time.get_ticks_usec()
	for i in 10:
		var d2: Dictionary = Catalog.ITEMS[i * 41].duplicate()
		d2["cond"] = "CIB"
		var m := ItemModels.build(d2, null, 1)
		m.free()
	print("COST item model x10 %6.1fms" % ((Time.get_ticks_usec() - t3) / 1000.0))
	for k in frames:
		var a: Array = frames[k]
		a.sort()
		print("PHASE %-9s frames %4d  median %5.1fms  p95 %5.1fms  max %6.1fms" % [k, a.size(), a[a.size() / 2], a[int(a.size() * 0.95)], a[-1]])
	print("SPIKES ", spikes.size(), ": ", ", ".join(spikes.slice(0, 40)))
	quit()
