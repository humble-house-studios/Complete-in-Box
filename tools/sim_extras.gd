extends SceneTree
## Balance probes for the Home extras, played by the pro bot:
##   godot --headless -s res://tools/sim_extras.gd [-- N]
## Baseline, each system on its own, all together, then every landline deal
## and every supply forced on its own (win % and how often it was taken).

const Pro := preload("res://tools/pro_bot.gd")
var n := 200


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	if args.has("ban"):
		for c in Perks.CALLS:
			_go("ban " + String(c["id"]), {"use_supplies": true, "use_bags": true, "use_calls": true, "ban_call": c["id"]})
		quit()
		return
	if args.has("all"):
		_go("ALL", {"use_supplies": true, "use_bags": true, "use_calls": true})
		_go("base", {})
		quit()
		return
	_go("base", {})
	_go("supplies", {"use_supplies": true})
	_go("bags", {"use_bags": true})
	_go("calls", {"use_calls": true})
	_go("ALL", {"use_supplies": true, "use_bags": true, "use_calls": true})
	_go("hangup", {"force_call": "none"})
	if not args.has("quick"):
		for c in Perks.CALLS:
			_go("call " + String(c["id"]), {"force_call": c["id"]})
		for s in Perks.SUPPLIES:
			_go("supply " + String(s["id"]), {"use_supplies": true, "only_supply": s["id"]})
	quit()


func _go(tag: String, opts: Dictionary) -> void:
	var wins := 0
	var ante_sum := 0
	var took := 0
	var used := 0
	var deaths := {}
	var tally := {}
	for i in n:
		var run := Run.new()
		run.start(1000 + i)
		var bot = Pro.new(run, 5 + i)
		for k in opts:
			bot.set(k, opts[k])
		var r: Dictionary = bot.play_run()
		ante_sum += int(r["ante"])
		took += run.calls.size()
		for c in run.calls:
			tally[c] = int(tally.get(c, 0)) + 1
		used += int(run.stats.get("supplies", 0))
		if bool(r["won"]):
			wins += 1
		else:
			deaths[int(r["ante"])] = int(deaths.get(int(r["ante"]), 0)) + 1
	var parts: Array = []
	for a in range(1, 9):
		parts.append(str(int(deaths.get(a, 0))))
	print("EXTRAS %-22s wins=%3.0f%%  avg_ante=%.2f  deals/run=%.1f  supplies/run=%.1f  deaths A1-8: %s" % [tag, 100.0 * wins / n, float(ante_sum) / n, float(took) / n, float(used) / n, " ".join(parts)])
	if not tally.is_empty() and tag == "ALL":
		print("EXTRAS   taken: ", tally)
