extends SceneTree
## Balance sim: the greedy bot plays a pile of runs and reports where they end.
##   godot --headless -s res://tools/sim.gd
## Prints lines starting with "SIM" (CI shows them as notices).

const Bot := preload("res://tools/bot.gd")
const Pro := preload("res://tools/pro_bot.gd")
const RUNS := 300


func _init() -> void:
	if not OS.get_cmdline_user_args().has("meta"):
		_sim(false, "SIM")
		_sim(true, "SIM flip")
		_pro()
		quit()
		return
	# Estates and tiers: a quicker pass each, to keep them in the same ballpark.
	var U := preload("res://scripts/data/unlocks.gd")
	for e in U.ESTATES:
		_quick({"estate": e["id"]}, "SIM estate %s" % e["id"])
	for t in U.TIERS.size():
		_quick({"tier": t}, "SIM tier %d" % t)
	quit()


func _quick(opts: Dictionary, tag: String) -> void:
	var wins := 0
	var ante_sum := 0
	var n := 100
	for i in n:
		var run := Run.new()
		run.start(5000 + i, opts)
		var bot := Bot.new(run, 11 + i)
		bot.pivots = true
		var r: Dictionary = bot.play_run()
		ante_sum += int(r["ante"])
		if bool(r["won"]):
			wins += 1
	print("%s runs=%d wins=%d avg_ante=%.2f" % [tag, n, wins, float(ante_sum) / n])


## The pro bot plays like a sharp human who knows true values: a good player
## should win a fair share of tier-0 runs (aim: around half for this bot).
func _pro() -> void:
	var wins := 0
	var ante_sum := 0
	var n := 100
	for i in n:
		var run := Run.new()
		run.start(1000 + i)
		var r: Dictionary = Pro.new(run, 5 + i).play_run()
		ante_sum += int(r["ante"])
		if bool(r["won"]):
			wins += 1
	print("SIM pro runs=%d wins=%d (%.0f%%) avg_ante=%.2f" % [n, wins, 100.0 * wins / n, float(ante_sum) / n])


func _sim(flip: bool, tag: String) -> void:
	var deaths := {}
	var wins := 0
	var ante_sum := 0
	for i in RUNS:
		var run := Run.new()
		run.start(1000 + i)
		var bot := Bot.new(run, 7 + i)
		bot.pivots = flip
		var r: Dictionary = bot.play_run()
		ante_sum += int(r["ante"])
		if bool(r["won"]):
			wins += 1
		else:
			var key := "A%d-S%d" % [r["ante"], int(r["stop"]) + 1]
			deaths[key] = int(deaths.get(key, 0)) + 1
	var keys := deaths.keys()
	keys.sort()
	var parts: Array = []
	for k in keys:
		parts.append("%s:%d" % [k, deaths[k]])
	print("%s runs=%d wins=%d (%.0f%%) avg_ante=%.2f" % [tag, RUNS, wins, 100.0 * wins / RUNS, float(ante_sum) / RUNS])
	print("%s deaths " % tag + " ".join(parts))
