class_name BoxArt
extends RefCounted
## Paints original front and back box art for any catalog item into a Control
## (rendered in a SubViewport by Art). Every item gets: a genre scene, its
## platform's box template (black box, grey band, spine, DVD-case header...),
## its title, a tier frame, and an overlay for the copy's variant (budget
## banner, rental sticker, misprint, signature, test-cart label...).
## The back gets screenshots, a blurb, a rating box, publisher and barcode.

## Width of the art being painted (Art.cover_size: the real box front shape).
static var W := 120
const H := 150

static var _title_font: FontFile
static var _body_font: FontFile


static func _font(big: bool) -> FontFile:
	if _title_font == null:
		_title_font = _crisp(load("res://assets/fonts/Jersey10-Regular.ttf"))
		_body_font = _crisp(load("res://assets/fonts/Jersey15-Regular.ttf"))
	return _title_font if big else _body_font


static func _crisp(f: FontFile) -> FontFile:
	var c: FontFile = f.duplicate()
	c.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	c.hinting = TextServer.HINTING_NONE
	c.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	c.oversampling = 1.0
	return c


# ---------------------------------------------------------------- primitives

static func rect(c: Control, r: Rect2, col: Color) -> ColorRect:
	var cr := ColorRect.new()
	cr.position = r.position
	cr.size = r.size
	cr.color = col
	c.add_child(cr)
	return cr


static func poly(c: Control, pts: PackedVector2Array, col: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	c.add_child(p)


static func circle(c: Control, ctr: Vector2, r: float, col: Color, n: int = 18) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(ctr + Vector2(cos(a), sin(a)) * r)
	poly(c, pts, col)


static func text(c: Control, t: String, pos: Vector2, size: Vector2, fs: int, col: Color, big: bool = true, align := HORIZONTAL_ALIGNMENT_LEFT, outline: Color = Color(0, 0, 0, 0), wrap: bool = true) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", _font(big))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	if outline.a > 0.0:
		l.add_theme_color_override("font_outline_color", outline)
		l.add_theme_constant_override("outline_size", 4)
	l.add_theme_constant_override("line_spacing", -int(fs * 0.3))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if not wrap else TextServer.OVERRUN_NO_TRIMMING
	l.horizontal_alignment = align
	l.position = pos
	l.size = size
	l.clip_text = true
	c.add_child(l)
	return l


# ---------------------------------------------------------------- scenes

## A little genre scene filling r. Seeded so the same item always matches.
static func scene(c: Control, r: Rect2, genre: String, seed_key: String, accent: Color) -> void:
	if genre != "Hardware":
		CoverComp.compose(c, r, genre, seed_key, accent)
		return
	if _product != null:
		CoverComp.product(c, r, seed_key, accent, _product)
		return
	var g := RandomNumberGenerator.new()
	g.seed = hash(seed_key)
	var hue := fmod(accent.h + g.randf_range(-0.15, 0.15) + 1.0, 1.0)
	var sky := Color.from_hsv(hue, 0.55, 0.6)
	var deep := Color.from_hsv(fmod(hue + 0.55, 1.0), 0.6, 0.22)
	var x0 := r.position.x
	var y0 := r.position.y
	var w := r.size.x
	var h := r.size.y
	var holder := Control.new()
	holder.position = Vector2.ZERO
	holder.size = Vector2(W, H)
	holder.clip_contents = false
	c.add_child(holder)
	rect(holder, r, deep)
	rect(holder, Rect2(x0, y0, w, h * 0.55), sky)
	var cx := x0 + w * g.randf_range(0.35, 0.65)
	match genre:
		"RPG":
			circle(holder, Vector2(cx, y0 + h * 0.3), h * 0.12, Color(1, 0.9, 0.6))
			var cast := Color.from_hsv(hue, 0.3, 0.15)
			rect(holder, Rect2(x0 + w * 0.2, y0 + h * 0.45, w * 0.6, h * 0.35), cast)
			for k in 4:
				var tx := x0 + w * (0.2 + k * 0.15)
				rect(holder, Rect2(tx, y0 + h * 0.32, w * 0.1, h * 0.2), cast)
				poly(holder, PackedVector2Array([Vector2(tx - 2, y0 + h * 0.32), Vector2(tx + w * 0.05, y0 + h * 0.2), Vector2(tx + w * 0.1 + 2, y0 + h * 0.32)]), Color.from_hsv(hue, 0.6, 0.5))
			poly(holder, PackedVector2Array([Vector2(x0 + w * 0.5, y0 + h * 0.98), Vector2(x0 + w * 0.47, y0 + h * 0.6), Vector2(x0 + w * 0.5, y0 + h * 0.52), Vector2(x0 + w * 0.53, y0 + h * 0.6)]), Color(0.85, 0.88, 0.95))
		"Shooter":
			rect(holder, r, Color(0.03, 0.02, 0.08))
			for k in 30:
				var s := g.randf_range(1, 2.5)
				rect(holder, Rect2(x0 + g.randf() * w, y0 + g.randf() * h, s, s), Color(1, 1, 0.9, g.randf_range(0.4, 1)))
			circle(holder, Vector2(x0 + w * 0.8, y0 + h * 0.25), h * 0.14, Color.from_hsv(hue, 0.6, 0.8))
			var sx := x0 + w * 0.4
			var sy := y0 + h * 0.6
			poly(holder, PackedVector2Array([Vector2(sx, sy - 14), Vector2(sx + 10, sy + 10), Vector2(sx, sy + 5), Vector2(sx - 10, sy + 10)]), Color(0.85, 0.88, 0.95))
			rect(holder, Rect2(sx - 1, sy - 34, 2, 16), Color(1, 0.4, 0.3))
			rect(holder, Rect2(sx + 15, sy - 44, 2, 16), Color(1, 0.4, 0.3))
		"Racing":
			rect(holder, Rect2(x0, y0 + h * 0.45, w, h * 0.55), Color(0.25, 0.5, 0.25))
			poly(holder, PackedVector2Array([Vector2(x0 + w * 0.45, y0 + h * 0.45), Vector2(x0 + w * 0.55, y0 + h * 0.45), Vector2(x0 + w * 0.95, y0 + h), Vector2(x0 + w * 0.05, y0 + h)]), Color(0.2, 0.2, 0.22))
			for k in 4:
				var t := float(k) / 4.0
				rect(holder, Rect2(x0 + w * 0.5 - 1 - t * 2, y0 + h * (0.5 + t * 0.45), 2 + t * 4, h * 0.05), Color(1, 1, 0.8))
			rect(holder, Rect2(x0 + w * 0.32, y0 + h * 0.72, w * 0.36, h * 0.12), Color.from_hsv(hue, 0.8, 0.9))
			rect(holder, Rect2(x0 + w * 0.38, y0 + h * 0.66, w * 0.24, h * 0.08), Color.from_hsv(hue, 0.6, 0.6))
		"Fighting":
			var ctr := Vector2(x0 + w * 0.5, y0 + h * 0.5)
			for k in 12:
				var a0 := TAU * k / 12.0
				poly(holder, PackedVector2Array([ctr, ctr + Vector2(cos(a0), sin(a0)) * 130, ctr + Vector2(cos(a0 + 0.26), sin(a0 + 0.26)) * 130]), Color.from_hsv(hue, 0.75, 0.95))
			for side in [-1.0, 1.0]:
				var fx: float = x0 + w * (0.5 + 0.2 * side)
				circle(holder, Vector2(fx, y0 + h * 0.42), 7, Color(0.08, 0.06, 0.1))
				poly(holder, PackedVector2Array([Vector2(fx - 9, y0 + h * 0.48), Vector2(fx + 9, y0 + h * 0.48), Vector2(fx + 12, y0 + h * 0.85), Vector2(fx - 12, y0 + h * 0.85)]), Color(0.08, 0.06, 0.1))
				rect(holder, Rect2(fx - side * 10 - 6, y0 + h * 0.5, 12, 4), Color(0.08, 0.06, 0.1))
		"Puzzle":
			rect(holder, r, Color.from_hsv(hue, 0.4, 0.25))
			for k in 14:
				var bx := x0 + int(g.randi_range(0, 7)) * w / 8.0
				var by := y0 + h * 0.3 + int(g.randi_range(0, 6)) * h / 10.0
				rect(holder, Rect2(bx, by, w / 8.0 - 1, h / 10.0 - 1), Color.from_hsv(g.randf(), 0.7, 0.95))
		"Sports":
			rect(holder, Rect2(x0, y0 + h * 0.5, w, h * 0.5), Color(0.25, 0.6, 0.3))
			for k in 4:
				rect(holder, Rect2(x0, y0 + h * (0.55 + k * 0.11), w, 1), Color(1, 1, 1, 0.6))
			circle(holder, Vector2(cx, y0 + h * 0.4), h * 0.12, Color(0.95, 0.95, 0.95))
			rect(holder, Rect2(cx - 2, y0 + h * 0.32, 4, h * 0.16), Color(0.2, 0.2, 0.2))
		"Horror":
			rect(holder, r, Color(0.25, 0.03, 0.05))
			circle(holder, Vector2(x0 + w * 0.7, y0 + h * 0.25), h * 0.13, Color(0.95, 0.92, 0.8))
			var hc := Color(0.04, 0.02, 0.04)
			rect(holder, Rect2(x0 + w * 0.15, y0 + h * 0.5, w * 0.45, h * 0.5), hc)
			poly(holder, PackedVector2Array([Vector2(x0 + w * 0.1, y0 + h * 0.5), Vector2(x0 + w * 0.375, y0 + h * 0.3), Vector2(x0 + w * 0.65, y0 + h * 0.5)]), hc)
			rect(holder, Rect2(x0 + w * 0.3, y0 + h * 0.62, 6, 8), Color(1, 0.85, 0.3))
		"Music":
			rect(holder, r, Color.from_hsv(hue, 0.6, 0.35))
			for k in 6:
				var nx := x0 + g.randf() * w * 0.85
				var ny := y0 + h * 0.3 + g.randf() * h * 0.55
				circle(holder, Vector2(nx, ny), 5, Color.from_hsv(g.randf(), 0.6, 1.0))
				rect(holder, Rect2(nx + 3, ny - 16, 2, 16), Color.from_hsv(g.randf(), 0.6, 1.0))
		"Life Sim":
			rect(holder, Rect2(x0, y0 + h * 0.5, w, h * 0.5), Color(0.45, 0.7, 0.3))
			for k in 5:
				rect(holder, Rect2(x0, y0 + h * (0.55 + k * 0.09), w, 3), Color(0.35, 0.25, 0.15))
			rect(holder, Rect2(x0 + w * 0.6, y0 + h * 0.35, w * 0.28, h * 0.2), Color(0.75, 0.2, 0.15))
			poly(holder, PackedVector2Array([Vector2(x0 + w * 0.57, y0 + h * 0.36), Vector2(x0 + w * 0.74, y0 + h * 0.24), Vector2(x0 + w * 0.91, y0 + h * 0.36)]), Color(0.5, 0.15, 0.1))
			circle(holder, Vector2(x0 + w * 0.2, y0 + h * 0.2), h * 0.09, Color(1, 0.9, 0.4))
		"Strategy":
			rect(holder, r, Color(0.3, 0.45, 0.3))
			for k in 6:
				rect(holder, Rect2(x0 + k * w / 6.0, y0, 1, h), Color(0, 0, 0, 0.25))
				rect(holder, Rect2(x0, y0 + k * h / 6.0, w, 1), Color(0, 0, 0, 0.25))
			for k in 3:
				var fx := x0 + g.randf_range(0.15, 0.85) * w
				var fy := y0 + g.randf_range(0.4, 0.85) * h
				rect(holder, Rect2(fx, fy - 16, 2, 16), Color(0.2, 0.15, 0.1))
				rect(holder, Rect2(fx + 2, fy - 16, 9, 6), Color(0.9, 0.2, 0.2) if k % 2 == 0 else Color(0.2, 0.4, 0.9))
		"Hardware":
			rect(holder, r, Color(0.93, 0.91, 0.87))
			for k in 4:
				rect(holder, Rect2(x0, y0 + h * 0.15 + k * 6, w, 3), accent.lerp(Color.WHITE, k * 0.2))
			rect(holder, Rect2(x0 + w * 0.15, y0 + h * 0.45, w * 0.7, h * 0.28), Color(0.15, 0.15, 0.17))
			rect(holder, Rect2(x0 + w * 0.2, y0 + h * 0.5, w * 0.6, h * 0.05), accent)
			circle(holder, Vector2(x0 + w * 0.75, y0 + h * 0.62), 4, Color(0.9, 0.2, 0.2))
		_:
			# Platformer / Action / Adventure: hills, clouds, a hero, coins.
			for k in 3:
				circle(holder, Vector2(x0 + g.randf() * w, y0 + h * 0.62 + k * 6), h * (0.22 - k * 0.04), Color.from_hsv(fmod(hue + 0.3, 1.0), 0.5, 0.45 + k * 0.1), 14)
			rect(holder, Rect2(x0, y0 + h * 0.78, w, h * 0.22), Color(0.4, 0.25, 0.15))
			rect(holder, Rect2(x0, y0 + h * 0.76, w, 4), Color(0.3, 0.75, 0.3))
			for k in 2:
				circle(holder, Vector2(x0 + g.randf_range(0.1, 0.9) * w, y0 + h * 0.15), 7, Color(1, 1, 1, 0.9), 10)
			if genre == "Action":
				for k in 8:
					var a0 := TAU * k / 8.0
					poly(holder, PackedVector2Array([Vector2(cx, y0 + h * 0.5), Vector2(cx, y0 + h * 0.5) + Vector2(cos(a0), sin(a0)) * 80, Vector2(cx, y0 + h * 0.5) + Vector2(cos(a0 + 0.3), sin(a0 + 0.3)) * 80]), Color(1, 1, 1, 0.12))
			var hx := cx
			var hy := y0 + h * 0.62
			circle(holder, Vector2(hx, hy - 12), 6, Color(1, 0.8, 0.65))
			rect(holder, Rect2(hx - 7, hy - 18, 14, 4), Color.from_hsv(hue, 0.8, 0.9))
			rect(holder, Rect2(hx - 6, hy - 6, 12, 12), Color.from_hsv(fmod(hue + 0.5, 1.0), 0.8, 0.85))
			rect(holder, Rect2(hx - 6, hy + 6, 4, 8), Color(0.2, 0.2, 0.5))
			rect(holder, Rect2(hx + 2, hy + 6, 4, 8), Color(0.2, 0.2, 0.5))
			for k in 3:
				circle(holder, Vector2(x0 + w * (0.2 + k * 0.25), y0 + h * 0.4), 3, Color(1, 0.85, 0.2), 8)


# ---------------------------------------------------------------- front

## The product render for the hardware box being painted (set by paint_*).
static var _product: Texture2D


const CCArt := preload("res://scripts/gfx/cc_art.gd")


static func paint_front(c: Control, item: Dictionary) -> void:
	if Catalog.is_cc(item):
		CCArt.H = H
		CCArt.paint_front(c, item, W)
		return
	CoverComp.current_title = String(item.get("name", ""))
	_product = Art.icon(item, false) if String(item.get("kind", "game")) != "game" else null
	var plat := String(item["plat"])
	var pd: Dictionary = Catalog.platform(plat)
	var pc: Color = pd["color"]
	var variant := String(item.get("variant", "Standard"))
	var genre := String(item.get("genre", "Action"))
	if item["kind"] != "game":
		genre = "Hardware"
	var title := String(item["name"]).to_upper()
	var key := String(item["id"])
	if variant == "Test Cart":
		_test_label(c, item)
		return
	var art := Rect2(0, 18, W, H - 18)
	var title_at := "bottom"
	match plat:
		"FES":
			rect(c, Rect2(0, 0, W, H), Color(0.04, 0.04, 0.04))
			for k in 8:
				rect(c, Rect2(0, 4 + k * 4, W, 1), Color(0.2, 0.2, 0.22))
			art = Rect2(10, 34, W - 20, 78)
			scene(c, art, genre, key, pc)
			text(c, "FES", Vector2(4, 0), Vector2(60, 20), 20, Color(0.85, 0.15, 0.15))
			CoverComp.title(c, title, Vector2(4, 112), Vector2(W - 8, 38), 18, Color(0.95, 0.95, 0.95), item)
			title_at = "done"
		"SFES":
			scene(c, Rect2(0, 0, W, 116), genre, key, pc)
			rect(c, Rect2(0, 116, W, 34), Color(0.82, 0.82, 0.86))
			for k in 4:
				circle(c, Vector2(W - 30 + k * 7, 124), 3, [Color(0.9, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.6, 0.3), Color(0.2, 0.3, 0.8)][k], 8)
			text(c, "SUPER FES", Vector2(4, 116), Vector2(80, 16), 14, Color(0.35, 0.3, 0.5))
			CoverComp.title(c, title, Vector2(4, 128), Vector2(W - 8, 22), 14, Color(0.15, 0.12, 0.2), item, HORIZONTAL_ALIGNMENT_LEFT)
			title_at = "done"
		"F64":
			scene(c, Rect2(14, 0, W - 14, H), genre, key, pc)
			rect(c, Rect2(0, 0, 14, H), Color(0.8, 0.12, 0.12))
			rect(c, Rect2(2, 4, 10, 10), Color(0.2, 0.6, 0.25))
			art = Rect2(14, 0, W - 14, H)
		"PST":
			scene(c, Rect2(16, 0, W - 16, H), genre, key, pc)
			rect(c, Rect2(0, 0, 16, H), Color(0.05, 0.05, 0.06))
			for k in 4:
				rect(c, Rect2(4, 6 + k * 5, 8, 3), [Color(0.9, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.6, 0.3), Color(0.2, 0.3, 0.8)][k])
			art = Rect2(16, 0, W - 16, H)
		"PST2", "XBX", "PSPK", "FCUBE", "SAT", "GEN", "PBOY", "PBA", "DUO", "DC":
			var band_col: Color = {"PST2": Color(0.08, 0.12, 0.35), "XBX": Color(0.2, 0.55, 0.2), "PSPK": Color(0.92, 0.92, 0.94),
				"FCUBE": Color(0.08, 0.06, 0.12), "SAT": Color(0.06, 0.06, 0.08), "GEN": Color(0.05, 0.05, 0.05),
				"PBOY": pc.darkened(0.3), "PBA": Color(0.3, 0.25, 0.6), "DUO": Color(0.85, 0.85, 0.88), "DC": Color(0.96, 0.96, 0.96)}[plat]
			scene(c, Rect2(0, 18, W, H - 18), genre, key, pc)
			rect(c, Rect2(0, 0, W, 18), band_col)
			var lc := Color(0.1, 0.1, 0.12) if band_col.get_luminance() > 0.6 else Color(0.95, 0.95, 0.95)
			if plat == "GEN":
				for k in 6:
					rect(c, Rect2(60 + k * 10, 0, 1, 18), Color(0.3, 0.3, 0.3))
				lc = Color(0.9, 0.2, 0.2)
			if plat == "DC":
				circle(c, Vector2(9, 9), 6, Color(0.95, 0.5, 0.15), 12)
				circle(c, Vector2(9, 9), 3, Color(0.96, 0.96, 0.96), 10)
			text(c, String(pd["short"]) if plat != "DC" else "    DC", Vector2(4, -2), Vector2(W, 20), 20, lc)
		"NEO":
			rect(c, Rect2(0, 0, W, H), Color(0.03, 0.03, 0.03))
			text(c, "NEON GEO", Vector2(4, 0), Vector2(W, 24), 22, Color(0.95, 0.75, 0.2))
			art = Rect2(6, 24, W - 12, 86)
			scene(c, art, genre, key, pc)
			rect(c, Rect2(0, 110, W, 2), Color(0.95, 0.75, 0.2))
			CoverComp.title(c, title, Vector2(4, 112), Vector2(W - 8, 38), 18, Color(0.95, 0.95, 0.95), item)
			title_at = "done"
		"A26":
			rect(c, Rect2(0, 0, W, H), Color(0.07, 0.05, 0.04))
			art = Rect2(8, 8, W - 16, 98)
			scene(c, art, genre, key, pc)
			for k in 3:
				rect(c, Rect2(0, 110 + k * 3, W, 2), [Color(0.9, 0.5, 0.1), Color(0.9, 0.2, 0.1), Color(0.95, 0.8, 0.2)][k])
			CoverComp.title(c, title, Vector2(4, 118), Vector2(W - 8, 32), 16, Color(0.95, 0.95, 0.95), item)
			title_at = "done"
		_:
			scene(c, Rect2(0, 0, W, H), genre, key, pc)
			rect(c, Rect2(0, 0, W, 18), Color(0.75, 0.15, 0.15) if plat == "MISC" else pc.darkened(0.4))
			text(c, "COLLECTOR" if plat == "MISC" else String(pd["short"]), Vector2(4, -2), Vector2(W, 20), 18, Color(1, 0.92, 0.6))
	if title_at == "bottom":
		# Title placement varies per game: top or bottom, with or without a band.
		var tg := RandomNumberGenerator.new()
		tg.seed = hash(key + "title")
		var top: bool = tg.randf() < 0.4 and item["kind"] == "game"
		var ty: float = (art.position.y + 2) if top else float(H - 46)
		if tg.randf() < 0.6:
			rect(c, Rect2(art.position.x, ty - 2, art.size.x, 46), Color(0.03, 0.02, 0.05, 0.55))
		CoverComp.title(c, title, Vector2(art.position.x + 3, ty), Vector2(art.size.x - 6, 44), 20, Color(1, 0.97, 0.88), item)
	CoverComp.publisher_mark(c, item, W, H)
	_variant_overlay(c, item, variant)
	# Tier frame.
	var tier := int(item.get("tier", 0))
	if tier >= 2 or variant == "Collector's Edition":
		var fc: Color = Catalog.TIER_COLORS[tier] if variant != "Collector's Edition" else Color(0.85, 0.7, 0.25)
		for r2 in [Rect2(0, 0, W, 3), Rect2(0, H - 3, W, 3), Rect2(0, 0, 3, H), Rect2(W - 3, 0, 3, H)]:
			rect(c, r2, fc)


static func _test_label(c: Control, item: Dictionary) -> void:
	rect(c, Rect2(0, 0, W, H), Color(0.97, 0.96, 0.9))
	for k in 9:
		rect(c, Rect2(0, 30 + k * 13, W, 1), Color(0.6, 0.75, 0.95))
	rect(c, Rect2(14, 0, 1, H), Color(0.95, 0.5, 0.5))
	text(c, "TEST", Vector2(18, 2), Vector2(W, 26), 26, Color(0.85, 0.15, 0.15))
	text(c, String(item["name"]).to_upper() + "\nREV 0.%d" % (absi(hash(String(item["id"]))) % 9 + 1), Vector2(18, 32), Vector2(W - 22, 100), 16, Color(0.15, 0.15, 0.35), false)
	text(c, "DO NOT SELL", Vector2(18, H - 20), Vector2(W, 20), 14, Color(0.85, 0.15, 0.15))


static func _variant_overlay(c: Control, item: Dictionary, variant: String) -> void:
	var fam := String(Catalog.platform(String(item["plat"]))["family"])
	match variant:
		"Player's Pick":
			var col: Color = {"funtendo": Color(0.95, 0.8, 0.15), "statia": Color(0.85, 0.15, 0.15), "saga": Color(0.15, 0.35, 0.85), "xbux": Color(0.95, 0.95, 0.95)}.get(fam, Color(0.9, 0.8, 0.2))
			rect(c, Rect2(0, H - 14, W, 14), col)
			text(c, Catalog.variant_label(item).to_upper(), Vector2(0, H - 16), Vector2(W, 16), 14, Color(0.1, 0.1, 0.1) if col.get_luminance() > 0.5 else Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		"Black Label":
			circle(c, Vector2(W - 14, 30), 10, Color(0.05, 0.05, 0.05), 14)
			circle(c, Vector2(W - 14, 30), 8, Color(0.85, 0.75, 0.3), 14)
			circle(c, Vector2(W - 14, 30), 6, Color(0.05, 0.05, 0.05), 14)
		"First Print":
			text(c, "1ST PRINT", Vector2(4, 20), Vector2(W, 12), 11, Color(1, 1, 1, 0.8), false)
		"Japan Import":
			circle(c, Vector2(W - 13, 31), 9, Color(0.95, 0.95, 0.95), 14)
			circle(c, Vector2(W - 13, 31), 5, Color(0.85, 0.1, 0.15), 14)
		"Rental Copy":
			rect(c, Rect2(W - 50, 22, 46, 20), Color(0.1, 0.25, 0.65))
			rect(c, Rect2(W - 48, 24, 42, 16), Color(0.95, 0.8, 0.15))
			text(c, "RENTAL", Vector2(W - 48, 22), Vector2(42, 18), 14, Color(0.1, 0.25, 0.65), true, HORIZONTAL_ALIGNMENT_CENTER)
		"Collector's Edition":
			rect(c, Rect2(0, 18, W, 12), Color(0.85, 0.7, 0.25))
			text(c, "COLLECTOR'S EDITION", Vector2(0, 16), Vector2(W, 14), 12, Color(0.15, 0.1, 0.05), true, HORIZONTAL_ALIGNMENT_CENTER)
		"Signed by Dev":
			var pts := PackedVector2Array()
			for k in 12:
				pts.append(Vector2(20 + k * 7, 70 + sin(k * 1.7) * 8))
			var line := Line2D.new()
			line.points = pts
			line.width = 2.0
			line.default_color = Color(0.9, 0.9, 0.95)
			c.add_child(line)
		"Misprint":
			# Ghost title printed off-register in magenta, and a wrong-colour band.
			var t := text(c, String(item["name"]).to_upper(), Vector2(8, 40), Vector2(W - 8, 60), 20, Color(1, 0.2, 0.7, 0.75))
			t.rotation_degrees = 180.0
			t.position = Vector2(W - 4, H * 0.67)
			rect(c, Rect2(0, 0, 6, H), Color(0.2, 0.9, 0.9))
		"Store Display", "Prototype", "Launch Edition", "Boxed Bundle", "Refurbished", "Limited Color":
			var col2: Color = Catalog.VARIANTS[variant]["color"]
			rect(c, Rect2(0, 20, W, 14), col2)
			var label: String = {"Store Display": "NOT FOR RESALE", "Prototype": "PROTOTYPE", "Launch Edition": "LAUNCH EDITION",
				"Boxed Bundle": "BUNDLE!", "Refurbished": "REFURBISHED", "Limited Color": "LIMITED EDITION"}[variant]
			text(c, label, Vector2(0, 18), Vector2(W, 16), 14, Color(0.08, 0.08, 0.08) if col2.get_luminance() > 0.5 else Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)


# ---------------------------------------------------------------- back

static func paint_back(c: Control, item: Dictionary) -> void:
	if Catalog.is_cc(item):
		CCArt.H = H
		CCArt.paint_back(c, item, W)
		return
	CoverComp.current_title = String(item.get("name", ""))
	_product = Art.icon(item, false) if String(item.get("kind", "game")) != "game" else null
	var plat := String(item["plat"])
	var pd: Dictionary = Catalog.platform(plat)
	var pc: Color = pd["color"]
	var key := String(item["id"])
	var genre := String(item.get("genre", "Action"))
	if item["kind"] != "game":
		genre = "Hardware"
	rect(c, Rect2(0, 0, W, H), Color(0.08, 0.07, 0.1) if plat in ["FES", "NEO", "GEN", "SAT", "PST2", "FCUBE"] else pc.darkened(0.65))
	rect(c, Rect2(0, 0, W, 14), pc.darkened(0.2))
	text(c, String(pd["name"]).to_upper(), Vector2(3, -2), Vector2(W, 16), 14, Color(1, 1, 1, 0.9))
	# Three "screenshots".
	var wide := W >= 150
	var sw := (W - 16) / 3.0 if wide else (W - 12) / 2.0
	for k in 3:
		var sr := Rect2(4 + (k % 2) * (sw + 4), 18 + (k / 2) * 40, sw, 36)
		if wide:
			sr = Rect2(4 + k * (sw + 4), 18, sw, 36)
		elif k == 2:
			sr = Rect2(4, 58, sw, 36)
		rect(c, sr.grow(1), Color(0.9, 0.9, 0.9))
		scene(c, sr, genre, key + "s%d" % k, pc)
	if wide:
		text(c, String(item.get("blurb", "")), Vector2(4, 56), Vector2(W - 8, 40), 11, Color(0.92, 0.92, 0.9), false)
	else:
		text(c, String(item.get("blurb", "")), Vector2(sw + 8, 56), Vector2(W - sw - 10, 44), 11, Color(0.92, 0.92, 0.9), false)
	text(c, String(item["name"]), Vector2(4, 96), Vector2(W - 8, 14), 12, Color(1, 0.9, 0.5), true, HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), false)
	text(c, "%d %s. %s" % [int(item.get("year", 1990)), String(item.get("pub", "")), String(item.get("genre", ""))], Vector2(4, 108), Vector2(W - 8, 12), 10, Color(0.8, 0.8, 0.85), false, HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), false)
	# Rating box, barcode.
	var rating := String(item.get("rating", ""))
	if rating != "":
		rect(c, Rect2(4, H - 30, 22, 26), Color(0.95, 0.95, 0.95))
		rect(c, Rect2(5, H - 29, 20, 18), Color(0.05, 0.05, 0.05))
		text(c, rating, Vector2(5, H - 31), Vector2(20, 20), 20, Color.WHITE, true, HORIZONTAL_ALIGNMENT_CENTER)
		text(c, "ESRP", Vector2(5, H - 13), Vector2(20, 10), 8, Color(0.05, 0.05, 0.05), false, HORIZONTAL_ALIGNMENT_CENTER)
	var g := RandomNumberGenerator.new()
	g.seed = hash(key + "bar")
	rect(c, Rect2(W - 44, H - 24, 40, 20), Color.WHITE)
	var x := W - 42.0
	while x < W - 6:
		var bw := float(g.randi_range(1, 2))
		rect(c, Rect2(x, H - 22, bw, 13), Color.BLACK)
		x += bw + g.randi_range(1, 2)
	text(c, "%06d" % (absi(hash(key)) % 1000000), Vector2(W - 44, H - 10), Vector2(40, 8), 7, Color.BLACK, false, HORIZONTAL_ALIGNMENT_CENTER)
	text(c, "(c) %d\n%s" % [int(item.get("year", 1990)), String(item.get("pub", ""))], Vector2(30, H - 24), Vector2(48, 22), 8, Color(0.75, 0.75, 0.8), false)
