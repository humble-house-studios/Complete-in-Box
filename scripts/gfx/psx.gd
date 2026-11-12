class_name Psx
extends RefCounted
## PSX-look building blocks: one shader for every surface (vertex snap, nearest
## textures, distance fog), plus helpers that build boxes, cylinders and quads,
## and load the furniture models in assets/models/props with that look.

const SHADER := preload("res://assets/shaders/psx.gdshader")

## Fog applied to every material built after it is set (stage sets it per scene).
static var fog_color := Color(0.04, 0.03, 0.05)
static var fog_near := 4.0
static var fog_far := 14.0
static var snap := 120.0

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


static func label_mat(base: Texture2D, label: Texture2D, rect: Rect2, tint: Color) -> ShaderMaterial:
	var m := mat(Color.WHITE, base)
	m.set_shader_parameter("use_label", label != null)
	m.set_shader_parameter("label_tex", label)
	m.set_shader_parameter("label_rect", Vector4(rect.position.x, rect.position.y, rect.size.x, rect.size.y))
	m.set_shader_parameter("body_tint", tint)
	return m


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
	var path := "res://assets/models/props/%s.glb" % name
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
