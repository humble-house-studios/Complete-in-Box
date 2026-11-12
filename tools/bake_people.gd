extends SceneTree
## Bakes Rocketbox avatars (FBX, Microsoft-Rocketbox, MIT) into light static
## meshes for the PSX rooms: arms lowered from the A-pose (plus a per-person
## stance), skinning applied on the CPU, saved as res://assets/models/people_rb/<name>.res
## (surfaces: body, head, hair/opacity). Run after copying the FBX files into
## res://_rb_tmp/<name>.fbx and importing (see tools/gen_people.sh):
##   godot --headless -s res://tools/bake_people.gd

const SRC := "res://_rb_tmp/"
const OUT := "res://assets/models/people_rb/"

## name -> [arm drop degrees, elbow bend degrees, arm swing forward degrees]
const STANCE := {"default": [40.0, 12.0, 15.0]}


func _initialize() -> void:
	var d := DirAccess.open(SRC)
	for f in d.get_files():
		if f.ends_with(".fbx"):
			_bake(f.get_basename())
	quit()


func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r != null:
			return r
	return null


func _bake(name: String) -> void:
	var root: Node3D = (load(SRC + name + ".fbx") as PackedScene).instantiate()
	var sk: Skeleton3D = _find(root, "Skeleton3D")
	var mi: MeshInstance3D = _find(root, "MeshInstance3D")
	if sk == null or mi == null:
		print("skip ", name)
		return
	var st: Array = STANCE.get(name, STANCE["default"])
	for side in ["L", "R"]:
		var sgn := 1.0 if side == "L" else -1.0
		var ua := sk.find_bone("Bip01 %s UpperArm" % side)
		var fa := sk.find_bone("Bip01 %s Forearm" % side)
		if ua >= 0:
			var q := sk.get_bone_pose_rotation(ua)
			var drop := Quaternion(Vector3(0, 1, 0), deg_to_rad(float(st[0]) * sgn)) * Quaternion(Vector3(0, 0, 1), deg_to_rad(float(st[2])))
			sk.set_bone_pose_rotation(ua, q * drop)
		if fa >= 0:
			var q2 := sk.get_bone_pose_rotation(fa)
			sk.set_bone_pose_rotation(fa, q2 * Quaternion(Vector3(0, 1, 0), deg_to_rad(-float(st[1]))))
	var skin: Skin = mi.skin
	var mats: Array = []
	for i in skin.get_bind_count():
		var bone := skin.get_bind_bone(i)
		if bone < 0:
			bone = sk.find_bone(skin.get_bind_name(i))
		mats.append(sk.get_bone_global_pose(bone) * skin.get_bind_pose(i))
	var src: Mesh = mi.mesh
	var out := ArrayMesh.new()
	for s in src.get_surface_count():
		var a := src.surface_get_arrays(s)
		var vs: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var ns: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var bs: PackedInt32Array = a[Mesh.ARRAY_BONES]
		var ws: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		var per := bs.size() / maxi(1, vs.size())
		var nv := PackedVector3Array()
		var nn := PackedVector3Array()
		nv.resize(vs.size())
		nn.resize(vs.size())
		for v in vs.size():
			var p := Vector3.ZERO
			var q := Vector3.ZERO
			var tw := 0.0
			for k in per:
				var w := ws[v * per + k]
				if w <= 0.0:
					continue
				var m: Transform3D = mats[bs[v * per + k]]
				p += (m * vs[v]) * w
				q += (m.basis * ns[v]) * w
				tw += w
			nv[v] = p / maxf(tw, 0.0001)
			nn[v] = q.normalized()
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = nv
		arr[Mesh.ARRAY_NORMAL] = nn
		arr[Mesh.ARRAY_TEX_UV] = a[Mesh.ARRAY_TEX_UV]
		arr[Mesh.ARRAY_INDEX] = a[Mesh.ARRAY_INDEX]
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	DirAccess.make_dir_recursive_absolute(OUT)
	ResourceSaver.save(out, OUT + name + ".res", ResourceSaver.FLAG_COMPRESS)
	print("baked ", name, " ", out.get_aabb())
	root.free()
