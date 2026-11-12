extends GutTest
## The UI builds every screen and drives a run end to end without errors.

var game: Control


func before_each() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	add_child_autofree(game)
	game.fast = true
	await wait_frames(2)


func _buttons(n: Node, out: Array = []) -> Array:
	for c in n.get_children():
		if c is Button:
			out.append(c)
		_buttons(c, out)
	return out


func _has_text(n: Node, text: String) -> bool:
	for c in n.get_children():
		if (c is Label and (c as Label).text.contains(text)) or (c is Button and (c as Button).text.contains(text)):
			return true
		if _has_text(c, text):
			return true
	return false


func test_title_screen() -> void:
	assert_eq(game.screen, "title")
	assert_true(_has_text(game, "NEW RUN"))


func test_new_run_shows_guide_first() -> void:
	game._save["guide_off"] = 0
	game._on_new_run()
	await wait_frames(2)
	assert_true(game.sheet_open())
	assert_true(_has_text(game, "HEY, COLLECTOR"))
	assert_eq(game.screen, "title")
	for k in game.GUIDE.size():
		game._guide_step(1)
		await wait_frames(1)
	assert_false(game.sheet_open())
	assert_eq(game.screen, "home")


func test_collection_tracks_and_wall() -> void:
	game.start_new_run(31)
	await wait_frames(2)
	game.go_to_venue("garage")
	await wait_frames(2)
	var seen_id := String(game.run.stock[0]["item"]["id"])
	assert_true(game._coll_seen.has(seen_id))
	var it: Dictionary = game.run.shelf[0] if not game.run.shelf.is_empty() else game.run.make_item(Catalog.get_def("fes_console"), "CIB")
	if game.run.shelf.is_empty():
		game.run.shelf.append(it)
	var n: int = game._coll_wall.size()
	game._hang_from_shelf(int(it["uid"]))
	await wait_frames(2)
	assert_true(game._on_wall(String(it["id"])))
	assert_true(game._coll_wall.size() >= mini(n + 1, game.WALL_MAX) or n >= game.WALL_MAX)
	game._open_collection()
	await wait_frames(2)
	assert_true(_has_text(game, "THE WALL"))
	game._set_coll_tab("binder")
	await wait_frames(2)
	assert_true(_has_text(game, "found"))


func _pad_press(btn: int) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = btn
	e.pressed = true
	game._input(e)


func test_controller_focus_tabs_and_back() -> void:
	_pad_press(JOY_BUTTON_DPAD_DOWN)
	await wait_frames(8)
	assert_true(game._pad, "pad mode on")
	assert_true(get_viewport().gui_get_focus_owner() is BaseButton, "title focus")
	game.start_new_run(12)
	await wait_frames(8)
	var before: String = game._home_tab
	_pad_press(JOY_BUTTON_RIGHT_SHOULDER)
	await wait_frames(8)
	assert_ne(game._home_tab, before, "RB switches tab")
	assert_true(get_viewport().gui_get_focus_owner() is BaseButton, "home focus")
	game._show_how_to()
	await wait_frames(8)
	assert_true(game.sheet_open(), "guide open")
	game._last_back = 0
	_pad_press(JOY_BUTTON_B)
	await wait_frames(4)
	assert_false(game.sheet_open(), "B closes")


func test_pad_a_presses_focused_button() -> void:
	_pad_press(JOY_BUTTON_DPAD_DOWN)
	await wait_frames(8)
	var fo = get_viewport().gui_get_focus_owner()
	assert_true(fo is BaseButton, "something focused")
	var hits := [0]
	(fo as BaseButton).pressed.connect(func(): hits[0] += 1)
	_pad_press(JOY_BUTTON_A)
	await wait_frames(2)
	assert_eq(hits[0], 1, "A pressed the focused button once")


func test_pad_y_does_main_action_and_x_switches() -> void:
	game.start_new_run(21)
	await wait_frames(4)
	_pad_press(JOY_BUTTON_DPAD_DOWN)
	await wait_frames(8)
	var before: String = game._home_tab
	_pad_press(JOY_BUTTON_X)
	await wait_frames(4)
	assert_ne(game._home_tab, before, "X switches the home tab")
	game._set_home_tab("route")
	await wait_frames(4)
	_pad_press(JOY_BUTTON_Y)
	await wait_frames(8)
	assert_eq(game.screen, "venue", "Y heads to the venue")


func test_pause_menu_quit_to_title_and_continue() -> void:
	game.start_new_run(8)
	await wait_frames(2)
	game._open_menu()
	await wait_frames(2)
	assert_true(game.sheet_open())
	game._close_sheet()
	game._quit_to_title()
	await wait_frames(2)
	assert_eq(game.screen, "title")
	assert_true(_has_text(game, "CONTINUE RUN"))
	game._continue_run()
	await wait_frames(2)
	assert_eq(game.screen, "home")


func test_home_then_venue_then_appraisal() -> void:
	game.start_new_run(77)
	await wait_frames(2)
	assert_eq(game.screen, "home")
	assert_true(_has_text(game, "PERK SHOP"))
	assert_true(_has_text(game, "Garage Sale"))
	game.go_to_venue("garage")
	await wait_frames(2)
	assert_eq(game.screen, "venue")
	assert_true(_has_text(game, "FOR SALE"))
	# Open an offer's sheet and buy from it.
	game.run.cash = 500
	game._open_offer(0)
	assert_true(game.sheet_open())
	game._close_sheet()
	game._do_buy(0)
	await wait_frames(2)
	# Lots reveal.
	game._do_lot(0)
	await wait_frames(2)
	game._close_reveal()
	# Shelf item sheet.
	game._open_shelf_item(int(game.run.shelf[0]["uid"]), "")
	assert_true(game.sheet_open())
	game._close_sheet()
	# Make sure we pass, then appraise.
	game.run.shelf.append(game.run.make_item(Catalog.get_def("fes_stadium"), "CIB"))
	await game.finish_stop()
	await wait_frames(2)
	assert_eq(game.screen, "appraisal")
	assert_true(_has_text(game, "CONTINUE"))
	game._after_appraisal()
	await wait_frames(2)
	assert_eq(game.screen, "home")
	assert_eq(game.run.stop, 1)


func test_every_venue_screen_builds() -> void:
	game.start_new_run(5)
	await wait_frames(2)
	for v in Venues.LIST:
		var r: Run = game.run
		r.ante = 8
		r.stop = Venues.SLOTS.find(v["slot"])
		r._prepare_home()
		r.venue_choices = [v["id"]]
		game.go_to_venue(v["id"])
		await wait_frames(2)
		assert_eq(game.screen, "venue", v["id"])
		assert_true(_has_text(game, String(v["name"])), "header shows " + v["name"])
		for i in r.auctions.size():
			game._open_auction(i)
			game._close_sheet()
		for i in r.lots.size():
			game._open_lot(i)
			game._close_sheet()
		r.phase = Run.Phase.HOME
		game.screen = "home"


func test_losing_shows_game_over() -> void:
	game.start_new_run(3)
	await wait_frames(2)
	game.go_to_venue("garage")
	await wait_frames(1)
	game.run.shelf.clear()
	await game.finish_stop()
	game._after_appraisal()
	await wait_frames(2)
	assert_eq(game.screen, "over")
	assert_true(_has_text(game, "OUT OF BUSINESS"))


func test_landscape_layout_builds() -> void:
	game.start_new_run(9)
	get_window().content_scale_size = Vector2i(1280, 720)
	game.request_refresh()
	await wait_frames(2)
	assert_eq(game.screen, "home")
	get_window().content_scale_size = Vector2i(720, 1280)
