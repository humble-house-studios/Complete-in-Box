extends SceneTree
## Shots of the Home shop: relic perk cards, supplies, the grab bag, the pocket.
##   xvfb-run -a -s "-screen 0 1280x1280x24" godot --rendering-driver opengl3 -s res://tools/shop_shots.gd -- OUT_DIR [landscape]

var out := "user://shots"
var game: Control


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DisplayServer.window_set_size(Vector2i(1280, 720) if args.has("landscape") else Vector2i(720, 1280))
	DirAccess.make_dir_recursive_absolute(out)
	game = load("res://scenes/main.tscn").instantiate()
	game.fast = true
	root.add_child(game)
	_go.call_deferred()


func _snap(name: String) -> void:
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _go() -> void:
	for i in 10:
		await process_frame
	game.start_new_run(4242)
	var r = game.run
	r.cash = 60
	r.letters_read = 99
	for i in 6:
		await process_frame
	game._close_sheet()
	r.perk_offers = ["early_bird", "silver_tongue", "curator"]
	r.supply_offers = ["energy", "copier"]
	game._set_home_tab("perks")
	await _snap("shop")
	r.perks = ["sticker_gun", "whale", "hoarder"]
	r.supplies = ["cleaning_kit", "lucky_penny"]
	r.spot_mult = 1.0
	game.request_refresh()
	await _snap("shop_owned")
	var sc = game._active_scroll()
	if sc != null:
		sc.scroll_vertical = 100000
	await _snap("shop_bottom")
	for kind in 3:
		var bag: Dictionary = Perks.BAGS[kind].duplicate()
		bag["open"] = true
		bag["cost"] = 6
		match kind:
			0: bag["picks"] = [r.roll_item(2, Balance.BAG_CONDS), r.roll_item(3, Balance.BAG_CONDS), r.roll_item(6, Balance.BAG_CONDS)]
			1: bag["picks"] = ["energy", "flyer", "spotlight"]
			2: bag["picks"] = ["glass_case", "cursed_cart"]
		r.bag_offer = bag
		game._open_bag()
		await _snap("bag_%s" % bag["id"])
		game._close_sheet()
	game._open_supply("cleaning_kit", true)
	await _snap("supply_sheet")
	game._close_sheet()
	game._pick_supply_target("cleaning_kit")
	await _snap("supply_target")
	game._close_sheet()
	game._set_home_tab("route")
	r.call_offer = ["collateral", "night_owl", "static"]
	r.calls = ["wide_shelf"]
	game.request_refresh()
	await _snap("call_route")
	game._open_call()
	await _snap("call")
	game._open_call_deal("collateral")
	await _snap("call_deal")
	game._close_sheet()
	r.call_offer = []
	game.go_to_venue(String(r.venue_choices[0]))
	await _snap("venue_pocket")
	quit()
