extends RefCounted
## Paints trading cards, sealed card product and coins (BoxArt.paint_front/back
## hand these kinds over). No class_name (TV self-update): preload it.
##
##   Cards: each TCG has its own frame. Pocket Critters = yellow border, type
##     colour, HP, two moves with energy pips, weakness row, set number.
##     Magick = black border, colour frame, mana cost, type line, rules box, P/T.
##     Yu-Gi-Whoa = frame by card type, attribute orb, level stars, ATK/DEF.
##     Other TCGs = accent frame, cost gem, power. Art windows show the card's
##     subject (Subjects CG render) over a seeded backdrop; holo variants get a
##     rainbow foil, 1st Edition a stamp, Shadowless no drop shadow.
##   Packs: a crimped foil booster, a display box or a starter deck.
##   Coins: front = obverse, back = reverse, painted as struck metal in relief:
##     beaded rim, legends around the edge, the date, and a motif (a Liberty
##     head with its headdress, an emperor in laurels, an eagle, an owl...).

const PROFILE := [Vector2(0.34, 0.98), Vector2(0.3, 0.58), Vector2(0.52, 0.28), Vector2(0.52, -0.28), Vector2(0.26, -0.58),
	Vector2(-0.08, -0.66), Vector2(-0.34, -0.5), Vector2(-0.44, -0.24), Vector2(-0.45, -0.1), Vector2(-0.6, 0.04),
	Vector2(-0.47, 0.12), Vector2(-0.5, 0.21), Vector2(-0.44, 0.27), Vector2(-0.47, 0.36), Vector2(-0.33, 0.47),
	Vector2(-0.17, 0.55), Vector2(-0.16, 0.98)]

const CRIT_COL := {"Fire": Color("e8603a"), "Water": Color("3a8ad6"), "Grass": Color("5ab04a"), "Lightning": Color("f2c230"),
	"Psychic": Color("a05ab8"), "Fighting": Color("b86a3a"), "Darkness": Color("3a3a4a"), "Dragon": Color("c8a03a"),
	"Colorless": Color("c8c4b8"), "Trainer": Color("9aa3b5")}
const MAGI_COL := {"White": Color("efe6c8"), "Blue": Color("4a7ac8"), "Black": Color("4a4048"), "Red": Color("c8503a"),
	"Green": Color("4a9a5a"), "Artifact": Color("a8a4a0"), "Land": Color("b89a6a"), "Gold": Color("d8b04a")}
const MANA := {"W": Color("f5f0d0"), "U": Color("5a9ae0"), "B": Color("3a3438"), "R": Color("e0603a"), "G": Color("4ab05a")}
const YUGI_COL := {"Normal": Color("d8b05a"), "Effect": Color("d07a3a"), "Spell": Color("1f9a82"), "Trap": Color("b8407e"),
	"Fusion": Color("8a52b8"), "Ritual": Color("4a72d0")}
const ATTR_COL := {"DARK": Color("6a3a8a"), "LIGHT": Color("e8d070"), "FIRE": Color("e0503a"), "WATER": Color("3a80d8"),
	"EARTH": Color("8a6a3a"), "WIND": Color("5ab06a"), "DIVINE": Color("e8b030"), "SPELL": Color("1f9a82"), "TRAP": Color("b8407e")}
## [field, highlight, shadow] per metal.
const METALS := {"gold": [Color("e2b84e"), Color("fff0b0"), Color("8a6418")], "silver": [Color("c4cad3"), Color("ffffff"), Color("6a707c")],
	"copper": [Color("c47a48"), Color("f2b080"), Color("6a3418")], "bronze": [Color("a8784a"), Color("e0b080"), Color("5a3a1a")],
	"nickel": [Color("b4b6ae"), Color("eceee6"), Color("62645e")], "steel": [Color("cfd4da"), Color("ffffff"), Color("7a8088")],
	"electrum": [Color("d4c070"), Color("fff2b8"), Color("7a6a28")], "billon": [Color("9c968e"), Color("d8d2c8"), Color("54504a")],
	"brass": [Color("c8aa52"), Color("f2e090"), Color("6a5420")], "pewter": [Color("9ea4a4"), Color("dce0e0"), Color("565c5c")]}

static var W := 120
static var H := 150


static func _def(item: Dictionary) -> Dictionary:
	var d: Dictionary = Catalog.get_def(String(item.get("id", ""))).duplicate()
	d.merge(item, true)
	return d


static func _rng(key: String) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = hash(key)
	return g


## Text in a named cover font, shrunk until it fits.
static func _t(c: Control, txt: String, pos: Vector2, size: Vector2, fs: int, col: Color, fname := "jersey", align := HORIZONTAL_ALIGNMENT_LEFT, outline := Color(0, 0, 0, 0), wrap := false) -> Label:
	var l := Label.new()
	var f := CoverComp.font(fname)
	var px := fs
	while px > 5 and not wrap:
		if f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x <= size.x:
			break
		px -= 1
	l.text = txt
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", col)
	if outline.a > 0.0:
		l.add_theme_color_override("font_outline_color", outline)
		l.add_theme_constant_override("outline_size", maxi(2, px / 4))
	l.add_theme_constant_override("line_spacing", -int(px * 0.3))
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	l.position = pos
	l.size = size
	l.clip_text = true
	c.add_child(l)
	return l


static func _frame(c: Control, r: Rect2, col: Color, t := 1.0) -> void:
	BoxArt.rect(c, Rect2(r.position.x, r.position.y, r.size.x, t), col)
	BoxArt.rect(c, Rect2(r.position.x, r.end.y - t, r.size.x, t), col)
	BoxArt.rect(c, Rect2(r.position.x, r.position.y, t, r.size.y), col)
	BoxArt.rect(c, Rect2(r.end.x - t, r.position.y, t, r.size.y), col)


static func _star(c: Control, ctr: Vector2, r: float, col: Color, pts := 5) -> void:
	var p := PackedVector2Array()
	for i in pts * 2:
		var a := -PI / 2.0 + PI * i / pts
		p.append(ctr + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	BoxArt.poly(c, p, col)


## Diagonal rainbow foil over r (holo cards, foil packs).
static func _foil(c: Control, r: Rect2, alpha: float, key: String) -> void:
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	var g := _rng(key + "foil")
	var off := g.randf() * 40.0
	var n := 9
	for i in n:
		var x := -r.size.y + (r.size.x + r.size.y) * float(i) / n + off * 0.3
		var col := Color.from_hsv(fmod(float(i) / n + g.randf() * 0.1, 1.0), 0.6, 1.0, alpha)
		var w := (r.size.x + r.size.y) / n
		BoxArt.poly(holder, PackedVector2Array([Vector2(x, r.size.y), Vector2(x + w, r.size.y), Vector2(x + w + r.size.y, 0), Vector2(x + r.size.y, 0)]), col)
	for k in 6:
		BoxArt.circle(holder, Vector2(g.randf() * r.size.x, g.randf() * r.size.y), g.randf_range(1.0, 2.2), Color(1, 1, 1, alpha * 2.4), 6)


## The card's illustration: seeded sky + ground, glow and the subject render.
static func _art(c: Control, r: Rect2, d: Dictionary, base: Color, shadow := true) -> void:
	var g := _rng(String(d.get("id", "")) + "art")
	if shadow:
		BoxArt.rect(c, Rect2(r.position + Vector2(2, 2), r.size), Color(0, 0, 0, 0.45))
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	var lr := Rect2(Vector2.ZERO, r.size)
	var hue := fmod(base.h + g.randf_range(-0.12, 0.12) + 1.0, 1.0)
	CoverComp.gradient(holder, lr, Color.from_hsv(hue, 0.45, 0.95), Color.from_hsv(fmod(hue + 0.08, 1.0), 0.65, 0.55))
	match g.randi() % 4:
		0:
			BoxArt.rect(holder, Rect2(0, r.size.y * 0.7, r.size.x, r.size.y * 0.3), Color.from_hsv(fmod(hue + 0.3, 1.0), 0.5, 0.5))
		1:
			for k in 5:
				var x := g.randf() * r.size.x
				BoxArt.poly(holder, PackedVector2Array([Vector2(x - 18, r.size.y), Vector2(x, r.size.y * g.randf_range(0.45, 0.7)), Vector2(x + 18, r.size.y)]), Color.from_hsv(hue, 0.3, 0.4, 0.8))
		2:
			var ctr := Vector2(r.size.x * 0.5, r.size.y * 0.5)
			for k in 10:
				var a := TAU * k / 10.0
				BoxArt.poly(holder, PackedVector2Array([ctr, ctr + Vector2(cos(a), sin(a)) * 90, ctr + Vector2(cos(a + 0.3), sin(a + 0.3)) * 90]), Color(1, 1, 1, 0.13))
		_:
			for k in 14:
				BoxArt.circle(holder, Vector2(g.randf() * r.size.x, g.randf() * r.size.y * 0.6), g.randf_range(0.6, 1.6), Color(1, 1, 0.9, 0.8), 5)
	CoverComp.glow(holder, Vector2(r.size.x * 0.5, r.size.y * 0.5), r.size.y * 0.42, Color(1, 0.95, 0.75))
	var subj := String(d.get("subj", ""))
	if subj == "":
		subj = "sparkles"
	var hgt := r.size.y * 0.86
	CoverComp.cg(holder, g, subj, Vector2(r.size.x * 0.5, r.size.y * 0.95), hgt, g.randf() < 0.4)


# ================================================================ cards

static func paint_front(c: Control, item: Dictionary, w: int) -> void:
	W = w
	var d := _def(item)
	match String(d.get("kind", "")):
		"coin": _coin(c, d, true)
		"pack": _pack(c, d)
		_: _card(c, d)


static func paint_back(c: Control, item: Dictionary, w: int) -> void:
	W = w
	var d := _def(item)
	match String(d.get("kind", "")):
		"coin": _coin(c, d, false)
		"pack": _pack_back(c, d)
		_: _card_back(c, String(d["plat"]), d)


static func _card(c: Control, d: Dictionary) -> void:
	var v := String(d.get("variant", "Standard"))
	if v == "Playtest Card":
		_playtest(c, d)
		return
	match String(d["plat"]):
		"CRIT": _crit(c, d)
		"MAGI": _magi(c, d)
		"YUGI": _yugi(c, d)
		_: _alt(c, d)
	match v:
		"1st Edition":
			BoxArt.circle(c, Vector2(12, 84), 5, Color(0.05, 0.05, 0.05), 12)
			_t(c, "1", Vector2(7, 78), Vector2(10, 12), 10, Color.WHITE, "jersey", HORIZONTAL_ALIGNMENT_CENTER)
		"Promo Stamp":
			_star(c, Vector2(W - 13, 84), 6, Color(1, 0.85, 0.2))
		"Signed by Artist":
			var ln := Line2D.new()
			var pts := PackedVector2Array()
			for k in 10:
				pts.append(Vector2(W * 0.2 + k * W * 0.06, 52 + sin(k * 1.9) * 6))
			ln.points = pts
			ln.width = 1.5
			ln.default_color = Color(0.92, 0.92, 0.98)
			c.add_child(ln)
		"Misprint":
			var gh := _t(c, String(d["name"]).to_upper(), Vector2(4, 30), Vector2(W - 8, 14), 12, Color(1, 0.2, 0.7, 0.55), "bungee")
			gh.rotation_degrees = 8.0
			BoxArt.rect(c, Rect2(0, 0, 4, H), Color(0.2, 0.9, 0.9, 0.8))
		"Japan Import":
			BoxArt.rect(c, Rect2(W - 18, H - 13, 14, 9), Color.WHITE)
			BoxArt.circle(c, Vector2(W - 11, H - 8.5), 2.6, Color(0.85, 0.1, 0.15), 10)


static func _energy(c: Control, ctr: Vector2, r: float, type: String) -> void:
	var col: Color = CRIT_COL.get(type, CRIT_COL["Colorless"])
	BoxArt.circle(c, ctr, r + 0.8, Color(0.1, 0.1, 0.1), 12)
	BoxArt.circle(c, ctr, r, col, 12)
	BoxArt.circle(c, ctr - Vector2(r, r) * 0.3, r * 0.35, Color(1, 1, 1, 0.45), 8)


static func _crit(c: Control, d: Dictionary) -> void:
	var type := String(d.get("ctype", "Colorless"))
	var col: Color = CRIT_COL.get(type, CRIT_COL["Colorless"])
	var v := String(d.get("variant", ""))
	BoxArt.rect(c, Rect2(0, 0, W, H), Color("f2c230"))
	BoxArt.rect(c, Rect2(4, 4, W - 8, H - 8), col.lightened(0.15))
	CoverComp.gradient(c, Rect2(4, 4, W - 8, H - 8), col.lightened(0.45), col.darkened(0.05))
	var trainer := type == "Trainer"
	if trainer:
		BoxArt.rect(c, Rect2(4, 4, W - 8, 13), Color(0.25, 0.3, 0.45))
		_t(c, "TRAINER", Vector2(7, 4), Vector2(W - 14, 13), 11, Color.WHITE, "russo")
	else:
		_t(c, String(d.get("line", "Basic")).to_upper(), Vector2(7, 4), Vector2(40, 7), 6, Color(0.15, 0.15, 0.15))
	_t(c, String(d["name"]), Vector2(7, 9 if not trainer else 17), Vector2(W - 44, 12), 11, Color(0.08, 0.08, 0.1), "russo")
	if not trainer:
		_t(c, "%d HP" % int(d.get("hp", 60)), Vector2(W - 44, 8), Vector2(28, 12), 9, Color(0.85, 0.1, 0.1), "russo", HORIZONTAL_ALIGNMENT_RIGHT)
		_energy(c, Vector2(W - 11, 14), 4.2, type)
	var ar := Rect2(9, 24 if not trainer else 30, W - 18, 58)
	BoxArt.rect(c, ar.grow(2), Color("d8b040"))
	_art(c, ar, d, col, v != "Shadowless")
	_frame(c, ar.grow(2), Color("8a6a20"))
	if v == "Holo Foil":
		_foil(c, ar, 0.22, String(d["id"]))
	elif v == "Reverse Holo":
		_foil(c, Rect2(4, ar.end.y + 3, W - 8, H - ar.end.y - 8), 0.2, String(d["id"]))
	BoxArt.rect(c, Rect2(14, ar.end.y + 2, W - 28, 6), Color("e8d090"))
	_t(c, "NO. %03d  %s CRITTER" % [absi(hash(String(d["id"]))) % 251 + 1, type.to_upper()], Vector2(14, ar.end.y + 2), Vector2(W - 28, 6), 5, Color(0.25, 0.2, 0.1), "jersey", HORIZONTAL_ALIGNMENT_CENTER)
	var y := ar.end.y + 10
	if trainer:
		_t(c, String(d.get("text", "")), Vector2(9, y), Vector2(W - 18, 34), 8, Color(0.1, 0.1, 0.12), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	else:
		for mv in d.get("moves", []):
			var cost := 1 + int(mv[1]) / 40
			for k in mini(cost, 3):
				_energy(c, Vector2(12 + k * 7, y + 6), 3, type if k == 0 else "Colorless")
			_t(c, String(mv[0]), Vector2(34, y), Vector2(W - 60, 12), 9, Color(0.08, 0.08, 0.1), "russo")
			_t(c, str(mv[1]), Vector2(W - 28, y), Vector2(20, 12), 10, Color(0.08, 0.08, 0.1), "russo", HORIZONTAL_ALIGNMENT_RIGHT)
			BoxArt.rect(c, Rect2(9, y + 14, W - 18, 1), Color(0.1, 0.1, 0.1, 0.3))
			y += 17
	var wy := H - 27
	_t(c, "weakness", Vector2(8, wy), Vector2(24, 6), 5, Color(0.1, 0.1, 0.1))
	_t(c, "resistance", Vector2(W * 0.38, wy), Vector2(26, 6), 5, Color(0.1, 0.1, 0.1))
	_t(c, "retreat", Vector2(W - 28, wy), Vector2(22, 6), 5, Color(0.1, 0.1, 0.1))
	if not trainer:
		var weak := {"Fire": "Water", "Water": "Lightning", "Grass": "Fire", "Lightning": "Fighting", "Psychic": "Darkness", "Fighting": "Psychic", "Darkness": "Fighting", "Dragon": "Dragon", "Colorless": "Fighting"}
		_energy(c, Vector2(14, wy + 9), 2.6, String(weak.get(type, "Fighting")))
		for k in 1 + absi(hash(String(d["id"]) + "rt")) % 3:
			_energy(c, Vector2(W - 24 + k * 6, wy + 9), 2.4, "Colorless")
	BoxArt.rect(c, Rect2(8, H - 16, W - 16, 9), Color(1, 1, 0.92, 0.75))
	_t(c, String(d.get("blurb", "")), Vector2(9, H - 16), Vector2(W - 18, 9), 5, Color(0.2, 0.2, 0.2), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	_t(c, "Illus. " + String(d.get("artist", "")), Vector2(6, H - 7), Vector2(W * 0.55, 5), 5, Color(0.15, 0.15, 0.15))
	_t(c, String(d.get("num", "")), Vector2(W * 0.55, H - 7), Vector2(W * 0.3, 5), 5, Color(0.15, 0.15, 0.15), "jersey", HORIZONTAL_ALIGNMENT_RIGHT)
	_rarity_mark(c, Vector2(W - 9, H - 4.5), String(d.get("rarity", "Common")), int(d.get("tier", 0)))


static func _rarity_mark(c: Control, at: Vector2, rarity: String, tier: int) -> void:
	if rarity.contains("Gold Star"):
		_star(c, at, 3.2, Color(1, 0.8, 0.15))
	elif tier >= 2 or rarity.contains("Holo") or rarity.contains("Art"):
		_star(c, at, 3.0, Color(0.05, 0.05, 0.05))
	elif tier == 1:
		BoxArt.poly(c, PackedVector2Array([at + Vector2(0, -2.6), at + Vector2(2.6, 0), at + Vector2(0, 2.6), at + Vector2(-2.6, 0)]), Color(0.05, 0.05, 0.05))
	else:
		BoxArt.circle(c, at, 2.2, Color(0.05, 0.05, 0.05), 8)


static func _mana(c: Control, cost: String, right: float, y: float) -> void:
	var pips: Array = []
	var num := ""
	for ch in cost:
		if ch.is_valid_int():
			num += ch
		else:
			pips.append(ch)
	if num != "":
		pips.push_front(num)
	var x := right - 6.0 * pips.size()
	for p in pips:
		var col: Color = MANA.get(p, Color(0.75, 0.73, 0.7))
		BoxArt.circle(c, Vector2(x + 3, y), 3.0, Color(0.1, 0.1, 0.1), 10)
		BoxArt.circle(c, Vector2(x + 3, y), 2.5, col, 10)
		if not MANA.has(p):
			_t(c, String(p), Vector2(x, y - 4), Vector2(6, 8), 7, Color(0.1, 0.1, 0.1), "jersey", HORIZONTAL_ALIGNMENT_CENTER)
		x += 6.0


static func _magi(c: Control, d: Dictionary) -> void:
	var colname := String(d.get("ctype", "Artifact"))
	var col: Color = MAGI_COL.get(colname, MAGI_COL["Artifact"])
	var v := String(d.get("variant", ""))
	var g := _rng(String(d["id"]) + "m")
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.04, 0.04, 0.05))
	BoxArt.rect(c, Rect2(5, 5, W - 10, H - 12), col.darkened(0.15))
	for k in 8:
		BoxArt.circle(c, Vector2(5 + g.randf() * (W - 10), 5 + g.randf() * (H - 12)), g.randf_range(3, 8), Color(col.lightened(0.2), 0.25), 8)
	var light := col.get_luminance() > 0.5
	BoxArt.rect(c, Rect2(8, 8, W - 16, 11), col.lightened(0.35))
	_frame(c, Rect2(8, 8, W - 16, 11), Color(0.1, 0.1, 0.1, 0.6))
	_t(c, String(d["name"]), Vector2(10, 8), Vector2(W - 20 - 6 * String(d.get("cost", "")).length(), 11), 9, Color(0.05, 0.05, 0.05), "cinzel")
	_mana(c, String(d.get("cost", "")), W - 10, 13.5)
	var ar := Rect2(11, 21, W - 22, 56)
	BoxArt.rect(c, ar.grow(1), Color(0.1, 0.1, 0.1))
	_art(c, ar, d, col, false)
	if v == "Holo Foil" or v == "Reverse Holo":
		_foil(c, ar if v == "Holo Foil" else Rect2(5, 5, W - 10, H - 12), 0.18, String(d["id"]))
	BoxArt.rect(c, Rect2(8, ar.end.y + 2, W - 16, 10), col.lightened(0.35))
	_frame(c, Rect2(8, ar.end.y + 2, W - 16, 10), Color(0.1, 0.1, 0.1, 0.6))
	_t(c, String(d.get("line", "")), Vector2(10, ar.end.y + 2), Vector2(W - 32, 10), 8, Color(0.05, 0.05, 0.05), "cinzel")
	var sc: Color = [Color(0.1, 0.1, 0.1), Color(0.75, 0.78, 0.82), Color(0.95, 0.75, 0.2), Color(0.95, 0.45, 0.15)][clampi(int(d.get("tier", 0)), 0, 3)]
	BoxArt.poly(c, PackedVector2Array([Vector2(W - 17, ar.end.y + 4), Vector2(W - 11, ar.end.y + 7), Vector2(W - 17, ar.end.y + 10), Vector2(W - 20, ar.end.y + 7)]), sc)
	var tb := Rect2(11, ar.end.y + 14, W - 22, H - ar.end.y - 26)
	BoxArt.rect(c, tb, col.lightened(0.6) if not light else Color(0.97, 0.95, 0.88))
	_t(c, String(d.get("text", "")), tb.position + Vector2(2, 1), Vector2(tb.size.x - 4, tb.size.y * 0.55), 7, Color(0.08, 0.08, 0.08), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	_t(c, String(d.get("blurb", "")), tb.position + Vector2(2, tb.size.y * 0.55), Vector2(tb.size.x - 4, tb.size.y * 0.45), 6, Color(0.25, 0.22, 0.2), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	if String(d.get("stat", "")) != "":
		BoxArt.rect(c, Rect2(W - 30, H - 16, 22, 11), col.lightened(0.35))
		_frame(c, Rect2(W - 30, H - 16, 22, 11), Color(0.1, 0.1, 0.1, 0.7))
		_t(c, String(d["stat"]), Vector2(W - 30, H - 16), Vector2(22, 11), 9, Color(0.05, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, "Illus. " + String(d.get("artist", "")), Vector2(8, H - 7), Vector2(W - 40, 6), 5, Color(0.85, 0.85, 0.85))


static func _yugi(c: Control, d: Dictionary) -> void:
	var yt := String(d.get("ctype", "Normal"))
	var col: Color = YUGI_COL.get(yt, YUGI_COL["Normal"])
	var v := String(d.get("variant", ""))
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.2, 0.13, 0.08))
	BoxArt.rect(c, Rect2(3, 3, W - 6, H - 6), col)
	CoverComp.gradient(c, Rect2(3, 3, W - 6, H - 6), col.lightened(0.2), col.darkened(0.15))
	BoxArt.rect(c, Rect2(6, 6, W - 12, 12), col.lightened(0.25))
	_frame(c, Rect2(6, 6, W - 12, 12), Color(0.25, 0.18, 0.1, 0.8))
	var gold := int(d.get("tier", 0)) >= 3 or String(d.get("rarity", "")).contains("Ultra")
	_t(c, String(d["name"]).to_upper(), Vector2(8, 6), Vector2(W - 28, 12), 9, Color(0.95, 0.85, 0.4) if gold else Color(0.05, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_LEFT, Color(0.2, 0.15, 0.05) if gold else Color(0, 0, 0, 0))
	var attr := String(d.get("attr", "DARK"))
	BoxArt.circle(c, Vector2(W - 13, 12), 5.5, Color(0.1, 0.1, 0.1), 14)
	BoxArt.circle(c, Vector2(W - 13, 12), 4.8, ATTR_COL.get(attr, Color.GRAY), 14)
	_t(c, attr.substr(0, 1), Vector2(W - 18, 7), Vector2(10, 10), 8, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
	var lv := int(d.get("level", 0))
	if lv > 0:
		for k in lv:
			BoxArt.circle(c, Vector2(W - 12 - k * 7.4, 23), 3.2, Color(0.85, 0.25, 0.1), 10)
			_star(c, Vector2(W - 12 - k * 7.4, 23), 2.4, Color(1, 0.85, 0.2))
	else:
		_t(c, String(d.get("line", "")), Vector2(8, 19), Vector2(W - 16, 8), 7, Color(0.05, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_RIGHT)
	var side := W - 26.0
	var ar := Rect2((W - side) * 0.5, 29, side, minf(side, 64))
	BoxArt.rect(c, ar.grow(2), Color(0.55, 0.45, 0.3))
	_art(c, ar, d, col, false)
	_frame(c, ar.grow(2), Color(0.25, 0.18, 0.1))
	if v == "Holo Foil" or String(d.get("rarity", "")).contains("Ghost"):
		_foil(c, ar, 0.24, String(d["id"]))
	var code := String(d.get("set", "LOB")).substr(0, 3).to_upper()
	_t(c, "%s-EN%03d" % [code, absi(hash(String(d["id"]))) % 125], Vector2(W * 0.45, ar.end.y + 2), Vector2(W * 0.45, 6), 5, Color(0.05, 0.05, 0.05), "jersey", HORIZONTAL_ALIGNMENT_RIGHT)
	var tb := Rect2(7, ar.end.y + 9, W - 14, H - ar.end.y - 15)
	BoxArt.rect(c, tb, Color("e8dcc0"))
	_frame(c, tb, Color(0.45, 0.35, 0.2))
	var y0 := tb.position.y + 1
	if lv > 0:
		_t(c, String(d.get("line", "")), Vector2(tb.position.x + 2, y0), Vector2(tb.size.x - 4, 7), 7, Color(0.05, 0.05, 0.05), "russo")
		y0 += 7
	var body := String(d.get("text", "")) if String(d.get("text", "")) != "" else String(d.get("blurb", ""))
	_t(c, body, Vector2(tb.position.x + 2, y0), Vector2(tb.size.x - 4, tb.end.y - y0 - 8), 6, Color(0.1, 0.08, 0.05), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	if String(d.get("stat", "")) != "":
		BoxArt.rect(c, Rect2(tb.position.x + 2, tb.end.y - 8, tb.size.x - 4, 1), Color(0.1, 0.08, 0.05))
		_t(c, String(d["stat"]), Vector2(tb.position.x + 2, tb.end.y - 7), Vector2(tb.size.x - 4, 7), 7, Color(0.05, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_RIGHT)


static func _alt(c: Control, d: Dictionary) -> void:
	var acc := Color("#" + String(d.get("accent", "3fb3a8"))) if String(d.get("accent", "")) != "" else Color("3fb3a8")
	var v := String(d.get("variant", ""))
	BoxArt.rect(c, Rect2(0, 0, W, H), acc.darkened(0.55))
	var ar := Rect2(5, 5, W - 10, H * 0.62)
	_art(c, ar, d, acc, false)
	if v == "Holo Foil" or int(d.get("tier", 0)) >= 3:
		_foil(c, ar, 0.2, String(d["id"]))
	_frame(c, Rect2(3, 3, W - 6, H - 6), acc, 2.0)
	BoxArt.circle(c, Vector2(14, 14), 8, Color(0.08, 0.08, 0.1), 16)
	BoxArt.circle(c, Vector2(14, 14), 6.8, acc.lightened(0.2), 16)
	_t(c, String(d.get("cost", "1")), Vector2(8, 8), Vector2(12, 12), 11, Color(0.05, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	var pr := Rect2(5, ar.end.y - 4, W - 10, H - ar.end.y - 2)
	BoxArt.poly(c, PackedVector2Array([pr.position, Vector2(pr.end.x, pr.position.y + 6), pr.end, Vector2(pr.position.x, pr.end.y)]), Color(0.06, 0.06, 0.08, 0.92))
	_t(c, String(d["name"]), Vector2(9, pr.position.y + 6), Vector2(W - 18, 12), 10, Color.WHITE, "bungee")
	_t(c, String(d.get("line", "")) + "  |  " + String(d.get("game", "")), Vector2(9, pr.position.y + 18), Vector2(W - 18, 7), 6, acc.lightened(0.4))
	_t(c, String(d.get("text", "")), Vector2(9, pr.position.y + 25), Vector2(W - 34, pr.size.y - 28), 6, Color(0.88, 0.88, 0.9), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	BoxArt.rect(c, Rect2(W - 30, H - 16, 24, 11), acc)
	_t(c, String(d.get("stat", "")), Vector2(W - 30, H - 16), Vector2(24, 11), 9, Color(0.05, 0.05, 0.05), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	_rarity_mark(c, Vector2(W * 0.5, H - 5), String(d.get("rarity", "")), int(d.get("tier", 0)))


static func _playtest(c: Control, d: Dictionary) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.97, 0.96, 0.92))
	_frame(c, Rect2(4, 4, W - 8, H - 8), Color(0.2, 0.2, 0.2))
	_t(c, String(d["name"]), Vector2(8, 8), Vector2(W - 16, 12), 10, Color(0.1, 0.1, 0.1), "russo")
	BoxArt.rect(c, Rect2(8, 22, W - 16, 52), Color(0.85, 0.85, 0.85))
	_t(c, "ART TBD", Vector2(8, 22), Vector2(W - 16, 52), 12, Color(0.5, 0.5, 0.5), "marker", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, String(d.get("text", d.get("blurb", ""))), Vector2(8, 78), Vector2(W - 16, 40), 7, Color(0.1, 0.1, 0.1), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	var n := _t(c, "too strong??", Vector2(10, 118), Vector2(W - 20, 14), 11, Color(0.85, 0.15, 0.15), "marker")
	n.rotation_degrees = -6.0
	_t(c, "PLAYTEST - NOT FOR SALE", Vector2(6, H - 13), Vector2(W - 12, 8), 6, Color(0.3, 0.3, 0.3), "jersey", HORIZONTAL_ALIGNMENT_CENTER)


static func _card_back(c: Control, plat: String, d: Dictionary) -> void:
	match plat:
		"CRIT":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color("1f4fa8"))
			for k in 7:
				BoxArt.circle(c, Vector2(W * 0.5, H * 0.5), H * (0.62 - k * 0.07), Color("2a64c8") if k % 2 == 0 else Color("1f4fa8"), 28)
			var ctr := Vector2(W * 0.38, H * 0.56)
			BoxArt.circle(c, ctr, W * 0.27, Color(0.05, 0.05, 0.08), 24)
			BoxArt.circle(c, ctr, W * 0.25, Color("f2f2f2"), 24)
			var top := PackedVector2Array()
			for i in 13:
				var a := PI + PI * i / 12.0
				top.append(ctr + Vector2(cos(a), sin(a)) * W * 0.25)
			BoxArt.poly(c, top, Color("ff7a2a"))
			BoxArt.rect(c, Rect2(ctr.x - W * 0.25, ctr.y - 1.5, W * 0.5, 3), Color(0.05, 0.05, 0.08))
			BoxArt.circle(c, ctr, W * 0.07, Color(0.05, 0.05, 0.08), 14)
			BoxArt.circle(c, ctr, W * 0.045, Color("f2f2f2"), 14)
			_t(c, "POCKET", Vector2(6, 14), Vector2(W - 12, 20), 18, Color("ffd23f"), "lucky", HORIZONTAL_ALIGNMENT_CENTER, Color("2a3a8a"))
			_t(c, "CRITTERS", Vector2(6, 32), Vector2(W - 12, 18), 16, Color("ffd23f"), "lucky", HORIZONTAL_ALIGNMENT_CENTER, Color("2a3a8a"))
			_t(c, "TRADING CARD GAME", Vector2(6, H - 22), Vector2(W - 12, 10), 8, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
			BoxArt.rect(c, Rect2(0, 0, W, 4), Color("2a3a8a"))
			BoxArt.rect(c, Rect2(0, H - 4, W, 4), Color("2a3a8a"))
		"MAGI":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color("6a4228"))
			CoverComp.gradient(c, Rect2(6, 6, W - 12, H - 12), Color("8a5a34"), Color("4a2a18"), true)
			var ctr2 := Vector2(W * 0.5, H * 0.5)
			var oval := PackedVector2Array()
			for i in 28:
				var a := TAU * i / 28.0
				oval.append(ctr2 + Vector2(cos(a) * W * 0.36, sin(a) * H * 0.3))
			BoxArt.poly(c, oval, Color("c86a2a"))
			var oval2 := PackedVector2Array()
			for p in oval:
				oval2.append(ctr2 + (p - ctr2) * 0.86)
			BoxArt.poly(c, oval2, Color("e8a050"))
			var cols := [MANA["W"], MANA["U"], MANA["B"], MANA["R"], MANA["G"]]
			for k in 5:
				var a2 := -PI / 2.0 + TAU * k / 5.0
				BoxArt.circle(c, ctr2 + Vector2(cos(a2) * W * 0.36, sin(a2) * H * 0.33), 5, Color(0.1, 0.06, 0.04), 12)
				BoxArt.circle(c, ctr2 + Vector2(cos(a2) * W * 0.36, sin(a2) * H * 0.33), 4, cols[k], 12)
			_t(c, "Magick", Vector2(10, ctr2.y - 14), Vector2(W - 20, 18), 16, Color("ffe08a"), "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color("4a2410"))
			_t(c, "The Gatherening", Vector2(10, ctr2.y + 3), Vector2(W - 20, 10), 8, Color("ffe08a"), "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color("4a2410"))
			_t(c, "DECKMEISTER", Vector2(6, H - 16), Vector2(W - 12, 9), 7, Color("e8c890"), "cinzel", HORIZONTAL_ALIGNMENT_CENTER)
		"YUGI":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color("5a3418"))
			for k in 12:
				var a3 := TAU * k / 12.0
				var ctr3 := Vector2(W * 0.5, H * 0.5)
				BoxArt.poly(c, PackedVector2Array([ctr3, ctr3 + Vector2(cos(a3), sin(a3)) * 120, ctr3 + Vector2(cos(a3 + 0.26), sin(a3 + 0.26)) * 120]), Color("7a4a22"))
			var ov := PackedVector2Array()
			for i in 28:
				var a4 := TAU * i / 28.0
				ov.append(Vector2(W * 0.5, H * 0.5) + Vector2(cos(a4) * W * 0.3, sin(a4) * H * 0.34))
			BoxArt.poly(c, ov, Color(0.06, 0.04, 0.03))
			_t(c, "YU-GI-WHOA!", Vector2(4, H * 0.5 - 9), Vector2(W - 8, 18), 13, Color("ffcc33"), "bangers", HORIZONTAL_ALIGNMENT_CENTER, Color("8a2a10"))
			_t(c, "KONAMO", Vector2(4, H - 14), Vector2(W - 8, 9), 7, Color("e8c890"), "russo", HORIZONTAL_ALIGNMENT_CENTER)
		_:
			var acc := Color("#" + String(d.get("accent", "3fb3a8"))) if String(d.get("accent", "")) != "" else Color("3fb3a8")
			BoxArt.rect(c, Rect2(0, 0, W, H), acc.darkened(0.45))
			var g := _rng(String(d.get("game", "x")))
			for k in 10:
				_star(c, Vector2(g.randf() * W, g.randf() * H), g.randf_range(4, 10), Color(acc.lightened(0.3), 0.3))
			_frame(c, Rect2(5, 5, W - 10, H - 10), acc.lightened(0.3), 2.0)
			_t(c, String(d.get("game", "TCG")).to_upper(), Vector2(8, H * 0.5 - 20), Vector2(W - 16, 40), 12, Color.WHITE, "bungee", HORIZONTAL_ALIGNMENT_CENTER, acc.darkened(0.6), true)


# ================================================================ sealed product

static func _crimp(c: Control, y: float, h: float, col: Color) -> void:
	BoxArt.rect(c, Rect2(0, y, W, h), col)
	for k in int(W / 3.0):
		BoxArt.rect(c, Rect2(k * 3.0, y, 1, h), col.darkened(0.25))


static func _logo(c: Control, plat: String, d: Dictionary, r: Rect2) -> void:
	match plat:
		"CRIT":
			_t(c, "POCKET CRITTERS", r.position, r.size, 16, Color("ffd23f"), "lucky", HORIZONTAL_ALIGNMENT_CENTER, Color("2a3a8a"))
		"MAGI":
			_t(c, "Magick", r.position, r.size, 18, Color("ffe08a"), "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color("4a2410"))
		"YUGI":
			_t(c, "YU-GI-WHOA!", r.position, r.size, 16, Color("ffcc33"), "bangers", HORIZONTAL_ALIGNMENT_CENTER, Color("8a2a10"))
		_:
			_t(c, String(d.get("game", "TCG")).to_upper(), r.position, r.size, 14, Color.WHITE, "bungee", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.8))


static func _pack(c: Control, d: Dictionary) -> void:
	var plat := String(d["plat"])
	var pc: Color = Catalog.platform(plat)["color"]
	if String(d.get("accent", "")) != "":
		pc = Color("#" + String(d["accent"]))
	var tags: Array = d.get("tags", [])
	var g := _rng(String(d["id"]) + "pk")
	var hue := fmod(pc.h + g.randf_range(-0.2, 0.2) + 1.0, 1.0)
	var count := int(d.get("count", 11))
	var setname := String(d.get("set", ""))
	if tags.has("box"):
		CoverComp.gradient(c, Rect2(0, 0, W, H), Color.from_hsv(hue, 0.6, 0.85), Color.from_hsv(fmod(hue + 0.1, 1.0), 0.75, 0.35))
		BoxArt.rect(c, Rect2(0, 0, W, 22), Color(0.05, 0.05, 0.08, 0.85))
		_logo(c, plat, d, Rect2(6, 1, W - 12, 20))
		var subs := [String(d.get("subj", "dragon")), "sparkles", ["dragon#ffb04a", "fox#ff7a3d", "turtle#4f7cff", "hamster#ffd23f", "person_mage", "crossed_swords"][g.randi() % 6]]
		CoverComp.glow(c, Vector2(W * 0.5, H * 0.55), H * 0.4, Color(1, 0.95, 0.7))
		CoverComp.cg(c, g, subs[2], Vector2(W * 0.24, H * 0.82), H * 0.42, false)
		CoverComp.cg(c, g, subs[0], Vector2(W * 0.55, H * 0.86), H * 0.6, g.randf() < 0.5)
		_foil(c, Rect2(0, 22, W, H - 48), 0.12, String(d["id"]))
		BoxArt.rect(c, Rect2(0, H - 26, W, 26), Color(0.05, 0.05, 0.08, 0.88))
		_t(c, setname.to_upper(), Vector2(6, H - 26), Vector2(W * 0.6, 14), 12, Color.WHITE, "russo")
		var what := "ELITE TRAINER BOX" if String(d["name"]).contains("Elite") else ("PREMIUM COLLECTION" if String(d["name"]).contains("Collection") else "%d BOOSTER PACKS" % count)
		_t(c, what, Vector2(6, H - 13), Vector2(W * 0.6, 11), 9, Color("ffcc33"), "russo")
		BoxArt.rect(c, Rect2(W - 52, H - 22, 46, 18), Color(0.9, 0.15, 0.15))
		_t(c, "DISPLAY", Vector2(W - 52, H - 22), Vector2(46, 18), 10, Color.WHITE, "bungee", HORIZONTAL_ALIGNMENT_CENTER)
		return
	if tags.has("deck"):
		BoxArt.rect(c, Rect2(0, 0, W, H), Color.from_hsv(hue, 0.65, 0.4))
		CoverComp.gradient(c, Rect2(0, 18, W, H - 50), Color.from_hsv(hue, 0.4, 0.95), Color.from_hsv(hue, 0.7, 0.45))
		_logo(c, plat, d, Rect2(4, 0, W - 8, 18))
		CoverComp.glow(c, Vector2(W * 0.5, 70), 40, Color(1, 1, 0.8))
		CoverComp.cg(c, g, String(d.get("subj", "dragon")), Vector2(W * 0.5, H - 34), 76)
		BoxArt.rect(c, Rect2(0, H - 32, W, 32), Color(0.06, 0.06, 0.08))
		_t(c, "STARTER DECK", Vector2(4, H - 32), Vector2(W - 8, 16), 13, Color("ffcc33"), "bungee", HORIZONTAL_ALIGNMENT_CENTER)
		_t(c, "%d CARDS  |  READY TO PLAY" % count, Vector2(4, H - 15), Vector2(W - 8, 10), 7, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
		return
	# A foil booster pack: crimped top and bottom.
	CoverComp.gradient(c, Rect2(0, 0, W, H), Color.from_hsv(hue, 0.55, 0.95), Color.from_hsv(fmod(hue + 0.12, 1.0), 0.8, 0.4))
	_foil(c, Rect2(0, 0, W, H), 0.14, String(d["id"]))
	CoverComp.glow(c, Vector2(W * 0.5, H * 0.52), H * 0.36, Color(1, 1, 0.85))
	CoverComp.cg(c, g, String(d.get("subj", "dragon")), Vector2(W * 0.5, H * 0.8), H * 0.5, g.randf() < 0.5)
	BoxArt.rect(c, Rect2(4, 14, W - 8, 22), Color(0, 0, 0, 0.35))
	_logo(c, plat, d, Rect2(4, 14, W - 8, 22))
	_t(c, setname.to_upper(), Vector2(4, 36), Vector2(W - 8, 10), 8, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.7))
	BoxArt.rect(c, Rect2(0, H - 30, W, 16), Color(0.05, 0.05, 0.08, 0.8))
	_t(c, "BOOSTER PACK  |  %d CARDS" % count, Vector2(2, H - 30), Vector2(W - 4, 16), 8, Color("ffcc33"), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	var silver := Color(0.82, 0.84, 0.9)
	_crimp(c, 0, 9, silver)
	_crimp(c, H - 10, 10, silver)
	var v := String(d.get("variant", ""))
	if v == "1st Edition":
		BoxArt.circle(c, Vector2(W - 13, 52), 7, Color(0.05, 0.05, 0.05), 14)
		_t(c, "1ST", Vector2(W - 20, 46), Vector2(14, 12), 7, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
	elif v == "Resealed?":
		var tp := BoxArt.rect(c, Rect2(-4, 6, W + 8, 5), Color(0.95, 0.9, 0.6, 0.55))
		tp.rotation_degrees = 3.0


static func _pack_back(c: Control, d: Dictionary) -> void:
	var plat := String(d["plat"])
	var pc: Color = Catalog.platform(plat)["color"]
	BoxArt.rect(c, Rect2(0, 0, W, H), pc.darkened(0.6))
	_logo(c, plat, d, Rect2(4, 6, W - 8, 18))
	_t(c, "WHAT'S INSIDE", Vector2(6, 28), Vector2(W - 12, 10), 9, Color("ffcc33"), "russo")
	var lines := ["%d cards per pack" % int(d.get("count", 11)), "At least 1 rare", "Holo chance: who knows", "Set: " + String(d.get("set", "")),
		"Released %d" % int(d.get("year", 2000)), String(d.get("blurb", ""))]
	_t(c, "\n".join(lines), Vector2(6, 40), Vector2(W - 12, H - 74), 7, Color(0.92, 0.92, 0.94), "jersey", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0), true)
	var g := _rng(String(d["id"]) + "bar")
	BoxArt.rect(c, Rect2(W - 40, H - 22, 36, 18), Color.WHITE)
	var x := W - 38.0
	while x < W - 6:
		var bw := float(g.randi_range(1, 2))
		BoxArt.rect(c, Rect2(x, H - 20, bw, 12), Color.BLACK)
		x += bw + g.randi_range(1, 2)
	_t(c, "(c) %d %s" % [int(d.get("year", 2000)), String(d.get("pub", ""))], Vector2(4, H - 14), Vector2(W - 48, 10), 6, Color(0.75, 0.75, 0.8))


# ================================================================ coins

static func metal_cols(d: Dictionary) -> Array:
	var m := String(d.get("metal", "silver"))
	if METALS.has(m):
		return METALS[m]
	if m.contains("nickel"):
		return METALS["nickel"]
	if m.contains("silver"):
		return METALS["silver"]
	if m.contains("zinc") or m.contains("copper"):
		return METALS["copper"]
	return METALS["silver"]


## Letters set around a circle (the legend on a coin's rim).
static func _arc_text(c: Control, txt: String, ctr: Vector2, rad: float, from_deg: float, to_deg: float, fs: int, col: Color, inner := false) -> void:
	var n := txt.length()
	if n == 0:
		return
	var f := CoverComp.font("cinzel")
	for i in n:
		var ch := txt[i]
		if ch == " ":
			continue
		var t := 0.5 if n == 1 else float(i) / float(n - 1)
		var a := deg_to_rad(lerpf(from_deg, to_deg, t))
		var l := Label.new()
		l.text = ch
		l.add_theme_font_override("font", f)
		l.add_theme_font_size_override("font_size", fs)
		l.add_theme_color_override("font_color", col)
		l.size = Vector2(fs, fs * 1.3)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.pivot_offset = l.size * 0.5
		var p := ctr + Vector2(cos(a), sin(a)) * rad
		l.position = p - l.size * 0.5
		l.rotation = a + (PI / 2.0 if not inner else -PI / 2.0)
		c.add_child(l)


## Draws a polygon as raised metal: shadow below-right, highlight above-left, face.
static func _relief(c: Control, pts: PackedVector2Array, mc: Array, face_mix := 0.15) -> void:
	var sh := PackedVector2Array()
	var hi := PackedVector2Array()
	for p in pts:
		sh.append(p + Vector2(1.6, 1.8))
		hi.append(p + Vector2(-1.0, -1.1))
	BoxArt.poly(c, sh, Color(mc[2], 0.95))
	BoxArt.poly(c, hi, Color(mc[1], 0.9))
	BoxArt.poly(c, pts, (mc[0] as Color).lerp(mc[1], face_mix))


static func _xf(pts: Array, ctr: Vector2, s: float, flip := false) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		var q: Vector2 = p
		if flip:
			q.x = -q.x
		out.append(ctr + q * s)
	return out


static func _ellipse(ctr: Vector2, rx: float, ry: float, rot := 0.0, n := 14) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		out.append(ctr + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return out


static func _wreath(c: Control, ctr: Vector2, r: float, mc: Array, half := false) -> void:
	for side in [-1.0, 1.0]:
		for k in 9:
			var a := deg_to_rad(100.0 + k * 17.0) if side < 0 else deg_to_rad(80.0 - k * 17.0)
			if half and k > 6:
				continue
			var p := ctr + Vector2(cos(a), sin(a)) * r
			_relief(c, _ellipse(p, r * 0.16, r * 0.07, a + PI / 2.0 + side * 0.5, 8), mc)


static func _bust(c: Control, kind: String, ctr: Vector2, s: float, mc: Array) -> void:
	var flip := kind == "monarch" or kind == "lincoln" or kind == "modern"
	var head := _xf(PROFILE, ctr, s, flip)
	var fx := -1.0 if flip else 1.0
	# Behind the head: hair, feathers, cap backs.
	match kind:
		"indian":
			for k in 7:
				var a := deg_to_rad(-150.0 + k * 22.0)
				var base := ctr + Vector2(0.1 * fx, -0.45) * s
				var tip := base + Vector2(cos(a) * fx, sin(a)) * s * 0.85
				var nrm := Vector2(-sin(a) * fx, cos(a)) * s * 0.07
				_relief(c, PackedVector2Array([base + nrm, tip + nrm * 0.6, tip - nrm * 0.6, base - nrm]), mc, 0.3)
		"liberty", "liberty_flowing", "nymph":
			_relief(c, _ellipse(ctr + Vector2(0.42 * fx, -0.1) * s, s * 0.24, s * 0.2), mc)
			if kind != "liberty":
				for k in 4:
					var p0 := ctr + Vector2((0.3 + k * 0.06) * fx, 0.3) * s
					_relief(c, _ellipse(p0 + Vector2(0, k * 0.1 * s), s * 0.09, s * 0.22, 0.3 * fx), mc)
		"colonial":
			_relief(c, PackedVector2Array([ctr + Vector2(0.45 * fx, 0.1) * s, ctr + Vector2(0.7 * fx, 0.55) * s, ctr + Vector2(0.6 * fx, 0.62) * s, ctr + Vector2(0.38 * fx, 0.25) * s]), mc)
	_relief(c, head, mc, 0.25)
	# Eye and ear.
	BoxArt.circle(c, ctr + Vector2(-0.28 * fx, -0.15) * s, s * 0.035, mc[2], 6)
	BoxArt.poly(c, _ellipse(ctr + Vector2(0.12 * fx, -0.05) * s, s * 0.07, s * 0.11), (mc[2] as Color).lerp(mc[0], 0.5))
	# On top of the head.
	match kind:
		"liberty", "liberty_rays", "liberty_flowing":
			_relief(c, PackedVector2Array([ctr + Vector2(-0.38 * fx, -0.46) * s, ctr + Vector2(0.4 * fx, -0.3) * s, ctr + Vector2(0.38 * fx, -0.2) * s, ctr + Vector2(-0.4 * fx, -0.36) * s]), mc, 0.45)
			if kind == "liberty_rays":
				for k in 7:
					var a2 := deg_to_rad(-170.0 + k * 22.0)
					var b0 := ctr + Vector2(0.05 * fx, -0.35) * s
					_relief(c, PackedVector2Array([b0 + Vector2(cos(a2 + 0.1), sin(a2 + 0.1)) * s * 0.35, b0 + Vector2(cos(a2), sin(a2)) * s * 0.75, b0 + Vector2(cos(a2 - 0.1), sin(a2 - 0.1)) * s * 0.35]), mc, 0.4)
		"liberty_cap":
			_relief(c, PackedVector2Array([ctr + Vector2(-0.4 * fx, -0.38) * s, ctr + Vector2(-0.15 * fx, -0.85) * s, ctr + Vector2(0.35 * fx, -0.8) * s, ctr + Vector2(0.65 * fx, -0.45) * s, ctr + Vector2(0.5 * fx, -0.2) * s]), mc, 0.35)
		"liberty_wings":
			for k in 3:
				_relief(c, _ellipse(ctr + Vector2((0.15 + k * 0.08) * fx, -0.62 + k * 0.05) * s, s * 0.28, s * 0.07, -0.6 * fx), mc, 0.4)
		"indian":
			_relief(c, PackedVector2Array([ctr + Vector2(-0.4 * fx, -0.4) * s, ctr + Vector2(0.48 * fx, -0.28) * s, ctr + Vector2(0.48 * fx, -0.18) * s, ctr + Vector2(-0.42 * fx, -0.3) * s]), mc, 0.4)
		"lincoln":
			_relief(c, PackedVector2Array([ctr + Vector2(-0.46 * fx, 0.28) * s, ctr + Vector2(-0.4 * fx, 0.52) * s, ctr + Vector2(-0.1 * fx, 0.62) * s, ctr + Vector2(0.15 * fx, 0.3) * s, ctr + Vector2(0.05 * fx, 0.15) * s]), mc, 0.1)
			_relief(c, PackedVector2Array([ctr + Vector2(-0.3 * fx, -0.55) * s, ctr + Vector2(0.4 * fx, -0.45) * s, ctr + Vector2(0.5 * fx, -0.1) * s, ctr + Vector2(0.2 * fx, -0.35) * s]), mc, 0.1)
		"modern":
			_relief(c, PackedVector2Array([ctr + Vector2(-0.34 * fx, -0.52) * s, ctr + Vector2(0.0, -0.7) * s, ctr + Vector2(0.45 * fx, -0.45) * s, ctr + Vector2(0.4 * fx, -0.2) * s, ctr + Vector2(0.1 * fx, -0.42) * s]), mc, 0.1)
		"monarch":
			var cr := PackedVector2Array()
			var y0 := -0.55
			cr.append(ctr + Vector2(-0.35 * fx, y0) * s)
			for k in 5:
				var x := -0.35 + k * 0.17
				cr.append(ctr + Vector2((x + 0.085) * fx, y0 - 0.3) * s)
				cr.append(ctr + Vector2((x + 0.17) * fx, y0) * s)
			cr.append(ctr + Vector2(0.5 * fx, y0 + 0.12) * s)
			cr.append(ctr + Vector2(-0.35 * fx, y0 + 0.1) * s)
			_relief(c, cr, mc, 0.5)
			for k in 5:
				BoxArt.circle(c, ctr + Vector2((-0.265 + k * 0.17) * fx, y0 - 0.3) * s, s * 0.04, mc[1], 6)
			_relief(c, PackedVector2Array([ctr + Vector2(-0.3 * fx, 0.85) * s, ctr + Vector2(0.55 * fx, 0.7) * s, ctr + Vector2(0.65 * fx, 1.0) * s, ctr + Vector2(-0.35 * fx, 1.0) * s]), mc, 0.2)
		"emperor":
			for k in 7:
				var a3 := deg_to_rad(-160.0 + k * 22.0)
				var p3 := ctr + Vector2(0.05 * fx, -0.15) * s + Vector2(cos(a3), sin(a3)) * s * 0.5
				_relief(c, _ellipse(p3, s * 0.12, s * 0.05, a3 + PI / 2.0, 8), mc, 0.3)
		"athena", "helmet":
			_relief(c, PackedVector2Array([ctr + Vector2(-0.48 * fx, -0.3) * s, ctr + Vector2(-0.3 * fx, -0.72) * s, ctr + Vector2(0.2 * fx, -0.82) * s, ctr + Vector2(0.6 * fx, -0.5) * s, ctr + Vector2(0.55 * fx, 0.0) * s, ctr + Vector2(0.2 * fx, -0.25) * s]), mc, 0.3)
			if kind == "athena":
				for k in 6:
					_relief(c, _ellipse(ctr + Vector2((-0.15 + k * 0.12) * fx, -0.95 + absf(k - 2.5) * 0.04) * s, s * 0.07, s * 0.16, 0.4 * fx, 8), mc, 0.4)


static func _figure(c: Control, kind: String, ctr: Vector2, s: float, mc: Array) -> void:
	# A standing / striding / seated figure, as a raised silhouette.
	var head := ctr + Vector2(0, -0.62) * s
	if kind == "seated":
		_relief(c, PackedVector2Array([ctr + Vector2(-0.15, -0.5) * s, ctr + Vector2(0.15, -0.5) * s, ctr + Vector2(0.22, 0.05) * s, ctr + Vector2(0.55, 0.1) * s, ctr + Vector2(0.55, 0.3) * s, ctr + Vector2(0.15, 0.32) * s, ctr + Vector2(0.2, 0.8) * s, ctr + Vector2(-0.1, 0.8) * s, ctr + Vector2(-0.22, 0.1) * s]), mc)
		_relief(c, _ellipse(ctr + Vector2(-0.42, 0.25) * s, s * 0.2, s * 0.26), mc, 0.35)
		_relief(c, PackedVector2Array([ctr + Vector2(0.12, -0.45) * s, ctr + Vector2(0.18, -0.48) * s, ctr + Vector2(0.4, -0.95) * s, ctr + Vector2(0.36, -0.97) * s]), mc)
	else:
		_relief(c, PackedVector2Array([ctr + Vector2(-0.16, -0.5) * s, ctr + Vector2(0.16, -0.5) * s, ctr + Vector2(0.3, 0.0) * s, ctr + Vector2(0.5, 0.85) * s, ctr + Vector2(0.15, 0.85) * s, ctr + Vector2(0.0, 0.3) * s, ctr + Vector2(-0.3, 0.85) * s, ctr + Vector2(-0.6, 0.8) * s, ctr + Vector2(-0.25, 0.0) * s]), mc)
		_relief(c, PackedVector2Array([ctr + Vector2(-0.1, -0.45) * s, ctr + Vector2(-0.45, -0.95) * s, ctr + Vector2(-0.38, -1.0) * s, ctr + Vector2(0.0, -0.5) * s]), mc)
		BoxArt.circle(c, ctr + Vector2(-0.42, -1.02) * s, s * 0.08, mc[1], 8)
		_relief(c, PackedVector2Array([ctr + Vector2(0.12, -0.4) * s, ctr + Vector2(0.75, -0.1) * s, ctr + Vector2(0.9, 0.2) * s, ctr + Vector2(0.25, -0.05) * s]), mc, 0.3)
		if kind == "victory":
			_relief(c, _ellipse(ctr + Vector2(0.35, -0.55) * s, s * 0.35, s * 0.12, -0.7), mc, 0.4)
	_relief(c, _ellipse(head, s * 0.14, s * 0.16), mc, 0.3)


static func _emoji(c: Control, ref: String, ctr: Vector2, h: float, mc: Array, g: RandomNumberGenerator) -> void:
	CoverComp.cg(c, g, ref + "#" + (mc[0] as Color).lightened(0.15).to_html(false), ctr + Vector2(0, h * 0.5), h, false, 0.0, true)


static func _motif(c: Control, m: String, ctr: Vector2, s: float, mc: Array, d: Dictionary, g: RandomNumberGenerator) -> void:
	var emo := {"eagle": "eagle", "bison": "cow", "building": "classical_building", "bell": "bell", "horseman": "horse", "lion": "lion",
		"panda": "bear", "springbok": "horse", "kangaroo": "rabbit", "dragon": "dragon", "globe": "globe_showing_americas", "lily": "blossom",
		"rooster": "chicken", "canoe": "canoe", "goose": "bird", "fish": "fish", "clasp": "handshake", "chariot": "horse", "stag": "horse",
		"turtle": "turtle", "bee": "honeybee", "chalice": "amphora", "temple": "classical_building", "ship": "sailboat", "horse": "horse",
		"daggers": "dagger", "eye": "eye", "dioscuri": "horse"}
	match m:
		"liberty", "liberty_cap", "liberty_flowing", "liberty_rays", "liberty_wings", "indian", "lincoln", "colonial", "modern", "monarch", "emperor", "athena", "helmet", "nymph":
			_bust(c, m, ctr + Vector2(0, -s * 0.05), s * 0.82, mc)
		"striding", "seated", "victory", "god", "zeus", "christ":
			if m == "christ":
				BoxArt.circle(c, ctr + Vector2(0, -0.45) * s, s * 0.38, Color(mc[1], 0.6), 18)
			_figure(c, "seated" if m in ["seated", "zeus"] else ("victory" if m == "victory" else "striding"), ctr + Vector2(0, s * 0.1), s * 0.75, mc)
		"wreath":
			_wreath(c, ctr, s * 0.82, mc)
			_t(c, _denom_word(d), ctr - Vector2(s * 0.6, s * 0.3), Vector2(s * 1.2, s * 0.6), int(s * 0.32), (mc[2] as Color), "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color(mc[1], 0.6), true)
		"wheat":
			for side in [-1.0, 1.0]:
				for k in 7:
					var p := ctr + Vector2(side * s * (0.62 - k * 0.02), s * (0.7 - k * 0.2))
					_relief(c, _ellipse(p, s * 0.09, s * 0.05, side * 0.6, 8), mc)
			_t(c, "ONE\nCENT", ctr - Vector2(s * 0.45, s * 0.35), Vector2(s * 0.9, s * 0.7), int(s * 0.3), mc[2], "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color(mc[1], 0.6), true)
		"chain":
			for k in 15:
				var a := TAU * k / 15.0
				_relief(c, _ellipse(ctr + Vector2(cos(a), sin(a)) * s * 0.72, s * 0.13, s * 0.07, a + PI / 2.0, 10), mc, 0.4)
			_t(c, "ONE\nCENT", ctr - Vector2(s * 0.45, s * 0.35), Vector2(s * 0.9, s * 0.7), int(s * 0.28), mc[2], "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color(mc[1], 0.6), true)
		"denom":
			_wreath(c, ctr, s * 0.82, mc, true)
			var dn := String(d.get("denom", "1"))
			var big := "V" if dn == "5c" else dn.replace("c", "").replace("$", "")
			_t(c, big, ctr - Vector2(s * 0.6, s * 0.55), Vector2(s * 1.2, s * 0.9), int(s * 0.8), mc[2], "cinzel", HORIZONTAL_ALIGNMENT_CENTER, Color(mc[1], 0.7))
			_t(c, _denom_word(d), ctr + Vector2(-s * 0.6, s * 0.3), Vector2(s * 1.2, s * 0.3), int(s * 0.2), mc[2], "cinzel", HORIZONTAL_ALIGNMENT_CENTER)
		"fasces":
			_relief(c, PackedVector2Array([ctr + Vector2(-0.12, -0.75) * s, ctr + Vector2(0.12, -0.75) * s, ctr + Vector2(0.12, 0.75) * s, ctr + Vector2(-0.12, 0.75) * s]), mc, 0.3)
			for y in [-0.5, 0.0, 0.5]:
				_relief(c, PackedVector2Array([ctr + Vector2(-0.16, y - 0.04) * s, ctr + Vector2(0.16, y - 0.04) * s, ctr + Vector2(0.16, y + 0.04) * s, ctr + Vector2(-0.16, y + 0.04) * s]), mc, 0.5)
			_relief(c, PackedVector2Array([ctr + Vector2(0.1, -0.75) * s, ctr + Vector2(0.38, -0.95) * s, ctr + Vector2(0.38, -0.7) * s]), mc, 0.5)
			_wreath(c, ctr, s * 0.7, mc, true)
		"star":
			var sp := PackedVector2Array()
			for i in 10:
				var a2 := -PI / 2.0 + PI * i / 5.0
				sp.append(ctr + Vector2(cos(a2), sin(a2)) * s * (0.8 if i % 2 == 0 else 0.35))
			_relief(c, sp, mc, 0.3)
		"shield", "arms":
			var sh := PackedVector2Array([ctr + Vector2(-0.5, -0.55) * s, ctr + Vector2(0.5, -0.55) * s, ctr + Vector2(0.5, 0.1) * s, ctr + Vector2(0.0, 0.7) * s, ctr + Vector2(-0.5, 0.1) * s])
			_relief(c, sh, mc, 0.2)
			if m == "shield":
				for k in 6:
					BoxArt.rect(c, Rect2(ctr.x + (-0.42 + k * 0.16) * s, ctr.y - 0.25 * s, s * 0.07, s * 0.6 - absf(k - 2.5) * 0.08 * s), mc[2])
				BoxArt.rect(c, Rect2(ctr.x - 0.5 * s, ctr.y - 0.55 * s, s, s * 0.25), (mc[0] as Color).lerp(mc[1], 0.4))
			else:
				BoxArt.rect(c, Rect2(ctr.x - 0.02 * s, ctr.y - 0.55 * s, s * 0.04, s * 1.15), mc[2])
				BoxArt.rect(c, Rect2(ctr.x - 0.5 * s, ctr.y - 0.1 * s, s, s * 0.04), mc[2])
				_bust_crown(c, ctr + Vector2(0, -0.72) * s, s, mc)
		"cross":
			for r2 in [Rect2(-0.12, -0.75, 0.24, 1.5), Rect2(-0.75, -0.12, 1.5, 0.24)]:
				var rr: Rect2 = r2
				_relief(c, PackedVector2Array([ctr + rr.position * s, ctr + Vector2(rr.end.x, rr.position.y) * s, ctr + rr.end * s, ctr + Vector2(rr.position.x, rr.end.y) * s]), mc, 0.3)
			for q in [Vector2(-0.4, -0.4), Vector2(0.4, -0.4), Vector2(-0.4, 0.4), Vector2(0.4, 0.4)]:
				BoxArt.circle(c, ctr + q * s, s * 0.08, mc[1], 8)
		"tree":
			for k in 4:
				var y2 := -0.7 + k * 0.32
				_relief(c, PackedVector2Array([ctr + Vector2(0, y2 - 0.1) * s, ctr + Vector2(0.18 + k * 0.12, y2 + 0.3) * s, ctr + Vector2(-0.18 - k * 0.12, y2 + 0.3) * s]), mc, 0.2)
			_relief(c, PackedVector2Array([ctr + Vector2(-0.06, 0.55) * s, ctr + Vector2(0.06, 0.55) * s, ctr + Vector2(0.06, 0.85) * s, ctr + Vector2(-0.06, 0.85) * s]), mc)
		"sun":
			for k in 16:
				var a3 := TAU * k / 16.0
				_relief(c, PackedVector2Array([ctr + Vector2(cos(a3 - 0.12), sin(a3 - 0.12)) * s * 0.42, ctr + Vector2(cos(a3), sin(a3)) * s * 0.85, ctr + Vector2(cos(a3 + 0.12), sin(a3 + 0.12)) * s * 0.42]), mc, 0.3)
			_relief(c, _ellipse(ctr, s * 0.4, s * 0.4, 0, 20), mc, 0.35)
		"pillars":
			for x in [-0.55, 0.55]:
				_relief(c, PackedVector2Array([ctr + Vector2(x - 0.08, -0.6) * s, ctr + Vector2(x + 0.08, -0.6) * s, ctr + Vector2(x + 0.08, 0.7) * s, ctr + Vector2(x - 0.08, 0.7) * s]), mc, 0.3)
				_bust_crown(c, ctr + Vector2(x, -0.72) * s, s * 0.5, mc)
			_emoji(c, "globe_showing_americas", ctr, s * 0.7, mc, g)
		"owl":
			_relief(c, _ellipse(ctr + Vector2(0, 0.15) * s, s * 0.42, s * 0.6, 0, 18), mc, 0.15)
			for x in [-0.18, 0.18]:
				_relief(c, _ellipse(ctr + Vector2(x, -0.18) * s, s * 0.15, s * 0.15, 0, 12), mc, 0.6)
				BoxArt.circle(c, ctr + Vector2(x, -0.18) * s, s * 0.06, mc[2], 8)
			for x in [-0.32, 0.32]:
				_relief(c, PackedVector2Array([ctr + Vector2(x * 0.6, -0.42) * s, ctr + Vector2(x * 1.15, -0.72) * s, ctr + Vector2(x, -0.3) * s]), mc)
			_relief(c, _ellipse(ctr + Vector2(-0.62, -0.5) * s, s * 0.12, s * 0.05, 0.6, 8), mc)
			_relief(c, _ellipse(ctr + Vector2(-0.68, -0.32) * s, s * 0.12, s * 0.05, -0.4, 8), mc)
		"maple":
			var lf := PackedVector2Array()
			for i in 22:
				var a4 := -PI / 2.0 + TAU * i / 22.0
				var rr2 := 0.75 if i % 2 == 0 else 0.42
				if i in [9, 10, 11, 12, 13]:
					rr2 *= 0.75
				lf.append(ctr + Vector2(cos(a4), sin(a4)) * s * rr2)
			_relief(c, lf, mc, 0.25)
			BoxArt.rect(c, Rect2(ctr.x - s * 0.03, ctr.y, s * 0.06, s * 0.85), mc[2])
		"punch":
			var q := s * 0.62
			BoxArt.rect(c, Rect2(ctr.x - q * 0.5, ctr.y - q * 0.5, q, q), mc[2])
			for k in 4:
				BoxArt.rect(c, Rect2(ctr.x - q * 0.5 + (k % 2) * q * 0.52, ctr.y - q * 0.5 + (k / 2) * q * 0.52, q * 0.46, q * 0.46), (mc[0] as Color).darkened(0.2))
		"script":
			for row in 4:
				var y3 := ctr.y + (-0.45 + row * 0.3) * s
				var x3 := ctr.x - 0.55 * s
				while x3 < ctr.x + 0.5 * s:
					var wv := g.randf_range(0.05, 0.16) * s
					_relief(c, PackedVector2Array([Vector2(x3, y3), Vector2(x3 + wv, y3 - s * g.randf_range(0.0, 0.12)), Vector2(x3 + wv, y3 + s * 0.03), Vector2(x3, y3 + s * 0.04)]), mc, 0.4)
					x3 += wv + s * 0.05
		"cash":
			var hs := s * 0.28
			BoxArt.rect(c, Rect2(ctr.x - hs * 1.2, ctr.y - hs * 1.2, hs * 2.4, hs * 2.4), (mc[0] as Color).lerp(mc[1], 0.3))
			BoxArt.rect(c, Rect2(ctr.x - hs, ctr.y - hs, hs * 2, hs * 2), Color(0, 0, 0, 0))
			for q2 in [Vector2(0, -0.62), Vector2(0, 0.62), Vector2(-0.62, 0), Vector2(0.62, 0)]:
				var p2: Vector2 = ctr + q2 * s
				for k in 3:
					_relief(c, PackedVector2Array([p2 + Vector2(-0.14 + k * 0.1, -0.12) * s, p2 + Vector2(-0.1 + k * 0.1, -0.12) * s, p2 + Vector2(-0.1 + k * 0.1, 0.12) * s, p2 + Vector2(-0.14 + k * 0.1, 0.12) * s]), mc, 0.4)
				_relief(c, PackedVector2Array([p2 + Vector2(-0.16, -0.02) * s, p2 + Vector2(0.16, -0.02) * s, p2 + Vector2(0.16, 0.02) * s, p2 + Vector2(-0.16, 0.02) * s]), mc, 0.4)
		_:
			if emo.has(m):
				_emoji(c, String(emo[m]), ctr, s * 1.35, mc, g)
				if m == "daggers":
					_emoji(c, "dagger", ctr + Vector2(s * 0.3, 0), s * 1.2, mc, g)
					_relief(c, _ellipse(ctr + Vector2(0.1, -0.55) * s, s * 0.18, s * 0.14), mc, 0.4)
			else:
				_bust(c, "liberty", ctr, s * 0.82, mc)


static func _bust_crown(c: Control, at: Vector2, s: float, mc: Array) -> void:
	var cr := PackedVector2Array([at + Vector2(-0.22, 0.08) * s, at + Vector2(-0.22, -0.08) * s, at + Vector2(-0.11, 0.0) * s, at + Vector2(0, -0.14) * s,
		at + Vector2(0.11, 0.0) * s, at + Vector2(0.22, -0.08) * s, at + Vector2(0.22, 0.08) * s])
	_relief(c, cr, mc, 0.5)


static func _denom_word(d: Dictionary) -> String:
	var dn := String(d.get("denom", ""))
	var words := {"1c": "ONE CENT", "1/2c": "HALF CENT", "2c": "2 CENTS", "3c": "III", "5c": "FIVE CENTS", "10c": "ONE DIME", "20c": "20 CENTS",
		"25c": "QUAR. DOL.", "50c": "HALF DOL.", "$1": "ONE DOLLAR", "$2.50": "2 1/2 D.", "$3": "3 DOLLARS", "$4": "4 DOL.", "$5": "FIVE D.",
		"$10": "TEN D.", "$20": "TWENTY D.", "$50": "FIFTY D."}
	return String(words.get(dn, dn.to_upper()))


static func _year_text(y: int) -> String:
	return "%d BC" % -y if y < 0 else str(y)


static func _coin(c: Control, d: Dictionary, obverse: bool) -> void:
	var mc := metal_cols(d)
	var v := String(d.get("variant", ""))
	var key := String(d["id"]) + ("o" if obverse else "r")
	var g := _rng(key)
	var ancient := String(d.get("plat", "")) == "ANCT" and int(d.get("year", 0)) < 1100
	var ctr := Vector2(W * 0.5, H * 0.5)
	var r := minf(W, H) * 0.5
	# The square behind the disc (cropped to a circle on the model) is the field.
	var field: Color = (mc[0] as Color)
	if v == "Proof-Like" or v == "Deep Cameo" or "proof" in (d.get("tags", []) as Array):
		field = (mc[2] as Color).darkened(0.35)
	BoxArt.rect(c, Rect2(0, 0, W, H), (mc[2] as Color).darkened(0.2))
	if ancient:
		# Hand-struck flans are never quite round.
		var fl := PackedVector2Array()
		for i in 26:
			var a := TAU * i / 26.0
			fl.append(ctr + Vector2(cos(a), sin(a)) * r * g.randf_range(0.88, 0.99))
		BoxArt.poly(c, fl, (mc[0] as Color).darkened(0.08))
	else:
		BoxArt.circle(c, ctr, r, (mc[0] as Color).lerp(mc[1], 0.25), 40)
		BoxArt.circle(c, ctr, r * 0.9, (mc[2] as Color).lerp(mc[0], 0.5), 40)
	# Field: soft radial shading, lit from the top left.
	for k in 8:
		var t := float(k) / 7.0
		BoxArt.circle(c, ctr + Vector2(-r, -r) * 0.06 * t, r * 0.88 * (1.0 - t * 0.85), field.darkened(0.12).lerp(field.lightened(0.2), t), 36)
	if not ancient:
		for k in 48:
			var a5 := TAU * k / 48.0
			BoxArt.circle(c, ctr + Vector2(cos(a5), sin(a5)) * r * 0.85, r * 0.022, mc[1], 5)
	if v == "Rainbow Toned":
		for k in 5:
			BoxArt.circle(c, ctr, r * (0.98 - k * 0.04), Color.from_hsv(0.08 + k * 0.17, 0.7, 0.9, 0.18), 36)
	var off := Vector2.ZERO
	if v == "Off-Center":
		off = Vector2(r * 0.18, -r * 0.12)
	var dark := (mc[2] as Color).darkened(0.1)
	var motif := String(d.get("obv" if obverse else "rev", "liberty"))
	var s := r * 0.55
	_motif(c, motif, ctr + off + Vector2(0, -r * 0.02), s, mc, d, g)
	if v == "Deep Cameo":
		BoxArt.circle(c, ctr + off, s * 0.05, Color(1, 1, 1, 0.0))
	var leg := String(d.get("legend" if obverse else "legend2", ""))
	if leg.length() > 26:
		leg = leg.substr(0, 26)
	var span := clampf(leg.length() * 13.0, 40.0, 250.0)
	var fs := clampi(int(r * 0.17), 7, 16)
	if leg != "":
		_arc_text(c, leg, ctr + off, r * 0.72, -90.0 - span * 0.5, -90.0 + span * 0.5, fs, dark)
	if obverse:
		_t(c, _year_text(int(d.get("year", 1900))), ctr + off + Vector2(-r * 0.4, r * 0.56), Vector2(r * 0.8, r * 0.22), fs + 2, dark, "cinzel", HORIZONTAL_ALIGNMENT_CENTER)
		var mint := String(d.get("name", "")).get_slice(" ", 0)
		if mint.contains("-"):
			_t(c, mint.get_slice("-", 1), ctr + off + Vector2(r * 0.42, r * 0.5), Vector2(r * 0.2, r * 0.2), fs, dark, "cinzel", HORIZONTAL_ALIGNMENT_CENTER)
		if v == "Doubled Die":
			_t(c, _year_text(int(d.get("year", 1900))), ctr + off + Vector2(-r * 0.38, r * 0.54), Vector2(r * 0.8, r * 0.22), fs + 2, Color(dark, 0.5), "cinzel", HORIZONTAL_ALIGNMENT_CENTER)
			_arc_text(c, leg, ctr + off + Vector2(1.5, -1.5), r * 0.72, -90.0 - span * 0.5, -90.0 + span * 0.5, fs, Color(dark, 0.45))
	else:
		var low := _denom_word(d) if String(d.get("country", "")) == "United States" else String(d.get("denom", "")).to_upper()
		if motif != "wreath" and motif != "denom" and motif != "wheat" and motif != "chain":
			_t(c, low, ctr + off + Vector2(-r * 0.55, r * 0.55), Vector2(r * 1.1, r * 0.2), fs, dark, "cinzel", HORIZONTAL_ALIGNMENT_CENTER)
		if v == "Pattern":
			_t(c, "PATTERN", ctr + Vector2(-r * 0.4, -r * 0.08), Vector2(r * 0.8, r * 0.2), fs, Color(0.1, 0.5, 0.2, 0.8), "cinzel", HORIZONTAL_ALIGNMENT_CENTER)
	# Light catching the top-left of the rim.
	CoverComp.glow(c, ctr + Vector2(-r * 0.45, -r * 0.5), r * 0.35, Color(1, 1, 1, 0.5))
	if v == "Restrike":
		_t(c, "R", ctr + Vector2(r * 0.55, -r * 0.1), Vector2(r * 0.15, r * 0.15), fs - 2, dark, "cinzel")
