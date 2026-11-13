extends SceneTree
## Screenshots of the meta screens: estate picker, won screen unlocks, binder rewards.
##   xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/meta_shots.gd -- OUT_DIR [landscape]

var out := "user://meta_shots"
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


func _snap(name: String, frames: int = 24) -> void:
	for i in frames:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _go() -> void:
	var keep: Dictionary = game._save.duplicate()
	game._save["estates"] = 7
	game._save["max_tier"] = 2
	game._save["won_arlo"] = 1
	game._save["last_estate"] = 2
	game._save["last_tier"] = 1
	game._open_estates()
	await _snap("estates")
	game._close_sheet()
	game._save["estates"] = 1
	game._save["max_tier"] = 0
	game.start_new_run(808)
	await _snap("home", 12)
	game._close_sheet()
	game.run.phase = Run.Phase.WON
	game._record_win()
	game.screen = "won"
	game.request_refresh()
	await _snap("won", 30)
	game._open_collection()
	game._set_coll_tab("binder")
	await _snap("binder")
	game._save = keep
	game._write_save()
	quit()
