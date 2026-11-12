extends SceneTree
## Dumps every pad-focusable button on a venue screen and where each D-pad
## direction goes from it:  godot --headless --resolution 720x1280 -s res://tools/nav_dump.gd -- [venue_id]

var game: Control

func _initialize() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)
	_go.call_deferred()


func _t(c: Control) -> String:
	if c == null:
		return "-"
	if c is Button and (c as Button).text != "":
		return (c as Button).text.replace("\n", " ").left(24)
	return game._key_of(c).left(30)


func _go() -> void:
	await process_frame
	game._intro_skip = true
	game._skip_intro()
	var args := OS.get_cmdline_user_args()
	game.start_new_run(5)
	for i in 10:
		await process_frame
	if args.size() > 0:
		game.go_to_venue(args[0] if args[0] != "first" else String(game.run.venue_choices[0]))
	for i in 10:
		await process_frame
	game._pad = true
	game.request_refresh()
	for i in 10:
		await process_frame
	var list: Array = game._focusables(game._pad_layer())
	for b in list:
		var line := "%-32s %s" % [_t(b), str(b.get_global_rect()).replace("[P: ", "").replace("]", "")]
		for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			line += "  %s>%s" % ["U" if d == Vector2.UP else "D" if d == Vector2.DOWN else "L" if d == Vector2.LEFT else "R", _t(game._nav_pick(b, d, list))]
		print(line)
	quit()
