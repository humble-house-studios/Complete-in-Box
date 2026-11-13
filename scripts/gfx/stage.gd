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

var pixel := 2
var vp: SubViewport
var cam: Camera3D
var env: Environment
var world: Node3D
var scene_id := ""

var _key := ""
var _focus := 0.3
var _zoom := 1.0
## Your Wall finds, shown on the living room's second shelf.
var wall_items: Array = []
## The lose ending (scene "cursed"): grade, condition and labels for your case.
var case_info: Dictionary = {}
## The title vault's covered case: empty = still under its dust sheet (the
## twist stays hidden); after your first loss it holds your last sealed self.
var vault_case: Dictionary = {}
## The other collectors' cases in the title vault, one per estate:
## [{who, name, freed, grade}]. Freed collectors leave an open, empty case.
var collector_cases: Array = []
var _shelf_view: Array = []
var _home_view: Array = []
## Landscape centre-strip layout: look down onto the table like phones do.
var look_down := false
var _look := Vector3.ZERO
var _cam_pos := Vector3(0, 1.4, 1.6)
var _fov := 50.0
var _items: Array = []
var _flicker: Array = []
var _spin: Array = []
var _swing: Array = []
var _t := 0.0
var _shake := 0.0
## Cinematic camera (intro): when on, the camera follows these instead.
var cine_on := false
var cine_pos := Vector3.ZERO
var cine_look := Vector3.ZERO
var cine_fov := 50.0
var _sweep: Array = []
var _cine_look_s := Vector3.ZERO


func _ready() -> void:
	stretch = true
	stretch_shrink = pixel
	if Lite.perf:
		# Big TV screens: keep the 3D render around 360 px tall.
		var h := float(DisplayServer.window_get_size().y)
		if get_window() != null and get_window().content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT:
			h = get_viewport().get_visible_rect().size.y
		stretch_shrink = maxi(pixel, int(ceil(h / 360.0)))
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
	var bits: Array = [id, wall_items.size(), case_info.hash() if id == "cursed" else (vault_case.hash() if id == "title" else 0)]
	for it in items:
		bits.append("%s/%s" % [it.get("id", ""), it.get("cond", "")])
	var key := "|".join(bits)
	if key == _key:
		return
	_key = key
	scene_id = id
	# Headless runs (tests, CI) have no renderer: skip the 3D build.
	if DisplayServer.get_name() == "headless" or Lite.no3d:
		return
	if world != null:
		vp.remove_child(world)
		world.queue_free()
	_items.clear()
	_sweep.clear()
	_flicker.clear()
	_spin.clear()
	_swing.clear()
	_breathe.clear()
	_walkers.clear()
	_sel = null
	_sel_item = null
	_bounds = Rect2(-4, -5, 8, 7)
	world = Node3D.new()
	vp.add_child(world)
	_build(id, items)
	_motes()
	if Lite.perf:
		_trim_lights(4)
		mark_dirty(8)


## Dust in the light: slow warm specks drifting where the camera looks, so
## every room feels lived in. Skipped on weak devices.
func _motes() -> void:
	if Lite.perf or scene_id == "ebay":
		return
	var p := CPUParticles3D.new()
	p.amount = 46
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.8, 0.9, 1.0)
	p.direction = Vector3(0.2, 1, 0)
	p.spread = 60.0
	p.gravity = Vector3(0, -0.01, 0)
	p.initial_velocity_min = 0.01
	p.initial_velocity_max = 0.05
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var q := QuadMesh.new()
	q.size = Vector2(0.012, 0.012)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = Color(1.0, 0.85, 0.55, 0.55)
	q.material = m
	p.mesh = q
	p.position = _look + Vector3(0, 0.7, -0.3)
	world.add_child(p)


## Weak devices: keep only the strongest few lamps (each one costs every draw).
func _trim_lights(keep: int) -> void:
	var lamps: Array = []
	_collect_lamps(world, lamps)
	lamps.sort_custom(func(a, b): return a.light_energy > b.light_energy)
	for i in range(keep, lamps.size()):
		var l: Light3D = lamps[i]
		l.visible = false
		for f in _flicker.duplicate():
			if f[0] == l:
				_flicker.erase(f)
	for k in range(1, _sweep.size()):
		(_sweep[k] as Node3D).visible = false


func _collect_lamps(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is OmniLight3D or c is SpotLight3D:
			out.append(c)
		_collect_lamps(c, out)


## Where the table should appear: 0 = top of the screen, 1 = bottom.
## zoom > 1 widens the view (fits the subject into a short window).
func set_focus(frac: float, zoom: float = 1.0) -> void:
	_focus = clampf(frac, 0.05, 0.95)
	_zoom = clampf(zoom, 0.5, 2.0)


func shake(amount: float = 1.0) -> void:
	_shake = maxf(_shake, amount)


## Bounce one of the scene's items (appraisal counting).
func pulse(i: int) -> void:
	mark_dirty(12)
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


## The title hero box (first item), for the intro's drop.
func hero() -> Node3D:
	return _items[0] if not _items.is_empty() else null


func item_count() -> int:
	return _items.size()


## Weak devices (Lite.perf): the room is "pre-rendered". It only redraws for
## a few frames after something changes (new room, camera aim, shake), a
## couple of times a second to pick up finished box art, and every frame
## while the intro camera flies. Spinning/flickering decor holds still.
var _dirty := 8
var _redraw_t := 0.0
var _last_focus := Vector2(-1, -1)


func mark_dirty(frames: int = 6) -> void:
	_dirty = maxi(_dirty, frames)


func _perf_update(delta: float) -> void:
	var f := Vector2(_focus, _zoom)
	if f != _last_focus or _shake > 0.0:
		_last_focus = f
		mark_dirty(4)
	_redraw_t += delta
	if _redraw_t > 0.5:
		_redraw_t = 0.0
		mark_dirty(1)
	if cine_on or _dirty > 0:
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_dirty -= 1
	else:
		vp.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _process(delta: float) -> void:
	_t += delta
	if Lite.perf and vp != null:
		_perf_update(delta)
		if not cine_on:
			_shake = maxf(0.0, _shake - delta * 3.0)
			_apply_cam()
			return
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
			(s as Node3D).rotation.y += delta * 0.22
	if not _walkers.is_empty():
		_walk_update(delta)
	_sel_update()
	for b in _breathe:
		if is_instance_valid(b[0]):
			(b[0] as Node3D).scale.y = float(b[1]) * (1.0 + sin(_t * 1.6 + float(b[2])) * 0.006)
	for s in _swing:
		if is_instance_valid(s):
			(s as Node3D).rotation.z = sin(_t * 1.3) * 0.12
	for k in _sweep.size():
		var sp: Node3D = _sweep[k]
		if is_instance_valid(sp):
			sp.rotation.y = sin(_t * 0.25 + k * 2.1) * 0.6
			sp.rotation.x = -1.0 + sin(_t * 0.33 + k) * 0.25
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
	# Camera holds still: idle sway made every vertex snap back and forth.
	var sway := Vector3.ZERO
	# Phones see a narrow band: look down a bit more so back rows show.
	var raise := Vector3(0, 0.28, -0.1) if portrait else (Vector3(0, 0.42, -0.25) if look_down else Vector3.ZERO)
	var fov := minf((_fov + (14.0 if portrait else 0.0)) * _zoom, 100.0)
	if cine_on:
		cam.position = cam.position.lerp(cine_pos, 0.35)
		_cine_look_s = _cine_look_s.lerp(cine_look, 0.2)
		cam.look_at(_cine_look_s)
		fov = cine_fov + (16.0 if portrait else 0.0)
	elif room_on:
		# First person: stand at room_eye, look along yaw / pitch.
		cam.position = room_eye
		cam.rotation = Vector3(room_pitch, room_yaw, 0.0)
		fov = clampf((fov + 8.0) * room_zoom, 25.0, 100.0)
	else:
		cam.position = _cam_pos + sway + raise
		cam.look_at(_look + sway * 0.5)
	var near := 0.05
	cam.keep_aspect = Camera3D.KEEP_WIDTH if portrait else Camera3D.KEEP_HEIGHT
	var s := 2.0 * near * tan(deg_to_rad(fov * 0.5))
	var h := s / aspect if portrait else s
	var off := Vector2(0, (_focus - 0.5) * h)
	if _shake > 0.0:
		off += Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * h * 0.02
	cam.set_frustum(s, off, near, 90.0)


# ================================================================ world building

## sky = background/fog colour (horizon). Brighter defaults than the first pass.
func _setup(fog: Color, ambient: Color, ambient_energy: float = 1.0, near: float = 6.0, far: float = 24.0) -> void:
	env.background_color = fog
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	Psx.fog_color = fog
	Psx.fog_near = near
	Psx.fog_far = far
	Psx.snap = 700.0


func _view(pos: Vector3, look: Vector3, fov: float = 50.0) -> void:
	_cam_pos = pos
	_look = look
	_fov = fov


## Sunlight with hard PSX-style shadows. rot = degrees (pitch, yaw).
func _sun(pitch: float, yaw: float, color: Color, energy: float, shadows: bool = true) -> DirectionalLight3D:
	var d := DirectionalLight3D.new()
	d.rotation_degrees = Vector3(pitch, yaw, 0)
	d.light_color = color
	d.light_energy = energy
	d.shadow_enabled = shadows and not Lite.perf
	d.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	d.directional_shadow_max_distance = 16.0
	d.shadow_bias = 0.06
	world.add_child(d)
	return d


## A big gradient backdrop far away (never fogged).
func _sky(z: float, w: float, h: float, top: Color, horizon: Color, y0: float = -2.0) -> void:
	var g := Gradient.new()
	g.set_color(0, top)
	g.set_color(1, horizon)
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	gt.width = 4
	gt.height = 64
	var m := Psx.mat(Color.WHITE, gt, Vector2.ONE, 1.0)
	m.set_shader_parameter("fog_near", 1000.0)
	m.set_shader_parameter("fog_far", 2000.0)
	m.set_shader_parameter("albedo", Color(0.0, 0.0, 0.0))
	Psx.quad(Vector2(w, h), m, Vector3(0, y0 + h * 0.5, z), world)


func _ground(tex: String, tint: Color, size: Vector2, center: Vector3, uv: float = 0.5) -> MeshInstance3D:
	var g := Psx.quad(size, Psx.mat(tint, Psx.tex(tex), size * uv), center, world)
	g.rotation_degrees.x = -90.0
	return g


## Floor, walls (back wall can have a hole: x centre, bottom, width, height),
## ceiling, baseboards. Back wall sits at z = 2.5 - d.
func _room(w: float, d: float, h: float, floor_tex: String, floor_tint: Color, wall_tex: String, wall_tint: Color, uv: float = 1.0, hole := Rect2(), ceiling := Color(0.55, 0.52, 0.5)) -> void:
	var zc := -d * 0.5 + 2.5
	var zb := 2.5 - d
	_bounds = Rect2(-w * 0.5 + 0.4, zb + 0.4, w - 0.8, 2.4 - (zb + 0.4))
	_ground(floor_tex, floor_tint, Vector2(w, d), Vector3(0, 0, zc), 0.7 * uv)
	var tx := Psx.tex(wall_tex)
	if hole.size == Vector2.ZERO:
		Psx.quad(Vector2(w, h), Psx.mat(wall_tint, tx, Vector2(w, h) * 0.6 * uv), Vector3(0, h * 0.5, zb), world)
	else:
		var hx0 := hole.position.x - hole.size.x * 0.5
		var hx1 := hole.position.x + hole.size.x * 0.5
		var hy0 := hole.position.y
		var hy1 := hole.position.y + hole.size.y
		var parts := [
			Rect2(-w * 0.5, 0, hx0 + w * 0.5, h),
			Rect2(hx1, 0, w * 0.5 - hx1, h),
			Rect2(hx0, hy1, hx1 - hx0, h - hy1),
			Rect2(hx0, 0, hx1 - hx0, hy0),
		]
		for r in parts:
			if r.size.x <= 0.01 or r.size.y <= 0.01:
				continue
			Psx.quad(r.size, Psx.mat(wall_tint, tx, r.size * 0.6 * uv), Vector3(r.position.x + r.size.x * 0.5, r.position.y + r.size.y * 0.5, zb), world)
		# Frame around the opening.
		var fr := Psx.mat(Color(0.85, 0.82, 0.75))
		Psx.box(Vector3(hole.size.x + 0.12, 0.08, 0.14), fr, Vector3(hole.position.x, hy1, zb), world)
		if hy0 > 0.05:
			Psx.box(Vector3(hole.size.x + 0.12, 0.06, 0.2), fr, Vector3(hole.position.x, hy0, zb), world)
		for x in [hx0, hx1]:
			Psx.box(Vector3(0.08, hole.size.y, 0.14), fr, Vector3(x, hy0 + hole.size.y * 0.5, zb), world)
	for sx in [-1.0, 1.0]:
		var sw := Psx.quad(Vector2(d, h), Psx.mat(wall_tint.darkened(0.12), tx, Vector2(d, h) * 0.6 * uv), Vector3(sx * w * 0.5, h * 0.5, zc), world)
		sw.rotation_degrees.y = -90.0 * sx
		Psx.box(Vector3(0.03, 0.12, d), Psx.mat(Color(0.3, 0.25, 0.22)), Vector3(sx * (w * 0.5 - 0.015), 0.06, zc), world)
	Psx.box(Vector3(w, 0.12, 0.03), Psx.mat(Color(0.3, 0.25, 0.22)), Vector3(0, 0.06, zb + 0.015), world)
	var ce := Psx.quad(Vector2(w, d), Psx.mat(ceiling, Psx.tex("plaster001"), Vector2(w, d) * 0.5), Vector3(0, h, zc), world)
	ce.rotation_degrees.x = 90.0


## Mullions for a window hole.
func _window_bars(hole: Rect2, z: float, cols: int = 2, rows: int = 2) -> void:
	var fr := Psx.mat(Color(0.85, 0.82, 0.75))
	for k in range(1, cols):
		var x := hole.position.x - hole.size.x * 0.5 + hole.size.x * k / cols
		Psx.box(Vector3(0.05, hole.size.y, 0.06), fr, Vector3(x, hole.position.y + hole.size.y * 0.5, z), world)
	for k in range(1, rows):
		Psx.box(Vector3(hole.size.x, 0.05, 0.06), fr, Vector3(hole.position.x, hole.position.y + hole.size.y * k / rows, z), world)


## A framed poster showing an item's box art.
func _poster(pos: Vector3, rot_y: float, size: Vector2, id: String) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = rot_y
	world.add_child(n)
	var art := Art.front(Catalog.get_def(id))
	# Keep the poster's height; its width follows the box art (no stretching).
	size.x = size.y * float(art.get_width()) / maxf(1.0, art.get_height())
	Psx.box(Vector3(size.x + 0.08, size.y + 0.08, 0.03), Psx.mat(Color(0.12, 0.1, 0.1)), Vector3.ZERO, n)
	Psx.quad(size, Psx.mat(Color(1.1, 1.1, 1.1), art), Vector3(0, 0, 0.018), n)


func _poster_ids(seed_value: int, n: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var out: Array = []
	var pool := _decor_pool()
	for k in n:
		out.append(String(pool[r.randi() % pool.size()]["id"]))
	return out


## Shopkeeper / shopper (Kenney mini-market character), tinted.
## Shopkeepers and shoppers: realistic Rocketbox people (baked by
## tools/bake_people.gd), picked by spot so a room keeps its cast, breathing
## gently. `who` picks someone specific (e.g. "business_male_02").
const PEOPLE := ["male_adult_01", "male_adult_03", "male_adult_05", "male_adult_08", "male_adult_11", "male_adult_14", "male_adult_17",
	"female_adult_01", "female_adult_03", "female_adult_05", "female_adult_08", "female_adult_11", "female_adult_14"]
var _breathe: Array = []


func _person(pos: Vector3, rot_y: float, tint := Color.WHITE, h: float = 1.45, who: String = "", _anim: String = "") -> Node3D:
	var pick := who
	if pick == "" or not ResourceLoader.exists("res://assets/models/people_rb/%s_rig.scn" % pick):
		pick = String(PEOPLE[absi(hash(Vector2i(int(pos.x * 10.0), int(pos.z * 10.0)))) % PEOPLE.size()])
	var n := Psx.person(pick)
	n.scale = Vector3.ONE * (h / 1.45) * 0.86
	n.position = pos
	n.rotation_degrees.y = rot_y
	world.add_child(n)
	if tint != Color.WHITE:
		Psx.tint_all(n, Color.WHITE.lerp(tint, 0.15))
	Psx.outline(n, 1.0)
	var w := _rig(n)
	_pose(w, 0.0, 0.0, "", 0.0)
	_breathe.append([n, n.scale.y, absf(pos.x * 1.7 + pos.z)])
	return n


# ---------------------------------------------------------------- walkers

## People who move: customers wandering between spots and browsing, the
## manager pacing between counter and shelves to restock, tidy and wipe.
## Rocketbox skeletons are posed in code (no animation clips): a walk cycle
## (legs, knees, arm swing, hip bob) and a few chores. Off in Lite.perf.
var _walkers: Array = []

const ARM_DOWN := 40.0
const ARM_IN := 3.0


func _rig(n: Node3D) -> Dictionary:
	var sk: Skeleton3D = n.find_child("Skeleton3D", true, false)
	var w := {"node": n, "sk": sk, "b": {}, "rest": {}}
	if sk == null:
		return w
	for nm in ["L Thigh", "R Thigh", "L Calf", "R Calf", "L UpperArm", "R UpperArm", "L Forearm", "R Forearm", "Spine1", "Head", "Neck"]:
		var b := sk.find_bone("Bip01 " + nm)
		if b >= 0:
			w["b"][nm] = b
			w["rest"][nm] = sk.get_bone_pose_rotation(b)
	return w


func _rot(w: Dictionary, nm: String, q: Quaternion) -> void:
	if not w["b"].has(nm):
		return
	(w["sk"] as Skeleton3D).set_bone_pose_rotation(w["b"][nm], (w["rest"][nm] as Quaternion) * q)


## walk: 0..1 how much of the walk cycle, ph its phase; act: chore name, at: its clock.
func _pose(w: Dictionary, ph: float, walk: float, act: String, at: float) -> void:
	if w["sk"] == null:
		return
	var s := sin(ph)
	for side in ["L", "R"]:
		var sg := 1.0 if side == "L" else -1.0
		var leg := s * sg
		_rot(w, side + " Thigh", Quaternion(Vector3.BACK, deg_to_rad(26.0 * leg * walk)))
		var knee := maxf(0.0, -sin(ph + (0.0 if side == "L" else PI) - 0.6)) * 38.0 * walk
		_rot(w, side + " Calf", Quaternion(Vector3.BACK, deg_to_rad(-knee)))
		# Arms swing against the leg on the same side (+Z = back).
		var swing := 16.0 * leg * walk
		var lift := 0.0
		var bend := 12.0
		if act == "reach" and side == "R":
			lift = 70.0 + sin(at * 2.2) * 8.0
			bend = 25.0
		elif act == "restock" and side == "R":
			lift = 45.0 + absf(sin(at * 1.6)) * 55.0
			bend = 40.0 - absf(sin(at * 1.6)) * 30.0
		elif act == "wipe" and side == "R":
			lift = 38.0
			bend = 55.0 + sin(at * 5.0) * 18.0
			swing = sin(at * 5.0) * 10.0
		elif act == "talk":
			lift = (10.0 + sin(at * 2.6 + sg) * 12.0) if side == "R" else 0.0
			bend = 50.0 if side == "R" else 12.0
		var down := Quaternion(Vector3.UP, deg_to_rad(ARM_DOWN * sg)) * Quaternion(Vector3.BACK, deg_to_rad(ARM_IN + swing - lift))
		_rot(w, side + " UpperArm", down)
		_rot(w, side + " Forearm", Quaternion(Vector3.UP, deg_to_rad(-bend)))
	var look := 0.0
	var nod := 0.0
	if act == "browse":
		look = sin(at * 0.7) * 25.0
		nod = 12.0
	elif act == "reach" or act == "restock":
		nod = -6.0
	_rot(w, "Head", Quaternion(Vector3.RIGHT, deg_to_rad(look)) * Quaternion(Vector3.BACK, deg_to_rad(-nod)))
	_rot(w, "Spine1", Quaternion(Vector3.RIGHT, deg_to_rad(s * 4.0 * walk)))


## A walker following `path` (looping), pausing at each point to do `acts`
## (one per point: "browse", "reach", "restock", "wipe", "talk", "").
func _walker(path: Array, acts: Array, who: String = "", speed: float = 0.55, h: float = 1.45) -> void:
	if path.is_empty():
		return
	var n := _person(path[0], 0.0, Color.WHITE, h, who)
	_breathe.pop_back()
	if Lite.perf:
		# Weak devices draw the room once: stand them at their first chore.
		if path.size() > 1:
			var d0: Vector3 = (path[1] as Vector3) - (path[0] as Vector3)
			n.rotation.y = atan2(d0.x, d0.z)
		return
	var w := _rig(n)
	w["path"] = path
	w["acts"] = acts
	w["seg"] = 0
	w["pos"] = path[0]
	w["speed"] = speed * randf_range(0.85, 1.15)
	w["pause"] = randf_range(0.5, 3.0)
	w["ph"] = randf() * TAU
	w["at"] = 0.0
	w["walk"] = 0.0
	w["base_y"] = (path[0] as Vector3).y
	_walkers.append(w)


func _walk_update(delta: float) -> void:
	for w in _walkers:
		var n: Node3D = w["node"]
		if not is_instance_valid(n):
			continue
		var path: Array = w["path"]
		var seg := int(w["seg"])
		var entry = (w["acts"] as Array)[seg % (w["acts"] as Array).size()] if not (w["acts"] as Array).is_empty() else ""
		var act := ""
		var face := INF
		if entry is Array:
			act = String(entry[0])
			face = deg_to_rad(float(entry[1]))
		else:
			act = String(entry)
		var walk_goal := 0.0
		if float(w["pause"]) > 0.0:
			w["pause"] = float(w["pause"]) - delta
			w["at"] = float(w["at"]) + delta
			if face != INF:
				n.rotation.y = lerp_angle(n.rotation.y, face, minf(1.0, delta * 4.0))
		else:
			act = ""
			var target: Vector3 = path[(seg + 1) % path.size()]
			var pos: Vector3 = w["pos"]
			var to := target - pos
			to.y = 0.0
			var dist := to.length()
			if dist < 0.05:
				w["seg"] = (seg + 1) % path.size()
				seg = int(w["seg"])
				w["pause"] = randf_range(2.5, 6.0)
				w["at"] = 0.0
			else:
				walk_goal = 1.0
				var step := minf(dist, float(w["speed"]) * delta)
				pos += to / dist * step
				w["pos"] = pos
				w["ph"] = float(w["ph"]) + step * 5.2
				var yaw := atan2(to.x, to.z)
				n.rotation.y = lerp_angle(n.rotation.y, yaw, minf(1.0, delta * 6.0))
		# At a chore: face the point's facing (stored as the next point's direction).
		w["walk"] = lerpf(float(w["walk"]), walk_goal, minf(1.0, delta * 5.0))
		var p: Vector3 = w["pos"]
		n.position = Vector3(p.x, float(w["base_y"]) + absf(cos(float(w["ph"]))) * 0.025 * float(w["walk"]), p.z)
		_pose(w, float(w["ph"]), float(w["walk"]), act, float(w["at"]))


## Loops one of a model's own animations, started at `offset` seconds.
func _animate(n: Node, anim: String, offset: float = 0.0) -> void:
	var aps := n.find_children("*", "AnimationPlayer", true, false)
	if aps.is_empty():
		return
	var ap := aps[0] as AnimationPlayer
	if not ap.has_animation(anim):
		return
	var a := ap.get_animation(anim)
	a.loop_mode = Animation.LOOP_LINEAR
	ap.play(anim)
	ap.seek(fmod(offset, maxf(a.length, 0.01)), true)


## Fluorescent ceiling panel with its light.
func _panel_light(pos: Vector3, energy: float = 1.6, color := Color(0.95, 0.97, 1.0), rng: float = 5.0, flicker: float = 0.0) -> void:
	var m := Psx.mat(color, null, Vector2.ONE, 2.0)
	Psx.box(Vector3(1.2, 0.05, 0.3), m, pos, world)
	_light(pos + Vector3(0, -0.3, 0), color, energy, rng, flicker)


## Street outside: sidewalk, road, houses across it, trees, parked cars.
func _street(z: float, seed_value: int, houses: bool = true) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	_ground("pavingstones070", Color(0.85, 0.83, 0.8), Vector2(40, 3), Vector3(0, 0.01, z - 1.5), 0.6)
	_ground("asphalt012", Color(0.6, 0.6, 0.62), Vector2(40, 7), Vector3(0, 0.0, z - 6.5), 0.25)
	for k in 7:
		Psx.box(Vector3(1.2, 0.01, 0.15), Psx.mat(Color(0.95, 0.85, 0.3)), Vector3(-15 + k * 5, 0.015, z - 6.5), world)
	_ground("pavingstones070", Color(0.85, 0.83, 0.8), Vector2(40, 3), Vector3(0, 0.01, z - 11.5), 0.6)
	_ground("grass004", Color(0.8, 0.95, 0.7), Vector2(40, 14), Vector3(0, 0.0, z - 20), 0.4)
	var cars := ["car/sedan", "car/suv", "car/van", "car/hatchback-sports", "car/taxi", "car/delivery"]
	for k in 3:
		var x := -8.0 + k * 7.0 + r.randf_range(-1, 1)
		_prop(cars[r.randi() % cars.size()], Vector3(x, 0, z - 4.6 - (k % 2) * 3.8), 90.0 if k % 2 == 0 else -90.0, 0.0, Color.WHITE, 4.2)
	if houses:
		var types := ["a", "b", "c", "d", "e", "f"]
		for k in 5:
			var x := -12.0 + k * 6.0
			_prop("suburb/building-type-" + types[r.randi() % types.size()], Vector3(x, 0, z - 17.5), 180.0, 0.0, Color.WHITE, 6.0)
			_prop("suburb/fence-1x3", Vector3(x + 2.0, 0, z - 13.4), 0.0, 0.0, Color.WHITE, 3.0)
	for k in 6:
		var x := -14.0 + k * 5.5 + r.randf_range(-1, 1)
		var trees := ["nature/tree_oak_dark", "nature/tree_detailed", "nature/tree_default", "suburb/tree-large"]
		_prop(trees[r.randi() % trees.size()], Vector3(x, 0, z - 12.6 - r.randf_range(0, 2)), r.randf_range(0, 360), r.randf_range(4.0, 6.0), Color(0.75, 1.0, 0.7))


func _skyline(z: float, seed_value: int, tint := Color(0.55, 0.6, 0.75), lit: bool = false) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var types := ["a", "b", "c", "d", "e"]
	for k in 9:
		var p := _prop("city/low-detail-building-" + types[r.randi() % types.size()], Vector3(-20 + k * 5.0 + r.randf_range(-1, 1), 0, z - r.randf_range(0, 6)), r.randf_range(0, 360), r.randf_range(9, 20), tint)
		if lit:
			var b := Psx.aabb(p)
			for i in 8:
				var wm := Psx.mat(Color(1.0, 0.85, 0.5), null, Vector2.ONE, 2.0)
				wm.set_shader_parameter("fog_near", 1000.0)
				wm.set_shader_parameter("fog_far", 2000.0)
				var wp := Vector3(r.randf_range(b.position.x + 0.4, b.end.x - 0.4), r.randf_range(1.5, b.end.y - 1.0), b.end.z + 0.05)
				Psx.box(Vector3(0.6, 0.4, 0.05), wm, wp, world)




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


## Card and coin venues reuse the game rooms' shells with their own signs.
const SIGNS := {
	"cardshow": {"COLLECTOR CON": "CARD SHOW"},
	"tradenight": {"GAMES": "TRADE NIGHT", "BUY  SELL  TRADE": "THURSDAYS 6PM"},
	"cardshop": {"GAMES": "CARDS", "BUY  SELL  TRADE": "SINGLES  SLABS  SEALED"},
	"coinshow": {"COLLECTOR CON": "COIN SHOW"},
	"coinshop": {"PAWN": "COINS & BULLION"},
	"coinauction": {"HERITAGE": "STAX & TOWERS"},
	"dugout": {"GAMES": "THE DUGOUT", "BUY  SELL  TRADE": "WAX  SLABS  SINGLES"},
	"ballroom": {"COLLECTOR CON": "SUNDAY CARD SHOW"},
	"comiccon": {"COLLECTOR CON": "COMIC CON"},
}


## The catalog this room's decor comes from (cards in card shops...).
func _decor_pool() -> Array:
	var m := Venues.market(scene_id) if Venues.get_def(scene_id).size() > 0 else "games"
	return Catalog.items_of(m)


func _neon(text: String, pos: Vector3, color: Color, size: int = 64, rot_y: float = 0.0) -> void:
	text = String((SIGNS.get(scene_id, {}) as Dictionary).get(text, text))
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
	_display_mat(center, width + 0.24, depth * rows + 0.2)
	center.y += 0.012
	for i in n:
		var r := i / per
		var c := i % per
		var in_row := mini(per, n - r * per)
		var x := center.x + (float(c) - (in_row - 1) * 0.5) * (width / maxf(per, 1))
		var z := center.z + (float(r) - (rows - 1) * 0.5) * -depth
		var m := ItemModels.build(items[i])
		# Cards and coins are tiny at real size: show them a bit bigger on the mat.
		m.scale = Vector3.ONE * ITEM_SCALE * (1.7 if Catalog.is_cc(items[i]) else 1.0)
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
		m.set_meta("uid", int((items[i] as Dictionary).get("uid", -1)))
		Psx.outline(m)
		_tier_glow(items[i], Vector3(x, center.y + lift, z), m)
		_items.append(m)


## The card look on the table: a dark felt mat with a gold trim and a thick
## front edge, like the panels and cards in the menus.
func _display_mat(center: Vector3, w: float, d: float) -> void:
	var felt := Psx.mat(Color(0.2, 0.14, 0.3), Psx.tex("fabric061"), Vector2(w * 2.0, d * 2.0))
	Psx.box(Vector3(w, 0.012, d), felt, center + Vector3(0, 0.006, 0), world)
	var gold := Psx.mat(Color(1.0, 0.78, 0.3), null, Vector2.ONE, 0.35)
	for sz in [-1.0, 1.0]:
		Psx.box(Vector3(w, 0.016, 0.022), gold, center + Vector3(0, 0.008, sz * d * 0.5), world)
		Psx.box(Vector3(0.022, 0.016, d), gold, center + Vector3(sz * w * 0.5, 0.008, 0), world)
	# Thick front lip, like a card's coloured edge.
	Psx.box(Vector3(w + 0.03, 0.03, 0.05), Psx.mat(Color(0.95, 0.55, 0.2), null, Vector2.ONE, 0.25), center + Vector3(0, 0.0, d * 0.5 + 0.02), world)


## Rare and grail items sit in a glowing ring in their tier colour (the cards'
## tier frames), gently pulsing.
func _tier_glow(item: Dictionary, at: Vector3, m: Node3D) -> void:
	var tier := int(item.get("tier", 0))
	if tier < 2:
		return
	var b := Psx.aabb(m)
	var r := maxf(b.size.x, b.size.z) * 0.62 + 0.04
	var col: Color = Catalog.TIER_COLORS[clampi(tier, 0, 3)]
	var gm := Psx.mat(col, null, Vector2.ONE, 1.6)
	Psx.cyl(r, 0.006, gm, at + Vector3(0, 0.002, 0), world, 20)
	Psx.cyl(r * 0.82, 0.007, Psx.mat(Color(0.12, 0.08, 0.18)), at + Vector3(0, 0.003, 0), world, 20)
	_flicker.append([gm, 1.6, 0.25])


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
		var pool := _decor_pool()
		for k in per_level:
			var d: Dictionary = pool[r.randi() % pool.size()]
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
		"cardshow", "coinshow": _convention(items)
		"tradenight": _retro(items)
		"cardshop": _tcgshop(items)
		"tcgmarket": _online(items)
		"coinshop": _pawn(items)
		"coinauction": _heritage(items)
		"beach": _beach(items)
		"ballroom": _ballroom(items)
		"shoebox": _garage(items)
		"dugout": _retro(items)
		"breaks": _online(items)
		"comicshop": _comicshop(items)
		"comiccon": _convention(items)
		"atticfind": _estate(items)
		"comicauction": _online(items)
		"cursed": _cursed(items)
		_: _garage(items)


## The Ramadoh hotel ballroom on a Sunday: a card show. Patterned carpet,
## chandeliers, rows of dealer tables with glass cases of slabs, dime boxes,
## team pennants, a stage at the back and Grandma Rose's case on a dealer's
## table marked NOT FOR SALE (open and empty once you've freed her).
func _ballroom(items: Array) -> void:
	_setup(Color(0.18, 0.1, 0.08), Color(0.85, 0.7, 0.6), 1.15, 8.0, 26.0)
	_room(14, 12, 4.4, "carpet012", Color(0.85, 0.32, 0.3), "wallpaper001a", Color(0.85, 0.72, 0.5), 1.6, Rect2(), Color(0.55, 0.45, 0.35))
	# Your dealer's table at the front: navy skirt, felt mat, a dime box and a binder.
	var table := _prop("tableCloth", Vector3(0, 0, 0), 0, 0.0, Color(0.35, 0.4, 0.8), 2.2)
	var top := _top(table)
	_lay_items(items, Vector3(0, top, 0.0), 1.9, 0.32, 4)
	_prop("temp:cardboard_box_01", Vector3(-1.0, top, -0.25), 15, 0.22)
	_prop("temp:binder_notebook", Vector3(1.0, top, -0.2), -20, 0.06)
	Psx.box(Vector3(0.36, 0.1, 0.002), Psx.mat(Color(1.0, 0.85, 0.2)), Vector3(-1.0, top + 0.26, -0.12), world)
	var dime := Label3D.new()
	dime.text = "DIME BOX 10¢"
	dime.font = FONT
	dime.font_size = 30
	dime.pixel_size = 0.0035
	dime.modulate = Color(0.15, 0.08, 0.05)
	dime.outline_size = 0
	dime.shaded = false
	dime.position = Vector3(-1.0, top + 0.26, -0.115)
	world.add_child(dime)
	_person(Vector3(1.25, 0, -0.85), -15, Color(1.0, 0.92, 0.85), 1.45, "male_adult_11")
	# The banner over the stage.
	Psx.box(Vector3(4.6, 0.9, 0.05), Psx.mat(Color(0.12, 0.25, 0.55), Psx.tex("fabric086")), Vector3(0, 3.2, -5.9), world)
	_neon("COLLECTOR CON", Vector3(0, 3.2, -5.85), Color(1.0, 0.85, 0.35), 76)
	# The stage: a low platform, red curtains, a podium with a mic.
	Psx.box(Vector3(6.0, 0.35, 1.6), Psx.mat(Color(0.35, 0.22, 0.15), Psx.tex("planks012"), Vector2(4, 1)), Vector3(0, 0.175, -5.2), world)
	for x in [-2.6, 2.6]:
		Psx.box(Vector3(1.4, 3.6, 0.08), Psx.mat(Color(0.6, 0.06, 0.1), Psx.tex("fabric061"), Vector2(2, 3)), Vector3(x, 2.15, -5.95), world)
	Psx.box(Vector3(0.5, 1.0, 0.4), Psx.mat(Color(0.3, 0.18, 0.12), Psx.tex("wood066")), Vector3(0.0, 0.85, -5.0), world)
	Psx.cyl(0.012, 0.4, Psx.mat(Color(0.15, 0.15, 0.15)), Vector3(0.0, 1.55, -5.0), world, 6)
	# Dealer rows: skirted tables with glass display cases of slabs.
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var glass := _glass()
	for row in 2:
		for i in 3:
			var x := -4.4 + i * 4.4
			var z := -2.4 - row * 1.9
			var t := _prop("tableCloth", Vector3(x, 0, z), 0, 0.0, [Color(0.35, 0.4, 0.8), Color(0.25, 0.3, 0.45), Color(0.7, 0.2, 0.25)][(i + row) % 3], 2.0)
			var ty := _top(t)
			_decor_stock(Vector3(x, 0, z), 1.6, [ty], 700 + row * 3 + i, 5, true)
			var case_box := Psx.box(Vector3(1.8, 0.28, 0.5), glass, Vector3(x, ty + 0.14, z), world)
			case_box.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_person(Vector3(x + r.randf_range(-0.6, 0.6), 0, z - 0.55), 0, Color.from_hsv(r.randf(), 0.25, 1.0), 1.45, String(PEOPLE[(row * 3 + i * 2) % PEOPLE.size()]))
	# Team pennants all along the side walls.
	for side in [-1.0, 1.0]:
		for k in 6:
			var pc := Color.from_hsv(r.randf(), 0.7, 0.85)
			var pen := Node3D.new()
			pen.position = Vector3(side * 6.95, 2.6, -5.0 + k * 1.6)
			pen.rotation_degrees.y = -90.0 * side
			world.add_child(pen)
			var pm := Psx.mat(pc)
			var tri := ArrayMesh.new()
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for v in [Vector3(-0.35, 0.18, 0), Vector3(0.45, 0, 0), Vector3(-0.35, -0.18, 0)]:
				st.add_vertex(v)
			tri = st.commit()
			var mi := MeshInstance3D.new()
			mi.mesh = tri
			mi.material_override = pm
			pen.add_child(mi)
	# Grandma Rose's case on the side table: NOT FOR SALE.
	var rose: Dictionary = {}
	for c in collector_cases:
		if String(c.get("name", "")) == "Grandma Rose":
			rose = c
	var holder := world
	var croot := Node3D.new()
	croot.position = Vector3(4.6, 0, -0.6)
	croot.rotation_degrees.y = -35.0
	croot.scale = Vector3.ONE * 0.8
	holder.add_child(croot)
	world = croot
	if bool(rose.get("freed", false)):
		_open_case(Vector3.ZERO, "Grandma Rose")
	else:
		_grade_case(Vector3.ZERO, "female_adult_14", {"grade": "9.6", "cond": "NEAR MINT", "lot": "#0003", "name": "GRANDMA ROSE",
			"ante": "NOT FOR SALE", "label": "GCA SPORTS", "case": "slab"}, false)
	world = holder
	_spot(Vector3(4.0, 3.6, 0.6), Vector3(4.6, 1.0, -0.6), Color(1.0, 0.9, 0.75), 3.0, 24, 7.0)
	# Chandeliers: real models with warm light under each.
	for x in [-4.0, 0.0, 4.0]:
		for z in [-1.5, -4.2]:
			_prop("temp:lantern_chandelier_01", Vector3(x, 3.4, z), 0, 0.9)
			_light(Vector3(x, 3.1, z), Color(1.0, 0.82, 0.55), 1.8, 6.0, 0.03)
	for x in [-6.2, 6.2]:
		_prop("shop/column", Vector3(x, 0, -3.0), 0, 4.4)
	# Collectors doing laps of the aisles.
	for k in 3:
		var zl := -1.2 - k * 1.0
		_walker([Vector3(-6.0 + k, 0, zl), Vector3(-2.0, 0, zl - 0.3), Vector3(2.0, 0, zl), Vector3(6.0 - k, 0, zl - 0.2)], ["", ["browse", 180], ["browse", 180], ""], String(PEOPLE[(k * 4 + 1) % PEOPLE.size()]), 0.5)
	_spot(Vector3(0, 3.6, 1.5), Vector3(0, 0.8, 0), Color(1.0, 0.9, 0.75), 3.2, 30, 8.0)
	_view(Vector3(0, 1.5, 1.85), Vector3(0, 0.85, -0.1))


## A few real catalog items (as display stock) standing on a shelf row.
func _decor_row(pool: Array, center: Vector3, w: float, n: int, seed_value: int, cond := "CIB", sc := 0.95) -> void:
	if pool.is_empty():
		return
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	for k in n:
		var it: Dictionary = pool[r.randi() % pool.size()].duplicate()
		it["cond"] = cond
		var m := ItemModels.build(it)
		m.scale = Vector3.ONE * ITEM_SCALE * sc
		m.position = center + Vector3((k - (n - 1) * 0.5) * (w / n), 0, r.randf_range(-0.02, 0.03))
		m.rotation_degrees.y = r.randf_range(-6, 6)
		world.add_child(m)


## The card shop (TCG): a floor-to-ceiling wall of sealed booster boxes, a
## grading counter with a loupe lamp and a slab station, glass cases of slabs,
## play tables with mats, and the Pruitt Twins' two cases side by side.
func _tcgshop(items: Array) -> void:
	_setup(Color(0.1, 0.09, 0.16), Color(0.75, 0.72, 0.85), 1.2, 7.0, 22.0)
	_room(9, 7.5, 3.2, "woodfloor051", Color(0.85, 0.8, 0.75), "plaster001", Color(0.55, 0.62, 0.8), 1.3, Rect2(), Color(0.55, 0.55, 0.6))
	var pool := Catalog.items_of("cards")
	var boxes := pool.filter(func(d): return String(d["kind"]) == "pack")
	var singles := pool.filter(func(d): return String(d["kind"]) == "card")
	# The sealed wall: four wide shelf units packed with booster boxes.
	for i in 3:
		var x := -3.0 + i * 3.0
		var tops := _shelf_unit(Vector3(x, 0, -3.6), 2.8, 5, 0.42, Color(0.25, 0.22, 0.3))
		for k in tops.size():
			_decor_row(boxes, Vector3(x, tops[k], -3.55), 2.6, 6, 400 + i * 10 + k, "Mint", 1.2)
	_neon("SEALED", Vector3(-1.6, 2.95, -3.9), Color(1.0, 0.85, 0.3), 60)
	_neon("GRADING  ON  SITE", Vector3(1.8, 2.95, -3.9), Color(0.4, 0.9, 1.0), 40)
	# The front glass counter: your table's items on top, slabs inside.
	Psx.box(Vector3(2.8, 0.9, 0.7), Psx.mat(Color(0.2, 0.2, 0.28), Psx.tex("metalplates006")), Vector3(0, 0.45, 0), world)
	Psx.box(Vector3(2.85, 0.04, 0.75), Psx.mat(Color(0.6, 0.85, 0.9), null, Vector2.ONE, 0.35), Vector3(0, 0.92, 0), world)
	_lay_items(items, Vector3(-0.2, 0.94, 0.0), 1.9, 0.3, 4)
	_prop("shop/cash-register", Vector3(1.15, 0.94, -0.1), -20, 0.35)
	# The grading counter on the right: lamp, loupe, a stack of slabs.
	var gc := Vector3(3.0, 0, -1.6)
	Psx.box(Vector3(0.7, 0.95, 1.8), Psx.mat(Color(0.3, 0.3, 0.36), Psx.tex("metalplates006")), gc + Vector3(0, 0.475, 0), world)
	Psx.box(Vector3(0.75, 0.04, 1.85), Psx.mat(Color(0.9, 0.9, 0.92)), gc + Vector3(0, 0.97, 0), world)
	_prop("lampRoundTable", gc + Vector3(0.1, 0.99, -0.6), -90, 0.45)
	var slabbed := singles.slice(0, 40)
	var r := RandomNumberGenerator.new()
	r.seed = 91
	for k in 5:
		var it: Dictionary = slabbed[r.randi() % slabbed.size()].duplicate()
		it["cond"] = "Mint"
		it["grade"] = 9 + r.randi() % 2
		var m := ItemModels.build(it)
		m.scale = Vector3.ONE * ITEM_SCALE * 0.9
		m.position = gc + Vector3(0.05, 0.99, -0.2 + k * 0.17)
		m.rotation_degrees = Vector3(-70, -90, 0)
		world.add_child(m)
	_neon("GRADING", gc + Vector3(-0.35, 2.2, 0), Color(0.4, 0.9, 1.0), 48, -90)
	_person(gc + Vector3(0.6, 0, 0.2), -90, Color(0.95, 0.95, 1.0), 1.45, "male_adult_17")
	# A play table with mats and two players mid-game.
	for tp in [Vector3(0.6, 0, -2.0)]:
		var t := _prop("table", tp, 0, 0.0, Color(0.5, 0.45, 0.4), 1.6)
		var ty := _top(t)
		Psx.box(Vector3(1.4, 0.005, 0.55), Psx.mat(Color(0.2, 0.25, 0.55), Psx.tex("fabric086")), tp + Vector3(0, ty, 0), world)
		_decor_row(singles, tp + Vector3(0, ty + 0.005, 0), 1.2, 4, 77, "Loose", 0.7)
		_person(tp + Vector3(0, 0, -0.6), 0, Color.WHITE, 1.4, "male_adult_03")
		_person(tp + Vector3(0, 0, 0.6), 180, Color.WHITE, 1.4, "female_adult_03")
	# The Pruitt Twins: two cases, side by side.
	var twins: Dictionary = {}
	for c in collector_cases:
		if String(c.get("name", "")) == "The Pruitt Twins":
			twins = c
	var holder := world
	for k in 2:
		var croot := Node3D.new()
		croot.position = Vector3(-3.6 + k * 0.82, 0, -2.0)
		croot.rotation_degrees.y = 60.0
		croot.scale = Vector3.ONE * 0.7
		holder.add_child(croot)
		world = croot
		if bool(twins.get("freed", false)):
			_open_case(Vector3.ZERO, "Pruitt Twin #%d" % (k + 1))
		else:
			_grade_case(Vector3.ZERO, "female_adult_08", {"grade": "9.%d" % (2 + k), "cond": "SEALED", "lot": "#000%d" % (2 + k), "name": "PRUITT TWIN #%d" % (k + 1),
				"ante": "PAIR", "label": "PSX CARDS"}, false)
		world = holder
	_spot(Vector3(-2.6, 3.0, 0.2), Vector3(-3.2, 1.0, -2.0), Color(1.0, 0.8, 1.0), 2.6, 26, 6.0)
	_walker([Vector3(-1.2, 0, -3.05), Vector3(2.2, 0, -3.1), Vector3(-0.2, 0, -3.0)], [["browse", 180], ["reach", 180], ["browse", 180]], "male_adult_11", 0.45)
	for x in [-2.0, 0.0, 2.0]:
		_panel_light(Vector3(x, 3.15, -0.8), 1.4, Color(0.95, 0.97, 1.0), 5.0)
	_light(Vector3(0, 2.6, -3.0), Color(1.0, 0.9, 0.85), 1.8, 5.0)
	_view(Vector3(0, 1.55, 1.8), Vector3(0, 0.95, -0.1))


## The comic shop (Panel Hoppers): a back-issue wall of bagged keys to the
## ceiling, tables of longboxes sorted by era, a spinner rack, the counter,
## and Uncle Hector's case in the corner, bagged, boarded and slabbed.
func _comicshop(items: Array) -> void:
	_setup(Color(0.12, 0.08, 0.1), Color(0.8, 0.72, 0.7), 1.2, 7.0, 22.0)
	_room(9, 7.5, 3.3, "woodfloor043", Color(0.8, 0.72, 0.62), "bricks105", Color(0.72, 0.5, 0.45), 1.3, Rect2(), Color(0.5, 0.45, 0.42))
	var pool := Catalog.items_of("comics")
	var books := pool.filter(func(d): return String(d["kind"]) == "comic")
	var boxes := pool.filter(func(d): return String(d["kind"]) == "longbox")
	# The back-issue wall: rows of bagged books on slat-wall hooks, keys up top.
	var wall := Psx.mat(Color(0.85, 0.85, 0.82), Psx.tex("planks012"), Vector2(6, 2))
	Psx.box(Vector3(8.6, 3.0, 0.05), wall, Vector3(0, 1.6, -3.68), world)
	var r := RandomNumberGenerator.new()
	r.seed = 404
	for row in 5:
		var y := 0.55 + row * 0.5
		for k in 11:
			var it: Dictionary = books[r.randi() % books.size()].duplicate()
			it["cond"] = "Mint"
			if row == 4 and r.randf() < 0.5:
				it["grade"] = 9
			var m := ItemModels.build(it)
			m.scale = Vector3.ONE * ITEM_SCALE * 1.15
			m.position = Vector3(-3.9 + k * 0.78, y, -3.6)
			world.add_child(m)
	_neon("BACK ISSUES", Vector3(-1.6, 3.05, -3.6), Color(1.0, 0.35, 0.3), 56)
	_neon("KEYS  ON  THE  WALL", Vector3(2.0, 3.1, -3.6), Color(0.4, 0.85, 1.0), 34)
	# Tables of longboxes, sorted by era, books standing up inside.
	for i in 2:
		var tp := Vector3(-2.0 + i * 4.0, 0, -1.9)
		var t := _prop("table", tp, 0, 0.0, Color(0.55, 0.45, 0.35), 1.8)
		var ty := _top(t)
		for k in 3:
			var bx: Dictionary = boxes[(i * 3 + k) % boxes.size()].duplicate()
			bx["cond"] = "CIB"
			var bm := ItemModels.build(bx)
			bm.scale = Vector3.ONE * ITEM_SCALE * 0.95
			bm.position = tp + Vector3(-0.55 + k * 0.55, ty, 0)
			bm.rotation_degrees.y = 0.0
			world.add_child(bm)
		_person(tp + Vector3(0.3, 0, -0.6), 0, Color.WHITE, 1.45, String(PEOPLE[(i * 5 + 3) % PEOPLE.size()]))
	# A spinner rack by the door.
	var sp := Node3D.new()
	sp.position = Vector3(3.4, 0, 0.6)
	world.add_child(sp)
	Psx.cyl(0.03, 1.8, Psx.mat(Color(0.75, 0.75, 0.78)), Vector3(0, 0.9, 0), sp, 6)
	for tier in 4:
		for k in 4:
			var it2: Dictionary = books[r.randi() % books.size()].duplicate()
			it2["cond"] = "Loose"
			var cm := ItemModels.build(it2)
			cm.scale = Vector3.ONE * ITEM_SCALE * 0.8
			var a := TAU * k / 4.0
			cm.position = Vector3(sin(a) * 0.16, 0.25 + tier * 0.4, cos(a) * 0.16)
			cm.rotation.y = a
			sp.add_child(cm)
	_spin.append(sp)
	# The counter with your table's items, a register and a pull-list box.
	Psx.box(Vector3(2.6, 0.9, 0.7), Psx.mat(Color(0.3, 0.22, 0.18), Psx.tex("wood066")), Vector3(0, 0.45, 0), world)
	Psx.box(Vector3(2.65, 0.04, 0.75), Psx.mat(Color(0.6, 0.85, 0.9), null, Vector2.ONE, 0.35), Vector3(0, 0.92, 0), world)
	_lay_items(items, Vector3(-0.2, 0.94, 0.0), 1.9, 0.3, 4)
	_prop("shop/cash-register", Vector3(1.1, 0.94, -0.1), -20, 0.35)
	_person(Vector3(1.3, 0, -0.85), -15, Color(1.0, 0.95, 0.9), 1.45, "male_adult_01")
	# Uncle Hector's case in the corner.
	var hector: Dictionary = {}
	for c in collector_cases:
		if String(c.get("name", "")) == "Uncle Hector":
			hector = c
	var holder := world
	var croot := Node3D.new()
	croot.position = Vector3(-3.5, 0, -0.5)
	croot.rotation_degrees.y = 55.0
	croot.scale = Vector3.ONE * 0.8
	holder.add_child(croot)
	world = croot
	if bool(hector.get("freed", false)):
		_open_case(Vector3.ZERO, "Uncle Hector")
	else:
		_grade_case(Vector3.ZERO, "male_adult_14", {"grade": "4.0", "cond": "GOOD", "lot": "#0004", "name": "UNCLE HECTOR",
			"ante": "HEAVY WEAR, COMPLETE", "label": "CGX COMICS", "case": "comic"}, false)
	world = holder
	_spot(Vector3(-2.6, 3.1, 0.8), Vector3(-3.5, 1.0, -0.5), Color(0.8, 0.85, 1.0), 2.8, 26, 6.0)
	_walker([Vector3(-3.0, 0, -3.0), Vector3(0.0, 0, -3.1), Vector3(3.0, 0, -3.0)], [["browse", 180], ["reach", 180], ["browse", 180]], "female_adult_11", 0.45)
	for x in [-2.5, 0.0, 2.5]:
		_panel_light(Vector3(x, 3.25, -1.0), 1.5, Color(1.0, 0.97, 0.92), 5.5)
	_light(Vector3(0, 2.6, -3.0), Color(1.0, 0.9, 0.8), 1.8, 5.0)
	_view(Vector3(0, 1.55, 1.8), Vector3(0, 0.95, -0.1))


## The camera flight for a world's first-visit intro: [[pos, look], ...].
## Ends on the venue's usual view so the reveal lands on the signature item.
func intro_path(id: String) -> Array:
	match id:
		"title":
			# The title vault: along the shelves, swing round, onto the pedestal.
			return [
				[Vector3(-3.2, 1.5, -3.0), Vector3(-3.0, 1.2, -4.9)],
				[Vector3(-2.2, 1.45, -3.85), Vector3(-1.6, 1.15, -4.9)],
				[Vector3(-0.6, 1.4, -3.9), Vector3(0.2, 1.1, -4.9)],
				[Vector3(1.0, 1.45, -3.8), Vector3(1.9, 1.05, -4.9)],
				[Vector3(2.5, 1.7, -2.2), Vector3(1.6, 1.0, -3.6)],
				[Vector3(2.7, 1.9, 0.2), Vector3(-0.8, 1.2, -2.2)],  # glances past the covered case
				[Vector3(1.4, 1.7, 2.4), Vector3(0.0, 1.0, 0.0)],
				[Vector3(0.0, 1.4, 2.3), Vector3(0.0, 1.0, 0.0)],
			]
		"cardshop":
			return [
				[Vector3(-3.4, 2.4, -1.8), Vector3(-2.6, 2.0, -3.6)],  # up close to the sealed wall
				[Vector3(-1.0, 2.0, -2.2), Vector3(0.6, 1.6, -3.6)],
				[Vector3(1.8, 1.7, -1.4), Vector3(3.0, 1.1, -1.6)],  # the grading counter
				[Vector3(0.6, 1.6, -0.4), Vector3(-3.2, 1.2, -2.0)],  # the Twins' cases
				[Vector3(1.0, 1.5, 1.9), Vector3(0.0, 0.95, 0.0)],
				[Vector3(0.0, 1.5, 1.7), Vector3(0.0, 0.95, -0.1)],  # the signature card on the counter
			]
		"comicshop":
			return [
				[Vector3(-3.4, 2.7, -2.0), Vector3(-2.6, 2.6, -3.6)],  # along the top row of keys
				[Vector3(-0.8, 2.3, -2.3), Vector3(0.4, 2.0, -3.6)],
				[Vector3(1.8, 1.9, -1.8), Vector3(2.4, 1.2, -3.6)],
				[Vector3(1.6, 1.6, -0.4), Vector3(-3.5, 1.2, -0.5)],  # Hector in his bag
				[Vector3(0.9, 1.5, 1.9), Vector3(0.0, 0.95, 0.0)],
				[Vector3(0.0, 1.5, 1.7), Vector3(0.0, 0.95, -0.1)],  # the signature book on the counter
			]
		"ballroom":
			return [
				[Vector3(-5.5, 3.0, -5.0), Vector3(0.0, 3.2, -5.9)],  # past the banner and the stage
				[Vector3(-4.0, 2.0, -3.2), Vector3(-1.0, 1.0, -4.3)],  # down over the dealer rows
				[Vector3(-1.0, 1.4, -3.2), Vector3(1.5, 1.0, -2.4)],
				[Vector3(2.4, 1.6, -1.6), Vector3(4.6, 1.3, -0.6)],  # a glance at Rose's slab
				[Vector3(2.4, 1.6, 0.9), Vector3(4.4, 1.2, -0.7)],
				[Vector3(1.0, 1.4, 2.2), Vector3(0.0, 0.9, 0.0)],
				[Vector3(0.0, 1.35, 1.6), Vector3(0.0, 0.85, 0.0)],  # the signature card on the table
			]
	return []


## Metal detecting at dawn: sand, surf, a towel with today's finds.
func _beach(items: Array) -> void:
	_setup(Color(0.75, 0.82, 0.92), Color(0.8, 0.78, 0.72), 1.2, 10.0, 40.0)
	_sky(-40, 120, 40, Color(0.45, 0.65, 0.95), Color(1.0, 0.82, 0.62))
	_ground("pavingstones070", Color(0.95, 0.85, 0.62), Vector2(60, 30), Vector3(0, 0, -6), 0.15)
	var sea := Psx.mat(Color(0.25, 0.55, 0.75), null, Vector2.ONE, 0.25)
	Psx.box(Vector3(80, 0.02, 30), sea, Vector3(0, 0.01, -26), world)
	for k in 4:
		Psx.box(Vector3(80, 0.03, 0.15), Psx.mat(Color(0.92, 0.96, 1.0), null, Vector2.ONE, 0.4), Vector3(0, 0.02, -11.2 - k * 1.7), world)
	_sun(-25, 160, Color(1.0, 0.88, 0.7), 1.3)
	var towel := Psx.mat(Color(0.9, 0.35, 0.3), Psx.tex("fabric061"), Vector2(2, 2))
	Psx.box(Vector3(2.4, 0.02, 1.0), towel, Vector3(0, 0.01, 0), world)
	for k in 5:
		Psx.box(Vector3(2.4, 0.022, 0.08), Psx.mat(Color(0.98, 0.95, 0.85)), Vector3(0, 0.012, -0.4 + k * 0.2), world)
	_lay_items(items, Vector3(0, 0.03, 0.0), 1.9, 0.3, 5)
	# Umbrella, a bucket, a sand sieve and a detector lying in the sand.
	Psx.cyl(0.025, 2.0, Psx.mat(Color(0.9, 0.9, 0.9)), Vector3(-1.8, 1.0, -0.8), world, 6)
	var top := Psx.cyl(1.1, 0.12, Psx.mat(Color(0.25, 0.6, 0.85)), Vector3(-1.8, 2.0, -0.8), world, 10)
	top.rotation_degrees.z = 8.0
	Psx.cyl(0.14, 0.24, Psx.mat(Color(0.95, 0.75, 0.2)), Vector3(1.5, 0.12, 0.3), world, 10)
	var det := Psx.cyl(0.015, 1.2, Psx.mat(Color(0.2, 0.2, 0.22)), Vector3(1.4, 0.05, -0.5), world, 6)
	det.rotation_degrees.z = 80.0
	Psx.cyl(0.16, 0.03, Psx.mat(Color(0.15, 0.15, 0.15)), Vector3(0.85, 0.02, -0.55), world, 12)
	for k in 6:
		_prop("nature/rock_smallA", Vector3(-6 + k * 2.4, 0, -4 - (k % 3)), k * 40, 0.3)
	_prop("nature/grass_large", Vector3(-4.5, 0, -2.5), 0, 0.6)
	_prop("nature/grass_large", Vector3(4.2, 0, -3.0), 50, 0.7)
	_walker([Vector3(-4, 0, -3.5), Vector3(4, 0, -4.2), Vector3(2, 0, -6.0)], [["browse", 90], ["reach", 180], ["browse", -90]], "male_adult_14", 0.35)
	_walker([Vector3(5, 0, -7), Vector3(-5, 0, -7.5)], ["", ""], "female_adult_03", 0.5)
	_view(Vector3(0, 1.4, 1.8), Vector3(0, 0.1, -0.3))


func _title(items: Array) -> void:
	_setup(Color(0.1, 0.07, 0.12), Color(0.6, 0.5, 0.65), 1.0, 5.0, 16.0)
	Psx.snap = 900.0  # no vertex wobble here: the intro camera glides through it
	_room(8, 8, 3.4, "marble012", Color(0.55, 0.5, 0.55), "bricks105", Color(0.6, 0.45, 0.45), 1.0, Rect2(), Color(0.25, 0.2, 0.25))
	# The grail plinth: velvet column with gold rings, like a card's tier frame.
	var ped := Psx.mat(Color(0.32, 0.12, 0.3), Psx.tex("fabric061"), Vector2(3, 1))
	var gold := Psx.mat(Color(1.0, 0.8, 0.3), null, Vector2.ONE, 0.5)
	Psx.cyl(0.52, 0.08, Psx.mat(Color(0.12, 0.08, 0.16)), Vector3(0, 0.04, 0), world, 20)
	Psx.cyl(0.4, 0.7, ped, Vector3(0, 0.39, 0), world, 16)
	for y in [0.1, 0.72]:
		Psx.cyl(0.44, 0.05, gold, Vector3(0, y, 0), world, 16)
	# Round rug with a gold ring under it all.
	Psx.cyl(1.6, 0.01, Psx.mat(Color(0.22, 0.12, 0.32), Psx.tex("fabric061"), Vector2(4, 4)), Vector3(0, 0.005, 0), world, 28)
	Psx.cyl(1.66, 0.008, gold, Vector3(0, 0.003, 0), world, 28)
	# A brass plaque on the front of the plinth.
	var pl := Label3D.new()
	pl.text = "GRAIL"
	pl.font = FONT
	pl.font_size = 64
	pl.pixel_size = 0.0042
	pl.modulate = Color(0.2, 0.1, 0.05)
	pl.outline_size = 0
	pl.shaded = false
	pl.position = Vector3(0, 0.42, 0.405)
	Psx.box(Vector3(0.5, 0.17, 0.01), gold, Vector3(0, 0.42, 0.4), world)
	world.add_child(pl)
	# Museum ropes round the plinth.
	for k in 4:
		var a0 := TAU * k / 4.0 + PI / 4.0
		var post := Vector3(cos(a0) * 1.15, 0, sin(a0) * 1.15)
		Psx.cyl(0.03, 0.85, gold, post + Vector3(0, 0.43, 0), world, 8)
		Psx.cyl(0.07, 0.04, gold, post + Vector3(0, 0.02, 0), world, 10)
		var a1 := TAU * (k + 1) / 4.0 + PI / 4.0
		if k == 0:
			continue  # open towards the camera
		var post2 := Vector3(cos(a1) * 1.15, 0, sin(a1) * 1.15)
		for j in 6:
			var t0 := float(j) / 6.0
			var t1 := float(j + 1) / 6.0
			var p0 := post.lerp(post2, t0) + Vector3(0, 0.78 - sin(t0 * PI) * 0.18, 0)
			var p1 := post.lerp(post2, t1) + Vector3(0, 0.78 - sin(t1 * PI) * 0.18, 0)
			var seg := Psx.cyl(0.018, p0.distance_to(p1), Psx.mat(Color(0.75, 0.1, 0.18), Psx.tex("fabric061")), (p0 + p1) * 0.5, world, 5)
			seg.look_at((p0 + p1) * 0.5 + (p1 - p0), Vector3.UP)
			seg.rotate_object_local(Vector3.RIGHT, PI / 2.0)
	if not items.is_empty():
		var hero := ItemModels.build(items[0])
		hero.scale = Vector3.ONE * 3.6
		hero.position = Vector3(0, 0.75, 0)
		world.add_child(hero)
		Psx.outline(hero, 1.8)
		_spin.append(hero)
		_items.append(hero)
	# A soft beam of light falling on the grail.
	_beam(Vector3(0, 3.3, 0.2), 0.25, 1.0, 2.6, Color(1.0, 0.85, 0.6, 0.09))
	# A collector's vault behind it.
	for i in 3:
		var x := -2.6 + i * 2.6
		var tops := _shelf_unit(Vector3(x, 0, -4.9), 2.3, 4, 0.48, Color(0.5, 0.35, 0.3))
		_decor_stock(Vector3(x, 0, -4.85), 2.3, tops, 900 + i, 7)
	var ids := _poster_ids(77, 4)
	for k in 4:
		_poster(Vector3(-3.95, 1.7, -2.6 + k * 1.3), 90, Vector2(0.7, 0.8), ids[k])
	# Stacks of real boxed games waiting to be shelved.
	_box_stack(Vector3(-1.7, 0, -0.7), 30, 5, 501)
	_box_stack(Vector3(1.75, 0, -0.6), -20, 4, 502)
	_box_stack(Vector3(2.3, 0, -1.3), 10, 3, 503)
	_prop("arcade/arcade-machine", Vector3(-3.4, 0, -3.7), 35, 1.8)
	_prop("arcade/claw-machine", Vector3(-3.5, 0, -2.7), 80, 1.8)
	_prop("arcade/pinball", Vector3(3.4, 0, -3.3), -80, 1.2)
	_prop("pottedPlant", Vector3(3.3, 0, -1.6), 0, 1.2)
	_bulb(Vector3(0, 2.0, 0), Color(1.0, 0.82, 0.55), 4.0, 6.0, 3.4, 0.06)
	_spot(Vector3(0, 3.3, 1.4), Vector3(0, 0.9, 0), Color(1.0, 0.75, 1.0), 3.0, 24, 8.0)
	# Searchlights sweeping the vault (the intro flies past them).
	for k in 3:
		var pivot := Node3D.new()
		pivot.position = Vector3(-2.6 + k * 2.6, 3.2, -2.2)
		world.add_child(pivot)
		var sl := SpotLight3D.new()
		sl.light_color = [Color(0.6, 0.4, 1.0), Color(1.0, 0.5, 0.8), Color(0.4, 0.8, 1.0)][k]
		sl.light_energy = 3.0
		sl.spot_angle = 18.0
		sl.spot_range = 7.0
		pivot.add_child(sl)
		_sweep.append(pivot)
	_light(Vector3(0, 2.6, -3.8), Color(1.0, 0.75, 0.55), 2.0, 6.0)
	_vault_case(Vector3(-1.3, 0, -2.95), 18.0)
	_collector_row(Vector3(0, 0, -4.15), 0.55)
	_view(Vector3(0, 1.4, 2.3), Vector3(0, 1.0, 0), 44.0)


## A row of small cases along the back of the vault, one per collector the
## Buyer sealed. Freed ones stand open and empty; the rest hold their owner.
func _collector_row(center: Vector3, sc: float) -> void:
	var n := collector_cases.size()
	if n == 0:
		return
	var step := CASE_W * sc + 0.08
	var holder := world
	for k in n:
		var c: Dictionary = collector_cases[k]
		if Lite.perf and not bool(c.get("freed", false)) and k > 2:
			continue
		var root := Node3D.new()
		root.position = center + Vector3((k - (n - 1) * 0.5) * step, 0, 0)
		root.scale = Vector3.ONE * sc
		holder.add_child(root)
		world = root
		if bool(c.get("freed", false)):
			_open_case(Vector3.ZERO, String(c.get("name", "")))
		else:
			_grade_case(Vector3.ZERO, String(c.get("who", "male_adult_01")), {"grade": String(c.get("grade", "9.6")), "cond": "SEALED",
				"lot": "#%04d" % (k * 613 + 451), "name": String(c.get("name", "")).to_upper(), "ante": ""}, false)
		world = holder


## An empty case: plinth, the cut plastic slumped inside, the door open.
func _open_case(pos: Vector3, who: String) -> void:
	var brass := Psx.mat(Color(0.75, 0.6, 0.3), null, Vector2.ONE, 0.15)
	Psx.box(Vector3(CASE_W + 0.14, PLINTH_H, CASE_D + 0.14), Psx.mat(Color(0.16, 0.05, 0.08), Psx.tex("fabric061"), Vector2(2, 1)), pos + Vector3(0, PLINTH_H * 0.5, 0), world)
	Psx.box(Vector3(CASE_W + 0.18, 0.03, CASE_D + 0.18), brass, pos + Vector3(0, PLINTH_H, 0), world)
	var cap := CapsuleMesh.new()
	cap.radius = 0.27
	cap.height = 1.1
	cap.radial_segments = 10
	cap.rings = 4
	var bag := Psx.mesh(cap, _shrink_wrap(), pos + Vector3(0.05, PLINTH_H + 0.12, 0.0), world)
	bag.rotation_degrees = Vector3(0, 20, 84)
	bag.scale = Vector3(0.7, 1.0, 0.35)
	var g := _glass()
	var gy := PLINTH_H + CASE_H * 0.5
	for side in [[Vector3(CASE_W, CASE_H, 0.01), Vector3(0, gy, -CASE_D * 0.5)], [Vector3(0.01, CASE_H, CASE_D), Vector3(-CASE_W * 0.5, gy, 0)],
			[Vector3(0.01, CASE_H, CASE_D), Vector3(CASE_W * 0.5, gy, 0)], [Vector3(CASE_W, 0.01, CASE_D), Vector3(0, PLINTH_H + CASE_H, 0)]]:
		Psx.box(side[0], g, pos + side[1], world).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var door := Psx.box(Vector3(CASE_W, CASE_H, 0.02), g, pos + Vector3(CASE_W * 0.5 + 0.25, gy, CASE_D * 0.5 + 0.2), world)
	door.rotation_degrees.y = -70
	Psx.box(Vector3(CASE_W + 0.08, 0.06, CASE_D + 0.08), brass, pos + Vector3(0, PLINTH_H + CASE_H + 0.05, 0), world)
	var root := Node3D.new()
	root.position = pos
	world.add_child(root)
	_vault_plaque(root, "RELEASED", who.to_upper())


## A pile of boxed games (real catalog items with their box art), slightly askew.
func _box_stack(pos: Vector3, rot_y: float, n: int, seed_value: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	var y := 0.0
	for k in n:
		var games := Catalog.items_of("games")
		var d: Dictionary = games[r.randi() % games.size()].duplicate()
		if String(d["kind"]) != "game":
			continue
		d["cond"] = "CIB"
		var m := ItemModels.build(d, null, 1)
		m.scale = Vector3.ONE * ITEM_SCALE
		m.rotation_degrees = Vector3(-90, rot_y + r.randf_range(-12, 12), 0)
		var b := Psx.aabb(m)
		m.position = pos + Vector3(r.randf_range(-0.03, 0.03), y - b.position.y, r.randf_range(-0.03, 0.03))
		world.add_child(m)
		y += b.size.y


## A soft see-through cone of light (additive), for spotlights and beams.
func _beam(top: Vector3, r_top: float, r_bot: float, h: float, col: Color) -> void:
	var c := CylinderMesh.new()
	c.top_radius = r_top
	c.bottom_radius = r_bot
	c.height = h
	c.radial_segments = 16
	c.cap_top = false
	c.cap_bottom = false
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = col
	m.no_depth_test = false
	c.material = m
	var mi := MeshInstance3D.new()
	mi.mesh = c
	mi.position = top - Vector3(0, h * 0.5, 0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mi)


## LOOK AROUND: first person, like a normal 3D game. You stand where the
## camera usually is; dragging looks around (yaw + pitch), the joystick / WASD /
## left stick walks you round the room (kept inside `_bounds`), pinch zooms.
var room_on := false
var room_eye := Vector3.ZERO
var room_yaw := 0.0
var room_pitch := 0.0
var room_zoom := 1.0
var _bounds := Rect2(-3, -3, 6, 5.5)


func room_view(on: bool) -> void:
	room_on = on
	room_reset()


func room_reset() -> void:
	room_eye = _cam_pos + Vector3(0, 0.12, 0.2)
	var d := (_look - room_eye).normalized()
	room_yaw = atan2(-d.x, -d.z)
	room_pitch = clampf(asin(clampf(d.y, -1.0, 1.0)), -0.7, 0.2)
	room_zoom = 1.0
	mark_dirty(12)


## Drag pixels -> look: drag right to look right, up to look up.
func room_look(dx: float, dy: float) -> void:
	_facing = 0.0
	room_yaw = wrapf(room_yaw - dx * 0.0055, -PI, PI)
	room_pitch = clampf(room_pitch - dy * 0.0055, -1.2, 1.1)
	mark_dirty(4)


func room_zoom_by(f: float) -> void:
	room_zoom = clampf(room_zoom * f, 0.45, 1.25)
	mark_dirty(4)


## v = stick (x right, y down = back), walking speed in m/s at full tilt.
func room_walk(v: Vector2, delta: float) -> void:
	if v.length() < 0.05:
		return
	var fwd := Vector3(-sin(room_yaw), 0, -cos(room_yaw))
	var right := Vector3(cos(room_yaw), 0, -sin(room_yaw))
	room_eye += (right * v.x - fwd * v.y) * 1.7 * delta
	room_eye.x = clampf(room_eye.x, _bounds.position.x, _bounds.end.x)
	room_eye.z = clampf(room_eye.z, _bounds.position.y, _bounds.end.y)
	mark_dirty(3)


# ---------------------------------------------------------------- selector

## A marker under the 3D item that matches the selected mini card: a pulsing
## gold ring on the surface and a bobbing arrow above it.
var _sel: Node3D
var _sel_item: Node3D
var _sel_base := Vector3.ZERO


func highlight_uid(uid: int) -> void:
	if _sel != null and is_instance_valid(_sel):
		_sel.queue_free()
	_sel = null
	_sel_item = null
	if uid < 0 or world == null:
		return
	for n in _items:
		if is_instance_valid(n) and (n as Node3D).has_meta("uid") and int((n as Node3D).get_meta("uid")) == uid:
			_sel_item = n
			break
	if _sel_item == null:
		return
	var b := _global_aabb(_sel_item)
	_sel = Node3D.new()
	world.add_child(_sel)
	_sel_base = Vector3(b.get_center().x, b.position.y, b.get_center().z)
	_sel.position = _sel_base
	var r := maxf(b.size.x, b.size.z) * 0.7 + 0.03
	var gold := Psx.mat(Color(1.0, 0.8, 0.25), null, Vector2.ONE, 2.0)
	var ring := Psx.cyl(r, 0.008, gold, Vector3(0, 0.004, 0), _sel, 24)
	ring.set_meta("ring", true)
	Psx.cyl(r * 0.8, 0.009, Psx.mat(Color(0.1, 0.06, 0.16)), Vector3(0, 0.005, 0), _sel, 24)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.07
	cone.bottom_radius = 0.0
	cone.height = 0.14
	cone.radial_segments = 4
	var arrow := Psx.mesh(cone, Psx.mat(Color(1.0, 0.82, 0.3), null, Vector2.ONE, 1.4), Vector3(0, b.size.y + 0.12, 0), _sel)
	arrow.set_meta("arrow", b.size.y + 0.12)
	Psx.outline(arrow, 1.2)
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.82, 0.4)
	l.light_energy = 0.9
	l.omni_range = 0.8
	l.position = Vector3(0, 0.15, 0)
	_sel.add_child(l)
	if room_on:
		# Turn to face it, like a game's "look at" when you pick something.
		var to := (b.get_center() - room_eye)
		_face_goal = Vector2(clampf(asin(clampf(to.normalized().y, -1.0, 1.0)), -1.1, 0.6), atan2(-to.x, -to.z))
		_facing = 0.45
	mark_dirty(10)


var _face_goal := Vector2.ZERO
var _facing := 0.0


func _sel_update() -> void:
	if _facing > 0.0 and room_on:
		var dt := get_process_delta_time()
		_facing -= dt
		var k := minf(1.0, dt * 9.0)
		room_pitch = lerpf(room_pitch, _face_goal.x, k)
		room_yaw = lerp_angle(room_yaw, _face_goal.y, k)
		mark_dirty(2)
	if _sel == null or not is_instance_valid(_sel):
		return
	for c in _sel.get_children():
		if c.has_meta("arrow"):
			(c as Node3D).position.y = float(c.get_meta("arrow")) + sin(_t * 4.0) * 0.025
			(c as Node3D).rotation.y = _t * 1.5
		elif c.has_meta("ring"):
			var s := 1.0 + sin(_t * 5.0) * 0.06
			(c as Node3D).scale = Vector3(s, 1, s)


func _global_aabb(n: Node3D) -> AABB:
	var acc: Array = [null]
	Psx._aabb(n, n.global_transform, acc)
	return acc[0] if acc[0] != null else AABB(n.global_position, Vector3.ONE * 0.1)


## Close-up on the collection shelf ("VIEW SHELF") or back to the room.
func showcase(on: bool) -> void:
	var v: Array = _shelf_view if on else _home_view
	if v.is_empty():
		return
	_view(v[0], v[1], v[2])
	mark_dirty(10)


func _home(items: Array) -> void:
	# Evening at home: low warm lamps, the street dark outside, the shelf lit.
	_setup(Color(0.03, 0.03, 0.06), Color(0.32, 0.28, 0.4), 0.5, 5.0, 16.0)
	var hole := Rect2(1.4, 0.95, 1.4, 1.1)
	_room(6, 5.5, 2.7, "woodfloor043", Color(0.55, 0.45, 0.4), "bricks105", Color(0.45, 0.36, 0.38), 1.0, hole)
	_window_bars(hole, -3.0)
	_sky(-26, 60, 22, Color(0.05, 0.06, 0.18), Color(0.35, 0.25, 0.45))
	_street(-4.0, 11)
	var tops := _shelf_unit(Vector3(-0.6, 0, -0.9), 2.2, 3, 0.48)
	tops.reverse()
	var per := maxi(4, int(ceil(items.size() / 3.0)))
	var level := 0
	var row: Array = []
	for i in items.size():
		row.append(items[i])
		if row.size() == per or i == items.size() - 1:
			_lay_items(row, Vector3(-0.6, tops[mini(level, tops.size() - 1)], -0.88), 2.0, 0.3, per)
			row = []
			level += 1
	_prop("loungeSofa", Vector3(-2.3, 0, 0.7), 80, 0.0, Color(0.75, 0.4, 0.35), 1.7)
	_prop("cabinetTelevision", Vector3(1.7, 0, -1.6), -20, 0.0, Color(0.8, 0.65, 0.5), 1.2)
	_crt(Vector3(1.7, 0.5, -1.6), 0.55, Color(0.45, 0.65, 1.0), -20)
	_prop("lampRoundFloor", Vector3(2.5, 0, -0.4), 0, 1.6)
	_prop("rugRectangle", Vector3(0, 0.005, 0.7), 0, 0.0, Color(0.85, 0.45, 0.4), 2.4)
	_prop("cardboardBoxOpen", Vector3(-2.2, 0, -2.3), 15, 0.4)
	_prop("plantSmall1", Vector3(0.9, 1.5, -0.9), 0, 0.3)
	_prop("bear", Vector3(-1.5, 1.5, -0.9), 20, 0.25)
	var ids := _poster_ids(5, 3)
	_poster(Vector3(-2.2, 1.75, -2.98), 0, Vector2(0.6, 0.7), ids[0])
	_poster(Vector3(-2.99, 1.6, -0.5), 90, Vector2(0.6, 0.7), ids[1])
	# Your Wall: a display case on the left wall with the finds you kept.
	if not wall_items.is_empty():
		var side := Node3D.new()
		side.position = Vector3(-2.35, 0, -0.9)
		world.add_child(side)
		var wt := _shelf_unit_at(side, 1.15, 3, 0.48)
		var holder := world
		world = side
		for k in 3:
			var chunk := wall_items.slice(k * 4, (k + 1) * 4)
			if chunk.is_empty():
				break
			_lay_items(chunk, Vector3(0, wt[mini(k, wt.size() - 1)], 0.02), 1.0, 0.3, 4)
		world = holder
		_light(Vector3(-2.35, 1.95, -0.3), Color(1.0, 0.78, 0.45), 1.8, 2.2)
		var tag := Label3D.new()
		tag.text = "THE WALL"
		tag.font = FONT
		tag.font_size = 36
		tag.pixel_size = 0.004
		tag.modulate = Color(1.0, 0.82, 0.35)
		tag.position = Vector3(-2.35, 1.62, -0.68)
		world.add_child(tag)
	_bulb(Vector3(0, 2.05, 0.4), Color(1.0, 0.68, 0.4), 1.1, 4.0, 2.7, 0.03)
	_light(Vector3(2.4, 1.4, -0.4), Color(1.0, 0.7, 0.45), 1.8, 3.2)
	# Shelf lighting: a warm strip in front of the collection.
	_light(Vector3(-0.6, 1.9, -0.2), Color(1.0, 0.88, 0.65), 2.2, 2.6)
	_light(Vector3(1.4, 1.6, -3.6), Color(0.35, 0.45, 1.0), 0.9, 4.0)
	_light(Vector3(1.7, 0.6, -1.2), Color(0.45, 0.65, 1.0), 0.8, 1.8)
	_home_view = [Vector3(0, 1.45, 2.0), Vector3(-0.3, 1.05, -0.9), 46.0]
	# Framed a little right of centre so the shelves sit left of the pop-up card.
	_shelf_view = [Vector3(-0.55, 1.2, 1.3), Vector3(-0.75, 0.95, -0.9), 58.0]
	_view(_home_view[0], _home_view[1], _home_view[2])


func _garage(items: Array) -> void:
	_setup(Color(0.95, 0.75, 0.55), Color(0.7, 0.62, 0.58), 1.15, 9.0, 34.0)
	var door := Rect2(0, 0, 3.6, 2.3)
	_room(6.5, 6, 2.8, "concrete034", Color(0.8, 0.77, 0.72), "paintedwood009c", Color(0.85, 0.82, 0.72), 1.0, door)
	# Rolled-up door overhead.
	Psx.box(Vector3(3.7, 0.35, 0.3), Psx.mat(Color(0.85, 0.85, 0.82), Psx.tex("corrugatedsteel009"), Vector2(3, 1)), Vector3(0, 2.55, -3.3), world)
	_sky(-40, 90, 30, Color(0.35, 0.55, 0.9), Color(1.0, 0.8, 0.6))
	_ground("concrete047a", Color(0.85, 0.82, 0.78), Vector2(4, 6), Vector3(0, 0.005, -6.5), 0.5)
	_ground("grass004", Color(0.8, 0.95, 0.7), Vector2(40, 6), Vector3(0, 0, -6.5), 0.4)
	_prop("car/suv", Vector3(0.3, 0, -7.2), 10, 0.0, Color.WHITE, 4.3)
	_prop("nature/plant_bushLarge", Vector3(-3.0, 0, -4.4), 0, 0.9, Color(0.7, 1.0, 0.6))
	_prop("nature/flower_yellowC", Vector3(2.6, 0, -4.2), 0, 0.4)
	_street(-9.5, 3)
	_sun(-32, 200, Color(1.0, 0.85, 0.65), 1.6)
	# Inside.
	var table := _prop("tableCross", Vector3(0, 0, 0), 0, 0.0, Color.WHITE, 2.0)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.7, 0.32, 4)
	var sign := Label3D.new()
	sign.text = "GARAGE SALE\nEVERYTHING MUST GO"
	sign.font = FONT
	sign.font_size = 40
	sign.pixel_size = 0.004
	sign.modulate = Color(0.9, 0.15, 0.1)
	sign.outline_size = 0
	sign.position = Vector3(-1.9, 1.25, -0.4)
	sign.rotation_degrees.y = 20
	world.add_child(sign)
	var board := Psx.box(Vector3(0.9, 0.55, 0.02), Psx.mat(Color(0.85, 0.7, 0.45), Psx.tex("cardboard002")), Vector3(-1.905, 1.25, -0.42), world)
	board.rotation_degrees.y = 20
	Psx.cyl(0.02, 1.0, Psx.mat(Color(0.5, 0.4, 0.3)), Vector3(-1.9, 0.5, -0.43), world, 4)
	_prop("cardboardBoxOpen", Vector3(-1.5, 0, 0.5), 30, 0.45)
	_prop("cardboardBoxClosed", Vector3(1.8, 0, 0.3), -20, 0.5)
	_prop("cardboardBoxClosed", Vector3(1.75, 0.5, 0.3), 5, 0.4)
	_prop("bookcaseOpenLow", Vector3(-2.6, 0, -1.8), 70, 0.9)
	_prop("books", Vector3(-2.6, 0.9, -1.8), 70, 0.25)
	_prop("washer", Vector3(2.85, 0, -2.4), -90, 0.9)
	_prop("dryer", Vector3(2.85, 0, -1.6), -90, 0.9)
	_prop("kitchenFridgeSmall", Vector3(2.85, 0, -0.6), -90, 1.0)
	_prop("shop/hand-truck", Vector3(-2.6, 0, 0.6), 40, 1.2)
	_prop("bear", Vector3(1.8, 0.9, 0.3), -10, 0.3)
	_prop("radio", Vector3(-2.6, 0.9, -1.4), 70, 0.25)
	# The host potters about; a neighbour wanders in off the driveway to browse.
	_walker([Vector3(-1.6, 0, -2.7), Vector3(-2.2, 0, -1.5)], [["talk", 20], ["reach", -100]], "male_adult_14")
	_walker([Vector3(2.4, 0, -7.0), Vector3(1.0, 0, -3.9), Vector3(0.8, 0, -1.4), Vector3(-0.7, 0, -1.3), Vector3(0.4, 0, -4.2)], ["", "", ["browse", 0], ["browse", 0], ""], "female_adult_05")
	_bulb(Vector3(0, 1.9, 0.2), Color(1.0, 0.85, 0.6), 2.6, 5.0, 2.8)
	_light(Vector3(0, 1.8, -2.4), Color(1.0, 0.8, 0.6), 1.8, 5.0)
	_view(Vector3(0, 1.45, 1.75), Vector3(0, 0.85, -0.05))


func _flea(items: Array) -> void:
	_setup(Color(0.75, 0.85, 0.95), Color(0.75, 0.75, 0.8), 1.2, 10.0, 40.0)
	_sky(-50, 120, 40, Color(0.3, 0.55, 0.95), Color(0.85, 0.92, 1.0))
	_ground("asphalt012", Color(0.7, 0.7, 0.72), Vector2(40, 30), Vector3(0, 0, -10), 0.25)
	for k in 8:
		Psx.box(Vector3(0.1, 0.01, 4.0), Psx.mat(Color(0.95, 0.95, 0.9)), Vector3(-10 + k * 2.8, 0.01, -12.5), world)
	_sun(-50, 150, Color(1.0, 0.95, 0.85), 1.5)
	# Our stall with a striped canopy.
	var tarp := Psx.mat(Color(0.95, 0.3, 0.25), Psx.tex("fabric028"), Vector2(2, 1))
	var roof := Psx.box(Vector3(2.8, 0.04, 1.7), tarp, Vector3(0, 2.2, -0.1), world)
	roof.rotation_degrees.x = 8.0
	for x in [-1.35, 1.35]:
		for z in [-0.85, 0.65]:
			Psx.cyl(0.025, 2.2, Psx.mat(Color(0.75, 0.75, 0.78)), Vector3(x, 1.1, z), world, 6)
	var table := _prop("tableCloth", Vector3(0, 0, 0), 0, 0.0, Color(1, 1, 1), 2.1)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.8, 0.32, 4)
	_person(Vector3(1.1, 0, -2.2), -15, Color(0.9, 0.95, 1.0))
	_prop("cardboardBoxOpen", Vector3(-1.4, 0, -0.7), 20, 0.45)
	# Other stalls under parasols.
	var r := RandomNumberGenerator.new()
	r.seed = 21
	for i in 5:
		var x := -6.0 + i * 3.0
		var z := -3.6 - (i % 2) * 1.2
		var t := _prop("tableCross", Vector3(x, 0, z), 0, 0.0, Color(0.95, 0.95, 0.95), 1.7)
		_decor_stock(Vector3(x, 0, z), 1.5, [_top(t)], 40 + i, 4, i % 2 == 0)
		_prop("city/detail-parasol-" + ("a" if i % 2 == 0 else "b"), Vector3(x, 0, z - 0.3), 0, 2.6, Color.from_hsv(r.randf(), 0.5, 1.0))
		_person(Vector3(x + 0.4, 0, z - 0.8), 0, Color.from_hsv(r.randf(), 0.3, 1.0))
		_prop("cardboardBoxClosed", Vector3(x - 0.8, 0, z - 0.5), r.randf_range(0, 90), 0.4)
	for i in 4:
		var px: float = [-4.6, -2.4, 2.4, 4.6][i] + r.randf_range(-0.3, 0.3)
		_person(Vector3(px, 0, -2.6 + r.randf_range(-0.3, 0.3)), r.randf_range(120, 240), Color.from_hsv(r.randf(), 0.35, 1.0))
	var cars := ["car/van", "car/truck", "car/sedan", "car/suv", "car/delivery"]
	for i in 5:
		_prop(cars[i], Vector3(-8.5 + i * 4.2, 0, -10.5), 180 + r.randf_range(-6, 6), 0.0, Color.WHITE, 4.3)
	_prop("car/cone", Vector3(2.4, 0, -1.6), 0, 0.5)
	_prop("car/cone", Vector3(-2.5, 0, -1.8), 0, 0.5)
	for i in 6:
		_prop(["nature/tree_oak_dark", "nature/tree_detailed", "suburb/tree-large"][i % 3], Vector3(-12 + i * 4.8, 0, -15.5), r.randf_range(0, 360), r.randf_range(4.5, 6.5), Color(0.75, 1.0, 0.7))
	_skyline(-24, 8, Color(0.75, 0.8, 0.95))
	# Shoppers drifting between the stalls.
	_walker([Vector3(-5.0, 0, -3.8), Vector3(-1.8, 0, -3.6), Vector3(2.4, 0, -4.0), Vector3(5.0, 0, -3.7)], ["", ["browse", 180], ["browse", 180], ""], "male_adult_17", 0.6)
	_walker([Vector3(4.6, 0, -1.4), Vector3(2.6, 0, -1.2), Vector3(-2.8, 0, -1.5), Vector3(-4.8, 0, -1.2)], ["", ["browse", 0], ["browse", 0], ""], "female_adult_14", 0.5)
	_view(Vector3(0, 1.5, 1.8), Vector3(0, 0.85, -0.05))


func _estate(items: Array) -> void:
	_setup(Color(0.8, 0.88, 0.95), Color(0.7, 0.65, 0.6), 1.1, 9.0, 30.0)
	var hole := Rect2(0.9, 0.9, 2.2, 1.5)
	_room(7, 6, 2.9, "woodfloor043", Color(0.95, 0.85, 0.75), "wallpaper001a", Color(0.62, 0.75, 0.6), 1.0, hole, Color(0.85, 0.82, 0.78))
	_window_bars(hole, -3.5, 3, 2)
	_sky(-40, 90, 30, Color(0.4, 0.6, 0.95), Color(0.9, 0.95, 1.0))
	_ground("grass004", Color(0.8, 1.0, 0.7), Vector2(40, 30), Vector3(0, -0.01, -18), 0.4)
	for k in 6:
		_prop("nature/fence_simple", Vector3(-6 + k * 2.2, 0, -7.5), 0, 0.0, Color.WHITE, 2.2)
	for k in 5:
		_prop(["nature/tree_oak_dark", "nature/tree_detailed", "nature/tree_default"][k % 3], Vector3(-6 + k * 3.2, 0, -10 - (k % 2) * 2.5), k * 70, 5.0 + k * 0.4, Color(0.75, 1.0, 0.7))
	for k in 4:
		_prop("nature/plant_bushLarge", Vector3(-3 + k * 2.0, 0, -5.5), k * 40, 0.9, Color(0.7, 1.0, 0.6))
	_prop("nature/flower_purpleB", Vector3(1.2, 0, -4.6), 0, 0.4)
	_sun(-38, 205, Color(1.0, 0.95, 0.85), 1.4)
	var table := _prop("table", Vector3(0, 0, 0), 0, 0.0, Color(0.85, 0.65, 0.5), 1.9)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.6, 0.32, 4)
	_prop("couch", Vector3(-2.3, 0, -1.8), 35, 0.0, Color(0.75, 0.5, 0.55), 1.8)
	_prop("loungeChair", Vector3(2.5, 0, -0.6), -60, 0.0, Color(0.7, 0.55, 0.45), 0.9)
	_prop("bookcase", Vector3(-1.6, 0, -3.25), 0, 1.9)
	_prop("tableCoffee", Vector3(-1.6, 0, -0.9), 20, 0.0, Color(0.8, 0.6, 0.45), 1.0)
	_prop("lampRoundTable", Vector3(-1.6, _top_at(-1.6, -0.9), -0.9), 0, 0.5)
	_prop("coatRackStanding", Vector3(3.0, 0, -2.6), 0, 1.7)
	_prop("rugRound", Vector3(-1.6, 0.005, -0.9), 0, 0.0, Color(0.7, 0.35, 0.35), 2.4)
	_prop("pottedPlant", Vector3(2.9, 0, 0.8), 0, 1.0)
	_prop("ceilingFan", Vector3(0, 2.9, -0.6), 0, 0.0, Color.WHITE, 1.2)
	var ids := _poster_ids(31, 3)
	_poster(Vector3(-3.48, 1.6, -1.6), 90, Vector2(0.6, 0.75), ids[0])
	_poster(Vector3(-3.48, 1.6, -0.3), 90, Vector2(0.5, 0.6), ids[1])
	_poster(Vector3(3.48, 1.7, -1.8), -90, Vector2(0.7, 0.85), ids[2])
	var sheet := Psx.box(Vector3(1.0, 0.9, 0.7), Psx.mat(Color(0.95, 0.94, 0.9), Psx.tex("fabric086")), Vector3(2.0, 0.45, -2.9), world)
	sheet.rotation_degrees.y = 12.0
	_bulb(Vector3(0, 2.0, 0.05), Color(1.0, 0.85, 0.6), 2.4, 5.0, 2.9, 0.03)
	_light(Vector3(0.9, 1.6, -2.8), Color(0.85, 0.92, 1.0), 2.0, 5.0)
	_walker([Vector3(-2.4, 0, -2.2), Vector3(1.8, 0, -2.5), Vector3(2.6, 0, -1.0)], [["browse", -90], ["reach", 180], ["browse", 90]], "female_adult_03", 0.4)
	_walker([Vector3(2.2, 0, -2.6), Vector3(-1.9, 0, -1.7)], [["browse", 180], ["browse", -60]], "male_adult_05", 0.45)
	_view(Vector3(0, 1.45, 1.75), Vector3(0, 0.85, -0.05))


func _storage(items: Array) -> void:
	_setup(Color(0.35, 0.3, 0.45), Color(0.55, 0.55, 0.65), 1.0, 8.0, 28.0)
	_sky(-40, 90, 30, Color(0.15, 0.15, 0.35), Color(0.95, 0.55, 0.45))
	_ground("asphalt012", Color(0.65, 0.65, 0.68), Vector2(30, 30), Vector3(0, 0, -6), 0.25)
	# Our unit: open, packed with junk.
	var steel := Psx.mat(Color(0.75, 0.78, 0.82), Psx.tex("corrugatedsteel009"), Vector2(3, 2))
	var unit := Node3D.new()
	unit.position = Vector3(0, 0, -1.6)
	world.add_child(unit)
	Psx.quad(Vector2(3.2, 2.6), steel, Vector3(0, 1.3, -1.6), unit)
	for sx in [-1.0, 1.0]:
		var sw := Psx.quad(Vector2(3.2, 2.6), steel, Vector3(sx * 1.6, 1.3, 0), unit)
		sw.rotation_degrees.y = -90.0 * sx
	var top := Psx.quad(Vector2(3.2, 3.2), Psx.mat(Color(0.4, 0.4, 0.42)), Vector3(0, 2.6, 0), unit)
	top.rotation_degrees.x = 90.0
	Psx.box(Vector3(3.3, 0.4, 0.15), Psx.mat(Color(0.95, 0.55, 0.2), Psx.tex("corrugatedsteel009"), Vector2(3, 1)), Vector3(0, 2.45, 1.6), unit)
	_neon("UNIT 13", Vector3(0, 2.85, -0.0), Color(1.0, 0.85, 0.4), 48)
	var crate_tex: Texture2D = load("res://assets/models/props/crate_tex.png")
	for i in 4:
		_prop("crate", Vector3(-1.0 + (i % 2) * 0.62, (i / 2) * 0.62, -2.7), i * 9, 0.6, Color.WHITE, 0.0, crate_tex)
	_prop("loungeSofa", Vector3(0.7, 0, -2.6), 0, 0.0, Color(0.55, 0.55, 0.4), 1.4)
	_prop("bear", Vector3(0.5, 0.45, -2.6), 0, 0.3)
	_prop("lampSquareFloor", Vector3(1.2, 0, -1.6), 0, 1.4)
	_prop("televisionVintage", Vector3(-1.2, 0, -1.4), 40, 0.6)
	_prop("StorageTub", Vector3(1.1, 0, -0.6), -20, 0.45, Color(0.3, 0.45, 0.7))
	# Neighbouring units, doors down.
	for sx in [-1.0, 1.0]:
		for k in 2:
			var x: float = sx * (3.4 + k * 3.3)
			Psx.box(Vector3(3.2, 2.6, 0.1), Psx.mat(Color(0.95, 0.55, 0.2), Psx.tex("corrugatedsteel009"), Vector2(3, 2)), Vector3(x, 1.3, -1.6), world)
			Psx.box(Vector3(3.3, 0.6, 0.3), Psx.mat(Color(0.8, 0.8, 0.8)), Vector3(x, 2.9, -1.6), world)
	Psx.box(Vector3(30, 0.6, 0.3), Psx.mat(Color(0.8, 0.8, 0.8)), Vector3(0, 2.9, -1.55), world)
	# Lots on a pallet in the aisle.
	_prop("urban/pallet", Vector3(0, 0, 0.2), 0, 0.0, Color.WHITE, 1.6)
	if items.is_empty():
		for i in 3:
			var b := _prop("cardboardBoxClosed", Vector3(-0.5 + i * 0.5, 0.15, 0.2), i * 13.0 - 10.0, 0.42)
			_items.append(b)
	else:
		_lay_items(items, Vector3(0, 0.15, 0.2), 1.4, 0.35, 4)
	_person(Vector3(-2.3, 0, -0.3), 50, Color(0.9, 0.9, 1.0), 1.45, "construction_male_01")
	_prop("urban/detail-light-double", Vector3(-4.5, 0, 1.5), 90, 4.0)
	_prop("urban/detail-light-double", Vector3(4.5, 0, 1.5), -90, 4.0)
	_prop("urban/truck-grey", Vector3(5.0, 0, 3.5), 100, 0.0, Color.WHITE, 5.0)
	_prop("urban/detail-dumpster-closed", Vector3(-5.5, 0, 2.5), 80, 0.0, Color.WHITE, 2.0)
	_spot(Vector3(0.3, 3.2, 1.8), Vector3(0, 0.2, -0.5), Color(1.0, 0.95, 0.8), 5.0, 32, 8.0)
	_light(Vector3(0, 2.3, -2.0), Color(1.0, 0.85, 0.6), 2.2, 4.0, 0.15)
	_light(Vector3(-4.5, 3.8, 1.0), Color(1.0, 0.8, 0.5), 2.0, 6.0)
	_light(Vector3(4.5, 3.8, 1.0), Color(1.0, 0.8, 0.5), 2.0, 6.0)
	_view(Vector3(0, 1.6, 2.2), Vector3(0, 0.55, -0.3))


func _retro(items: Array) -> void:
	_setup(Color(0.12, 0.1, 0.16), Color(0.75, 0.7, 0.8), 1.2, 7.0, 22.0)
	_room(8, 6.5, 3.0, "tiles139", Color(0.9, 0.85, 0.9), "bricks105", Color(0.75, 0.6, 0.65), 1.3, Rect2(), Color(0.6, 0.6, 0.65))
	for i in 3:
		var x := -2.5 + i * 2.5
		var tops := _shelf_unit(Vector3(x, 0, -3.6), 2.3, 4, 0.42, Color(0.6, 0.48, 0.42))
		_decor_stock(Vector3(x, 0, -3.55), 2.3, tops, 100 + i, 7)
	for sx in [-1.0, 1.0]:
		var side := Node3D.new()
		side.position = Vector3(sx * 3.75, 0, -1.6)
		side.rotation_degrees.y = -90.0 * sx
		world.add_child(side)
		var tops2 := _shelf_unit_at(side, 2.6, 4, 0.42)
		_decor_stock_at(side, 2.6, tops2, 150 + int(sx), 7)
	var ids := _poster_ids(12, 5)
	for k in 5:
		_poster(Vector3(-3.0 + k * 1.5, 2.45, -3.98), 0, Vector2(0.5, 0.55), ids[k])
	# Glass counter.
	Psx.box(Vector3(2.6, 0.9, 0.7), Psx.mat(Color(0.35, 0.3, 0.4), Psx.tex("metalplates006")), Vector3(0, 0.45, 0), world)
	Psx.box(Vector3(2.65, 0.04, 0.75), Psx.mat(Color(0.6, 0.85, 0.9), null, Vector2.ONE, 0.35), Vector3(0, 0.92, 0), world)
	_lay_items(items, Vector3(-0.2, 0.94, 0.0), 1.9, 0.3, 4)
	_prop("shop/cash-register", Vector3(1.1, 0.94, -0.1), -20, 0.35)
	# The manager restocks the back shelves and wipes down the counter.
	_walker([Vector3(0.9, 0, -2.6), Vector3(-1.4, 0, -3.0), Vector3(1.9, 0, -3.0), Vector3(0.9, 0, -0.75)], [["talk", 0], ["restock", 180], ["restock", 180], ["wipe", 0]], "male_adult_08")
	_walker([Vector3(-3.0, 0, -2.2), Vector3(-1.0, 0, -2.7), Vector3(2.8, 0, -2.0)], [["browse", -90], ["browse", 180], ["browse", 90]], "female_adult_11", 0.45)
	_walker([Vector3(2.9, 0, -0.6), Vector3(3.0, 0, -2.6), Vector3(-2.9, 0, -1.2)], [["browse", 90], ["reach", 90], ["browse", -90]], "male_adult_03", 0.5)
	_crt(Vector3(-1.6, 0.94, -0.1), 0.45, Color(0.5, 0.95, 0.6), 25)
	_prop("shop/gacha-machine", Vector3(-3.0, 0, 0.4), 60, 1.4)
	_prop("arcade/arcade-machine", Vector3(-3.1, 0, 1.4), 75, 1.75)
	_prop("arcade/claw-machine", Vector3(3.1, 0, 1.2), -80, 1.75)
	_prop("shop/shopping-basket", Vector3(2.6, 0, 0.6), 0, 0.35)
	_neon("GAMES", Vector3(1.6, 2.65, -3.9), Color(1.0, 0.3, 0.7), 96)
	_neon("BUY  SELL  TRADE", Vector3(-1.4, 2.75, -3.9), Color(0.3, 0.8, 1.0), 40)
	for x in [-2.0, 0.0, 2.0]:
		_panel_light(Vector3(x, 2.95, -0.8), 1.4, Color(0.95, 0.97, 1.0), 5.0, 0.03 if x == 2.0 else 0.0)
	_light(Vector3(0, 2.4, -2.8), Color(1.0, 0.9, 0.8), 1.8, 5.0)
	_view(Vector3(0, 1.55, 1.8), Vector3(0, 0.95, -0.1))


func _pawn(items: Array) -> void:
	_setup(Color(0.7, 0.75, 0.85), Color(0.68, 0.7, 0.62), 1.1, 8.0, 28.0)
	var hole := Rect2(-1.2, 1.0, 2.0, 1.3)
	_room(7, 6, 2.9, "concrete034", Color(0.8, 0.8, 0.75), "plaster001", Color(0.8, 0.78, 0.6), 1.0, hole)
	for k in 9:
		Psx.cyl(0.02, 1.3, Psx.mat(Color(0.25, 0.25, 0.25)), Vector3(-2.1 + k * 0.225, 1.65, -3.42), world, 4)
	_sky(-40, 90, 30, Color(0.45, 0.6, 0.85), Color(0.9, 0.9, 0.95))
	_ground("pavingstones070", Color(0.85, 0.83, 0.8), Vector2(30, 4), Vector3(0, 0, -5.5), 0.6)
	_ground("asphalt012", Color(0.6, 0.6, 0.62), Vector2(30, 8), Vector3(0, -0.01, -11), 0.25)
	_prop("car/taxi", Vector3(-2.0, 0, -9.0), 90, 0.0, Color.WHITE, 4.3)
	for k in 4:
		var w: String = ["urban/wall-a-window", "urban/wall-b-window", "urban/wall-a", "urban/wall-a-garage"][k]
		_prop(w, Vector3(-6 + k * 4.0, 0, -16), 0, 4.0)
		_prop(w, Vector3(-6 + k * 4.0, 4.0, -16), 0, 4.0)
	_prop("urban/detail-dumpster-closed", Vector3(2.5, 0, -14.6), 0, 0.0, Color.WHITE, 2.0)
	_sun(-45, 200, Color(1.0, 0.95, 0.85), 1.2)
	_prop("MetalShelving", Vector3(1.6, 0, -3.1), 0, 2.1, Color(0.6, 0.6, 0.65))
	_prop("televisionVintage", Vector3(1.2, 0.0, -3.0), 0, 0.5)
	_prop("radio", Vector3(1.6, 0.75, -3.0), 10, 0.3)
	_prop("laptop", Vector3(2.0, 0.75, -3.0), -10, 0.15)
	_prop("kitchenMicrowave", Vector3(1.4, 1.45, -3.0), 0, 0.3)
	_prop("speakerSmall", Vector3(2.1, 1.45, -3.0), 0, 0.35)
	_prop("speaker", Vector3(3.1, 0, -2.0), -60, 1.1)
	_prop("lampSquareFloor", Vector3(3.1, 0, -0.6), 0, 1.5)
	_prop("bear", Vector3(1.6, 1.45, -3.0), 0, 0.3)
	_prop("kitchenCoffeeMachine", Vector3(-3.0, 0.95, -1.0), 90, 0.35)
	_prop("sideTableDrawers", Vector3(-3.0, 0, -1.0), 90, 0.95)
	_crt(Vector3(-2.9, 0, -2.4), 0.5, Color(0.6, 0.75, 1.0), 60)
	# Counter.
	Psx.box(Vector3(2.6, 0.95, 0.7), Psx.mat(Color(0.7, 0.55, 0.4), Psx.tex("wood092")), Vector3(0, 0.475, 0), world)
	Psx.box(Vector3(2.65, 0.04, 0.75), Psx.mat(Color(0.6, 0.8, 0.85), null, Vector2.ONE, 0.25), Vector3(0, 0.97, 0), world)
	_lay_items(items, Vector3(-0.2, 0.99, 0.0), 1.9, 0.3, 4)
	_prop("shop/cash-register", Vector3(1.1, 0.99, -0.1), -20, 0.35)
	# The pawnbroker checks stock on the shelving and the drawers out back.
	_walker([Vector3(-0.6, 0, -2.4), Vector3(1.3, 0, -2.5), Vector3(-2.3, 0, -1.6)], [["talk", 10], ["restock", 180], ["reach", -90]], "male_adult_11")
	_walker([Vector3(2.5, 0, -1.6), Vector3(2.4, 0, -0.4)], [["browse", 90], ["browse", 120]], "female_adult_08", 0.4)
	_neon("PAWN", Vector3(1.2, 2.45, -3.4), Color(1.0, 0.85, 0.2), 110)
	_panel_light(Vector3(0, 2.85, -0.6), 2.0, Color(0.9, 1.0, 0.9), 6.0, 0.2)
	_panel_light(Vector3(0, 2.85, -2.4), 1.4, Color(0.9, 1.0, 0.9), 5.0)
	_view(Vector3(0, 1.55, 1.8), Vector3(0, 0.95, -0.1))


func _convention(items: Array) -> void:
	_setup(Color(0.2, 0.15, 0.3), Color(0.75, 0.68, 0.85), 1.25, 9.0, 30.0)
	_room(14, 12, 5.5, "carpet012", Color(0.65, 0.65, 0.95), "plaster001", Color(0.55, 0.5, 0.7), 1.4, Rect2(), Color(0.3, 0.28, 0.35))
	var table := _prop("tableCloth", Vector3(0, 0, 0), 0, 0.0, Color(0.7, 0.7, 1.0), 2.2)
	_lay_items(items, Vector3(0, _top(table), 0.0), 1.9, 0.32, 4)
	Psx.box(Vector3(3.0, 2.2, 0.05), Psx.mat(Color(0.3, 0.2, 0.5), Psx.tex("fabric086")), Vector3(0, 1.1, -1.2), world)
	_neon("COLLECTOR CON", Vector3(0, 1.85, -1.15), Color(1.0, 0.4, 0.75), 70)
	_person(Vector3(1.3, 0, -0.85), -15, Color(0.95, 0.85, 1.0))
	var r := RandomNumberGenerator.new()
	r.seed = 55
	for i in 4:
		var x := -6.0 + i * 4.0
		var z := -5.5
		var t := _prop("tableCloth", Vector3(x, 0, z), 0, 0.0, Color.from_hsv(r.randf(), 0.35, 1.0), 2.0)
		_decor_stock(Vector3(x, 0, z), 1.8, [_top(t)], 300 + i, 5, true)
		var banner := Color.from_hsv(r.randf(), 0.6, 0.9)
		Psx.box(Vector3(2.6, 1.6, 0.05), Psx.mat(banner, Psx.tex("fabric086")), Vector3(x, 1.8, z - 0.9), world)
		var ids := _poster_ids(400 + i, 2)
		_poster(Vector3(x - 0.6, 1.9, z - 0.86), 0, Vector2(0.55, 0.65), ids[0])
		_poster(Vector3(x + 0.6, 1.9, z - 0.86), 0, Vector2(0.55, 0.65), ids[1])
		_person(Vector3(x + 0.3, 0, z - 0.5), 0, Color.from_hsv(r.randf(), 0.3, 1.0))
	for i in 7:
		var cx := r.randf_range(2.0, 6.0) * (1.0 if i % 2 == 0 else -1.0)
		_person(Vector3(cx, 0, r.randf_range(-4.4, -2.4)), r.randf_range(0, 360), Color.from_hsv(r.randf(), 0.35, 1.0))
	_prop("shop/mannequin", Vector3(-2.6, 0, -1.4), 30, 1.75, Color(0.9, 0.6, 0.9))
	_prop("shop/mannequin", Vector3(2.7, 0, -1.5), -30, 1.75, Color(0.6, 0.8, 1.0))
	_prop("shop/gacha-machine", Vector3(3.6, 0, -0.2), -60, 1.4)
	# Free-play corner: cabinets and a pinball with players.
	for k in 3:
		_prop(["arcade/arcade-machine", "arcade/dance-machine", "arcade/pinball"][k], Vector3(-6.0 + k * 1.3, 0, -1.5), 20, 1.8 if k < 2 else 1.2)
	_person(Vector3(-5.6, 0, -0.7), 200, Color.WHITE, 1.4)
	_prop("arcade/basketball-game", Vector3(6.0, 0, -1.4), -30, 1.9)
	for x in [-5.0, 5.0]:
		_prop("shop/column", Vector3(x, 0, -3.0), 0, 5.5)
	for x in [-4.0, 0.0, 4.0]:
		_panel_light(Vector3(x, 5.4, -3.0), 1.6, Color(1.0, 0.95, 0.9), 8.0)
	_spot(Vector3(-1.5, 3.5, 1.5), Vector3(0, 0.8, 0), Color(1.0, 0.55, 0.85), 3.5, 28, 8.0)
	_spot(Vector3(1.5, 3.5, 1.5), Vector3(0, 0.8, 0), Color(0.55, 0.75, 1.0), 3.5, 28, 8.0)
	# Con-goers doing laps of the hall.
	for k in 3:
		var zl := -3.0 - k * 0.6
		_walker([Vector3(-6.5 + k, 0, zl), Vector3(-2.0, 0, zl - 0.4), Vector3(2.5, 0, zl), Vector3(6.5 - k, 0, zl - 0.3)], ["", ["browse", 180], ["browse", 180], ""], String(PEOPLE[(k * 5 + 2) % PEOPLE.size()]), 0.55)
	_view(Vector3(0, 1.5, 1.85), Vector3(0, 0.85, -0.1))


func _online(items: Array) -> void:
	_setup(Color(0.05, 0.06, 0.15), Color(0.55, 0.55, 0.75), 1.0, 7.0, 40.0)
	var hole := Rect2(-0.9, 1.0, 2.0, 1.2)
	_room(5.5, 5, 2.6, "carpet016", Color(0.6, 0.55, 0.65), "wallpaper001c", Color(0.45, 0.5, 0.7), 1.0, hole)
	_window_bars(hole, -2.5, 2, 1)
	_sky(-60, 140, 50, Color(0.02, 0.03, 0.12), Color(0.35, 0.2, 0.45))
	_skyline(-22, 4, Color(0.25, 0.28, 0.45), true)
	_ground("asphalt012", Color(0.25, 0.25, 0.3), Vector2(60, 40), Vector3(0, -6, -25), 0.2)
	var desk := _prop("desk", Vector3(0, 0, -0.2), 180, 0.0, Color(0.7, 0.6, 0.5), 2.0)
	var top := _top(desk)
	_crt(Vector3(0.1, top, -0.5), 0.6, Color(0.45, 0.65, 1.0))
	var l := Label3D.new()
	l.text = {"ebay": "eBuy", "tcgmarket": "TCGrabber", "breaks": "BREAKZ LIVE", "comicauction": "PanelLink"}.get(scene_id, "LOT 0451")
	l.font = FONT
	l.font_size = 48
	l.pixel_size = 0.004
	l.shaded = false
	l.modulate = Color(1, 1, 0.6)
	l.position = Vector3(0.08, top + 0.3, -0.23)
	world.add_child(l)
	_lay_items(items, Vector3(0, top, 0.05), 1.7, 0.3, 5)
	_prop("computerKeyboard", Vector3(0.1, top, -0.15), 180, 0.0, Color.WHITE, 0.45)
	_prop("chairDesk", Vector3(0.9, 0, 0.9), 200, 0.9)
	_prop("bedSingle", Vector3(-2.0, 0, -1.6), 90, 0.0, Color(0.55, 0.6, 0.9), 2.0)
	_prop("pillow", Vector3(-2.4, 0.5, -2.2), 90, 0.0, Color.WHITE, 0.5)
	_prop("pottedPlant", Vector3(2.4, 0, -2.1), 0, 0.9)
	_prop("bookcaseClosedWide", Vector3(2.4, 0, -1.0), -90, 1.6)
	_prop("cardboardBoxClosed", Vector3(1.7, 0, -2.2), 30, 0.45)
	_prop("cardboardBoxClosed", Vector3(1.7, 0.45, -2.2), 10, 0.35)
	_prop("rugRound", Vector3(0, 0.005, 0.6), 0, 0.0, Color(0.5, 0.4, 0.75), 2.0)
	var ids := _poster_ids(66, 3)
	_poster(Vector3(1.2, 1.7, -2.48), 0, Vector2(0.55, 0.65), ids[0])
	_poster(Vector3(-2.73, 1.6, -0.9), 90, Vector2(0.55, 0.65), ids[1])
	_poster(Vector3(-2.73, 1.6, 0.1), 90, Vector2(0.55, 0.65), ids[2])
	_prop("lampRoundTable", Vector3(-1.0, top, -0.4), 0, 0.45)
	_light(Vector3(-1.0, top + 0.5, -0.3), Color(1.0, 0.75, 0.45), 1.6, 3.0)
	_light(Vector3(0, 2.3, 0.8), Color(0.8, 0.8, 1.0), 1.2, 5.0)
	_view(Vector3(0, 1.4, 1.5), Vector3(0, top + 0.1, -0.2))


func _heritage(items: Array) -> void:
	_setup(Color(0.15, 0.06, 0.07), Color(0.75, 0.6, 0.55), 1.15, 8.0, 26.0)
	_room(10, 9, 4.2, "woodfloor051", Color(0.95, 0.8, 0.65), "wallpaper001a", Color(0.75, 0.25, 0.28), 1.0, Rect2(), Color(0.85, 0.8, 0.7))
	var velvet := Psx.mat(Color(0.65, 0.1, 0.15), Psx.tex("fabric086"))
	var gold := Psx.mat(Color(1.0, 0.8, 0.35), null, Vector2.ONE, 0.3)
	Psx.box(Vector3(2.2, 0.85, 0.8), velvet, Vector3(0, 0.425, 0), world)
	Psx.box(Vector3(2.3, 0.04, 0.9), gold, Vector3(0, 0.87, 0), world)
	_lay_items(items, Vector3(0, 0.89, 0.0), 1.9, 0.32, 4)
	for x in [-1.6, 1.6]:
		Psx.cyl(0.04, 0.9, gold, Vector3(x, 0.45, 0.8), world, 8)
	var rope := Psx.cyl(0.02, 3.2, velvet, Vector3(0, 0.8, 0.8), world, 6)
	rope.rotation_degrees.z = 90.0
	# Auctioneer at the podium, bidders in rows.
	Psx.box(Vector3(0.7, 1.15, 0.55), Psx.mat(Color(0.6, 0.42, 0.3), Psx.tex("wood092")), Vector3(2.4, 0.575, -1.8), world)
	_person(Vector3(2.4, 0, -2.3), -10, Color(1.0, 0.95, 0.85), 1.45, "business_male_02")
	_walker([Vector3(-4.6, 0, -3.4), Vector3(-4.6, 0, -0.4)], [["browse", 60], ["browse", 120]], "security_male_01", 0.35)
	var r := RandomNumberGenerator.new()
	r.seed = 9
	for row in 2:
		for k in 5:
			var x := -4.2 + k * 0.7
			var z := -2.2 - row * 0.9
			_prop("chairCushion", Vector3(x, 0, z), 70, 0.0, Color(0.8, 0.3, 0.3), 0.6)
			if r.randf() < 0.45:
				# Bidders standing at the back of their row.
				_person(Vector3(x - 0.45, 0, z), 70, Color.from_hsv(r.randf(), 0.25, 1.0))
	for x in [-4.6, -1.6, 1.6, 4.6]:
		_prop("shop/column", Vector3(x, 0, -4.1), 0, 4.2, Color(1.0, 0.95, 0.85))
	var ids := _poster_ids(88, 3)
	for k in 3:
		_poster(Vector3(-3.1 + k * 3.1, 2.0, -4.45), 0, Vector2(1.0, 1.15), ids[k])
	_neon("HERITAGE", Vector3(0, 3.5, -4.4), Color(1.0, 0.8, 0.4), 90)
	for x in [-2.5, 2.5]:
		_bulb(Vector3(x, 3.3, -1.5), Color(1.0, 0.85, 0.6), 2.5, 6.0, 4.2, 0.0)
	_spot(Vector3(0, 3.6, 1.2), Vector3(0, 0.9, 0), Color(1.0, 0.88, 0.65), 6.0, 26, 7.0)
	_light(Vector3(0, 3.0, -3.2), Color(1.0, 0.75, 0.55), 2.2, 7.0)
	_view(Vector3(0, 1.5, 1.85), Vector3(0, 0.9, -0.05))


## Height of a placed prop's top surface (for laying items on it).
func _top(n: Node3D) -> float:
	return Psx.aabb(n).end.y


## Top of the most recently placed prop near (x, z) — used to stand a lamp on a table.
func _top_at(x: float, z: float) -> float:
	var best := 0.0
	for c in world.get_children():
		if c is Node3D and absf((c as Node3D).position.x - x) < 0.05 and absf((c as Node3D).position.z - z) < 0.05:
			best = maxf(best, Psx.aabb(c).end.y)
	return best


## Shelf unit under a parent node (for side walls).
func _shelf_unit_at(parent: Node3D, w: float, levels: int, gap: float) -> Array:
	var holder := world
	world = parent
	var tops := _shelf_unit(Vector3.ZERO, w, levels, gap, Color(0.6, 0.48, 0.42))
	world = holder
	return tops


func _decor_stock_at(parent: Node3D, w: float, tops: Array, seed_value: int, per_level: int) -> void:
	var holder := world
	world = parent
	_decor_stock(Vector3(0, 0, 0.05), w, tops, seed_value, per_level)
	world = holder


# ================================================================ the curse

## Who "you" are in 3D (the lose ending puts this model in a case).
const PLAYER := "male_adult_05"
const CASE_W := 0.86
const CASE_D := 0.66
const CASE_H := 1.92
const PLINTH_H := 0.32


## The lose ending: you, plastic-wrapped and bound with twine, standing in a
## graded glass case in the Buyer's dark vault, between the others who came
## up short. case_info = {grade, cond, lot, name, ante}.
func _cursed(_items: Array) -> void:
	_setup(Color(0.012, 0.01, 0.02), Color(0.22, 0.24, 0.34), 0.35, 3.5, 11.0)
	Psx.snap = 900.0
	_ground("concrete047a", Color(0.32, 0.3, 0.34), Vector2(16, 16), Vector3(0, 0, -2), 0.6)
	var info := case_info
	_grade_case(Vector3.ZERO, PLAYER, info, true)
	# The others who came up short, fading into the dark on both sides.
	var who := ["male_adult_11", "female_adult_08", "male_adult_17", "female_adult_03", "male_adult_01", "female_adult_14"]
	var grades := ["3.0", "6.5", "1.5", "8.0", "4.0", "2.5"]
	var conds := ["LOOSE", "CIB", "DAMAGED", "MINT", "LOOSE", "DAMAGED"]
	var spots := [Vector3(-1.45, 0, -0.9), Vector3(1.45, 0, -0.9), Vector3(-2.9, 0, -1.8), Vector3(2.9, 0, -1.8), Vector3(-1.45, 0, -3.4), Vector3(1.45, 0, -3.4)]
	var n := 2 if Lite.perf else spots.size()
	for k in n:
		var pos: Vector3 = spots[k]
		var lot := "#%04d" % ((int(info.get("lot_n", 451)) * 7 + k * 613) % 9973)
		_grade_case(pos, String(who[k]), {"grade": grades[k], "cond": conds[k], "lot": lot, "name": "PREVIOUS OWNER", "ante": ""}, false)
	# Cold light straight down on your case, a sick red glow from below.
	_spot(Vector3(0, 3.6, 0.5), Vector3(0, 1.0, 0), Color(0.75, 0.88, 1.0), 5.5, 22.0, 6.0)
	var top := _light(Vector3(0, 2.5, 0.35), Color(0.7, 0.85, 1.0), 1.6, 2.6, 0.22)
	top.shadow_enabled = false
	_light(Vector3(0, 0.15, 1.1), Color(0.85, 0.08, 0.12), 1.6, 2.2, 0.1)
	_beam(Vector3(0, 3.6, 0.2), 0.12, 0.75, 3.4, Color(0.6, 0.75, 1.0, 0.06))
	_view(Vector3(0, 1.25, 3.7), Vector3(0, 1.0, 0), 40.0)


func _glass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.65, 0.82, 0.95, 0.13)
	m.metallic_specular = 1.0
	m.roughness = 0.04
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.rim_enabled = true
	m.rim = 0.6
	return m


func _shrink_wrap() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.88, 0.92, 1.0, 0.3)
	m.metallic_specular = 1.0
	m.roughness = 0.08
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.rim_enabled = true
	m.rim = 1.0
	m.rim_tint = 0.0
	return m


## One graded display case at `pos`: plinth, glass, a wrapped and bound
## collector inside, a grading slab label on the front.
func _grade_case(pos: Vector3, who: String, info: Dictionary, hero: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	world.add_child(root)
	var dark := Psx.mat(Color(0.1, 0.09, 0.11), Psx.tex("metal032"))
	var brass := Psx.mat(Color(0.75, 0.6, 0.3), null, Vector2.ONE, 0.15)
	# Plinth.
	Psx.box(Vector3(CASE_W + 0.14, PLINTH_H, CASE_D + 0.14), Psx.mat(Color(0.16, 0.05, 0.08), Psx.tex("fabric061"), Vector2(2, 1)), Vector3(0, PLINTH_H * 0.5, 0), root)
	Psx.box(Vector3(CASE_W + 0.18, 0.03, CASE_D + 0.18), brass, Vector3(0, PLINTH_H, 0), root)
	# The collector, arms at their sides, head bowed.
	var p := Psx.person(who)
	p.scale = Vector3.ONE * 0.86
	p.position = Vector3(0, PLINTH_H + 0.02, 0.0)
	root.add_child(p)
	if hero:
		Psx.outline(p, 1.0)
		# Still breathing in there.
		_breathe.append([p, p.scale.y, 0.3])
	else:
		Psx.tint_all(p, Color(0.55, 0.6, 0.75))
	var w := _rig(p)
	_pose(w, 0.0, 0.0, "", 0.0)
	_rot(w, "Head", Quaternion(Vector3.BACK, deg_to_rad(22.0)))
	_rot(w, "L UpperArm", Quaternion(Vector3.UP, deg_to_rad(ARM_DOWN + 8.0)) * Quaternion(Vector3.BACK, deg_to_rad(ARM_IN)))
	_rot(w, "R UpperArm", Quaternion(Vector3.UP, deg_to_rad(-ARM_DOWN - 8.0)) * Quaternion(Vector3.BACK, deg_to_rad(ARM_IN)))
	# Shrink wrap: a glossy bag over the whole body, twisted shut above the head.
	var body_h := 1.56
	var cap := CapsuleMesh.new()
	cap.radius = 0.27
	cap.height = body_h + 0.12
	cap.radial_segments = 14
	cap.rings = 6
	var bag := Psx.mesh(cap, _shrink_wrap(), Vector3(0, PLINTH_H + 0.02 + body_h * 0.5, 0.0), root)
	bag.scale = Vector3(1.0, 1.0, 0.72)
	bag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var knot := CylinderMesh.new()
	knot.top_radius = 0.07
	knot.bottom_radius = 0.01
	knot.height = 0.18
	knot.radial_segments = 8
	Psx.mesh(knot, _shrink_wrap(), Vector3(0, PLINTH_H + body_h + 0.17, 0), root)
	# Bound up: twine wrapped round chest, waist, knees and ankles.
	var twine := Psx.mat(Color(0.55, 0.38, 0.2), Psx.tex("fabric028"), Vector2(6, 1))
	for band in [[1.24, 0.25], [0.98, 0.24], [0.52, 0.15], [0.16, 0.11]]:
		var t := TorusMesh.new()
		t.inner_radius = float(band[1])
		t.outer_radius = float(band[1]) + 0.025
		t.rings = 14
		t.ring_segments = 5
		var ring := Psx.mesh(t, twine, Vector3(0, PLINTH_H + 0.02 + float(band[0]), 0.0), root)
		ring.scale = Vector3(1.08, 1.0, 0.82)
	# Glass case with a dark metal frame.
	var g := _glass()
	var gy := PLINTH_H + CASE_H * 0.5
	for side in [[Vector3(CASE_W, CASE_H, 0.01), Vector3(0, gy, CASE_D * 0.5)], [Vector3(CASE_W, CASE_H, 0.01), Vector3(0, gy, -CASE_D * 0.5)],
			[Vector3(0.01, CASE_H, CASE_D), Vector3(-CASE_W * 0.5, gy, 0)], [Vector3(0.01, CASE_H, CASE_D), Vector3(CASE_W * 0.5, gy, 0)],
			[Vector3(CASE_W, 0.01, CASE_D), Vector3(0, PLINTH_H + CASE_H, 0)]]:
		var pane := Psx.box(side[0], g, side[1], root)
		pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for x in [-CASE_W * 0.5, CASE_W * 0.5]:
		for z in [-CASE_D * 0.5, CASE_D * 0.5]:
			Psx.box(Vector3(0.035, CASE_H, 0.035), dark, Vector3(x, gy, z), root)
	Psx.box(Vector3(CASE_W + 0.04, 0.05, CASE_D + 0.04), dark, Vector3(0, PLINTH_H + CASE_H, 0), root)
	Psx.box(Vector3(CASE_W + 0.08, 0.06, CASE_D + 0.08), brass, Vector3(0, PLINTH_H + CASE_H + 0.05, 0), root)
	# The grading slab label: red banner, grade box, condition, lot number.
	var lab := Node3D.new()
	lab.position = Vector3(0, PLINTH_H * 0.5, CASE_D * 0.5 + 0.075)
	root.add_child(lab)
	Psx.box(Vector3(CASE_W * 0.92, PLINTH_H * 0.82, 0.012), Psx.mat(Color(0.92, 0.9, 0.84)), Vector3.ZERO, lab)
	Psx.box(Vector3(CASE_W * 0.92, PLINTH_H * 0.22, 0.014), Psx.mat(Color(0.7, 0.07, 0.1), null, Vector2.ONE, 0.2), Vector3(0, PLINTH_H * 0.3, 0.002), lab)
	Psx.box(Vector3(0.2, PLINTH_H * 0.5, 0.016), Psx.mat(Color(0.08, 0.06, 0.08)), Vector3(CASE_W * 0.33, -PLINTH_H * 0.08, 0.002), lab)
	_case_text(lab, String(info.get("label", "COLLECTOR'S CURSE GRADING")), Vector3(0, PLINTH_H * 0.3, 0.012), 22, Color(1.0, 0.92, 0.85))
	if String(info.get("case", "")) == "slab" or String(info.get("case", "")) == "comic":
		# Sports: the case is a giant grading slab: thick clear acrylic edges
		# and a red-and-white flip label riding on top.
		var acr := Psx.mat(Color(0.82, 0.9, 0.98), null, Vector2.ONE, 0.25)
		for x in [-CASE_W * 0.5 - 0.04, CASE_W * 0.5 + 0.04]:
			for z in [-CASE_D * 0.5 - 0.03, CASE_D * 0.5 + 0.03]:
				Psx.box(Vector3(0.07, CASE_H + 0.1, 0.07), acr, Vector3(x, PLINTH_H + CASE_H * 0.5, z), root)
		var top := PLINTH_H + CASE_H + 0.2
		Psx.box(Vector3(CASE_W + 0.2, 0.32, 0.1), Psx.mat(Color(0.96, 0.95, 0.92)), Vector3(0, top, CASE_D * 0.5), root)
		var comic := String(info.get("case", "")) == "comic"
		Psx.box(Vector3(CASE_W + 0.2, 0.08 if not comic else 0.32, 0.104), Psx.mat(Color(0.75, 0.08, 0.1) if not comic else Color(0.15, 0.35, 0.75)), Vector3(0, top + (0.12 if not comic else 0.0), CASE_D * 0.5), root)
		_case_text(root, ("GEM MT %s" if not comic else "%s  WHITE PAGES") % String(info.get("grade", "?")), Vector3(0, top - 0.03, CASE_D * 0.5 + 0.055), 44, Color(0.1, 0.07, 0.08) if not comic else Color(1, 1, 1))
	_case_text(lab, String(info.get("grade", "?")), Vector3(CASE_W * 0.33, -PLINTH_H * 0.06, 0.012), 60, Color(1.0, 0.82, 0.3))
	var lines := "%s\nCOND: %s\nLOT %s  %s" % [String(info.get("name", "YOU")), String(info.get("cond", "LOOSE")), String(info.get("lot", "#0451")), String(info.get("ante", ""))]
	var body := _case_text(lab, lines, Vector3(-CASE_W * 0.1, -PLINTH_H * 0.1, 0.012), 17, Color(0.1, 0.07, 0.08))
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.position.x = -CASE_W * 0.42
	if hero:
		# A price-gun sticker slapped on the glass.
		var st := Node3D.new()
		st.position = Vector3(CASE_W * 0.22, PLINTH_H + 0.42, CASE_D * 0.5 + 0.012)
		st.rotation_degrees.z = -14.0
		root.add_child(st)
		Psx.box(Vector3(0.3, 0.12, 0.006), Psx.mat(Color(1.0, 0.54, 0.24), null, Vector2.ONE, 0.25), Vector3.ZERO, st)
		_case_text(st, "AS-IS  NO RETURNS", Vector3(0, 0, 0.006), 18, Color(0.12, 0.05, 0.03))


func _case_text(parent: Node3D, text: String, pos: Vector3, size: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = FONT
	l.font_size = size
	l.pixel_size = 0.0024
	l.modulate = col
	l.outline_size = 0
	l.shaded = false
	l.line_spacing = -4.0
	l.position = pos
	parent.add_child(l)
	return l


## The tall case in the corner of the title vault. Until your first loss it
## stands under a dust sheet with a RESERVED plaque (and a faint red glow
## under the hem). After that the sheet is on the floor and you're inside.
func _vault_case(pos: Vector3, rot_y: float) -> void:
	var holder := world
	var root := Node3D.new()
	root.position = pos
	root.rotation_degrees.y = rot_y
	world.add_child(root)
	world = root
	var sheet := Psx.mat(Color(0.78, 0.74, 0.68), Psx.tex("fabric086"), Vector2(2, 3))
	if bool(vault_case.get("freed", false)):
		# True ending seen: the case stands open and empty, the plastic cut
		# and slumped on the plinth, the twine in coils on the floor.
		var brass := Psx.mat(Color(0.75, 0.6, 0.3), null, Vector2.ONE, 0.15)
		Psx.box(Vector3(CASE_W + 0.14, PLINTH_H, CASE_D + 0.14), Psx.mat(Color(0.16, 0.05, 0.08), Psx.tex("fabric061"), Vector2(2, 1)), Vector3(0, PLINTH_H * 0.5, 0), root)
		Psx.box(Vector3(CASE_W + 0.18, 0.03, CASE_D + 0.18), brass, Vector3(0, PLINTH_H, 0), root)
		var cap := CapsuleMesh.new()
		cap.radius = 0.27
		cap.height = 1.1
		cap.radial_segments = 14
		cap.rings = 6
		var bag := Psx.mesh(cap, _shrink_wrap(), Vector3(0.05, PLINTH_H + 0.12, 0.0), root)
		bag.rotation_degrees = Vector3(0, 20, 84)
		bag.scale = Vector3(0.7, 1.0, 0.35)
		var twine := Psx.mat(Color(0.55, 0.38, 0.2), Psx.tex("fabric028"), Vector2(6, 1))
		for k in 3:
			var t := TorusMesh.new()
			t.inner_radius = 0.12 + k * 0.03
			t.outer_radius = t.inner_radius + 0.025
			Psx.mesh(t, twine, Vector3(0.5 + k * 0.18, 0.015, 0.45 - k * 0.1), root)
		# The glass front, swung open.
		var glass := _glass()
		var door := Psx.box(Vector3(CASE_W, CASE_H, 0.02), glass, Vector3(CASE_W * 0.5 + 0.25, PLINTH_H + CASE_H * 0.5, CASE_D * 0.5 + 0.2), root)
		door.rotation_degrees.y = -70
		_vault_plaque(root, "SET COMPLETE", "RELEASED. THANK YOU.")
		world = holder
		_light(pos + Vector3(0, 2.6, 0.6), Color(1.0, 0.86, 0.55), 1.6, 3.0, 0.1)
		return
	if vault_case.is_empty():
		# Plinth under the sheet.
		Psx.box(Vector3(CASE_W + 0.14, PLINTH_H, CASE_D + 0.14), Psx.mat(Color(0.16, 0.05, 0.08), Psx.tex("fabric061"), Vector2(2, 1)), Vector3(0, PLINTH_H * 0.5, 0), root)
		# The dust sheet: draped over the case, flaring at the hem, sagging folds.
		var top := PLINTH_H + CASE_H + 0.06
		Psx.box(Vector3(CASE_W + 0.06, CASE_H + 0.06, CASE_D + 0.06), sheet, Vector3(0, PLINTH_H + CASE_H * 0.5 + 0.03, 0), root)
		var hem := Psx.box(Vector3(CASE_W + 0.26, 0.5, CASE_D + 0.26), sheet, Vector3(0, PLINTH_H + 0.12, 0), root)
		hem.scale = Vector3(1.0, 1.0, 1.0)
		for k in 5:
			var fx := -CASE_W * 0.4 + k * CASE_W * 0.2
			var fold := Psx.box(Vector3(0.05, CASE_H * (0.7 + 0.06 * (k % 3)), 0.05), Psx.mat(Color(0.66, 0.62, 0.57), Psx.tex("fabric086")), Vector3(fx, PLINTH_H + CASE_H * 0.4, CASE_D * 0.5 + 0.05), root)
			fold.rotation_degrees.z = (k - 2) * 2.5
		# Something under there pushes the sheet up at about head height.
		var sm := SphereMesh.new()
		sm.radius = 0.16
		sm.height = 0.2
		sm.radial_segments = 10
		sm.rings = 5
		Psx.mesh(sm, sheet, Vector3(0, top - 0.02, 0.0), root)
		# A thin red glow leaking from under the hem.
		var glow := Psx.box(Vector3(CASE_W + 0.2, 0.015, CASE_D + 0.2), Psx.mat(Color(0.9, 0.08, 0.1), null, Vector2.ONE, 1.6), Vector3(0, 0.006, 0), root)
		_flicker.append([glow.material_override, 1.6, 0.25])
		var red := OmniLight3D.new()
		red.position = Vector3(0, 0.08, CASE_D * 0.5 + 0.2)
		red.light_color = Color(0.9, 0.1, 0.12)
		red.light_energy = 0.8
		red.omni_range = 1.1
		root.add_child(red)
		_flicker.append([red, 0.8, 0.3])
		_vault_plaque(root, "RESERVED", "AWAITING CONSIGNMENT")
	else:
		var info := vault_case.duplicate()
		info["name"] = "SPECIMEN: YOU"
		_grade_case(Vector3.ZERO, PLAYER, info, true)
		# The sheet that covered it, dropped in a heap on the floor.
		var heap := Psx.box(Vector3(0.8, 0.12, 0.6), sheet, Vector3(0.75, 0.06, 0.45), root)
		heap.rotation_degrees = Vector3(4, 25, -3)
		Psx.box(Vector3(0.5, 0.1, 0.4), sheet, Vector3(0.6, 0.15, 0.4), root).rotation_degrees.y = -20
		var n := int(vault_case.get("count", 1))
		_vault_plaque(root, "SEALED  x%d" % n, "THE BUYER THANKS YOU")
		world = holder
		_light(pos + Vector3(0, 2.6, 0.6), Color(0.65, 0.8, 1.0), 1.4, 3.0, 0.15)
	world = holder


func _vault_plaque(root: Node3D, big: String, small: String) -> void:
	var brass := Psx.mat(Color(0.75, 0.6, 0.3), null, Vector2.ONE, 0.2)
	var z := CASE_D * 0.5 + 0.14
	Psx.box(Vector3(0.5, 0.17, 0.01), brass, Vector3(0, 0.19, z), root)
	_case_text(root, big, Vector3(0, 0.215, z + 0.008), 30, Color(0.2, 0.1, 0.05))
	_case_text(root, small, Vector3(0, 0.15, z + 0.008), 13, Color(0.25, 0.14, 0.06))
