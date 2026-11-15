extends SceneTree
## Real 3D models for loose consoles and accessories (see tools/fetch_hw_models.py).
## Needs a renderer for the sheets: xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/bake_hw.gd -- MODE ...
##   nodes RAW.glb OUT.png      every mesh node on its own tile (pick `keep` indices, printed in order)
##   bake [FORM...]             tools/hw_models.json -> .cache/hw/split/<form>.glb (keep, drop, rotate)
##   items OUT.png [PAGE]       every loose catalog item that uses one, built by ItemModels (24 a page)
##   sheet OUT.png [FORM...]    the finished assets/temp_test/models/hw_<form>.glb, seen as in the game (front = +Z)

const CFG := "res://tools/hw_models.json"
const RAW := "res://.cache/hw/raw/%s.glb"
const SPLIT := "res://.cache/hw/split/%s.glb"
const OUT := "res://assets/temp_test/models/hw_%s.glb"
const TILE := 320

var vp: SubViewport
var cam: Camera3D


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var mode := a[0] if a.size() > 0 else ""
	match mode:
		"nodes":
			await _setup()
			await _nodes(a[1], a[2])
		"bake":
			_bake(a.slice(1))
		"sheet":
			await _setup()
			await _sheet(a[1], a.slice(2))
		"items":
			await _setup()
			await _items(a[1], int(a[2]) if a.size() > 2 else 0)
		_:
			print("usage: nodes RAW OUT.png | bake [FORM...] | sheet OUT.png [FORM...]")
	quit()


static func cfg() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(CFG))


func _load(path: String) -> Array:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(path), st) != OK:
		push_error("can't read " + path)
		return []
	return [doc.generate_scene(st), st]


## Every MeshInstance3D under n, in tree order (the indices `keep` / `drop` use).
func _mesh_nodes(n: Node, out: Array = []) -> Array:
	if n is MeshInstance3D:
		out.append(n)
	for ch in n.get_children():
		_mesh_nodes(ch, out)
	return out


func _bake(only: Array) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.cache/hw/split"))
	var c := cfg()
	for form in c:
		if only.size() > 0 and not only.has(form):
			continue
		var e: Dictionary = c[form]
		var r := _load(RAW % String(e["uid"]).substr(0, 8))
		if r.is_empty():
			continue
		var scene: Node3D = r[0]
		var keep: Array = e.get("keep", [])
		var drop: Array = e.get("drop", [])
		var ms := _mesh_nodes(scene)
		for i in ms.size():
			if (keep.size() > 0 and not keep.has(float(i))) or drop.has(float(i)):
				if ms[i].get_child_count() == 0:
					ms[i].free()
				else:
					(ms[i] as MeshInstance3D).mesh = null
		for m in _mesh_nodes(scene):
			_strip(m as MeshInstance3D)
		var root := Node3D.new()
		root.name = "hw_" + form
		var turn := Node3D.new()
		turn.name = "turn"
		var rot: Array = e.get("rot", [0, 0, 0])
		turn.rotation_degrees = Vector3(rot[0], rot[1], rot[2])
		root.add_child(turn)
		turn.add_child(scene)
		_own(scene, root)
		turn.owner = root
		var doc := GLTFDocument.new()
		var st2 := GLTFState.new()
		doc.append_from_scene(root, st2)
		var p := ProjectSettings.globalize_path(SPLIT % form)
		var err := doc.write_to_filesystem(st2, p)
		print("baked ", form, " -> ", p, " err ", err)
		root.free()


## The PSX shader only reads the colour map: drop normal / roughness / AO / emission maps.
func _strip(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	for i in mi.mesh.get_surface_count():
		var m := mi.mesh.surface_get_material(i)
		if m is BaseMaterial3D:
			var b := m as BaseMaterial3D
			b.normal_enabled = false
			b.normal_texture = null
			b.roughness_texture = null
			b.metallic_texture = null
			b.ao_enabled = false
			b.ao_texture = null
			b.emission_texture = null
			b.clearcoat_enabled = false
			b.rim_enabled = false
			b.heightmap_enabled = false
			b.heightmap_texture = null


func _own(n: Node, root: Node) -> void:
	for ch in n.get_children():
		_own(ch, root)
	n.owner = root


func _setup() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(TILE, TILE)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.56, 0.6)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.6)
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	vp.add_child(sun)
	cam = Camera3D.new()
	cam.fov = 40
	vp.add_child(cam)
	cam.current = true
	for w in 8:
		await process_frame


func _shot(n: Node3D, view: Vector3) -> Image:
	var box := _aabb(n, Transform3D.IDENTITY)
	var c := box.get_center()
	var r := maxf(box.size.length() * 0.5, 0.001)
	cam.near = r * 0.01
	cam.far = r * 50.0
	cam.position = c + view.normalized() * r / tan(deg_to_rad(20)) * 1.05
	cam.look_at(c)
	for f in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	return img


func _grid(imgs: Array, out: String) -> void:
	var cols := 4
	var rows := int(ceil(imgs.size() / float(cols)))
	var sheet := Image.create(TILE * cols, TILE * maxi(rows, 1), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.2, 0.2, 0.22))
	for i in imgs.size():
		sheet.blit_rect(imgs[i], Rect2i(0, 0, TILE, TILE), Vector2i((i % cols) * TILE, (i / cols) * TILE))
	sheet.save_png(out)


func _nodes(raw: String, out: String) -> void:
	var r := _load(raw)
	var scene: Node3D = r[0]
	vp.add_child(scene)
	var ms := _mesh_nodes(scene)
	var meshes := ms.map(func(m): return (m as MeshInstance3D).mesh)
	var imgs := []
	for i in ms.size():
		for j in ms.size():
			(ms[j] as MeshInstance3D).mesh = meshes[j] if j == i else null
		imgs.append(await _shot(scene, Vector3(0.7, 0.6, 1.0)))
		print(i, " = node ", ms[i].name)
	_grid(imgs, out)


func _sheet(out: String, only: Array) -> void:
	var imgs := []
	var c := cfg()
	for form in c:
		if only.size() > 0 and not only.has(form):
			continue
		var r := _load(OUT % form)
		if r.is_empty():
			continue
		var n: Node3D = r[0]
		vp.add_child(n)
		imgs.append(await _shot(n, Vector3(0.45, 0.5, 1.0)))
		var b := _aabb(n, Transform3D.IDENTITY)
		print(imgs.size() - 1, " = ", form, " size ", b.size)
		n.queue_free()
	_grid(imgs, out)


func _aabb(n: Node, t: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var tt := t
	if n is Node3D:
		tt = t * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out = tt * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for ch in n.get_children():
		var cb := _aabb(ch, tt)
		if cb.size != Vector3.ZERO:
			out = cb if first else out.merge(cb)
			first = false
	return out


func _items(out: String, page: int) -> void:
	var picks := []
	for d in Catalog.ITEMS:
		if ItemModels.hw_form(d) != "":
			picks.append(d)
	var imgs := []
	for d in picks.slice(page * 24, page * 24 + 24):
		var it: Dictionary = (d as Dictionary).duplicate()
		it["cond"] = "Loose"
		var n := ItemModels.build(it, null, 0)
		vp.add_child(n)
		imgs.append(await _shot(n, Vector3(0.45, 0.5, 1.0)))
		print(imgs.size() - 1, " = ", it["id"], " ", ItemModels.hw_form(it), " ", Psx.aabb(n).size)
		n.queue_free()
	print(picks.size(), " items use a real model")
	_grid(imgs, out)
