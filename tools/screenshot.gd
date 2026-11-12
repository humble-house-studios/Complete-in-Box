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
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _go() -> void:
	await _snap("title")
	game.start_new_run(4242)
	game.run.cash = 60
	await _snap("home")
	game.go_to_venue("garage")
	await _snap("venue_garage")
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
