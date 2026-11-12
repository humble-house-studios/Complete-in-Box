class_name Art
extends Node
## Item art made on demand at runtime instead of baked files (770 items x
## variants would blow the web size budget):
##   Art.front(item)  -> ImageTexture of the box front (BoxArt.paint_front)
##   Art.back(item)   -> box back
##   Art.icon(item, boxed) -> a 3D render of the item for cards
## Each call returns a texture at once (blank at first). A small queue renders
## a few per frame in SubViewports and updates the texture in place, so
## anything already showing it (cards, 3D labels) fills in by itself.
## Headless runs (tests, CI) skip the rendering.

const ICON := Vector2i(96, 96)
const PER_FRAME := 16
const MAX_CACHE := 600

static var _host: Art
static var _tex: Dictionary = {}
static var _order: Array = []

var _queue: Array = []
var _busy := false


static func _get_host() -> Art:
	if _host == null or not is_instance_valid(_host):
		_host = Art.new()
		_host.name = "ArtService"
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			tree.root.add_child.call_deferred(_host)
	return _host


static func _key(item: Dictionary) -> String:
	return "%s|%s" % [item.get("id", "?"), item.get("variant", "Standard")]


## Box front (also used for cart stickers and disc labels).
static func front(item: Dictionary) -> Texture2D:
	return _request("F|" + _key(item), Vector2i(BoxArt.W, BoxArt.H), item, "front")


static func back(item: Dictionary) -> Texture2D:
	return _request("B|" + _key(item), Vector2i(BoxArt.W, BoxArt.H), item, "back")


## 3D render for cards. Boxed copies show the retail box, loose ones the cart/disc.
static func icon(item: Dictionary, boxed: bool) -> Texture2D:
	var k := "I|%s|%d|%s" % [_key(item), 1 if boxed else 0, item.get("cond", "") if item.get("cond", "") == "Sealed" else ""]
	if not _tex.has(k):
		front(item)
		if boxed:
			back(item)
	return _request(k, ICON, item, "icon_box" if boxed else "icon_loose")


static func _request(k: String, size: Vector2i, item: Dictionary, kind: String) -> Texture2D:
	if _tex.has(k):
		return _tex[k]
	var img := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0) if kind.begins_with("icon") else Color(0.15, 0.13, 0.18))
	var t := ImageTexture.create_from_image(img)
	_tex[k] = t
	_order.append(k)
	if DisplayServer.get_name() != "headless":
		_get_host()._queue.append({"key": k, "item": item.duplicate(), "kind": kind, "size": size})
	_trim()
	return t


static func _trim() -> void:
	if _order.size() <= MAX_CACHE:
		return
	# Drop the oldest textures nothing else is holding on to.
	var keep: Array = []
	var excess := _order.size() - int(MAX_CACHE * 0.8)
	for k in _order:
		var t: ImageTexture = _tex.get(k)
		if excess > 0 and t != null and t.get_reference_count() <= 1:
			_tex.erase(k)
			excess -= 1
		else:
			keep.append(k)
	_order = keep


func _process(_delta: float) -> void:
	if _busy or _queue.is_empty():
		return
	_run_batch()


func _run_batch() -> void:
	_busy = true
	# Covers first: icons need their cover already painted.
	var batch: Array = []
	var rest: Array = []
	var covers_waiting := false
	for j in _queue:
		if not String(j["kind"]).begins_with("icon"):
			covers_waiting = true
	for j in _queue:
		var is_icon := String(j["kind"]).begins_with("icon")
		if batch.size() < PER_FRAME and (not is_icon or not covers_waiting):
			batch.append(j)
		else:
			rest.append(j)
	_queue = rest
	var vps: Array = []
	for j in batch:
		vps.append(_make_viewport(j))
	# A few frames so fonts have uploaded their glyphs before we grab the image.
	for f in 3:
		await RenderingServer.frame_post_draw
	for i in batch.size():
		var vp: SubViewport = vps[i]
		if vp == null or not is_instance_valid(vp):
			continue
		var img := vp.get_texture().get_image()
		var t: ImageTexture = _tex.get(batch[i]["key"])
		if img != null and t != null:
			img.convert(Image.FORMAT_RGBA8)
			var sz: Vector2i = batch[i]["size"]
			if img.get_size() != sz:
				img.resize(sz.x, sz.y, Image.INTERPOLATE_NEAREST)
			t.update(img)
		vp.queue_free()
	_busy = false


func _make_viewport(j: Dictionary) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = j["size"]
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var kind := String(j["kind"])
	var item: Dictionary = j["item"]
	if kind == "front" or kind == "back":
		vp.disable_3d = true
		vp.transparent_bg = false
		add_child(vp)
		var c := Control.new()
		c.size = Vector2(vp.size)
		c.clip_contents = true
		vp.add_child(c)
		if kind == "front":
			BoxArt.paint_front(c, item)
		else:
			BoxArt.paint_back(c, item)
		return vp
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_DISABLED
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.56, 0.65)
	e.ambient_light_energy = 0.95
	env.environment = e
	vp.add_child(env)
	var key := DirectionalLight3D.new()
	key.light_color = Color(1.0, 0.92, 0.8)
	key.light_energy = 1.1
	key.rotation_degrees = Vector3(-35, 35, 0)
	vp.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.light_color = Color(0.55, 0.65, 1.0)
	rim.light_energy = 0.6
	rim.rotation_degrees = Vector3(-10, 200, 0)
	vp.add_child(rim)
	var fn := Psx.fog_near
	var ff := Psx.fog_far
	Psx.fog_near = 100.0
	Psx.fog_far = 200.0
	var model := ItemModels.build(item, null, 1 if kind == "icon_box" else 0)
	Psx.fog_near = fn
	Psx.fog_far = ff
	vp.add_child(model)
	model.rotation_degrees.y = -24.0
	var b := Psx.aabb(model)
	var cam := Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	var center := b.get_center()
	var dist := b.size.length() * 0.5 / tan(deg_to_rad(15.0)) * 1.02
	cam.look_at_from_position(center + Vector3(0, 0.35, 1).normalized() * dist, center)
	return vp
