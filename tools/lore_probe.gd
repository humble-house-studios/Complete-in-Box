extends SceneTree
## Prints the item-card history for a few items (and two copies of one).
func _init() -> void:
	var ids := [Catalog.ITEMS[0], Catalog.ITEMS[300], Catalog.ITEMS[650], Catalog.ITEMS[5]]
	for d in ids:
		print("== ", d["name"], " (", d["plat"], ")")
		for h in Flavor.history(d, {"uid": 7, "serial": 1234, "kind": d["kind"], "tier": d["tier"]}):
			print("  ", h[0], ": ", h[1])
	print("-- another copy: ", Flavor.provenance(ids[0], {"uid": 8}, Flavor.facts(ids[0])))
	quit()
