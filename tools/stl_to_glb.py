#!/usr/bin/env python3
"""Converts a binary STL (mm, Z up, front facing -Y) into a .glb for Godot:
Y up, front facing +Z, base on y=0, metres x10 (so ~1 unit wide), with a
planar front-view UV on front-facing triangles (u = x across, v = top->bottom)
so the PSX label shader can put a sticker in a UV rect. Everything else maps
to UV (0.01, 0.99), outside any label.
Usage: python3 tools/stl_to_glb.py IN.stl OUT.glb"""
import json, struct, sys
import numpy as np

src, out = sys.argv[1], sys.argv[2]
d = open(src, "rb").read()
n = struct.unpack("<I", d[80:84])[0]
a = np.frombuffer(d[84:84 + 50 * n], dtype=np.dtype([("n", "<3f4"), ("v", "<9f4"), ("a", "<u2")]))
v = a["v"].reshape(-1, 3, 3).astype(np.float64)
lo = v.reshape(-1, 3).min(0)
hi = v.reshape(-1, 3).max(0)
size = hi - lo
# STL (x, y, z) -> Godot (x, z, -y), centred in x/z, base on y=0, mm -> 1/100.
p = np.empty_like(v)
p[..., 0] = v[..., 0] - (lo[0] + hi[0]) / 2
p[..., 1] = v[..., 2] - lo[2]
p[..., 2] = -(v[..., 1] - (lo[1] + hi[1]) / 2)
p *= 0.01
e1 = p[:, 1] - p[:, 0]
e2 = p[:, 2] - p[:, 0]
nr = np.cross(e1, e2)
nr /= np.maximum(np.linalg.norm(nr, axis=1, keepdims=True), 1e-12)
uv = np.zeros((n, 3, 2))
uv[..., 0] = (v[..., 0] - lo[0]) / size[0]
uv[..., 1] = (hi[2] - v[..., 2]) / size[2]
front = nr[:, 2] > 0.5
uv[~front] = (0.01, 0.99)
pos = p.reshape(-1, 3).astype("<f4")
nor = np.repeat(nr, 3, axis=0).astype("<f4")
tex = uv.reshape(-1, 2).astype("<f4")
blob = pos.tobytes() + nor.tobytes() + tex.tobytes()
cnt = len(pos)
views = [{"buffer": 0, "byteOffset": 0, "byteLength": cnt * 12},
         {"buffer": 0, "byteOffset": cnt * 12, "byteLength": cnt * 12},
         {"buffer": 0, "byteOffset": cnt * 24, "byteLength": cnt * 8}]
acc = [{"bufferView": 0, "componentType": 5126, "count": cnt, "type": "VEC3",
        "min": pos.min(0).tolist(), "max": pos.max(0).tolist()},
       {"bufferView": 1, "componentType": 5126, "count": cnt, "type": "VEC3"},
       {"bufferView": 2, "componentType": 5126, "count": cnt, "type": "VEC2"}]
gl = {"asset": {"version": "2.0", "generator": "stl_to_glb.py"}, "scene": 0,
      "scenes": [{"nodes": [0]}], "nodes": [{"mesh": 0, "name": "cart"}],
      "materials": [{"name": "body", "pbrMetallicRoughness": {"baseColorFactor": [0.5, 0.5, 0.52, 1], "metallicFactor": 0, "roughnessFactor": 1}}],
      "meshes": [{"primitives": [{"attributes": {"POSITION": 0, "NORMAL": 1, "TEXCOORD_0": 2}, "material": 0}]}],
      "buffers": [{"byteLength": len(blob)}], "bufferViews": views, "accessors": acc}
js = json.dumps(gl).encode()
js += b" " * (-len(js) % 4)
blob += b"\0" * (-len(blob) % 4)
with open(out, "wb") as f:
    f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob)))
    f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
    f.write(struct.pack("<II", len(blob), 0x004E4942) + blob)
print(out, n, "tris, size mm", size.round(1).tolist(), "front tris", int(front.sum()))
