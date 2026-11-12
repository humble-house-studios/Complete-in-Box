extends SceneTree
## Bakes the item art the game ships with (run after changing the catalog or
## item models):
##   xvfb-run -a -s "-screen 0 1024x1024x24" godot --rendering-driver opengl3 -s res://tools/bake_items.gd
## Writes assets/items/labels/<id>.png (box art / cart sticker, 112x128) and
## assets/items/icons/<id>_loose.png + <id>_box.png (3D renders for the cards).
## Then run `godot --headless --import` so Godot picks the new PNGs up.

const LABEL_SIZE := Vector2i(112, 128)
const ICON_SIZE := Vector2i(96, 96)
const OUT_LABELS := "res://assets/items/labels"
const OUT_ICONS := "res://assets/items/icons"

var font_title: Font
var font_body: Font


func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(256, 256))
	font_title = _crisp(load("res://assets/fonts/Jersey10-Regular.ttf"))
	font_body = _crisp(load("res://assets/fonts/Jersey15-Regular.ttf"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_LABELS))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_ICONS))
	_run.call_deferred()


func _crisp(f: FontFile) -> FontFile:
	var c: FontFile = f.duplicate()
	c.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	c.hinting = TextServer.HINTING_NONE
	c.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	c.oversampling = 1.0
	return c


func _run() -> void:
	var only := OS.get_cmdline_user_args()
	var labels := {}
	for d in Catalog.ITEMS:
		if not only.is_empty() and not only.has(d["id"]):
			continue
		var img := await _bake_label(d)
		img.save_png(ProjectSettings.globalize_path(OUT_LABELS.path_join(String(d["id"]) + ".png")))
		labels[d["id"]] = ImageTexture.create_from_image(img)
	print("labels: ", labels.size())
	var count := 0
	for d in Catalog.ITEMS:
		if not labels.has(d["id"]):
			continue
		var forms := [["loose", 0], ["box", 1]]
		if d["kind"] == "misc":
			forms = [["loose", 0]]
		for f in forms:
			var img := await _bake_icon(d, labels[d["id"]], int(f[1]))
			img.save_png(ProjectSettings.globalize_path(OUT_ICONS.path_join("%s_%s.png" % [d["id"], f[0]])))
			count += 1
	print("icons: ", count)
	quit()


# ---------------------------------------------------------------- labels

func _rng(id: String) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash(id)
	return r


func _bake_label(d: Dictionary) -> Image:
	var vp := SubViewport.new()
	vp.size = LABEL_SIZE
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	root.add_child(vp)
	var c := Control.new()
	c.size = Vector2(LABEL_SIZE)
	vp.add_child(c)
	_paint_label(c, d)
	for i in 3:
		await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img


func _rect(parent: Control, r: Rect2, col: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = r.position
	cr.size = r.size
	cr.color = col
	parent.add_child(cr)
	return cr


func _poly(parent: Control, pts: PackedVector2Array, col: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	parent.add_child(p)


func _circle(parent: Control, center: Vector2, r: float, col: Color, n: int = 20) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	_poly(parent, pts, col)


func _paint_label(c: Control, d: Dictionary) -> void:
	var w := float(LABEL_SIZE.x)
	var h := float(LABEL_SIZE.y)
	var r := _rng(String(d["id"]))
	var plat: Dictionary = Catalog.platform(String(d["plat"]))
	var pc: Color = plat["color"]
	var hue := fmod(pc.h + r.randf_range(-0.12, 0.12) + 1.0, 1.0)
	var sky := Color.from_hsv(hue, 0.55, 0.55)
	var sky2 := Color.from_hsv(fmod(hue + 0.5, 1.0), 0.6, 0.25)
	_rect(c, Rect2(0, 0, w, h), sky2)
	_rect(c, Rect2(0, 0, w, h * 0.55), sky)
	var motif := r.randi() % 5
	if d["kind"] == "console" or d["kind"] == "acc":
		motif = 5
	match motif:
		0: # sunset + mountains
			_circle(c, Vector2(w * r.randf_range(0.3, 0.7), h * 0.5), r.randf_range(18, 30), Color.from_hsv(0.1, 0.7, 1.0))
			for k in 3:
				var x := r.randf_range(-20, w)
				_poly(c, PackedVector2Array([Vector2(x, h * 0.78), Vector2(x + 34, h * 0.42 + r.randf_range(-10, 10)), Vector2(x + 70, h * 0.78)]), sky2.darkened(0.3 + k * 0.1))
			_rect(c, Rect2(0, h * 0.74, w, h * 0.3), sky2.darkened(0.5))
		1: # space
			_rect(c, Rect2(0, 0, w, h), Color(0.04, 0.03, 0.1))
			for k in 26:
				var s := r.randf_range(1, 2.5)
				_rect(c, Rect2(r.randf_range(0, w), r.randf_range(18, h * 0.75), s, s), Color(1, 1, 0.9, r.randf_range(0.4, 1)))
			var pp := Vector2(w * r.randf_range(0.35, 0.65), h * 0.45)
			_circle(c, pp, 24, Color.from_hsv(hue, 0.6, 0.85))
			_poly(c, PackedVector2Array([pp + Vector2(-40, 6), pp + Vector2(40, -6), pp + Vector2(40, -2), pp + Vector2(-40, 10)]), Color(0.95, 0.85, 0.6))
		2: # hero burst
			var ctr := Vector2(w * 0.5, h * 0.48)
			for k in 12:
				var a0 := TAU * k / 12.0
				var a1 := a0 + TAU / 24.0
				_poly(c, PackedVector2Array([ctr, ctr + Vector2(cos(a0), sin(a0)) * 120, ctr + Vector2(cos(a1), sin(a1)) * 120]), Color.from_hsv(hue, 0.7, 0.9))
			_circle(c, ctr + Vector2(0, -16), 11, Color(0.08, 0.06, 0.1))
			_poly(c, PackedVector2Array([ctr + Vector2(-16, -4), ctr + Vector2(16, -4), ctr + Vector2(22, 34), ctr + Vector2(-22, 34)]), Color(0.08, 0.06, 0.1))
		3: # synth grid
			_rect(c, Rect2(0, 0, w, h * 0.55), Color(0.12, 0.03, 0.2))
			_circle(c, Vector2(w * 0.5, h * 0.5), 26, Color(1.0, 0.45, 0.35))
			_rect(c, Rect2(0, h * 0.55, w, h * 0.45), Color(0.06, 0.02, 0.1))
			for k in 6:
				_rect(c, Rect2(0, h * 0.55 + pow(k / 6.0, 1.8) * h * 0.45, w, 1), Color(1, 0.3, 0.8, 0.8))
			for k in 9:
				var x := w * k / 8.0
				_poly(c, PackedVector2Array([Vector2(w * 0.5, h * 0.55), Vector2(x - 1, h), Vector2(x + 1, h)]), Color(1, 0.3, 0.8, 0.7))
		4: # big initial
			var l := Label.new()
			l.text = String(d["name"]).left(1)
			l.add_theme_font_override("font", font_title)
			l.add_theme_font_size_override("font_size", 110)
			l.add_theme_color_override("font_color", Color.from_hsv(hue, 0.5, 1.0))
			l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
			l.add_theme_constant_override("shadow_offset_x", 5)
			l.add_theme_constant_override("shadow_offset_y", 5)
			l.position = Vector2(w * 0.5 - 28, h * 0.02)
			c.add_child(l)
		5: # product shot: platform stripes
			_rect(c, Rect2(0, 0, w, h), Color(0.92, 0.9, 0.86))
			for k in 4:
				_rect(c, Rect2(0, 30 + k * 9, w, 5), pc.lerp(Color.WHITE, k * 0.2))
			_rect(c, Rect2(w * 0.18, h * 0.42, w * 0.64, h * 0.26), Color(0.15, 0.15, 0.17))
			_rect(c, Rect2(w * 0.22, h * 0.46, w * 0.56, h * 0.05), pc)
	# Platform band on top.
	var band := Color(0.05, 0.05, 0.06) if d["plat"] != "MISC" else Color(0.75, 0.15, 0.15)
	_rect(c, Rect2(0, 0, w, 20), band)
	var pl := Label.new()
	pl.text = String(plat["short"]) if d["plat"] != "MISC" else "COLLECTOR"
	pl.add_theme_font_override("font", font_title)
	pl.add_theme_font_size_override("font_size", 20)
	pl.add_theme_color_override("font_color", pc.lightened(0.3) if d["plat"] != "MISC" else Color(1, 0.9, 0.5))
	pl.position = Vector2(5, -3)
	c.add_child(pl)
	_rect(c, Rect2(w - 22, 5, 16, 10), pc)
	# Title on a dark strip so it reads over any art.
	_rect(c, Rect2(0, h * 0.58, w, h * 0.42), Color(0.03, 0.02, 0.05, 0.55))
	var t := Label.new()
	t.text = String(d["name"]).to_upper()
	t.add_theme_font_override("font", font_title)
	t.add_theme_font_size_override("font_size", 22)
	t.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	t.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.06))
	t.add_theme_constant_override("outline_size", 6)
	t.add_theme_constant_override("line_spacing", -6)
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	t.position = Vector2(3, h * 0.45)
	t.size = Vector2(w - 6, h * 0.55 - 4)
	c.add_child(t)
	# Frame: tier colour for rare and grail.
	var tier := int(d["tier"])
	var fc := Color(0, 0, 0, 0.7)
	var fw := 2.0
	if tier >= 2:
		fc = Catalog.TIER_COLORS[tier]
		fw = 4.0
	_rect(c, Rect2(0, 0, w, fw), fc)
	_rect(c, Rect2(0, h - fw, w, fw), fc)
	_rect(c, Rect2(0, 0, fw, h), fc)
	_rect(c, Rect2(w - fw, 0, fw, h), fc)


# ---------------------------------------------------------------- icons

func _bake_icon(d: Dictionary, label: Texture2D, boxed: int) -> Image:
	var vp := SubViewport.new()
	vp.size = ICON_SIZE
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.5, 0.6)
	e.ambient_light_energy = 0.9
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.9, 0.75)
	key.light_energy = 1.1
	key.rotation_degrees = Vector3(-35, 35, 0)
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.5, 0.6, 1.0)
	rim.light_energy = 0.6
	rim.rotation_degrees = Vector3(-10, 200, 0)
	vp.add_child(rim)
	Psx.fog_near = 100.0
	Psx.fog_far = 200.0
	var model := ItemModels.build(d, label, boxed)
	vp.add_child(model)
	model.rotation_degrees.y = -24.0
	var b := Psx.aabb(model)
	var cam := Camera3D.new()
	cam.fov = 30.0
	var center := b.get_center()
	var rad := b.size.length() * 0.5
	var dist := rad / tan(deg_to_rad(cam.fov * 0.5)) * 1.02
	cam.position = center + Vector3(0, 0.35, 1).normalized() * dist
	vp.add_child(cam)
	cam.look_at(center)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	return img
