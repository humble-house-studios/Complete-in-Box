extends SceneTree
## Contact sheet of runtime box art + icons for random items:
##   xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/art_sheet.gd -- OUT.png [seed] [games|cards|coins]

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(256, 256))
	_go.call_deferred()


func _go() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0] if args.size() > 0 else "user://art.png"
	var rng := RandomNumberGenerator.new()
	rng.seed = int(args[1]) if args.size() > 1 else 3
	var picks: Array = []
	var pool: Array = Catalog.items_of(args[2]) if args.size() > 2 else Catalog.ITEMS
	for i in 30:
		var d: Dictionary = pool[rng.randi() % pool.size()].duplicate()
		d["variant"] = Catalog.roll_variant(d, rng) if i % 2 == 0 else "Standard"
		if i % 5 == 0:
			d["variant"] = ["Misprint", "Test Cart", "Player's Pick", "Rental Copy", "Collector's Edition", "Prototype"][(i / 5) % 6]
			if not (Catalog.VARIANTS[d["variant"]]["kinds"] as Array).has(d["kind"]):
				d["variant"] = "Standard"
		d["cond"] = ["CIB", "Loose", "Mint", "Sealed"][i % 4]
		if i % 7 == 3:
			d["grade"] = 9
		picks.append(d)
	var texs: Array = []
	for d in picks:
		texs.append([Art.front(d), Art.back(d), Art.icon(d, true), Art.icon(d, false)])
	for i in 60:
		await process_frame
	var cw := 240 + 240 + 96 + 96 + 8
	var sheet := Image.create(cw * 3, 150 * 10, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.2, 0.2, 0.24))
	for i in picks.size():
		var x := (i % 3) * cw
		var y := (i / 3) * 150
		var t: Array = texs[i]
		var xs := [0, 240, 480, 576]
		for k in 4:
			var img: Image = (t[k] as Texture2D).get_image()
			if img != null:
				img.convert(Image.FORMAT_RGBA8)
				sheet.blend_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(x + xs[k], y + (0 if k < 2 else 27)))
		print(i, " ", picks[i]["name"], " [", picks[i]["plat"], "] ", picks[i]["variant"])
	sheet.save_png(out)
	quit()
