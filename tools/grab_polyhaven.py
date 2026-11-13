#!/usr/bin/env python3
"""Downloads Poly Haven models (CC0) as small single-file GLBs for the PSX look.

    python3 tools/grab_polyhaven.py lantern_chandelier_01 pocket_watch ...

Each lands in assets/temp_test/models/<name>.glb: the 1k glTF, with only the
diffuse textures kept (shrunk to 256 px, the PSX shader ignores the rest) and
everything packed into one GLB. Load it with Psx.prop("temp:<name>", h).
Logged in assets/temp_test/MANIFEST.txt and assets/sources.txt.
"""
import datetime
import io
import json
import os
import struct
import subprocess
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "temp_test", "models")
UA = "Mozilla/5.0 (CollectorsCurse asset fetch)"


def get(url):
    r = subprocess.run(["curl", "-sS", "-L", "-m", "120", "-A", UA, url], capture_output=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.decode()[:200])
    return r.stdout


def pad4(b, fill=b"\0"):
    return b + fill * ((4 - len(b) % 4) % 4)


def grab(name):
    info = json.loads(get("https://api.polyhaven.com/files/" + name))
    g = info["gltf"]["1k"]["gltf"]
    inc = {k: v["url"] for k, v in g.get("include", {}).items()}
    base = g["url"].rsplit("/", 1)[0] + "/"
    src = lambda uri: inc.get(uri, base + uri)  # noqa: E731
    doc = json.loads(get(g["url"]))
    bins = {}
    for b in doc.get("buffers", []):
        bins[b["uri"]] = get(src(b["uri"]))
    # Keep only base colour textures; drop normal / ARM maps from materials.
    used = set()
    for m in doc.get("materials", []):
        pbr = m.get("pbrMetallicRoughness", {})
        pbr.pop("metallicRoughnessTexture", None)
        m.pop("normalTexture", None)
        m.pop("occlusionTexture", None)
        if "baseColorTexture" in pbr:
            used.add(doc["textures"][pbr["baseColorTexture"]["index"]]["source"])
    # One binary blob: the original buffer(s), then each kept image.
    blob = b""
    views = doc.get("bufferViews", [])
    offsets = {}
    for uri, data in bins.items():
        offsets[uri] = len(blob)
        blob = pad4(blob + data)
    for v in views:
        uri = doc["buffers"][v["buffer"]]["uri"]
        v["byteOffset"] = v.get("byteOffset", 0) + offsets[uri]
        v["buffer"] = 0
    for i, img in enumerate(doc.get("images", [])):
        if i not in used:
            img.clear()
            img["mimeType"] = "image/png"
            data = _png(Image.new("RGB", (4, 4), (128, 128, 128)))
        else:
            im = Image.open(io.BytesIO(get(src(img["uri"])))).convert("RGBA" if "alpha" in img["uri"] else "RGB")
            im.thumbnail((256, 256))
            data = _png(im)
            img.clear()
            img["mimeType"] = "image/png"
        views.append({"buffer": 0, "byteOffset": len(blob), "byteLength": len(data)})
        img["bufferView"] = len(views) - 1
        blob = pad4(blob + data)
    doc["bufferViews"] = views
    doc["buffers"] = [{"byteLength": len(blob)}]
    js = pad4(json.dumps(doc, separators=(",", ":")).encode(), b" ")
    glb = struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(blob))
    glb += struct.pack("<II", len(js), 0x4E4F534A) + js + struct.pack("<II", len(blob), 0x004E4942) + blob
    os.makedirs(OUT, exist_ok=True)
    path = os.path.join(OUT, name + ".glb")
    open(path, "wb").write(glb)
    rel = os.path.relpath(path, ROOT)
    page = "https://polyhaven.com/a/" + name
    day = datetime.date.today().isoformat()
    for f, line in (("assets/temp_test/MANIFEST.txt", "%s | %s" % (rel, page)), ("assets/sources.txt", "%s | %s | %s" % (rel, page, day))):
        p = os.path.join(ROOT, f)
        old = open(p, encoding="utf-8").read() if os.path.exists(p) else ""
        if rel + " |" not in old:
            open(p, "a", encoding="utf-8").write(line + "\n")
    print(name, "%.0f KB" % (len(glb) / 1024))


def _png(im):
    b = io.BytesIO()
    im.save(b, "PNG", optimize=True)
    return b.getvalue()


if __name__ == "__main__":
    for n in sys.argv[1:]:
        grab(n)
