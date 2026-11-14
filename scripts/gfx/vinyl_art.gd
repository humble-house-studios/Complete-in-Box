extends RefCounted
## Paints vinyl records and crates (CCArt hands over kinds "record" and "crate").
## No class_name (TV self-update): preload it.
##
##   Fronts: the real sleeve when tools/fetch_world_art.py found one shaped
##   like a record (def "scan", square). Otherwise painted by the def's "fmt":
##     LP: a picture sleeve in the house style of its binder page:
##       ROCK  full-bleed art or a psychedelic sunburst, chunky title.
##       JAZZ  a tinted photo block and a big type block, label-style bars.
##       SOUL  a glowing portrait wash, script title, label badge.
##       PUNK  a ransom-note title cut from mismatched letters on photocopy.
##       HIPH  a neon title over a dark brick wall, sticker logos.
##     7in: the label's company sleeve, a hole showing the record label.
##     12in: a die-cut dance sleeve (hole, big logo) or a picture sleeve.
##     78: a brown kraft sleeve with the shellac label showing.
##   Variants: test pressing (plain white sleeve, handwritten sticker), promo
##   (a gold NOT FOR SALE stamp), mono / first pressing / reissue stickers,
##   Japanese pressing (the paper obi strip), coloured vinyl and picture disc
##   (hype stickers), cut-out (a clipped corner), record club, signed (silver
##   marker), DJ's own copy (a radio station's library sticker).
##   Backs: track listing by side, the label's logo and a catalogue number.
##   Crates: a plastic milk crate with sleeves sticking out of the top.

const CCArt := preload("res://scripts/gfx/cc_art.gd")
## Fallback picture subjects per binder page.
const SUBJ := {"ROCK": "guitar", "JAZZ": "saxophone", "SOUL": "microphone", "PUNK": "exploding_head", "HIPH": "headphone"}
const PAGE_FONTS := {"ROCK": ["right", "bungee", "monoton", "lucky"], "JAZZ": ["russo", "blackops", "rubik"], "SOUL": ["pacifico", "right", "lucky"],
	"PUNK": ["marker", "blackops", "creep"], "HIPH": ["bangers", "marker", "audio"]}
const RANSOM := ["blackops", "russo", "bungee", "marker", "creep", "lucky", "rubik", "cinzel", "bangers"]
const VINYL := Color(0.06, 0.06, 0.07)
const WORDS_A := ["Midnight", "Blue", "Lonely", "Electric", "Sweet", "Broken", "Golden", "Late", "Crazy", "Little", "Moon", "Summer", "Silver", "Wild", "Velvet", "Last"]
const WORDS_B := ["Train", "Heart", "Radio", "Groove", "Street", "Baby", "Dream", "Blues", "Fever", "Dancer", "Night", "Static", "Rain", "Highway", "Signal", "Song"]

static var W := 150
static var H := 150


static func _t(c: Control, txt: String, pos: Vector2, size: Vector2, fs: int, col: Color, fname := "jersey", align := HORIZONTAL_ALIGNMENT_CENTER, outline := Color(0, 0, 0, 0), wrap := false) -> Label:
	return CCArt._t(c, txt, pos, size, fs, col, fname, align, outline, wrap)


static func _rng(key: String) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = hash(key)
	return g


static func _tex(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


static func _img(c: Control, t: Texture2D, r: Rect2, tint := Color.WHITE) -> void:
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.size = r.size
	tr.modulate = tint
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	holder.add_child(tr)


## The picture panel: the def's photo, or a subject render on a soft wash.
static func _art(c: Control, r: Rect2, d: Dictionary, tint := Color.WHITE) -> void:
	var t := _tex(String(d.get("photo", "")))
	if t != null:
		_img(c, t, r, tint)
		return
	var g := _rng(String(d.get("id", "")) + "art")
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	var pc: Color = Catalog.platform(String(d["plat"]))["color"]
	var hue := fmod(pc.h + g.randf_range(-0.12, 0.12) + 1.0, 1.0)
	CoverComp.gradient(holder, Rect2(Vector2.ZERO, r.size), Color.from_hsv(hue, 0.45, 0.95), Color.from_hsv(fmod(hue + 0.08, 1.0), 0.65, 0.45))
	var subs := CoverComp.subjects_for(String(d.get("name", "")))
	var ref := String(subs[0]) if not subs.is_empty() else String(SUBJ.get(String(d["plat"]), "musical_notes"))
	CoverComp.cg(holder, g, ref, Vector2(r.size.x * 0.5, r.size.y * 0.96), r.size.y * 0.8, g.randf() < 0.5)
	holder.modulate = tint


static func _title(c: Control, d: Dictionary, r: Rect2, col: Color, font: String, outline := Color(0, 0, 0, 0)) -> void:
	_t(c, String(d.get("name", "")), r.position, r.size, int(r.size.y * 0.42), col, font, HORIZONTAL_ALIGNMENT_CENTER, outline, true)


static func _artist(c: Control, d: Dictionary, r: Rect2, col: Color, font := "russo", align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	_t(c, String(d.get("artist", "")).to_upper(), r.position, r.size, int(r.size.y), col, font, align)


static func paint_front(c: Control, d: Dictionary, w: int) -> void:
	W = w
	if String(d.get("kind", "")) == "crate":
		_crate(c, d)
		return
	var v := String(d.get("variant", "Standard"))
	var fmt := String(d.get("fmt", "LP"))
	var scan := _tex(String(d.get("scan", "")))
	if v == "Test Pressing":
		_test(c, d)
	elif fmt == "78":
		_kraft(c, d)
	elif scan != null:
		_img(c, scan, Rect2(0, 0, W, H))
	elif fmt == "7in":
		_company(c, d)
	elif fmt == "12in":
		if _rng(String(d["id"]) + "12").randf() < 0.5:
			_company(c, d, true)
		else:
			_sleeve(c, d)
	else:
		_sleeve(c, d)
	# Ring wear from decades in a stack (scans already show their own).
	if scan == null and v != "Test Pressing" and fmt == "LP":
		var cond := String(d.get("cond", "CIB"))
		if cond == "Damaged" or cond == "Loose":
			_ring(c, Vector2(W * 0.5, H * 0.5), W * 0.44, Color(1, 1, 1, 0.13 if cond == "Damaged" else 0.07))
	_variant(c, d)


## A faint ring: the record's outline rubbed through the sleeve.
static func _ring(c: Control, ctr: Vector2, r: float, col: Color) -> void:
	var n := 40
	for i in n:
		if i % 7 == 3:
			continue
		var a := TAU * i / n
		BoxArt.rect(c, Rect2(ctr + Vector2(cos(a), sin(a)) * r - Vector2(1.5, 1.5), Vector2(3, 3)), col)


## The record label in the middle of a disc: a coloured circle with text.
static func _label(c: Control, d: Dictionary, ctr: Vector2, r: float) -> void:
	var g := _rng(String(d.get("imprint", "")) + "lab")
	var lc := Color.from_hsv(g.randf(), g.randf_range(0.4, 0.85), g.randf_range(0.55, 0.95))
	if String(d.get("variant", "")) == "White Label Promo":
		lc = Color(0.95, 0.95, 0.92)
	BoxArt.circle(c, ctr, r + r * 1.7, VINYL, 30)
	for k in 3:
		CCArt._frame(c, Rect2(ctr - Vector2.ONE * (r * (1.3 + k * 0.4)), Vector2.ONE * r * (2.6 + k * 0.8)), Color(1, 1, 1, 0.03), 1.0)
	BoxArt.circle(c, ctr, r, lc, 24)
	var ink := Color(0.05, 0.05, 0.05) if lc.v > 0.6 else Color(0.97, 0.95, 0.9)
	_t(c, String(d.get("imprint", "")).to_upper(), ctr + Vector2(-r * 0.8, -r * 0.8), Vector2(r * 1.6, r * 0.38), 9, ink, "russo")
	BoxArt.circle(c, ctr, r * 0.1, Color(0.9, 0.88, 0.85), 10)
	_t(c, String(d.get("name", "")), ctr + Vector2(-r * 0.85, r * 0.15), Vector2(r * 1.7, r * 0.34), 8, ink, "jersey")
	_t(c, String(d.get("artist", "")), ctr + Vector2(-r * 0.75, r * 0.48), Vector2(r * 1.5, r * 0.28), 7, ink, "jersey")


## An LP picture sleeve in the page's house style.
static func _sleeve(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "sl")
	var plat := String(d["plat"])
	var fonts: Array = PAGE_FONTS.get(plat, ["right"])
	var font := String(fonts[g.randi() % fonts.size()])
	var pc: Color = Catalog.platform(plat)["color"]
	var base := Color.from_hsv(fmod(pc.h + g.randf_range(-0.15, 0.15) + 1.0, 1.0), g.randf_range(0.45, 0.85), g.randf_range(0.35, 0.9))
	var ink := Color(0.98, 0.96, 0.9) if base.v < 0.6 else Color(0.06, 0.05, 0.07)
	match plat:
		"JAZZ":
			# A tinted photo block and a big type block, the hard-bop way.
			BoxArt.rect(c, Rect2(0, 0, W, H), base)
			var top := g.randf() < 0.5
			var pr := Rect2(0, 0 if top else H * 0.42, W, H * 0.58)
			_art(c, pr, d, Color(base.lightened(0.5), 1.0))
			var tr := Rect2(6, H * 0.6 if top else 4, W - 12, H * 0.22)
			_title(c, d, tr, ink, font)
			_artist(c, d, Rect2(6, tr.end.y, W - 12, 12), ink, "russo")
			BoxArt.rect(c, Rect2(0, H * (0.58 if top else 0.4), W, 3), Color(0.98, 0.96, 0.9))
		"SOUL":
			CoverComp.gradient(c, Rect2(0, 0, W, H), base.lightened(0.25), base.darkened(0.45), true)
			_art(c, Rect2(W * 0.12, H * 0.16, W * 0.76, H * 0.66), d)
			_title(c, d, Rect2(6, H * 0.74, W - 12, 30), Color(1.0, 0.95, 0.8), font, Color(0, 0, 0, 0.5))
			_artist(c, d, Rect2(6, 6, W - 12, 13), Color(1.0, 0.92, 0.7), "right")
			BoxArt.circle(c, Vector2(W - 16, 18), 10, Color(0.95, 0.85, 0.3), 14)
			_t(c, String(d.get("imprint", "")).left(4).to_upper(), Vector2(W - 26, 13), Vector2(20, 10), 6, Color(0.1, 0.05, 0.05), "russo")
		"PUNK":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.92, 0.9, 0.85))
			_art(c, Rect2(0, 0, W, H), d, Color(0.85, 0.85, 0.85))
			# Photocopy grain.
			for k in 90:
				BoxArt.rect(c, Rect2(g.randf() * W, g.randf() * H, g.randf_range(1, 3), 1), Color(0, 0, 0, 0.25))
			_ransom(c, d, Rect2(6, H * 0.1, W - 12, H * 0.36), g)
			BoxArt.rect(c, Rect2(0, H - 22, W, 16), Color(1.0, 0.3, 0.6) if g.randf() < 0.5 else Color(1.0, 0.9, 0.2))
			_artist(c, d, Rect2(4, H - 21, W - 8, 14), Color(0.05, 0.05, 0.05), "marker")
		"HIPH":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.12, 0.09, 0.1))
			for y in range(0, H, 10):
				for x in range(0 if (y / 10) % 2 == 0 else -10, W, 20):
					BoxArt.rect(c, Rect2(x + 1, y + 1, 18, 8), Color(0.32, 0.14, 0.12, 0.9))
			_art(c, Rect2(W * 0.18, H * 0.3, W * 0.64, H * 0.6), d)
			var neon := Color.from_hsv(fmod(pc.h + g.randf_range(-0.3, 0.3) + 1.0, 1.0), 0.7, 1.0)
			_title(c, d, Rect2(6, 6, W - 12, H * 0.26), neon, font, Color(0, 0, 0, 0.85))
			_artist(c, d, Rect2(6, H - 18, W - 12, 13), Color.WHITE, "marker")
		_:
			if g.randf() < 0.5:
				# Full-bleed art, a title band.
				_art(c, Rect2(0, 0, W, H), d)
				BoxArt.rect(c, Rect2(0, 0, W, H * 0.26), Color(base, 0.85))
				_title(c, d, Rect2(6, 4, W - 12, H * 0.2), ink, font)
				_artist(c, d, Rect2(6, H - 16, W - 12, 12), Color.WHITE, "russo")
			else:
				# A psychedelic sunburst behind a round picture.
				BoxArt.rect(c, Rect2(0, 0, W, H), base.darkened(0.2))
				var ctr := Vector2(W * 0.5, H * 0.58)
				for i in 16:
					var a0 := TAU * i / 16.0
					var a1 := TAU * (i + 0.5) / 16.0
					BoxArt.poly(c, PackedVector2Array([ctr, ctr + Vector2(cos(a0), sin(a0)) * W, ctr + Vector2(cos(a1), sin(a1)) * W]),
						Color.from_hsv(fmod(base.h + 0.1 * (i % 3), 1.0), 0.75, 0.95, 0.85))
				_art(c, Rect2(W * 0.22, H * 0.34, W * 0.56, H * 0.5), d)
				_title(c, d, Rect2(4, 4, W - 8, H * 0.24), Color.WHITE, font, Color(0, 0, 0, 0.8))
				_artist(c, d, Rect2(6, H - 16, W - 12, 12), Color.WHITE, "russo")


## A ransom-note title: every letter cut from a different paper.
static func _ransom(c: Control, d: Dictionary, r: Rect2, g: RandomNumberGenerator) -> void:
	var txt := String(d.get("name", "")).to_upper()
	var words := txt.split(" ")
	var x := r.position.x
	var y := r.position.y
	var sz := clampf(r.size.x / 7.0, 11.0, 18.0)
	for wd in words:
		if x + sz * wd.length() * 0.8 > r.end.x and x > r.position.x:
			x = r.position.x
			y += sz * 1.15
		if y > r.end.y:
			break
		for ch in wd:
			var holder := Control.new()
			holder.position = Vector2(x, y)
			holder.size = Vector2(sz * 0.85, sz)
			holder.pivot_offset = holder.size * 0.5
			holder.rotation_degrees = g.randf_range(-12, 12)
			c.add_child(holder)
			var paper := Color.from_hsv(g.randf(), g.randf_range(0.0, 0.7), g.randf_range(0.1, 1.0))
			BoxArt.rect(holder, Rect2(Vector2.ZERO, holder.size), paper)
			_t(holder, ch, Vector2.ZERO, holder.size, int(sz * 0.8), Color(0.05, 0.05, 0.05) if paper.v > 0.55 else Color(0.97, 0.97, 0.95), String(RANSOM[g.randi() % RANSOM.size()]))
			x += sz * 0.8
		x += sz * 0.4


## A company sleeve: the label's own paper bag with a hole showing the record.
static func _company(c: Control, d: Dictionary, die_cut := false) -> void:
	var g := _rng(String(d.get("imprint", "")) + "co")
	var col := Color.from_hsv(g.randf(), g.randf_range(0.5, 0.9), g.randf_range(0.4, 0.85))
	if die_cut:
		col = [Color(0.08, 0.08, 0.09), Color(0.95, 0.94, 0.9), col][g.randi() % 3]
	var ink := Color(0.98, 0.96, 0.9) if col.v < 0.6 else Color(0.06, 0.05, 0.07)
	BoxArt.rect(c, Rect2(0, 0, W, H), col)
	# The logo repeated in stripes, the way 60s sleeves did it.
	for k in 4:
		_t(c, String(d.get("imprint", "")).to_upper(), Vector2(4, 4 + k * (H - 16) / 3.0), Vector2(W - 8, 12), 11, Color(ink, 0.35), "russo")
	_label(c, d, Vector2(W * 0.5, H * 0.5), W * 0.17)
	if die_cut:
		_t(c, "12\" SINGLE  33 RPM", Vector2(4, H - 14), Vector2(W - 8, 10), 8, ink, "russo")
	else:
		_t(c, "45 RPM", Vector2(4, H - 14), Vector2(W - 8, 10), 8, ink, "russo")


## A 78: a brown kraft paper sleeve with the shellac label in the hole.
static func _kraft(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "kr")
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.62, 0.48, 0.3))
	for k in 30:
		BoxArt.rect(c, Rect2(0, g.randf() * H, W, 1), Color(0.4, 0.3, 0.18, 0.25))
	_t(c, "%s RECORDS" % String(d.get("imprint", "")).to_upper(), Vector2(4, 6), Vector2(W - 8, 12), 11, Color(0.25, 0.16, 0.08), "cinzel")
	_t(c, "Play with a fresh needle", Vector2(4, H - 16), Vector2(W - 8, 10), 8, Color(0.25, 0.16, 0.08), "jersey")
	_label(c, d, Vector2(W * 0.5, H * 0.52), W * 0.19)


## Test pressing: a plain white sleeve with a handwritten sticker.
static func _test(c: Control, d: Dictionary) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.94, 0.93, 0.9))
	BoxArt.circle(c, Vector2(W * 0.5, H * 0.5), W * 0.2, Color(0.82, 0.8, 0.76), 24)
	BoxArt.rect(c, Rect2(W * 0.12, H * 0.1, W * 0.76, H * 0.24), Color(1, 1, 1))
	CCArt._frame(c, Rect2(W * 0.12, H * 0.1, W * 0.76, H * 0.24), Color(0.3, 0.3, 0.3), 1.0)
	_t(c, "TEST PRESSING", Vector2(W * 0.14, H * 0.11), Vector2(W * 0.72, 10), 8, Color(0.4, 0.1, 0.1), "russo")
	_t(c, String(d.get("name", "")), Vector2(W * 0.14, H * 0.18), Vector2(W * 0.72, 18), 14, Color(0.1, 0.12, 0.4), "marker")
	_t(c, "OK - M.", Vector2(W * 0.5, H * 0.74), Vector2(W * 0.4, 20), 16, Color(0.1, 0.12, 0.4), "marker")


static func _sticker(c: Control, txt: String, ctr: Vector2, r: float, col: Color, ink := Color(0.05, 0.05, 0.05)) -> void:
	BoxArt.circle(c, ctr, r, col, 18)
	_t(c, txt, ctr - Vector2(r, r * 0.8), Vector2(r * 2, r * 1.6), int(r * 0.55), ink, "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)


static func _variant(c: Control, d: Dictionary) -> void:
	var v := String(d.get("variant", "Standard"))
	match v:
		"Japanese Pressing":
			# The obi: a paper strip wrapped round the left edge.
			BoxArt.rect(c, Rect2(0, 0, 20, H), Color(0.97, 0.96, 0.92))
			BoxArt.rect(c, Rect2(0, 0, 20, 20), Color(0.82, 0.12, 0.14))
			var txt := "OBI  LIMITED"
			for i in txt.length():
				_t(c, txt[i], Vector2(2, 24 + i * 9), Vector2(16, 9), 8, Color(0.1, 0.1, 0.1), "russo")
			_t(c, "Y2500", Vector2(1, H - 14), Vector2(18, 10), 6, Color(0.1, 0.1, 0.1), "jersey")
		"White Label Promo":
			var holder := Control.new()
			holder.position = Vector2(W * 0.1, H * 0.68)
			holder.size = Vector2(W * 0.8, 26)
			holder.pivot_offset = holder.size * 0.5
			holder.rotation_degrees = -8.0
			c.add_child(holder)
			CCArt._frame(holder, Rect2(Vector2.ZERO, holder.size), Color(0.85, 0.65, 0.2, 0.95), 2.0)
			_t(holder, "PROMOTIONAL COPY\nNOT FOR SALE", Vector2(2, 1), holder.size - Vector2(4, 2), 10, Color(0.85, 0.65, 0.2, 0.95), "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)
		"Mono Pressing":
			BoxArt.rect(c, Rect2(W - 38, 4, 34, 14), Color(0.98, 0.97, 0.94))
			CCArt._frame(c, Rect2(W - 38, 4, 34, 14), Color(0.1, 0.1, 0.1), 1.0)
			_t(c, "MONO", Vector2(W - 38, 4), Vector2(34, 14), 10, Color(0.1, 0.1, 0.1), "russo")
		"First Pressing":
			BoxArt.rect(c, Rect2(2, 2, 46, 12), Color(0.15, 0.35, 0.75, 0.92))
			_t(c, "1ST PRESS", Vector2(2, 2), Vector2(46, 12), 8, Color.WHITE, "russo")
		"Reissue":
			BoxArt.rect(c, Rect2(W - 52, H - 18, 48, 14), Color(0.98, 0.98, 0.98))
			_t(c, "180g REISSUE", Vector2(W - 52, H - 18), Vector2(48, 14), 7, Color(0.1, 0.1, 0.1), "russo")
		"Record Club Pressing":
			_t(c, "RECORD CLUB EDITION  RC-%d" % (1000 + hash(String(d["id"])) % 9000), Vector2(4, H - 10), Vector2(W - 8, 8), 6, Color(1, 1, 1, 0.85), "russo", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.6))
		"Cut-Out":
			BoxArt.poly(c, PackedVector2Array([Vector2(W, H), Vector2(W - 22, H), Vector2(W, H - 22)]), Color(0.92, 0.9, 0.84))
			BoxArt.circle(c, Vector2(W - 10, 10), 4, Color(0.08, 0.08, 0.08), 10)
		"Colored Vinyl":
			var hue := float(absi(hash(String(d["id"]))) % 100) / 100.0
			_sticker(c, "LIMITED\nCOLOURED\nVINYL", Vector2(W - 24, H - 26), 20, Color.from_hsv(hue, 0.7, 1.0))
		"Picture Disc":
			_sticker(c, "PICTURE\nDISC", Vector2(W - 24, 26), 20, Color(0.95, 0.9, 0.3))
			CoverComp.glow(c, Vector2(W * 0.3, H * 0.3), W * 0.5, Color(1, 1, 1, 0.12))
		"Signed Sleeve":
			var who := String(d.get("artist", "A")).split(" ")
			var sig := String(who[who.size() - 1])
			_t(c, sig, Vector2(W * 0.08, H * 0.45), Vector2(W * 0.84, 36), 20, Color(0.92, 0.92, 0.95), "marker", HORIZONTAL_ALIGNMENT_CENTER, Color(0.1, 0.1, 0.12, 0.8))
		"Pedigree":
			BoxArt.rect(c, Rect2(W * 0.18, 4, W * 0.64, 18), Color(0.98, 0.96, 0.88))
			CCArt._frame(c, Rect2(W * 0.18, 4, W * 0.64, 18), Color(0.6, 0.1, 0.1), 1.0)
			_t(c, "WMRV LIBRARY\nDO NOT REMOVE", Vector2(W * 0.18, 4), Vector2(W * 0.64, 18), 7, Color(0.6, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)
		"Misprint":
			BoxArt.rect(c, Rect2(0, H * 0.5, W, 3), Color(0.9, 0.2, 0.3, 0.6))
			_t(c, "WRONG LABEL", Vector2(4, H * 0.5 + 4), Vector2(W - 8, 10), 7, Color(1, 1, 1, 0.8), "russo", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.7))


## Fake track titles, the same every time for a record.
static func _tracks(d: Dictionary) -> Array:
	var g := _rng(String(d["id"]) + "trk")
	var out: Array = []
	for i in int(d.get("tracks", 10)):
		out.append("%s %s" % [WORDS_A[g.randi() % WORDS_A.size()], WORDS_B[g.randi() % WORDS_B.size()]])
	return out


static func paint_back(c: Control, d: Dictionary, w: int) -> void:
	W = w
	if String(d.get("kind", "")) == "crate":
		_crate(c, d, true)
		return
	var g := _rng(String(d["id"]) + "back")
	var fmt := String(d.get("fmt", "LP"))
	if fmt == "7in" or fmt == "78" or (fmt == "12in" and g.randf() < 0.5):
		# The back of a company sleeve shows the B-side label through the hole.
		if fmt == "78":
			_kraft(c, d)
		else:
			_company(c, d, fmt == "12in")
		_t(c, "B-SIDE", Vector2(4, 22), Vector2(W - 8, 10), 8, Color(1, 1, 1, 0.8), "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.6))
		return
	var paper := Color(0.95, 0.93, 0.88) if g.randf() < 0.6 else Color(0.1, 0.1, 0.12)
	var ink := Color(0.1, 0.1, 0.1) if paper.v > 0.5 else Color(0.92, 0.92, 0.9)
	BoxArt.rect(c, Rect2(0, 0, W, H), paper)
	_t(c, String(d.get("name", "")), Vector2(6, 4), Vector2(W - 12, 14), 12, ink, "russo")
	_artist(c, d, Rect2(6, 18, W - 12, 9), ink.lerp(paper, 0.3), "jersey")
	var tr := _tracks(d)
	var half := int(ceil(tr.size() / 2.0))
	for side in 2:
		var x := 6.0 + side * (W - 12) * 0.5
		_t(c, "SIDE %s" % ["ONE", "TWO"][side], Vector2(x, 32), Vector2((W - 12) * 0.5, 9), 8, Color(0.75, 0.2, 0.2), "russo", HORIZONTAL_ALIGNMENT_LEFT)
		for i in half:
			var k := side * half + i
			if k >= tr.size():
				break
			_t(c, "%d. %s" % [i + 1, tr[k]], Vector2(x, 43 + i * 9), Vector2((W - 12) * 0.5 - 2, 9), 7, ink, "jersey", HORIZONTAL_ALIGNMENT_LEFT)
	# Liner-note block, the logo and the catalogue number.
	for k in 4:
		BoxArt.rect(c, Rect2(6, H - 46 + k * 5, W * (0.5 + 0.1 * (k % 2)), 2), Color(ink, 0.3))
	BoxArt.circle(c, Vector2(W - 20, H - 22), 12, Color.from_hsv(_rng(String(d.get("imprint", "")) + "lab").randf(), 0.7, 0.8), 16)
	_t(c, String(d.get("imprint", "")).left(5).to_upper(), Vector2(W - 32, H - 27), Vector2(24, 10), 6, Color.WHITE, "russo")
	var cat := "%s-%d" % [String(d.get("imprint", "LP")).left(2).to_upper(), 1000 + absi(hash(String(d["id"]))) % 9000]
	_t(c, cat, Vector2(6, H - 14), Vector2(W * 0.5, 10), 8, ink, "russo", HORIZONTAL_ALIGNMENT_LEFT)


## A milk crate of records: plastic grid, sleeves sticking out of the top.
static func _crate(c: Control, d: Dictionary, back := false) -> void:
	var g := _rng(String(d["id"]) + ("crb" if back else "cr"))
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.16, 0.14, 0.16))
	# Sleeve tops poking out above the crate.
	var x := 4.0
	while x < W - 6:
		var sw := g.randf_range(6, 14)
		var sh := g.randf_range(24, 40)
		BoxArt.rect(c, Rect2(x, 34 - sh * 0.5, sw, sh), Color.from_hsv(g.randf(), g.randf_range(0.3, 0.8), g.randf_range(0.35, 0.95)))
		x += sw + 1
	var crate_col: Color = [Color(0.75, 0.12, 0.12), Color(0.15, 0.3, 0.7), Color(0.12, 0.12, 0.13), Color(0.85, 0.65, 0.15)][g.randi() % 4]
	BoxArt.rect(c, Rect2(0, 44, W, H - 44), crate_col)
	# The open grid.
	for row in 4:
		for col in 6:
			BoxArt.rect(c, Rect2(6 + col * (W - 12) / 6.0, 52 + row * (H - 64) / 4.0, (W - 12) / 6.0 - 4, (H - 64) / 4.0 - 4), crate_col.darkened(0.55))
	BoxArt.rect(c, Rect2(W * 0.3, 48, W * 0.4, 9), crate_col.darkened(0.7))
	var lab: String = ["RECORDS", "MARV - UNFLIPPED", "DO NOT SELL", "BASEMENT", "45s", "KEEPERS?"][g.randi() % 6]
	if back:
		lab = "%d RECORDS (APPROX)" % int(d.get("count", 60))
	BoxArt.rect(c, Rect2(10, H * 0.48, W - 20, 30), Color(0.9, 0.85, 0.6, 0.92))
	var tl := _t(c, lab, Vector2(12, H * 0.48), Vector2(W - 24, 30), 16, Color(0.1, 0.1, 0.12), "marker")
	tl.rotation_degrees = g.randf_range(-4, 4)
	_t(c, String(Catalog.platform(String(d["plat"]))["name"]).to_upper(), Vector2(10, H * 0.48 + 34), Vector2(W - 20, 14), 10, Color(0.98, 0.95, 0.85), "marker", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.7))
	if String(d.get("variant", "")) == "Resealed?":
		var t2 := BoxArt.rect(c, Rect2(-4, H - 30, W + 8, 10), Color(0.85, 0.75, 0.45, 0.65))
		t2.rotation_degrees = 4.0
