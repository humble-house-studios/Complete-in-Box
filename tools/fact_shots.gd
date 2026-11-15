extends SceneTree
## Item cards with their real facts (tools/wiki_facts.py), scrolled to the stats.
## xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/fact_shots.gd -- OUT_DIR [landscape] ID...

var game: Control


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0] if args.size() > 0 else "/tmp/facts"
	DirAccess.make_dir_recursive_absolute(out)
	var land := args.has("landscape")
	DisplayServer.window_set_size(Vector2i(1280, 720) if land else Vector2i(720, 1280))
	var ids: Array = []
	for a in args.slice(1):
		if a != "landscape":
			ids.append(a)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	_go.call_deferred(out, ids)


func _go(out: String, ids: Array) -> void:
	for i in 300:
		await process_frame
	game.run = Run.new()
	game.run.start(7, {})
	for id in ids:
		var def := Catalog.get_def(String(id))
		if def.is_empty():
			print("no item ", id)
			continue
		var it: Dictionary = game.run.make_item(def, "Mint")
		game._open_sheet(String(def["name"]), [], [], it)
		for i in 40:
			await process_frame
		root.get_texture().get_image().save_png(out.path_join(String(id) + "_a.png"))
		# Scroll the info down to the real stats and the history panels.
		for sc in _scrolls(game._sheet):
			sc.scroll_vertical = 700
		for i in 10:
			await process_frame
		root.get_texture().get_image().save_png(out.path_join(String(id) + "_b.png"))
		for sc in _scrolls(game._sheet):
			sc.scroll_vertical = 1600
		for i in 10:
			await process_frame
		root.get_texture().get_image().save_png(out.path_join(String(id) + "_c.png"))
		game._close_sheet()
	quit()


func _scrolls(n: Node) -> Array:
	var outl: Array = []
	if n is ScrollContainer:
		outl.append(n)
	for c in n.get_children():
		outl.append_array(_scrolls(c))
	return outl
