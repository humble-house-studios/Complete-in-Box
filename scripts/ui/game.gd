extends Control
## Complete In Box: the whole UI, built from Control nodes in code.
## The rules live in scripts/engine/run.gd; this file only draws the run's
## state and turns taps into Run actions. Screens are rebuilt from scratch
## after every action (cheap at this size, and impossible to get out of sync).
##
## Portrait (phones) = one column. Landscape (Steam) = two columns.

const SafeArea := preload("res://scripts/ui/safe_area.gd")

## Dev shortcuts (+$100, +1 ante) at Home. Set false before shipping.
const DEV := true

const BG := Color("15131d")
const PANEL := Color("221f2e")
const PANEL_HI := Color("2f2a42")
const INK := Color("f2ead8")
const MUTED := Color("9a93ab")
const GOOD := Color("5ee08a")
const BAD := Color("ff6b6b")
const GOLD := Color("ffcc33")
const STICKER := Color("ff8a3d")
const HOT_C := Color("ff7043")
const COLD_C := Color("64b5f6")
const SAVE_PATH := "user://save.cfg"

var run: Run
var screen: String = "title"
## Tests turn this on to skip every animation delay.
var fast: bool = false

var _safe: MarginContainer
var _root_box: VBoxContainer
var _overlay: Control
var _sheet: Control
var _toast: PanelContainer
var _toast_label: Label
var _toast_tween: Tween
var _sfx: Sfx
var _margins := Vector4(16, 16, 16, 16)
var _last_inset := Vector4(-1, -1, -1, -1)
var _refresh_queued := false
var _busy := false
var _skip := false
var _save := {"best_ante": 0, "best_appraisal": 0, "runs": 0, "wins": 0}


func _ready() -> void:
	theme = _make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_safe = MarginContainer.new()
	_safe.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_safe)
	_root_box = VBoxContainer.new()
	_root_box.add_theme_constant_override("separation", 10)
	_safe.add_child(_root_box)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	_build_toast()
	_sfx = Sfx.new()
	add_child(_sfx)
	_load_save()
	get_viewport().size_changed.connect(_on_resized)
	var poll := Timer.new()
	poll.wait_time = 1.0
	poll.autostart = true
	poll.timeout.connect(_apply_safe_area)
	add_child(poll)
	_on_resized()
	show_title()


# ================================================================ layout

func is_landscape() -> bool:
	var s := get_viewport_rect().size
	return s.x > s.y


func _on_resized() -> void:
	var base := Vector2i(1280, 720) if is_landscape() else Vector2i(720, 1280)
	if get_viewport() == get_window() and get_window().content_scale_size != base:
		get_window().content_scale_size = base
	_last_inset = Vector4(-1, -1, -1, -1)
	_apply_safe_area()
	request_refresh()


func _apply_safe_area() -> void:
	var inset := Vector4.ZERO
	if get_viewport() == get_window():
		inset = SafeArea.get_insets(get_viewport_rect().size)
	if inset == _last_inset:
		return
	_last_inset = inset
	var base := 16.0
	_margins = Vector4(base + inset.x, base + inset.y, base + inset.z, base + inset.w)
	_safe.add_theme_constant_override("margin_left", int(_margins.x))
	_safe.add_theme_constant_override("margin_top", int(_margins.y))
	_safe.add_theme_constant_override("margin_right", int(_margins.z))
	_safe.add_theme_constant_override("margin_bottom", int(_margins.w))


func _content_w() -> float:
	return get_viewport_rect().size.x - _margins.x - _margins.z


## Width of the main (left) column and the side (right) column.
func _main_w() -> float:
	return (_content_w() - 20.0) * 0.6 if is_landscape() else _content_w() - 12.0


func _side_w() -> float:
	return (_content_w() - 20.0) * 0.4 - 12.0 if is_landscape() else _content_w() - 12.0


func request_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	_do_refresh.call_deferred()


func _do_refresh() -> void:
	_refresh_queued = false
	if _root_box == null:
		return
	for c in _root_box.get_children():
		_root_box.remove_child(c)
		c.queue_free()
	match screen:
		"title": _build_title()
		"home": _build_home()
		"venue": _build_venue()
		"over": _build_over()
		"won": _build_won()
		_: pass


# ================================================================ theme + widgets

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 24
	t.set_color("font_color", "Label", INK)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.35))
	t.set_stylebox("normal", "Button", _box(PANEL_HI, 14))
	t.set_stylebox("hover", "Button", _box(PANEL_HI.lightened(0.07), 14))
	t.set_stylebox("pressed", "Button", _box(PANEL_HI.darkened(0.25), 14))
	t.set_stylebox("disabled", "Button", _box(PANEL.darkened(0.15), 14))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 16))
	return t


func _box(color: Color, radius: int = 14, border: Color = Color(0, 0, 0, 0), width: int = 0, stripe: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14 + stripe
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	if width > 0:
		s.set_border_width_all(width)
		s.border_color = border
	if stripe > 0:
		s.border_width_left = stripe
		s.border_color = border
	return s


func _label(text: String, fs: int = 24, color: Color = INK, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _title_label(text: String, fs: int, color: Color) -> Label:
	var l := _label(text, fs, color)
	l.add_theme_color_override("font_outline_color", Color("0b0a10"))
	l.add_theme_constant_override("outline_size", maxi(4, int(fs / 7.0)))
	return l


func _button(text: String, cb: Callable, color: Color = PANEL_HI, fs: int = 24, height: float = 88.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_size_override("font_size", fs)
	b.add_theme_stylebox_override("normal", _box(color, 14))
	b.add_theme_stylebox_override("hover", _box(color.lightened(0.08), 14))
	b.add_theme_stylebox_override("pressed", _box(color.darkened(0.25), 14))
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(cb)
	if color.get_luminance() > 0.55:
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, Color("15131d"))
	return b


func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)


func _hbox(sep: int = 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


func _vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


func _spacer(vertical: bool = true) -> Control:
	var c := Control.new()
	if vertical:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


func _panel(color: Color = PANEL, border: Color = Color(0, 0, 0, 0), width: int = 0) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(color, 16, border, width))
	return p


func _section(parent: Control, text: String, right: Control = null) -> void:
	var h := _hbox()
	h.add_child(_title_label(text, 26, GOLD))
	h.add_child(_spacer(false))
	if right != null:
		h.add_child(right)
	parent.add_child(h)


## A scrolling column. ratio splits the row in landscape.
func _scroll_col(parent: Control, ratio: float) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_stretch_ratio = ratio
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent.add_child(sc)
	var v := _vbox(14)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	return v


## [main column, side column]: the same column in portrait.
func _columns() -> Array:
	if is_landscape():
		var hb := _hbox(20)
		hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_root_box.add_child(hb)
		return [_scroll_col(hb, 0.6), _scroll_col(hb, 0.4)]
	var v := _scroll_col(_root_box, 1.0)
	return [v, v]


## GridContainer sized for the width; returns [grid, cell_width].
func _grid(avail: float, min_w: float, sep: int = 10) -> Array:
	var cols := maxi(1, int(floor((avail + sep) / (min_w + sep))))
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", sep)
	g.add_theme_constant_override("v_separation", sep)
	var cell := (avail - sep * (cols - 1)) / cols
	return [g, cell]


func _money(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-$" if n < 0 else "$") + s + out


# ================================================================ cards

func _card_shell(w: float, h: float, stripe: Color, cb: Callable, bg: Color = PANEL) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(w, h)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.add_theme_stylebox_override("normal", _box(bg, 12, stripe, 0, 10))
	b.add_theme_stylebox_override("hover", _box(bg.lightened(0.06), 12, stripe, 0, 10))
	b.add_theme_stylebox_override("pressed", _box(bg.darkened(0.2), 12, stripe, 0, 10))
	b.pressed.connect(cb)
	return b


func _card_inner(b: Button) -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 20)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	b.add_child(m)
	var v := _vbox(2)
	m.add_child(v)
	return v


func _tag_row(item: Dictionary, fs: int = 17) -> HBoxContainer:
	var plat := Catalog.platform(String(item["plat"]))
	var row := _hbox(8)
	row.add_child(_label(String(plat["short"]), fs, plat["color"]))
	var cond := String(item["cond"])
	row.add_child(_label(String(Catalog.COND_SHORT[cond]), fs, Catalog.COND_COLORS[cond]))
	if int(item["grade"]) > 0:
		row.add_child(_label("GRADE %d" % item["grade"], fs, GOLD))
	row.add_child(_spacer(false))
	var tier := int(item["tier"])
	if tier > 0:
		var tn := String(Catalog.TIER_NAMES[tier]).to_upper()
		if fs < 16:
			tn = ["", "UNC", "RARE", "GRAIL"][tier]
		row.add_child(_label(tn, fs - 2, Catalog.TIER_COLORS[tier]))
	return row


func _trend_tag(item: Dictionary) -> String:
	var p := String(item["plat"])
	if run.hot.has(p):
		return " HOT"
	if run.cold.has(p):
		return " COLD"
	return ""


func _sticker(text: String, color: Color = STICKER) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _box(color, 8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 2
	s.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", s)
	p.add_child(_label(text, 22, Color("15131d")))
	return p


func _offer_card(i: int, w: float) -> Button:
	var o: Dictionary = run.stock[i]
	var item: Dictionary = o["item"]
	var b := _card_shell(w, 150, Catalog.platform(String(item["plat"]))["color"], func(): _open_offer(i))
	var v := _card_inner(b)
	v.add_child(_tag_row(item))
	var nm := _label(String(item["name"]), 22, INK, true)
	nm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(nm)
	var bottom := _hbox()
	var worth: String
	if run.shows_exact():
		worth = "Worth " + _money(run.market_value(item)) + _trend_tag(item)
	else:
		var est: Array = o["est"]
		worth = "~%s-%s?" % [_money(int(est[0])), _money(int(est[1]))]
	bottom.add_child(_label(worth, 18, MUTED))
	bottom.add_child(_spacer(false))
	if bool(o["bargain"]):
		bottom.add_child(_label("BARGAIN", 15, GOOD))
	bottom.add_child(_sticker(_money(int(o["price"]))))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _lot_card(i: int, w: float) -> Button:
	var lot: Dictionary = run.lots[i]
	var storage: bool = run.venue["id"] == "storage"
	var b := _card_shell(w, 150, GOLD, func(): _open_lot(i), Color("2b2433"))
	var v := _card_inner(b)
	var items: Array = lot["items"]
	v.add_child(_label(("STORAGE UNIT #%d" % (i + 1)) if storage else "MYSTERY BOX LOT", 20, GOLD))
	var peek: Array = []
	for k in mini(int(lot["peek"]), items.size()):
		peek.append(String(items[k]["name"]))
	var txt := "%d items. You can see: %s" % [items.size(), ", ".join(peek)]
	if bool(lot["bought"]):
		txt = "SOLD to you."
	var l := _label(txt, 18, INK, true)
	l.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(l)
	var bottom := _hbox()
	bottom.add_child(_spacer(false))
	if not bool(lot["bought"]):
		bottom.add_child(_sticker(_money(int(lot["price"])), GOLD))
	v.add_child(bottom)
	_ignore_mouse(b)
	if bool(lot["bought"]):
		b.disabled = true
	return b


func _auction_card(i: int, w: float) -> Button:
	var a: Dictionary = run.auctions[i]
	var item: Dictionary = a["item"]
	var b := _card_shell(w, 150, Catalog.platform(String(item["plat"]))["color"], func(): _open_auction(i))
	var v := _card_inner(b)
	v.add_child(_tag_row(item))
	var nm := _label("AUCTION: " + String(item["name"]), 21, INK, true)
	nm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(nm)
	var bottom := _hbox()
	var status := "no bid yet"
	var sc := MUTED
	if int(a["my_max"]) > 0:
		if run.winning(i):
			status = "WINNING"
			sc = GOOD
		else:
			status = "OUTBID"
			sc = BAD
	bottom.add_child(_label(status, 18, sc))
	bottom.add_child(_spacer(false))
	bottom.add_child(_sticker(_money(int(a["bid"])), Color("4fd9a0")))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _shelf_tile(item: Dictionary, w: float, state: String = "") -> Button:
	var bg := PANEL if state == "" else PANEL.darkened(0.3)
	var b := _card_shell(w, 104, Catalog.platform(String(item["plat"]))["color"], func(): _open_shelf_item(int(item["uid"]), state), bg)
	var v := _card_inner(b)
	v.add_child(_tag_row(item, 14))
	var nm := _label(String(item["name"]), 16, INK if state == "" else MUTED, true)
	nm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	nm.max_lines_visible = 2
	v.add_child(nm)
	var bottom := _hbox(4)
	if state == "":
		bottom.add_child(_label(_money(run.market_value(item)), 18, GOLD))
		var t := _trend_tag(item)
		if t != "":
			bottom.add_child(_label(t.strip_edges(), 13, HOT_C if t == " HOT" else COLD_C))
	else:
		bottom.add_child(_label(state, 15, COLD_C))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _empty_tile(w: float) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, 104)
	p.add_theme_stylebox_override("panel", _box(Color(1, 1, 1, 0.03), 12, Color(1, 1, 1, 0.08), 2))
	var l := _label("empty", 15, Color(MUTED, 0.5))
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p


func _shelf_grid(parent: Control, avail: float) -> void:
	var ap := run.appraise()
	var head := _label("Appraises %s" % _money(int(ap["total"])), 20, GOLD)
	_section(parent, "YOUR SHELF %d/%d" % [run.slots_used(), run.shelf_cap], head)
	var gc: Array = _grid(avail, 150, 8)
	var g: GridContainer = gc[0]
	var w: float = gc[1]
	for it in run.shelf:
		g.add_child(_shelf_tile(it, w))
	for it in run.listings:
		g.add_child(_shelf_tile(it, w, "LISTED"))
	for gr in run.grading:
		g.add_child(_shelf_tile(gr["item"], w, "AT GRADER"))
	for k in run.free_slots():
		g.add_child(_empty_tile(w))
	parent.add_child(g)


# ================================================================ header

func _header() -> void:
	var h := _hbox(12)
	var left := _vbox(0)
	var ante_txt := "ANTE %d/%d" % [run.ante, Balance.ANTES_TO_WIN]
	if run.endless:
		ante_txt = "ANTE %d  ENDLESS" % run.ante
	left.add_child(_title_label(ante_txt, 30, INK))
	var stop_txt := "Stop %d of 3: %s" % [run.stop + 1, run.slot_name()]
	if screen == "venue":
		stop_txt = String(run.venue["name"])
	left.add_child(_label(stop_txt, 19, run.venue.get("color", MUTED) if screen == "venue" else MUTED))
	h.add_child(left)
	h.add_child(_spacer(false))
	if screen == "venue":
		var tv := _vbox(6)
		tv.add_child(_label("TIME %d" % run.time_left, 15, MUTED))
		var pips := _hbox(5)
		for k in maxi(run.time_left, 1):
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(16, 22)
			pip.color = COLD_C if run.time_left > 0 else Color(BAD, 0.6)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
		tv.add_child(pips)
		h.add_child(tv)
	var cv := _vbox(0)
	cv.add_child(_label("CASH", 15, MUTED))
	cv.add_child(_title_label(_money(run.cash), 34, GOLD))
	h.add_child(cv)
	_root_box.add_child(h)


func _market_panel(parent: Control) -> void:
	var p := _panel(PANEL)
	var v := _vbox(4)
	p.add_child(v)
	var row := _hbox(16)
	for plat in run.hot:
		row.add_child(_label("HOT: %s x%.1f" % [Catalog.platform(plat)["name"], run.trend_mult(plat)], 19, HOT_C))
	for plat in run.cold:
		row.add_child(_label("COLD: %s x%.2f" % [Catalog.platform(plat)["name"], run.trend_mult(plat)], 19, COLD_C))
	v.add_child(row)
	v.add_child(_label("Rumor: %s could be hot next stop." % Catalog.platform(run.rumor)["name"], 18, MUTED, true))
	parent.add_child(p)


# ================================================================ title

func show_title() -> void:
	screen = "title"
	request_refresh()


func _build_title() -> void:
	_root_box.add_child(_spacer())
	var cart := _panel(Color("3a3646"), Color("6b6580"), 4)
	var cv := _vbox(4)
	cart.add_child(cv)
	var stripe := ColorRect.new()
	stripe.color = Color("d64545")
	stripe.custom_minimum_size = Vector2(0, 14)
	cv.add_child(stripe)
	for pair in [["COMPLETE", INK], ["IN BOX", GOLD]]:
		var l := _title_label(pair[0], 76, pair[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(l)
	var tag := _label("Dig. Haggle. Flip. Hoard. Get appraised.", 22, MUTED)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(tag)
	var stripe2 := ColorRect.new()
	stripe2.color = Color("3a6fd6")
	stripe2.custom_minimum_size = Vector2(0, 14)
	cv.add_child(stripe2)
	_root_box.add_child(cart)
	_root_box.add_child(_spacer())
	_root_box.add_child(_button("NEW RUN", start_new_run, STICKER, 34, 110))
	_root_box.add_child(_button("HOW TO PLAY", _show_how_to, PANEL_HI, 24, 88))
	var best := "No runs yet."
	if int(_save["runs"]) > 0:
		best = "Best: Ante %d  |  Best shelf %s  |  Wins %d" % [_save["best_ante"], _money(int(_save["best_appraisal"])), _save["wins"]]
	var bl := _label(best, 19, MUTED)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(bl)
	_root_box.add_child(_spacer())


func _show_how_to() -> void:
	_open_sheet("How to play", [
		["Each ante has 3 stops: The Hunt, The Shop, and Online. Buy low, sell high, and stock your shelf.", INK],
		["When you leave a stop, your shelf is appraised like a Balatro hand: every item adds its value, then sets and perks add Mult. Beat the target or you're out of business.", INK],
		["THE HUNT: cheap, but you only see guesses. Haggling and digging cost Time. Mystery lots are a gamble.", Color("e0a84a")],
		["THE SHOP: exact prices. They buy your stuff, grade it, and fix it.", Color("5fb3d9")],
		["ONLINE: Buy It Now, bid on auctions, list your own stuff. It all settles when you leave, and there's a boss twist.", Color("4fd9a0")],
		["SETS: 3+ items from one platform = +Mult. Console + game + accessory = x1.5. Every GRAIL = +1 Mult.", GOLD],
		["LONG GAME: collectibles gain value the longer you hold them; fads lose it. Watch Hot/Cold and the rumor.", MUTED],
		["Between stops, spend cash on Perks. Leftover Time and savings pay out.", MUTED],
	], [])


# ================================================================ run flow

func start_new_run(seed_value: int = 0) -> void:
	run = Run.new()
	run.start(seed_value)
	_save["runs"] = int(_save["runs"]) + 1
	_write_save()
	screen = "home"
	_close_sheet()
	request_refresh()


func _act(res: Dictionary, good: String = "coin") -> void:
	if bool(res.get("ok", false)):
		if String(res.get("msg", "")) != "":
			_toast_msg(String(res["msg"]), INK)
		_sfx.play(good)
	else:
		_toast_msg(String(res.get("msg", "Can't do that.")), BAD)
		_sfx.play("buzz")
	request_refresh()


# ================================================================ home

func _build_home() -> void:
	_header()
	var cols := _columns()
	var main: VBoxContainer = cols[0]
	var side: VBoxContainer = cols[1]
	# Next stop.
	var target_row := _hbox()
	target_row.add_child(_label("Appraisal target", 20, MUTED))
	target_row.add_child(_spacer(false))
	target_row.add_child(_title_label(_money(run.target()), 30, INK))
	_section(main, "NEXT: " + run.slot_name().to_upper())
	main.add_child(target_row)
	var boss := Venues.boss(run.boss_id)
	if run.is_boss_stop():
		var bp := _panel(Color("3a1f2a"), BAD, 2)
		var bv := _vbox(2)
		bp.add_child(bv)
		bv.add_child(_label("BOSS: " + String(boss["name"]), 22, BAD))
		bv.add_child(_label(String(boss["desc"]), 19, INK, true))
		main.add_child(bp)
	else:
		main.add_child(_label("This ante's boss: %s (%s)" % [boss["name"], boss["desc"]], 18, MUTED, true))
	_market_panel(main)
	_section(main, "WHERE TO?")
	for id in run.venue_choices:
		main.add_child(_venue_button(String(id)))
	if DEV:
		var dev := _hbox()
		dev.add_child(_button("DEV +$100", _dev_cash, Color("444055"), 18, 60))
		dev.add_child(_button("DEV +1 ANTE", _dev_ante, Color("444055"), 18, 60))
		main.add_child(dev)
	# Perk shop.
	var reroll := _button("Reroll %s" % _money(run.reroll_cost), func(): _act(run.reroll_perks(), "tick"), PANEL_HI, 18, 56)
	_section(side, "PERK SHOP", reroll)
	var gc: Array = _grid(_side_w(), 200, 10)
	var g: GridContainer = gc[0]
	for pid in run.perk_offers:
		g.add_child(_perk_card(String(pid), gc[1], false))
	if not run.upgrade_offer.is_empty():
		g.add_child(_upgrade_card(gc[1]))
	side.add_child(g)
	_section(side, "PERKS %d/%d" % [run.perks.size(), run.perk_cap])
	if run.perks.is_empty():
		side.add_child(_label("None yet. Perks bend the rules in your favor.", 18, MUTED, true))
	else:
		var pg: Array = _grid(_side_w(), 200, 10)
		var gg: GridContainer = pg[0]
		for pid in run.perks:
			gg.add_child(_perk_card(String(pid), pg[1], true))
		side.add_child(gg)
	_shelf_grid(side, _side_w())


func _venue_button(id: String) -> Button:
	var d := Venues.get_def(id)
	var b := _card_shell(0, 150, d["color"], func(): go_to_venue(id), PANEL)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := _card_inner(b)
	var top := _hbox()
	top.add_child(_title_label(String(d["name"]), 28, d["color"]))
	top.add_child(_spacer(false))
	top.add_child(_label("GO >", 22, INK))
	v.add_child(top)
	var blurb := _label(String(d["blurb"]), 18, INK, true)
	blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(blurb)
	v.add_child(_label(_venue_facts(d), 16, MUTED, true))
	_ignore_mouse(b)
	b.custom_minimum_size.y = 170
	return b


func _venue_facts(d: Dictionary) -> String:
	var bits: Array = ["Time %d" % (int(d["time"]) + run.time_bonus + (1 if run.has_perk("extra_hour") else 0))]
	if not bool(d["exact"]):
		bits.append("guesswork prices")
	if float(d["haggle"]) > 0.0:
		bits.append("haggle")
	if float(d["sell"]) > 0.0:
		bits.append("buys at %d%%" % int(round(float(d["sell"]) * 100.0)))
	if int(d["lots"]) > 0:
		bits.append("mystery lots")
	if int(d.get("auctions", 0)) > 0:
		bits.append("auctions")
	if d.has("list"):
		bits.append("list your items")
	if bool(d.get("grading", false)):
		bits.append("grading")
	if bool(d.get("repair", false)):
		bits.append("repairs")
	return " | ".join(bits)


func _perk_card(id: String, w: float, owned: bool) -> Button:
	var d := Perks.get_def(id)
	var b := _card_shell(w, 170, Color("b07cff") if not owned else GOOD, func(): _open_perk(id, owned), PANEL)
	var v := _card_inner(b)
	v.add_child(_label(String(d["name"]), 21, INK, true))
	var desc := _label(String(d["desc"]), 16, MUTED, true)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var bottom := _hbox()
	bottom.add_child(_spacer(false))
	if owned:
		bottom.add_child(_label("sell %s" % _money(int(d["cost"]) / 2), 16, MUTED))
	else:
		bottom.add_child(_sticker(_money(int(d["cost"]))))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _upgrade_card(w: float) -> Button:
	var d := run.upgrade_offer
	var b := _card_shell(w, 170, GOLD, func(): _open_upgrade(), Color("2b2433"))
	var v := _card_inner(b)
	v.add_child(_label("UPGRADE", 14, GOLD))
	v.add_child(_label(String(d["name"]), 21, INK, true))
	var desc := _label(String(d["desc"]), 16, MUTED, true)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var bottom := _hbox()
	bottom.add_child(_spacer(false))
	bottom.add_child(_sticker(_money(int(d["cost"])), GOLD))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _open_perk(id: String, owned: bool) -> void:
	var d := Perks.get_def(id)
	if owned:
		_open_sheet(String(d["name"]), [[String(d["desc"]), INK]], [
			["Sell for %s" % _money(int(d["cost"]) / 2), func(): _act(run.sell_perk(id), "coin"), BAD],
		])
	else:
		_open_sheet(String(d["name"]), [[String(d["desc"]), INK]], [
			["Buy for %s" % _money(int(d["cost"])), func(): _act(run.buy_perk(id), "coin"), STICKER],
		])


func _open_upgrade() -> void:
	var d := run.upgrade_offer
	_open_sheet(String(d["name"]), [[String(d["desc"]), INK]], [
		["Buy for %s" % _money(int(d["cost"])), func(): _act(run.buy_upgrade(), "coin"), GOLD],
	])


func go_to_venue(id: String) -> void:
	var res := run.enter_venue(id)
	if bool(res["ok"]):
		screen = "venue"
		_sfx.play("land")
		if not String(res["msg"]).begins_with("Welcome"):
			_toast_msg(String(res["msg"]), GOLD)
	else:
		_toast_msg(String(res["msg"]), BAD)
	request_refresh()


func _dev_cash() -> void:
	run.cash += 100
	request_refresh()


func _dev_ante() -> void:
	run.ante += 1
	run._roll_boss()
	run._prepare_home()
	request_refresh()


# ================================================================ venue

func _build_venue() -> void:
	_header()
	var ap := run.appraise()
	var total := int(ap["total"])
	var tgt := run.target()
	var bar := _panel(PANEL)
	var bh := _hbox()
	bar.add_child(bh)
	bh.add_child(_label("Shelf appraises", 18, MUTED))
	bh.add_child(_title_label(_money(total), 28, GOOD if total >= tgt else INK))
	bh.add_child(_label("of", 18, MUTED))
	bh.add_child(_title_label(_money(tgt), 28, GOLD))
	bh.add_child(_spacer(false))
	bh.add_child(_label("x%.2f Mult" % float(ap["mult"]), 18, Color("b07cff")))
	_root_box.add_child(bar)
	if run.is_boss_stop():
		var boss := Venues.boss(run.boss_id)
		_root_box.add_child(_label("BOSS: %s - %s" % [boss["name"], boss["desc"]], 18, BAD, true))
	var cols := _columns()
	var main: VBoxContainer = cols[0]
	var side: VBoxContainer = cols[1]
	var gc: Array = _grid(_main_w(), 300, 10)
	var g: GridContainer = gc[0]
	var w: float = gc[1]
	var label := "FOR SALE"
	if run.venue.get("bin", false):
		label = "BUY IT NOW"
	if not run.stock.is_empty():
		_section(main, label)
		for i in run.stock.size():
			g.add_child(_offer_card(i, w))
		main.add_child(g)
	elif int(run.venue["stock"]) > 0:
		main.add_child(_label("Picked clean.", 20, MUTED))
	if not run.lots.is_empty():
		_section(main, "LOTS")
		var lg: Array = _grid(_main_w(), 300, 10)
		for i in run.lots.size():
			lg[0].add_child(_lot_card(i, lg[1]))
		main.add_child(lg[0])
	if not run.auctions.is_empty():
		_section(main, "AUCTIONS")
		var ag: Array = _grid(_main_w(), 300, 10)
		for i in run.auctions.size():
			ag[0].add_child(_auction_card(i, ag[1]))
		main.add_child(ag[0])
	if int(run.venue["dig"]) > 0:
		var dig := _button("%s  (1 Time)" % run.venue["dig_label"], func(): _act(run.dig(), "tick"), PANEL_HI, 22, 80)
		dig.disabled = run.time_left <= 0
		main.add_child(dig)
	var hint := _venue_hint()
	if hint != "":
		main.add_child(_label(hint, 17, MUTED, true))
	_shelf_grid(side, _side_w())
	var done := _button("APPRAISE & LEAVE   %s / %s" % [_money(total), _money(tgt)], _confirm_done, STICKER if total >= tgt else Color("8a4a3a"), 26, 96)
	_root_box.add_child(done)


func _venue_hint() -> String:
	var bits: Array = []
	if run.sell_rate() > 0.0:
		bits.append("Tap your items to sell them here (%d%% of value)." % int(round(run.sell_rate() * 100.0)))
	if run.can_list():
		bits.append("Tap your items to list them; listings sell when you leave.")
	if run.can_grade():
		bits.append("Grading sends an item away for a stop; it comes back worth up to x3.")
	return " ".join(bits)


func _confirm_done() -> void:
	if _busy:
		return
	var total := int(run.appraise()["total"])
	if total < run.target() and run.listings.is_empty() and run.auctions.is_empty():
		_open_sheet("Short of the target", [
			["Your shelf appraises %s but you need %s. Leaving now ends the run." % [_money(total), _money(run.target())], BAD],
		], [["Appraise anyway", finish_stop, BAD]])
		return
	finish_stop()


func _open_offer(i: int) -> void:
	if i >= run.stock.size():
		return
	var o: Dictionary = run.stock[i]
	var item: Dictionary = o["item"]
	var lines: Array = _item_lines(item, run.shows_exact())
	if not run.shows_exact():
		var est: Array = o["est"]
		lines.append(["Seller's guess says %s to %s. Who knows?" % [_money(int(est[0])), _money(int(est[1]))], MUTED])
	if bool(o["bin"]) and not run.has_perk("bubble_wrap"):
		lines.append(["Online: might arrive a condition worse than listed.", MUTED])
	var actions: Array = [["Buy for %s" % _money(int(o["price"])), func(): _do_buy(i), STICKER]]
	if float(run.venue["haggle"]) > 0.0 and not bool(o["haggled"]) and run.time_left > 0:
		actions.append(["Haggle  (1 Time, %d%% odds)" % int(round(_haggle_odds() * 100.0)), func(): _do_haggle(i), PANEL_HI])
	elif bool(o["haggled"]):
		lines.append(["Already haggled.", MUTED])
	_open_sheet(String(item["name"]), lines, actions)


func _haggle_odds() -> float:
	return minf(1.0, float(run.venue["haggle"]) + (0.25 if run.has_perk("silver_tongue") else 0.0))


func _do_buy(i: int) -> void:
	var exact := run.shows_exact()
	var price := int(run.stock[i]["price"]) if i < run.stock.size() else 0
	var res := run.buy(i)
	if bool(res["ok"]) and not exact:
		var value := int(res["value"])
		var diff := value - price
		var msg := "%s  Turns out it's worth %s (%s%s)." % [res["msg"], _money(value), "+" if diff >= 0 else "", _money(diff)]
		res["msg"] = msg
		_act(res, "grail" if diff > 100 else "coin")
		return
	_act(res, "coin")


func _do_haggle(i: int) -> void:
	var res := run.haggle(i)
	_act(res, "haggle" if bool(res.get("success", false)) else "buzz")
	if bool(res.get("ok", false)) and i < run.stock.size():
		_open_offer.call_deferred(i)


func _open_lot(i: int) -> void:
	var lot: Dictionary = run.lots[i]
	if bool(lot["bought"]):
		return
	var items: Array = lot["items"]
	var lines: Array = [["%d items inside. What you can see:" % items.size(), INK]]
	for k in mini(int(lot["peek"]), items.size()):
		var it: Dictionary = items[k]
		lines.append(["- %s (%s %s)" % [it["name"], Catalog.platform(String(it["plat"]))["short"], it["cond"]], GOLD])
	lines.append(["The rest is a mystery. No room on the shelf? Extras get sold at 40%.", MUTED])
	_open_sheet("Mystery lot", lines, [["Buy the lot for %s" % _money(int(lot["price"])), func(): _do_lot(i), GOLD]])


func _do_lot(i: int) -> void:
	var res := run.buy_lot(i)
	if not bool(res["ok"]):
		_act(res)
		return
	request_refresh()
	_play_lot_reveal(res["items"], int(res["worth"]), String(res["msg"]))


func _open_auction(i: int) -> void:
	var a: Dictionary = run.auctions[i]
	var item: Dictionary = a["item"]
	var lines: Array = _item_lines(item, true)
	lines.append(["Current bid %s." % _money(int(a["bid"])), INK])
	if int(a["my_max"]) > 0:
		lines.append(["Your max bid: %s (%s)" % [_money(int(a["my_max"])), "winning" if run.winning(i) else "outbid"], GOOD if run.winning(i) else BAD])
	lines.append(["Your max is held until it ends. Snipers may jump in at the last second.", MUTED])
	var nb := run.next_bid(i)
	_open_sheet("Auction", lines, [["Bid up to %s" % _money(nb), func(): _do_bid(i), Color("4fd9a0")]])


func _do_bid(i: int) -> void:
	var res := run.bid(i)
	var ok := bool(res["ok"])
	_act(res, "haggle" if ok and run.winning(i) else "buzz")
	if ok:
		_open_auction.call_deferred(i)


func _item_lines(item: Dictionary, exact: bool) -> Array:
	var plat := Catalog.platform(String(item["plat"]))
	var tier := int(item["tier"])
	var desc := "%s  |  %s  |  %s" % [plat["name"], item["cond"], Catalog.TIER_NAMES[tier]]
	if int(item["grade"]) > 0:
		desc += "  |  Graded %d" % item["grade"]
	var lines: Array = [[desc, plat["color"]]]
	if exact:
		lines.append(["Worth %s right now.%s" % [_money(run.market_value(item)), _trend_tag(item)], GOLD])
	if (item["tags"] as Array).has("fad"):
		lines.append(["FAD: loses value every stop you hold it.", HOT_C])
	elif tier >= 1 or item["cond"] == "Mint" or item["cond"] == "Sealed":
		lines.append(["Collectible: gains value every stop you hold it.", GOOD])
	return lines


func _open_shelf_item(uid: int, state: String) -> void:
	if _busy:
		return
	if state == "LISTED":
		for it in run.listings:
			if int(it["uid"]) == uid:
				_open_sheet(String(it["name"]), [["Listed. It sells when you leave this stop.", INK]],
					[["Pull the listing", func(): _act(run.unlist(uid), "tick"), PANEL_HI]])
		return
	if state != "":
		_open_sheet("At the grader", [["Comes back next stop with a grade from 6 to 10.", INK]], [])
		return
	var item := run.find_item(uid)
	if item.is_empty():
		return
	var lines := _item_lines(item, true)
	lines.append(["Paid %s  |  Held %d stop%s" % [_money(int(item["paid"])), item["held"], "" if int(item["held"]) == 1 else "s"], MUTED])
	var actions: Array = []
	if screen == "venue":
		if run.sell_rate() > 0.0:
			actions.append(["Sell for %s" % _money(run.sell_price(item)), func(): _act(run.sell(uid), "coin"), GOOD])
		if run.can_list():
			actions.append(["List for auction", func(): _act(run.list_item(uid), "tick"), Color("4fd9a0")])
		if run.can_repair() and item["cond"] == "Damaged":
			actions.append(["Repair for %s" % _money(run.repair_cost(item)), func(): _act(run.repair(uid), "haggle"), PANEL_HI])
		if run.can_grade() and int(item["grade"]) == 0 and item["cond"] != "Damaged":
			actions.append(["Send to grading for %s" % _money(run.grade_cost(item)), func(): _act(run.send_to_grading(uid), "tick"), GOLD])
	actions.append(["Dump it for %s" % _money(Balance.DUMP_VALUE), func(): _act(run.dump(uid), "buzz"), Color("5a3a3a")])
	_open_sheet(String(item["name"]), lines, actions)


# ================================================================ appraisal

func finish_stop() -> void:
	if _busy or run.phase != Run.Phase.VENUE:
		return
	_close_sheet()
	var res := run.end_stop()
	screen = "appraisal"
	request_refresh()
	if int(res["appraisal"]["total"]) > int(_save["best_appraisal"]):
		_save["best_appraisal"] = int(res["appraisal"]["total"])
	_save["best_ante"] = maxi(int(_save["best_ante"]), run.ante)
	if run.phase == Run.Phase.WON:
		_save["wins"] = int(_save["wins"]) + 1
	_write_save()
	await _play_appraisal(res)


func _wait(t: float) -> void:
	if fast or _skip or not is_inside_tree():
		return
	await get_tree().create_timer(t).timeout


func _play_appraisal(res: Dictionary) -> void:
	_busy = true
	_skip = false
	_hide_toast()
	var ap: Dictionary = res["appraisal"]
	var tgt := run.target()
	var layer := ColorRect.new()
	layer.color = Color(BG, 0.97)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.gui_input.connect(_on_appraisal_input)
	layer.name = "Appraisal"
	_overlay.add_child(layer)
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 24)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(m)
	var v := _vbox(8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(v)
	v.add_child(_title_label("APPRAISAL", 44, GOLD))
	v.add_child(_label("Target %s" % _money(tgt), 22, MUTED))
	for e in res["events"]:
		v.add_child(_label(String(e), 18, Color("4fd9a0"), true))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.mouse_filter = Control.MOUSE_FILTER_PASS
	v.add_child(sc)
	var list := _vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var totals := _hbox(16)
	var chips_l := _title_label("$0", 36, Color("4fa3ff"))
	var x_l := _label("x", 26, MUTED)
	var mult_l := _title_label("1.00", 36, Color("ff5577"))
	totals.add_child(chips_l)
	totals.add_child(x_l)
	totals.add_child(mult_l)
	v.add_child(totals)
	var total_l := _title_label("", 52, INK)
	v.add_child(total_l)
	var items: Array = ap["items"]
	var d := minf(0.2, 2.4 / maxf(1.0, items.size()))
	var chips := 0
	var pitch := 0.8
	for row in items:
		var h := _hbox()
		h.add_child(_label("+" + _money(int(row["value"])), 22, Color("4fa3ff")))
		var n := String(row["name"])
		if not (row["notes"] as Array).is_empty():
			n += "  (" + ", ".join(row["notes"]) + ")"
		h.add_child(_label(n, 18, INK, true))
		list.add_child(h)
		chips += int(row["value"])
		chips_l.text = _money(chips)
		_sfx.play("tick", pitch)
		pitch = minf(2.0, pitch + 0.06)
		await _wait(d)
	var add := 0.0
	var times := 1.0
	for b in ap["bonuses"]:
		var txt: String
		if float(b["times"]) > 1.0:
			times *= float(b["times"])
			txt = "x%.1f Mult" % float(b["times"])
		else:
			add += float(b["add"])
			txt = "+%s Mult" % str(snappedf(float(b["add"]), 0.01))
		var h2 := _hbox()
		h2.add_child(_label(txt, 22, Color("ff5577")))
		h2.add_child(_label(String(b["label"]), 18, INK, true))
		list.add_child(h2)
		mult_l.text = "%.2f" % ((1.0 + add) * times)
		_sfx.play("tick", 1.4)
		await _wait(0.25)
	mult_l.text = "%.2f" % float(ap["mult"])
	await _wait(0.3)
	var total := int(ap["total"])
	var passed := bool(res["passed"])
	total_l.text = "= " + _money(total)
	total_l.add_theme_color_override("font_color", GOOD if passed else BAD)
	_sfx.play("pass" if passed else "fail")
	if passed:
		var r: Dictionary = res["rewards"]
		v.add_child(_label("CLEARED! Payout: stop %s + interest %s + leftover Time %s = %s" % [
			_money(int(r["base"])), _money(int(r["interest"])), _money(int(r["time"])), _money(int(r["total"]))], 20, GOOD, true))
		var label := "CONTINUE"
		if run.phase == Run.Phase.WON:
			label = "YOU WON. SEE RESULTS"
		v.add_child(_button(label, _after_appraisal, STICKER, 28, 96))
	else:
		v.add_child(_label("Short by %s. The appraiser shakes their head." % _money(tgt - total), 22, BAD, true))
		v.add_child(_button("SEE RESULTS", _after_appraisal, BAD, 28, 96))
	_busy = false


func _on_appraisal_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_skip = true


func _after_appraisal() -> void:
	var layer := _overlay.get_node_or_null("Appraisal")
	if layer != null:
		_overlay.remove_child(layer)
		layer.queue_free()
	match run.phase:
		Run.Phase.APPRAISAL:
			run.advance()
			screen = "home"
		Run.Phase.WON:
			screen = "won"
		_:
			screen = "over"
	request_refresh()


func _play_lot_reveal(items: Array, worth: int, msg: String) -> void:
	_busy = true
	_skip = false
	var layer := ColorRect.new()
	layer.color = Color(0, 0, 0, 0.85)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.gui_input.connect(_on_appraisal_input)
	layer.name = "Reveal"
	_overlay.add_child(layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(center)
	var p := _panel(PANEL, GOLD, 3)
	p.custom_minimum_size = Vector2(minf(640.0, _content_w()), 0)
	center.add_child(p)
	var v := _vbox(10)
	p.add_child(v)
	v.add_child(_title_label("OPENING THE LOT...", 32, GOLD))
	var reels: Array = []
	for it in items:
		var l := _label("? ? ?", 24, MUTED)
		v.add_child(l)
		reels.append(l)
	var pool := Catalog.ITEMS
	for k in items.size():
		var l: Label = reels[k]
		for spin in 9:
			l.text = String(pool[randi() % pool.size()]["name"])
			_sfx.play("spin", 0.8 + spin * 0.08)
			await _wait(0.045)
		var it: Dictionary = items[k]
		var tier := int(it["tier"])
		l.text = "%s  (%s %s)  %s" % [it["name"], Catalog.platform(String(it["plat"]))["short"], Catalog.COND_SHORT[it["cond"]], _money(run.market_value(it))]
		l.add_theme_color_override("font_color", Catalog.TIER_COLORS[tier])
		_sfx.play("grail" if tier >= 3 else "land")
		await _wait(0.25)
	v.add_child(_label(msg, 22, GOOD, true))
	v.add_child(_button("NICE", _close_reveal, STICKER, 26, 88))
	_busy = false
	request_refresh()


func _close_reveal() -> void:
	var layer := _overlay.get_node_or_null("Reveal")
	if layer != null:
		_overlay.remove_child(layer)
		layer.queue_free()


# ================================================================ end screens

func _build_over() -> void:
	_root_box.add_child(_spacer())
	var t := _title_label("OUT OF BUSINESS", 56, BAD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(t)
	_end_stats()
	_root_box.add_child(_spacer())
	_root_box.add_child(_button("NEW RUN", start_new_run, STICKER, 32, 104))
	_root_box.add_child(_button("TITLE", show_title, PANEL_HI, 24, 88))


func _build_won() -> void:
	_root_box.add_child(_spacer())
	var t := _title_label("CERTIFIED LEGEND", 56, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(t)
	_root_box.add_child(_label("You beat all %d antes. The collection is museum grade." % Balance.ANTES_TO_WIN, 22, INK, true))
	_end_stats()
	_root_box.add_child(_spacer())
	_root_box.add_child(_button("KEEP GOING (ENDLESS)", _go_endless, STICKER, 28, 100))
	_root_box.add_child(_button("NEW RUN", start_new_run, PANEL_HI, 24, 88))


func _go_endless() -> void:
	run.advance()
	screen = "home"
	request_refresh()


func _end_stats() -> void:
	var p := _panel(PANEL)
	var v := _vbox(6)
	p.add_child(v)
	var s := run.stats
	var rows := [
		["Reached", "Ante %d, stop %d" % [run.ante, run.stop + 1]],
		["Best appraisal", _money(int(s["best_appraisal"]))],
		["Items bought / sold", "%d / %d" % [s["bought"], s["sold"]]],
		["Flip profit", _money(int(s["profit"]))],
		["Best flip", ("%s (+%s)" % [s["best_flip_name"], _money(int(s["best_flip"]))]) if int(s["best_flip"]) > 0 else "-"],
		["Perks", ", ".join(run.perks.map(func(id): return Perks.get_def(id)["name"])) if not run.perks.is_empty() else "-"],
		["Seed", str(run.seed_value)],
	]
	for r in rows:
		var h := _hbox()
		h.add_child(_label(String(r[0]), 20, MUTED))
		h.add_child(_spacer(false))
		var val := _label(String(r[1]), 20, INK)
		val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(val)
		v.add_child(h)
	_root_box.add_child(p)


# ================================================================ sheet + toast

func _open_sheet(title: String, lines: Array, actions: Array) -> void:
	_close_sheet()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	_overlay.add_child(dim)
	_sheet = dim
	var panel := PanelContainer.new()
	var st := _box(Color("2a2638"), 22, Color("4a4460"), 2)
	st.content_margin_left = 22
	st.content_margin_right = 22
	st.content_margin_top = 18
	st.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", st)
	if is_landscape():
		panel.anchor_left = 0.5
		panel.anchor_right = 0.5
		panel.offset_left = -330
		panel.offset_right = 330
	else:
		panel.anchor_left = 0.0
		panel.anchor_right = 1.0
		panel.offset_left = _margins.x
		panel.offset_right = -_margins.z
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_bottom = -_margins.w
	panel.offset_top = -_margins.w
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.add_child(panel)
	var v := _vbox(10)
	panel.add_child(v)
	v.add_child(_title_label(title, 30, INK))
	for ln in lines:
		v.add_child(_label(String(ln[0]), 20, ln[1], true))
	for a in actions:
		var cb: Callable = a[1]
		var btn := _button(String(a[0]), _sheet_action.bind(cb), a[2], 24, 88)
		v.add_child(btn)
	v.add_child(_button("Close", _close_sheet, Color("3a3548"), 22, 72))


func _sheet_action(cb: Callable) -> void:
	_close_sheet()
	cb.call()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_close_sheet.call_deferred()


func _close_sheet() -> void:
	if _sheet != null and is_instance_valid(_sheet):
		_sheet.get_parent().remove_child(_sheet)
		_sheet.queue_free()
	_sheet = null


func sheet_open() -> bool:
	return _sheet != null and is_instance_valid(_sheet)


func _build_toast() -> void:
	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", _box(Color("0d0c12"), 14, GOLD, 2))
	_toast.anchor_left = 0.0
	_toast.anchor_right = 1.0
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = 24
	_toast.offset_right = -24
	_toast.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_label = _label("", 21, INK, true)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_child(_toast_label)
	_toast.visible = false
	add_child(_toast)


func _hide_toast() -> void:
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	if _toast != null:
		_toast.visible = false


func _toast_msg(text: String, color: Color) -> void:
	if _toast == null:
		return
	_toast_label.text = text
	_toast_label.add_theme_color_override("font_color", color)
	_toast.visible = true
	_toast.modulate.a = 1.0
	_toast.offset_left = _margins.x + 8
	_toast.offset_right = -_margins.z - 8
	_toast.offset_bottom = -_margins.w - 112
	_toast.offset_top = _toast.offset_bottom
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): _toast.visible = false)


# ================================================================ save

func _load_save() -> void:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return
	for k in _save.keys():
		_save[k] = int(cf.get_value("best", k, _save[k]))


func _write_save() -> void:
	var cf := ConfigFile.new()
	for k in _save.keys():
		cf.set_value("best", k, _save[k])
	cf.save(SAVE_PATH)
