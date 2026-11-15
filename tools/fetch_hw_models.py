#!/usr/bin/env python3
"""Real 3D models for loose consoles and accessories (test-only, assets/temp_test/models/hw_<form>.glb).

Source: Sketchfab models (Creative Commons) mirrored as plain .glb files by the Objaverse dataset
on Hugging Face (huggingface.co/datasets/allenai/objaverse), so no Sketchfab account or token is needed.
Sketchfab's search API (no key) finds candidates; the uid is the same on both sides.

  python3 tools/fetch_hw_models.py search "nes console" ...   candidates that are in Objaverse
  python3 tools/fetch_hw_models.py [FORM...]                   download -> bake -> shrink

tools/hw_models.json = form -> {uid, keep/drop (mesh indices), rot [x,y,z] so the front faces +Z}.
Pick parts with: godot -s res://tools/bake_hw.gd -- nodes res://.cache/hw/raw/<uid8>.glb OUT.png
Check the result: godot -s res://tools/bake_hw.gd -- sheet OUT.png [FORM...]  (both need xvfb + opengl3)
Shrinking uses glTF Transform (npx @gltf-transform/cli): 256 px textures, meshoptimizer simplify.
ItemModels.HW maps catalog items to forms.
"""
import gzip, json, os, subprocess, sys, time, urllib.parse, urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CFG = os.path.join(ROOT, "tools", "hw_models.json")
CACHE = os.path.join(ROOT, ".cache", "hw")
HF = "https://huggingface.co/datasets/allenai/objaverse/resolve/main/"
UA = {"user-agent": "curl/8.5.0"}
GODOT = os.environ.get("GODOT", "godot")
GT = ["npx", "--yes", "@gltf-transform/cli@4.1.1"]
SIMPLIFY_ERROR = "0.004"


def get(url, dest=None):
    for t in range(4):
        try:
            r = urllib.request.urlopen(urllib.request.Request(url, headers=UA), timeout=120)
            data = r.read()
            if dest:
                open(dest, "wb").write(data)
            return data
        except Exception as e:
            print("  retry", url, e)
            time.sleep(3 * (t + 1))
    raise SystemExit("can't fetch " + url)


def objaverse():
    p = os.path.join(CACHE, "object-paths.json.gz")
    if not os.path.exists(p):
        get(HF + "object-paths.json.gz", p)
    return json.load(gzip.open(p))


def search(queries):
    obj = objaverse()
    for q in queries:
        u = "https://api.sketchfab.com/v3/search?" + urllib.parse.urlencode({"type": "models", "q": q, "count": 24, "max_face_count": 80000})
        print("==", q)
        for r in json.loads(get(u)).get("results", []):
            lic = (r.get("license") or {}).get("label", "")
            if r["uid"] in obj and "NoDeriv" not in lic:
                print("  ", r["uid"], r["faceCount"], lic, "|", r["name"], "by", r["user"]["username"])
        time.sleep(0.5)


def main(only):
    cfg = json.load(open(CFG))
    os.makedirs(os.path.join(CACHE, "raw"), exist_ok=True)
    forms = [f for f in cfg if not only or f in only]
    for f in forms:
        e = cfg[f]
        raw = os.path.join(CACHE, "raw", e["uid"][:8] + ".glb")
        if not os.path.exists(raw):
            print("download", f, e["name"])
            get(HF + e["objaverse"], raw)
    subprocess.run([GODOT, "--headless", "--path", ROOT, "-s", "res://tools/bake_hw.gd", "--", "bake"] + forms, check=True)
    out_dir = os.path.join(ROOT, "assets", "temp_test", "models")
    man = os.path.join(ROOT, "assets", "temp_test", "MANIFEST.txt")
    lines = open(man).read().splitlines() if os.path.exists(man) else []
    for f in forms:
        e = cfg[f]
        out = os.path.join(out_dir, "hw_%s.glb" % f)
        subprocess.run(GT + ["optimize", os.path.join(CACHE, "split", f + ".glb"), out, "--compress", "false",
                             "--texture-compress", "auto", "--texture-size", "256", "--palette", "false",
                             "--instance", "false", "--simplify", "true", "--simplify-error", SIMPLIFY_ERROR],
                       check=True, stdout=subprocess.DEVNULL)
        rel = "assets/temp_test/models/hw_%s.glb" % f
        src = "https://sketchfab.com/3d-models/%s | %s by %s, %s (via Objaverse)" % (e["uid"], e["name"], e["by"], e["license"])
        lines = [l for l in lines if not l.startswith(rel + " ")] + ["%s | %s" % (rel, src)]
        print("%-10s %4d KB  %s" % (f, os.path.getsize(out) // 1024, e["name"]))
    open(man, "w").write("\n".join(lines) + "\n")


if __name__ == "__main__":
    a = sys.argv[1:]
    if a[:1] == ["search"]:
        search(a[1:])
    else:
        main(a)
