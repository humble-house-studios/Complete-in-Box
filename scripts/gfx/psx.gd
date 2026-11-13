class_name Psx
extends RefCounted
## PSX-look building blocks: one shader for every surface (vertex snap, nearest
## textures, distance fog), plus helpers that build boxes, cylinders and quads,
## and load the furniture models in assets/models/props with that look.

const SHADER := preload("res://assets/shaders/psx.gdshader")
const OUTLINE := preload("res://assets/shaders/outline.gdshader")
static var _outline_mat: ShaderMaterial

## Fog applied to every material built after it is set (stage sets it per scene).
static var fog_color := Color(0.04, 0.03, 0.05)
static var fog_near := 4.0
static var fog_far := 14.0
static var snap := 700.0

static var _scenes: Dictionary = {}
static var _tex: Dictionary = {}


static func tex(name: String) -> Texture2D:
	if not _tex.has(name):
		var path := "res://assets/textures/%s.png" % name
		_tex[name] = load(path) if ResourceLoader.exists(path) else null
	return _tex[name]


static func mat(color: Color, texture: Texture2D = null, uv := Vector2.ONE, emit := 0.0) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("albedo", color)
	if texture != null:
		m.set_shader_parameter("tex", texture)
		m.set_shader_parameter("use_tex", true)
	m.set_shader_parameter("uv_scale", uv)
	m.set_shader_parameter("emit", emit)
	m.set_shader_parameter("snap", snap)
	m.set_shader_parameter("fog_color", fog_color)
	m.set_shader_parameter("fog_near", fog_near)
	m.set_shader_parameter("fog_far", fog_far)
	return m


## `aspect` = the sticker's real width / height: the art is fitted inside it
## (never stretched), with `bg` filling any spare edge.
static func label_mat(base: Texture2D, label: Texture2D, rect: Rect2, tint: Color, aspect: float = 0.0, bg := Color(0.06, 0.06, 0.07)) -> ShaderMaterial:
	var m := mat(Color.WHITE, base)
	m.set_shader_parameter("use_label", label != null)
	m.set_shader_parameter("label_tex", label)
	m.set_shader_parameter("label_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	m.set_shader_parameter("body_tint", tint)
	m.set_shader_parameter("label_bg", bg)
	if label != null and aspect > 0.0:
		m.set_shader_parameter("label_fit", fit(float(label.get_width()) / maxf(1.0, label.get_height()), aspect, false))
	return m


## UV transform that puts a picture of aspect `pic` on a surface of aspect
## `surf` without stretching. contain (cover=false): whole picture, bands
## around it (for label_fit: uv = (l - xy) / zw). cover=true: crop to fill
## (for tex_fit: uv = UV * zw + xy).
static func fit(pic: float, surf: float, cover: bool) -> Vector4:
	if cover:
		if pic > surf:
			var sx := surf / pic
			return Vector4((1.0 - sx) * 0.5, 0.0, sx, 1.0)
		var sy := pic / surf
		return Vector4(0.0, (1.0 - sy) * 0.5, 1.0, sy)
	if pic > surf:
		var h := surf / pic
		return Vector4(0.0, (1.0 - h) * 0.5, 1.0, h)
	var w := pic / surf
	return Vector4((1.0 - w) * 0.5, 0.0, w, 1.0)


static func mesh(m: Mesh, material: Material, pos := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.position = pos
	if parent != null:
		parent.add_child(mi)
	return mi


static func box(size: Vector3, material: Material, pos := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return mesh(b, material, pos, parent)


static func cyl(radius: float, height: float, material: Material, pos := Vector3.ZERO, parent: Node3D = null, sides: int = 12) -> MeshInstance3D:
	var c := CylinderMesh.new()
	c.top_radius = radius
	c.bottom_radius = radius
	c.height = height
	c.radial_segments = sides
	c.rings = 1
	return mesh(c, material, pos, parent)


## A flat picture facing +Z (or rotated by the caller).
static func quad(size: Vector2, material: Material, pos := Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = size
	return mesh(q, material, pos, parent)


## Loads res://assets/models/props/<name>.glb with every surface turned PSX.
## The result sits on y=0, centred in x/z, scaled so its height is `height`
## (or its widest side is `width` when width > 0).
static func prop(name: String, height: float = 0.0, tint := Color.WHITE, width: float = 0.0, texture: Texture2D = null) -> Node3D:
	# "temp:<name>" = a test-only model from assets/temp_test/models/.
	var path := ("res://assets/temp_test/models/%s.glb" % name.substr(5)) if name.begins_with("temp:") else "res://assets/models/props/%s.glb" % name
	if not _scenes.has(path):
		_scenes[path] = load(path) if ResourceLoader.exists(path) else null
	var holder := Node3D.new()
	holder.name = name
	var ps: PackedScene = _scenes[path]
	if ps == null:
		return holder
	var inner: Node3D = ps.instantiate()
	holder.add_child(inner)
	_convert(inner, tint, texture)
	var b := aabb(inner)
	if b.size == Vector3.ZERO:
		return holder
	var s := 1.0
	if width > 0.0:
		s = width / maxf(b.size.x, b.size.z)
	elif height > 0.0:
		s = height / b.size.y
	inner.scale *= s
	inner.position = -Vector3(b.get_center().x, b.position.y, b.get_center().z) * s
	return holder


static func _convert(n: Node, tint: Color, texture: Texture2D) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.mesh != null:
			for i in mi.mesh.get_surface_count():
				var src := mi.get_active_material(i)
				var col := Color.WHITE
				var t: Texture2D = texture
				if src is BaseMaterial3D:
					col = (src as BaseMaterial3D).albedo_color
					if t == null:
						t = (src as BaseMaterial3D).albedo_texture
				mi.set_surface_override_material(i, mat(col * tint, t))
	for c in n.get_children():
		_convert(c, tint, texture)


## A realistic person (Rocketbox avatar, rigged; see tools/bake_people.gd):
## body and head in the PSX look, hair cards alpha-cut. Returns the scene
## root; its Skeleton3D is animated by Stage (Walker).
static var _people: Dictionary = {}


static func person(name: String) -> Node3D:
	var base := "res://assets/models/people_rb/" + name
	if not _people.has(name):
		_people[name] = load(base + "_rig.scn") if ResourceLoader.exists(base + "_rig.scn") else null
	var ps: PackedScene = _people[name]
	if ps == null:
		return Node3D.new()
	var root: Node3D = ps.instantiate()
	var mi: MeshInstance3D = root.find_child("Body", true, false)
	if mi != null:
		var tex_names := ["body", "head", "opacity"]
		for i in mi.mesh.get_surface_count():
			var tn: String = tex_names[mini(i, 2)]
			var tp := "%s_%s.png" % [base, tn]
			var t: Texture2D = load(tp) if ResourceLoader.exists(tp) else null
			if tn == "opacity":
				var sm := StandardMaterial3D.new()
				sm.albedo_texture = t
				sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				sm.alpha_scissor_threshold = 0.5
				sm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
				sm.cull_mode = BaseMaterial3D.CULL_DISABLED
				sm.roughness = 1.0
				mi.set_surface_override_material(i, sm)
			else:
				mi.set_surface_override_material(i, mat(Color.WHITE, t))
	return root


## Multiplies the colour of every PSX surface under n (shop lights, moods).
static func tint_all(n: Node, t: Color) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for i in (mi.mesh.get_surface_count() if mi.mesh else 0):
			var m := mi.get_surface_override_material(i)
			if m is ShaderMaterial:
				var c = (m as ShaderMaterial).get_shader_parameter("albedo")
				if c is Color:
					(m as ShaderMaterial).set_shader_parameter("albedo", (c as Color) * t)
	for c in n.get_children():
		tint_all(c, t)


## Gives every mesh under n an ink outline (the cards' thick border, in 3D).
## Off on weak devices (it draws each mesh twice).
static func outline(n: Node, width: float = 1.4) -> void:
	if Lite.perf:
		return
	if _outline_mat == null or absf(float(_outline_mat.get_shader_parameter("width")) - width) > 0.01:
		_outline_mat = ShaderMaterial.new()
		_outline_mat.shader = OUTLINE
		_outline_mat.set_shader_parameter("width", width)
		_outline_mat.set_shader_parameter("snap", snap)
	_add_outline(n, _outline_mat)


static func _add_outline(n: Node, om: ShaderMaterial) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var mi := n as MeshInstance3D
		if mi.material_override is ShaderMaterial:
			(mi.material_override as ShaderMaterial).next_pass = om
		else:
			for i in mi.mesh.get_surface_count():
				var m := mi.get_surface_override_material(i)
				if m is ShaderMaterial:
					(m as ShaderMaterial).next_pass = om
	for c in n.get_children():
		_add_outline(c, om)


## Bounding box of every mesh under n, in n's parent space.
static func aabb(n: Node3D) -> AABB:
	var acc: Array = [null]
	_aabb(n, n.transform, acc)
	return acc[0] if acc[0] != null else AABB()


static func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var b: AABB = xf * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = b if acc[0] == null else (acc[0] as AABB).merge(b)
	for c in n.get_children():
		if c is Node3D:
			_aabb(c, xf * (c as Node3D).transform, acc)
