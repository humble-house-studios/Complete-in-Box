extends SceneTree
## Renders every prop in assets/models/props/<subdir> (PSX materials) into
## OUT_DIR/<name>.png for picking props:  ... -s res://tools/prop_sheet.gd -- OUT_DIR [subdir]

func _initialize() -> void:
	DisplayServer.window_set_size(Vector2i(160, 160))
	_go.call_deferred()


func _go() -> void:
	var args := OS.get_cmdline_user_args()
	var out: String = args[0]
	var sub: String = args[1] if args.size() > 1 else ""
	DirAccess.make_dir_recursive_absolute(out)
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.3, 0.3, 0.35)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.7, 0.7)
	we.environment = e
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	root.add_child(sun)
	var cam := Camera3D.new()
	root.add_child(cam)
	Psx.fog_near = 100.0
	Psx.fog_far = 200.0
	var dir := "res://assets/models/props/" + sub
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".glb"):
			continue
		var name := (sub + "/" + f.get_basename()) if sub != "" else f.get_basename()
		var p := Psx.prop(name, 1.0)
		root.add_child(p)
		var b := Psx.aabb(p)
		var c := b.get_center()
		var r := b.size.length() * 0.5
		cam.position = c + Vector3(1, 0.7, 1.4).normalized() * r * 2.6
		cam.look_at(c)
		for i in 3:
			await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(name.replace("/", "_") + ".png"))
		p.queue_free()
	quit()
