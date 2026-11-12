extends SceneTree
## Renders every Stage scene to PNG for checking the look:
##   xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/stage_shots.gd -- OUT_DIR [landscape]

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://stage"
	var land := args.has("landscape")
	DisplayServer.window_set_size(Vector2i(1280, 720) if land else Vector2i(720, 1280))
	DirAccess.make_dir_recursive_absolute(out)
	var st := Stage.new()
	root.add_child(st)
	_go.call_deferred(st, out)


func _go(st: Stage, out: String) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 7
	var conds := ["Loose", "CIB", "Sealed", "Damaged", "Mint"]
	for id in ["title", "home", "garage", "flea", "estate", "storage", "retro", "pawn", "convention", "ebay", "heritage"]:
		var items: Array = []
		var n := 1 if id == "title" else (9 if id == "home" else 6)
		for k in n:
			var d: Dictionary = Catalog.ITEMS[r.randi() % Catalog.ITEMS.size()].duplicate()
			d["cond"] = conds[r.randi() % conds.size()]
			items.append(d)
		st.show_scene(id, items)
		st.set_focus(0.3)
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(id + ".png"))
		print("shot ", id)
	quit()
