extends RefCounted
## Paints comics and longboxes (CCArt hands over kinds "comic" and "longbox").
## No class_name (TV self-update): preload it.
##
##   Fronts: the real cover when tools/fetch_world_art.py found one shaped
##   like a cover (def "scan"), with a small corner box added. Otherwise a
##   painted cover in the style of its era:
##     Golden: yellowed paper, a big arched title, 10¢ in a circle.
##     Silver/Bronze: the publisher's corner box (price, issue, a face),
##       title banner, a Comics Code stamp, the art panel.
##     Modern: full-bleed art, a slim logo, a barcode box.
##     Indie: black and white, a small-press logo, photocopy grain.
##   The art panel is the character's photo (def "photo") or a superhero /
##   subject render on a starburst. Variants: foil, virgin (no text), newsstand
##   barcode, price variant box, signature, restored (a purple tint).
##   Backs: an ad page from the era (sea creatures by mail, X-ray glasses,
##   muscles in seven days...). Longboxes: cardboard with a marker label.

const CCArt := preload("res://scripts/gfx/cc_art.gd")
const SUBJ := {"GLDN": "person_superhero", "SLVR": "person_superhero", "BRNZ": "person_supervillain", "MODN": "person_superhero", "INDY": "ninja"}

static var W := 97
static var H := 150


static func _t(c: Control, txt: String, pos: Vector2, size: Vector2, fs: int, col: Color, fname := "jersey", align := HORIZONTAL_ALIGNMENT_LEFT, outline := Color(0, 0, 0, 0)) -> Label:
	return CCArt._t(c, txt, pos, size, fs, col, fname, align, outline)


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


## The art panel: the character photo, or a hero render on a starburst.
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
	var hue := fmod(pc.h + g.randf_range(-0.15, 0.15) + 1.0, 1.0)
	CoverComp.gradient(holder, Rect2(Vector2.ZERO, r.size), Color.from_hsv(hue, 0.7, 0.95), Color.from_hsv(fmod(hue + 0.5, 1.0), 0.8, 0.45))
	var ctr := Vector2(r.size.x * 0.5, r.size.y * 0.45)
	for k in 14:
		var a := TAU * k / 14.0
		BoxArt.poly(holder, PackedVector2Array([ctr, ctr + Vector2(cos(a), sin(a)) * 140, ctr + Vector2(cos(a + 0.22), sin(a + 0.22)) * 140]), Color(1, 1, 0.8, 0.16))
	CoverComp.cg(holder, g, String(SUBJ.get(String(d["plat"]), "person_superhero")), Vector2(r.size.x * 0.5, r.size.y * 0.98), r.size.y * 0.9, g.randf() < 0.5)


static func paint_front(c: Control, d: Dictionary, w: int) -> void:
	W = w
	if String(d.get("kind", "")) == "longbox":
		_longbox(c, d)
		return
	var v := String(d.get("variant", "Standard"))
	var plat := String(d["plat"])
	var scan := _tex(String(d.get("scan", "")))
	if v == "Virgin Cover":
		_art(c, Rect2(0, 0, W, H), d)
	elif scan != null:
		_img(c, scan, Rect2(0, 0, W, H), Color(1.0, 0.94, 0.85) if plat == "GLDN" else Color.WHITE)
	else:
		match plat:
			"GLDN": _golden(c, d)
			"SLVR", "BRNZ": _corner_box_era(c, d)
			"MODN": _modern(c, d)
			_: _indie(c, d)
	_variant(c, d, scan != null)


static func _title(c: Control, d: Dictionary, r: Rect2, col: Color, font := "bangers", outline := Color(0, 0, 0, 0.9)) -> void:
	_t(c, String(d.get("set", d.get("name", ""))).to_upper(), r.position, r.size, int(r.size.y), col, font, HORIZONTAL_ALIGNMENT_CENTER, outline)


static func _golden(c: Control, d: Dictionary) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.93, 0.86, 0.66))
	_art(c, Rect2(4, 30, W - 8, H - 36), d, Color(1.0, 0.92, 0.78))
	BoxArt.rect(c, Rect2(0, 0, W, 30), Color(0.93, 0.86, 0.66))
	_title(c, d, Rect2(14, 2, W - 28, 24), Color(0.85, 0.15, 0.1), "lucky", Color(0.15, 0.1, 0.05))
	BoxArt.circle(c, Vector2(9, 9), 8, Color(0.95, 0.85, 0.2), 14)
	_t(c, String(d.get("price", "10¢")), Vector2(1, 3), Vector2(16, 12), 8, Color(0.1, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, "No. %s" % String(d.get("issue", "1")), Vector2(W - 26, 3), Vector2(24, 10), 8, Color(0.1, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_RIGHT)
	# A coverline banner across the bottom.
	BoxArt.rect(c, Rect2(4, H - 18, W - 8, 13), Color(0.95, 0.85, 0.2, 0.92))
	_t(c, String(d.get("note", "")).to_upper(), Vector2(6, H - 18), Vector2(W - 12, 13), 8, Color(0.6, 0.08, 0.05), "bangers", HORIZONTAL_ALIGNMENT_CENTER)


static func _corner_box_era(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "cb")
	var bronze := String(d["plat"]) == "BRNZ"
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.97, 0.97, 0.95))
	_art(c, Rect2(2, 28, W - 4, H - 30), d)
	# Title banner and the publisher's corner box.
	var bc := Color.from_hsv(g.randf(), 0.75, 0.85)
	BoxArt.rect(c, Rect2(0, 0, W, 28), bc)
	_title(c, d, Rect2(26, 2, W - 30, 22), Color(1, 0.95, 0.4), "bangers")
	BoxArt.rect(c, Rect2(2, 2, 22, 24), Color(0.98, 0.98, 0.96))
	_t(c, String(d.get("pub", "")).left(6).to_upper(), Vector2(2, 2), Vector2(22, 7), 6, Color(0.8, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, String(d.get("price", "12¢")), Vector2(2, 9), Vector2(22, 8), 7, Color(0.1, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, String(d.get("issue", "1")), Vector2(2, 16), Vector2(22, 10), 9, Color(0.1, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	# Comics Code stamp and a speech balloon of a coverline.
	BoxArt.rect(c, Rect2(W - 16, 30, 14, 16), Color(0.98, 0.98, 0.96))
	_t(c, "CCA", Vector2(W - 16, 30), Vector2(14, 16), 6, Color(0.1, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	var y := H - (30 if bronze else 26)
	BoxArt.rect(c, Rect2(6, y, W * 0.7, 20), Color(1, 1, 1, 0.93))
	BoxArt.poly(c, PackedVector2Array([Vector2(20, y + 20), Vector2(30, y + 20), Vector2(18, y + 28)]), Color(1, 1, 1, 0.93))
	_t(c, String(d.get("note", "")) + "!", Vector2(8, y), Vector2(W * 0.7 - 4, 20), 8, Color(0.1, 0.1, 0.1), "bangers", HORIZONTAL_ALIGNMENT_CENTER)


static func _modern(c: Control, d: Dictionary) -> void:
	_art(c, Rect2(0, 0, W, H), d)
	BoxArt.rect(c, Rect2(0, 0, W, 24), Color(0, 0, 0, 0.45))
	_title(c, d, Rect2(4, 2, W - 8, 20), Color.WHITE, "audio", Color(0, 0, 0, 0.6))
	_t(c, "#%s" % String(d.get("issue", "1")), Vector2(W - 22, 24), Vector2(18, 12), 10, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.7))
	_t(c, String(d.get("pub", "")).to_upper(), Vector2(4, H - 12), Vector2(W * 0.6, 10), 7, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.7))


static func _indie(c: Control, d: Dictionary) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.95, 0.94, 0.9))
	_art(c, Rect2(6, 26, W - 12, H - 40), d, Color(0.85, 0.85, 0.85))
	# Photocopy look: grey wash and speckle.
	BoxArt.rect(c, Rect2(6, 26, W - 12, H - 40), Color(0.5, 0.5, 0.5, 0.25))
	var g := _rng(String(d["id"]) + "xer")
	for k in 40:
		BoxArt.rect(c, Rect2(g.randf() * W, g.randf() * H, 1, 1), Color(0, 0, 0, 0.5))
	_title(c, d, Rect2(4, 2, W - 8, 22), Color(0.08, 0.08, 0.08), "marker", Color(0, 0, 0, 0))
	_t(c, "%s  #%s" % [String(d.get("pub", "")), String(d.get("issue", "1"))], Vector2(6, H - 13), Vector2(W - 12, 10), 7, Color(0.1, 0.1, 0.1), "russo")


static func _variant(c: Control, d: Dictionary, real_cover: bool) -> void:
	var v := String(d.get("variant", "Standard"))
	match v:
		"Foil Cover":
			CCArt._foil(c, Rect2(0, 0, W, H), 0.18, String(d["id"]))
		"Newsstand Edition":
			BoxArt.rect(c, Rect2(4, H - 26, 24, 20), Color.WHITE)
			for k in 10:
				BoxArt.rect(c, Rect2(6 + k * 2, H - 24, 1.2 if k % 3 else 0.7, 14), Color.BLACK)
		"Price Variant":
			BoxArt.rect(c, Rect2(2, 2, 22, 12), Color(1, 0.95, 0.4))
			_t(c, "35¢", Vector2(2, 2), Vector2(22, 12), 9, Color(0.6, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_CENTER)
		"UK Pence Copy":
			BoxArt.rect(c, Rect2(2, 2, 22, 12), Color(1, 1, 1))
			_t(c, "8p", Vector2(2, 2), Vector2(22, 12), 9, Color(0.1, 0.1, 0.5), "russo", HORIZONTAL_ALIGNMENT_CENTER)
		"Signature Series":
			_t(c, String(d.get("char", "Stan")).split(" ")[0] + "!", Vector2(W * 0.15, H * 0.5), Vector2(W * 0.7, 22), 18, Color(0.85, 0.85, 0.95), "marker", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.5))
		"Restored":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.6, 0.3, 0.8, 0.12))
		"2nd Printing":
			BoxArt.rect(c, Rect2(W - 30, H - 20, 26, 14), Color(0.95, 0.3, 0.3))
			_t(c, "2ND", Vector2(W - 30, H - 20), Vector2(26, 14), 9, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
		"1:100 Ratio Variant":
			CCArt._frame(c, Rect2(0, 0, W, H), Color("4fa3ff"), 3.0)
		"Misprint":
			BoxArt.rect(c, Rect2(0, H * 0.45, W, 4), Color(0.1, 0.6, 0.9, 0.7))
			BoxArt.rect(c, Rect2(2, 0, W, H), Color(0.9, 0.2, 0.6, 0.08))


static func paint_back(c: Control, d: Dictionary, w: int) -> void:
	W = w
	if String(d.get("kind", "")) == "longbox":
		_longbox(c, d, true)
		return
	var g := _rng(String(d["id"]) + "ad")
	var year := int(d.get("year", 1970))
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.93, 0.89, 0.75) if year < 1985 else Color(0.97, 0.97, 0.97))
	var ads := [["SEA MUNKEYS!", "Instant pets! Just add water. They do tricks*", "*they don't"],
		["X-RAY SPECKS", "See through walls! See through clothes!*", "*you won't"],
		["I WAS A 97 LB WEAKLING", "Muscles in 7 days with the Charles Atlast method.", "Mail this coupon today"],
		["SELL GRIT!", "Earn prizes selling our newspaper door to door.", "Bicycles! Radios! A pony?"],
		["100 TOY SOLDIERS", "Only $1.25! Comes in a footlocker!", "Footlocker is cardboard"],
		["COLLECT THEM ALL", "Back issues by mail: 50 cents each, 4-6 weeks.", "Send cash. Do not send cash."]]
	var ad: Array = ads[g.randi() % ads.size()]
	BoxArt.rect(c, Rect2(4, 4, W - 8, 20), Color(0.85, 0.15, 0.1))
	_t(c, String(ad[0]), Vector2(6, 4), Vector2(W - 12, 20), 14, Color.WHITE, "bangers", HORIZONTAL_ALIGNMENT_CENTER)
	CoverComp.cg(c, g, ["turtle", "eyes", "rolled_up_newspaper", "military_helmet", "books"][g.randi() % 5], Vector2(W * 0.5, H * 0.62), H * 0.34, false)
	BoxArt.text(c, String(ad[1]), Vector2(6, 28), Vector2(W - 12, 30), 9, Color(0.1, 0.1, 0.1), false)
	BoxArt.rect(c, Rect2(6, H - 34, W - 12, 28), Color(1, 1, 1, 0.8))
	_frame_dash(c, Rect2(6, H - 34, W - 12, 28))
	_t(c, String(ad[2]), Vector2(8, H - 32), Vector2(W - 16, 12), 8, Color(0.15, 0.15, 0.15), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, "NAME ____________", Vector2(8, H - 20), Vector2(W - 16, 10), 7, Color(0.3, 0.3, 0.3), "jersey")


static func _frame_dash(c: Control, r: Rect2) -> void:
	for x in range(int(r.position.x), int(r.end.x), 5):
		BoxArt.rect(c, Rect2(x, r.position.y, 3, 1), Color(0.3, 0.3, 0.3))
		BoxArt.rect(c, Rect2(x, r.end.y - 1, 3, 1), Color(0.3, 0.3, 0.3))


static func _longbox(c: Control, d: Dictionary, back := false) -> void:
	var g := _rng(String(d["id"]) + ("lbb" if back else "lb"))
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.93, 0.92, 0.88))
	for k in 12:
		BoxArt.rect(c, Rect2(0, g.randf() * H, W, 1), Color(0.8, 0.78, 0.72, 0.5))
	# The printed COMICS logo, a hand hole, a marker label.
	_t(c, "COMIC STORAGE", Vector2(4, 6), Vector2(W - 8, 14), 10, Color(0.2, 0.3, 0.6), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	BoxArt.rect(c, Rect2(W * 0.35, 24, W * 0.3, 10), Color(0.25, 0.22, 0.2))
	var lab: String = ["KEEP", "DO NOT SELL", "HECTOR - KEEP", "GOOD ONES", "%d - %d" % [int(d.get("year", 1970)) - 5, int(d.get("year", 1970)) + 5], "MISC A-M"][g.randi() % 6]
	if back:
		lab = "%d BOOKS (APPROX)" % int(d.get("count", 200))
	var tl := _t(c, lab, Vector2(6, 46), Vector2(W - 12, 32), 20, Color(0.1, 0.1, 0.12), "marker", HORIZONTAL_ALIGNMENT_CENTER)
	tl.rotation_degrees = g.randf_range(-6, 6)
	_t(c, String(Catalog.platform(String(d["plat"]))["name"]).to_upper(), Vector2(6, 82), Vector2(W - 12, 14), 11, Color(0.6, 0.1, 0.1), "marker", HORIZONTAL_ALIGNMENT_CENTER)
	# Packing tape across the lid.
	var tape := BoxArt.rect(c, Rect2(-4, H - 30, W + 8, 10), Color(0.85, 0.75, 0.45, 0.65))
	tape.rotation_degrees = -3.0
	if String(d.get("variant", "")) == "Resealed?":
		var t2 := BoxArt.rect(c, Rect2(-4, H - 44, W + 8, 10), Color(0.85, 0.75, 0.45, 0.65))
		t2.rotation_degrees = 4.0
