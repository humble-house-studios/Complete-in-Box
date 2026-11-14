extends Control
## Loot-case reveal laid over a new item card (entering a stop, digging the
## bin, checking the back room): a long strip of mini playing cards, dealt from
## the stop's real pull odds, rolls sideways past a gold marker like a CS case
## (cards curve round a drum: they squash, dip and fan out toward the edges and
## lean into the motion while it races), slows, teases the card next door and
## lands on the item's tier (COMMON / UNCOMMON / RARE / GRAIL) with a flash in
## the tier colour, then fades to show the card.
## The mini cards copy the play cards: ink outline, cream border (silver for
## rare, gold for grail), platform-coloured striped face, tier-framed art
## window with the tier's symbol, corner indices and a parchment name plate.
## Drawn in _draw (no child nodes) so a whole table of reels stays cheap.
## No class_name (TV self-update): preload("res://scripts/ui/slot_reel.gd").

const Subjects := preload("res://scripts/gfx/subjects.gd")
const SYMS := ["coin", "glowing_star", "gem_stone", "crown"]
const NAMES := ["COMMON", "UNCOMMON", "RARE!", "GRAIL!!"]
const SHORT := ["COMMON", "UNCOMMON", "RARE", "GRAIL"]
const HOLD := [0.3, 0.4, 0.7, 1.2]
const STRIP := 64  # cards in the strip
const LAND := 56  # index of the card that lands under the marker

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


const CREAM := [Color("f2ead8"), Color("f2ead8"), Color("dbe6f7"), Color("ffd45a")]
const INK := Color("17131f")
const LETTER := ["C", "U", "R", "G"]


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
	var ch := minf(h * 0.6, w * 0.78)
	var cw := ch * 0.7
	var step := cw * 1.04
	var cy := h * 0.43
	# Track: the house felt (purple mat, gold trim) the cards roll along.
	var track := Rect2(0, cy - ch * 0.5 - 10, w, ch + 20)
	draw_rect(track, Color(0.2, 0.1, 0.3, 0.95 * a))
	for k in 4:
		draw_rect(Rect2(0, track.position.y + track.size.y * k / 4.0, w, track.size.y / 8.0), Color(1, 1, 1, 0.025 * a))
	draw_line(Vector2(0, track.position.y), Vector2(w, track.position.y), Color(1.0, 0.8, 0.3, 0.7 * a), 2.0)
	draw_line(Vector2(0, track.end.y), Vector2(w, track.end.y), Color(1.0, 0.55, 0.2, 0.8 * a), 3.0)
	var mid := w * 0.5
	var speed := 0.0
	if _phase == 1:
		var k := clampf(_t / dur, 0.0, 1.0)
		speed = pow(1.0 - k, 4.0)  # 1 = flat out, 0 = stopped
	# The drum: cards sit on a cylinder of radius R seen from the front.
	var rad := maxf(w * 0.62, step * 1.6)
	var reach := int(ceilf(rad * 1.6 / step)) + 1
	var vis: Array = []
	for i in range(maxi(int(_x) - reach, 0), mini(int(_x) + reach, _cards.size() - 1) + 1):
		var ang := (i - _x) * step / rad
		if absf(ang) < 1.5:
			vis.append([absf(ang), i, ang])
	vis.sort_custom(func(p, q): return p[0] > q[0])  # far ones first, centre on top
	for v in vis:
		var i: int = v[1]
		var ang: float = v[2]
		var c := cos(ang)
		var px := mid + rad * sin(ang)
		var py := cy + (1.0 - c) * ch * 0.22
		var rot := ang * 0.22 - speed * 0.14
		var win := landed and i == LAND
		var sc := Vector2(c, 0.86 + 0.14 * c)
		if win:
			sc *= 1.0 + 0.12 * _flash + (0.05 if tier >= 2 else 0.0)
			rot = 0.0
		var shade := (1.0 - c) * 0.75
		if landed and not win:
			shade = maxf(shade, 0.6)
		draw_set_transform(Vector2(px, py), rot, sc)
		_mini_card(Rect2(-cw * 0.5, -ch * 0.5, cw, ch), int(_cards[i][0]), _cards[i][1], a, speed, win, shade)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# The marker: gold line with triangles top and bottom.
	var mc := Color(1.0, 0.82, 0.25, a) if not landed else Color(tier_col.lightened(0.3), a)
	draw_line(Vector2(mid, track.position.y), Vector2(mid, track.end.y), Color(mc, 0.55 * a), 2.0)
	var ts := 10.0
	draw_colored_polygon(PackedVector2Array([Vector2(mid - ts, track.position.y - 6), Vector2(mid + ts, track.position.y - 6), Vector2(mid, track.position.y + ts)]), mc)
	draw_colored_polygon(PackedVector2Array([Vector2(mid - ts, track.end.y + 6), Vector2(mid + ts, track.end.y + 6), Vector2(mid, track.end.y - ts)]), mc)
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


## A rounded rectangle as a polygon (3 steps per corner, cheap enough for a strip).
func _rrect(r: Rect2, rad: float, col: Color) -> void:
	rad = minf(rad, minf(r.size.x, r.size.y) * 0.5)
	if rad < 1.0:
		draw_rect(r, col)
		return
	var pts := PackedVector2Array()
	var cs := [Vector2(r.end.x - rad, r.position.y + rad), Vector2(r.end.x - rad, r.end.y - rad), Vector2(r.position.x + rad, r.end.y - rad), Vector2(r.position.x + rad, r.position.y + rad)]
	for k in 4:
		for s in 4:
			var t: float = -PI * 0.5 + (k + s / 3.0) * PI * 0.5
			pts.append(cs[k] + Vector2(cos(t), sin(t)) * rad)
	draw_colored_polygon(pts, col)


## One mini playing card, styled like the real play cards, centred on 0,0
## (the caller's transform rolls, squashes and tilts it).
func _mini_card(r: Rect2, t: int, edge: Color, a: float, blur: float, win: bool, shade: float) -> void:
	var tc: Color = Catalog.TIER_COLORS[t]
	var u := r.size.x / 100.0
	if win:
		for k in 4:
			_rrect(r.grow(4.0 + k * 4.0), 10 * u + k * 4.0, Color(tc, (0.32 - k * 0.07) * a))
	# Motion smear: faint ghosts trailing while the strip is flying.
	if blur > 0.25:
		for k in 2:
			_rrect(Rect2(r.position + Vector2(r.size.x * (0.16 + k * 0.16), 0), r.size), 10 * u, Color(tc.lerp(edge, 0.5), 0.1 * blur * a))
	# Shadow, ink outline, cream / silver / gold border.
	_rrect(Rect2(r.position + Vector2(4 * u, 6 * u), r.size), 10 * u, Color(0, 0, 0, 0.45 * a))
	_rrect(r, 10 * u, Color(INK, a))
	var border := r.grow(-2.0)
	_rrect(border, 9 * u, Color(CREAM[t], a))
	# Platform face with soft diagonal stripes.
	var face := border.grow(-5 * u)
	_rrect(face, 6 * u, Color(edge.darkened(0.15), a))
	for k in 5:
		var x0 := face.position.x + face.size.x * (k * 0.3 - 0.3)
		var x1 := x0 + face.size.x * 0.12
		var pts := PackedVector2Array([Vector2(maxf(x0, face.position.x), face.end.y - 6 * u), Vector2(maxf(x1, face.position.x), face.end.y - 6 * u), Vector2(minf(x1 + face.size.y * 0.5, face.end.x), face.position.y + 6 * u), Vector2(minf(x0 + face.size.y * 0.5, face.end.x), face.position.y + 6 * u)])
		if pts[0].x < pts[3].x:
			draw_colored_polygon(pts, Color(1, 1, 1, 0.07 * a))
	# Corner indices: tier letter over a little gem, like a playing card.
	var isz := int(clampf(18 * u, 9, 30))
	if _font != null:
		var lp := face.position + Vector2(5 * u, isz * 0.95)
		draw_string_outline(_font, lp, LETTER[t], HORIZONTAL_ALIGNMENT_LEFT, -1, isz, maxi(2, int(4 * u)), Color(INK, a))
		draw_string(_font, lp, LETTER[t], HORIZONTAL_ALIGNMENT_LEFT, -1, isz, Color(tc.lightened(0.25), a))
		_gem(lp + Vector2(isz * 0.28, isz * 0.45), isz * 0.24, tc, a)
	# Art window, tier-framed, with the tier symbol.
	var art := Rect2(face.position + Vector2(face.size.x * 0.16, face.size.y * 0.2), Vector2(face.size.x * 0.68, face.size.y * 0.5))
	_rrect(art.grow(3 * u), 6 * u, Color(tc if t >= 1 else Color(1, 1, 1, 0.45), a))
	_rrect(art, 4 * u, Color(0.05, 0.04, 0.08, a))
	var wash: float = [0.1, 0.22, 0.36, 0.5][t]
	for k in 4:
		draw_rect(Rect2(art.position.x, art.position.y + art.size.y * k / 4.0, art.size.x, art.size.y / 4.0 + 1), Color(tc, wash * (k + 1) / 4.0 * a))
	var tex: Texture2D = _tex[t] if t < _tex.size() else null
	if tex != null:
		var s := minf(art.size.x, art.size.y) * (0.84 if t >= 2 else 0.7)
		draw_texture_rect(tex, Rect2(art.get_center() - Vector2(s, s) * 0.5, Vector2(s, s)), false, Color(1, 1, 1, a))
	# Parchment name plate.
	var nb := Rect2(face.position.x + 6 * u, art.end.y + 8 * u, face.size.x - 12 * u, face.end.y - art.end.y - 14 * u)
	_rrect(nb, 4 * u, Color(Color("efe2c0"), a))
	draw_rect(Rect2(nb.position.x, nb.end.y - 3 * u, nb.size.x, 3 * u), Color(tc if t >= 1 else Color("b8a882"), a))
	if _font != null:
		var txt: String = SHORT[t]
		var fsz := int(clampf(nb.size.y * 0.72, 8, 24))
		var tw := _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		if tw > nb.size.x - 4.0:
			fsz = maxi(6, int(fsz * (nb.size.x - 4.0) / tw))
			tw = _font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz).x
		draw_string(_font, Vector2(nb.get_center().x - tw * 0.5, nb.get_center().y + fsz * 0.34), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(INK, a))
	# Foil sweep on rares and grails.
	if t >= 2:
		var off := fmod(Time.get_ticks_msec() * 0.08, face.size.x * 1.6) - face.size.x * 0.3
		var x0 := face.position.x + off
		var pts := PackedVector2Array([Vector2(x0, face.end.y), Vector2(x0 + 10 * u, face.end.y), Vector2(x0 + 10 * u + face.size.y * 0.35, face.position.y), Vector2(x0 + face.size.y * 0.35, face.position.y)])
		for k in pts.size():
			pts[k].x = clampf(pts[k].x, face.position.x, face.end.x)
		draw_colored_polygon(pts, Color(1, 1, 1, (0.22 if t == 3 else 0.15) * a))
	# Darken cards rolling away round the drum (and the losers once it lands).
	if shade > 0.01:
		_rrect(r, 10 * u, Color(0.04, 0.02, 0.07, clampf(shade, 0.0, 0.85) * a))


func _gem(c: Vector2, s: float, col: Color, a: float) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.8, 0), c + Vector2(0, s), c + Vector2(-s * 0.8, 0)])
	draw_colored_polygon(pts, Color(INK, a))
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(c + (p - c) * 0.6)
	draw_colored_polygon(inner, Color(col.lightened(0.2), a))
