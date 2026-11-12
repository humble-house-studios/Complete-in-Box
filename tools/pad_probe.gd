extends SceneTree
## Plays the start of the game with simulated Xbox pad presses (not "fast"),
## printing what has focus after each press.

var game: Control


func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	_go.call_deferred()


func _press(btn: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	Input.parse_input_event(e)
	await process_frame
	var u := InputEventJoypadButton.new()
	u.button_index = btn
	u.pressed = false
	Input.parse_input_event(u)
	for i in 12:
		await process_frame


func _stick(axis: int, val: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = val
	Input.parse_input_event(e)
	for i in 3:
		await process_frame
	var z := InputEventJoypadMotion.new()
	z.axis = axis
	z.axis_value = 0.0
	Input.parse_input_event(z)
	for i in 8:
		await process_frame


func _show(tag: String) -> void:
	var fo := root.gui_get_focus_owner()
	var t := "none"
	if fo is Button:
		t = (fo as Button).text if (fo as Button).text != "" else "card " + str(fo.get_path()).right(40)
	print("%-18s screen=%s sheet=%s pad=%s focus=%s" % [tag, game.screen, game.sheet_open(), game._pad, t.replace("\n", " ")])


func _go() -> void:
	for i in 30:
		await process_frame
	_show("start")
	await _press(JOY_BUTTON_DPAD_DOWN)
	_show("dpad (gate)")
	await _press(JOY_BUTTON_A)
	_show("A (gate)")
	await create_timer(2.0).timeout
	await _press(JOY_BUTTON_START)
	_show("start (skip)")
	await create_timer(2.5).timeout
	await _press(JOY_BUTTON_A)
	_show("A new run")
	await create_timer(0.8).timeout
	_show("guide")
	for k in 8:
		await _press(JOY_BUTTON_A)
	await create_timer(1.0).timeout
	_show("after guide")
	await _stick(JOY_AXIS_RIGHT_Y, 1.0)
	_show("R stick down")
	await _stick(JOY_AXIS_RIGHT_Y, 1.0)
	_show("R stick down")
	await _stick(JOY_AXIS_LEFT_Y, 1.0)
	_show("L stick down")
	await _stick(JOY_AXIS_LEFT_X, 1.0)
	_show("L stick right")
	await _press(JOY_BUTTON_DPAD_DOWN)
	_show("dpad down")
	await _press(JOY_BUTTON_A)
	await create_timer(0.6).timeout
	_show("A on card")
	await _press(JOY_BUTTON_DPAD_DOWN)
	_show("down in card")
	await _press(JOY_BUTTON_DPAD_RIGHT)
	_show("right in card")
	await _press(JOY_BUTTON_DPAD_LEFT)
	_show("left in card")
	await _press(JOY_BUTTON_A)
	await create_timer(0.6).timeout
	_show("A action")
	await _press(JOY_BUTTON_START)
	await create_timer(0.5).timeout
	_show("start menu")
	for k in 4:
		await _press(JOY_BUTTON_DPAD_DOWN)
	_show("menu down x4")
	await _press(JOY_BUTTON_A)
	await create_timer(1.0).timeout
	_show("A quit")
	quit()
