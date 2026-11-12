extends Control
## Complete In Box: the whole UI, built from Control nodes in code.
## The rules live in scripts/engine/run.gd; this file only draws the run's
## state and turns taps into Run actions. Screens are rebuilt from scratch
## after every action (cheap at this size, and impossible to get out of sync).
##
## Portrait (phones) = one column. Landscape (Steam) = two columns.
##
## Look: a low-res PSX-style 3D room (scripts/gfx/stage.gd) sits behind the UI,
## with the items on the table. The UI leaves a "window" gap under the header
## so you look into the room; panels are dark smoked glass over it.

const SafeArea := preload("res://scripts/ui/safe_area.gd")
const FONT_BODY := preload("res://assets/fonts/Jersey15-Regular.ttf")
const FONT_DISPLAY := preload("res://assets/fonts/Jersey10-Regular.ttf")
const CRT_SHADER := preload("res://assets/shaders/crt.gdshader")
## Jersey runs small, so every font size is scaled up by this.
const FONT_SCALE := 1.18

## Dev shortcuts (+$100, +1 ante) at Home. Set false before shipping.
const DEV := true

const BG := Color("15131d")
const PANEL := Color(0.075, 0.065, 0.095, 0.9)
const PANEL_HI := Color("3a3150")
const INK := Color("f2ead8")
const MUTED := Color("b9b0cc")
const FLAVOR_C := Color("e3d3ae")
const DARK_TXT := Color("17131f")
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
var _save := {"best_ante": 0, "best_appraisal": 0, "runs": 0, "wins": 0, "sound": 1}
var _stage: Stage
var _gap: Control
var _crt: ColorRect
var _shown_cash := -1
var _cash_label: Label
var _cash_tween: Tween
var _title_item: Dictionary = {}


func _ready() -> void:
	theme = _make_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_stage = Stage.new()
	add_child(_stage)
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
	_crt = ColorRect.new()
	_crt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cm := ShaderMaterial.new()
	cm.shader = CRT_SHADER
	_crt.material = cm
	add_child(_crt)
	_sfx = Sfx.new()
	add_child(_sfx)
	_load_save()
	_sfx.enabled = int(_save["sound"]) == 1
	_sfx.music_enabled = _sfx.enabled
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
	return ((_content_w() - 20.0) * 0.6 if is_landscape() else _content_w()) - 26.0


func _side_w() -> float:
	return ((_content_w() - 20.0) * 0.4 if is_landscape() else _content_w()) - 26.0


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
	_gap = null
	_cash_label = null
	match screen:
		"title": _build_title()
		"home": _build_home()
		"venue": _build_venue()
		"over": _build_over()
		"won": _build_won()
		_: pass
	_sync_stage()
	_update_focus.call_deferred()


## Puts the right room (and its items) behind the UI and picks the music.
func _sync_stage() -> void:
	if _stage == null:
		return
	match screen:
		"title":
			_stage.show_scene("title", [_hero_item()])
			_sfx.music("title")
		"home":
			_stage.show_scene("home", run.shelf)
			_sfx.music("home")
		"venue":
			var items: Array = []
			for o in run.stock:
				items.append(o["item"])
			for a in run.auctions:
				items.append(a["item"])
			_stage.show_scene(String(run.venue["id"]), items)
			_sfx.music(String(run.venue["slot"]), String(run.venue["id"]))
		"over":
			var it := _hero_item()
			it["cond"] = "Damaged"
			_stage.show_scene("title", [it])
			_sfx.music("title")
		"won":
			_stage.show_scene("title", [_hero_item()])
			_sfx.music("home")


## Aims the 3D camera so the table shows through the gap under the header.
func _update_focus() -> void:
	if _stage == null or not is_inside_tree():
		return
	# Containers settle a frame or two after a rebuild.
	await get_tree().process_frame
	await get_tree().process_frame
	if _stage == null or not is_inside_tree() or screen == "appraisal":
		return
	var vh := get_viewport_rect().size.y
	if _gap != null and is_instance_valid(_gap) and _gap.is_inside_tree() and vh > 0:
		var r := _gap.get_global_rect()
		var zoom := 1.0
		if is_landscape():
			zoom = 1.5 if screen == "title" else 1.4
		_stage.set_focus((r.position.y + r.size.y * 0.62) / vh, zoom)
	else:
		_stage.set_focus(0.42)


## The big sealed box spinning on the title screen.
func _hero_item() -> Dictionary:
	if _title_item.is_empty():
		var grails := Catalog.defs_of_tier(3)
		var d: Dictionary = grails[randi() % grails.size()].duplicate()
		d["cond"] = "Sealed"
		_title_item = d
	return _title_item.duplicate()


## A see-through hole in the layout where the 3D room shows.
func _stage_gap(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gap = c
	return c


# ================================================================ theme + widgets

func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = FONT_BODY
	t.default_font_size = int(24 * FONT_SCALE)
	t.set_color("font_color", "Label", INK)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", INK)
	t.set_color("font_disabled_color", "Button", Color(INK, 0.35))
	t.set_font("font", "Button", FONT_DISPLAY)
	t.set_stylebox("normal", "Button", _box(PANEL_HI, 6))
	t.set_stylebox("hover", "Button", _box(PANEL_HI.lightened(0.07), 6))
	t.set_stylebox("pressed", "Button", _box(PANEL_HI.darkened(0.25), 6))
	t.set_stylebox("disabled", "Button", _box(PANEL.darkened(0.15), 6))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, 6))
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(GOLD, 0.5)
	grab.set_corner_radius_all(3)
	grab.content_margin_left = 3
	grab.content_margin_right = 3
	t.set_stylebox("grabber", "VScrollBar", grab)
	t.set_stylebox("grabber_highlight", "VScrollBar", grab)
	t.set_stylebox("grabber_pressed", "VScrollBar", grab)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0, 0, 0, 0.25)
	track.content_margin_left = 3
	track.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", track)
	return t


func _box(color: Color, radius: int = 6, border: Color = Color(0, 0, 0, 0), width: int = 0, stripe: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(mini(radius, 8))
	s.content_margin_left = 14 + stripe
	s.content_margin_right = 14
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 4)
	if width > 0:
		s.set_border_width_all(width)
		s.border_color = border
	elif stripe == 0:
		s.border_width_top = 2
		s.border_color = Color(1, 1, 1, 0.06)
	if stripe > 0:
		s.border_width_left = stripe
		s.border_width_bottom = 3
		s.border_color = border
	return s


func _label(text: String, fs: int = 24, color: Color = INK, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", int(fs * FONT_SCALE))
	l.add_theme_color_override("font_color", color)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Big chunky display text with a dark outline and a drop shadow.
func _title_label(text: String, fs: int, color: Color) -> Label:
	var l := _label(text, fs, color)
	l.add_theme_font_override("font", FONT_DISPLAY)
	l.add_theme_font_size_override("font_size", int(fs * FONT_SCALE * 1.12))
	l.add_theme_color_override("font_outline_color", Color("0b0a10"))
	l.add_theme_constant_override("outline_size", maxi(5, int(fs / 5.0)))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(2, int(fs / 10.0)))
	return l


## Chunky arcade button: thick darker bottom edge that squashes when pressed.
func _button(text: String, cb: Callable, color: Color = PANEL_HI, fs: int = 24, height: float = 88.0) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, height)
	b.add_theme_font_override("font", FONT_DISPLAY)
	b.add_theme_font_size_override("font_size", int(fs * FONT_SCALE * 1.15))
	b.add_theme_stylebox_override("normal", _btn_box(color, 7))
	b.add_theme_stylebox_override("hover", _btn_box(color.lightened(0.08), 7))
	b.add_theme_stylebox_override("pressed", _btn_box(color.darkened(0.15), 2))
	b.add_theme_stylebox_override("disabled", _btn_box(color.darkened(0.45), 3))
	b.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	b.add_theme_constant_override("outline_size", 4)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.pressed.connect(cb)
	b.button_down.connect(_click)
	if color.get_luminance() > 0.55:
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			b.add_theme_color_override(c, Color("15131d"))
		b.add_theme_constant_override("outline_size", 0)
	return b


func _btn_box(color: Color, edge: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(7)
	s.border_width_bottom = edge
	s.border_width_top = 2
	s.border_color = color.darkened(0.5)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 10 + (7 - edge)
	s.content_margin_bottom = 8
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 3)
	return s


func _click() -> void:
	if _sfx != null:
		_sfx.play("click")


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
	p.add_theme_stylebox_override("panel", _box(color, 6, border, width))
	return p


## Section header like a shop sign: gold bar, title, a rule to the right.
func _section(parent: Control, text: String, right: Control = null) -> void:
	var h := _hbox(10)
	var bar := ColorRect.new()
	bar.color = GOLD
	bar.custom_minimum_size = Vector2(6, 30)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bar)
	h.add_child(_title_label(text, 28, GOLD))
	var rule := ColorRect.new()
	rule.color = Color(GOLD, 0.25)
	rule.custom_minimum_size = Vector2(0, 2)
	rule.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rule.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(rule)
	if right != null:
		h.add_child(right)
	parent.add_child(h)


## Small rounded badge with dark text on a coloured background.
func _pill(text: String, bg: Color, fs: int = 15, fg: Color = DARK_TXT) -> PanelContainer:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.set_corner_radius_all(5)
	st.content_margin_left = 7
	st.content_margin_right = 7
	st.content_margin_top = 0
	st.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", st)
	var l := _label(text, fs, fg)
	l.add_theme_font_override("font", FONT_DISPLAY)
	l.add_theme_font_size_override("font_size", int(fs * FONT_SCALE * 1.12))
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return p


func _scroll_col(parent: Control, ratio: float) -> VBoxContainer:
	# Smoked-glass backing so text reads over the bright 3D rooms.
	var back := PanelContainer.new()
	var st := _box(Color(0.03, 0.025, 0.045, 0.72), 8)
	st.content_margin_left = 8
	st.content_margin_right = 4
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	st.shadow_size = 0
	back.add_theme_stylebox_override("panel", st)
	back.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back.size_flags_vertical = Control.SIZE_EXPAND_FILL
	back.size_flags_stretch_ratio = ratio
	parent.add_child(back)
	var sc := ScrollContainer.new()
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	back.add_child(sc)
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
	var base := Color(bg.lerp(stripe.darkened(0.55), 0.22), maxf(bg.a, 0.93))
	b.add_theme_stylebox_override("normal", _card_box(base, stripe))
	b.add_theme_stylebox_override("hover", _card_box(base.lightened(0.06), stripe))
	b.add_theme_stylebox_override("pressed", _card_box(base.darkened(0.2), stripe))
	b.add_theme_stylebox_override("disabled", _card_box(base.darkened(0.35), stripe.darkened(0.5)))
	b.pressed.connect(cb)
	b.button_down.connect(_click)
	return b


func _card_box(bg: Color, edge: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(8)
	s.set_border_width_all(2)
	s.border_width_left = 8
	s.border_width_bottom = 4
	s.border_color = Color(edge, 0.85)
	s.shadow_color = Color(0, 0, 0, 0.5)
	s.shadow_size = 1
	s.shadow_offset = Vector2(0, 4)
	return s


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


## Card body with the item's 3D icon on the left; returns the text column.
func _card_inner_icon(b: Button, item: Dictionary, px: float) -> VBoxContainer:
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 10)
	m.add_theme_constant_override("margin_top", 8)
	m.add_theme_constant_override("margin_bottom", 8)
	b.add_child(m)
	var h := _hbox(10)
	m.add_child(h)
	h.add_child(_icon_well(item, px))
	var v := _vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	return v


## The baked 3D render of an item (assets/items/icons), pixel-crisp.
func _icon(item: Dictionary, px: float) -> TextureRect:
	var form := "box" if ItemModels.is_boxed(item) and String(item["kind"]) != "misc" else "loose"
	var path := "res://assets/items/icons/%s_%s.png" % [item["id"], form]
	var tr := TextureRect.new()
	if ResourceLoader.exists(path):
		tr.texture = load(path)
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.custom_minimum_size = Vector2(px, px)
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if String(item.get("cond", "")) == "Damaged":
		tr.modulate = Color(0.85, 0.68, 0.58)
	return tr


## Icon on a little dark plinth, glowing for rare and grail items.
func _icon_well(item: Dictionary, px: float) -> PanelContainer:
	var p := PanelContainer.new()
	var tier := int(item.get("tier", 0))
	var st := _box(Color(0.85, 0.8, 0.95, 0.13), 6)
	st.content_margin_left = 2
	st.content_margin_right = 2
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	st.shadow_size = 0
	if tier >= 2:
		st.set_border_width_all(2)
		st.border_color = Color(Catalog.TIER_COLORS[tier], 0.8)
		st.shadow_color = Color(Catalog.TIER_COLORS[tier], 0.35)
		st.shadow_size = 6
		st.shadow_offset = Vector2.ZERO
	p.add_theme_stylebox_override("panel", st)
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p.add_child(_icon(item, px))
	if int(item.get("grade", 0)) > 0:
		var g := _sticker(str(item["grade"]), GOLD)
		g.size_flags_horizontal = Control.SIZE_SHRINK_END
		g.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		p.add_child(g)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


## Platform / condition / grade / tier as coloured pills.
func _tag_row(item: Dictionary, fs: int = 16) -> HFlowContainer:
	var plat := Catalog.platform(String(item["plat"]))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 5)
	row.add_theme_constant_override("v_separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_pill(String(plat["short"]), (plat["color"] as Color).lightened(0.15), fs))
	var cond := String(item["cond"])
	row.add_child(_pill(String(Catalog.COND_SHORT[cond]), (Catalog.COND_COLORS[cond] as Color).lightened(0.1), fs))
	if int(item["grade"]) > 0:
		row.add_child(_pill("GRADE %d" % item["grade"], GOLD, fs))
	var tier := int(item["tier"])
	if tier > 0:
		var tn := String(Catalog.TIER_NAMES[tier]).to_upper()
		if fs < 16:
			tn = ["", "UNC", "RARE", "GRAIL"][tier]
		row.add_child(_pill(tn, Catalog.TIER_COLORS[tier], fs))
	var t := _trend_tag(item).strip_edges()
	if t != "":
		row.add_child(_pill(t, HOT_C if t == "HOT" else COLD_C, fs))
	return row


func _trend_tag(item: Dictionary) -> String:
	var p := String(item["plat"])
	if run.hot.has(p):
		return " HOT"
	if run.cold.has(p):
		return " COLD"
	return ""


## Price-gun sticker: chunky, slightly crooked.
func _sticker(text: String, color: Color = STICKER) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _box(color, 6)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 0
	s.content_margin_bottom = 2
	s.border_width_bottom = 3
	s.border_width_top = 0
	s.border_color = color.darkened(0.35)
	s.shadow_offset = Vector2(2, 3)
	p.add_theme_stylebox_override("panel", s)
	var l := _title_label(text, 26, DARK_TXT)
	l.add_theme_constant_override("outline_size", 0)
	l.add_theme_constant_override("shadow_offset_y", 0)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	p.add_child(l)
	p.rotation_degrees = -4.0
	p.size_flags_vertical = Control.SIZE_SHRINK_END
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


func _offer_card(i: int, w: float) -> Button:
	var o: Dictionary = run.stock[i]
	var item: Dictionary = o["item"]
	var b := _card_shell(w, 196, Catalog.platform(String(item["plat"]))["color"], func(): _open_offer(i))
	var v := _card_inner_icon(b, item, 112)
	var nm := _title_label(String(item["name"]), 24, INK)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.max_lines_visible = 2
	v.add_child(nm)
	v.add_child(_tag_row(item))
	var fl := _label(Flavor.cond_line(item), 16, FLAVOR_C, true)
	fl.max_lines_visible = 1
	fl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	fl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(fl)
	var bottom := _hbox(6)
	var wv := _vbox(-4)
	if run.shows_exact():
		wv.add_child(_label("WORTH", 13, MUTED))
		wv.add_child(_title_label(_money(run.market_value(item)), 22, GOLD))
	else:
		var est: Array = o["est"]
		wv.add_child(_label("GUESS", 13, MUTED))
		wv.add_child(_title_label("%s-%s?" % [_money(int(est[0])), _money(int(est[1]))], 20, Color("e8dcc0")))
	bottom.add_child(wv)
	bottom.add_child(_spacer(false))
	if bool(o["bargain"]):
		bottom.add_child(_pill("BARGAIN", GOOD, 14))
	bottom.add_child(_sticker(_money(int(o["price"]))))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


## A taped-up cardboard box.
func _lot_card(i: int, w: float) -> Button:
	var lot: Dictionary = run.lots[i]
	var storage: bool = run.venue["id"] == "storage"
	var b := _card_shell(w, 196, Color("c8963e"), func(): _open_lot(i), Color(0.36, 0.25, 0.14, 0.95))
	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + side, 12 if side != "left" else 18)
	b.add_child(m)
	var hb := _hbox(12)
	m.add_child(hb)
	var boxw := PanelContainer.new()
	var bs := _box(Color("b98a4b"), 4)
	bs.shadow_size = 0
	bs.border_width_top = 10
	bs.border_color = Color("e8d27a")
	boxw.add_theme_stylebox_override("panel", bs)
	boxw.custom_minimum_size = Vector2(104, 104)
	boxw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var q := _title_label("?", 72, Color("3a2412"))
	q.add_theme_constant_override("outline_size", 0)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boxw.add_child(q)
	hb.add_child(boxw)
	var v := _vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(v)
	var items: Array = lot["items"]
	v.add_child(_title_label(("STORAGE UNIT #%d" % (i + 1)) if storage else "MYSTERY BOX LOT", 22, GOLD))
	if bool(lot["bought"]):
		v.add_child(_label("SOLD to you.", 18, INK, true))
	else:
		v.add_child(_label("%d items inside" % items.size(), 18, INK))
		var peek: Array = []
		for k in mini(int(lot["peek"]), items.size()):
			peek.append(String(items[k]["name"]))
		var pk := _label("On top: " + ", ".join(peek), 16, Color("f0e2c0"), true)
		pk.max_lines_visible = 2
		v.add_child(pk)
		var fl := _label(Flavor.pick(Flavor.LOT, i + run.ante * 7), 15, FLAVOR_C, true)
		fl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(fl)
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
	var b := _card_shell(w, 196, Catalog.platform(String(item["plat"]))["color"], func(): _open_auction(i))
	var v := _card_inner_icon(b, item, 112)
	v.add_child(_label("AUCTION", 14, Color("4fd9a0")))
	var nm := _title_label(String(item["name"]), 24, INK)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.max_lines_visible = 2
	nm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(nm)
	v.add_child(_tag_row(item))
	var bottom := _hbox(6)
	var status := "NO BID YET"
	var sc := MUTED
	if int(a["my_max"]) > 0:
		if run.winning(i):
			status = "WINNING"
			sc = GOOD
		else:
			status = "OUTBID"
			sc = BAD
	if sc == MUTED:
		bottom.add_child(_label(status, 16, MUTED))
	else:
		bottom.add_child(_pill(status, sc, 15))
	bottom.add_child(_spacer(false))
	bottom.add_child(_sticker(_money(int(a["bid"])), Color("4fd9a0")))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _shelf_tile(item: Dictionary, w: float, state: String = "") -> Button:
	var bg := PANEL if state == "" else PANEL.darkened(0.3)
	var b := _card_shell(w, 188, Catalog.platform(String(item["plat"]))["color"], func(): _open_shelf_item(int(item["uid"]), state), bg)
	var v := _card_inner(b)
	var well := _icon_well(item, 72)
	well.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if state != "":
		well.modulate = Color(0.6, 0.6, 0.7)
	v.add_child(well)
	var nm := _title_label(String(item["name"]), 18, INK if state == "" else MUTED)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.max_lines_visible = 2
	nm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(nm)
	var bottom := _hbox(4)
	var plat := Catalog.platform(String(item["plat"]))
	bottom.add_child(_pill(String(plat["short"]), (plat["color"] as Color).lightened(0.15), 13))
	bottom.add_child(_spacer(false))
	if state == "":
		bottom.add_child(_title_label(_money(run.market_value(item)), 20, GOLD))
	else:
		bottom.add_child(_pill(state, COLD_C, 13))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _empty_tile(w: float) -> Control:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(w, 176)
	p.add_theme_stylebox_override("panel", _box(Color(0, 0, 0, 0.25), 6, Color(1, 1, 1, 0.1), 2))
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
			pip.custom_minimum_size = Vector2(14, 24)
			pip.color = Color("ffb347") if run.time_left > 0 else Color(BAD, 0.6)
			pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pips.add_child(pip)
		tv.add_child(pips)
		h.add_child(tv)
	var cv := _vbox(0)
	cv.add_child(_label("CASH", 15, MUTED))
	if _shown_cash < 0 or fast:
		_shown_cash = run.cash
	_cash_label = _title_label(_money(_shown_cash), 40, GOLD)
	_cash_label.add_theme_color_override("font_outline_color", Color("3a2600"))
	cv.add_child(_cash_label)
	h.add_child(cv)
	var hp := _panel(Color(0.04, 0.035, 0.05, 0.82))
	hp.add_child(h)
	_root_box.add_child(hp)
	if _shown_cash != run.cash:
		_roll_cash.call_deferred(_shown_cash, run.cash)


## Cash counts up/down like a till instead of jumping.
func _roll_cash(from: int, to: int) -> void:
	if _cash_label == null or not is_instance_valid(_cash_label):
		_shown_cash = to
		return
	if _cash_tween != null and _cash_tween.is_valid():
		_cash_tween.kill()
	_cash_tween = create_tween()
	_cash_tween.tween_method(_set_cash, from, to, clampf(absf(to - from) / 200.0, 0.25, 0.8))
	_punch(_cash_label, 1.25)


func _set_cash(v: int) -> void:
	_shown_cash = v
	if _cash_label != null and is_instance_valid(_cash_label):
		_cash_label.text = _money(v)


## Quick scale pop for numbers and stickers.
func _punch(c: Control, amount: float = 1.3) -> void:
	if c == null or not is_instance_valid(c) or fast:
		return
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * amount, 0.05)
	tw.tween_property(c, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _market_panel(parent: Control) -> void:
	var p := _panel(Color(0.06, 0.05, 0.08, 0.85), Color(1, 1, 1, 0.08), 2)
	var v := _vbox(6)
	p.add_child(v)
	v.add_child(_label("MARKET REPORT", 14, MUTED))
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	for plat in run.hot:
		row.add_child(_pill("HOT  %s x%.1f" % [Catalog.platform(plat)["name"], run.trend_mult(plat)], HOT_C, 16))
	for plat in run.cold:
		row.add_child(_pill("COLD  %s x%.2f" % [Catalog.platform(plat)["name"], run.trend_mult(plat)], COLD_C, 16))
	v.add_child(row)
	v.add_child(_label("Word around the shops: %s could be hot next stop." % Catalog.platform(run.rumor)["name"], 18, FLAVOR_C, true))
	parent.add_child(p)


# ================================================================ title

func show_title() -> void:
	screen = "title"
	request_refresh()


func _build_title() -> void:
	var land := is_landscape()
	var logo := _vbox(-18 if not land else -12)
	for pair in [["COMPLETE", INK], ["IN BOX", GOLD]]:
		var l := _title_label(pair[0], 96 if not land else 60, pair[1])
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		logo.add_child(l)
	var tag := _label("Dig. Haggle. Flip. Hoard. Get appraised.", 22, Color("d9c9a8"))
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	tag.add_theme_constant_override("outline_size", 6)
	if not land:
		_root_box.add_child(_spacer())
	_root_box.add_child(logo)
	_root_box.add_child(tag)
	var gap := _stage_gap(260 if not land else 120)
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gap.size_flags_stretch_ratio = 4.0
	_root_box.add_child(gap)
	_root_box.add_child(_button("NEW RUN", start_new_run, STICKER, 34 if not land else 28, 110 if not land else 84))
	var row := _hbox(10)
	var bh := 80.0 if not land else 64.0
	for bt in [_button("HOW TO PLAY", _show_how_to, PANEL_HI, 22, bh), _button("SOUND: %s" % ("ON" if _sfx.enabled else "OFF"), _toggle_sound, PANEL_HI, 22, bh), _button("CREDITS", _show_credits, PANEL_HI, 22, bh)]:
		bt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(bt)
	_root_box.add_child(row)
	var best := "No runs yet."
	if int(_save["runs"]) > 0:
		best = "Best: Ante %d  |  Best shelf %s  |  Wins %d" % [_save["best_ante"], _money(int(_save["best_appraisal"])), _save["wins"]]
	var bl := _label(best, 19, MUTED)
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(bl)


func _toggle_sound() -> void:
	var on := not _sfx.enabled
	_save["sound"] = 1 if on else 0
	_write_save()
	_sfx.enabled = on
	_sfx.set_music_enabled(on)
	request_refresh()


const CREDITS := [
	"3D props: Kenney Furniture Kit, 3D Interior Home Assets, Escape Room Pack, Crate model (OpenGameArt).",
	"Cartridge models: Late 1980s Game Cartridges (OpenGameArt, CC-BY 3.0).",
	"Textures: ambientCG (CC0). Fonts: Jersey 10/15, VT323 (OFL).",
	"Sounds: Kenney Casino, Interface Sounds and Music Jingles; 80 CC0 RPG SFX; 75 CC0 breaking/falling SFX.",
	"Music: Jazzy Vibes #89, A Cloudy Morning, Chilled Lofi Beat, Squirrel Village Lounge, 8bit Bossa (OpenGameArt). Ambience: Free General Ambience Sounds.",
	"Full list with links: assets/sources.txt",
]


func _show_credits() -> void:
	var lines: Array = []
	for c in CREDITS:
		lines.append([c, MUTED])
	_open_sheet("Credits", lines, [])


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
	_root_box.add_child(_stage_gap(130 if is_landscape() else 250))
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


## A destination card: coloured sign band, mood line, fact pills.
func _venue_button(id: String) -> Button:
	var d := Venues.get_def(id)
	var col: Color = d["color"]
	var b := _card_shell(0, 210, col, func(): go_to_venue(id), PANEL)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var v := _card_inner(b)
	var band := PanelContainer.new()
	var bs := StyleBoxFlat.new()
	bs.bg_color = col
	bs.set_corner_radius_all(5)
	bs.content_margin_left = 10
	bs.content_margin_right = 10
	band.add_theme_stylebox_override("panel", bs)
	var top := _hbox()
	var nm := _title_label(String(d["name"]), 30, DARK_TXT)
	nm.add_theme_constant_override("outline_size", 0)
	nm.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.25))
	top.add_child(nm)
	top.add_child(_spacer(false))
	var go := _title_label("GO >", 26, DARK_TXT)
	go.add_theme_constant_override("outline_size", 0)
	top.add_child(go)
	band.add_child(top)
	v.add_child(band)
	var mood := _label(Flavor.mood(id), 18, FLAVOR_C, true)
	v.add_child(mood)
	var blurb := _label(String(d["blurb"]), 17, INK, true)
	blurb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(blurb)
	var facts := HFlowContainer.new()
	facts.add_theme_constant_override("h_separation", 5)
	facts.add_theme_constant_override("v_separation", 4)
	for f in _venue_facts(d).split(" | "):
		facts.add_child(_pill(String(f).to_upper(), Color(1, 1, 1, 0.82), 13))
	v.add_child(facts)
	_ignore_mouse(b)
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
	var col := Color("b07cff") if not owned else GOOD
	var b := _card_shell(w, 190, col, func(): _open_perk(id, owned), PANEL)
	var v := _card_inner(b)
	v.add_child(_pill("OWNED" if owned else "PERK", col, 13))
	var nm := _title_label(String(d["name"]), 22, INK)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)
	var desc := _label(String(d["desc"]), 17, Color("ddd5ea"), true)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(desc)
	var bottom := _hbox()
	bottom.add_child(_spacer(false))
	if owned:
		bottom.add_child(_label("sell %s" % _money(int(d["cost"]) / 2), 17, MUTED))
	else:
		bottom.add_child(_sticker(_money(int(d["cost"]))))
	v.add_child(bottom)
	_ignore_mouse(b)
	return b


func _upgrade_card(w: float) -> Button:
	var d := run.upgrade_offer
	var b := _card_shell(w, 190, GOLD, func(): _open_upgrade(), Color(0.17, 0.13, 0.2, 0.93))
	var v := _card_inner(b)
	v.add_child(_pill("UPGRADE", GOLD, 13))
	var nm := _title_label(String(d["name"]), 22, INK)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(nm)
	var desc := _label(String(d["desc"]), 17, Color("ddd5ea"), true)
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
		_sfx.play("door")
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
	_root_box.add_child(_stage_gap(110 if is_landscape() else 270))
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
		var dig := _button("%s  (1 Time)" % run.venue["dig_label"], func(): _act(run.dig(), "dig"), PANEL_HI, 22, 80)
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
	var lines: Array = []
	var quote := Flavor.seller(String(run.venue["id"]), str(item["uid"]))
	if quote != "":
		lines.append([quote, FLAVOR_C])
	lines.append_array(_item_lines(item, run.shows_exact()))
	if not run.shows_exact():
		var est: Array = o["est"]
		lines.append(["Your gut says %s to %s. Could be more. Could be junk." % [_money(int(est[0])), _money(int(est[1]))], MUTED])
	if bool(o["bin"]) and not run.has_perk("bubble_wrap"):
		lines.append(["Online: might arrive a condition worse than listed.", MUTED])
	var actions: Array = [["Buy for %s" % _money(int(o["price"])), func(): _do_buy(i), STICKER]]
	if float(run.venue["haggle"]) > 0.0 and not bool(o["haggled"]) and run.time_left > 0:
		actions.append(["Haggle  (1 Time, %d%% odds)" % int(round(_haggle_odds() * 100.0)), func(): _do_haggle(i), PANEL_HI])
	elif bool(o["haggled"]):
		lines.append(["Already haggled.", MUTED])
	_open_sheet(String(item["name"]), lines, actions, item)


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
		_act(res, "grail" if diff > 100 else ("bargain" if diff > 0 else "buy"))
		if diff > 100:
			_stage.shake(0.6)
		return
	_act(res, "buy")


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
	_sfx.play("lot")
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
	_open_sheet(String(item["name"]), lines, [["Bid up to %s" % _money(nb), func(): _do_bid(i), Color("4fd9a0")]], item)


func _do_bid(i: int) -> void:
	var res := run.bid(i)
	var ok := bool(res["ok"])
	_act(res, "haggle" if ok and run.winning(i) else "buzz")
	if ok:
		_open_auction.call_deferred(i)


func _item_lines(item: Dictionary, exact: bool) -> Array:
	var plat := Catalog.platform(String(item["plat"]))
	var tier := int(item["tier"])
	var lines: Array = [[Flavor.cond_line(item), INK]]
	if tier > 0:
		lines.append([Flavor.tier_line(item), Catalog.TIER_COLORS[tier]])
	lines.append(["%s  |  %s  |  %s%s" % [plat["name"], item["cond"], Catalog.TIER_NAMES[tier], ("  |  Graded %d" % item["grade"]) if int(item["grade"]) > 0 else ""], (plat["color"] as Color).lightened(0.25)])
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
	_open_sheet(String(item["name"]), lines, actions, item)


# ================================================================ appraisal

func finish_stop() -> void:
	if _busy or run.phase != Run.Phase.VENUE:
		return
	_close_sheet()
	var shelf_before: Array = run.shelf.duplicate()
	var res := run.end_stop()
	res["shelf_before"] = shelf_before
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
	# The shelf being appraised, in the order the rows count up.
	var before: Array = res.get("shelf_before", run.shelf)
	var shown: Array = []
	for row in ap["items"]:
		for it in before:
			if int(it["uid"]) == int(row["uid"]):
				shown.append(it)
				break
	_stage.show_scene("appraisal", shown)
	_sfx.duck(true)
	var layer := ColorRect.new()
	layer.color = Color(0.02, 0.015, 0.03, 0.35)
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
	var head := _hbox()
	head.add_child(_title_label("APPRAISAL", 52, GOLD))
	head.add_child(_spacer(false))
	head.add_child(_title_label("Target %s" % _money(tgt), 30, INK))
	v.add_child(head)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 150 if is_landscape() else 260)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)
	_focus_on.call_deferred(gap)
	var card := _panel(Color(0.05, 0.04, 0.065, 0.93), Color(GOLD, 0.35), 2)
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(card)
	var cv := _vbox(6)
	card.add_child(cv)
	for e in res["events"]:
		cv.add_child(_label(String(e), 18, Color("4fd9a0"), true))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.mouse_filter = Control.MOUSE_FILTER_PASS
	cv.add_child(sc)
	var list := _vbox(4)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(list)
	var totals := _hbox(16)
	totals.alignment = BoxContainer.ALIGNMENT_CENTER
	var chips_l := _title_label("$0", 44, Color("4fa3ff"))
	var x_l := _title_label("x", 30, MUTED)
	var mult_l := _title_label("1.00", 44, Color("ff5577"))
	totals.add_child(chips_l)
	totals.add_child(x_l)
	totals.add_child(mult_l)
	cv.add_child(totals)
	var total_l := _title_label("", 64, INK)
	total_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cv.add_child(total_l)
	var items: Array = ap["items"]
	var d := minf(0.22, 2.6 / maxf(1.0, items.size()))
	var chips := 0
	var pitch := 0.8
	var idx := 0
	for row in items:
		var h := _hbox()
		h.add_child(_title_label("+" + _money(int(row["value"])), 24, Color("4fa3ff")))
		var n := String(row["name"])
		if not (row["notes"] as Array).is_empty():
			n += "  (" + ", ".join(row["notes"]) + ")"
		h.add_child(_label(n, 18, INK, true))
		list.add_child(h)
		chips += int(row["value"])
		chips_l.text = _money(chips)
		_punch(chips_l, 1.15)
		_stage.pulse(idx)
		idx += 1
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
		h2.add_child(_title_label(txt, 24, Color("ff5577")))
		h2.add_child(_label(String(b["label"]), 18, INK, true))
		list.add_child(h2)
		mult_l.text = "%.2f" % ((1.0 + add) * times)
		_punch(mult_l, 1.35)
		_sfx.play("mult", 1.0 + add * 0.1)
		await _wait(0.28)
	mult_l.text = "%.2f" % float(ap["mult"])
	await _wait(0.35)
	var total := int(ap["total"])
	var passed := bool(res["passed"])
	total_l.text = "= " + _money(total)
	total_l.add_theme_color_override("font_color", GOOD if passed else BAD)
	_sfx.play("stamp")
	_punch(total_l, 1.6)
	if passed:
		_sfx.play("pass")
		_stage.shake(0.5)
		_coin_burst(layer, total_l)
		var r: Dictionary = res["rewards"]
		cv.add_child(_label(Flavor.pick(Flavor.PASS, run.ante * 3 + run.stop), 20, FLAVOR_C, true))
		cv.add_child(_label("CLEARED! Payout: stop %s + interest %s + leftover Time %s = %s" % [
			_money(int(r["base"])), _money(int(r["interest"])), _money(int(r["time"])), _money(int(r["total"]))], 20, GOOD, true))
		var label := "CONTINUE"
		if run.phase == Run.Phase.WON:
			label = "YOU WON. SEE RESULTS"
			_sfx.play("win")
		v.add_child(_button(label, _after_appraisal, STICKER, 28, 96))
	else:
		_sfx.play("fail")
		_stage.shake(1.4)
		_flash(layer, BAD)
		cv.add_child(_label("Short by %s. %s" % [_money(tgt - total), Flavor.pick(Flavor.FAIL, run.ante * 3 + run.stop)], 22, BAD, true))
		v.add_child(_button("SEE RESULTS", _after_appraisal, BAD, 28, 96))
	_busy = false


func _focus_on(c: Control) -> void:
	if c == null or not is_instance_valid(c) or not c.is_inside_tree():
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(c) or not c.is_inside_tree():
		return
	var vh := get_viewport_rect().size.y
	var r := c.get_global_rect()
	_stage.set_focus((r.position.y + r.size.y * 0.6) / maxf(vh, 1.0))


## Gold confetti from a label (appraisal passed).
func _coin_burst(parent: Control, from: Control) -> void:
	if fast:
		return
	var p := CPUParticles2D.new()
	p.amount = 48
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 1.4
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 350.0
	p.initial_velocity_max = 750.0
	p.gravity = Vector2(0, 1300)
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	p.angular_velocity_min = -360.0
	p.angular_velocity_max = 360.0
	var g := Gradient.new()
	g.set_color(0, GOLD)
	g.set_color(1, Color("ff8a3d"))
	p.color_initial_ramp = g
	parent.add_child(p)
	p.global_position = from.global_position + from.size * 0.5
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func _flash(parent: Control, color: Color) -> void:
	if fast:
		return
	var f := ColorRect.new()
	f.color = Color(color, 0.45)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(f)
	var tw := f.create_tween()
	tw.tween_property(f, "color:a", 0.0, 0.5)
	tw.tween_callback(f.queue_free)


func _on_appraisal_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_skip = true


func _after_appraisal() -> void:
	_sfx.duck(false)
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
		_punch(l, 1.2)
		if tier >= 3:
			_stage.shake(0.8)
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
	var t := _title_label("OUT OF BUSINESS", 64, BAD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(t)
	var gap := _stage_gap(160)
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_box.add_child(gap)
	_end_stats()
	_root_box.add_child(_button("NEW RUN", start_new_run, STICKER, 32, 104))
	_root_box.add_child(_button("TITLE", show_title, PANEL_HI, 24, 88))


func _build_won() -> void:
	_root_box.add_child(_spacer())
	var t := _title_label("CERTIFIED LEGEND", 64, GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(t)
	var sub := _label("You beat all %d antes. The collection is museum grade." % Balance.ANTES_TO_WIN, 22, INK, true)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(sub)
	var gap := _stage_gap(160)
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_box.add_child(gap)
	_end_stats()
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

func _open_sheet(title: String, lines: Array, actions: Array, item: Dictionary = {}) -> void:
	_close_sheet()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	_overlay.add_child(dim)
	_sheet = dim
	if _sfx != null and not fast:
		_sfx.play("open")
	var panel := PanelContainer.new()
	var st := _box(Color(0.09, 0.075, 0.11, 0.97), 8, Color(GOLD, 0.45), 2)
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
	if item.is_empty():
		v.add_child(_title_label(title, 32, INK))
	else:
		var head := _hbox(14)
		head.add_child(_icon_well(item, 128))
		var hv := _vbox(4)
		hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hv.alignment = BoxContainer.ALIGNMENT_CENTER
		var t := _title_label(title, 32, INK)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hv.add_child(t)
		hv.add_child(_tag_row(item, 17))
		head.add_child(hv)
		v.add_child(head)
	for ln in lines:
		var txt := String(ln[0])
		if txt.begins_with("\""):
			# Someone talking: a speech panel.
			var q := _panel(Color(0.2, 0.16, 0.1, 0.9), Color(FLAVOR_C, 0.4), 2)
			q.add_child(_label(txt, 20, FLAVOR_C, true))
			v.add_child(q)
		else:
			v.add_child(_label(txt, 20, ln[1], true))
	for a in actions:
		var cb: Callable = a[1]
		var btn := _button(String(a[0]), _sheet_action.bind(cb), a[2], 24, 88)
		v.add_child(btn)
	v.add_child(_button("Close", _close_sheet_sfx, Color("3a3548"), 22, 72))
	if not fast:
		panel.modulate.a = 0.0
		var tw := panel.create_tween()
		tw.tween_property(panel, "modulate:a", 1.0, 0.12)


func _close_sheet_sfx() -> void:
	_sfx.play("close")
	_close_sheet()


func _sheet_action(cb: Callable) -> void:
	_close_sheet()
	cb.call()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_sfx.play("close")
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
	_toast.add_theme_stylebox_override("panel", _box(Color(0.05, 0.04, 0.07, 0.95), 8, GOLD, 2))
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
	_toast.pivot_offset = Vector2(_toast.size.x * 0.5, 0)
	_toast.scale = Vector2(0.9, 0.9)
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
