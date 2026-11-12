class_name ItemModels
extends RefCounted
## Builds a low-poly 3D model for any catalog item: real cartridge models
## (assets/models/items) with a per-game label, jewel cases and discs, retail
## boxes, consoles, controllers and memorabilia. Labels are baked by
## tools/bake_items.gd into assets/items/labels/<id>.png.
##
## build() returns a Node3D sitting on y=0, centred, front facing +Z, sized in
## metres (a cart is ~0.17 m tall) so a scene can drop it straight on a table.

const CART_BIG := "res://assets/models/items/gameCartridge1.glb"
const CART_SMALL := "res://assets/models/items/handheldCartridge1.glb"
const CART_BIG_TEX := "res://assets/models/items/gameCartridge1.png"
const CART_SMALL_TEX := "res://assets/models/items/handheldCartridge1.png"
## Where the sticker sits on each cart texture (UV).
const BIG_LABEL := Rect2(0.22, 0.05, 0.205, 0.42)
const SMALL_LABEL := Rect2(0.078, 0.312, 0.344, 0.297)

## Loose cart look per platform: [model, scale (thickness, height, width), body tint].
const CART := {
	"FES": ["big", Vector3(1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0)],
	"SFES": ["big", Vector3(1.0, 0.78, 1.22), Color(1.08, 1.08, 1.1)],
	"F64": ["big", Vector3(1.4, 0.74, 1.12), Color(0.42, 0.42, 0.46)],
	"GEN": ["big", Vector3(1.15, 0.92, 0.84), Color(0.2, 0.2, 0.22)],
	"A26": ["big", Vector3(1.25, 0.62, 0.78), Color(0.17, 0.15, 0.14)],
	"PBOY": ["small", Vector3(1.0, 1.0, 1.0), Color(1.0, 1.0, 1.0)],
}

## Retail box size (w, h, d) for games, by platform.
const GAME_BOX := {
	"FES": Vector3(0.72, 1.0, 0.17), "SFES": Vector3(1.0, 0.72, 0.18),
	"F64": Vector3(1.0, 0.72, 0.2), "GEN": Vector3(0.72, 1.0, 0.14),
	"A26": Vector3(0.72, 0.95, 0.17), "PBOY": Vector3(0.62, 0.68, 0.13),
	"PST": Vector3(1.0, 0.9, 0.1), "DC": Vector3(1.0, 0.9, 0.1),
}

## Real-world-ish sizes (largest side, metres) so a scene reads at a glance.
const SIZE := {"game": 0.17, "game_box": 0.21, "console": 0.34, "console_box": 0.42, "acc": 0.2, "acc_box": 0.24, "misc": 0.24}

static var _carts: Dictionary = {}


static func is_boxed(item: Dictionary) -> bool:
	return ["CIB", "Mint", "Sealed"].has(String(item.get("cond", "Loose")))


static func is_disc(item: Dictionary) -> bool:
	return (item.get("tags", []) as Array).has("disc")


static func label_for(id: String) -> Texture2D:
	var path := "res://assets/items/labels/%s.png" % id
	return load(path) if ResourceLoader.exists(path) else null


## item: a catalog def or a run item (needs id, plat, kind, tags; cond optional).
static func build(item: Dictionary, label: Texture2D = null, boxed: int = -1) -> Node3D:
	if label == null:
		label = label_for(String(item["id"]))
	var box := is_boxed(item) if boxed < 0 else boxed == 1
	var plat := String(item["plat"])
	var kind := String(item["kind"])
	var col: Color = Catalog.platform(plat)["color"]
	var model := Node3D.new()
	var size_key := kind
	if kind == "game":
		if box:
			_retail_box(model, GAME_BOX.get(plat, Vector3(0.72, 1.0, 0.17)), label, col, plat, true)
			size_key = "game_box"
		elif is_disc(item):
			_disc(model, label)
		else:
			_cart(model, plat, label)
	elif kind == "console":
		if box:
			_retail_box(model, Vector3(1.5, 1.0, 0.45), label, col, plat, false)
			size_key = "console_box"
		else:
			_console(model, String(item["id"]), plat, label)
	elif kind == "acc":
		if box:
			_retail_box(model, Vector3(0.9, 0.75, 0.24), label, col, plat, false)
			size_key = "acc_box"
		else:
			_accessory(model, String(item["id"]), plat, col)
	else:
		_misc(model, String(item["id"]), label, col)
	var cond := String(item.get("cond", ""))
	if cond == "Sealed":
		_seal(model)
	var holder := Node3D.new()
	holder.add_child(model)
	_fit(model, float(SIZE.get(size_key, 0.2)))
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
	var spec: Array = CART.get(plat, CART["FES"])
	var small: bool = spec[0] == "small"
	var path := CART_SMALL if small else CART_BIG
	if not _carts.has(path):
		_carts[path] = load(path)
	var ps: PackedScene = _carts[path]
	var inner: Node3D = ps.instantiate()
	var base: Texture2D = load(CART_SMALL_TEX if small else CART_BIG_TEX)
	var m := Psx.label_mat(base, label, SMALL_LABEL if small else BIG_LABEL, spec[2])
	_apply(inner, m)
	inner.scale = spec[1]
	inner.rotation_degrees.y = -90.0
	model.add_child(inner)


static func _apply(n: Node, m: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = m
	for c in n.get_children():
		_apply(c, m)


static func _disc(model: Node3D, label: Texture2D) -> void:
	var silver := Psx.mat(Color(0.78, 0.8, 0.86), null, Vector2.ONE, 0.15)
	var d := Psx.cyl(0.5, 0.02, silver, Vector3(0, 0.5, 0), model, 20)
	d.rotation_degrees.x = 90.0
	var lm := Psx.mat(Color.WHITE, label)
	lm.set_shader_parameter("circle", true)
	Psx.quad(Vector2(0.94, 0.94), lm, Vector3(0, 0.5, 0.012), model)


## Cardboard (or plastic) retail box with the label as its front art.
static func _retail_box(model: Node3D, size: Vector3, label: Texture2D, col: Color, plat: String, game: bool) -> void:
	var body: Material
	if plat == "PST" or plat == "DC":
		body = Psx.mat(Color(0.16, 0.16, 0.18) if plat == "PST" else Color(0.85, 0.85, 0.82))
	elif plat == "GEN" and game:
		body = Psx.mat(Color(0.1, 0.1, 0.11))
	elif plat == "FES" and game:
		body = Psx.mat(Color(0.08, 0.08, 0.08))
	else:
		body = Psx.mat(col.lerp(Color(0.75, 0.6, 0.4), 0.45), Psx.tex("cardboard002"))
	Psx.box(size, body, Vector3(0, size.y / 2.0, 0), model)
	var front := Psx.mat(Color.WHITE, label)
	var inset := 0.04 if (plat == "PST" or plat == "DC") else 0.0
	Psx.quad(Vector2(size.x - inset * 2.0, size.y - inset * 2.0), front, Vector3(0, size.y / 2.0, size.z / 2.0 + 0.002), model)
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

static func _console(model: Node3D, id: String, plat: String, label: Texture2D) -> void:
	var dark := Psx.mat(Color(0.08, 0.08, 0.09))
	match plat:
		"FES":
			var g := Psx.mat(Color(0.72, 0.72, 0.74))
			Psx.box(Vector3(1.3, 0.36, 1.0), g, Vector3(0, 0.18, 0), model)
			Psx.box(Vector3(1.32, 0.05, 1.02), dark, Vector3(0, 0.2, 0), model)
			Psx.box(Vector3(0.8, 0.02, 0.5), Psx.mat(Color(0.62, 0.62, 0.64)), Vector3(0, 0.37, 0.1), model)
			Psx.box(Vector3(0.12, 0.06, 0.02), Psx.mat(Color(0.8, 0.15, 0.12), null, Vector2.ONE, 0.6), Vector3(-0.45, 0.1, 0.51), model)
			for x in [-0.15, 0.1]:
				Psx.box(Vector3(0.14, 0.08, 0.02), dark, Vector3(x, 0.1, 0.51), model)
		"SFES":
			var g := Psx.mat(Color(0.78, 0.78, 0.82))
			Psx.box(Vector3(1.2, 0.3, 0.95), g, Vector3(0, 0.15, 0), model)
			Psx.box(Vector3(0.7, 0.08, 0.45), Psx.mat(Color(0.68, 0.68, 0.72)), Vector3(0, 0.34, -0.05), model)
			Psx.box(Vector3(0.5, 0.03, 0.08), dark, Vector3(0, 0.39, -0.05), model)
			var purple := Psx.mat(Color(0.45, 0.32, 0.7))
			Psx.box(Vector3(0.14, 0.05, 0.1), purple, Vector3(-0.35, 0.32, 0.3), model)
			Psx.box(Vector3(0.14, 0.05, 0.1), purple, Vector3(0.35, 0.32, 0.3), model)
		"F64":
			var c := Color(0.2, 0.2, 0.22)
			if id == "f64_jungle":
				c = Color(0.25, 0.65, 0.3)
			var g := Psx.mat(c, null, Vector2.ONE, 0.25 if id == "f64_jungle" else 0.0)
			Psx.box(Vector3(1.3, 0.28, 1.0), g, Vector3(0, 0.14, 0), model)
			Psx.box(Vector3(0.62, 0.16, 0.6), g, Vector3(0, 0.36, -0.05), model)
			Psx.box(Vector3(0.4, 0.03, 0.08), dark, Vector3(0, 0.45, -0.05), model)
			for x in [-0.39, -0.13, 0.13, 0.39]:
				Psx.box(Vector3(0.12, 0.08, 0.02), dark, Vector3(x, 0.12, 0.51), model)
		"PBOY":
			var c := Color(0.75, 0.75, 0.72)
			if id == "pboy_gold":
				c = Color(0.9, 0.72, 0.25)
			var g := Psx.mat(c, null, Vector2.ONE, 0.15 if id == "pboy_gold" else 0.0)
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
			var g := Psx.mat(Color(0.1, 0.1, 0.11))
			Psx.box(Vector3(1.25, 0.26, 0.95), g, Vector3(0, 0.13, 0), model)
			Psx.cyl(0.36, 0.06, Psx.mat(Color(0.16, 0.16, 0.18)), Vector3(0.0, 0.29, -0.05), model, 16)
			Psx.box(Vector3(0.45, 0.04, 0.06), dark, Vector3(0, 0.33, -0.05), model)
			Psx.box(Vector3(0.6, 0.02, 0.02), Psx.mat(Color(0.85, 0.15, 0.15), null, Vector2.ONE, 0.5), Vector3(0, 0.2, 0.48), model)
		"DC":
			var g := Psx.mat(Color(0.88, 0.88, 0.86))
			Psx.box(Vector3(1.1, 0.34, 1.1), g, Vector3(0, 0.17, 0), model)
			Psx.cyl(0.38, 0.04, Psx.mat(Color(0.8, 0.8, 0.78)), Vector3(0, 0.36, -0.05), model, 18)
			Psx.cyl(0.08, 0.02, Psx.mat(Color(0.95, 0.5, 0.15), null, Vector2.ONE, 0.6), Vector3(0, 0.39, -0.05), model, 10)
		"PST":
			var g := Psx.mat(Color(0.7, 0.71, 0.74))
			Psx.box(Vector3(1.3, 0.28, 0.95), g, Vector3(0, 0.14, 0), model)
			Psx.cyl(0.36, 0.04, Psx.mat(Color(0.64, 0.65, 0.68)), Vector3(0.12, 0.3, -0.03), model, 18)
			for p in [Vector3(-0.45, 0.3, 0.2), Vector3(-0.45, 0.3, -0.05)]:
				Psx.cyl(0.06, 0.04, Psx.mat(Color(0.5, 0.52, 0.56)), p, model, 8)
		"A26":
			Psx.box(Vector3(1.3, 0.26, 0.9), Psx.mat(Color(0.1, 0.09, 0.09)), Vector3(0, 0.13, 0), model)
			Psx.box(Vector3(1.3, 0.14, 0.04), Psx.mat(Color(1, 1, 1), Psx.tex("wood092")), Vector3(0, 0.12, 0.46), model)
			Psx.box(Vector3(0.8, 0.12, 0.5), Psx.mat(Color(0.12, 0.11, 0.1)), Vector3(0, 0.3, -0.1), model)
			for x in [-0.5, -0.3, 0.3, 0.5]:
				Psx.cyl(0.04, 0.1, Psx.mat(Color(0.7, 0.7, 0.7)), Vector3(x, 0.3, 0.25), model, 6)
		_:
			_misc(model, id, label, Catalog.platform(plat)["color"])


# ---------------------------------------------------------------- accessories

static func _accessory(model: Node3D, id: String, plat: String, col: Color) -> void:
	var dark := Psx.mat(Color(0.1, 0.1, 0.11))
	var grey := Psx.mat(Color(0.72, 0.72, 0.74))
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


# ---------------------------------------------------------------- memorabilia

static func _misc(model: Node3D, id: String, label: Texture2D, col: Color) -> void:
	match id:
		"misc_pogs":
			Psx.cyl(0.18, 0.9, Psx.mat(Color(0.95, 0.85, 0.3), null, Vector2.ONE, 0.1), Vector3(0, 0.45, 0), model, 12)
			Psx.cyl(0.19, 0.08, Psx.mat(Color(0.85, 0.2, 0.3)), Vector3(0, 0.92, 0), model, 12)
			Psx.quad(Vector2(0.3, 0.5), Psx.mat(Color.WHITE, label), Vector3(0, 0.45, 0.185), model)
		"misc_kiosk":
			var shell := Psx.mat(Color(0.75, 0.75, 0.78))
			Psx.box(Vector3(0.8, 1.7, 0.55), shell, Vector3(0, 0.85, 0), model)
			Psx.box(Vector3(0.84, 0.3, 0.6), Psx.mat(Color(0.8, 0.15, 0.15), null, Vector2.ONE, 0.4), Vector3(0, 1.6, 0), model)
			Psx.quad(Vector2(0.6, 0.48), Psx.mat(Color.WHITE, label, Vector2.ONE, 0.6), Vector3(0, 1.15, 0.28), model)
			Psx.box(Vector3(0.5, 0.06, 0.2), Psx.mat(Color(0.2, 0.2, 0.22)), Vector3(0, 0.78, 0.35), model)
		"misc_proto":
			var g := Psx.mat(Color(0.78, 0.78, 0.8))
			Psx.box(Vector3(1.25, 0.32, 1.0), g, Vector3(0, 0.16, 0), model)
			Psx.cyl(0.33, 0.04, Psx.mat(Color(0.66, 0.66, 0.7)), Vector3(0.2, 0.34, -0.05), model, 16)
			Psx.box(Vector3(0.36, 0.03, 0.08), Psx.mat(Color(0.1, 0.1, 0.1)), Vector3(-0.35, 0.33, 0.1), model)
			var tag := Psx.quad(Vector2(0.4, 0.4), Psx.mat(Color.WHITE, label), Vector3(-0.3, 0.335, 0.3), model)
			tag.rotation_degrees.x = -90.0
		_:
			# Strategy guide / magazine: a book standing up with its cover out.
			var d := 0.05 if id == "misc_mag1" else 0.1
			Psx.box(Vector3(0.75, 1.0, d), Psx.mat(Color(0.9, 0.88, 0.82)), Vector3(0, 0.5, 0), model)
			Psx.quad(Vector2(0.75, 1.0), Psx.mat(Color.WHITE, label), Vector3(0, 0.5, d / 2.0 + 0.002), model)
			var _r4 := Psx.quad(Vector2(d, 1.0), Psx.mat(col.darkened(0.3)), Vector3(-0.376, 0.5, 0), model)
			_r4.rotation_degrees.y = -90.0
