class_name ItemModels
extends RefCounted
## Builds a low-poly 3D model for any catalog item: real cartridge models
## (assets/models/items) with a per-game label, jewel cases and discs, retail
## boxes, consoles, controllers and memorabilia. Box art (front + back) comes
## from Art (painted at runtime by BoxArt), per item and variant.
## Hardware picks its shape from the platform and name: colour editions tint
## the shell, and accessories map to archetypes (pad, gun, mouse, card...).
##
## build() returns a Node3D sitting on y=0, centred, front facing +Z, sized in
## metres (a cart is ~0.17 m tall) so a scene can drop it straight on a table.

const CART_BIG := "res://assets/models/items/gameCartridge1.glb"
const CART_SMALL := "res://assets/models/items/handheldCartridge1.glb"
const CART_BIG_TEX := "res://assets/models/items/gameCartridge1.png"
const CART_SMALL_TEX := "res://assets/models/items/handheldCartridge1.png"
## A real N64-style shell (115.5 x 76 x 18.6 mm, converted from a printable
## STL by tools/stl_to_glb.py): front-view UVs, front facing +Z, no texture.
const CART_F64 := "res://assets/models/items/n64Cartridge.glb"
const F64_LABEL := Rect2(0.205, 0.09, 0.59, 0.64)
## Where the sticker sits on each cart texture (UV).
const BIG_LABEL := Rect2(0.22, 0.05, 0.205, 0.42)
const SMALL_LABEL := Rect2(0.078, 0.312, 0.344, 0.297)
## Sticker width / height on the unscaled models (measured from their UVs),
## so box art goes on without stretching (Psx.label_mat letterboxes it).
const BIG_LABEL_ASPECT := 0.488
const SMALL_LABEL_ASPECT := 1.158
const F64_LABEL_ASPECT := 1.40

## Loose cart look per platform: [model, scale (thickness, height, width), body tint].
const CART := {
	"FES": ["big", Vector3(1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0)],
	"SFES": ["big", Vector3(1.0, 0.78, 1.22), Color(1.08, 1.08, 1.1)],
	"F64": ["big", Vector3(1.4, 0.74, 1.12), Color(0.42, 0.42, 0.46)],
	"GEN": ["big", Vector3(1.15, 0.92, 0.84), Color(0.2, 0.2, 0.22)],
	"A26": ["big", Vector3(1.25, 0.62, 0.78), Color(0.17, 0.15, 0.14)],
	"PBOY": ["small", Vector3(1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0)],
	"PBA": ["small", Vector3(1.0, 0.68, 1.2), Color(0.55, 0.5, 0.7)],
	"DUO": ["small", Vector3(0.7, 0.62, 0.72), Color(0.9, 0.9, 0.92)],
	"NEO": ["big", Vector3(1.6, 1.3, 1.45), Color(0.15, 0.14, 0.13)],
}

## Retail box size (w, h, d) for games, by platform.
const GAME_BOX := {
	"FES": Vector3(0.72, 1.0, 0.17), "SFES": Vector3(1.0, 0.72, 0.18),
	"F64": Vector3(1.0, 0.72, 0.2), "GEN": Vector3(0.72, 1.0, 0.14),
	"A26": Vector3(0.72, 0.95, 0.17), "PBOY": Vector3(0.62, 0.68, 0.13),
	"PST": Vector3(1.0, 0.9, 0.1), "DC": Vector3(1.0, 0.9, 0.1),
	"PST2": Vector3(0.75, 1.05, 0.1), "XBX": Vector3(0.75, 1.05, 0.1), "FCUBE": Vector3(0.72, 0.98, 0.1),
	"PSPK": Vector3(0.62, 1.0, 0.09), "SAT": Vector3(0.9, 1.1, 0.1), "NEO": Vector3(0.85, 1.15, 0.32),
	"PBA": Vector3(0.62, 0.68, 0.13), "DUO": Vector3(0.62, 0.58, 0.09),
}

## Plastic case colour per platform (cardboard for everything else).
const CASE_COLOR := {"PST": Color(0.16, 0.16, 0.18), "DC": Color(0.85, 0.85, 0.82), "PST2": Color(0.08, 0.08, 0.1),
	"XBX": Color(0.2, 0.5, 0.22), "FCUBE": Color(0.1, 0.1, 0.12), "PSPK": Color(0.75, 0.78, 0.82), "SAT": Color(0.08, 0.08, 0.09),
	"DUO": Color(0.85, 0.85, 0.88)}

## Edition colours read from the item name ("... Atomic Purple", "... Gold").
const NAME_COLORS := [
	["Atomic Purple", Color(0.5, 0.35, 0.75), 0.35], ["Clear", Color(0.75, 0.82, 0.85), 0.3], ["Jungle Green", Color(0.25, 0.65, 0.3), 0.25],
	["Fire Orange", Color(0.95, 0.45, 0.15), 0.25], ["Ice Blue", Color(0.5, 0.75, 0.95), 0.25], ["Grape", Color(0.45, 0.25, 0.6), 0.2],
	["Watermelon Red", Color(0.9, 0.25, 0.3), 0.2], ["Smoke Black", Color(0.2, 0.2, 0.22), 0.1], ["Pikapal", Color(0.98, 0.85, 0.2), 0.05],
	["Gold", Color(0.9, 0.72, 0.25), 0.2], ["Indigo", Color(0.3, 0.25, 0.65), 0.0], ["Jet Black", Color(0.08, 0.08, 0.09), 0.0],
	["Platinum", Color(0.8, 0.8, 0.84), 0.0], ["Spice Orange", Color(0.95, 0.55, 0.1), 0.0], ["Berry", Color(0.85, 0.2, 0.45), 0.1],
	["Dandelion", Color(0.98, 0.85, 0.2), 0.05], ["Kiwi", Color(0.6, 0.8, 0.2), 0.05], ["Teal", Color(0.2, 0.65, 0.7), 0.05],
	["Glacier", Color(0.7, 0.85, 0.95), 0.3], ["Fuchsia", Color(0.9, 0.3, 0.7), 0.05], ["Arctic", Color(0.92, 0.94, 0.96), 0.0],
	["Orange", Color(0.95, 0.5, 0.15), 0.0], ["Pearl Pink", Color(0.95, 0.75, 0.8), 0.05], ["Onyx", Color(0.12, 0.12, 0.14), 0.0],
	["Flame", Color(0.85, 0.2, 0.15), 0.1], ["Tribal", Color(0.2, 0.25, 0.6), 0.0], ["Ceramic White", Color(0.93, 0.93, 0.92), 0.0],
	["Satin Silver", Color(0.75, 0.76, 0.8), 0.05], ["Ocean Blue", Color(0.2, 0.4, 0.75), 0.0], ["Sakura Pink", Color(0.95, 0.7, 0.8), 0.0],
	["Pink", Color(0.95, 0.7, 0.8), 0.0], ["Piano Black", Color(0.06, 0.06, 0.07), 0.0], ["Ice Silver", Color(0.8, 0.82, 0.86), 0.0],
	["Felicia Blue", Color(0.45, 0.6, 0.85), 0.0], ["Lavender Purple", Color(0.7, 0.6, 0.85), 0.0], ["Crystal", Color(0.75, 0.85, 0.85), 0.35],
	["Lime Green", Color(0.55, 0.85, 0.2), 0.1], ["Mountain Doo", Color(0.4, 0.8, 0.2), 0.1], ["Hallo", Color(0.25, 0.45, 0.3), 0.0],
	["Skeleton", Color(0.7, 0.72, 0.75), 0.35], ["Hello Kitteh", Color(0.95, 0.7, 0.8), 0.0], ["Black", Color(0.1, 0.1, 0.11), 0.0],
	["White", Color(0.92, 0.92, 0.9), 0.0], ["Silver", Color(0.78, 0.8, 0.84), 0.0], ["Gray", Color(0.62, 0.62, 0.64), 0.0],
	["Woodie", Color(0.1, 0.09, 0.09), 0.0], ["Vadur", Color(0.06, 0.06, 0.06), 0.0], ["Famicom", Color(0.85, 0.2, 0.2), 0.0],
	["Funicom", Color(0.85, 0.2, 0.2), 0.0],
]

## Real-world-ish sizes (largest side, metres) so a scene reads at a glance.
const SIZE := {"game": 0.17, "game_box": 0.21, "console": 0.34, "console_box": 0.42, "acc": 0.15, "acc_box": 0.22, "misc": 0.24}
## Real-life largest dimension in metres, per platform, so a handheld cart sits
## tiny next to a big-box PC-style game and a console dwarfs both.
## Loose discs are the bare disc: 12 cm CD/DVD/GD-ROM, 8 cm mini disc, a 6.5 cm UMD shell.
const REAL_CART := {"FES": 0.133, "SFES": 0.135, "F64": 0.116, "PBOY": 0.065, "PBA": 0.057, "GEN": 0.125, "A26": 0.10, "NEO": 0.19, "DUO": 0.035, "ODD": 0.13}
const REAL_DISC := {"PST": 0.12, "PST2": 0.12, "SAT": 0.12, "DC": 0.12, "FCUBE": 0.08, "XBX": 0.12, "PSPK": 0.065}
const REAL_BOX := {"FES": 0.178, "SFES": 0.184, "F64": 0.178, "PBOY": 0.128, "PBA": 0.128, "GEN": 0.19, "A26": 0.185, "NEO": 0.30, "PST": 0.142, "PST2": 0.19, "SAT": 0.24, "DC": 0.142, "FCUBE": 0.19, "XBX": 0.19, "PSPK": 0.17, "DUO": 0.137, "ODD": 0.19}
const REAL_CONSOLE := {"FES": 0.26, "SFES": 0.24, "F64": 0.26, "FCUBE": 0.16, "PBOY": 0.148, "PBA": 0.145, "PSPK": 0.17, "GEN": 0.28, "SAT": 0.26, "DC": 0.19, "PST": 0.27, "PST2": 0.30, "XBX": 0.32, "NEO": 0.32, "A26": 0.34, "DUO": 0.14, "ODD": 0.30}


static func _real_size(key: String, plat: String, item: Dictionary) -> float:
	match key:
		"game":
			return float((REAL_DISC if is_disc(item) else REAL_CART).get(plat, SIZE["game"]))
		"game_box":
			return float(REAL_BOX.get(plat, SIZE["game_box"]))
		"console":
			return float(REAL_CONSOLE.get(plat, SIZE["console"]))
		"console_box":
			return float(REAL_CONSOLE.get(plat, SIZE["console"])) * 1.35
	return float(SIZE.get(key, 0.2))

static var _carts: Dictionary = {}


static func is_boxed(item: Dictionary) -> bool:
	return ["CIB", "Mint", "Sealed"].has(String(item.get("cond", "Loose")))


static func is_disc(item: Dictionary) -> bool:
	return (item.get("tags", []) as Array).has("disc")


## Shell colour for hardware: an edition colour from the name, or `fallback`.
static func name_color(item: Dictionary, fallback: Color) -> Array:
	var n := String(item.get("name", ""))
	for e in NAME_COLORS:
		if n.contains(String(e[0])):
			return [e[1], e[2]]
	if String(item.get("variant", "")) == "Limited Color":
		var hsh := absi(hash(String(item.get("id", ""))))
		return [Color.from_hsv(float(hsh % 360) / 360.0, 0.55, 0.85), 0.1]
	return [fallback, 0.0]


## item: a catalog def or a run item (needs id, plat, kind, tags; cond optional).
static func build(item: Dictionary, label: Texture2D = null, boxed: int = -1) -> Node3D:
	if label == null:
		label = Art.front(item)
	var box := is_boxed(item) if boxed < 0 else boxed == 1
	var plat := String(item["plat"])
	var kind := String(item["kind"])
	var col: Color = Catalog.platform(plat)["color"]
	var model := Node3D.new()
	var size_key := kind
	if kind == "game":
		if box:
			_retail_box(model, GAME_BOX.get(plat, Vector3(0.72, 1.0, 0.17)), label, col, plat, true, item)
			size_key = "game_box"
		elif is_disc(item):
			_disc(model, label, plat)
		else:
			_cart(model, plat, label)
	elif kind == "console":
		if box:
			_retail_box(model, Vector3(1.5, 1.0, 0.45), label, col, plat, false, item)
			size_key = "console_box"
		else:
			_console(model, item, plat, label)
	elif kind == "acc":
		if box:
			_retail_box(model, Vector3(0.9, 0.75, 0.24), label, col, plat, false, item)
			size_key = "acc_box"
		else:
			_accessory(model, item, plat, col)
	else:
		_misc(model, String(item["id"]), label, col)
	var cond := String(item.get("cond", ""))
	if cond == "Sealed":
		_seal(model)
	var holder := Node3D.new()
	holder.add_child(model)
	_fit(model, _real_size(size_key, plat, item))
	if cond == "Damaged":
		model.rotation_degrees.z += 6.0
		_tint(model, Color(0.7, 0.62, 0.55))
	return holder


## Scales so the largest side is `size` and sets the base on y=0.
static func _fit(model: Node3D, size: float) -> void:
	var b := Psx.aabb(model)
	if b.size == Vector3.ZERO:
		return
	var s := size / maxf(b.size.x, maxf(b.size.y, b.size.z))
	model.scale = Vector3.ONE * s
	model.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z) * s


static func _tint(n: Node, t: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		var mats: Array = [mi.material_override]
		for i in (mi.mesh.get_surface_count() if mi.mesh else 0):
			mats.append(mi.get_surface_override_material(i))
		for m in mats:
			if m is ShaderMaterial:
				var c: Color = (m as ShaderMaterial).get_shader_parameter("albedo")
				(m as ShaderMaterial).set_shader_parameter("albedo", c * t)
	for c in n.get_children():
		_tint(c, t)


# ---------------------------------------------------------------- games

static func _cart(model: Node3D, plat: String, label: Texture2D) -> void:
	if plat == "F64" and ResourceLoader.exists(CART_F64):
		if not _carts.has(CART_F64):
			_carts[CART_F64] = load(CART_F64)
		var n64: Node3D = (_carts[CART_F64] as PackedScene).instantiate()
		_apply(n64, Psx.label_mat(_white(), label, F64_LABEL, Color(0.36, 0.36, 0.39), F64_LABEL_ASPECT))
		model.add_child(n64)
		return
	var spec: Array = CART.get(plat, CART["FES"])
	var small: bool = spec[0] == "small"
	var path := CART_SMALL if small else CART_BIG
	if not _carts.has(path):
		_carts[path] = load(path)
	var ps: PackedScene = _carts[path]
	var inner: Node3D = ps.instantiate()
	var base: Texture2D = load(CART_SMALL_TEX if small else CART_BIG_TEX)
	var sc: Vector3 = spec[1]
	var aspect := (SMALL_LABEL_ASPECT if small else BIG_LABEL_ASPECT) * sc.z / sc.y
	var m := Psx.label_mat(base, label, SMALL_LABEL if small else BIG_LABEL, spec[2], aspect)
	_apply(inner, m)
	inner.scale = spec[1]
	inner.rotation_degrees.y = -90.0
	model.add_child(inner)


static var _white_tex: Texture2D
## True while Art renders an icon: the box back faces away, so skip painting it.
static var icon_build := false


## A picture material that fills a `surf`-shaped quad by cropping, never stretching.
static func _pic_mat(t: Texture2D, surf: float, emit := 0.0) -> ShaderMaterial:
	var m := Psx.mat(Color.WHITE, t, Vector2.ONE, emit)
	if t != null:
		m.set_shader_parameter("tex_fit", Psx.fit(float(t.get_width()) / maxf(1.0, t.get_height()), surf, true))
	return m


static func _white() -> Texture2D:
	if _white_tex == null:
		var img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		_white_tex = ImageTexture.create_from_image(img)
	return _white_tex


static func _apply(n: Node, m: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = m
	for c in n.get_children():
		_apply(c, m)


static func _disc(model: Node3D, label: Texture2D, plat: String = "") -> void:
	var r := 0.5
	if plat == "FCUBE":
		r = 0.36  # mini disc
	var silver := Psx.mat(Color(0.78, 0.8, 0.86), null, Vector2.ONE, 0.15)
	if plat == "PSPK":
		# UMD: a small disc in a clear shell.
		Psx.box(Vector3(0.7, 0.78, 0.06), Psx.mat(Color(0.7, 0.75, 0.8), null, Vector2.ONE, 0.1), Vector3(0, 0.39, 0), model)
		r = 0.3
	var d := Psx.cyl(r, 0.02, silver, Vector3(0, r, 0.03), model, 20)
	d.rotation_degrees.x = 90.0
	var lm := Psx.mat(Color.WHITE, label)
	lm.set_shader_parameter("circle", true)
	if label != null:
		# Round label: crop the box art to a square instead of squashing it.
		lm.set_shader_parameter("tex_fit", Psx.fit(float(label.get_width()) / maxf(1.0, label.get_height()), 1.0, true))
	Psx.quad(Vector2(r * 1.88, r * 1.88), lm, Vector3(0, r, 0.042), model)
	# The data side: mirror silver with the diffraction rainbow (black on PS1/PS2 discs).
	var back := Psx.quad(Vector2(r * 2.0, r * 2.0), disc_back_mat(plat), Vector3(0, r, 0.018), model)
	back.rotation_degrees.y = 180.0


const DISC_BACK := preload("res://assets/shaders/disc_back.gdshader")


static func disc_back_mat(plat: String = "") -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = DISC_BACK
	var black := plat == "PST" or plat == "PST2"
	m.set_shader_parameter("base", Color(0.12, 0.1, 0.16) if black else Color(0.8, 0.82, 0.88))
	m.set_shader_parameter("strength", 0.8 if black else 1.0)
	m.set_shader_parameter("snap", Psx.snap)
	m.set_shader_parameter("fog_color", Psx.fog_color)
	m.set_shader_parameter("fog_near", Psx.fog_near)
	m.set_shader_parameter("fog_far", Psx.fog_far)
	return m


## Cardboard (or plastic) retail box with the label as its front art.
static func _retail_box(model: Node3D, size: Vector3, label: Texture2D, col: Color, plat: String, game: bool, item: Dictionary = {}) -> void:
	var body: Material
	if game and CASE_COLOR.has(plat):
		body = Psx.mat(CASE_COLOR[plat])
	elif plat == "GEN" and game:
		body = Psx.mat(Color(0.1, 0.1, 0.11))
	elif plat == "FES" and game:
		body = Psx.mat(Color(0.08, 0.08, 0.08))
	else:
		body = Psx.mat(col.lerp(Color(0.75, 0.6, 0.4), 0.45), Psx.tex("cardboard002"))
	Psx.box(size, body, Vector3(0, size.y / 2.0, 0), model)
	var inset := 0.04 if (game and CASE_COLOR.has(plat)) else 0.0
	var surf := (size.x - inset * 2.0) / (size.y - inset * 2.0)
	var front := _pic_mat(label, surf)
	Psx.quad(Vector2(size.x - inset * 2.0, size.y - inset * 2.0), front, Vector3(0, size.y / 2.0, size.z / 2.0 + 0.002), model)
	if not item.is_empty() and not icon_build:
		var bq := Psx.quad(Vector2(size.x - inset * 2.0, size.y - inset * 2.0), _pic_mat(Art.back(item), surf), Vector3(0, size.y / 2.0, -size.z / 2.0 - 0.002), model)
		bq.rotation_degrees.y = 180.0
	# Side spine in the platform colour.
	var spine := Psx.mat(col.darkened(0.2))
	var sp := Psx.quad(Vector2(size.z, size.y), spine, Vector3(size.x / 2.0 + 0.002, size.y / 2.0, 0), model)
	sp.rotation_degrees.y = 90.0


static func _seal(model: Node3D) -> void:
	var b := Psx.aabb(model)
	var gold := Psx.mat(Color(1.0, 0.82, 0.25), null, Vector2.ONE, 0.6)
	var s := Psx.cyl(0.08 * b.size.y + 0.02, 0.01, gold, Vector3(b.end.x - 0.14, b.end.y - 0.14, b.end.z + 0.006), model, 10)
	s.rotation_degrees.x = 90.0


# ---------------------------------------------------------------- consoles

static func _console(model: Node3D, item: Dictionary, plat: String, label: Texture2D) -> void:
	var id := String(item["id"])
	var nm := String(item.get("name", ""))
	var dark := Psx.mat(Color(0.08, 0.08, 0.09))
	if _special_hardware(model, item, plat, label):
		return
	match plat:
		"FES":
			var fc: Array = name_color(item, Color(0.72, 0.72, 0.74))
			if nm.contains("Funicom"):
				_famicom(model, nm)
				return
			var g := Psx.mat(fc[0], null, Vector2.ONE, fc[1])
			Psx.box(Vector3(1.3, 0.36, 1.0), g, Vector3(0, 0.18, 0), model)
			Psx.box(Vector3(1.32, 0.05, 1.02), dark, Vector3(0, 0.2, 0), model)
			Psx.box(Vector3(0.8, 0.02, 0.5), Psx.mat(Color(0.62, 0.62, 0.64)), Vector3(0, 0.37, 0.1), model)
			Psx.box(Vector3(0.12, 0.06, 0.02), Psx.mat(Color(0.8, 0.15, 0.12), null, Vector2.ONE, 0.6), Vector3(-0.45, 0.1, 0.51), model)
			for x in [-0.15, 0.1]:
				Psx.box(Vector3(0.14, 0.08, 0.02), dark, Vector3(x, 0.1, 0.51), model)
		"SFES":
			var g := Psx.mat(name_color(item, Color(0.78, 0.78, 0.82))[0])
			Psx.box(Vector3(1.2, 0.3, 0.95), g, Vector3(0, 0.15, 0), model)
			Psx.box(Vector3(0.7, 0.08, 0.45), Psx.mat(Color(0.68, 0.68, 0.72)), Vector3(0, 0.34, -0.05), model)
			Psx.box(Vector3(0.5, 0.03, 0.08), dark, Vector3(0, 0.39, -0.05), model)
			var purple := Psx.mat(Color(0.45, 0.32, 0.7))
			Psx.box(Vector3(0.14, 0.05, 0.1), purple, Vector3(-0.35, 0.32, 0.3), model)
			Psx.box(Vector3(0.14, 0.05, 0.1), purple, Vector3(0.35, 0.32, 0.3), model)
		"F64":
			var nc: Array = name_color(item, Color(0.2, 0.2, 0.22))
			if id == "f64_jungle":
				nc = [Color(0.25, 0.65, 0.3), 0.25]
			var g := Psx.mat(nc[0], null, Vector2.ONE, nc[1])
			Psx.box(Vector3(1.3, 0.28, 1.0), g, Vector3(0, 0.14, 0), model)
			Psx.box(Vector3(0.62, 0.16, 0.6), g, Vector3(0, 0.36, -0.05), model)
			Psx.box(Vector3(0.4, 0.03, 0.08), dark, Vector3(0, 0.45, -0.05), model)
			for x in [-0.39, -0.13, 0.13, 0.39]:
				Psx.box(Vector3(0.12, 0.08, 0.02), dark, Vector3(x, 0.12, 0.51), model)
		"PBOY":
			var pc: Array = name_color(item, Color(0.75, 0.75, 0.72))
			if id == "pboy_gold":
				pc = [Color(0.9, 0.72, 0.25), 0.15]
			var g := Psx.mat(pc[0], null, Vector2.ONE, pc[1])
			var small := nm.contains("Pocket") or nm.contains("Light") or nm.contains("Color")
			if small:
				model.scale = Vector3(0.85, 0.85, 0.85)
			Psx.box(Vector3(0.6, 1.0, 0.16), g, Vector3(0, 0.5, 0), model)
			Psx.box(Vector3(0.48, 0.42, 0.01), Psx.mat(Color(0.25, 0.26, 0.3)), Vector3(0, 0.7, 0.085), model)
			Psx.box(Vector3(0.32, 0.28, 0.01), Psx.mat(Color(0.55, 0.65, 0.25), null, Vector2.ONE, 0.5), Vector3(0, 0.7, 0.092), model)
			Psx.box(Vector3(0.16, 0.05, 0.03), dark, Vector3(-0.13, 0.3, 0.09), model)
			Psx.box(Vector3(0.05, 0.16, 0.03), dark, Vector3(-0.13, 0.3, 0.09), model)
			var red := Psx.mat(Color(0.6, 0.12, 0.3))
			for p in [Vector3(0.1, 0.28, 0.09), Vector3(0.2, 0.33, 0.09)]:
				var b := Psx.cyl(0.045, 0.03, red, p, model, 8)
				b.rotation_degrees.x = 90.0
		"GEN":
			if nm.contains("Nomadd"):
				_handheld_wide(model, Color(0.12, 0.12, 0.13), 0.0, 1.3)
				return
			var g := Psx.mat(name_color(item, Color(0.1, 0.1, 0.11))[0])
			if nm.contains("CD") or nm.contains("33X"):
				Psx.box(Vector3(1.25, 0.3, 0.95), g, Vector3(0, 0.15, 0), model)
				Psx.cyl(0.3, 0.04, Psx.mat(Color(0.2, 0.2, 0.22)), Vector3(0, 0.32, 0), model, 16)
				return
			Psx.box(Vector3(1.25, 0.26, 0.95), g, Vector3(0, 0.13, 0), model)
			Psx.cyl(0.36, 0.06, Psx.mat(Color(0.16, 0.16, 0.18)), Vector3(0.0, 0.29, -0.05), model, 16)
			Psx.box(Vector3(0.45, 0.04, 0.06), dark, Vector3(0, 0.33, -0.05), model)
			Psx.box(Vector3(0.6, 0.02, 0.02), Psx.mat(Color(0.85, 0.15, 0.15), null, Vector2.ONE, 0.5), Vector3(0, 0.2, 0.48), model)
		"DC":
			var dcol: Array = name_color(item, Color(0.88, 0.88, 0.86))
			var g := Psx.mat(dcol[0], null, Vector2.ONE, dcol[1])
			Psx.box(Vector3(1.1, 0.34, 1.1), g, Vector3(0, 0.17, 0), model)
			Psx.cyl(0.38, 0.04, Psx.mat(Color(0.8, 0.8, 0.78)), Vector3(0, 0.36, -0.05), model, 18)
			Psx.cyl(0.08, 0.02, Psx.mat(Color(0.95, 0.5, 0.15), null, Vector2.ONE, 0.6), Vector3(0, 0.39, -0.05), model, 10)
		"PST":
			if nm.contains("PocketStatia"):
				_handheld_tall(model, Color(0.75, 0.76, 0.8), 0.0, 0.5)
				return
			var pcol := Color(0.7, 0.71, 0.74)
			if nm.contains("Yaroza") or nm.contains("Debugg"):
				pcol = Color(0.1, 0.1, 0.12) if nm.contains("Yaroza") else Color(0.3, 0.45, 0.65)
			var g := Psx.mat(pcol)
			Psx.box(Vector3(1.3, 0.28, 0.95), g, Vector3(0, 0.14, 0), model)
			Psx.cyl(0.36, 0.04, Psx.mat(Color(0.64, 0.65, 0.68)), Vector3(0.12, 0.3, -0.03), model, 18)
			for p in [Vector3(-0.45, 0.3, 0.2), Vector3(-0.45, 0.3, -0.05)]:
				Psx.cyl(0.06, 0.04, Psx.mat(Color(0.5, 0.52, 0.56)), p, model, 8)
		"A26":
			Psx.box(Vector3(1.3, 0.26, 0.9), Psx.mat(Color(0.1, 0.09, 0.09)), Vector3(0, 0.13, 0), model)
			if not (nm.contains("Vadur") or nm.contains("Jr.")):
				Psx.box(Vector3(1.3, 0.14, 0.04), Psx.mat(Color(1, 1, 1), Psx.tex("wood092")), Vector3(0, 0.12, 0.46), model)
			Psx.box(Vector3(0.8, 0.12, 0.5), Psx.mat(Color(0.12, 0.11, 0.1)), Vector3(0, 0.3, -0.1), model)
			for x in [-0.5, -0.3, 0.3, 0.5]:
				Psx.cyl(0.04, 0.1, Psx.mat(Color(0.7, 0.7, 0.7)), Vector3(x, 0.3, 0.25), model, 6)
		"FCUBE":
			var cc: Array = name_color(item, Color(0.3, 0.25, 0.65))
			var g := Psx.mat(cc[0], null, Vector2.ONE, cc[1])
			Psx.box(Vector3(0.9, 0.75, 0.9), g, Vector3(0, 0.375, 0), model)
			Psx.box(Vector3(0.5, 0.06, 0.1), Psx.mat(cc[0].darkened(0.3)), Vector3(0, 0.82, -0.3), model)
			Psx.cyl(0.25, 0.02, Psx.mat(cc[0].lightened(0.15)), Vector3(0, 0.76, 0.05), model, 16)
			for x in [-0.3, -0.1, 0.1, 0.3]:
				Psx.box(Vector3(0.12, 0.08, 0.02), dark, Vector3(x, 0.12, 0.46), model)
		"PBA":
			var ac: Array = name_color(item, Color(0.35, 0.3, 0.65))
			if nm.contains("SP"):
				_clamshell(model, ac[0], ac[1], false)
			elif nm.contains("Micro"):
				_handheld_wide(model, ac[0], ac[1], 0.8)
			else:
				_handheld_wide(model, ac[0], ac[1], 1.2)
		"DUO":
			_clamshell(model, name_color(item, Color(0.9, 0.9, 0.92))[0], 0.05, true)
		"PST2":
			var sc: Array = name_color(item, Color(0.08, 0.08, 0.09))
			var g := Psx.mat(sc[0], null, Vector2.ONE, sc[1])
			if nm.contains("Slimline"):
				Psx.box(Vector3(1.0, 0.12, 0.65), g, Vector3(0, 0.06, 0), model)
				Psx.cyl(0.22, 0.02, Psx.mat(sc[0].lightened(0.1)), Vector3(0, 0.13, 0), model, 14)
				return
			Psx.box(Vector3(1.2, 0.3, 0.9), g, Vector3(0, 0.15, 0), model)
			for k in 5:
				Psx.box(Vector3(1.22, 0.015, 0.92), Psx.mat(sc[0].lightened(0.12)), Vector3(0, 0.05 + k * 0.05, 0), model)
			Psx.box(Vector3(0.12, 0.05, 0.02), Psx.mat(Color(0.2, 0.4, 0.9), null, Vector2.ONE, 0.8), Vector3(0.45, 0.22, 0.46), model)
		"PSPK":
			var pc2: Array = name_color(item, Color(0.06, 0.06, 0.07))
			_handheld_wide(model, pc2[0], pc2[1], 1.5)
		"XBX":
			if nm.contains("361"):
				var w := Psx.mat(Color(0.9, 0.9, 0.9) if not nm.contains("Elite") else Color(0.08, 0.08, 0.09))
				Psx.box(Vector3(1.0, 0.3, 0.85), w, Vector3(0, 0.15, 0), model)
				Psx.box(Vector3(0.95, 0.05, 0.8), Psx.mat(Color(0.75, 0.75, 0.78)), Vector3(0, 0.32, 0), model)
				Psx.cyl(0.06, 0.02, Psx.mat(Color(0.3, 0.9, 0.3), null, Vector2.ONE, 1.5), Vector3(0.3, 0.2, 0.43), model, 10).rotation_degrees.x = 90.0
				return
			var xc: Array = name_color(item, Color(0.1, 0.1, 0.11))
			var g := Psx.mat(xc[0], null, Vector2.ONE, xc[1])
			Psx.box(Vector3(1.3, 0.42, 1.05), g, Vector3(0, 0.21, 0), model)
			Psx.box(Vector3(0.95, 0.06, 0.8), Psx.mat(xc[0].lightened(0.08)), Vector3(0, 0.45, 0), model)
			var jewel := Psx.cyl(0.14, 0.05, Psx.mat(Color(0.3, 0.85, 0.3), null, Vector2.ONE, 1.2), Vector3(0, 0.48, 0.1), model, 12)
			jewel.scale = Vector3(1, 1, 1)
		"SAT":
			var tc: Array = name_color(item, Color(0.15, 0.15, 0.17))
			var g := Psx.mat(tc[0], null, Vector2.ONE, tc[1])
			Psx.box(Vector3(1.3, 0.3, 0.95), g, Vector3(0, 0.15, 0), model)
			Psx.cyl(0.32, 0.05, Psx.mat(tc[0].lightened(0.12)), Vector3(-0.2, 0.33, -0.02), model, 18)
			Psx.box(Vector3(0.3, 0.04, 0.1), Psx.mat(Color(0.4, 0.4, 0.45)), Vector3(0.38, 0.32, 0.25), model)
		"NEO":
			if nm.contains("Cabinet"):
				_cabinet(model, Color(0.85, 0.2, 0.15))
				return
			if nm.contains("Slot"):
				Psx.box(Vector3(1.4, 0.35, 0.9), Psx.mat(Color(0.2, 0.45, 0.25)), Vector3(0, 0.175, 0), model)
				var slots := 1 if nm.contains("1-") else (4 if nm.contains("4-") else 6)
				for k in slots:
					Psx.box(Vector3(0.14, 0.05, 0.7), Psx.mat(Color(0.1, 0.1, 0.1)), Vector3(-0.55 + k * 0.22, 0.37, 0), model)
				return
			Psx.box(Vector3(1.5, 0.28, 0.95), Psx.mat(Color(0.08, 0.08, 0.08)), Vector3(0, 0.14, 0), model)
			Psx.box(Vector3(0.8, 0.04, 0.12), Psx.mat(Color(0.9, 0.7, 0.2), null, Vector2.ONE, 0.6), Vector3(0, 0.3, -0.1), model)
		_:
			_misc(model, id, label, Catalog.platform(plat)["color"])


## Prototype / oddball hardware and big set-ups, by name.
static func _special_hardware(model: Node3D, item: Dictionary, plat: String, label: Texture2D) -> bool:
	var nm := String(item.get("name", ""))
	var col: Color = Catalog.platform(plat)["color"]
	if nm.contains("Cabinet"):
		_cabinet(model, col)
		return true
	if nm.contains("Disk System") or nm.contains("64DeeDee") or nm.contains("Satelloview (") or nm.contains("Player") or nm.contains("Super PocketBoy"):
		Psx.box(Vector3(1.1, 0.3, 0.9), Psx.mat(col.darkened(0.25)), Vector3(0, 0.15, 0), model)
		Psx.box(Vector3(0.6, 0.03, 0.1), Psx.mat(Color(0.06, 0.06, 0.06)), Vector3(0, 0.25, 0.46), model)
		return true
	if plat == "ODD":
		var dark := nm.contains("Jagwire") or nm.contains("Panthar")
		var c := Color(0.08, 0.08, 0.09) if dark else Color(0.2, 0.2, 0.22)
		Psx.box(Vector3(1.3, 0.35, 1.0), Psx.mat(c), Vector3(0, 0.175, 0), model)
		Psx.cyl(0.3, 0.05, Psx.mat(c.lightened(0.15)), Vector3(0, 0.37, 0), model, 14)
		Psx.box(Vector3(0.5, 0.05, 0.02), Psx.mat(Color(0.9, 0.2, 0.2), null, Vector2.ONE, 0.6), Vector3(0, 0.2, 0.51), model)
		return true
	if nm.contains("PlayStatia (SFES-CD") or nm.contains("Neptune"):
		Psx.box(Vector3(1.3, 0.32, 1.0), Psx.mat(Color(0.75, 0.75, 0.78) if not nm.contains("Neptune") else Color(0.1, 0.1, 0.11)), Vector3(0, 0.16, 0), model)
		Psx.cyl(0.3, 0.04, Psx.mat(Color(0.6, 0.6, 0.65)), Vector3(0.2, 0.34, 0), model, 16)
		Psx.box(Vector3(0.45, 0.04, 0.1), Psx.mat(Color(0.1, 0.1, 0.1)), Vector3(-0.35, 0.33, 0.1), model)
		return true
	return false


static func _famicom(model: Node3D, nm: String) -> void:
	var white := Psx.mat(Color(0.88, 0.85, 0.8))
	var red := Psx.mat(Color(0.75, 0.15, 0.15))
	Psx.box(Vector3(1.2, 0.3, 0.9), white, Vector3(0, 0.15, 0), model)
	Psx.box(Vector3(1.2, 0.08, 0.9), red, Vector3(0, 0.04, 0), model)
	Psx.box(Vector3(0.5, 0.06, 0.12), Psx.mat(Color(0.1, 0.1, 0.1)), Vector3(0, 0.33, -0.1), model)
	for x in [-0.75, 0.75]:
		Psx.box(Vector3(0.28, 0.06, 0.12), red, Vector3(x, 0.03, 0.3), model)


static func _screen(model: Node3D, pos: Vector3, size: Vector2) -> void:
	Psx.box(Vector3(size.x + 0.08, size.y + 0.08, 0.01), Psx.mat(Color(0.12, 0.12, 0.15)), pos, model)
	Psx.box(Vector3(size.x, size.y, 0.01), Psx.mat(Color(0.45, 0.6, 0.75), null, Vector2.ONE, 0.6), pos + Vector3(0, 0, 0.006), model)


## Landscape handheld (PocketBoy Advance, PSPocket, Nomadd): wide body, screen, pads.
static func _handheld_wide(model: Node3D, col: Color, emit: float, w: float) -> void:
	var g := Psx.mat(col, null, Vector2.ONE, emit)
	var cap := CapsuleMesh.new()
	cap.radius = 0.32
	cap.height = w
	cap.radial_segments = 12
	var body := Psx.mesh(cap, g, Vector3(0, 0.33, 0), model)
	body.rotation_degrees.z = 90.0
	body.scale = Vector3(1, 1, 0.3)
	_screen(model, Vector3(0, 0.34, 0.1), Vector2(w * 0.42, 0.34))
	var dark := Psx.mat(Color(0.1, 0.1, 0.11))
	Psx.box(Vector3(0.12, 0.04, 0.03), dark, Vector3(-w * 0.36, 0.34, 0.1), model)
	Psx.box(Vector3(0.04, 0.12, 0.03), dark, Vector3(-w * 0.36, 0.34, 0.1), model)
	for k in 2:
		var b := Psx.cyl(0.035, 0.03, Psx.mat(Color(0.25, 0.25, 0.3)), Vector3(w * 0.33 + k * 0.08, 0.3 + k * 0.06, 0.1), model, 8)
		b.rotation_degrees.x = 90.0


## Portrait handheld (PocketStatia etc).
static func _handheld_tall(model: Node3D, col: Color, emit: float, s: float) -> void:
	Psx.box(Vector3(0.6 * s * 2.0, 1.0 * s * 2.0, 0.16), Psx.mat(col, null, Vector2.ONE, emit), Vector3(0, s, 0), model)
	_screen(model, Vector3(0, s * 1.35, 0.085), Vector2(0.7 * s, 0.6 * s))


## Clamshell handheld, open (PocketBoy SP, Duo).
static func _clamshell(model: Node3D, col: Color, emit: float, two_screens: bool) -> void:
	var g := Psx.mat(col, null, Vector2.ONE, emit)
	Psx.box(Vector3(0.85, 0.08, 0.8), g, Vector3(0, 0.04, 0), model)
	var lid := Node3D.new()
	lid.position = Vector3(0, 0.08, -0.4)
	lid.rotation_degrees.x = -70.0
	model.add_child(lid)
	Psx.box(Vector3(0.85, 0.06, 0.8), g, Vector3(0, 0.03, 0.4), lid)
	var scr := Psx.box(Vector3(0.6, 0.01, 0.5), Psx.mat(Color(0.45, 0.6, 0.75), null, Vector2.ONE, 0.6), Vector3(0, -0.005, 0.4), lid)
	scr.position.y = -0.002
	if two_screens:
		Psx.box(Vector3(0.5, 0.01, 0.42), Psx.mat(Color(0.45, 0.6, 0.75), null, Vector2.ONE, 0.6), Vector3(0, 0.085, 0.05), model)
	var dark := Psx.mat(Color(0.12, 0.12, 0.13))
	Psx.box(Vector3(0.12, 0.02, 0.04), dark, Vector3(-0.28, 0.09, 0.2), model)
	Psx.box(Vector3(0.04, 0.02, 0.12), dark, Vector3(-0.28, 0.09, 0.2), model)


## Upright arcade cabinet (MVS, PlayChoice, Vs.).
static func _cabinet(model: Node3D, col: Color) -> void:
	var body := Psx.mat(Color(0.12, 0.12, 0.13))
	Psx.box(Vector3(0.8, 1.8, 0.75), body, Vector3(0, 0.9, 0), model)
	Psx.box(Vector3(0.84, 0.25, 0.8), Psx.mat(col, null, Vector2.ONE, 0.8), Vector3(0, 1.72, 0.02), model)
	Psx.box(Vector3(0.6, 0.45, 0.02), Psx.mat(Color(0.35, 0.55, 0.85), null, Vector2.ONE, 0.9), Vector3(0, 1.3, 0.38), model)
	var panel := Psx.box(Vector3(0.82, 0.08, 0.3), Psx.mat(Color(0.2, 0.2, 0.22)), Vector3(0, 0.95, 0.45), model)
	panel.rotation_degrees.x = 15.0
	Psx.cyl(0.03, 0.12, Psx.mat(Color(0.85, 0.15, 0.15)), Vector3(-0.2, 1.05, 0.45), model, 6)
	for k in 3:
		Psx.cyl(0.035, 0.02, Psx.mat([Color(0.9, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.5, 0.9)][k]), Vector3(0.05 + k * 0.1, 1.02, 0.47), model, 8)


# ---------------------------------------------------------------- accessories

## Accessory archetype from the item name (generated items) or its legacy id.
static func _archetype(item: Dictionary) -> String:
	var n := String(item.get("name", "")).to_lower()
	var table := [
		["cabinet", "cabinet"], ["zappr", "gun"], ["gunkon", "gun"], ["g-kon", "gun"], ["justifyer", "gun"], ["light gun", "gun"],
		["super scoop", "bazooka"], ["mitt", "glove"], ["r.o.b.b.", "robot"], ["power padd", "mat"], [" mat", "mat"], ["dance dance", "mat"],
		["mouse", "mouse"], ["keyboard", "keyboard"], ["piano", "keyboard"], ["guitar", "guitar"], ["maracaz", "maracas"],
		["bongoes", "drums"], ["wheel", "wheel"], ["fishing", "rod"], ["arcade stick", "stick"], ["joystick", "stick"],
		["twin stick", "stick"], ["advantage", "stick"], ["trak-bawl", "trackball"], ["camera", "camera"], ["eyetoi", "camera"],
		["dreamseye", "camera"], ["kinnect", "camera"], ["printer", "printer"], ["microphone", "mic"], ["communicator", "mic"],
		["voice", "mic"], ["cable", "cable"], ["link", "cable"], ["memory", "card"], ["pakk", "card"], ["vmd", "card"],
		["jump pack", "card"], ["rumble", "card"], ["gamesnark", "card"], ["game jeannie", "card"], ["action replai", "card"],
		["freeloadr", "card"], ["flash", "card"], ["sufunny", "card"], ["e-readr", "card"], ["censor", "card"],
		["adapter", "adapter"], ["modem", "adapter"], ["multitapp", "adapter"], ["four scour", "adapter"], ["satellyte", "adapter"],
		["hard disk", "drive"], ["hd dvdee", "drive"], ["drive", "drive"], ["unit", "adapter"], ["kit", "adapter"],
		["remote", "remote"], ["stand", "stand"], ["vga box", "adapter"], ["recordr", "adapter"], ["start-up disc", "disc"],
		["controller", "pad"], ["pad", "pad"], ["max", "pad"], ["negkon", "pad"], ["jogkon", "pad"], ["u-farce", "adapter"],
		["roll 'n rockr", "mat"],
	]
	for e in table:
		if n.contains(String(e[0])):
			return String(e[1])
	return ""


static func _accessory(model: Node3D, item: Dictionary, plat: String, col: Color) -> void:
	var id := String(item["id"])
	var dark := Psx.mat(Color(0.1, 0.1, 0.11))
	var grey := Psx.mat(Color(0.72, 0.72, 0.74))
	var arche := _archetype(item)
	if not id.begins_with("fes_") and not id.begins_with("sfes_") or arche != "":
		if _build_archetype(model, item, plat, col, arche):
			return
	match id:
		"fes_zapper":
			var o := Psx.mat(Color(0.95, 0.5, 0.15))
			Psx.box(Vector3(0.9, 0.22, 0.2), o, Vector3(0.1, 0.65, 0), model)
			var h := Psx.box(Vector3(0.22, 0.6, 0.2), o, Vector3(-0.2, 0.32, 0), model)
			h.rotation_degrees.z = -15.0
			var _r1 := Psx.cyl(0.07, 0.3, dark, Vector3(0.62, 0.65, 0), model, 8)
			_r1.rotation_degrees.z = 90.0
		"fes_mitt":
			Psx.box(Vector3(0.6, 0.9, 0.2), grey, Vector3(0, 0.45, 0), model)
			Psx.box(Vector3(0.5, 0.3, 0.02), dark, Vector3(0, 0.6, 0.11), model)
			for x in [-0.15, 0.0, 0.15]:
				var _r2 := Psx.cyl(0.04, 0.03, Psx.mat(Color(0.8, 0.15, 0.15)), Vector3(x, 0.25, 0.11), model, 8)
				_r2.rotation_degrees.x = 90.0
		"sfes_bazooka":
			var t := Psx.cyl(0.18, 1.3, grey, Vector3(0, 0.3, 0), model, 10)
			t.rotation_degrees.z = 90.0
			Psx.box(Vector3(0.15, 0.3, 0.12), dark, Vector3(-0.1, 0.1, 0), model)
		"f64_rumble", "pst_memcard":
			var c := grey if id == "pst_memcard" else dark
			Psx.box(Vector3(0.6, 0.4, 0.12), c, Vector3(0, 0.2, 0), model)
			Psx.box(Vector3(0.4, 0.15, 0.01), Psx.mat(col), Vector3(0, 0.25, 0.065), model)
		"pboy_link":
			var tm := TorusMesh.new()
			tm.inner_radius = 0.38
			tm.outer_radius = 0.46
			tm.rings = 12
			tm.ring_segments = 6
			var t := Psx.mesh(tm, Psx.mat(Color(0.45, 0.3, 0.6)), Vector3(0, 0.46, 0), model)
			t.rotation_degrees.x = 90.0
		"pboy_camera":
			Psx.box(Vector3(0.5, 0.6, 0.12), Psx.mat(Color(0.8, 0.78, 0.72)), Vector3(0, 0.3, 0), model)
			var s := SphereMesh.new()
			s.radius = 0.22
			s.height = 0.44
			s.radial_segments = 10
			s.rings = 6
			Psx.mesh(s, Psx.mat(Color(0.75, 0.15, 0.15)), Vector3(0, 0.75, 0), model)
		"dc_vmd":
			Psx.box(Vector3(0.45, 0.65, 0.12), Psx.mat(Color(0.9, 0.9, 0.88)), Vector3(0, 0.33, 0), model)
			Psx.box(Vector3(0.3, 0.22, 0.01), Psx.mat(Color(0.5, 0.6, 0.4), null, Vector2.ONE, 0.4), Vector3(0, 0.45, 0.065), model)
		"a26_paddle":
			Psx.box(Vector3(0.5, 0.25, 0.4), dark, Vector3(0, 0.125, 0), model)
			Psx.cyl(0.14, 0.2, Psx.mat(Color(0.85, 0.85, 0.85)), Vector3(0, 0.35, 0), model, 10)
			Psx.box(Vector3(0.1, 0.06, 0.1), Psx.mat(Color(0.8, 0.15, 0.15)), Vector3(-0.17, 0.27, 0.1), model)
		"sfes_pad":
			_pad(model, grey, 1.0, [Color(0.8, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.25, 0.6, 0.3), Color(0.25, 0.35, 0.8)])
		"gen_pad6":
			_pad(model, dark, 0.9, [Color(0.3, 0.3, 0.32), Color(0.3, 0.3, 0.32), Color(0.3, 0.3, 0.32), Color(0.3, 0.3, 0.32), Color(0.3, 0.3, 0.32), Color(0.3, 0.3, 0.32)])
		"f64_pad":
			var g := Psx.mat(Color(0.5, 0.5, 0.54))
			Psx.box(Vector3(0.9, 0.2, 0.35), g, Vector3(0, 0.6, 0), model)
			for x in [-0.35, 0.0, 0.35]:
				Psx.box(Vector3(0.16, 0.5, 0.2), g, Vector3(x, 0.3, 0), model)
			Psx.cyl(0.05, 0.08, dark, Vector3(0, 0.74, 0), model, 6)
		"pst_dualpad":
			_pad(model, grey, 1.0, [Color(0.3, 0.75, 0.6), Color(0.85, 0.3, 0.3), Color(0.6, 0.45, 0.8), Color(0.5, 0.6, 0.85)])
			for x in [-0.32, 0.32]:
				Psx.cyl(0.12, 0.5, grey, Vector3(x, 0.15, 0.05), model, 8)
		_:
			_pad(model, Psx.mat(col.darkened(0.3)), 1.0, [Color(0.85, 0.2, 0.2), Color(0.85, 0.2, 0.2)])


## A flat game pad standing up, facing +Z: body, d-pad and face buttons.
static func _pad(model: Node3D, body: Material, w: float, buttons: Array) -> void:
	var cap := CapsuleMesh.new()
	cap.radius = 0.24
	cap.height = w
	cap.radial_segments = 10
	cap.rings = 2
	var b := Psx.mesh(cap, body, Vector3(0, 0.3, 0), model)
	b.rotation_degrees.z = 90.0
	b.scale = Vector3(1, 1, 0.45)
	var dark := Psx.mat(Color(0.12, 0.12, 0.13))
	Psx.box(Vector3(0.16, 0.05, 0.03), dark, Vector3(-w * 0.27, 0.3, 0.11), model)
	Psx.box(Vector3(0.05, 0.16, 0.03), dark, Vector3(-w * 0.27, 0.3, 0.11), model)
	for i in buttons.size():
		var a := TAU * float(i) / buttons.size()
		var p := Vector3(w * 0.27 + cos(a) * 0.07, 0.3 + sin(a) * 0.07, 0.11)
		var _r3 := Psx.cyl(0.035, 0.03, Psx.mat(buttons[i]), p, model, 8)
		_r3.rotation_degrees.x = 90.0


static func _build_archetype(model: Node3D, item: Dictionary, plat: String, col: Color, arche: String) -> bool:
	var nm := String(item.get("name", ""))
	var shell: Array = name_color(item, Color(0.7, 0.7, 0.73))
	var g := Psx.mat(shell[0], null, Vector2.ONE, shell[1])
	var dark := Psx.mat(Color(0.1, 0.1, 0.11))
	var accent := Psx.mat(col)
	match arche:
		"cabinet":
			_cabinet(model, col)
		"gun":
			var gc := Color(0.95, 0.5, 0.15) if nm.contains("Orange") else (shell[0] as Color)
			if plat in ["PST", "PST2", "DC"]:
				gc = Color(0.15, 0.15, 0.17) if plat != "DC" else Color(0.85, 0.85, 0.85)
			var o := Psx.mat(gc)
			Psx.box(Vector3(0.9, 0.22, 0.2), o, Vector3(0.1, 0.65, 0), model)
			var hd := Psx.box(Vector3(0.22, 0.6, 0.2), o, Vector3(-0.2, 0.32, 0), model)
			hd.rotation_degrees.z = -15.0
			var br := Psx.cyl(0.07, 0.3, dark, Vector3(0.62, 0.65, 0), model, 8)
			br.rotation_degrees.z = 90.0
		"bazooka":
			var t := Psx.cyl(0.18, 1.3, Psx.mat(Color(0.25, 0.25, 0.28)), Vector3(0, 0.3, 0), model, 10)
			t.rotation_degrees.z = 90.0
			Psx.box(Vector3(0.15, 0.3, 0.12), dark, Vector3(-0.1, 0.1, 0), model)
		"glove":
			Psx.box(Vector3(0.6, 0.9, 0.22), Psx.mat(Color(0.35, 0.35, 0.38)), Vector3(0, 0.45, 0), model)
			Psx.box(Vector3(0.5, 0.3, 0.02), dark, Vector3(0, 0.6, 0.12), model)
			for k in 4:
				Psx.box(Vector3(0.1, 0.35, 0.12), Psx.mat(Color(0.35, 0.35, 0.38)), Vector3(-0.22 + k * 0.15, 1.05, 0), model)
		"robot":
			Psx.box(Vector3(0.6, 0.12, 0.6), g, Vector3(0, 0.06, 0), model)
			Psx.cyl(0.06, 0.8, dark, Vector3(0, 0.5, 0), model, 8)
			Psx.box(Vector3(0.5, 0.3, 0.35), g, Vector3(0, 0.95, 0), model)
			for x in [-0.12, 0.12]:
				var eye := Psx.cyl(0.06, 0.04, Psx.mat(Color(0.9, 0.2, 0.2), null, Vector2.ONE, 1.0), Vector3(x, 0.98, 0.18), model, 10)
				eye.rotation_degrees.x = 90.0
			for x in [-0.32, 0.32]:
				Psx.box(Vector3(0.08, 0.06, 0.4), g, Vector3(x, 0.6, 0.15), model)
		"mat":
			Psx.box(Vector3(1.3, 0.04, 1.3), Psx.mat(Color(0.15, 0.15, 0.2)), Vector3(0, 0.02, 0), model)
			for k in 4:
				var a := TAU * k / 4.0
				Psx.box(Vector3(0.28, 0.02, 0.28), Psx.mat(Color.from_hsv(float(k) / 4.0, 0.6, 0.9), null, Vector2.ONE, 0.3), Vector3(cos(a) * 0.4, 0.05, sin(a) * 0.4), model)
		"mouse":
			var s := SphereMesh.new()
			s.radius = 0.35
			s.height = 0.4
			s.radial_segments = 10
			s.rings = 5
			var mm := Psx.mesh(s, g, Vector3(0, 0.2, 0), model)
			mm.scale = Vector3(0.8, 0.5, 1.2)
			Psx.box(Vector3(0.02, 0.05, 0.3), dark, Vector3(0, 0.38, 0.15), model)
		"keyboard":
			Psx.box(Vector3(1.5, 0.1, 0.55), g, Vector3(0, 0.05, 0), model)
			for r in 3:
				for k in 10:
					Psx.box(Vector3(0.1, 0.04, 0.1), Psx.mat(Color(0.95, 0.95, 0.95) if nm.contains("Pian") else Color(0.25, 0.25, 0.28)), Vector3(-0.63 + k * 0.14, 0.12, -0.15 + r * 0.14), model)
		"guitar":
			var neck := Psx.box(Vector3(1.2, 0.08, 0.1), dark, Vector3(0.3, 0.5, 0), model)
			neck.rotation_degrees.z = 25.0
			Psx.box(Vector3(0.55, 0.65, 0.12), Psx.mat(Color(0.85, 0.2, 0.15)), Vector3(-0.3, 0.33, 0), model)
			for k in 5:
				Psx.box(Vector3(0.05, 0.03, 0.06), Psx.mat(Color.from_hsv(k / 5.0, 0.7, 0.9)), Vector3(0.5 + k * 0.07, 0.75 + k * 0.03, 0.06), model)
		"maracas":
			for x in [-0.25, 0.25]:
				var s2 := SphereMesh.new()
				s2.radius = 0.22
				s2.height = 0.44
				s2.radial_segments = 10
				s2.rings = 5
				Psx.mesh(s2, Psx.mat(Color(0.85, 0.2, 0.2)), Vector3(x, 0.75, 0), model)
				Psx.cyl(0.04, 0.5, dark, Vector3(x, 0.3, 0), model, 6)
		"drums":
			for x in [-0.3, 0.3]:
				Psx.cyl(0.28, 0.5, Psx.mat(Color(0.55, 0.35, 0.2), Psx.tex("wood092")), Vector3(x, 0.25, 0), model, 14)
				Psx.cyl(0.29, 0.02, Psx.mat(Color(0.9, 0.88, 0.8)), Vector3(x, 0.51, 0), model, 14)
		"wheel":
			Psx.box(Vector3(0.9, 0.3, 0.6), g, Vector3(0, 0.15, 0), model)
			var tm := TorusMesh.new()
			tm.inner_radius = 0.32
			tm.outer_radius = 0.4
			tm.rings = 14
			tm.ring_segments = 6
			var wh := Psx.mesh(tm, dark, Vector3(0, 0.55, 0.15), model)
			wh.rotation_degrees.x = 70.0
		"rod":
			var rd := Psx.cyl(0.04, 1.4, dark, Vector3(0.2, 0.6, 0), model, 6)
			rd.rotation_degrees.z = -40.0
			Psx.cyl(0.12, 0.12, g, Vector3(-0.15, 0.25, 0), model, 10).rotation_degrees.x = 90.0
		"stick", "trackball":
			Psx.box(Vector3(1.0, 0.22, 0.6), Psx.mat(Color(0.12, 0.12, 0.14)), Vector3(0, 0.11, 0), model)
			if arche == "trackball":
				var s3 := SphereMesh.new()
				s3.radius = 0.18
				s3.height = 0.36
				Psx.mesh(s3, Psx.mat(Color(0.75, 0.2, 0.2)), Vector3(0, 0.25, 0), model)
			else:
				Psx.cyl(0.03, 0.3, dark, Vector3(-0.25, 0.37, 0), model, 6)
				var ball := SphereMesh.new()
				ball.radius = 0.08
				ball.height = 0.16
				Psx.mesh(ball, Psx.mat(Color(0.85, 0.15, 0.15)), Vector3(-0.25, 0.52, 0), model)
				for k in 6:
					Psx.cyl(0.05, 0.03, Psx.mat(Color.from_hsv(k / 6.0, 0.6, 0.9)), Vector3(0.05 + (k % 3) * 0.14, 0.23, -0.07 + (k / 3) * 0.14), model, 8)
		"camera":
			Psx.box(Vector3(0.6, 0.35, 0.3), g, Vector3(0, 0.3, 0), model)
			var lens := Psx.cyl(0.11, 0.1, dark, Vector3(0, 0.3, 0.18), model, 12)
			lens.rotation_degrees.x = 90.0
			Psx.box(Vector3(0.3, 0.12, 0.25), dark, Vector3(0, 0.06, 0), model)
		"printer":
			Psx.box(Vector3(0.6, 0.35, 0.6), g, Vector3(0, 0.175, 0), model)
			Psx.box(Vector3(0.4, 0.3, 0.01), Psx.mat(Color(0.97, 0.97, 0.95)), Vector3(0, 0.45, -0.1), model)
		"mic":
			var hd2 := SphereMesh.new()
			hd2.radius = 0.15
			hd2.height = 0.3
			Psx.mesh(hd2, dark, Vector3(0, 0.75, 0), model)
			Psx.cyl(0.06, 0.6, g, Vector3(0, 0.35, 0), model, 8)
		"cable":
			var tm2 := TorusMesh.new()
			tm2.inner_radius = 0.34
			tm2.outer_radius = 0.42
			tm2.rings = 12
			tm2.ring_segments = 6
			var t2 := Psx.mesh(tm2, Psx.mat(col.darkened(0.3)), Vector3(0, 0.42, 0), model)
			t2.rotation_degrees.x = 90.0
			Psx.box(Vector3(0.12, 0.08, 0.06), dark, Vector3(0.42, 0.42, 0), model)
		"card":
			Psx.box(Vector3(0.6, 0.42, 0.1), g, Vector3(0, 0.21, 0), model)
			Psx.box(Vector3(0.4, 0.18, 0.01), accent, Vector3(0, 0.25, 0.055), model)
		"adapter", "remote", "stand":
			var h3 := 0.25 if arche == "adapter" else (0.12 if arche == "remote" else 0.8)
			Psx.box(Vector3(0.8 if arche != "remote" else 0.25, h3, 0.5 if arche != "remote" else 0.8), g, Vector3(0, h3 * 0.5, 0), model)
			Psx.box(Vector3(0.3, 0.04, 0.02), accent, Vector3(0, h3 * 0.6, 0.26), model)
		"drive":
			Psx.box(Vector3(1.0, 0.3, 0.8), g, Vector3(0, 0.15, 0), model)
			Psx.box(Vector3(0.5, 0.03, 0.02), dark, Vector3(0, 0.2, 0.41), model)
		"disc":
			_disc(model, Art.front(item), plat)
		"pad":
			_platform_pad(model, item, plat, col, g)
		_:
			return false
	return true


## Controller shaped like its platform's pad.
static func _platform_pad(model: Node3D, item: Dictionary, plat: String, col: Color, g: Material) -> void:
	var dark := Psx.mat(Color(0.1, 0.1, 0.11))
	var shell: Color = name_color(item, Color(0.72, 0.72, 0.74))[0]
	match plat:
		"FES":
			Psx.box(Vector3(1.0, 0.45, 0.12), Psx.mat(Color(0.72, 0.72, 0.74)), Vector3(0, 0.3, 0), model)
			Psx.box(Vector3(0.94, 0.35, 0.01), dark, Vector3(0, 0.3, 0.065), model)
			for x in [0.2, 0.35]:
				Psx.cyl(0.05, 0.03, Psx.mat(Color(0.8, 0.15, 0.15)), Vector3(x, 0.27, 0.08), model, 8).rotation_degrees.x = 90.0
		"F64", "FCUBE":
			var pg := Psx.mat(shell if plat == "F64" else Color(0.3, 0.25, 0.65) if shell == Color(0.72, 0.72, 0.74) else shell)
			Psx.box(Vector3(0.9, 0.22, 0.35), pg, Vector3(0, 0.6, 0), model)
			for x in ([-0.35, 0.0, 0.35] if plat == "F64" else [-0.35, 0.35]):
				Psx.box(Vector3(0.18, 0.5, 0.22), pg, Vector3(x, 0.3, 0), model)
			Psx.cyl(0.07, 0.06, Psx.mat(Color(0.2, 0.75, 0.4)), Vector3(0.25, 0.73, 0), model, 10)
		"XBX":
			var big := String(item.get("name", "")).contains("Duke")
			_pad(model, Psx.mat(shell if shell != Color(0.72, 0.72, 0.74) else Color(0.15, 0.15, 0.17)), 1.3 if big else 1.0, [Color(0.2, 0.75, 0.3), Color(0.85, 0.2, 0.2), Color(0.2, 0.4, 0.9), Color(0.95, 0.8, 0.2)])
		"NEO":
			Psx.box(Vector3(1.2, 0.2, 0.6), dark, Vector3(0, 0.1, 0), model)
			Psx.cyl(0.03, 0.25, dark, Vector3(-0.35, 0.32, 0), model, 6)
			for k in 4:
				Psx.cyl(0.06, 0.03, Psx.mat([Color(0.9, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.7, 0.3), Color(0.2, 0.4, 0.9)][k]), Vector3(0.1 + k * 0.13, 0.21, 0), model, 8)
		"DC":
			_pad(model, Psx.mat(Color(0.88, 0.88, 0.86)), 0.9, [Color(0.85, 0.2, 0.2), Color(0.2, 0.4, 0.9), Color(0.95, 0.8, 0.2), Color(0.2, 0.7, 0.3)])
			Psx.box(Vector3(0.22, 0.25, 0.05), Psx.mat(Color(0.25, 0.25, 0.28)), Vector3(0, 0.42, 0.1), model)
		"PST", "PST2":
			_pad(model, Psx.mat(shell if plat == "PST" else Color(0.1, 0.1, 0.11)), 1.0, [Color(0.3, 0.75, 0.6), Color(0.85, 0.3, 0.3), Color(0.6, 0.45, 0.8), Color(0.5, 0.6, 0.85)])
			for x in [-0.32, 0.32]:
				Psx.cyl(0.12, 0.5, Psx.mat(shell if plat == "PST" else Color(0.1, 0.1, 0.11)), Vector3(x, 0.15, 0.05), model, 8)
		"GEN":
			_pad(model, dark, 0.9, [Color(0.3, 0.3, 0.32), Color(0.3, 0.3, 0.32), Color(0.3, 0.3, 0.32)])
		_:
			_pad(model, Psx.mat(shell), 1.0, [Color(0.85, 0.2, 0.2), Color(0.95, 0.8, 0.2), Color(0.2, 0.6, 0.3), Color(0.25, 0.35, 0.8)])


# ---------------------------------------------------------------- memorabilia

static func _misc(model: Node3D, id: String, label: Texture2D, col: Color) -> void:
	match id:
		"misc_pogs":
			Psx.cyl(0.18, 0.9, Psx.mat(Color(0.95, 0.85, 0.3), null, Vector2.ONE, 0.1), Vector3(0, 0.45, 0), model, 12)
			Psx.cyl(0.19, 0.08, Psx.mat(Color(0.85, 0.2, 0.3)), Vector3(0, 0.92, 0), model, 12)
			Psx.quad(Vector2(0.3, 0.5), _pic_mat(label, 0.6), Vector3(0, 0.45, 0.185), model)
		"misc_kiosk":
			var shell := Psx.mat(Color(0.75, 0.75, 0.78))
			Psx.box(Vector3(0.8, 1.7, 0.55), shell, Vector3(0, 0.85, 0), model)
			Psx.box(Vector3(0.84, 0.3, 0.6), Psx.mat(Color(0.8, 0.15, 0.15), null, Vector2.ONE, 0.4), Vector3(0, 1.6, 0), model)
			Psx.quad(Vector2(0.6, 0.48), _pic_mat(label, 1.25, 0.6), Vector3(0, 1.15, 0.28), model)
			Psx.box(Vector3(0.5, 0.06, 0.2), Psx.mat(Color(0.2, 0.2, 0.22)), Vector3(0, 0.78, 0.35), model)
		"misc_proto":
			var g := Psx.mat(Color(0.78, 0.78, 0.8))
			Psx.box(Vector3(1.25, 0.32, 1.0), g, Vector3(0, 0.16, 0), model)
			Psx.cyl(0.33, 0.04, Psx.mat(Color(0.66, 0.66, 0.7)), Vector3(0.2, 0.34, -0.05), model, 16)
			Psx.box(Vector3(0.36, 0.03, 0.08), Psx.mat(Color(0.1, 0.1, 0.1)), Vector3(-0.35, 0.33, 0.1), model)
			var tag := Psx.quad(Vector2(0.4, 0.4), _pic_mat(label, 1.0), Vector3(-0.3, 0.335, 0.3), model)
			tag.rotation_degrees.x = -90.0
		_:
			# Strategy guide / magazine: a book standing up with its cover out.
			var d := 0.05 if id == "misc_mag1" else 0.1
			Psx.box(Vector3(0.75, 1.0, d), Psx.mat(Color(0.9, 0.88, 0.82)), Vector3(0, 0.5, 0), model)
			Psx.quad(Vector2(0.75, 1.0), _pic_mat(label, 0.75), Vector3(0, 0.5, d / 2.0 + 0.002), model)
			var _r4 := Psx.quad(Vector2(d, 1.0), Psx.mat(col.darkened(0.3)), Vector3(-0.376, 0.5, 0), model)
			_r4.rotation_degrees.y = -90.0
