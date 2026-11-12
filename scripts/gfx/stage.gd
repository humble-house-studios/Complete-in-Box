class_name Stage
extends SubViewportContainer
## The 3D world behind the UI: a grimy low-res room for every venue, with the
## items you can buy sitting on the table (or your own shelf at home). Renders
## at 1/3 resolution with nearest upscaling, then dither + vignette (post shader).
##
## game.gd calls show_scene(id, items) after each refresh (it only rebuilds when
## something changed) and set_focus() so the table lands in the gap it leaves
## between the header and the panels.

const POST := preload("res://assets/shaders/post.gdshader")
const FONT := preload("res://assets/fonts/Jersey10-Regular.ttf")
## Items are drawn a bit bigger than life so they read at low resolution.
const ITEM_SCALE := 1.7

var pixel := 3
var vp: SubViewport
var cam: Camera3D
var env: Environment
var world: Node3D
var scene_id := ""

var _key := ""
var _focus := 0.3
var _zoom := 1.0
var _look := Vector3.ZERO
var _cam_pos := Vector3(0, 1.4, 1.6)
var _fov := 50.0
var _items: Array = []
var _flicker: Array = []
var _spin: Array = []
var _swing: Array = []
var _t := 0.0
var _shake := 0.0


func _ready() -> void:
	stretch = true
	stretch_shrink = pixel
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := ShaderMaterial.new()
	m.shader = POST
	m.set_shader_parameter("pixel", float(pixel))
	material = m
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.positional_shadow_atlas_size = 0
	add_child(vp)
	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	we.environment = env
	vp.add_child(we)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.current = true
	vp.add_child(cam)


## Rebuilds the room only when the scene or its items changed.
func show_scene(id: String, items: Array = []) -> void:
	var bits: Array = [id]
	for it in items:
		bits.append("%s/%s" % [it.get("id", ""), it.get("cond", "")])
	var key := "|".join(bits)
	if key == _key:
		return
	_key = key
	scene_id = id
	# Headless runs (tests, CI) have no renderer: skip the 3D build.
	if DisplayServer.get_name() == "headless":
		return
	if world != null:
		vp.remove_child(world)
		world.queue_free()
	_items.clear()
	_flicker.clear()
	_spin.clear()
	_swing.clear()
	world = Node3D.new()
	vp.add_child(world)
	_build(id, items)


## Where the table should appear: 0 = top of the screen, 1 = bottom.
## zoom > 1 widens the view (fits the subject into a short window).
func set_focus(frac: float, zoom: float = 1.0) -> void:
	_focus = clampf(frac, 0.05, 0.95)
	_zoom = clampf(zoom, 0.5, 2.0)


func shake(amount: float = 1.0) -> void:
	_shake = maxf(_shake, amount)


## Bounce one of the scene's items (appraisal counting).
func pulse(i: int) -> void:
	if i < 0 or i >= _items.size():
		return
	var n: Node3D = _items[i]
	if not is_instance_valid(n):
		return
	var base: Vector3 = n.get_meta("base_scale", n.scale)
	n.set_meta("base_scale", base)
	var tw := create_tween()
	tw.tween_property(n, "scale", base * 1.35, 0.06)
	tw.tween_property(n, "scale", base, 0.14)


func item_count() -> int:
	return _items.size()


func _process(delta: float) -> void:
	_t += delta
	for f in _flicker:
		var node: Object = f[0]
		if not is_instance_valid(node):
			continue
		var base: float = f[1]
		var amt: float = f[2]
		var n := sin(_t * 13.0 + base * 7.0) * 0.5 + sin(_t * 31.0 + base) * 0.3
		var dip := 1.0
		if fmod(_t + base * 3.1, 5.3) < 0.08:
			dip = 0.35
		var v := base * (1.0 + n * amt) * dip
		if node is Light3D:
			(node as Light3D).light_energy = v
		elif node is ShaderMaterial:
			(node as ShaderMaterial).set_shader_parameter("emit", v)
	for s in _spin:
		if is_instance_valid(s):
			(s as Node3D).rotation.y += delta * 0.6
	for s in _swing:
		if is_instance_valid(s):
			(s as Node3D).rotation.z = sin(_t * 1.3) * 0.12
	_shake = maxf(0.0, _shake - delta * 3.0)
	_apply_cam()


func _apply_cam() -> void:
	if cam == null:
		return
	var sz := size
	if sz.x <= 0 or sz.y <= 0:
		return
	var aspect := sz.x / sz.y
	var portrait := aspect < 1.0
	var sway := Vector3(sin(_t * 0.31) * 0.03, sin(_t * 0.47) * 0.015, 0)
	# Phones see a narrow band: look down a bit more so back rows show.
	var raise := Vector3(0, 0.28, -0.1) if portrait else Vector3.ZERO
	cam.position = _cam_pos + sway + raise
	cam.look_at(_look + sway * 0.5)
	var near := 0.05
	var fov := minf((_fov + (14.0 if portrait else 0.0)) * _zoom, 100.0)
	cam.keep_aspect = Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
	var s := 2.0 * near * tan(deg_to_rad(fov * 0.5))
	var h := s / aspect if portrait else s
	var off := Vector2(0, (_focus - 0.5) * h)
	if _shake > 0.0:
		off += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * h * 0.02
	cam.set_frustum(s, off, near, 40.0)


# ================================================================ building blocks

func _setup(fog: Color, ambient: Color, ambient_energy: float = 1.0, near: float = 3.5, far: float = 11.0) -> void:
	env.background_color = fog
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	Psx.fog_color = fog
	Psx.fog_near = near
	Psx.fog_far = far
	Psx.snap = 110.0


func _view(pos: Vector3, look: Vector3, fov: float = 50.0) -> void:
	_cam_pos = pos
	_look = look
	_fov = fov


## Floor, back wall, side walls and a dark ceiling.
func _room(w: float, d: float, h: float, floor_tex: String, floor_tint: Color, wall_tex: String, wall_tint: Color, uv: float = 1.0) -> void:
	var fm := Psx.mat(floor_tint, Psx.tex(floor_tex), Vector2(w, d) * 0.7 * uv)
	var fl := Psx.quad(Vector2(w, d), fm, Vector3(0, 0, -d * 0.5 + 2.5), world)
	fl.rotation_degrees.x = -90.0
	var wm := Psx.mat(wall_tint, Psx.tex(wall_tex), Vector2(w, h) * 0.6 * uv)
	Psx.quad(Vector2(w, h), wm, Vector3(0, h * 0.5, -d + 2.5), world)
	for sx in [-1.0, 1.0]:
		var sm := Psx.mat(wall_tint.darkened(0.2), Psx.tex(wall_tex), Vector2(d, h) * 0.6 * uv)
		var sw := Psx.quad(Vector2(d, h), sm, Vector3(sx * w * 0.5, h * 0.5, -d * 0.5 + 2.5), world)
		sw.rotation_degrees.y = -90.0 * sx
	var cm := Psx.mat(Color(0.05, 0.045, 0.05))
	var ce := Psx.quad(Vector2(w, d), cm, Vector3(0, h, -d * 0.5 + 2.5), world)
	ce.rotation_degrees.x = 90.0


func _prop(name: String, pos: Vector3, rot_y: float = 0.0, height: float = 0.0, tint := Color.WHITE, width: float = 0.0, texture: Texture2D = null) -> Node3D:
	var p := Psx.prop(name, height, tint, width, texture)
	p.position = pos
	p.rotation_degrees.y = rot_y
	world.add_child(p)
	return p


func _light(pos: Vector3, color: Color, energy: float, rng: float, flicker: float = 0.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.2
	world.add_child(l)
	if flicker > 0.0:
		_flicker.append([l, energy, flicker])
	return l


func _spot(pos: Vector3, target: Vector3, color: Color, energy: float, angle: float = 30.0, rng: float = 6.0) -> SpotLight3D:
	var l := SpotLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.spot_angle = angle
	l.spot_range = rng
	world.add_child(l)
	l.position = pos
	l.look_at_from_position(pos, target, Vector3.UP if absf(pos.x - target.x) + absf(pos.z - target.z) > 0.01 else Vector3.FORWARD)
	return l


## A bare bulb on a cord that swings a little, with its light.
func _bulb(pos: Vector3, color: Color, energy: float, rng: float, ceiling: float, flicker: float = 0.08) -> void:
	var pivot := Node3D.new()
	pivot.position = Vector3(pos.x, ceiling, pos.z)
	world.add_child(pivot)
	var cord := ceiling - pos.y
	Psx.cyl(0.008, cord, Psx.mat(Color(0.05, 0.05, 0.05)), Vector3(0, -cord * 0.5, 0), pivot, 4)
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.1
	sm.radial_segments = 8
	sm.rings = 4
	var bm := Psx.mat(color, null, Vector2.ONE, 2.5)
	Psx.mesh(sm, bm, Vector3(0, -cord, 0), pivot)
	var shade := Psx.cyl(0.14, 0.08, Psx.mat(Color(0.12, 0.12, 0.1)), Vector3(0, -cord + 0.08, 0), pivot, 10)
	shade.scale = Vector3(1, 1, 1)
	var l := OmniLight3D.new()
	l.position = Vector3(0, -cord - 0.05, 0)
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.1
	pivot.add_child(l)
	_swing.append(pivot)
	if flicker > 0.0:
		_flicker.append([l, energy, flicker])


func _neon(text: String, pos: Vector3, color: Color, size: int = 64, rot_y: float = 0.0) -> void:
	var l := Label3D.new()
	l.text = text
	l.font = FONT
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = color.lightened(0.25)
	l.outline_modulate = color.darkened(0.3)
	l.outline_size = 10
	l.shaded = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	l.position = pos
	l.rotation_degrees.y = rot_y
	world.add_child(l)
	var g := _light(pos + Vector3(0, 0, 0.3), color, 1.2, 3.0, 0.15)
	g.shadow_enabled = false


func _crt(pos: Vector3, w: float, screen: Color, rot_y: float = 0.0) -> Node3D:
	var tv := Node3D.new()
	tv.position = pos
	tv.rotation_degrees.y = rot_y
	world.add_child(tv)
	var body := Psx.mat(Color(0.16, 0.15, 0.15))
	Psx.box(Vector3(w, w * 0.78, w * 0.85), body, Vector3(0, w * 0.39, 0), tv)
	var sm := Psx.mat(screen, null, Vector2.ONE, 1.4)
	Psx.quad(Vector2(w * 0.78, w * 0.56), sm, Vector3(-w * 0.04, w * 0.41, w * 0.426), tv)
	_flicker.append([sm, 1.4, 0.12])
	var l := OmniLight3D.new()
	l.position = Vector3(0, w * 0.4, w * 0.7)
	l.light_color = screen
	l.light_energy = 1.2
	l.omni_range = 2.0
	tv.add_child(l)
	_flicker.append([l, 1.2, 0.15])
	return tv


## Lays items out in rows on a surface centred at `center` (y = surface top).
func _lay_items(items: Array, center: Vector3, width: float, depth: float = 0.35, max_per_row: int = 5) -> void:
	var n := items.size()
	if n == 0:
		return
	var rows := int(ceil(float(n) / max_per_row))
	var per := int(ceil(float(n) / rows))
	for i in n:
		var r := i / per
		var c := i % per
		var in_row := mini(per, n - r * per)
		var x := center.x + (float(c) - (in_row - 1) * 0.5) * (width / maxf(per, 1))
		var z := center.z + (float(r) - (rows - 1) * 0.5) * -depth
		var m := ItemModels.build(items[i])
		m.scale = Vector3.ONE * ITEM_SCALE
		# Back rows stand on a riser so they peek over the front row.
		var lift := 0.0
		if r > 0:
			lift = 0.09 * r
			if c == 0:
				var riser := Psx.mat(Color(0.35, 0.28, 0.22), Psx.tex("wood092"), Vector2(3, 1))
				Psx.box(Vector3(width + 0.1, lift, depth * 0.8), riser, Vector3(center.x, center.y + lift * 0.5, z), world)
		m.position = Vector3(x, center.y + lift, z)
		m.rotation_degrees.y = sin(i * 2.7) * 12.0
		world.add_child(m)
		_items.append(m)


## A plain wooden shelf unit built from boards (so item heights are exact).
func _shelf_unit(pos: Vector3, w: float, levels: int, gap: float, tint := Color(0.75, 0.6, 0.45)) -> Array:
	var wood := Psx.mat(tint, Psx.tex("wood092"), Vector2(2, 1))
	var tops: Array = []
	var h := levels * gap + 0.08
	for sx in [-1.0, 1.0]:
		Psx.box(Vector3(0.05, h, 0.4), wood, pos + Vector3(sx * w * 0.5, h * 0.5, 0), world)
	Psx.box(Vector3(w, h, 0.02), Psx.mat(tint.darkened(0.45), Psx.tex("wood092")), pos + Vector3(0, h * 0.5, -0.2), world)
	for k in levels + 1:
		var y := 0.04 + k * gap
		Psx.box(Vector3(w, 0.04, 0.4), wood, pos + Vector3(0, y, 0), world)
		if k < levels:
			tops.append(pos.y + y + 0.02)
	return tops


## Fills a shelf with display stock (not interactive), deterministic per seed.
func _decor_stock(pos: Vector3, w: float, tops: Array, seed_value: int, per_level: int = 6, boxed: bool = true) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	for y in tops:
		for k in per_level:
			var d: Dictionary = Catalog.ITEMS[r.randi() % Catalog.ITEMS.size()]
			var it := d.duplicate()
			it["cond"] = "CIB" if boxed else "Loose"
			var m := ItemModels.build(it)
			m.scale = Vector3.ONE * ITEM_SCALE * 0.95
			m.position = Vector3(pos.x + (k - (per_level - 1) * 0.5) * (w / per_level), y, pos.z + r.randf_range(-0.03, 0.05))
			m.rotation_degrees.y = r.randf_range(-8, 8)
			world.add_child(m)


# ================================================================ scenes

func _build(id: String, items: Array) -> void:
	match id:
		"title": _title(items)
		"home", "appraisal": _home(items)
		"garage": _garage(items)
		"flea": _flea(items)
		"estate": _estate(items)
		"storage": _storage(items)
		"retro": _retro(items)
		"pawn": _pawn(items)
		"convention": _convention(items)
		"ebay": _online(items)
		"heritage": _heritage(items)
		_: _garage(items)


func _title(items: Array) -> void:
	_setup(Color(0.02, 0.015, 0.03), Color(0.25, 0.2, 0.3), 0.6, 2.5, 8.0)
	_room(6, 7, 3.0, "concrete047a", Color(0.55, 0.5, 0.5), "bricks105", Color(0.45, 0.35, 0.35))
	var ped := Psx.mat(Color(0.35, 0.12, 0.12), Psx.tex("fabric086"))
	Psx.cyl(0.38, 0.7, ped, Vector3(0, 0.35, 0), world, 14)
	Psx.cyl(0.42, 0.04, Psx.mat(Color(0.75, 0.6, 0.25), null, Vector2.ONE, 0.2), Vector3(0, 0.72, 0), world, 14)
	if not items.is_empty():
		var hero := ItemModels.build(items[0])
		hero.scale = Vector3.ONE * 3.6
		hero.position = Vector3(0, 0.74, 0)
		world.add_child(hero)
		_spin.append(hero)
		_items.append(hero)
	# Junk on the floor around it.
	for i in range(1, items.size()):
		var m := ItemModels.build(items[i])
		m.scale = Vector3.ONE * ITEM_SCALE
		var a := float(i) * 1.9
		m.position = Vector3(cos(a) * 1.0, 0, sin(a) * 0.6 - 0.2)
		m.rotation_degrees = Vector3(0, a * 40.0, 0)
		world.add_child(m)
	_prop("cardboardBoxOpen", Vector3(-1.3, 0, -0.8), 25, 0.5)
	_prop("cardboardBoxClosed", Vector3(1.4, 0, -0.6), -15, 0.45)
	_prop("cardboardBoxClosed", Vector3(1.35, 0.45, -0.6), 10, 0.35)
	_bulb(Vector3(0, 1.75, 0), Color(1.0, 0.78, 0.5), 3.2, 4.0, 3.0, 0.1)
	_spot(Vector3(0, 2.9, 1.2), Vector3(0, 0.9, 0), Color(0.9, 0.6, 1.0), 1.5, 22)
	_view(Vector3(0, 1.35, 2.1), Vector3(0, 1.0, 0), 44.0)


func _home(items: Array) -> void:
	_setup(Color(0.03, 0.025, 0.035), Color(0.35, 0.3, 0.4), 0.55, 3.0, 9.0)
	_room(5, 5.5, 2.7, "concrete034", Color(0.45, 0.42, 0.4), "bricks105", Color(0.5, 0.4, 0.38))
	var tops := _shelf_unit(Vector3(0, 0, -0.6), 2.0, 3, 0.48)
	tops.reverse()
	var per := maxi(4, int(ceil(items.size() / 3.0)))
	var level := 0
	var row: Array = []
	for i in items.size():
		row.append(items[i])
		if row.size() == per or i == items.size() - 1:
			_lay_items(row, Vector3(0, tops[mini(level, tops.size() - 1)], -0.58), 1.8, 0.3, per)
			row = []
			level += 1
	_prop("loungeSofa", Vector3(-1.9, 0, 0.5), 70, 0.0, Color(0.6, 0.35, 0.3), 1.6)
	_prop("lampRoundTable", Vector3(1.4, 0, -0.5), 0, 0.9)
	_crt(Vector3(1.5, 0.0, 0.6), 0.55, Color(0.4, 0.6, 1.0), -50)
	_prop("cardboardBoxOpen", Vector3(-1.3, 0, -0.9), 15, 0.4)
	_prop("rugRectangle", Vector3(0, 0.005, 0.8), 0, 0.0, Color(0.7, 0.4, 0.35), 2.2)
	_bulb(Vector3(0, 2.0, 0.4), Color(1.0, 0.75, 0.45), 2.6, 4.0, 2.7)
	_light(Vector3(1.4, 1.0, -0.4), Color(1.0, 0.8, 0.5), 0.8, 2.0)
	_view(Vector3(0, 1.45, 2.0), Vector3(0, 1.05, -0.6), 46.0)


func _garage(items: Array) -> void:
	_setup(Color(0.09, 0.05, 0.05), Color(0.45, 0.35, 0.35), 0.7, 3.5, 10.0)
	_room(6, 6, 2.8, "concrete034", Color(0.6, 0.57, 0.52), "paintedwood009c", Color(0.65, 0.6, 0.5))
	# Open garage door at the back: dusk outside.
	Psx.quad(Vector2(3.2, 2.0), Psx.mat(Color(0.95, 0.55, 0.35), null, Vector2.ONE, 1.6), Vector3(0, 1.0, -3.48), world)
	Psx.quad(Vector2(3.2, 0.6), Psx.mat(Color(0.35, 0.25, 0.45), null, Vector2.ONE, 1.2), Vector3(0, 2.3, -3.47), world)
	Psx.box(Vector3(3.3, 0.3, 0.1), Psx.mat(Color(0.7, 0.68, 0.62), Psx.tex("corrugatedsteel009")), Vector3(0, 2.6, -3.3), world)
	var table := _prop("tableCross", Vector3(0, 0, 0), 0, 0.0, Color.WHITE, 2.0)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.7, 0.32, 4)
	_prop("cardboardBoxOpen", Vector3(-1.6, 0, 0.4), 30, 0.45)
	_prop("cardboardBoxClosed", Vector3(1.7, 0, 0.3), -20, 0.5)
	_prop("cardboardBoxClosed", Vector3(1.65, 0.5, 0.3), 5, 0.4)
	_prop("bookcaseOpenLow", Vector3(-1.8, 0, -1.8), 20, 0.9)
	_prop("kitchenFridgeSmall", Vector3(2.2, 0, -2.0), -30, 1.0)
	_prop("trashcan", Vector3(1.2, 0, -2.6), 0, 0.7)
	_prop("radio", Vector3(-1.8, 0.9, -1.8), 20, 0.25)
	_bulb(Vector3(0, 1.85, 0.1), Color(1.0, 0.78, 0.5), 2.8, 4.5, 2.8)
	_light(Vector3(0, 1.0, -3.0), Color(1.0, 0.55, 0.3), 1.5, 4.0)
	_view(Vector3(0, 1.45, 1.75), Vector3(0, 0.85, -0.05))


func _flea(items: Array) -> void:
	_setup(Color(0.04, 0.04, 0.09), Color(0.3, 0.3, 0.5), 0.7, 3.0, 11.0)
	_room(8, 8, 4.0, "concrete047a", Color(0.45, 0.45, 0.48), "bricks105", Color(0.35, 0.3, 0.35))
	# Canopy over the stall.
	var tarp := Psx.mat(Color(0.75, 0.2, 0.2), Psx.tex("fabric028"), Vector2(2, 1))
	var roof := Psx.box(Vector3(2.8, 0.04, 1.6), tarp, Vector3(0, 2.2, -0.1), world)
	roof.rotation_degrees.x = 8.0
	for x in [-1.35, 1.35]:
		for z in [-0.8, 0.6]:
			Psx.cyl(0.025, 2.2, Psx.mat(Color(0.6, 0.6, 0.62)), Vector3(x, 1.1, z), world, 6)
	var table := _prop("tableCloth", Vector3(0, 0, 0), 0, 0.0, Color(1, 1, 1), 2.1)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.8, 0.32, 4)
	# Other stalls in the dark.
	for i in 3:
		var x := -2.6 + i * 2.6
		var t := _prop("tableCross", Vector3(x, 0, -2.6), 0, 0.0, Color(0.8, 0.8, 0.8), 1.6)
		_prop("cardboardBoxOpen", Vector3(x + 0.3, _top(t), -2.6), 15 * i, 0.35)
	# String lights.
	for k in 9:
		var x := -2.0 + k * 0.5
		var y := 2.15 - sin(float(k) / 8.0 * PI) * 0.25
		var c: Color = [Color(1, 0.8, 0.4), Color(1, 0.4, 0.4), Color(0.5, 0.8, 1)][k % 3]
		Psx.cyl(0.035, 0.07, Psx.mat(c, null, Vector2.ONE, 3.0), Vector3(x, y, 0.75), world, 6)
	_light(Vector3(0, 1.9, 0.6), Color(1.0, 0.8, 0.55), 2.4, 4.0, 0.06)
	_light(Vector3(-2.5, 1.5, -2.2), Color(0.5, 0.6, 1.0), 1.0, 3.0)
	_light(Vector3(2.5, 1.5, -2.2), Color(1.0, 0.5, 0.4), 1.0, 3.0)
	_view(Vector3(0, 1.5, 1.8), Vector3(0, 0.85, -0.05))


func _estate(items: Array) -> void:
	_setup(Color(0.05, 0.04, 0.03), Color(0.4, 0.35, 0.3), 0.6, 3.5, 10.0)
	_room(6, 6, 2.8, "woodfloor043", Color(0.8, 0.7, 0.6), "wallpaper001a", Color(0.45, 0.55, 0.42))
	var table := _prop("table", Vector3(0, 0, 0), 0, 0.0, Color(0.8, 0.6, 0.45), 1.9)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.6, 0.32, 4)
	_prop("couch", Vector3(-1.8, 0, -1.6), 25, 0.0, Color(0.6, 0.45, 0.5), 1.7)
	_prop("bookcase", Vector3(1.6, 0, -2.4), -10, 1.9)
	_prop("frame", Vector3(-0.4, 1.4, -3.45), 0, 0.0, Color.WHITE, 0.8)
	_prop("coatRackStanding", Vector3(2.3, 0, -0.6), 0, 1.7)
	_prop("lampRoundTable", Vector3(-1.0, 0, -2.6), 0, 1.2)
	_prop("rugRectangle", Vector3(0, 0.005, 0.2), 90, 0.0, Color(0.6, 0.3, 0.3), 2.6)
	# Dusty sheet over something.
	var sheet := Psx.box(Vector3(1.0, 0.9, 0.7), Psx.mat(Color(0.85, 0.84, 0.8), Psx.tex("fabric086")), Vector3(0.4, 0.45, -2.6), world)
	sheet.rotation_degrees.y = 12.0
	_bulb(Vector3(0, 1.9, 0.05), Color(1.0, 0.72, 0.45), 2.2, 4.0, 2.8, 0.05)
	_light(Vector3(-1.0, 1.3, -2.4), Color(1.0, 0.8, 0.5), 0.9, 2.5)
	_spot(Vector3(2.8, 2.4, 0.5), Vector3(0, 0.5, -1), Color(0.5, 0.65, 1.0), 1.2, 35)
	_view(Vector3(0, 1.45, 1.75), Vector3(0, 0.85, -0.05))


func _storage(items: Array) -> void:
	_setup(Color(0.02, 0.025, 0.03), Color(0.3, 0.33, 0.38), 0.45, 2.5, 8.0)
	_room(4.2, 6, 2.6, "concrete047a", Color(0.5, 0.5, 0.5), "corrugatedsteel009", Color(0.55, 0.58, 0.62), 1.5)
	# The roll-up door, half open overhead.
	Psx.box(Vector3(4.2, 0.5, 0.1), Psx.mat(Color(0.7, 0.45, 0.2), Psx.tex("corrugatedsteel009"), Vector2(3, 1)), Vector3(0, 2.4, 2.2), world)
	for i in 4:
		var c := _prop("crate", Vector3(-1.4 + (i % 2) * 0.62, (i / 2) * 0.62, -1.9), i * 7, 0.6, Color.WHITE, 0.0, load("res://assets/models/props/crate_tex.png"))
		c.rotation_degrees.y = i * 9.0
	_prop("MetalShelving", Vector3(1.5, 0, -2.3), 0, 1.9, Color(0.55, 0.55, 0.6))
	_prop("StorageTub", Vector3(1.2, 0, -0.9), -20, 0.45, Color(0.3, 0.4, 0.6))
	_prop("loungeSofa", Vector3(-1.4, 0, -0.6), 80, 0.0, Color(0.4, 0.4, 0.3), 1.4)
	# The lots: closed boxes on a pallet, or the items if they're known.
	Psx.box(Vector3(1.6, 0.14, 1.0), Psx.mat(Color(0.7, 0.6, 0.45), Psx.tex("wood092"), Vector2(3, 1)), Vector3(0, 0.07, 0.2), world)
	if items.is_empty():
		for i in 3:
			var b := _prop("cardboardBoxClosed", Vector3(-0.5 + i * 0.5, 0.14, 0.2), i * 13.0 - 10.0, 0.42)
			_items.append(b)
	else:
		_lay_items(items, Vector3(0, 0.14, 0.2), 1.4, 0.35, 4)
	_spot(Vector3(0.3, 2.5, 1.6), Vector3(0, 0.2, 0.0), Color(1.0, 0.95, 0.8), 4.0, 26)
	_light(Vector3(0, 2.4, -1.0), Color(0.75, 0.9, 1.0), 1.4, 4.0, 0.3)
	_view(Vector3(0, 1.55, 2.0), Vector3(0, 0.45, -0.1))


func _retro(items: Array) -> void:
	_setup(Color(0.05, 0.03, 0.07), Color(0.4, 0.35, 0.5), 0.7, 3.5, 11.0)
	_room(6, 6, 2.8, "tiles139", Color(0.6, 0.55, 0.6), "bricks105", Color(0.45, 0.38, 0.45), 1.3)
	for i in 3:
		var x := -1.9 + i * 1.9
		var tops := _shelf_unit(Vector3(x, 0, -3.1), 1.7, 4, 0.42, Color(0.55, 0.45, 0.4))
		_decor_stock(Vector3(x, 0, -3.05), 1.7, tops, 100 + i)
	# Glass counter.
	Psx.box(Vector3(2.4, 0.9, 0.7), Psx.mat(Color(0.25, 0.22, 0.28), Psx.tex("metalplates006")), Vector3(0, 0.45, 0), world)
	Psx.box(Vector3(2.45, 0.04, 0.75), Psx.mat(Color(0.55, 0.75, 0.8), null, Vector2.ONE, 0.3), Vector3(0, 0.92, 0), world)
	_lay_items(items, Vector3(0, 0.94, 0.0), 2.0, 0.3, 4)
	_crt(Vector3(-1.5, 0.94, -0.1), 0.45, Color(0.5, 0.9, 0.6), 25)
	_neon("GAMES", Vector3(1.2, 2.1, -2.6), Color(1.0, 0.3, 0.7), 96)
	_neon("BUY  SELL  TRADE", Vector3(-1.3, 2.25, -2.6), Color(0.3, 0.8, 1.0), 40)
	_light(Vector3(0, 2.6, 0.2), Color(0.95, 0.95, 1.0), 2.2, 4.0, 0.05)
	_light(Vector3(0, 2.2, -2.2), Color(1.0, 0.85, 0.75), 1.4, 3.5)
	_view(Vector3(0, 1.55, 1.8), Vector3(0, 0.95, -0.1))


func _pawn(items: Array) -> void:
	_setup(Color(0.04, 0.045, 0.035), Color(0.4, 0.42, 0.35), 0.6, 3.5, 10.0)
	_room(6, 6, 2.8, "concrete034", Color(0.55, 0.55, 0.5), "plaster001", Color(0.6, 0.6, 0.45))
	_prop("MetalShelving", Vector3(-1.8, 0, -2.8), 0, 2.0, Color(0.5, 0.5, 0.55))
	_prop("MetalShelving", Vector3(1.8, 0, -2.8), 0, 2.0, Color(0.5, 0.5, 0.55))
	_prop("radio", Vector3(-1.8, 1.02, -2.7), 10, 0.3)
	_prop("speaker", Vector3(1.6, 0, -2.0), -20, 1.0)
	_prop("lampRoundTable", Vector3(2.0, 0.98, -2.7), 0, 0.5)
	_crt(Vector3(-2.0, 0.5, -2.7), 0.4, Color(0.6, 0.7, 0.9))
	# Barred window on the back wall.
	Psx.quad(Vector2(1.4, 0.9), Psx.mat(Color(0.3, 0.45, 0.7), null, Vector2.ONE, 0.9), Vector3(0, 1.6, -3.48), world)
	for k in 7:
		Psx.cyl(0.02, 0.95, Psx.mat(Color(0.2, 0.2, 0.2)), Vector3(-0.6 + k * 0.2, 1.6, -3.42), world, 4)
	Psx.box(Vector3(2.4, 0.95, 0.7), Psx.mat(Color(0.55, 0.45, 0.35), Psx.tex("wood092")), Vector3(0, 0.475, 0), world)
	Psx.box(Vector3(2.45, 0.04, 0.75), Psx.mat(Color(0.5, 0.7, 0.75), null, Vector2.ONE, 0.2), Vector3(0, 0.97, 0), world)
	_lay_items(items, Vector3(0, 0.99, 0.0), 2.0, 0.3, 4)
	_neon("PAWN", Vector3(0, 2.35, -3.3), Color(1.0, 0.85, 0.2), 110)
	_light(Vector3(0, 2.5, 0.3), Color(0.85, 1.0, 0.85), 2.2, 4.5, 0.25)
	_view(Vector3(0, 1.55, 1.8), Vector3(0, 0.95, -0.1))


func _convention(items: Array) -> void:
	_setup(Color(0.05, 0.03, 0.08), Color(0.45, 0.35, 0.55), 0.8, 4.0, 13.0)
	_room(9, 9, 4.5, "carpet012", Color(0.5, 0.5, 0.7), "plaster001", Color(0.3, 0.25, 0.4), 1.4)
	var table := _prop("tableCloth", Vector3(0, 0, 0), 0, 0.0, Color(0.6, 0.6, 1.0), 2.2)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.9, 0.32, 4)
	# Booth backdrop + banner.
	Psx.box(Vector3(3.0, 2.2, 0.05), Psx.mat(Color(0.2, 0.15, 0.35), Psx.tex("fabric086")), Vector3(0, 1.1, -1.2), world)
	_neon("COLLECTOR CON", Vector3(0, 1.85, -1.15), Color(1.0, 0.4, 0.75), 70)
	for i in 2:
		var x := -3.0 + i * 6.0
		var t := _prop("tableCloth", Vector3(x, 0, -3.0), 0, 0.0, Color(0.8, 0.6, 0.6), 1.8)
		var tops := [_top(t)]
		_decor_stock(Vector3(x, 0, -3.0), 1.6, tops, 300 + i, 4, true)
	_spot(Vector3(-1.5, 3.5, 1.5), Vector3(0, 0.8, 0), Color(1.0, 0.5, 0.85), 3.0, 28, 8.0)
	_spot(Vector3(1.5, 3.5, 1.5), Vector3(0, 0.8, 0), Color(0.5, 0.7, 1.0), 3.0, 28, 8.0)
	_light(Vector3(0, 3.0, -2.5), Color(0.8, 0.7, 1.0), 1.5, 6.0)
	_view(Vector3(0, 1.5, 1.85), Vector3(0, 0.85, -0.1))


func _online(items: Array) -> void:
	_setup(Color(0.015, 0.02, 0.04), Color(0.2, 0.25, 0.45), 0.5, 2.5, 8.0)
	_room(4.5, 5, 2.6, "carpet016", Color(0.35, 0.33, 0.4), "wallpaper001c", Color(0.25, 0.28, 0.4))
	var desk := _prop("desk", Vector3(0, 0, -0.2), 180, 0.0, Color(0.6, 0.5, 0.45), 2.0)
	var top := _top(desk)
	_crt(Vector3(0, top, -0.5), 0.6, Color(0.4, 0.6, 1.0))
	var l := Label3D.new()
	l.text = "eBuy" if scene_id == "ebay" else "LOT 0451"
	l.font = FONT
	l.font_size = 48
	l.pixel_size = 0.004
	l.shaded = false
	l.modulate = Color(1, 1, 0.6)
	l.position = Vector3(-0.02, top + 0.3, -0.23)
	world.add_child(l)
	_lay_items(items, Vector3(0, top, 0.05), 1.7, 0.3, 5)
	_prop("chairDesk", Vector3(0.9, 0, 0.9), 200, 0.9)
	_prop("frame", Vector3(-1.2, 1.5, -2.45), 0, 0.0, Color(1, 1, 1), 0.7)
	_prop("pottedPlant", Vector3(-1.7, 0, -1.6), 0, 0.8)
	_prop("cardboardBoxClosed", Vector3(1.6, 0, -1.4), 30, 0.45)
	_prop("cardboardBoxClosed", Vector3(1.6, 0.45, -1.4), 10, 0.35)
	_light(Vector3(1.4, 1.7, 0.4), Color(1.0, 0.7, 0.4), 0.8, 3.0)
	_view(Vector3(0, 1.4, 1.5), Vector3(0, top + 0.1, -0.2))


func _heritage(items: Array) -> void:
	_setup(Color(0.04, 0.015, 0.02), Color(0.4, 0.25, 0.25), 0.55, 3.5, 11.0)
	_room(7, 7, 3.4, "woodfloor051", Color(0.8, 0.65, 0.55), "wallpaper001a", Color(0.55, 0.15, 0.18))
	var velvet := Psx.mat(Color(0.5, 0.08, 0.12), Psx.tex("fabric086"))
	var gold := Psx.mat(Color(0.95, 0.75, 0.3), null, Vector2.ONE, 0.25)
	Psx.box(Vector3(2.2, 0.85, 0.8), velvet, Vector3(0, 0.425, 0), world)
	Psx.box(Vector3(2.3, 0.04, 0.9), gold, Vector3(0, 0.87, 0), world)
	_lay_items(items, Vector3(0, 0.89, 0.0), 1.9, 0.32, 4)
	# Rope line.
	for x in [-1.6, 1.6]:
		Psx.cyl(0.04, 0.9, gold, Vector3(x, 0.45, 0.8), world, 8)
	var rope := Psx.cyl(0.02, 3.2, velvet, Vector3(0, 0.8, 0.8), world, 6)
	rope.rotation_degrees.z = 90.0
	# Podium.
	Psx.box(Vector3(0.6, 1.1, 0.5), Psx.mat(Color(0.5, 0.35, 0.25), Psx.tex("wood092")), Vector3(2.0, 0.55, -1.6), world)
	_prop("frame", Vector3(-1.4, 1.7, -3.45), 0, 0.0, Color(1, 0.9, 0.6), 1.0)
	_prop("frame", Vector3(1.0, 1.7, -3.45), 0, 0.0, Color(1, 0.9, 0.6), 0.8)
	_neon("HERITAGE", Vector3(0, 2.7, -3.3), Color(1.0, 0.8, 0.4), 80)
	_spot(Vector3(0, 3.2, 1.0), Vector3(0, 0.9, 0), Color(1.0, 0.85, 0.6), 5.0, 26, 6.0)
	_light(Vector3(0, 2.6, -2.5), Color(1.0, 0.6, 0.4), 1.2, 5.0)
	_view(Vector3(0, 1.5, 1.85), Vector3(0, 0.9, -0.05))


## Height of a placed prop's top surface (for laying items on it).
func _top(n: Node3D) -> float:
	return Psx.aabb(n).end.y
