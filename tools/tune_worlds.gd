extends SceneTree
## Balance helper for the ten worlds: the greedy bot (with flips, as in the
## meta sim) plays N runs per setting and prints the win count.
##   godot --headless -s res://tools/tune_worlds.gd -- world sports 1.0 1.2 1.4
##   godot --headless -s res://tools/tune_worlds.gd -- estate rose -10 -5 0   (bonus cash)
const Bot := preload("res://tools/bot.gd")


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var mode := String(a[0])
	var id := String(a[1])
	for k in range(2, a.size()):
		var v := float(a[k])
		var opts := {}
		Run.world_target_tweak = 1.0
		if mode == "world":
			# A plain start (no estate) in this world, flips as in the meta sim.
			# v scales every non-retro world's targets on top of worlds.gd.
			var open: Array = ["games", "cards", "coins"]
			if not open.has(id):
				open.append(id)
			opts = {"world": id, "worlds": open} if id != "games" else {"worlds": open}
			Run.world_target_tweak = v
		else:
			opts = {"estate": id, "bonus_cash": int(v)}
		var wins := 0
		for i in 100:
			var run := Run.new()
			run.start(5000 + i, opts)
			var bot := Bot.new(run, 11 + i)
			bot.pivots = true
			if bool(bot.play_run()["won"]):
				wins += 1
		print("TUNE %s %s %s wins=%d" % [mode, id, str(v), wins])
	quit()
