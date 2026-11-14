extends RefCounted
## Paints sports cards and wax (CCArt hands over kinds "scard" and "wax").
## No class_name (TV self-update): preload it.
##
##   Fronts come in three eras, like the real hobby:
##     vintage (before 1970): cream border, a hand-tinted portrait, a name
##       ribbon and a small team pennant.
##     wax era (1970-1992): white border, a coloured frame with the team in a
##       banner, a position badge and the maker's logo in a corner.
##     chrome era (1993+): full-bleed photo, chrome or prism stripes, a foil
##       name plate, the maker's logo top left.
##   The picture is the real player photo when tools/fetch_world_art.py found
##   one (def "photo"), or the real card scan for vintage cards (def "scan",
##   used as the whole front). Without either: a ball render and a silhouette.
##   Real backs (def "back", tools/fetch_sports_cards.py) when found, else
##   grey cardboard with the number, bio, stats table and the blurb.
##   Wax: a crimped wax-paper pack or a display box with the maker's logo.

const CCArt := preload("res://scripts/gfx/cc_art.gd")
const BALL := {"BASE": "baseball", "HOOP": "basketball", "GRID": "american_football", "PUCK": "ice_hockey", "FUTB": "soccer_ball"}

static var W := 107
static var H := 150


static func _t(c: Control, txt: String, pos: Vector2, size: Vector2, fs: int, col: Color, fname := "jersey", align := HORIZONTAL_ALIGNMENT_LEFT, outline := Color(0, 0, 0, 0)) -> Label:
	return CCArt._t(c, txt, pos, size, fs, col, fname, align, outline)


static func _rng(key: String) -> RandomNumberGenerator:
	var g := RandomNumberGenerator.new()
	g.seed = hash(key)
	return g


## The team colour pair for a card: seeded from the team name.
static func team_cols(d: Dictionary) -> Array:
	var g := _rng(String(d.get("team", d.get("id", ""))) + "team")
	var h1 := g.randf()
	var a := Color.from_hsv(h1, g.randf_range(0.55, 0.85), g.randf_range(0.55, 0.85))
	var b := Color.from_hsv(fmod(h1 + g.randf_range(0.35, 0.6), 1.0), g.randf_range(0.5, 0.9), g.randf_range(0.7, 0.95))
	return [a, b]


static func _tex(path: String) -> Texture2D:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return load(path)


## The picture window: the real photo, else a ball render and a silhouette.
static func _photo(c: Control, r: Rect2, d: Dictionary, tint := Color.WHITE) -> void:
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	var t := _tex(String(d.get("photo", "")))
	if t != null:
		var tr := TextureRect.new()
		tr.texture = t
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tr.size = r.size
		tr.modulate = tint
		tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		holder.add_child(tr)
		return
	var g := _rng(String(d.get("id", "")) + "ph")
	var cols := team_cols(d)
	CoverComp.gradient(holder, Rect2(Vector2.ZERO, r.size), Color(cols[1]).lightened(0.35), Color(cols[0]).darkened(0.2))
	BoxArt.rect(holder, Rect2(0, r.size.y * 0.72, r.size.x, r.size.y * 0.28), Color(0.3, 0.55, 0.3) if String(d["plat"]) != "PUCK" else Color(0.9, 0.95, 1.0))
	CoverComp.glow(holder, Vector2(r.size.x * 0.5, r.size.y * 0.45), r.size.y * 0.4, Color(1, 0.95, 0.8))
	# A player silhouette: head, shoulders, arm.
	var cx := r.size.x * g.randf_range(0.4, 0.6)
	var body := Color(cols[0]).darkened(0.35)
	BoxArt.circle(holder, Vector2(cx, r.size.y * 0.3), r.size.x * 0.11, body, 14)
	BoxArt.poly(holder, PackedVector2Array([Vector2(cx - r.size.x * 0.26, r.size.y), Vector2(cx - r.size.x * 0.2, r.size.y * 0.45),
		Vector2(cx + r.size.x * 0.2, r.size.y * 0.45), Vector2(cx + r.size.x * 0.26, r.size.y)]), body)
	BoxArt.poly(holder, PackedVector2Array([Vector2(cx + r.size.x * 0.16, r.size.y * 0.48), Vector2(cx + r.size.x * 0.42, r.size.y * 0.2),
		Vector2(cx + r.size.x * 0.47, r.size.y * 0.26), Vector2(cx + r.size.x * 0.22, r.size.y * 0.58)]), body)
	CoverComp.cg(holder, g, String(BALL.get(String(d["plat"]), "trophy")), Vector2(r.size.x * 0.78, r.size.y * 0.32), r.size.y * 0.24, false)


## A real scan (tools/fetch_sports_cards.py) filling the whole face.
static func _scan_face(c: Control, t: Texture2D) -> void:
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.92, 0.88, 0.78))
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.size = Vector2(W, H)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	c.add_child(tr)


static func paint_front(c: Control, d: Dictionary, w: int) -> void:
	W = w
	var year := int(d.get("year", 2000))
	var scan := _tex(String(d.get("scan", "")))
	if String(d.get("kind", "")) == "wax":
		if scan != null:
			_scan_face(c, scan)
		else:
			_wax(c, d)
		return
	if scan != null:
		_scan_face(c, scan)
	elif year < 1970:
		_vintage(c, d)
	elif year < 1993:
		_waxera(c, d)
	else:
		_chrome(c, d)
	_variant(c, d)


static func _vintage(c: Control, d: Dictionary) -> void:
	var cols := team_cols(d)
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.93, 0.89, 0.78))
	var win := Rect2(8, 8, W - 16, H - 36)
	BoxArt.rect(c, win.grow(1), Color(0.55, 0.5, 0.42))
	_photo(c, win, d, Color(1.0, 0.93, 0.82))
	# Hand-tinted look: a warm wash over the photo.
	BoxArt.rect(c, win, Color(0.95, 0.7, 0.45, 0.12))
	BoxArt.rect(c, Rect2(8, H - 26, W - 16, 18), cols[0])
	_t(c, String(d.get("player", d.get("name", ""))).to_upper(), Vector2(10, H - 26), Vector2(W - 20, 18), 13, Color(0.98, 0.95, 0.88), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	# A pennant with the team's city.
	BoxArt.poly(c, PackedVector2Array([Vector2(W - 34, 12), Vector2(W - 10, 18), Vector2(W - 34, 24)]), cols[1])
	_t(c, String(d.get("team", "")).split(" ")[0].left(4).to_upper(), Vector2(W - 34, 12), Vector2(18, 12), 7, Color.WHITE, "russo")


static func _waxera(c: Control, d: Dictionary) -> void:
	var cols := team_cols(d)
	var g := _rng(String(d.get("id", "")) + "we")
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.97, 0.97, 0.95))
	var win := Rect2(9, 9, W - 18, H - 44)
	BoxArt.rect(c, win.grow(3), cols[0])
	BoxArt.rect(c, win.grow(1), cols[1])
	_photo(c, win, d)
	# Team banner across the bottom of the photo, position badge, logo.
	BoxArt.rect(c, Rect2(6, H - 36, W - 12, 13), cols[0])
	_t(c, String(d.get("team", "")).to_upper(), Vector2(8, H - 36), Vector2(W - 16, 13), 10, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, String(d.get("player", d.get("name", ""))), Vector2(6, H - 22), Vector2(W - 34, 16), 14, Color(0.1, 0.1, 0.12), "bungee")
	BoxArt.circle(c, Vector2(W - 15, H - 15), 10, cols[1], 16)
	_t(c, String(d.get("pos", "")), Vector2(W - 25, H - 23), Vector2(20, 16), 9, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
	var corner := Vector2(12, 12) if g.randf() < 0.5 else Vector2(W - 32, 12)
	BoxArt.rect(c, Rect2(corner, Vector2(20, 9)), Color(0.85, 0.12, 0.12))
	_t(c, _brand(d), corner, Vector2(20, 9), 6, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)
	if (d.get("tags", []) as Array).has("rc"):
		_rc_badge(c, Vector2(W - 22, 20))


static func _chrome(c: Control, d: Dictionary) -> void:
	var cols := team_cols(d)
	var g := _rng(String(d.get("id", "")) + "ch")
	BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.12, 0.13, 0.16))
	_photo(c, Rect2(4, 4, W - 8, H - 8), d)
	# Chrome edges and prism stripes down one side.
	for k in 6:
		var a := 0.18 - k * 0.025
		BoxArt.rect(c, Rect2(4 + k * 2, 4, 2, H - 8), Color.from_hsv(fmod(g.randf() + k * 0.12, 1.0), 0.4, 1.0, a))
	CCArt._frame(c, Rect2(2, 2, W - 4, H - 4), Color(0.85, 0.88, 0.95), 2.0)
	BoxArt.poly(c, PackedVector2Array([Vector2(0, H - 30), Vector2(W, H - 40), Vector2(W, H), Vector2(0, H)]), Color(cols[0], 0.92))
	BoxArt.rect(c, Rect2(0, H - 30, W, 2), Color(cols[1]))
	_t(c, String(d.get("player", d.get("name", ""))).to_upper(), Vector2(6, H - 28), Vector2(W - 12, 15), 13, Color(1, 0.96, 0.8), "audio", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.6))
	_t(c, "%s  |  %s" % [String(d.get("team", "")).to_upper(), String(d.get("pos", ""))], Vector2(6, H - 14), Vector2(W - 12, 10), 8, Color.WHITE, "russo")
	_t(c, _brand(d), Vector2(8, 8), Vector2(40, 12), 10, Color.WHITE, "audio", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.6))
	if (d.get("tags", []) as Array).has("rc"):
		_rc_badge(c, Vector2(W - 20, 16))
	if (d.get("tags", []) as Array).has("auto"):
		# A sticker / on-card signature box.
		BoxArt.rect(c, Rect2(W * 0.18, H * 0.58, W * 0.64, 16), Color(0.97, 0.97, 0.95, 0.92))
		_t(c, String(d.get("player", "")), Vector2(W * 0.2, H * 0.58), Vector2(W * 0.6, 16), 13, Color(0.1, 0.2, 0.6), "marker", HORIZONTAL_ALIGNMENT_CENTER)


static func _rc_badge(c: Control, at: Vector2) -> void:
	CCArt._star(c, at, 10, Color(0.95, 0.15, 0.2), 6)
	_t(c, "RC", at - Vector2(7, 6), Vector2(14, 12), 8, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)


## The maker's short logo word ("TOPPZ", "FLEEB"...).
static func _brand(d: Dictionary) -> String:
	var pub := String(d.get("pub", "Toppz"))
	return pub.split(" ")[0].to_upper().left(7)


## Parallels, refractors and friends drawn on top of any front.
static func _variant(c: Control, d: Dictionary) -> void:
	var v := String(d.get("variant", "Standard"))
	match v:
		"Refractor":
			CCArt._foil(c, Rect2(0, 0, W, H), 0.16, String(d["id"]))
		"Gold Parallel":
			CCArt._frame(c, Rect2(0, 0, W, H), Color("e8b923"), 4.0)
			BoxArt.rect(c, Rect2(W - 32, H - 48, 28, 10), Color(0.1, 0.08, 0.02, 0.85))
			_t(c, "%02d/50" % (1 + absi(hash(String(d.get("uid", d["id"])))) % 50), Vector2(W - 32, H - 48), Vector2(28, 10), 8, Color("ffd23f"), "russo", HORIZONTAL_ALIGNMENT_CENTER)
		"Tiffany":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(1, 1, 1, 0.1))
		"On-Card Auto", "Patch Auto":
			if v == "Patch Auto":
				BoxArt.rect(c, Rect2(W * 0.3, H * 0.3, W * 0.4, H * 0.18), Color(0.75, 0.15, 0.2))
				for k in 4:
					BoxArt.rect(c, Rect2(W * 0.3, H * 0.3 + k * 6, W * 0.4, 2), Color(0.95, 0.95, 0.95))
			_t(c, String(d.get("player", "")), Vector2(W * 0.12, H * 0.5), Vector2(W * 0.76, 20), 16, Color(0.1, 0.15, 0.55), "marker", HORIZONTAL_ALIGNMENT_CENTER)
		"Printing Plate 1/1":
			BoxArt.rect(c, Rect2(0, 0, W, H), Color(0.0, 0.7, 0.8, 0.35))
			_t(c, "1/1", Vector2(W - 26, 6), Vector2(20, 12), 10, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER, Color(0, 0, 0, 0.8))
		"Short Print":
			_t(c, "SP", Vector2(6, H - 46), Vector2(16, 10), 8, Color("ffd23f"), "russo", HORIZONTAL_ALIGNMENT_LEFT, Color(0, 0, 0, 0.8))
		"O-Pee-Chee":
			_t(c, "IMPRIMÉ AU CANADA", Vector2(4, 0), Vector2(W - 8, 8), 6, Color(0.3, 0.3, 0.3), "russo", HORIZONTAL_ALIGNMENT_CENTER)
		"Misprint":
			BoxArt.rect(c, Rect2(0, H * 0.4, W, 5), Color(0.1, 0.1, 0.1, 0.8))
			_t(c, "ERROR", Vector2(4, H * 0.4 - 3), Vector2(30, 10), 8, Color(1, 0.3, 0.3), "russo")


static func paint_back(c: Control, d: Dictionary, w: int) -> void:
	W = w
	if String(d.get("kind", "")) == "wax":
		_wax_back(c, d)
		return
	# The real back of the card when one was found.
	var back := _tex(String(d.get("back", "")))
	if back != null:
		_scan_face(c, back)
		return
	var cols := team_cols(d)
	var year := int(d.get("year", 2000))
	var stock := Color(0.72, 0.7, 0.66) if year < 1993 else Color(0.92, 0.92, 0.94)
	BoxArt.rect(c, Rect2(0, 0, W, H), stock)
	BoxArt.rect(c, Rect2(5, 5, W - 10, H - 10), stock.lightened(0.1))
	BoxArt.rect(c, Rect2(5, 5, W - 10, 18), cols[0])
	_t(c, String(d.get("num", "#1")), Vector2(8, 5), Vector2(22, 18), 12, Color.WHITE, "russo")
	_t(c, String(d.get("player", "")).to_upper(), Vector2(30, 5), Vector2(W - 38, 18), 11, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_RIGHT)
	_t(c, "%s  •  %s" % [String(d.get("team", "")), String(d.get("pos", ""))], Vector2(8, 25), Vector2(W - 16, 10), 8, Color(0.15, 0.15, 0.18), "russo")
	# Stats table.
	var stats: Array = d.get("stats", [])
	var y := 40.0
	BoxArt.rect(c, Rect2(8, y, W - 16, 11), Color(cols[1], 0.85))
	_t(c, "YEAR", Vector2(10, y), Vector2(26, 11), 8, Color(0.08, 0.08, 0.1), "russo")
	for k in stats.size():
		_t(c, String(stats[k][0]), Vector2(38 + k * ((W - 46) / 3.0), y), Vector2((W - 46) / 3.0, 11), 8, Color(0.08, 0.08, 0.1), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	for row in 3:
		y += 11
		BoxArt.rect(c, Rect2(8, y, W - 16, 11), Color(1, 1, 1, 0.25 if row % 2 == 0 else 0.0))
		_t(c, str(year - 2 + row), Vector2(10, y), Vector2(26, 11), 8, Color(0.15, 0.15, 0.18), "jersey")
		for k in stats.size():
			var vtxt := String(stats[k][1])
			if vtxt.is_valid_int():
				vtxt = str(maxi(0, int(vtxt) - (2 - row) * 3))
			_t(c, vtxt, Vector2(38 + k * ((W - 46) / 3.0), y), Vector2((W - 46) / 3.0, 11), 8, Color(0.15, 0.15, 0.18), "jersey", HORIZONTAL_ALIGNMENT_CENTER)
	var bl := BoxArt.text(c, String(d.get("blurb", "")), Vector2(8, y + 16), Vector2(W - 16, H - y - 40), 9, Color(0.2, 0.2, 0.24), false)
	bl.clip_text = true
	BoxArt.rect(c, Rect2(5, H - 18, W - 10, 13), Color(0.1, 0.1, 0.12, 0.85))
	_t(c, "%s  ©%d  %s" % [_brand(d), year, String(d.get("set", "")).left(18)], Vector2(8, H - 18), Vector2(W - 16, 13), 7, Color.WHITE, "russo", HORIZONTAL_ALIGNMENT_CENTER)


static func _wax(c: Control, d: Dictionary) -> void:
	var pc: Color = Catalog.platform(String(d["plat"]))["color"]
	var g := _rng(String(d["id"]) + "wx")
	var tags: Array = d.get("tags", [])
	var year := int(d.get("year", 1990))
	var brand := _brand(d)
	if tags.has("box"):
		CoverComp.gradient(c, Rect2(0, 0, W, H), pc.lightened(0.2), pc.darkened(0.4))
		BoxArt.rect(c, Rect2(0, 0, W, 26), Color(0.95, 0.95, 0.92))
		_t(c, brand, Vector2(6, 2), Vector2(W - 12, 22), 22, Color(0.85, 0.12, 0.12), "bungee", HORIZONTAL_ALIGNMENT_CENTER)
		CoverComp.glow(c, Vector2(W * 0.5, H * 0.55), H * 0.38, Color(1, 0.95, 0.75))
		CoverComp.cg(c, g, String(BALL.get(String(d["plat"]), "trophy")), Vector2(W * 0.5, H * 0.84), H * 0.5, false)
		BoxArt.rect(c, Rect2(0, H - 30, W, 30), Color(0.05, 0.05, 0.08, 0.88))
		_t(c, "%d %s" % [year, String(Catalog.platform(String(d["plat"]))["name"]).to_upper()], Vector2(6, H - 30), Vector2(W * 0.66, 15), 12, Color.WHITE, "russo")
		_t(c, "%d WAX PACKS" % int(d.get("count", 24)), Vector2(6, H - 15), Vector2(W * 0.66, 12), 10, Color("ffcc33"), "russo")
		BoxArt.rect(c, Rect2(W - 56, H - 25, 50, 20), Color(0.9, 0.15, 0.15))
		_t(c, "HOBBY", Vector2(W - 56, H - 25), Vector2(50, 20), 11, Color.WHITE, "bungee", HORIZONTAL_ALIGNMENT_CENTER)
		return
	# A wax-paper pack: waxy sheen, folded ends, the logo and a stick of gum.
	var paper := pc.lightened(0.3) if year < 1990 else pc
	BoxArt.rect(c, Rect2(0, 0, W, H), paper)
	for k in 7:
		BoxArt.rect(c, Rect2(0, g.randf() * H, W, g.randf_range(2, 7)), Color(1, 1, 1, 0.07))
	BoxArt.rect(c, Rect2(6, 22, W - 12, 34), Color(0.97, 0.96, 0.9))
	_t(c, brand, Vector2(8, 22), Vector2(W - 16, 22), 20, Color(0.85, 0.12, 0.12), "bungee", HORIZONTAL_ALIGNMENT_CENTER)
	_t(c, "%d %s" % [year, String(Catalog.platform(String(d["plat"]))["name"]).to_upper()], Vector2(8, 43), Vector2(W - 16, 12), 9, Color(0.15, 0.15, 0.2), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	CoverComp.cg(c, g, String(BALL.get(String(d["plat"]), "trophy")), Vector2(W * 0.5, H - 32), H * 0.32, false)
	BoxArt.rect(c, Rect2(0, H - 30, W, 14), Color(0.05, 0.05, 0.08, 0.8))
	_t(c, "%d CARDS + 1 STICK OF GUM" % int(d.get("count", 12)), Vector2(2, H - 30), Vector2(W - 4, 14), 8, Color("ffcc33"), "russo", HORIZONTAL_ALIGNMENT_CENTER)
	CCArt._crimp(c, 0, 10, paper.darkened(0.15))
	CCArt._crimp(c, H - 10, 10, paper.darkened(0.15))
	if String(d.get("variant", "")) == "Resealed?":
		var tp := BoxArt.rect(c, Rect2(-4, 8, W + 8, 5), Color(0.95, 0.9, 0.6, 0.55))
		tp.rotation_degrees = 3.0


static func _wax_back(c: Control, d: Dictionary) -> void:
	var pc: Color = Catalog.platform(String(d["plat"]))["color"]
	BoxArt.rect(c, Rect2(0, 0, W, H), pc.darkened(0.5))
	_t(c, _brand(d), Vector2(6, 8), Vector2(W - 12, 20), 16, Color.WHITE, "bungee", HORIZONTAL_ALIGNMENT_CENTER)
	BoxArt.text(c, "COLLECT ALL %d! Look for rookie cards, short prints and the rare chrome parallels. Gum is not a food product." % (300 + absi(hash(String(d["id"]))) % 500), Vector2(8, 34), Vector2(W - 16, H - 70), 9, Color(0.95, 0.95, 0.9), false)
	BoxArt.rect(c, Rect2(8, H - 30, 40, 20), Color.WHITE)
	for k in 14:
		BoxArt.rect(c, Rect2(10 + k * 2.6, H - 28, 1.4 if k % 3 else 0.8, 14), Color.BLACK)
