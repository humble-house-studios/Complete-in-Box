extends Control
## Trading-card art for a perk: a graphic background about what the perk does
## (a sunrise for Early Bird, a brick basement for Mom's Basement, the open sea
## for Whale Watcher, a price list for Price Guide...), its glossy 3D picture
## (Subjects.PERKS) big in the middle with two smaller extras, and the effect
## badge ("x2", "+$8") in the corner. Everything is drawn from `size`, so the
## art fits any card width. No class_name (the TV app's self-update can't add
## global classes): use preload("res://scripts/gfx/perk_art.gd").make(...).

const THEMES := {
	"price_guide": "paper", "silver_tongue": "comic", "early_bird": "sunrise", "extra_hour": "clock",
	"box_and_manual": "cardboard", "shrink_wrap": "vault", "hoarder": "basement", "moms_basement": "basement",
	"power_seller": "money", "sticker_gun": "money", "funtendo_kid": "neon", "saga_does": "neon",
	"disc_jockey": "neon", "completionist": "paper", "piggy_bank": "money", "lucky_lots": "meadow",
	"flipper": "ocean", "hype_beast": "comic", "time_capsule": "clock", "grader_buddy": "metal",
	"bubble_wrap": "ocean", "nostalgia": "crt", "curator": "vault", "coupon": "kraft", "eagle_eye": "sky",
	"whale": "ocean", "lunchbox": "kitchen", "console_wars": "versus",
	"pack_rat": "cardboard", "holo_hunter": "neon", "gold_bug": "vault",
	"plastic_wrap": "vault", "dust_sheet": "basement", "full_page": "paper", "slab_fan": "metal",
	"glass_case": "vault", "hot_streak": "comic", "dollar_bin": "kraft", "haggle_king": "comic",
	"oddity_hunter": "neon", "cursed_cart": "basement",
	"archivist": "paper", "long_box": "cardboard", "rookie_fever": "sunrise", "hall_of_fame": "vault",
	"key_issue": "comic", "golden_age": "vault", "debut_novel": "paper", "antiquarian": "vault", "forty_five": "synthwave", "golden_oldies": "sunrise",
	"up_shelf": "basement", "up_time": "clock", "up_perk_slot": "cardboard", "up_interest": "money", "up_reroll": "comic",
}
## Pictures for perks added after subjects.gd was generated (existing renders only).
const EXTRA_PERKS := {
	"plastic_wrap": ["wrapped_gift", "sparkles"],
	"dust_sheet": ["card_file_box", "books"],
	"full_page": ["open_book", "check_mark_button"],
	"slab_fan": ["hundred_points", "sports_medal"],
	"glass_case": ["framed_picture", "gem_stone"],
	"hot_streak": ["fire", "chart_increasing"],
	"dollar_bin": ["coin", "card_file_box"],
	"haggle_king": ["handshake", "crown"],
	"oddity_hunter": ["eyes", "magnifying_glass_tilted_right"],
	"cursed_cart": ["coffin", "video_game", "skull"],
	"archivist": ["books", "scroll"],
	"long_box": ["card_file_box", "books"],
	"rookie_fever": ["baby_chick", "baseball", "glowing_star"],
	"hall_of_fame": ["trophy", "stadium", "sports_medal"],
	"key_issue": ["old_key", "person_superhero", "glowing_star"],
	"golden_age": ["crown", "rolled_up_newspaper", "sparkles"],
	"debut_novel": ["open_book", "baby_chick", "glowing_star"],
	"antiquarian": ["scroll", "books", "candle"],
	"forty_five": ["optical_disk", "musical_notes", "headphone"],
	"golden_oldies": ["radio", "saxophone", "sparkles"],
}
const BADGE_FONT := "res://assets/fonts/cover/Bangers-Regular.ttf"

var theme_name := "comic"
var col := Color.WHITE
var rng_seed := 0
var _main: TextureRect
var _extras: Array = []
var _badge: Label
static var _font: Font


const Subjects := preload("res://scripts/gfx/subjects.gd")


static func make(id: String, accent: Color, badge: String, h: float) -> Control:
	var a = (load("res://scripts/gfx/perk_art.gd") as GDScript).new()
	a.theme_name = String(THEMES.get(id, "comic"))
	a.col = accent
	a.rng_seed = hash(id)
	a.custom_minimum_size = Vector2(0, h)
	a.clip_contents = true
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var refs: Array = Subjects.PERKS.get(id, EXTRA_PERKS.get(id, []))
	var g := RandomNumberGenerator.new()
	g.seed = a.rng_seed
	for i in refs.size():
		var st := CoverComp.subject(g, String(refs[i]))
		if st[0] == null:
			continue
		var tr: TextureRect = _pic(st[0], st[1])
		if i == 0:
			a._main = tr
		else:
			a._extras.append(tr)
	for e in a._extras:
		var sh: TextureRect = _pic((e as TextureRect).texture, null)
		sh.modulate = Color(0, 0, 0, 0.35)
		sh.set_meta("shadow_of", e)
		a.add_child(sh)
		a.add_child(e)
	if a._main != null:
		var msh: TextureRect = _pic(a._main.texture, null)
		msh.modulate = Color(0, 0, 0, 0.4)
		msh.set_meta("shadow_of", a._main)
		a.add_child(msh)
		a.add_child(a._main)
	if badge != "":
		var l := Label.new()
		l.text = badge
		if _font == null:
			_font = load(BADGE_FONT)
		l.add_theme_font_override("font", _font)
		l.add_theme_font_size_override("font_size", 30)
		l.add_theme_color_override("font_color", Color(1, 0.97, 0.85))
		l.add_theme_color_override("font_outline_color", accent.darkened(0.65))
		l.add_theme_constant_override("outline_size", 10)
		l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
		l.add_theme_constant_override("shadow_offset_y", 3)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		a._badge = l
		a.add_child(l)
	return a


static func _pic(t: Texture2D, tint) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tint != null:
		var m := ShaderMaterial.new()
		m.shader = CoverComp.TINT
		m.set_shader_parameter("tint", tint)
		tr.material = m
	return tr


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_ENTER_TREE:
		_layout()
		queue_redraw()


func _layout() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var ms := h * 0.84
	if _main != null:
		_main.size = Vector2(ms, ms)
		_main.position = Vector2(w * 0.5 - ms * 0.5, h * 0.5 - ms * 0.47)
	var spots := [Vector2(0.17, 0.62), Vector2(0.83, 0.34)]
	for i in _extras.size():
		var e: TextureRect = _extras[i]
		var es := h * 0.44
		var at: Vector2 = spots[i % spots.size()]
		e.size = Vector2(es, es)
		e.position = Vector2(w * at.x - es * 0.5, h * at.y - es * 0.5)
		e.pivot_offset = e.size * 0.5
		e.rotation_degrees = -12.0 if i % 2 == 0 else 10.0
	for c in get_children():
		if c.has_meta("shadow_of"):
			var src: TextureRect = c.get_meta("shadow_of")
			var s := c as TextureRect
			s.size = src.size
			s.position = src.position + Vector2(src.size.x * 0.05, src.size.y * 0.06)
			s.pivot_offset = src.pivot_offset
			s.rotation_degrees = src.rotation_degrees
	if _badge != null:
		_badge.reset_size()
		_badge.position = Vector2(w - _badge.size.x - 8, h - _badge.size.y + 4)


# ---------------------------------------------------------------- backgrounds

func _draw() -> void:
	var w := size.x
	var h := size.y
	var g := RandomNumberGenerator.new()
	g.seed = rng_seed
	match theme_name:
		"sunrise":
			_bands([Color("2b1a5e"), Color("8a2f7a"), Color("ff6a5c"), Color("ffb347")])
			var c := Vector2(w * 0.5, h * 1.02)
			for k in 14:
				var a0 := PI + PI * k / 14.0
				_tri(c, a0, a0 + PI / 28.0, w, Color(1, 0.9, 0.6, 0.16))
			draw_circle(c, h * 0.5, Color("ffd36b"))
			draw_circle(c, h * 0.42, Color("ffe9a8"))
			for k in 3:
				_cloud(Vector2(g.randf() * w, h * g.randf_range(0.15, 0.4)), h * 0.08, Color(1, 0.8, 0.85, 0.55))
		"clock":
			draw_rect(Rect2(0, 0, w, h), Color("10183a"))
			var c := Vector2(w * 0.5, h * 0.5)
			for k in 6:
				draw_arc(c, h * (0.25 + k * 0.22), 0, TAU, 64, Color(col, 0.18 - k * 0.02), 3.0)
			for k in 12:
				var a := TAU * k / 12.0
				draw_line(c + Vector2(cos(a), sin(a)) * h * 0.62, c + Vector2(cos(a), sin(a)) * h * 0.74, Color(1, 1, 1, 0.35), 3.0)
			draw_line(c, c + Vector2(w * 0.3, -h * 0.1), Color(col, 0.35), 5.0)
			draw_line(c, c + Vector2(-w * 0.05, -h * 0.4), Color(1, 1, 1, 0.3), 4.0)
			for k in 20:
				draw_circle(Vector2(g.randf() * w, g.randf() * h), g.randf_range(0.8, 1.8), Color(1, 1, 1, g.randf_range(0.2, 0.6)))
		"money":
			_bands([Color("0f3d22"), Color("1d6b3a"), Color("2f8f4e")])
			for y in range(0, int(h) + 30, 26):
				for x in range(-20, int(w) + 30, 34):
					var o := 17 if (y / 26) % 2 == 1 else 0
					_coin(Vector2(x + o, y), 9.0, Color(1, 0.84, 0.3, 0.22))
			_glow(Vector2(w * 0.5, h * 0.5), h * 0.62, Color(1, 0.9, 0.4))
		"ocean":
			_bands([Color("7fd3ff"), Color("2a8fd6"), Color("124f8c"), Color("0a2c57")])
			for k in 6:
				var y := h * (0.32 + k * 0.13)
				var pts := PackedVector2Array()
				for x in range(0, int(w) + 12, 6):
					pts.append(Vector2(x, y + sin(x * 0.07 + k * 1.7) * 4.0))
				draw_polyline(pts, Color(1, 1, 1, 0.22 - k * 0.02), 2.0)
			for k in 12:
				var p := Vector2(g.randf() * w, g.randf_range(0.4, 1.0) * h)
				draw_arc(p, g.randf_range(3, 9), 0, TAU, 16, Color(1, 1, 1, 0.45), 1.5)
		"basement":
			_tex("bricks105", Color(0.55, 0.42, 0.38), 64.0)
			draw_rect(Rect2(0, h * 0.78, w, h * 0.22), Color("3a2a22"))
			_tex_rect("carpet012", Rect2(0, h * 0.8, w, h * 0.2), Color(0.6, 0.45, 0.4), 48.0)
			_glow(Vector2(w * 0.18, h * 0.25), h * 0.7, Color(1, 0.75, 0.4))
			draw_rect(Rect2(w * 0.72, h * 0.08, w * 0.16, h * 0.18), Color(0.85, 0.9, 1.0, 0.25))
			draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.02, 0.04, 0.25))
		"paper":
			_tex("paper001", Color(1, 0.98, 0.92), 128.0)
			for y in range(14, int(h), 13):
				draw_line(Vector2(0, y), Vector2(w, y), Color(0.45, 0.6, 0.9, 0.35), 1.0)
				if g.randf() < 0.7:
					var lw := g.randf_range(0.25, 0.55) * w
					draw_rect(Rect2(w * 0.12, y - 7, lw, 4), Color(0.2, 0.2, 0.3, 0.18))
					draw_rect(Rect2(w * 0.78, y - 7, w * 0.12, 4), Color(0.1, 0.4, 0.15, 0.25))
			draw_line(Vector2(w * 0.08, 0), Vector2(w * 0.08, h), Color(0.9, 0.3, 0.3, 0.6), 2.0)
		"kraft":
			_tex("paper006", Color(1, 1, 1), 128.0)
			var y := h * 0.5
			var x := 0.0
			while x < w:
				draw_line(Vector2(x, y), Vector2(x + 8, y), Color(0.2, 0.15, 0.1, 0.55), 2.0)
				x += 14.0
			for k in 4:
				draw_rect(Rect2(g.randf() * w, g.randf() * h, 26, 12), Color(1, 0.3, 0.3, 0.25))
			draw_string(_bfont(), Vector2(8, h * 0.3), "SAVE!", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.75, 0.15, 0.15, 0.4))
			draw_string(_bfont(), Vector2(w * 0.6, h * 0.92), "15% OFF", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.75, 0.15, 0.15, 0.35))
		"cardboard":
			_tex("cardboard002", Color(1, 0.92, 0.8), 96.0)
			draw_rect(Rect2(w * 0.42, 0, w * 0.16, h), Color(0.85, 0.75, 0.55, 0.6))
			draw_rect(Rect2(w * 0.42, 0, w * 0.16, h), Color(1, 1, 1, 0.12))
			draw_string(_bfont(), Vector2(6, h - 8), "FRAGILE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.1, 0.1, 0.5))
			draw_string(_bfont(), Vector2(w * 0.62, 22), "THIS SIDE UP", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.2, 0.1, 0.05, 0.4))
		"comic":
			draw_rect(Rect2(0, 0, w, h), col.lightened(0.15))
			var c := Vector2(w * 0.5, h * 0.5)
			for k in 18:
				var a0 := TAU * k / 18.0
				_tri(c, a0, a0 + PI / 18.0, w, Color(1, 1, 0.85, 0.28))
			for y in range(0, int(h) + 8, 8):
				for x in range(0, int(w) + 8, 8):
					var d := Vector2(x, y).distance_to(Vector2(w, h)) / (w + h)
					draw_circle(Vector2(x + (4 if (y / 8) % 2 == 1 else 0), y), 2.6 * (1.0 - d), Color(0, 0, 0, 0.14))
			_star(c, h * 0.52, h * 0.32, 12, Color(1, 0.95, 0.4, 0.85))
		"versus":
			draw_rect(Rect2(0, 0, w, h), Color("d8302f"))
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.58, 0), Vector2(w, 0), Vector2(w, h), Vector2(w * 0.42, h)]), Color("2a5bd7"))
			draw_line(Vector2(w * 0.58, 0), Vector2(w * 0.42, h), Color(1, 1, 0.8), 5.0)
			for k in 10:
				var y := g.randf() * h
				draw_line(Vector2(0, y), Vector2(w * g.randf_range(0.1, 0.3), y), Color(1, 1, 1, 0.25), 2.0)
				draw_line(Vector2(w, y), Vector2(w * g.randf_range(0.7, 0.9), y), Color(1, 1, 1, 0.25), 2.0)
			draw_string(_bfont(), Vector2(w * 0.5 - 18, h * 0.32), "VS", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1, 0.95, 0.4, 0.5))
		"neon":
			_bands([Color("12002a"), Color("3b0a5e"), Color("b0257a")])
			var hz := h * 0.62
			var sc := Vector2(w * 0.5, hz)
			draw_circle(sc, h * 0.34, Color("ffcf4a"))
			for k in 4:
				draw_rect(Rect2(sc.x - h * 0.4, hz - h * (0.05 + k * 0.07), h * 0.8, h * 0.025 + k * 0.004), Color("3b0a5e"))
			draw_rect(Rect2(0, hz, w, h - hz), Color("12002a"))
			for k in 9:
				var y := hz + (h - hz) * pow(k / 8.0, 1.8)
				draw_line(Vector2(0, y), Vector2(w, y), Color(col, 0.7), 1.5)
			for k in range(-8, 9):
				draw_line(Vector2(w * 0.5 + k * 6, hz), Vector2(w * 0.5 + k * w * 0.16, h), Color(col, 0.6), 1.5)
		"crt":
			draw_rect(Rect2(0, 0, w, h), Color("101014"))
			var bars := [Color("c0c0c0"), Color("c0c000"), Color("00c0c0"), Color("00c000"), Color("c000c0"), Color("c00000"), Color("0000c0")]
			for k in bars.size():
				draw_rect(Rect2(w * k / bars.size(), 0, w / bars.size() + 1, h * 0.7), Color(bars[k], 0.75))
			for y in range(0, int(h), 3):
				draw_line(Vector2(0, y), Vector2(w, y), Color(0, 0, 0, 0.35), 1.0)
			draw_string(_bfont(), Vector2(8, h - 8), "PLAY  0:00:00", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
		"vault":
			_tex("fabric061", Color(0.55, 0.1, 0.16), 64.0)
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.4, 0), Vector2(w * 0.6, 0), Vector2(w * 0.85, h), Vector2(w * 0.15, h)]), Color(1, 0.95, 0.8, 0.14))
			for k in 3:
				draw_rect(Rect2(3 + k * 3, 3 + k * 3, w - 6 - k * 6, h - 6 - k * 6), Color(1, 0.8, 0.3, 0.75 - k * 0.2), false, 2.0)
		"metal":
			_tex("metal032", Color(0.85, 0.88, 0.95), 128.0)
			for p in [Vector2(10, 10), Vector2(w - 10, 10), Vector2(10, h - 10), Vector2(w - 10, h - 10)]:
				draw_circle(p, 4.0, Color(0.4, 0.42, 0.5))
				draw_circle(p - Vector2(1, 1), 2.0, Color(1, 1, 1, 0.6))
			draw_string(_bfont(), Vector2(w * 0.08, h * 0.3), "10", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color(0.2, 0.3, 0.6, 0.18))
			_glow(Vector2(w * 0.5, h * 0.5), h * 0.6, col)
		"sky":
			_bands([Color("4aa3ff"), Color("8fd0ff"), Color("d6f0ff")])
			for k in 5:
				_cloud(Vector2(g.randf() * w, h * g.randf_range(0.2, 0.9)), h * g.randf_range(0.07, 0.12), Color(1, 1, 1, 0.8))
			draw_colored_polygon(PackedVector2Array([Vector2(0, h), Vector2(w * 0.3, h * 0.7), Vector2(w * 0.55, h)]), Color("5a6b8c"))
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.4, h), Vector2(w * 0.75, h * 0.6), Vector2(w * 1.1, h)]), Color("4a5a7a"))
		"meadow":
			_bands([Color("7cc8ff"), Color("c8ecff")])
			_hill(h * 0.62, Color("5fbf4a"), g)
			_hill(h * 0.78, Color("3f9a38"), g)
			for k in 18:
				draw_circle(Vector2(g.randf() * w, g.randf_range(0.7, 1.0) * h), 2.2, [Color("ffffff"), Color("ffe14d"), Color("ff7fbf")][k % 3])
		"kitchen":
			var s := 16.0
			for y in range(0, int(h / s) + 1):
				for x in range(0, int(w / s) + 1):
					draw_rect(Rect2(x * s, y * s, s, s), Color("e8473f") if (x + y) % 2 == 0 else Color("fff4e6"))
			draw_rect(Rect2(0, h * 0.72, w, h * 0.28), Color("8a5a3a"))
			draw_rect(Rect2(0, h * 0.72, w, 4), Color("b07a50"))
		_:
			draw_rect(Rect2(0, 0, w, h), col.darkened(0.6))
	# Soft vignette so the picture pops.
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.0))
	for k in 4:
		draw_rect(Rect2(k * 2, k * 2, w - k * 4, h - k * 4), Color(0, 0, 0, 0.12), false, 2.0)


func _bands(cols: Array) -> void:
	var n := 24
	for i in n:
		var t := float(i) / (n - 1) * (cols.size() - 1)
		var a: Color = cols[int(floor(t))]
		var b: Color = cols[mini(int(floor(t)) + 1, cols.size() - 1)]
		draw_rect(Rect2(0, size.y * i / n, size.x, size.y / n + 1), a.lerp(b, t - floor(t)))


func _tri(c: Vector2, a0: float, a1: float, r: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r * 1.5, c + Vector2(cos(a1), sin(a1)) * r * 1.5]), color)


func _glow(c: Vector2, r: float, color: Color) -> void:
	for k in 6:
		draw_circle(c, r * (1.0 - k * 0.14), Color(color, 0.06))


func _coin(p: Vector2, r: float, color: Color) -> void:
	draw_circle(p, r, color)
	draw_arc(p, r * 0.7, 0, TAU, 16, Color(color, color.a * 1.5), 1.5)


func _cloud(p: Vector2, r: float, color: Color) -> void:
	draw_circle(p, r, color)
	draw_circle(p + Vector2(r * 0.9, r * 0.25), r * 0.8, color)
	draw_circle(p + Vector2(-r * 0.9, r * 0.3), r * 0.7, color)
	draw_circle(p + Vector2(r * 0.2, -r * 0.5), r * 0.75, color)


func _star(c: Vector2, r_out: float, r_in: float, points: int, color: Color) -> void:
	var pts := PackedVector2Array()
	for k in points * 2:
		var a := PI * k / points - PI / 2.0
		var r := r_out if k % 2 == 0 else r_in
		pts.append(c + Vector2(cos(a) * r * 1.4, sin(a) * r))
	draw_colored_polygon(pts, color)


func _hill(y: float, color: Color, g: RandomNumberGenerator) -> void:
	var pts := PackedVector2Array([Vector2(0, size.y)])
	var ph := g.randf() * TAU
	for x in range(0, int(size.x) + 8, 8):
		pts.append(Vector2(x, y + sin(x * 0.03 + ph) * size.y * 0.06))
	pts.append(Vector2(size.x, size.y))
	draw_colored_polygon(pts, color)


func _tex(name: String, mod: Color, tile: float) -> void:
	_tex_rect(name, Rect2(Vector2.ZERO, size), mod, tile)


func _tex_rect(name: String, r: Rect2, mod: Color, tile: float) -> void:
	var t := Psx.tex(name)
	if t == null:
		draw_rect(r, mod.darkened(0.3))
		return
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x
		while x < r.end.x:
			var cell := Rect2(x, y, minf(tile, r.end.x - x), minf(tile, r.end.y - y))
			draw_texture_rect_region(t, cell, Rect2(0, 0, t.get_width() * cell.size.x / tile, t.get_height() * cell.size.y / tile), mod)
			x += tile
		y += tile


func _bfont() -> Font:
	if _font == null:
		_font = load(BADGE_FONT)
	return _font
