extends SceneTree
## Screenshots of each screen for checking layout:
##   xvfb-run -s "-screen 0 720x1280x24" godot --rendering-driver opengl3 -s res://tools/screenshot.gd -- OUT_DIR [landscape]
## Writes title.png, home.png, venue_*.png, appraisal.png, over.png into OUT_DIR.

var out := "user://shots"
var game: Control


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	if args.has("landscape"):
		DisplayServer.window_set_size(Vector2i(1280, 720))
	else:
		DisplayServer.window_set_size(Vector2i(720, 1280))
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)
	_go.call_deferred()


func _snap(name: String) -> void:
	for i in 24:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _go() -> void:
	await _snap("title")
	game._open_guide(Callable())
	for k in game.GUIDE.size():
		game._guide_show(k)
		await _snap("guide_%d" % k)
	game._close_sheet()
	game.start_new_run(4242)
	game.run.cash = 60
	await _snap("home")
	var pe := InputEventJoypadButton.new()
	pe.button_index = JOY_BUTTON_DPAD_DOWN
	pe.pressed = true
	game._input(pe)
	await _snap("pad_home")
	game._pad = false
	game.request_refresh()
	game._set_showcase(true)
	await _snap("home_showcase")
	game._set_showcase(false)
	game._set_home_tab("perks")
	await _snap("home_perks")
	game._set_home_tab("shelf")
	await _snap("home_shelf")
	game._set_home_tab("route")
	game.go_to_venue("garage")
	await _snap("venue_garage")
	var pv := InputEventJoypadButton.new()
	pv.button_index = JOY_BUTTON_DPAD_DOWN
	pv.pressed = true
	game._input(pv)
	await _snap("pad_venue")
	game._pad = false
	game.request_refresh()
	for pair in [["fes_zeldo", 12], ["fes_robo2", 60], ["fes_console", 30]]:
		var it: Dictionary = game.run.make_item(Catalog.get_def(pair[0]), "CIB")
		it["paid"] = pair[1]
		game.run.shelf.append(it)
	game._set_venue_tab("shelf")
	await _snap("venue_garage_shelf")
	game._open_shelf_item(int(game.run.shelf[-1]["uid"]), "")
	await _snap("shelf_item_open")
	for y in [700, 1300]:
		for sc in game.find_children("*", "ScrollContainer", true, false):
			(sc as ScrollContainer).scroll_vertical = y
		await _snap("shelf_item_mid_%d" % y)
	for sc in game.find_children("*", "ScrollContainer", true, false):
		(sc as ScrollContainer).scroll_vertical = 100000
	await _snap("shelf_item_history")
	game._close_sheet()
	game._set_venue_tab("sale")
	game._open_offer(0)
	await _snap("sheet_offer")
	game._close_sheet()
	game.run.shelf.append(game.run.make_item(Catalog.get_def("fes_console"), "CIB"))
	game.run.shelf.append(game.run.make_item(Catalog.get_def("fes_zapper"), "Loose"))
	game.run.shelf.append(game.run.make_item(Catalog.get_def("fes_robo2"), "CIB"))
	game.finish_stop()
	await _snap("appraisal")
	game._after_appraisal()
	game.run.ante = 3
	game.run._prepare_home()
	await _snap("home_later")
	for id in ["fes_wcup", "fes_samsin", "fes_console", "fes_zeldo"]:
		var w: Dictionary = game.run.make_item(Catalog.get_def(id), "CIB")
		game._hang(w, int(Catalog.get_def(id)["base"]))
	game._open_collection()
	game._set_coll_tab("wall")
	await _snap("collection_wall")
	game._set_coll_tab("binder")
	await _snap("collection_binder")
	game._binder_all = true
	game.request_refresh()
	await _snap("collection_binder_dev")
	game._binder_all = false
	game.screen = "home"
	game.request_refresh()
	game.go_to_venue(game.run.venue_choices[-1])
	await _snap("venue_shop")
	game.run.phase = Run.Phase.HOME
	game.run.stop = 2
	game.run._prepare_home()
	game.go_to_venue("ebay")
	await _snap("venue_ebay")
	game.run.shelf.clear()
	game.finish_stop()
	game._after_appraisal()
	await _snap("over")
	quit()
