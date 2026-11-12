extends SceneTree
## Frames from the opening sequence:  ... -s res://tools/intro_shots.gd -- OUT_DIR [landscape]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://intro"
	DisplayServer.window_set_size(Vector2i(1280, 720) if args.has("landscape") else Vector2i(720, 1280))
	DirAccess.make_dir_recursive_absolute(out)
	root.add_child(load("res://scenes/main.tscn").instantiate())
	_go.call_deferred(out)


func _go(out: String) -> void:
	var t := 0.0
	for at in [1.0, 3.2, 4.8, 6.3, 7.0, 8.2, 10.0, 13.0]:
		await create_timer(at - t).timeout
		t = at
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("t%04.1f.png" % at))
	quit()
