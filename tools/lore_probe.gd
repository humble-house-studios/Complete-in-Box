extends SceneTree
## Prints the item-card history for a few items, and counts repeated lines
## across a whole catalog's worth of cards (as if all shown in one run).
func _init() -> void:
	Flavor.reset_claims()
	for i in [0, 300, 650, 5]:
		var d: Dictionary = Catalog.ITEMS[i]
		print("== ", d["name"], " (", d["plat"], ")")
		for h in Flavor.history(d, {"uid": 7, "serial": 1234}):
			print("  ", h[0], ": ", h[1])
		for n in Flavor.numbers(d):
			print("  # ", n[0], ": ", n[1])
	var seen := {}
	var dup := 0
	var total := 0
	for d in Catalog.ITEMS:
		for h in Flavor.history(d, {"uid": hash(d["id"])}):
			total += 1
			if seen.has(h[1]):
				dup += 1
				if dup < 12:
					print("REPEAT ", h[0], ": ", h[1])
			seen[h[1]] = true
		for n in Flavor.numbers(d):
			total += 1
			var k: String = n[0] + n[1]
			if seen.has(k):
				dup += 1
				if dup < 12:
					print("REPEAT# ", k)
			seen[k] = true
	print("lines=", total, " exact repeats=", dup)
	quit()
