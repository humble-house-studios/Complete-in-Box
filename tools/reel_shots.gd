extends SceneTree
## Frames of the slot reel at a few moments (spinning, slowing, landed) for
## each tier. xvfb-run -a godot --rendering-driver opengl3 -s res://tools/reel_shots.gd -- OUT.png

const SLOT_REEL := preload("res://scripts/ui/slot_reel.gd")


func _init() -> void:
	var out := "reel.png"
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	root.content_scale_size = Vector2i(720, 980)
	root.size = Vector2i(720, 980)
	var bg := ColorRect.new()
	bg.color = Color(0.2, 0.18, 0.25)
	bg.size = Vector2(720, 980)
	root.add_child(bg)
	var moments := [0.15, 0.6, 0.97, -1.0]
	var cols := [Color("d04040"), Color("4060d0"), Color("40a060"), Color("c0a030")]
	for t in 4:
		for m in moments.size():
			var holder := Control.new()
			holder.position = Vector2(10 + m * 177, 10 + t * 240)
			holder.size = Vector2(170, 196)
			bg.add_child(holder)
			var r: Control = SLOT_REEL.new()
			r.tier = t
			r.tier_col = Catalog.TIER_COLORS[t]
			r.odds = [38, 36, 21, 5]
			r.plat_cols = cols
			holder.add_child(r)
			r.set_process(false)
			r.set_meta("m", moments[m])
	await process_frame
	for holder in bg.get_children():
		var r: Control = holder.get_child(0)
		var m: float = r.get_meta("m")
		if m < 0.0:
			r._phase = 3
			r._x = r.LAND
			r._flash = 0.5
		else:
			r._phase = 1
			r._t = r.dur * m
			r._x = r._end * (1.0 - pow(1.0 - m, 5.0))
		r.queue_redraw()
	for i in 4:
		await process_frame
	root.get_texture().get_image().save_png(out)
	quit()
