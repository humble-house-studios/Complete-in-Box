extends SceneTree
## Screenshots of the Collector's Curse bits: title, lore guide pages, the
## Buyer's letters on the home PC, and the graded-case lose ending.
##   xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/curse_shots.gd -- OUT_DIR [landscape]

var out := "user://curse_shots"
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
	game._save["sealed"] = 0
	game.show_title()
	await _snap("title")
	game._open_guide(Callable())
	game._guide_show(0)
	await _snap("guide_inheritance")
	game._guide_show(5)
	await _snap("guide_mail")
	game._close_sheet()
	game.start_new_run(4242)
	await _snap("home_letter1")
	game.run.letters_read = 8
	game._open_letter(7)
	await _snap("letter8")
	game._close_sheet()
	await _snap("home_pc_button")
	game.go_to_venue("garage")
	await _snap("venue", 12)
	# Come up short at 60% of the target: LOOSE.
	var tgt: int = game.run.target()
	game.run.shelf.clear()
	game.finish_stop()
	game.run.last_appraisal["total"] = int(tgt * 0.62)
	game._after_appraisal()
	await _snap("over", 40)
	game.show_title()
	await _snap("title_after_loss", 40)
	quit()
