extends SceneTree
## Balance sim: the greedy bot plays a pile of runs and reports where they end.
##   godot --headless -s res://tools/sim.gd
## Prints lines starting with "SIM" (CI shows them as notices).

const Bot := preload("res://tools/bot.gd")
const RUNS := 300


func _init() -> void:
	_sim(false, "SIM")
	_sim(true, "SIM flip")
	quit()


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
