extends RefCounted
## Paints rare books and box lots (CCArt hands over kinds "book" and "booklot").
## No class_name (TV self-update): preload it.
##
##   Fronts: the real first-edition cover or title page when
##   tools/fetch_world_art.py found one shaped like a book (def "scan"), aged
##   a little for old books. Otherwise painted by the def's "binding":
##     leather: calf or morocco, gilt double rules, a centre lozenge and a
##       red title label.
##     cloth: coloured publisher's cloth, blind-stamped frame, gilt title,
##       an inset plate (the def's photo, or a subject render).
##     jacket: a dust jacket, era fonts per binder page, the art panel,
##       author strip and the price on the flap corner.
##     paperback: a pocket book with a publisher badge and a cover price.
##   Variants: book club (no price, a blind dot), ex-library (a spine label
##   and a WITHDRAWN stamp), signed / inscribed (ink), fine binding (gilt
##   tooling over everything), limited (a numbered slipcase band), advance
##   proof (plain wrappers), price-clipped (a snipped corner).
##   Backs: the jacket's back flap with reviews, or a bookseller's ticket.
##   Box lots: a banker's box with a marker label.

const CCArt := preload("res://scripts/gfx/cc_art.gd")
## Fallback picture subjects per binder page.
const SUBJ := {"ANTQ": "scroll", "CLSC": "books", "MODF": "open_book", "GENR": "crystal_ball", "KIDS": "teddy_bear"}
const JACKET_FONTS := {"MODF": ["right", "russo", "cinzel"], "GENR": ["creep", "orbit", "blackops", "bangers"], "KIDS": ["lucky", "pacifico", "bungee"],
	"CLSC": ["cinzel"], "ANTQ": ["cinzel"]}
const GILT := Color(0.93, 0.78, 0.38)

static var W := 102
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
	CoverComp.gradient(holder, Rect2(Vector2.ZERO, r.size), Color.from_hsv(hue, 0.45, 0.95), Color.from_hsv(fmod(hue + 0.08, 1.0), 0.65, 0.5))
	var subs := CoverComp.subjects_for(String(d.get("name", "")))
	var ref := String(subs[0]) if not subs.is_empty() else String(SUBJ.get(String(d["plat"]), "books"))
	CoverComp.cg(holder, g, ref, Vector2(r.size.x * 0.5, r.size.y * 0.95), r.size.y * 0.82, g.randf() < 0.5)


static func paint_front(c: Control, d: Dictionary, w: int) -> void:
	W = w
	if String(d.get("kind", "")) == "booklot":
		_booklot(c, d)
		return
	var v := String(d.get("variant", "Standard"))
	var year := int(d.get("year", 1900))
	var scan := _tex(String(d.get("scan", "")))
	if v == "Advance Proof":
		_proof(c, d)
	elif scan != null:
		var age := clampf((1950.0 - year) / 400.0, 0.0, 0.25)
		_img(c, scan, Rect2(0, 0, W, H), Color(1.0, 1.0 - age * 0.3, 1.0 - age))
	else:
		match String(d.get("binding", "cloth")):
			"leather": _leather(c, d)
			"jacket": _jacket(c, d)
			"paperback": _paperback(c, d)
			_: _cloth(c, d)
	_variant(c, d)


static func _title(c: Control, d: Dictionary, r: Rect2, col: Color, font := "cinzel", outline := Color(0, 0, 0, 0)) -> void:
	_t(c, String(d.get("name", "")), r.position, r.size, int(r.size.y * 0.42), col, font, HORIZONTAL_ALIGNMENT_CENTER, outline, true)


static func _author(c: Control, d: Dictionary, r: Rect2, col: Color, font := "russo") -> void:
	_t(c, String(d.get("author", "")).to_upper(), r.position, r.size, int(r.size.y), col, font)


## Gilt rules: an outer and inner rectangle of thin gold lines.
static func _rules(c: Control, inset: float, col: Color, t := 1.0) -> void:
	for k in 2:
		var i := inset + k * 4.0
		CCArt._frame(c, Rect2(i, i, W - i * 2, H - i * 2), col, t)


static func _leather(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "lea")
	var base: Color = [Color(0.36, 0.2, 0.1), Color(0.42, 0.12, 0.1), Color(0.2, 0.22, 0.14), Color(0.3, 0.16, 0.12)][g.randi() % 4]
	CoverComp.gradient(c, Rect2(0, 0, W, H), base.lightened(0.12), base.darkened(0.25))
	# Grain and scuffs.
	for k in 60:
		BoxArt.rect(c, Rect2(g.randf() * W, g.randf() * H, g.randf_range(1, 4), 1), Color(0, 0, 0, 0.18) if k % 2 else Color(1, 0.9, 0.7, 0.07))
	_rules(c, 5, GILT, 1.0)
	# Corner fleurons and the centre lozenge.
	for p in [Vector2(14, 14), Vector2(W - 14, 14), Vector2(14, H - 14), Vector2(W - 14, H - 14)]:
		BoxArt.circle(c, p, 2.5, GILT, 8)
	var ctr := Vector2(W * 0.5, H * 0.58)
	BoxArt.poly(c, PackedVector2Array([ctr + Vector2(0, -26), ctr + Vector2(18, 0), ctr + Vector2(0, 26), ctr + Vector2(-18, 0)]), GILT)
	BoxArt.poly(c, PackedVector2Array([ctr + Vector2(0, -22), ctr + Vector2(14, 0), ctr + Vector2(0, 22), ctr + Vector2(-14, 0)]), base.darkened(0.1))
	BoxArt.circle(c, ctr, 5, GILT, 10)
	# The red morocco title label.
	BoxArt.rect(c, Rect2(16, 22, W - 32, 30), Color(0.55, 0.1, 0.08))
	CCArt._frame(c, Rect2(16, 22, W - 32, 30), GILT, 1.0)
	_title(c, d, Rect2(18, 23, W - 36, 28), GILT, "cinzel")
	_t(c, str(int(d.get("year", 1700))), Vector2(0, H - 32), Vector2(W, 10), 8, GILT, "cinzel")


static func _cloth(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "clo")
	var hues := [Color(0.15, 0.3, 0.2), Color(0.5, 0.12, 0.12), Color(0.15, 0.22, 0.45), Color(0.55, 0.42, 0.2), Color(0.35, 0.18, 0.35), Color(0.75, 0.6, 0.25)]
	var base: Color = hues[g.randi() % hues.size()]
	BoxArt.rect(c, Rect2(0, 0, W, H), base)
	# Cloth weave.
	for y in range(0, H, 3):
		BoxArt.rect(c, Rect2(0, y, W, 1), Color(0, 0, 0, 0.08))
	CCArt._frame(c, Rect2(6, 6, W - 12, H - 12), base.darkened(0.3), 2.0)
	_title(c, d, Rect2(8, 12, W - 16, 34), GILT, "cinzel", Color(0, 0, 0, 0.4))
	# An inset plate, the way Victorian pictorial cloth did it.
	var pr := Rect2(W * 0.2, 52, W * 0.6, H * 0.4)
	BoxArt.rect(c, pr.grow(2), GILT)
	_art(c, pr, d, Color(1.0, 0.95, 0.85))
	_author(c, d, Rect2(8, H - 26, W - 16, 10), GILT, "cinzel")


static func _jacket(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "dj")
	var plat := String(d["plat"])
	var fonts: Array = JACKET_FONTS.get(plat, ["right"])
	var font := String(fonts[g.randi() % fonts.size()])
	var pc: Color = Catalog.platform(plat)["color"]
	var base := Color.from_hsv(fmod(pc.h + g.randf_range(-0.2, 0.2) + 1.0, 1.0), g.randf_range(0.4, 0.8), g.randf_range(0.35, 0.85))
	var ink := Color(0.98, 0.95, 0.88) if base.v < 0.6 else Color(0.08, 0.07, 0.08)
	BoxArt.rect(c, Rect2(0, 0, W, H), base)
	match g.randi() % 3:
		0:  # Title block over a full art panel.
			_art(c, Rect2(0, 40, W, H - 62), d)
			_title(c, d, Rect2(4, 4, W - 8, 34), ink, font)
		1:  # Art window in a bold frame.
			_title(c, d, Rect2(4, 6, W - 8, 34), ink, font)
			var r := Rect2(10, 44, W - 20, H - 72)
			BoxArt.rect(c, r.grow(3), ink)
			_art(c, r, d)
		_:  # Full-bleed art, title band across the middle.
			_art(c, Rect2(0, 0, W, H), d)
			BoxArt.rect(c, Rect2(0, H * 0.36, W, 36), Color(base, 0.9))
			_title(c, d, Rect2(4, H * 0.36 + 1, W - 8, 34), ink, font)
	BoxArt.rect(c, Rect2(0, H - 20, W, 20), base.darkened(0.25))
	_author(c, d, Rect2(4, H - 17, W - 8, 13), Color(0.98, 0.95, 0.88))
	if plat == "KIDS":
		CCArt._frame(c, Rect2(2, 2, W - 4, H - 4), Color(1, 1, 1, 0.8), 2.0)


static func _paperback(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "pb")
	_art(c, Rect2(0, 0, W, H), d)
	BoxArt.rect(c, Rect2(0, 0, W, 34), Color(0.08, 0.06, 0.1, 0.8))
	_title(c, d, Rect2(18, 2, W - 22, 30), Color(1.0, 0.85, 0.25), ["orbit", "audio", "bangers"][g.randi() % 3])
	BoxArt.circle(c, Vector2(9, 9), 7, Color(0.9, 0.2, 0.15), 12)
	_t(c, String(d.get("pub", "")).left(3).to_upper(), Vector2(2, 4), Vector2(14, 10), 6, Color.WHITE, "russo")
	_t(c, "95p" if String(d.get("pub", "")).contains("Pann") else "$2.95", Vector2(W - 26, H - 14), Vector2(24, 12), 8, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.7))
	_author(c, d, Rect2(4, H - 28, W - 8, 11), Color.WHITE)


## Advance proof: plain printed wrappers, "UNCORRECTED PROOF - NOT FOR SALE".
static func _proof(c: Control, d: Dictionary) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.86, 0.82, 0.7))
	_t(c, "UNCORRECTED PROOF", Vector2(4, 10), Vector2(W - 8, 12), 9, Color(0.35, 0.1, 0.1), "russo")
	_title(c, d, Rect2(8, 34, W - 16, 40), Color(0.1, 0.1, 0.1), "cinzel")
	_author(c, d, Rect2(8, 80, W - 16, 10), Color(0.2, 0.2, 0.2))
	_t(c, "NOT FOR SALE\nPublication date to be announced", Vector2(6, H - 40), Vector2(W - 12, 30), 7, Color(0.3, 0.3, 0.3), "jersey", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)


static func _stamp(c: Control, txt: String, at: Vector2, col: Color, rot := -12.0) -> void:
	var holder := Control.new()
	holder.position = at
	holder.size = Vector2(W * 0.7, 20)
	holder.pivot_offset = holder.size * 0.5
	holder.rotation_degrees = rot
	c.add_child(holder)
	CCArt._frame(holder, Rect2(Vector2.ZERO, holder.size), col, 2.0)
	_t(holder, txt, Vector2(2, 1), holder.size - Vector2(4, 2), 12, col, "russo")


static func _variant(c: Control, d: Dictionary) -> void:
	var v := String(d.get("variant", "Standard"))
	match v:
		"Fine Binding":
			_rules(c, 3, Color(GILT, 0.9), 1.0)
			CCArt._foil(c, Rect2(0, 0, W, H), 0.12, String(d["id"]))
		"Limited Edition":
			BoxArt.rect(c, Rect2(0, H - 30, W, 12), Color(0.12, 0.1, 0.16, 0.92))
			_t(c, "No. %d of 500" % (1 + hash(String(d["id"])) % 500), Vector2(0, H - 30), Vector2(W, 12), 8, GILT, "cinzel")
		"Signed by the Author", "Inscribed Copy", "Association Copy":
			var who := String(d.get("author", "A")).split(" ")
			var sig := String(who[who.size() - 1])
			var txt := sig if v == "Signed by the Author" else ("For Margaret -\n" + sig)
			_t(c, txt, Vector2(W * 0.08, H * 0.52), Vector2(W * 0.84, 34), 16, Color(0.08, 0.1, 0.35, 0.9), "marker", HORIZONTAL_ALIGNMENT_CENTER, Color(1, 1, 1, 0.35), true)
		"Ex-Library":
			BoxArt.rect(c, Rect2(W - 18, H - 30, 14, 22), Color(0.95, 0.95, 0.9))
			_t(c, "823\n.8", Vector2(W - 18, H - 30), Vector2(14, 22), 6, Color(0.1, 0.1, 0.1), "jersey", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)
			_stamp(c, "WITHDRAWN", Vector2(W * 0.12, H * 0.3), Color(0.55, 0.1, 0.5, 0.85))
		"Book Club Edition":
			BoxArt.circle(c, Vector2(W - 8, H - 8), 3, Color(0, 0, 0, 0.45), 10)
			_t(c, "BOOK CLUB EDITION", Vector2(4, 2), Vector2(W - 8, 8), 6, Color(1, 1, 1, 0.8), "russo", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.6))
		"Price-Clipped":
			BoxArt.poly(c, PackedVector2Array([Vector2(W, 0), Vector2(W - 20, 0), Vector2(W, 20)]), Color(0.92, 0.9, 0.84))
		"Later Printing":
			_t(c, "Seventh printing", Vector2(4, H - 32), Vector2(W - 8, 10), 7, Color(1, 1, 1, 0.75), "jersey", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.6))
		"First State":
			BoxArt.rect(c, Rect2(2, 2, 34, 11), Color(0.15, 0.35, 0.75, 0.92))
			_t(c, "1ST STATE", Vector2(2, 2), Vector2(34, 11), 7, Color.WHITE, "russo")
		"Misprint":
			# Bound upside down: a second, flipped title ghosting through.
			BoxArt.rect(c, Rect2(0, H * 0.5, W, 3), Color(0.9, 0.2, 0.3, 0.6))
		"Pedigree":
			BoxArt.rect(c, Rect2(W * 0.25, 4, W * 0.5, 16), Color(0.95, 0.92, 0.82))
			CCArt._frame(c, Rect2(W * 0.25, 4, W * 0.5, 16), Color(0.2, 0.15, 0.1), 1.0)
			_t(c, "EX LIBRIS", Vector2(W * 0.25, 4), Vector2(W * 0.5, 16), 8, Color(0.2, 0.15, 0.1), "cinzel")


static func paint_back(c: Control, d: Dictionary, w: int) -> void:
	W = w
	if String(d.get("kind", "")) == "booklot":
		_booklot(c, d, true)
		return
	var g := _rng(String(d["id"]) + "back")
	var binding := String(d.get("binding", "cloth"))
	if binding == "jacket" or binding == "paperback":
		BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.96, 0.94, 0.88))
		_t(c, "PRAISE FOR", Vector2(4, 6), Vector2(W - 8, 10), 8, Color(0.5, 0.1, 0.1), "russo")
		_t(c, String(d.get("name", "")), Vector2(4, 16), Vector2(W - 8, 14), 10, Color(0.1, 0.1, 0.1), "cinzel")
		var quotes := ["\"Unputdownable.\"", "\"A triumph. Read it twice.\"", "\"I could not stop, and I tried.\"", "\"The book of the year, and possibly the century.\"",
			"\"Shocking. Ban it at once.\"", "\"Better than the film.\"", "\"My grandchildren will inherit this.\""]
		for k in 3:
			_t(c, String(quotes[g.randi() % quotes.size()]), Vector2(6, 36 + k * 26), Vector2(W - 12, 22), 9, Color(0.15, 0.15, 0.15), "jersey", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)
			_t(c, "- " + ["The Daily Reed", "Literary Revue", "Bookhound Weekly", "A Famous Novelist"][g.randi() % 4], Vector2(6, 52 + k * 26), Vector2(W - 12, 8), 6, Color(0.4, 0.4, 0.4), "russo")
		if String(d.get("variant", "")) != "Book Club Edition" and String(d.get("variant", "")) != "Price-Clipped":
			_t(c, "$%.2f" % (1.5 + float(hash(String(d["id"])) % 300) / 100.0), Vector2(W - 34, H - 14), Vector2(30, 12), 8, Color(0.1, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_RIGHT)
		_t(c, String(d.get("pub", "")), Vector2(4, H - 14), Vector2(W - 40, 12), 8, Color(0.3, 0.3, 0.3), "russo", HORIZONTAL_ALIGNMENT_LEFT)
		return
	# Leather and cloth: the back board, with a bookseller's ticket inside.
	var base := Color(0.4, 0.22, 0.12) if binding == "leather" else Color(0.25, 0.28, 0.3)
	BoxArt.rect(c, Rect2(0, 0, W, H), base)
	_rules(c, 6, Color(GILT, 0.6), 1.0)
	BoxArt.rect(c, Rect2(W * 0.2, H * 0.62, W * 0.6, 26), Color(0.95, 0.92, 0.82))
	_t(c, ["FOXED & FOLIO\nRare Books", "BOUGHT OF\nI. HALLOWAY", "BOUND BY\nRIVIERE-ISH & SON"][g.randi() % 3], Vector2(W * 0.2, H * 0.62), Vector2(W * 0.6, 26), 8, Color(0.2, 0.15, 0.1), "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)


static func _booklot(c: Control, d: Dictionary, back := false) -> void:
	var g := _rng(String(d["id"]) + ("blb" if back else "bl"))
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.82, 0.7, 0.5))
	for k in 10:
		BoxArt.rect(c, Rect2(0, g.randf() * H, W, 1), Color(0.6, 0.5, 0.35, 0.5))
	_t(c, "BANKERS BOX", Vector2(4, 6), Vector2(W - 8, 12), 9, Color(0.15, 0.3, 0.2), "russo")
	BoxArt.rect(c, Rect2(W * 0.35, 22, W * 0.3, 9), Color(0.25, 0.2, 0.15))
	var lab: String = ["BOOKS", "STUDY - MISC", "IRIS - UNCATALOGUED", "SHELF 4", "OLD ONES", "LIBRARY"][g.randi() % 6]
	if back:
		lab = "%d BOOKS (APPROX)" % int(d.get("count", 60))
	var tl := _t(c, lab, Vector2(6, 44), Vector2(W - 12, 30), 18, Color(0.1, 0.1, 0.12), "marker")
	tl.rotation_degrees = g.randf_range(-6, 6)
	_t(c, String(Catalog.platform(String(d["plat"]))["name"]).to_upper(), Vector2(6, 80), Vector2(W - 12, 14), 10, Color(0.55, 0.1, 0.1), "marker")
	var tape := BoxArt.rect(c, Rect2(-4, H - 30, W + 8, 10), Color(0.85, 0.75, 0.45, 0.65))
	tape.rotation_degrees = -3.0
	if String(d.get("variant", "")) == "Resealed?":
		var t2 := BoxArt.rect(c, Rect2(-4, H - 44, W + 8, 10), Color(0.85, 0.75, 0.45, 0.65))
		t2.rotation_degrees = 4.0
