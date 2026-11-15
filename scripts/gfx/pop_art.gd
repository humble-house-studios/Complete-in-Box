extends RefCounted
## Paints pop culture pieces (CCArt hands over kinds toy, prop, poster, toybox).
## No class_name (TV self-update): preload it.
##
##   Toys: the packaging, by the def's "form":
##     carded / vehicle  a blister card: peg hole, maker banner, starburst,
##                       the bubble with the toy inside, COLLECT THEM ALL.
##     lunchbox          the lithographed metal lid, rivets and a name banner.
##     badge             a radio premium pin on its kraft mailer card.
##     anything else     a window box: stripes, logo, cellophane window.
##   Props: a museum plaque: the photo in a gilt frame on velvet, a brass
##          plate with the film's studio and year, a SCREEN USED stamp.
##   Posters: the real one-sheet when tools/fetch_world_art.py found one shaped
##            like a poster (def "scan"); otherwise a painted one-sheet in the
##            style of its decade, with the credit block and fold lines.
##   Box lots: a shipper case, a painted toy chest, a prop crate, a poster tube
##             or a tied stack of lunchboxes, by aisle.
##   Variants: re-release banners, reproduction cards, foreign cards, store and
##   convention stickers, mail-away mailer boxes, glow / chrome stickers, signed
##   (silver marker), hand-painted prototype (a grey sample card), factory
##   errors, stunt / hero / studio-letter stamps, teaser and foil posters,
##   printer's proofs (colour bars) and celebrity provenance tags.
##   Backs: card backs with the rest of the wave, box backs, a provenance
##   letter for props, the folded back of a poster with its NSS stamp.

const CCArt := preload("res://scripts/gfx/cc_art.gd")
## Fallback picture subjects per aisle.
const SUBJ := {"FIGS": "robot", "TOYS": "teddy_bear", "PROP": "clapper_board", "POST": "performing_arts", "MEMO": "bento_box"}
const LOGO_FONTS := ["bungee", "lucky", "bangers", "right", "russo"]

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


## The picture: the def's photo, or a subject render on a soft wash.
static func _art(c: Control, r: Rect2, d: Dictionary, tint := Color.WHITE, wash := true) -> void:
	var cut := _tex(String(d.get("cut", "")))
	if cut != null:
		_cut_art(c, r, d, cut, tint, wash)
		return
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
	if wash:
		var hue := fmod(pc.h + g.randf_range(-0.12, 0.12) + 1.0, 1.0)
		CoverComp.gradient(holder, Rect2(Vector2.ZERO, r.size), Color.from_hsv(hue, 0.4, 0.98), Color.from_hsv(fmod(hue + 0.08, 1.0), 0.6, 0.55))
	var subs := CoverComp.subjects_for(String(d.get("name", "")))
	var ref := String(subs[0]) if not subs.is_empty() else String(SUBJ.get(String(d["plat"]), "robot"))
	CoverComp.cg(holder, g, ref, Vector2(r.size.x * 0.5, r.size.y * 0.95), r.size.y * 0.8, g.randf() < 0.5)
	holder.modulate = tint


## The real piece, cut out of its photo, standing in the window on a soft
## studio wash with a contact shadow: how it looks through a real bubble.
static func _cut_art(c: Control, r: Rect2, d: Dictionary, cut: Texture2D, tint: Color, wash: bool) -> void:
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	if wash:
		var pc: Color = Catalog.platform(String(d["plat"]))["color"]
		CoverComp.gradient(holder, Rect2(Vector2.ZERO, r.size), Color.from_hsv(pc.h, 0.18, 0.98), Color.from_hsv(pc.h, 0.35, 0.78), true)
	var a := float(cut.get_width()) / maxf(1.0, cut.get_height())
	var box := r.size * 0.92
	var sz := Vector2(box.y * a, box.y) if box.y * a <= box.x else Vector2(box.x, box.x / a)
	var at := Vector2((r.size.x - sz.x) * 0.5, r.size.y - sz.y - r.size.y * 0.03)
	# Contact shadow under the piece.
	BoxArt.poly(holder, PackedVector2Array([at + Vector2(sz.x * 0.15, sz.y), at + Vector2(sz.x * 0.85, sz.y), at + Vector2(sz.x * 0.75, sz.y + 4), at + Vector2(sz.x * 0.25, sz.y + 4)]), Color(0, 0, 0, 0.25))
	var tr := TextureRect.new()
	tr.texture = cut
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = at
	tr.size = sz
	tr.modulate = tint
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	holder.add_child(tr)


static func _base(d: Dictionary, g: RandomNumberGenerator) -> Color:
	var pc: Color = Catalog.platform(String(d["plat"]))["color"]
	return Color.from_hsv(fmod(pc.h + g.randf_range(-0.18, 0.18) + 1.0, 1.0), g.randf_range(0.6, 0.9), g.randf_range(0.6, 0.95))


static func _burst(c: Control, ctr: Vector2, r: float, col: Color, txt: String, ink := Color(0.1, 0.05, 0.05)) -> void:
	CCArt._star(c, ctr, r, col, 12)
	_t(c, txt, ctr - Vector2(r * 0.8, r * 0.55), Vector2(r * 1.6, r * 1.1), int(r * 0.5), ink, "bangers", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)


static func _maker_logo(c: Control, d: Dictionary, r: Rect2, col: Color) -> void:
	var g := _rng(String(d.get("maker", "")) + "logo")
	var bg := Color.from_hsv(g.randf(), 0.75, 0.75)
	BoxArt.rect(c, r, bg)
	CCArt._frame(c, r, Color(1, 1, 1, 0.9), 1.0)
	_t(c, String(d.get("maker", "")).to_upper(), r.position + Vector2(2, 1), r.size - Vector2(4, 2), int(r.size.y * 0.75), col, String(LOGO_FONTS[g.randi() % LOGO_FONTS.size()]))


static func _name(c: Control, d: Dictionary, r: Rect2, col: Color, outline: Color, font := "lucky") -> void:
	_t(c, String(d.get("name", "")).to_upper(), r.position, r.size, int(r.size.y * 0.42), col, font, HORIZONTAL_ALIGNMENT_CENTER, outline, true)


static func paint_front(c: Control, d: Dictionary, w: int) -> void:
	W = w
	var kind := String(d.get("kind", "toy"))
	var v := String(d.get("variant", "Standard"))
	match kind:
		"toybox":
			_box_lot(c, d)
		"prop":
			_plaque(c, d)
		"poster":
			var scan := _tex(String(d.get("scan", "")))
			if v == "Printer's Proof" or scan == null:
				_one_sheet(c, d)
			else:
				_img(c, scan, Rect2(0, 0, W, H))
			_folds(c, d)
		_:
			var boxshot := _tex(String(d.get("box", "")))
			if v == "Hand-Painted Prototype":
				_sample(c, d)
			elif boxshot != null and v != "Mail-Away Offer":
				_box_front(c, d, boxshot)
			elif v == "Mail-Away Offer":
				_mailer(c, d)
			else:
				match String(d.get("form", "boxed")):
					"carded", "vehicle":
						_carded(c, d)
					"lunchbox":
						_lunchbox(c, d)
					"badge":
						_badge_card(c, d)
					_:
						_window_box(c, d)
	_variant(c, d)


# ---------------------------------------------------------------- toys

## The real box (or lunchbox lid) photographed and cut out: a lunchbox lid fills
## the front edge to edge; a box stands on the aisle's colour.
static func _box_front(c: Control, d: Dictionary, t: Texture2D) -> void:
	if String(d.get("form", "")) == "lunchbox":
		BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.12, 0.1, 0.12))
		_img(c, t, Rect2(0, 0, W, H))
		return
	var pc: Color = Catalog.platform(String(d["plat"]))["color"]
	CoverComp.gradient(c, Rect2(0, 0, W, H), pc.lightened(0.35), pc.darkened(0.35), true)
	var a := float(t.get_width()) / maxf(1.0, t.get_height())
	var box := Vector2(W, H) * 0.97
	var sz := Vector2(box.y * a, box.y) if box.y * a <= box.x else Vector2(box.x, box.x / a)
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = (Vector2(W, H) - sz) * 0.5
	tr.size = sz
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	c.add_child(tr)


## A blister card hanging from its peg hole, the toy in the bubble.
static func _carded(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "card")
	var base := _base(d, g)
	CoverComp.gradient(c, Rect2(0, 0, W, H), base.lightened(0.2), base.darkened(0.4), true)
	# Speed lines out of the bubble.
	var ctr := Vector2(W * 0.5, H * 0.58)
	for i in 14:
		var a0 := TAU * i / 14.0
		var a1 := TAU * (i + 0.45) / 14.0
		BoxArt.poly(c, PackedVector2Array([ctr, ctr + Vector2(cos(a0), sin(a0)) * W * 1.2, ctr + Vector2(cos(a1), sin(a1)) * W * 1.2]), Color(1, 1, 1, 0.08))
	# The peg hole, then the header with the maker.
	BoxArt.rect(c, Rect2(W * 0.38, 5, W * 0.24, 7), Color(0.08, 0.06, 0.08))
	BoxArt.circle(c, Vector2(W * 0.38, 8.5), 3.5, Color(0.08, 0.06, 0.08), 10)
	BoxArt.circle(c, Vector2(W * 0.62, 8.5), 3.5, Color(0.08, 0.06, 0.08), 10)
	_maker_logo(c, d, Rect2(6, 16, W * 0.5, 14), Color.WHITE)
	_t(c, String(Catalog.platform(String(d["plat"]))["name"]).to_upper(), Vector2(W * 0.52, 16), Vector2(W * 0.46, 14), 9, Color(1, 1, 0.85), "russo", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.6))
	# The bubble: a lighter rounded shape with a glossy streak.
	var br := Rect2(W * 0.16, H * 0.25, W * 0.68, H * 0.52)
	BoxArt.rect(c, br.grow(2), Color(1, 1, 1, 0.55))
	_art(c, br, d, Color.WHITE, true)
	BoxArt.rect(c, Rect2(br.position.x + 4, br.position.y + 3, 5, br.size.y - 6), Color(1, 1, 1, 0.28))
	BoxArt.rect(c, Rect2(br.end.x - 10, br.position.y + 3, 2, br.size.y * 0.5), Color(1, 1, 1, 0.22))
	_name(c, d, Rect2(4, H * 0.78, W - 8, H * 0.13), Color(1.0, 0.92, 0.25), Color(0.05, 0.02, 0.1, 0.9))
	BoxArt.rect(c, Rect2(0, H - 10, W, 10), Color(0.05, 0.05, 0.08, 0.85))
	_t(c, "COLLECT THEM ALL!  AGES 4 & UP", Vector2(2, H - 10), Vector2(W - 4, 10), 7, Color.WHITE, "russo")
	if int(d.get("tier", 0)) >= 2 or g.randf() < 0.3:
		_burst(c, Vector2(W - 20, H * 0.3), 15, Color(1.0, 0.85, 0.15), ["NEW!", "WITH\nWEAPON!", "ACTION!", "WAVE 1"][g.randi() % 4])


## A window box: stripes, logo, a cellophane window onto the toy.
static func _window_box(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "box")
	var base := _base(d, g)
	BoxArt.rect(c, Rect2(0, 0, W, H), base)
	for i in range(-H, W, 16):
		BoxArt.poly(c, PackedVector2Array([Vector2(i, H), Vector2(i + 8, H), Vector2(i + 8 + H, 0), Vector2(i + H, 0)]), Color(1, 1, 1, 0.07))
	_maker_logo(c, d, Rect2(W * 0.2, 5, W * 0.6, 15), Color.WHITE)
	var wr := Rect2(W * 0.12, H * 0.17, W * 0.76, H * 0.56)
	BoxArt.rect(c, wr.grow(3), base.darkened(0.5))
	_art(c, wr, d)
	# Cellophane sheen.
	BoxArt.poly(c, PackedVector2Array([wr.position, wr.position + Vector2(wr.size.x * 0.35, 0), wr.position + Vector2(0, wr.size.y * 0.5)]), Color(1, 1, 1, 0.16))
	_name(c, d, Rect2(4, H * 0.75, W - 8, H * 0.16), Color.WHITE, base.darkened(0.7))
	_t(c, str(int(d.get("year", 1980))), Vector2(4, H - 12), Vector2(40, 10), 8, Color(1, 1, 1, 0.8), "russo", HORIZONTAL_ALIGNMENT_LEFT)
	if g.randf() < 0.5:
		_burst(c, Vector2(20, H * 0.24), 14, Color(1.0, 0.3, 0.3), ["NEW!", "WOW!", "FUN!"][g.randi() % 3], Color.WHITE)


## A lithographed metal lunchbox lid.
static func _lunchbox(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "lunch")
	var base := _base(d, g)
	BoxArt.rect(c, Rect2(0, 0, W, H), base.darkened(0.35))
	var ar := Rect2(7, 7, W - 14, H - 14)
	_art(c, ar, d)
	CCArt._frame(c, ar, base, 4.0)
	CCArt._frame(c, ar.grow(-4), Color(1, 1, 1, 0.35), 1.0)
	# Embossed name banner and rivets.
	BoxArt.rect(c, Rect2(W * 0.1, H * 0.74, W * 0.8, H * 0.17), Color(base.lightened(0.15), 0.94))
	_name(c, d, Rect2(W * 0.1, H * 0.74, W * 0.8, H * 0.17), Color(1, 0.97, 0.85), base.darkened(0.7), "bungee")
	for p in [Vector2(4, 4), Vector2(W - 4, 4), Vector2(4, H - 4), Vector2(W - 4, H - 4)]:
		BoxArt.circle(c, p, 2.5, Color(0.85, 0.85, 0.88), 8)
	_t(c, String(d.get("maker", "")).to_upper(), Vector2(10, 9), Vector2(W * 0.4, 9), 7, Color(1, 1, 1, 0.85), "russo", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.6))


## A premium pin on a kraft mailer card.
static func _badge_card(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "badge")
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.72, 0.58, 0.38))
	for k in 24:
		BoxArt.rect(c, Rect2(0, g.randf() * H, W, 1), Color(0.45, 0.33, 0.18, 0.2))
	_t(c, "SECRET SOCIETY", Vector2(4, 6), Vector2(W - 8, 12), 11, Color(0.35, 0.08, 0.08), "blackops")
	var ctr := Vector2(W * 0.5, H * 0.48)
	var r := W * 0.3
	BoxArt.circle(c, ctr, r + 4, Color(0.85, 0.7, 0.3), 28)
	BoxArt.circle(c, ctr, r, Color(0.95, 0.92, 0.85), 28)
	_art(c, Rect2(ctr - Vector2(r * 0.72, r * 0.72), Vector2(r * 1.44, r * 1.44)), d)
	_name(c, d, Rect2(6, H * 0.76, W - 12, H * 0.13), Color(0.2, 0.08, 0.05), Color(0, 0, 0, 0), "russo")
	_t(c, "MAIL TODAY! " + String(d.get("maker", "")).to_upper(), Vector2(4, H - 11), Vector2(W - 8, 9), 7, Color(0.3, 0.15, 0.08), "russo")


## A plain white mailer box from a mail-away offer, label and stamps.
static func _mailer(c: Control, d: Dictionary) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.95, 0.94, 0.9))
	BoxArt.rect(c, Rect2(0, H * 0.45, W, 8), Color(0.82, 0.72, 0.5, 0.8))
	BoxArt.rect(c, Rect2(W * 0.12, H * 0.14, W * 0.76, H * 0.24), Color.WHITE)
	CCArt._frame(c, Rect2(W * 0.12, H * 0.14, W * 0.76, H * 0.24), Color(0.3, 0.3, 0.35), 1.0)
	_t(c, "SPECIAL MAIL-AWAY OFFER", Vector2(W * 0.14, H * 0.15), Vector2(W * 0.72, 10), 8, Color(0.6, 0.1, 0.1), "russo")
	_t(c, String(d.get("name", "")), Vector2(W * 0.14, H * 0.24), Vector2(W * 0.72, 16), 12, Color(0.1, 0.1, 0.3), "marker")
	BoxArt.rect(c, Rect2(W - 30, H * 0.6, 22, 26), Color(0.85, 0.3, 0.3))
	_t(c, "15c", Vector2(W - 30, H * 0.6 + 8), Vector2(22, 10), 9, Color.WHITE, "russo")
	_t(c, "PROOFS OF PURCHASE ENCLOSED", Vector2(6, H * 0.84), Vector2(W - 12, 10), 7, Color(0.3, 0.3, 0.35), "russo")


## A factory sample: a grey card and a handwritten label.
static func _sample(c: Control, d: Dictionary) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.72, 0.72, 0.74))
	var br := Rect2(W * 0.2, H * 0.22, W * 0.6, H * 0.46)
	BoxArt.rect(c, br.grow(2), Color(1, 1, 1, 0.5))
	_art(c, br, d, Color(0.9, 0.9, 0.9))
	BoxArt.rect(c, Rect2(W * 0.1, H * 0.72, W * 0.8, H * 0.2), Color(1.0, 0.98, 0.85))
	_t(c, "SAMPLE - DO NOT SELL", Vector2(W * 0.1, H * 0.72), Vector2(W * 0.8, 12), 10, Color(0.75, 0.1, 0.1), "marker")
	_t(c, String(d.get("name", "")), Vector2(W * 0.1, H * 0.8), Vector2(W * 0.8, 14), 11, Color(0.1, 0.12, 0.4), "marker")


# ---------------------------------------------------------------- props

## A museum plaque: the photo in a gilt frame on velvet, a brass plate.
static func _plaque(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "plq")
	var velvet := Color.from_hsv(g.randf_range(0.95, 1.05) if g.randf() < 0.6 else 0.62, 0.65, 0.28)
	CoverComp.gradient(c, Rect2(0, 0, W, H), velvet.lightened(0.15), velvet.darkened(0.5), true)
	var fr := Rect2(W * 0.1, H * 0.07, W * 0.8, H * 0.62)
	BoxArt.rect(c, fr.grow(5), Color(0.75, 0.58, 0.22))
	BoxArt.rect(c, fr.grow(3), Color(0.95, 0.82, 0.42))
	BoxArt.rect(c, fr.grow(1), Color(0.5, 0.36, 0.12))
	_art(c, fr, d)
	CoverComp.glow(c, Vector2(W * 0.5, 0), W * 0.6, Color(1, 0.95, 0.8, 0.12))
	var pr := Rect2(W * 0.12, H * 0.74, W * 0.76, H * 0.2)
	BoxArt.rect(c, pr, Color(0.82, 0.66, 0.3))
	CCArt._frame(c, pr, Color(0.55, 0.4, 0.15), 1.0)
	_t(c, String(d.get("name", "")).to_upper(), pr.position + Vector2(3, 2), Vector2(pr.size.x - 6, pr.size.y * 0.5), 11, Color(0.18, 0.1, 0.03), "cinzel")
	_t(c, "%s  -  %d" % [String(d.get("maker", "")), int(d.get("year", 0))], pr.position + Vector2(3, pr.size.y * 0.55), Vector2(pr.size.x - 6, pr.size.y * 0.38), 8, Color(0.25, 0.15, 0.05), "russo")
	if (d.get("tags", []) as Array).has("screen"):
		_stamp(c, "SCREEN USED", Vector2(W * 0.5, H * 0.62), Color(0.85, 0.15, 0.15, 0.9), -10.0)


static func _stamp(c: Control, txt: String, ctr: Vector2, col: Color, rot := -8.0) -> void:
	var holder := Control.new()
	holder.size = Vector2(W * 0.6, 18)
	holder.position = ctr - holder.size * 0.5
	holder.pivot_offset = holder.size * 0.5
	holder.rotation_degrees = rot
	c.add_child(holder)
	CCArt._frame(holder, Rect2(Vector2.ZERO, holder.size), col, 2.0)
	_t(holder, txt, Vector2(2, 1), holder.size - Vector2(4, 2), 12, col, "blackops")


# ---------------------------------------------------------------- posters

## A painted one-sheet in the style of its decade.
static func _one_sheet(c: Control, d: Dictionary) -> void:
	var g := _rng(String(d["id"]) + "post")
	var year := int(d.get("year", 1960))
	var base := _base(d, g)
	var horror := year < 1940 and (String(d.get("maker", "")).begins_with("Univers") or g.randf() < 0.3)
	var font := "creep" if horror else ("cinzel" if year < 1950 else ("bungee" if year < 1970 else "russo"))
	if year < 1950:
		base = Color.from_hsv(base.h, 0.55, 0.45)
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.96, 0.94, 0.88))
	var ar := Rect2(4, 4, W - 8, H * 0.7)
	CoverComp.gradient(c, ar, base.lightened(0.25), base.darkened(0.55))
	_art(c, Rect2(ar.position.x, ar.position.y + ar.size.y * 0.15, ar.size.x, ar.size.y * 0.85), d, Color.WHITE, false)
	_t(c, ["THE PICTURE OF THE YEAR!", "SEE IT FROM THE BEGINNING!", "THE TALK OF THE TOWN!", "NOTHING LIKE IT EVER!"][g.randi() % 4], Vector2(6, 7), Vector2(W - 12, 9), 7, Color(1, 1, 0.9), "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.7))
	var tc := Color(1.0, 0.85, 0.2) if not horror else Color(0.6, 1.0, 0.45)
	var title := String(d.get("name", "")).to_upper()
	var fs := clampi(int(W * 2.2 / maxf(6.0, title.length())), 9, 20)
	_t(c, title, Vector2(4, H * 0.56), Vector2(W - 8, H * 0.22), fs, tc, font, HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.9), true)
	# The credit block.
	for k in 4:
		BoxArt.rect(c, Rect2(W * (0.15 + 0.03 * (k % 2)), H * 0.8 + k * 4, W * (0.7 - 0.06 * (k % 2)), 2), Color(0.25, 0.2, 0.2, 0.6))
	_t(c, String(d.get("maker", "")).to_upper() + " PRESENTS", Vector2(4, H - 13), Vector2(W - 8, 9), 7, Color(0.3, 0.1, 0.1), "russo")


## Fold lines on a folded one-sheet: theatres got them folded in eighths.
static func _folds(c: Control, d: Dictionary) -> void:
	var cond := String(d.get("cond", "CIB"))
	if cond == "Sealed":
		return
	var a := 0.16 if cond == "Damaged" else (0.1 if cond == "Loose" else 0.05)
	BoxArt.rect(c, Rect2(W * 0.5, 0, 1, H), Color(1, 1, 1, a))
	for k in [0.25, 0.5, 0.75]:
		BoxArt.rect(c, Rect2(0, H * k, W, 1), Color(1, 1, 1, a))
	if cond == "Damaged":
		BoxArt.poly(c, PackedVector2Array([Vector2(W, H * 0.3), Vector2(W - 14, H * 0.36), Vector2(W, H * 0.42)]), Color(0.1, 0.08, 0.08))


# ---------------------------------------------------------------- box lots

static func _box_lot(c: Control, d: Dictionary, back := false) -> void:
	var g := _rng(String(d["id"]) + ("lotb" if back else "lot"))
	var plat := String(d["plat"])
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.14, 0.12, 0.14))
	match plat:
		"TOYS":
			# A painted toy chest with a circus band.
			var wood := Color(0.62, 0.22, 0.2)
			BoxArt.rect(c, Rect2(6, H * 0.18, W - 12, H * 0.76), wood)
			BoxArt.rect(c, Rect2(2, H * 0.12, W - 4, H * 0.12), wood.darkened(0.25))
			for k in 6:
				BoxArt.circle(c, Vector2(20 + k * (W - 40) / 5.0, H * 0.55), 9, Color.from_hsv(k / 6.0, 0.6, 0.95), 14)
			BoxArt.rect(c, Rect2(W * 0.44, H * 0.2, W * 0.12, 10), Color(0.85, 0.7, 0.3))
		"PROP":
			var wood := Color(0.6, 0.45, 0.28)
			BoxArt.rect(c, Rect2(4, H * 0.14, W - 8, H * 0.8), wood)
			for k in 5:
				BoxArt.rect(c, Rect2(4, H * 0.14 + k * H * 0.16, W - 8, 2), wood.darkened(0.35))
			_t(c, "PROPS DEPT", Vector2(8, H * 0.3), Vector2(W - 16, 20), 18, Color(0.1, 0.08, 0.06, 0.8), "blackops")
			_t(c, "STAGE 7  -  HANDLE WITH CARE", Vector2(8, H * 0.46), Vector2(W - 16, 10), 8, Color(0.1, 0.08, 0.06, 0.8), "russo")
		"POST":
			# A cardboard tube lying across, a rolled poster poking out.
			BoxArt.rect(c, Rect2(10, H * 0.38, W - 30, H * 0.26), Color(0.7, 0.55, 0.35))
			BoxArt.circle(c, Vector2(W - 20, H * 0.51), H * 0.13, Color(0.85, 0.82, 0.75), 18)
			BoxArt.circle(c, Vector2(W - 20, H * 0.51), H * 0.05, Color(0.6, 0.55, 0.5), 12)
			BoxArt.rect(c, Rect2(10, H * 0.42, W - 30, 3), Color(0.5, 0.38, 0.22))
		"MEMO":
			for k in 4:
				var col := Color.from_hsv(g.randf(), 0.6, 0.85)
				BoxArt.rect(c, Rect2(14 + g.randf_range(-6, 6), H * 0.18 + k * H * 0.19, W - 28, H * 0.17), col)
				BoxArt.rect(c, Rect2(W * 0.4, H * 0.16 + k * H * 0.19, W * 0.2, 4), Color(0.2, 0.2, 0.22))
			BoxArt.rect(c, Rect2(W * 0.48, H * 0.12, 3, H * 0.8), Color(0.85, 0.8, 0.6))
		_:
			# A brown shipper case, taped.
			var card := Color(0.66, 0.5, 0.32)
			BoxArt.rect(c, Rect2(6, H * 0.12, W - 12, H * 0.82), card)
			BoxArt.rect(c, Rect2(6, H * 0.42, W - 12, 10), Color(0.82, 0.72, 0.5, 0.85))
			_t(c, "12 ASST", Vector2(8, H * 0.18), Vector2(W - 16, 18), 16, Color(0.15, 0.1, 0.06, 0.8), "blackops")
			_t(c, "%s  WAREHOUSE #%d" % [String(d.get("maker", "")).to_upper(), 100 + absi(hash(String(d["id"]))) % 900], Vector2(8, H * 0.6), Vector2(W - 16, 10), 8, Color(0.15, 0.1, 0.06, 0.8), "russo")
	var lab: String = ["DO NOT OPEN", "MISC", "KEEP?", "ATTIC", "DALE - UNSORTED", "TOYS"][g.randi() % 6]
	if back:
		lab = "ABOUT %d PIECES" % int(d.get("count", 20))
	BoxArt.rect(c, Rect2(12, H * 0.68, W - 24, 24), Color(0.95, 0.92, 0.7, 0.92))
	var tl := _t(c, lab, Vector2(14, H * 0.68), Vector2(W - 28, 24), 14, Color(0.1, 0.1, 0.12), "marker")
	tl.rotation_degrees = g.randf_range(-4, 4)
	_t(c, String(Catalog.platform(plat)["name"]).to_upper(), Vector2(6, 4), Vector2(W - 12, 12), 10, Color(0.98, 0.95, 0.85), "marker", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.7))
	if String(d.get("variant", "")) == "Resealed?":
		var t2 := BoxArt.rect(c, Rect2(-4, H - 30, W + 8, 10), Color(0.85, 0.75, 0.45, 0.65))
		t2.rotation_degrees = 4.0


# ---------------------------------------------------------------- variants

static func _sticker(c: Control, txt: String, ctr: Vector2, r: float, col: Color, ink := Color(0.05, 0.05, 0.05)) -> void:
	BoxArt.circle(c, ctr, r, col, 18)
	_t(c, txt, ctr - Vector2(r * 0.95, r * 0.8), Vector2(r * 1.9, r * 1.6), int(r * 0.36), ink, "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)


static func _variant(c: Control, d: Dictionary) -> void:
	var v := String(d.get("variant", "Standard"))
	match v:
		"Re-Release":
			BoxArt.rect(c, Rect2(0, H * 0.13, W, 11), Color(0.85, 0.75, 0.2, 0.95))
			_t(c, "25TH ANNIVERSARY RE-RELEASE" if String(d.get("kind", "")) == "toy" else "RE-RELEASE", Vector2(2, H * 0.13), Vector2(W - 4, 11), 8, Color(0.15, 0.1, 0.05), "russo")
		"Reproduction Card":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(1.0, 0.4, 0.8, 0.1))
			_t(c, "repro", Vector2(4, H - 22), Vector2(30, 10), 7, Color(1, 1, 1, 0.4), "jersey", HORIZONTAL_ALIGNMENT_LEFT)
		"Foreign Release":
			BoxArt.rect(c, Rect2(0, H * 0.13, W, 11), Color(0.1, 0.4, 0.75, 0.92))
			_t(c, ["FIGURA DE ACCION", "FIGURINE ARTICULEE", "SPIELFIGUR", "FIGURA D'AZIONE"][absi(hash(String(d["id"]))) % 4], Vector2(2, H * 0.13), Vector2(W - 4, 11), 8, Color.WHITE, "russo")
		"Store Exclusive":
			_sticker(c, "ONLY AT\nTOYZ 4 KIDZ", Vector2(W - 22, H - 30), 18, Color(0.3, 0.75, 1.0))
		"Glow in the Dark":
			CoverComp.glow(c, Vector2(W * 0.5, H * 0.5), W * 0.5, Color(0.5, 1.0, 0.4, 0.18))
			_sticker(c, "GLOWS IN\nTHE DARK!", Vector2(22, H - 30), 18, Color(0.6, 1.0, 0.4))
		"Chrome Finish":
			_sticker(c, "CHROME\nEDITION", Vector2(W - 22, 34), 18, Color(0.85, 0.88, 0.95))
		"Convention Exclusive":
			_sticker(c, "CON\nEXCLUSIVE\n1 OF 500", Vector2(W - 22, H - 30), 19, Color(0.75, 0.5, 1.0), Color.WHITE)
		"Signed by the Cast":
			var who: String = ["Mark", "Carrie", "Harrison", "Sigourney", "Bruce", "Linda"][absi(hash(String(d["id"]))) % 6]
			_t(c, who + "  x", Vector2(W * 0.08, H * 0.4), Vector2(W * 0.84, 36), 20, Color(0.92, 0.92, 0.95), "marker", HORIZONTAL_ALIGNMENT_CENTER, Color(0.1, 0.1, 0.12, 0.8))
		"Misprint":
			# A factory error: the name banner printed upside down.
			var holder := Control.new()
			holder.size = Vector2(W, 14)
			holder.position = Vector2(0, H * 0.4)
			holder.pivot_offset = holder.size * 0.5
			holder.rotation_degrees = 180.0
			c.add_child(holder)
			BoxArt.rect(holder, Rect2(Vector2.ZERO, holder.size), Color(0.95, 0.2, 0.3, 0.8))
			_t(holder, String(d.get("name", "")).to_upper(), Vector2(2, 0), holder.size - Vector2(4, 0), 10, Color.WHITE, "russo")
		"Stunt Double":
			_stamp(c, "STUNT", Vector2(W * 0.5, H * 0.35), Color(0.9, 0.55, 0.15, 0.9), 12.0)
		"Background Piece":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(0, 0, 0, 0.18))
		"Studio Letter":
			BoxArt.rect(c, Rect2(W - 32, 6, 26, 32), Color(0.97, 0.96, 0.9))
			for k in 5:
				BoxArt.rect(c, Rect2(W - 29, 12 + k * 5, 20, 1), Color(0.3, 0.3, 0.35))
		"Hero Version":
			_stamp(c, "HERO", Vector2(W * 0.5, H * 0.35), Color(0.95, 0.78, 0.2, 0.95), -12.0)
		"Advance Teaser":
			BoxArt.rect(c, Rect2(0, H * 0.06, W, 12), Color(0.05, 0.05, 0.08, 0.85))
			_t(c, "COMING SOON TO A THEATRE NEAR YOU", Vector2(2, H * 0.06), Vector2(W - 4, 12), 8, Color(1, 0.9, 0.4), "russo")
		"Style B":
			_t(c, "STYLE B", Vector2(4, H - 22), Vector2(40, 9), 7, Color(1, 1, 1, 0.85), "russo", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.7))
		"International Version":
			_t(c, "INTERNATIONAL", Vector2(W - 64, H - 22), Vector2(60, 9), 7, Color(1, 1, 1, 0.85), "russo", HORIZONTAL_ALIGNMENT_RIGHT, Color(0, 0, 0, 0.7))
		"Foil Teaser":
			CCArt._foil(c, Rect2(0, 0, W, H), 0.3, String(d["id"]))
		"Printer's Proof":
			var cols := [Color(0, 1, 1), Color(1, 0, 1), Color(1, 1, 0), Color(0, 0, 0)]
			for k in 12:
				BoxArt.rect(c, Rect2(W - 7, 4 + k * (H - 8) / 12.0, 6, (H - 8) / 12.0 - 1), cols[k % 4])
		"Pedigree":
			BoxArt.rect(c, Rect2(W * 0.14, H - 26, W * 0.72, 16), Color(0.98, 0.96, 0.88))
			CCArt._frame(c, Rect2(W * 0.14, H - 26, W * 0.72, 16), Color(0.6, 0.1, 0.1), 1.0)
			_t(c, "FROM A STAR'S\nPRIVATE COLLECTION", Vector2(W * 0.14, H - 26), Vector2(W * 0.72, 16), 7, Color(0.6, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)


# ---------------------------------------------------------------- backs

static func paint_back(c: Control, d: Dictionary, w: int) -> void:
	W = w
	var kind := String(d.get("kind", "toy"))
	var g := _rng(String(d["id"]) + "back")
	match kind:
		"toybox":
			_box_lot(c, d, true)
		"prop":
			# A letter of provenance on studio paper.
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.97, 0.96, 0.92))
			_t(c, String(d.get("maker", "")).to_upper(), Vector2(6, 6), Vector2(W - 12, 14), 12, Color(0.2, 0.15, 0.4), "cinzel")
			BoxArt.rect(c, Rect2(6, 22, W - 12, 1), Color(0.2, 0.15, 0.4))
			_t(c, "LETTER OF PROVENANCE", Vector2(6, 26), Vector2(W - 12, 10), 8, Color(0.3, 0.3, 0.35), "russo")
			_t(c, "This certifies that the %s offered here was made for and used in the %d production." % [String(d.get("name", "")), int(d.get("year", 0))], Vector2(8, 40), Vector2(W - 16, 50), 8, Color(0.15, 0.15, 0.2), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
			for k in 5:
				BoxArt.rect(c, Rect2(8, 92 + k * 6, (W - 16) * (0.6 + 0.4 * g.randf()), 2), Color(0.3, 0.3, 0.35, 0.4))
			_t(c, "J. Archivist", Vector2(W * 0.4, H - 22), Vector2(W * 0.55, 16), 12, Color(0.1, 0.12, 0.4), "marker")
		"poster":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.93, 0.91, 0.84))
			_folds(c, d.merged({"cond": "Damaged"}, true) if String(d.get("cond", "")) == "Damaged" else d.merged({"cond": "Loose"}, true))
			_t(c, "NSS  %02d/%d" % [int(d.get("year", 1960)) % 100, 100 + absi(hash(String(d["id"]))) % 400], Vector2(6, H - 16), Vector2(W * 0.6, 10), 8, Color(0.3, 0.3, 0.3), "russo", HORIZONTAL_ALIGNMENT_LEFT)
			_t(c, "Property of National Screen Servyce. Return after showing.", Vector2(6, H - 30), Vector2(W - 12, 12), 6, Color(0.35, 0.35, 0.35), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
		_:
			var form := String(d.get("form", "boxed"))
			var base := _base(d, _rng(String(d["id"]) + ("card" if form in ["carded", "vehicle"] else "box")))
			BoxArt.rect(c, Rect2(0, 0, W, H), base.darkened(0.15))
			_t(c, "COLLECT THEM ALL!", Vector2(4, 6), Vector2(W - 8, 14), 13, Color(1, 0.95, 0.3), "lucky", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.8))
			# The rest of the wave: little boxes with names from this aisle.
			var pool := Catalog.items_of("pop").filter(func(x): return String(x["plat"]) == String(d["plat"]) and String(x["kind"]) != "toybox")
			for k in mini(6, pool.size()):
				var o: Dictionary = pool[(k * 3 + g.randi() % 3) % pool.size()]
				var r := Rect2(6 + (k % 3) * (W - 12) / 3.0, 26 + (k / 3) * 52, (W - 12) / 3.0 - 4, 48)
				BoxArt.rect(c, r, Color(1, 1, 1, 0.9))
				var ink := Color.from_hsv(float(absi(hash(String(o["id"]))) % 100) / 100.0, 0.6, 0.7)
				BoxArt.rect(c, Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, r.size.y - 18)), ink)
				_t(c, String(o["name"]), Vector2(r.position.x + 1, r.end.y - 14), Vector2(r.size.x - 2, 13), 6, Color(0.1, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0), true)
			_t(c, "(c) %d %s. Made in Hong Kong." % [int(d.get("year", 1980)), String(d.get("maker", ""))], Vector2(4, H - 14), Vector2(W - 8, 10), 7, Color(1, 1, 1, 0.85), "jersey")
