extends Control
## Slot-machine reveal laid over a new item card (entering a stop, digging the
## bin, checking the back room): a reel of lucky symbols whirls, slows, lands
## on the item's rarity (coin = common, star = uncommon, gem = RARE, crown =
## GRAIL) with a flash in the tier colour, then slides away to show the card.
## Drawn in _draw (no child nodes) so a whole table of reels stays cheap.
## No class_name (TV self-update): preload("res://scripts/ui/slot_reel.gd").

const Subjects := preload("res://scripts/gfx/subjects.gd")
const SPIN := ["cherries", "bell", "coin", "gem_stone", "glowing_star", "crown", "four_leaf_clover", "slot_machine"]
const FINAL := ["coin", "glowing_star", "gem_stone", "crown"]
const NAMES := ["COMMON", "UNCOMMON", "RARE!", "GRAIL!!"]
const HOLD := [0.25, 0.32, 0.55, 1.0]

var tier := 0
var tier_col := Color.WHITE
var delay := 0.0
var dur := 0.9
## Returns true while the screen is still covered (a loading card): the reel waits.
var blocked: Callable
## Called with ("tick", pitch) as symbols pass, ("stop", tier) when it lands.
var sound: Callable
var reveal: Array = []  # Controls faded in when the reel is done.

var _t := 0.0
var _off := 0.0
var _last_sym := 0
var _phase := 0  # 0 wait, 1 spin, 2 landed, 3 fade
var _hold := 0.0
var _fade := 1.0
var _tex: Array = []
var _final: Texture2D
var _font: Font
var _seed := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_seed = randi()
	for k in SPIN:
		_tex.append(_load(k))
	_final = _load(FINAL[clampi(tier, 0, 3)])
	_font = load("res://assets/fonts/cover/Bangers-Regular.ttf")
	for c in reveal:
		if is_instance_valid(c):
			(c as CanvasItem).modulate.a = 0.0


func _load(k: String) -> Texture2D:
	var list: Array = Subjects.SPRITES.get(k, [])
	if list.is_empty():
		return null
	return CoverComp.tex(String(list[0]))


func _process(delta: float) -> void:
	if blocked.is_valid() and blocked.call():
		return
	match _phase:
		0:
			delay -= delta
			if delay <= 0.0:
				_phase = 1
		1:
			_t += delta
			var k := clampf(_t / dur, 0.0, 1.0)
			# Fast, then easing out as it settles.
			var speed := lerpf(16.0, 2.5, k * k)
			_off += speed * delta
			var sym := int(_off)
			if sym != _last_sym:
				_last_sym = sym
				if sound.is_valid():
					sound.call("tick", 0.9 + k * 0.5)
			if k >= 1.0:
				_phase = 2
				_hold = HOLD[clampi(tier, 0, 3)]
				if sound.is_valid():
					sound.call("stop", tier)
		2:
			_hold -= delta
			if _hold <= 0.0:
				_phase = 3
		3:
			_fade -= delta * 4.0
			for c in reveal:
				if is_instance_valid(c):
					(c as CanvasItem).modulate.a = 1.0 - maxf(_fade, 0.0)
			if _fade <= 0.0:
				queue_free()
				return
	queue_redraw()


## Skip straight to the card (a tap, or a rebuild).
func finish() -> void:
	for c in reveal:
		if is_instance_valid(c):
			(c as CanvasItem).modulate.a = 1.0
	queue_free()


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed):
		finish()
		accept_event()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var a := clampf(_fade, 0.0, 1.0)
	var landed := _phase >= 2
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.07, 0.05, 0.1, 0.97 * a))
	# Reel window in the middle, chrome rails top and bottom.
	var wh := minf(h * 0.78, w * 0.9)
	var win := Rect2(w * 0.5 - wh * 0.6, h * 0.5 - wh * 0.5, wh * 1.2, wh)
	draw_rect(win.grow(4), Color(0.75, 0.72, 0.8, a))
	draw_rect(win, Color(0.98, 0.96, 0.9, a) if not landed else Color(tier_col.lightened(0.6), a))
	var s := wh * 0.62
	if not landed:
		var frac: float = _off - floorf(_off)
		for k in range(-1, 3):
			var idx := absi(hash(_seed + int(_off) + k)) % _tex.size()
			var t: Texture2D = _tex[idx]
			if t == null:
				continue
			var cy: float = win.position.y + win.size.y * 0.5 + (frac - k) * s * 1.1
			var rr := Rect2(w * 0.5 - s * 0.5, cy - s * 0.5, s, s)
			var clip := rr.intersection(win)
			if clip.size.y <= 0.0:
				continue
			var src := Rect2(0, (clip.position.y - rr.position.y) / s * t.get_height(), t.get_width(), clip.size.y / s * t.get_height())
			# Motion-blur feel: squash vertically while fast.
			draw_texture_rect_region(t, clip, src, Color(1, 1, 1, a))
		# Glass shading top and bottom of the window.
		for k in 6:
			var sh := Color(0, 0, 0, (0.3 - k * 0.05) * a)
			draw_rect(Rect2(win.position.x, win.position.y + k * 4, win.size.x, 4), sh)
			draw_rect(Rect2(win.position.x, win.end.y - (k + 1) * 4, win.size.x, 4), sh)
	else:
		var pop := 1.0 + 0.25 * clampf(_hold * 4.0, 0.0, 1.0) * (1.0 if tier >= 2 else 0.4)
		var fs := s * pop
		if _final != null:
			draw_texture_rect(_final, Rect2(w * 0.5 - fs * 0.5, win.get_center().y - fs * 0.55, fs, fs), false, Color(1, 1, 1, a))
		if tier >= 2:
			for k in 3:
				draw_rect(r.grow(-k * 3.0), Color(tier_col, (0.9 - k * 0.25) * a), false, 3.0)
	# Pay line.
	draw_line(Vector2(win.position.x - 8, win.get_center().y), Vector2(win.position.x, win.get_center().y), Color(1, 0.3, 0.3, a), 4.0)
	draw_line(Vector2(win.end.x, win.get_center().y), Vector2(win.end.x + 8, win.get_center().y), Color(1, 0.3, 0.3, a), 4.0)
	if landed and _font != null:
		var txt: String = NAMES[clampi(tier, 0, 3)]
		var fsz := int(clampf(h * 0.16, 18, 34))
		var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		var p := Vector2(w * 0.5 - tw * 0.5, minf(h - 6, win.end.y + fsz * 0.95))
		draw_string_outline(_font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, 8, Color(0, 0, 0, a))
		draw_string(_font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(tier_col.lightened(0.3), a))
