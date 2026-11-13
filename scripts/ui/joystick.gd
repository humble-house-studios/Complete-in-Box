extends Control
## On-screen thumbstick for walking in LOOK AROUND: drag the knob, `value` is
## the stick (-1..1, y down = back). Touch (any finger) or mouse.
## No class_name (TV self-update): preload("res://scripts/ui/joystick.gd").

var value := Vector2.ZERO
var _finger := -2  # touch index, -1 = mouse, -2 = none
var _touch_ms := 0
var accent := Color(1.0, 0.8, 0.3)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _radius() -> float:
	return minf(size.x, size.y) * 0.5


func _set_from(p: Vector2) -> void:
	var c := size * 0.5
	var d := (p - c) / maxf(1.0, _radius() * 0.75)
	value = d.limit_length(1.0)
	queue_redraw()


func _release() -> void:
	_finger = -2
	value = Vector2.ZERO
	queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		var t := e as InputEventScreenTouch
		_touch_ms = Time.get_ticks_msec()
		if t.pressed and _finger == -2:
			_finger = t.index
			_set_from(t.position)
		elif not t.pressed and t.index == _finger:
			_release()
		accept_event()
	elif e is InputEventScreenDrag:
		var d := e as InputEventScreenDrag
		_touch_ms = Time.get_ticks_msec()
		if d.index == _finger:
			_set_from(d.position)
		accept_event()
	elif Time.get_ticks_msec() - _touch_ms > 600:
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if (e as InputEventMouseButton).pressed:
				_finger = -1
				_set_from((e as InputEventMouseButton).position)
			elif _finger == -1:
				_release()
			accept_event()
		elif e is InputEventMouseMotion and _finger == -1:
			_set_from((e as InputEventMouseMotion).position)
			accept_event()


func _draw() -> void:
	var c := size * 0.5
	var r := _radius()
	draw_circle(c, r, Color(0.05, 0.03, 0.08, 0.45))
	draw_arc(c, r - 2.0, 0, TAU, 40, Color(accent, 0.7), 3.0)
	for k in 4:
		var a := TAU * k / 4.0
		var p := c + Vector2(cos(a), sin(a)) * r * 0.72
		draw_circle(p, 3.0, Color(1, 1, 1, 0.35))
	var kp := c + value * r * 0.6
	draw_circle(kp, r * 0.4, Color(accent, 0.85 if _finger != -2 else 0.6))
	draw_arc(kp, r * 0.4, 0, TAU, 32, Color(0.25, 0.12, 0.02, 0.9), 3.0)
