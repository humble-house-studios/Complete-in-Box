extends SceneTree
## Frames from a world's first-visit intro:
##   xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/world_intro_shots.gd -- OUT_DIR [world] [landscape]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://world_intro"
	DisplayServer.window_set_size(Vector2i(1280, 720) if args.has("landscape") else Vector2i(720, 1280))
	DirAccess.make_dir_recursive_absolute(out)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var world: String = args[1] if args.size() > 1 and args[1] != "landscape" else "sports"
	_go.call_deferred(out, game, world)


func _go(out: String, game: Node, world: String) -> void:
	await create_timer(0.5).timeout
	game._skip_intro()
	await create_timer(0.5).timeout
	game.run = Run.new()
	game.run.start(7, {"estate": "rose", "world": world, "worlds": ["games", "cards", world]})
	game.screen = "home"
	game._world_intro(world, func(): pass)
	var t := 0.0
	for at in [0.8, 2.5, 4.5, 6.5, 8.6, 9.6, 11.0]:
		await create_timer(at - t).timeout
		t = at
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("w%04.1f.png" % at))
	quit()
