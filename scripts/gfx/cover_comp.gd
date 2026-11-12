class_name CoverComp
extends RefCounted
## Builds a unique cover illustration for any game from CC0 sprite packs
## (CoverSprites): a seeded colour palette, a backdrop, scenery, one of ~16
## layouts (hero close-up, versus, line-up, framed portrait, space battle,
## speed shot, creature close-up, landscape, pop-art grid, spotlight, badge,
## comic panels...) chosen from the genre, and characters/props from pools
## that fit the genre. Titles get a genre-flavoured font, and each publisher
## has its own logo badge and cover stripe so their games look related.

const FONTS := {
	"bungee": "res://assets/fonts/cover/Bungee-Regular.ttf", "bangers": "res://assets/fonts/cover/Bangers-Regular.ttf",
	"lucky": "res://assets/fonts/cover/LuckiestGuy-Regular.ttf", "cinzel": "res://assets/fonts/cover/CinzelDecorative-Bold.ttf",
	"creep": "res://assets/fonts/cover/Creepster-Regular.ttf", "orbit": "res://assets/fonts/cover/Orbitron.ttf",
	"russo": "res://assets/fonts/cover/RussoOne-Regular.ttf", "monoton": "res://assets/fonts/cover/Monoton-Regular.ttf",
	"right": "res://assets/fonts/cover/Righteous-Regular.ttf", "press": "res://assets/fonts/cover/PressStart2P-Regular.ttf",
	"blackops": "res://assets/fonts/cover/BlackOpsOne-Regular.ttf", "pacifico": "res://assets/fonts/cover/Pacifico-Regular.ttf",
	"marker": "res://assets/fonts/cover/PermanentMarker-Regular.ttf", "audio": "res://assets/fonts/cover/Audiowide-Regular.ttf",
	"rubik": "res://assets/fonts/cover/RubikMonoOne-Regular.ttf", "jersey": "res://assets/fonts/Jersey10-Regular.ttf",
}
const GENRE_FONTS := {
	"RPG": ["cinzel", "jersey", "cinzel", "right"], "Strategy": ["cinzel", "blackops", "russo"],
	"Shooter": ["orbit", "audio", "russo", "press"], "Racing": ["russo", "audio", "bungee", "blackops"],
	"Fighting": ["bangers", "blackops", "bungee"], "Puzzle": ["right", "lucky", "rubik", "press"],
	"Sports": ["bungee", "russo", "lucky"], "Horror": ["creep", "creep", "marker"], "Music": ["monoton", "pacifico", "right"],
	"Adventure": ["cinzel", "lucky", "right"], "Life Sim": ["pacifico", "lucky", "right"],
	"Platformer": ["lucky", "bangers", "right", "bungee"], "Action": ["bangers", "blackops", "bungee", "russo"],
	"Hardware": ["russo", "audio", "orbit"],
}
## Layouts each genre can use.
const LAYOUTS := {
	"Platformer": ["hero_center", "action_diag", "landscape", "group", "pop_grid", "panels"],
	"Action": ["hero_center", "action_diag", "versus", "spotlight", "panels", "group"],
	"Adventure": ["landscape", "hero_left", "portrait_frame", "hero_center"],
	"RPG": ["portrait_frame", "landscape", "group", "hero_left", "painted"],
	"Strategy": ["painted", "group", "landscape", "badge"],
	"Shooter": ["space", "space", "space_duo", "spotlight"],
	"Racing": ["speed", "speed", "badge", "pop_grid"],
	"Fighting": ["versus", "versus", "spotlight", "hero_center"],
	"Puzzle": ["pop_grid", "badge", "creature", "panels"],
	"Sports": ["hero_center", "badge", "action_diag", "group"],
	"Horror": ["spotlight", "landscape", "creature", "hero_left"],
	"Music": ["spotlight", "pop_grid", "group", "hero_center"],
	"Life Sim": ["landscape", "creature", "group", "hero_left"],
}
const HEROES := {
	"Platformer": ["hero_cute", "hero_person", "hero_cute"], "Action": ["hero_adventurer", "hero_person", "hero_robot"],
	"Adventure": ["hero_adventurer"], "RPG": ["hero_adventurer", "hero_adventurer", "hero_robot"],
	"Strategy": ["hero_adventurer"], "Shooter": ["ship"], "Racing": ["vehicle"], "Fighting": ["hero_person", "hero_adventurer", "hero_robot", "hero_zombie"],
	"Puzzle": ["animal", "hero_cute", "fish"], "Sports": ["hero_person"], "Horror": ["hero_zombie", "hero_person"],
	"Music": ["hero_person", "hero_robot"], "Life Sim": ["hero_person", "animal"],
}
const FOES := {
	"Platformer": ["enemy"], "Action": ["enemy", "hero_zombie", "hero_robot"], "Adventure": ["enemy", "animal"], "RPG": ["enemy", "hero_zombie"],
	"Strategy": ["hero_adventurer"], "Shooter": ["enemy_ship", "meteor"], "Racing": ["vehicle"], "Fighting": ["hero_person", "hero_robot", "hero_zombie"],
	"Puzzle": ["item", "animal"], "Sports": ["hero_person"], "Horror": ["hero_zombie", "enemy"], "Music": ["hero_person"], "Life Sim": ["animal"],
}

static var _tex: Dictionary = {}
static var _fonts: Dictionary = {}


static func tex(path: String) -> Texture2D:
	if not _tex.has(path):
		_tex[path] = load(path) if ResourceLoader.exists(path) else null
	return _tex[path]


static func pick(g: RandomNumberGenerator, cat: String) -> Texture2D:
	var list: Array = CoverSprites.SPRITES.get(cat, [])
	if list.is_empty():
		return null
	return tex(String(list[g.randi() % list.size()]))


static func font(name: String) -> FontFile:
	if not _fonts.has(name):
		var f: FontFile = (load(FONTS[name]) as FontFile).duplicate()
		f.oversampling = 1.0
		f.hinting = TextServer.HINTING_LIGHT
		if name == "jersey" or name == "press":
			f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_fonts[name] = f
	return _fonts[name]


## A sprite with its bottom-centre at `foot`, `h` tall.
static func sprite(c: Control, t: Texture2D, foot: Vector2, h: float, flip: bool = false, mod := Color.WHITE, rot: float = 0.0) -> TextureRect:
	if t == null:
		return null
	var tr := TextureRect.new()
	tr.texture = t
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var w := h * float(t.get_width()) / maxf(1.0, float(t.get_height()))
	tr.size = Vector2(w, h)
	tr.position = foot - Vector2(w * 0.5, h)
	tr.flip_h = flip
	tr.modulate = mod
	tr.pivot_offset = tr.size * 0.5
	tr.rotation_degrees = rot
	c.add_child(tr)
	return tr


static func gradient(c: Control, r: Rect2, top: Color, bottom: Color, radial: bool = false) -> void:
	var gr := Gradient.new()
	gr.set_color(0, top)
	gr.set_color(1, bottom)
	var gt := GradientTexture2D.new()
	gt.gradient = gr
	gt.width = 16
	gt.height = 32
	if radial:
		gt.fill = GradientTexture2D.FILL_RADIAL
		gt.fill_from = Vector2(0.5, 0.45)
		gt.fill_to = Vector2(1.0, 0.45)
	else:
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.position = r.position
	tr.size = r.size
	c.add_child(tr)


# ---------------------------------------------------------------- palette

## [sky top, sky bottom, ground, accent, ink] from a seeded scheme.
static func palette(g: RandomNumberGenerator, base: Color, genre: String) -> Array:
	var hue := fmod(base.h + g.randf_range(-0.2, 0.2) + 1.0, 1.0)
	var scheme := g.randi() % 5
	if genre == "Horror":
		scheme = 5
	elif genre == "Shooter":
		scheme = 6
	match scheme:
		0:  # sunset
			return [Color.from_hsv(fmod(hue + 0.75, 1.0), 0.6, 0.45), Color.from_hsv(0.07, 0.75, 1.0), Color.from_hsv(hue, 0.5, 0.3), Color.from_hsv(0.12, 0.8, 1.0), Color(1, 0.95, 0.85)]
		1:  # daylight
			return [Color.from_hsv(0.58, 0.55, 0.95), Color.from_hsv(0.55, 0.25, 1.0), Color.from_hsv(0.3, 0.55, 0.55), Color.from_hsv(hue, 0.8, 1.0), Color(1, 1, 1)]
		2:  # night
			return [Color.from_hsv(0.66, 0.7, 0.18), Color.from_hsv(fmod(hue + 0.6, 1.0), 0.6, 0.45), Color.from_hsv(0.66, 0.5, 0.15), Color.from_hsv(hue, 0.6, 1.0), Color(0.9, 0.95, 1.0)]
		3:  # mono pop
			return [Color.from_hsv(hue, 0.75, 0.85), Color.from_hsv(hue, 0.85, 0.55), Color.from_hsv(hue, 0.6, 0.3), Color.from_hsv(fmod(hue + 0.5, 1.0), 0.9, 1.0), Color(1, 1, 1)]
		4:  # pastel
			return [Color.from_hsv(hue, 0.3, 1.0), Color.from_hsv(fmod(hue + 0.15, 1.0), 0.35, 0.95), Color.from_hsv(fmod(hue + 0.3, 1.0), 0.4, 0.75), Color.from_hsv(fmod(hue + 0.5, 1.0), 0.7, 0.9), Color(0.15, 0.1, 0.25)]
		5:  # horror
			return [Color(0.05, 0.02, 0.05), Color(0.45, 0.04, 0.06), Color(0.04, 0.02, 0.03), Color(0.9, 0.15, 0.1), Color(0.95, 0.9, 0.85)]
		_:  # space
			return [Color(0.01, 0.01, 0.06), Color.from_hsv(hue, 0.6, 0.3), Color(0.02, 0.02, 0.05), Color.from_hsv(hue, 0.7, 1.0), Color(0.9, 0.95, 1.0)]


# ---------------------------------------------------------------- compose

## Fills r with a cover illustration. Smaller r (back-cover screenshots) gets
## a simpler shot from the same palette.
static func compose(c: Control, r: Rect2, genre: String, key: String, base: Color) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = hash(key)
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	var rr := Rect2(Vector2.ZERO, r.size)
	var pal := palette(g, base, genre)
	var layouts: Array = LAYOUTS.get(genre, LAYOUTS["Action"])
	var layout := String(layouts[g.randi() % layouts.size()])
	_backdrop(holder, rr, g, pal, genre, layout)
	var heroes: Array = HEROES.get(genre, ["hero_person"])
	var foes: Array = FOES.get(genre, ["enemy"])
	var hc := String(heroes[g.randi() % heroes.size()])
	var fc := String(foes[g.randi() % foes.size()])
	var w := rr.size.x
	var h := rr.size.y
	var tint := Color.WHITE.lerp(pal[3], g.randf_range(0.0, 0.25))
	match layout:
		"hero_center":
			sprite(holder, pick(g, fc), Vector2(w * 0.18, h * 0.86), h * 0.32, false)
			sprite(holder, pick(g, fc), Vector2(w * 0.84, h * 0.82), h * 0.28, true)
			sprite(holder, pick(g, hc), Vector2(w * 0.5, h * 0.98), h * 0.72, g.randf() < 0.5, tint)
		"hero_left":
			sprite(holder, pick(g, fc), Vector2(w * 0.78, h * 0.8), h * 0.38, true)
			sprite(holder, pick(g, hc), Vector2(w * 0.3, h * 1.02), h * 0.82, false, tint)
		"action_diag":
			for k in 5:
				var y := h * (0.2 + k * 0.15)
				BoxArt.rect(holder, Rect2(-10, y, w * 0.7, 2), Color(pal[4], 0.35))
			sprite(holder, pick(g, "item"), Vector2(w * 0.8, h * 0.35), h * 0.14)
			sprite(holder, pick(g, "item"), Vector2(w * 0.68, h * 0.22), h * 0.1)
			sprite(holder, pick(g, hc), Vector2(w * 0.52, h * 0.88), h * 0.66, false, tint, -14.0)
			sprite(holder, pick(g, fc), Vector2(w * 0.85, h * 0.98), h * 0.26, true)
		"versus":
			var split := PackedVector2Array([Vector2(w * 0.62, -5), Vector2(w + 5, -5), Vector2(w + 5, h + 5), Vector2(w * 0.38, h + 5)])
			BoxArt.poly(holder, split, Color(pal[3], 0.45))
			BoxArt.poly(holder, PackedVector2Array([Vector2(w * 0.6, -5), Vector2(w * 0.64, -5), Vector2(w * 0.4, h + 5), Vector2(w * 0.36, h + 5)]), Color(1, 1, 0.8, 0.9))
			sprite(holder, pick(g, hc), Vector2(w * 0.28, h * 1.02), h * 0.78, false, tint)
			sprite(holder, pick(g, fc if fc != hc else "hero_robot"), Vector2(w * 0.74, h * 1.02), h * 0.78, true)
		"group":
			var cats := [hc, fc, hc]
			for k in 3:
				var x := w * (0.2 + k * 0.3)
				sprite(holder, pick(g, String(cats[k])), Vector2(x, h * (0.98 if k != 1 else 1.02)), h * (0.5 if k != 1 else 0.62), k == 2, tint if k != 1 else Color.WHITE)
		"portrait_frame":
			BoxArt.circle(holder, Vector2(w * 0.5, h * 0.48), minf(w, h) * 0.42, pal[3], 28)
			BoxArt.circle(holder, Vector2(w * 0.5, h * 0.48), minf(w, h) * 0.38, pal[0], 28)
			sprite(holder, pick(g, hc), Vector2(w * 0.5, h * 0.82), h * 0.6, g.randf() < 0.5, tint)
			for k in 4:
				var a := TAU * k / 4.0 + PI / 4.0
				sprite(holder, pick(g, "item"), Vector2(w * 0.5, h * 0.52) + Vector2(cos(a), sin(a)) * minf(w, h) * 0.42, h * 0.1)
		"painted":
			sprite(holder, pick(g, "building_fantasy"), Vector2(w * 0.5, h * 0.8), h * 0.6)
			for k in 4:
				sprite(holder, pick(g, hc), Vector2(w * (0.15 + k * 0.23), h * 1.0), h * 0.32, k % 2 == 1)
			sprite(holder, pick(g, "item"), Vector2(w * 0.85, h * 0.25), h * 0.14)
		"space", "space_duo":
			for k in 4:
				sprite(holder, pick(g, "meteor"), Vector2(g.randf() * w, g.randf_range(0.2, 0.8) * h), h * g.randf_range(0.08, 0.2), g.randf() < 0.5, Color.WHITE, g.randf_range(0, 360))
			for k in 3:
				sprite(holder, pick(g, "enemy_ship"), Vector2(w * (0.2 + k * 0.3), h * g.randf_range(0.25, 0.4)), h * 0.16, false, Color.WHITE, 180.0)
			sprite(holder, pick(g, "ship"), Vector2(w * 0.5, h * 0.95), h * 0.45, false, Color.WHITE, g.randf_range(-12, 12))
			if layout == "space_duo":
				sprite(holder, pick(g, "ship"), Vector2(w * 0.2, h * 0.9), h * 0.22)
		"speed":
			BoxArt.poly(holder, PackedVector2Array([Vector2(w * 0.42, h * 0.4), Vector2(w * 0.58, h * 0.4), Vector2(w * 1.2, h), Vector2(-w * 0.2, h)]), Color(0.2, 0.2, 0.22))
			for k in 4:
				var t := float(k) / 4.0
				BoxArt.rect(holder, Rect2(w * 0.5 - 1 - t * 3, h * (0.45 + t * 0.5), 2 + t * 6, h * 0.05), Color(1, 1, 0.8))
			for k in 6:
				BoxArt.rect(holder, Rect2(g.randf() * w, g.randf_range(0.1, 0.9) * h, w * 0.3, 1), Color(1, 1, 1, 0.4))
			sprite(holder, pick(g, "vehicle"), Vector2(w * 0.5, h * 0.98), h * 0.6, false, Color.WHITE, 180.0)
			sprite(holder, pick(g, "vehicle"), Vector2(w * 0.25, h * 0.62), h * 0.25, false, Color.WHITE, 180.0)
		"creature":
			var t2 := pick(g, hc if hc in ["animal", "fish", "enemy"] else "animal")
			sprite(holder, t2, Vector2(w * 0.55, h * 1.15), h * 0.95, g.randf() < 0.5, tint, g.randf_range(-10, 10))
			sprite(holder, pick(g, "item"), Vector2(w * 0.18, h * 0.4), h * 0.14)
		"landscape":
			sprite(holder, pick(g, "building_fantasy" if genre in ["RPG", "Adventure", "Strategy"] else "building_town"), Vector2(w * g.randf_range(0.55, 0.8), h * 0.82), h * 0.42)
			for k in 3:
				sprite(holder, pick(g, "tree"), Vector2(g.randf() * w, h * 0.86), h * g.randf_range(0.18, 0.32))
			sprite(holder, pick(g, hc), Vector2(w * 0.25, h * 0.98), h * 0.36, false, tint)
		"pop_grid":
			var t3 := pick(g, hc)
			for gy in 4:
				for gx in 3:
					sprite(holder, t3, Vector2(w * (0.18 + gx * 0.32), h * (0.28 + gy * 0.24)), h * 0.18, (gx + gy) % 2 == 1, Color.from_hsv(fmod(pal[3].h + (gx + gy) * 0.12, 1.0), 0.5, 1.0))
		"spotlight":
			gradient(holder, rr, Color(pal[3], 0.55), Color(0, 0, 0, 0), true)
			var dark := Color(0.05, 0.03, 0.06) if genre == "Horror" or g.randf() < 0.5 else Color.WHITE
			sprite(holder, pick(g, hc), Vector2(w * 0.5, h * 1.0), h * 0.8, g.randf() < 0.5, dark)
		"badge":
			BoxArt.circle(holder, Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.4, pal[3], 24)
			BoxArt.circle(holder, Vector2(w * 0.5, h * 0.5), minf(w, h) * 0.33, Color(pal[4], 0.9), 24)
			sprite(holder, pick(g, hc), Vector2(w * 0.5, h * 0.72), h * 0.42, false, tint)
		"panels":
			for k in 3:
				var pr := Rect2(w * (0.04 + (k % 2) * 0.48), h * (0.06 + (k / 2) * 0.48), w * 0.44, h * 0.42)
				if k == 2:
					pr = Rect2(w * 0.04, h * 0.54, w * 0.92, h * 0.42)
				BoxArt.rect(holder, pr.grow(1.5), Color(0.05, 0.05, 0.05))
				BoxArt.rect(holder, pr, Color.from_hsv(fmod(pal[3].h + k * 0.2, 1.0), 0.45, 0.85))
				sprite(holder, pick(g, hc if k != 1 else fc), Vector2(pr.get_center().x, pr.end.y), pr.size.y * 0.85, k == 1)
	# Small foreground sparkle / coins on some covers.
	if g.randf() < 0.35 and h > 60:
		for k in 3:
			sprite(holder, pick(g, "item"), Vector2(g.randf_range(0.1, 0.9) * w, g.randf_range(0.15, 0.45) * h), h * 0.08)


static func _backdrop(c: Control, r: Rect2, g: RandomNumberGenerator, pal: Array, genre: String, layout: String) -> void:
	var w := r.size.x
	var h := r.size.y
	gradient(c, r, pal[0], pal[1])
	if genre in ["Shooter"] or layout.begins_with("space"):
		for k in 30:
			var s := g.randf_range(0.6, 2.0)
			BoxArt.rect(c, Rect2(g.randf() * w, g.randf() * h, s, s), Color(1, 1, 0.95, g.randf_range(0.4, 1.0)))
		BoxArt.circle(c, Vector2(g.randf_range(0.6, 0.9) * w, h * 0.22), h * g.randf_range(0.1, 0.2), Color.from_hsv(g.randf(), 0.5, 0.75), 22)
		return
	if layout in ["pop_grid", "badge", "spotlight", "versus", "panels"]:
		if layout == "versus" or (layout == "badge" and g.randf() < 0.5):
			var ctr := Vector2(w * 0.5, h * 0.5)
			for k in 12:
				var a0 := TAU * k / 12.0
				BoxArt.poly(c, PackedVector2Array([ctr, ctr + Vector2(cos(a0), sin(a0)) * w * 1.5, ctr + Vector2(cos(a0 + 0.26), sin(a0 + 0.26)) * w * 1.5]), Color(pal[4], 0.12))
		return
	# Scenery: optional painted backdrop, sky body, clouds, horizon, ground.
	if g.randf() < 0.3:
		var bd := pick(g, "backdrop")
		if bd != null:
			var tr := TextureRect.new()
			tr.texture = bd
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			tr.size = r.size
			tr.modulate = Color.WHITE.lerp(pal[1], 0.3)
			c.add_child(tr)
	sprite(c, pick(g, "sky_body"), Vector2(g.randf_range(0.15, 0.85) * w, h * 0.32), h * 0.16)
	for k in 2:
		sprite(c, pick(g, "cloud"), Vector2(g.randf() * w, h * g.randf_range(0.18, 0.4)), h * 0.1, false, Color(1, 1, 1, 0.85))
	if g.randf() < 0.5:
		sprite(c, pick(g, "hills"), Vector2(w * 0.5, h * 1.0), h * 0.5, g.randf() < 0.5, Color.WHITE.lerp(pal[2], 0.5))
	else:
		BoxArt.rect(c, Rect2(0, h * 0.8, w, h * 0.2), pal[2])
	if genre == "Horror":
		sprite(c, tex("res://assets/sprites/cover/tree/treeDead.png"), Vector2(w * 0.85, h * 0.85), h * 0.5, false, Color(0.05, 0.03, 0.05))


## Hardware box art: the real 3D render of the product on one of several
## studio looks (rays, spotlight, floor shine, lifestyle with a happy player,
## accessory spread).
static func product(c: Control, r: Rect2, key: String, base: Color, render: Texture2D) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = hash(key + "product")
	var holder := Control.new()
	holder.position = r.position
	holder.size = r.size
	holder.clip_contents = true
	c.add_child(holder)
	var w := r.size.x
	var h := r.size.y
	var hue := fmod(base.h + g.randf_range(-0.08, 0.08) + 1.0, 1.0)
	var look := g.randi() % 5
	var top := Color.from_hsv(hue, 0.5, 0.35)
	var bot := Color.from_hsv(fmod(hue + 0.08, 1.0), 0.65, 0.12)
	if look == 2:
		top = Color(0.95, 0.94, 0.9)
		bot = Color.from_hsv(hue, 0.25, 0.8)
	gradient(holder, Rect2(0, 0, w, h), top, bot)
	match look:
		0:
			var ctr := Vector2(w * 0.5, h * 0.55)
			for k in 14:
				var a0 := TAU * k / 14.0
				BoxArt.poly(holder, PackedVector2Array([ctr, ctr + Vector2(cos(a0), sin(a0)) * w * 1.4, ctr + Vector2(cos(a0 + 0.22), sin(a0 + 0.22)) * w * 1.4]), Color(1, 1, 1, 0.08))
		1:
			gradient(holder, Rect2(0, 0, w, h), Color(1, 0.95, 0.8, 0.5), Color(0, 0, 0, 0), true)
		2:
			for k in 4:
				BoxArt.rect(holder, Rect2(0, h * 0.12 + k * 5, w, 3), base.lerp(Color.WHITE, k * 0.2))
		3:
			BoxArt.rect(holder, Rect2(0, h * 0.72, w, h * 0.28), Color.from_hsv(hue, 0.3, 0.25))
			sprite(holder, pick(g, "hero_person"), Vector2(w * 0.8, h * 0.98), h * 0.55, true)
		4:
			for k in 5:
				sprite(holder, pick(g, "item"), Vector2(g.randf_range(0.1, 0.9) * w, g.randf_range(0.2, 0.9) * h), h * 0.1)
	# Floor shine under the product.
	var shadow := PackedVector2Array()
	for k in 20:
		var a1 := TAU * k / 20.0
		shadow.append(Vector2(w * 0.5, h * 0.84) + Vector2(cos(a1) * w * 0.34, sin(a1) * h * 0.05))
	BoxArt.poly(holder, shadow, Color(0, 0, 0, 0.3))
	var tr := TextureRect.new()
	tr.texture = render
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var sz := minf(w, h) * (0.95 if look != 3 else 0.75)
	tr.size = Vector2(sz, sz)
	tr.position = Vector2((w - sz) * (0.5 if look != 3 else 0.25), h * 0.86 - sz)
	holder.add_child(tr)
	if g.randf() < 0.5:
		var star: String = ["NEW!", "WOW!", "HOT!", "PRO!", "2X!"][g.randi() % 5]
		BoxArt.circle(holder, Vector2(w * 0.82, h * 0.22), 13, Color(1, 0.85, 0.15), 10)
		var l := Label.new()
		l.text = star
		l.add_theme_font_override("font", font("bangers"))
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", Color(0.75, 0.1, 0.1))
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.position = Vector2(w * 0.82 - 13, h * 0.22 - 8)
		l.size = Vector2(26, 16)
		l.rotation_degrees = -12
		holder.add_child(l)


# ---------------------------------------------------------------- titles

## Draws a title in the genre's lettering, shrunk to fit `size`.
static func title(c: Control, text: String, pos: Vector2, size: Vector2, fs: int, col: Color, item: Dictionary, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var genre := String(item.get("genre", "Action"))
	if String(item.get("kind", "game")) != "game":
		genre = "Hardware"
	var g := RandomNumberGenerator.new()
	g.seed = hash(String(item.get("id", text)) + "font")
	var opts: Array = GENRE_FONTS.get(genre, ["bungee"])
	var fname := String(opts[g.randi() % opts.size()])
	var f := font(fname)
	var size_px := fs
	if fname != "jersey":
		size_px = int(fs * 0.82)
	if fname == "press":
		size_px = int(fs * 0.5)
	if fname == "monoton" or fname == "rubik":
		size_px = int(fs * 0.7)
	while size_px > 7:
		var m := f.get_multiline_string_size(text, align, size.x, size_px)
		if m.y <= size.y and m.x <= size.x + 1:
			break
		size_px -= 1
	var shadow := Color(0.03, 0.02, 0.05, 0.9) if col.get_luminance() > 0.4 else Color(1, 1, 1, 0.6)
	var accent := Color.from_hsv(g.randf(), 0.75, 1.0)
	var style := g.randi() % 3
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col if style != 2 else accent.lightened(0.3))
	l.add_theme_color_override("font_outline_color", shadow if style != 1 else accent.darkened(0.4))
	l.add_theme_constant_override("outline_size", maxi(3, int(size_px / 4.0)))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.add_theme_constant_override("line_spacing", -int(size_px * 0.25))
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = pos
	l.size = size
	l.clip_text = true
	l.pivot_offset = size * 0.5
	if genre in ["Action", "Fighting", "Platformer", "Sports", "Racing"] and g.randf() < 0.5:
		l.rotation_degrees = g.randf_range(-5, 5)
	c.add_child(l)


# ---------------------------------------------------------------- publishers

## Each publisher: a fixed logo colour, shape and stripe so its games match.
static func publisher_mark(c: Control, item: Dictionary, w: float, h: float) -> void:
	var pub := String(item.get("pub", ""))
	if pub == "" or String(item.get("kind", "game")) != "game":
		return
	var g := RandomNumberGenerator.new()
	g.seed = hash(pub)
	var col := Color.from_hsv(g.randf(), g.randf_range(0.5, 0.9), g.randf_range(0.6, 1.0))
	var stripe := g.randi() % 4
	match stripe:
		0:
			BoxArt.rect(c, Rect2(w - 5, 0, 5, h), col)
		1:
			BoxArt.poly(c, PackedVector2Array([Vector2(w, h - 26), Vector2(w, h), Vector2(w - 26, h)]), col)
		2:
			BoxArt.rect(c, Rect2(0, h - 4, w, 4), col)
	var shape := g.randi() % 3
	var short := pub.split(" ")[0].to_upper().left(8)
	var fnames := ["russo", "bungee", "right", "blackops", "audio", "lucky", "marker"]
	var f := font(String(fnames[g.randi() % fnames.size()]))
	var bw := 30.0 + short.length() * 2.0
	var at := Vector2(w - bw - 4, h - 16) if stripe != 1 else Vector2(4, h - 16)
	if shape == 0:
		BoxArt.rect(c, Rect2(at, Vector2(bw, 12)), col)
	elif shape == 1:
		BoxArt.rect(c, Rect2(at + Vector2(6, 0), Vector2(bw - 12, 12)), col)
		BoxArt.circle(c, at + Vector2(6, 6), 6, col, 10)
		BoxArt.circle(c, at + Vector2(bw - 6, 6), 6, col, 10)
	else:
		BoxArt.poly(c, PackedVector2Array([at + Vector2(4, 0), at + Vector2(bw, 0), at + Vector2(bw - 4, 12), at + Vector2(0, 12)]), col)
	var l := Label.new()
	l.text = short
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08) if col.get_luminance() > 0.55 else Color.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = at
	l.size = Vector2(bw, 12)
	l.clip_text = true
	c.add_child(l)
