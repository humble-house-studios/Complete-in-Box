extends Control
## Loot-case reveal laid over a new item card (entering a stop, digging the
## bin, checking the back room): a strip of mini rarity cards, dealt from the
## stop's real pull odds, races sideways past a gold marker, slows, teases the
## card next door and lands on the item's tier (COMMON / UNCOMMON / RARE /
## GRAIL) with a flash in the tier colour, then fades to show the card.
## The mini cards copy the real cards: dark smoked body, thick platform edge,
## tier-coloured frame, art window with the tier's symbol, name band.
## Drawn in _draw (no child nodes) so a whole table of reels stays cheap.
## No class_name (TV self-update): preload("res://scripts/ui/slot_reel.gd").

const Subjects := preload("res://scripts/gfx/subjects.gd")
const SYMS := ["coin", "glowing_star", "gem_stone", "crown"]
const NAMES := ["COMMON", "UNCOMMON", "RARE!", "GRAIL!!"]
const SHORT := ["COMMON", "UNCOMMON", "RARE", "GRAIL"]
const HOLD := [0.3, 0.4, 0.7, 1.2]
const STRIP := 34  # cards in the strip
const LAND := 28  # index of the card that lands under the marker

var tier := 0
var tier_col := Color.WHITE
var delay := 0.0
var dur := 1.5
## [common, uncommon, rare, grail] weights the strip is dealt from.
var odds: Array = [70, 25, 5, 0]
## Platform colours for the cards' left edges (the active platforms).
var plat_cols: Array = []
## Returns true while the screen is still covered (a loading card): the reel waits.
var blocked: Callable
## Called with ("tick", pitch) as cards pass, ("stop", tier) when it lands.
var sound: Callable
var reveal: Array = []  # Controls faded in when the reel is done.

var _t := 0.0
var _x := 0.0  # strip position, in cards
var _end := 0.0  # where the strip stops (a little off centre, CS-style)
var _last := -1
var _phase := 0  # 0 wait, 1 spin, 2 settle, 3 landed, 4 fade
var _hold := 0.0
var _fade := 1.0
var _flash := 0.0
var _cards: Array = []  # [tier, edge colour]
var _tex: Array = []
var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in SYMS:
		_tex.append(_load(k))
	_font = load("res://assets/fonts/cover/Bangers-Regular.ttf")
	_deal()
	for c in reveal:
		if is_instance_valid(c):
			(c as CanvasItem).modulate.a = 0.0


func _load(k: String) -> Texture2D:
	var list: Array = Subjects.SPRITES.get(k, [])
	if list.is_empty():
		return null
	return CoverComp.tex(String(list[0]))


## Deal the strip from the odds. The landing card is the real tier; the one
## just past it is sometimes a better card you nearly got (only tiers that
## can actually drop here).
func _deal() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var w: Array = []
	var total := 0.0
	for i in 4:
		var x := maxf(float(odds[i]) if i < odds.size() else 0.0, 0.0)
		w.append(x)
		total += x
	if total <= 0.0:
		w = [1.0, 0.0, 0.0, 0.0]
		total = 1.0
	_cards.clear()
	for i in STRIP:
		var r := rng.randf() * total
		var t := 0
		for k in 4:
			r -= float(w[k])
			if r < 0.0:
				t = k
				break
		var col: Color = plat_cols[rng.randi() % plat_cols.size()] if not plat_cols.is_empty() else Color("7a6aa8")
		_cards.append([t, col])
	_cards[LAND][0] = clampi(tier, 0, 3)
	if tier < 3 and rng.randf() < 0.45:
		var better: Array = []
		for k in range(tier + 1, 4):
			if float(w[k]) > 0.0:
				better.append(k)
		if not better.is_empty():
			_cards[LAND + (1 if rng.randf() < 0.65 else -1)][0] = better[rng.randi() % better.size()]
	# Stop a little off the middle of the card, then nudge into place.
	_end = LAND + rng.randf_range(-0.38, 0.38)


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
			# Ease out (quintic): a blur at first, crawling past the last few.
			var e := 1.0 - pow(1.0 - k, 5.0)
			_x = _end * e
			_tick(k)
			if k >= 1.0:
				_phase = 2
				_t = 0.0
		2:
			_t += delta
			var k := clampf(_t / 0.22, 0.0, 1.0)
			_x = lerpf(_end, float(LAND), k * k * (3.0 - 2.0 * k))
			if k >= 1.0:
				_x = LAND
				_phase = 3
				_flash = 1.0
				_hold = HOLD[clampi(tier, 0, 3)]
				if sound.is_valid():
					sound.call("stop", tier)
		3:
			_flash = maxf(_flash - delta * 3.0, 0.0)
			_hold -= delta
			if _hold <= 0.0:
				_phase = 4
		4:
			_fade -= delta * 4.0
			for c in reveal:
				if is_instance_valid(c):
					(c as CanvasItem).modulate.a = 1.0 - maxf(_fade, 0.0)
			if _fade <= 0.0:
				queue_free()
				return
	queue_redraw()


func _tick(k: float) -> void:
	var idx := int(floorf(_x + 0.5))
	if idx != _last:
		_last = idx
		if sound.is_valid():
			sound.call("tick", 0.85 + k * 0.6)


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
	if w <= 0.0 or h <= 0.0 or _cards.is_empty():
		return
	var a := clampf(_fade, 0.0, 1.0)
	var landed := _phase >= 3
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.05, 0.1, 0.97 * a))
	if landed:
		# Flash behind the strip in the tier colour (behind, so the card stays crisp).
		var glow := _flash * (0.6 if tier >= 2 else 0.3) + (0.18 if tier >= 2 else 0.06)
		draw_rect(Rect2(Vector2.ZERO, size), Color(tier_col, glow * a))
	# Track: a darker band the cards run along.
	var ch := minf(h * 0.68, w * 0.9)
	var cw := ch * 0.74
	var gap := cw * 0.1
	var step := cw + gap
	var cy := h * 0.44
	var track := Rect2(0, cy - ch * 0.5 - 6, w, ch + 12)
	draw_rect(track, Color(0.03, 0.02, 0.05, 0.9 * a))
	draw_line(Vector2(0, track.position.y), Vector2(w, track.position.y), Color(1, 1, 1, 0.08 * a), 2.0)
	draw_line(Vector2(0, track.end.y), Vector2(w, track.end.y), Color(1, 1, 1, 0.08 * a), 2.0)
	var mid := w * 0.5
	var speed := 0.0
	if _phase == 1:
		var k := clampf(_t / dur, 0.0, 1.0)
		speed = 5.0 * pow(1.0 - k, 4.0)  # cards per second-ish, for the blur
	var first := int(floorf(_x - mid / step)) - 1
	var last := int(ceilf(_x + mid / step)) + 1
	for i in range(maxi(first, 0), mini(last, _cards.size() - 1) + 1):
		var cx := mid + (i - _x) * step
		var r := Rect2(cx - cw * 0.5, cy - ch * 0.5, cw, ch)
		var win := landed and i == LAND
		var dim := 1.0
		if landed and not win:
			dim = 0.35
		_mini_card(r, int(_cards[i][0]), _cards[i][1], a * dim, speed, win)
	# Edge fades so cards slide in from the dark.
	var fw := minf(w * 0.18, 60.0)
	for k in 8:
		var fa := (1.0 - k / 8.0) * 0.9 * a
		var sw := fw / 8.0
		draw_rect(Rect2(k * sw, track.position.y, sw + 1, track.size.y), Color(0.07, 0.05, 0.1, fa))
		draw_rect(Rect2(w - (k + 1) * sw, track.position.y, sw + 1, track.size.y), Color(0.07, 0.05, 0.1, fa))
	# The marker: gold line with triangles top and bottom.
	var mc := Color(1.0, 0.82, 0.25, a) if not landed else Color(tier_col.lightened(0.3), a)
	draw_line(Vector2(mid, track.position.y), Vector2(mid, track.end.y), Color(mc, 0.85 * a), 3.0)
	var ts := 9.0
	draw_colored_polygon(PackedVector2Array([Vector2(mid - ts, track.position.y - 4), Vector2(mid + ts, track.position.y - 4), Vector2(mid, track.position.y + ts)]), mc)
	draw_colored_polygon(PackedVector2Array([Vector2(mid - ts, track.end.y + 4), Vector2(mid + ts, track.end.y + 4), Vector2(mid, track.end.y - ts)]), mc)
	# Landing flash + rarity call-out.
	if landed:
		if tier >= 2:
			var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.012)
			for k in 3:
				draw_rect(Rect2(Vector2.ZERO, size).grow(-k * 3.0), Color(tier_col, (0.9 - k * 0.25) * a * pulse), false, 3.0)
		if _font != null:
			var txt: String = NAMES[clampi(tier, 0, 3)]
			var fsz := int(clampf(h * 0.14, 18, 34))
			var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
			var p := Vector2(mid - tw * 0.5, minf(h - 6.0, track.end.y + fsz * 1.05))
			draw_string_outline(_font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, 8, Color(0, 0, 0, a))
			draw_string(_font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(tier_col.lightened(0.3), a))


## One mini card, styled like the real ones.
func _mini_card(r: Rect2, t: int, edge: Color, a: float, blur: float, win: bool) -> void:
	var tc: Color = Catalog.TIER_COLORS[t]
	if win:
		var pop := 1.0 + 0.12 * _flash + (0.04 if t >= 2 else 0.0)
		r = Rect2(r.get_center() - r.size * pop * 0.5, r.size * pop)
		# Glow behind the winner.
		for k in 4:
			draw_rect(r.grow(4.0 + k * 4.0), Color(tc, (0.32 - k * 0.07) * a))
	# Motion smear: a faint ghost behind while the strip is flying.
	if blur > 0.4:
		draw_rect(Rect2(r.position + Vector2(r.size.x * 0.12, 0), r.size), Color(tc, 0.12 * a))
	# Shadow, frame, body.
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.5 * a))
	var bw := 2.0 if t < 2 else 3.0
	draw_rect(r, Color(tc if t >= 1 else edge.lightened(0.1), a))
	var body := r.grow(-bw)
	draw_rect(body, Color(Color(0.07, 0.06, 0.09).lerp(edge.darkened(0.7), 0.3), a))
	# Thick platform edge on the left, like the shelf / sale cards.
	var ew := maxf(4.0, r.size.x * 0.07)
	draw_rect(Rect2(body.position, Vector2(ew, body.size.y)), Color(edge, a))
	var inner := Rect2(body.position + Vector2(ew + 3, 3), body.size - Vector2(ew + 6, 6))
	# Art window, with a tier-coloured wash that gets richer up the tiers.
	var art := Rect2(inner.position, Vector2(inner.size.x, inner.size.y * 0.7))
	draw_rect(art, Color(edge.darkened(0.6), a))
	var wash: float = [0.12, 0.25, 0.4, 0.55][t]
	for k in 5:
		var band := Rect2(art.position.x, art.position.y + art.size.y * k / 5.0, art.size.x, art.size.y / 5.0 + 1)
		draw_rect(band, Color(tc, wash * (k + 1) / 5.0 * a))
	if t >= 2:
		# Diagonal foil stripes on rares and grails.
		var off := fmod(Time.get_ticks_msec() * 0.06, art.size.x)
		for k in 3:
			var x0 := art.position.x + fmod(off + k * art.size.x / 3.0, art.size.x)
			var pts := PackedVector2Array([Vector2(x0, art.end.y), Vector2(x0 + 6, art.end.y), Vector2(minf(x0 + 6 + art.size.y * 0.4, art.end.x), art.position.y), Vector2(minf(x0 + art.size.y * 0.4, art.end.x), art.position.y)])
			draw_colored_polygon(pts, Color(1, 1, 1, 0.12 * a))
	var tex: Texture2D = _tex[t] if t < _tex.size() else null
	if tex != null:
		var s := minf(art.size.x, art.size.y) * (0.78 if t >= 2 else 0.66)
		draw_texture_rect(tex, Rect2(art.get_center() - Vector2(s, s) * 0.5, Vector2(s, s)), false, Color(1, 1, 1, a))
	# Name band in the tier colour.
	var nb := Rect2(inner.position.x, art.end.y + 3, inner.size.x, inner.end.y - art.end.y - 3)
	draw_rect(nb, Color(tc if t >= 1 else Color(1, 1, 1, 0.8), a))
	if _font != null:
		var txt: String = SHORT[t]
		var fsz := int(clampf(nb.size.y * 0.8, 10, 24))
		var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		if tw > nb.size.x - 4.0:
			fsz = int(fsz * (nb.size.x - 4.0) / tw)
			tw = _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		var p := Vector2(nb.get_center().x - tw * 0.5, nb.get_center().y + fsz * 0.36)
		draw_string(_font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0.08, 0.06, 0.1, a))
