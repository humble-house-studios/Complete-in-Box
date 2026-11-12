#!/bin/bash
# Fetches Rocketbox avatars (github.com/microsoft/Microsoft-Rocketbox, MIT),
# shrinks their colour textures and bakes them into static PSX-ready meshes
# (tools/bake_people.gd) in assets/models/people_rb/.
# Usage: tools/gen_people.sh CLONE_DIR GODOT_BIN
#   CLONE_DIR: git clone --depth 1 --filter=blob:none --sparse https://github.com/microsoft/Microsoft-Rocketbox.git
set -e
CLONE="$1"; GODOT="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CAST="Adults/Male_Adult_01 Adults/Male_Adult_03 Adults/Male_Adult_05 Adults/Male_Adult_08 Adults/Male_Adult_11 Adults/Male_Adult_14 Adults/Male_Adult_17
Adults/Female_Adult_01 Adults/Female_Adult_03 Adults/Female_Adult_05 Adults/Female_Adult_08 Adults/Female_Adult_11 Adults/Female_Adult_14
Professions/Business_Male_02 Professions/Security_Male_01 Professions/Construction_Male_01"
PATHS=""
for c in $CAST; do PATHS="$PATHS /Assets/Avatars/$c/Export/$(basename $c).fbx /Assets/Avatars/$c/Textures/*_color.tga"; done
git -C "$CLONE" sparse-checkout set --no-cone $PATHS
mkdir -p "$ROOT/_rb_tmp" "$ROOT/assets/models/people_rb"
for c in $CAST; do
  n=$(basename $c | tr 'A-Z' 'a-z')
  cp "$CLONE/Assets/Avatars/$c/Export/$(basename $c).fbx" "$ROOT/_rb_tmp/$n.fbx"
  python3 -I - "$CLONE/Assets/Avatars/$c/Textures" "$ROOT/assets/models/people_rb/$n" <<'PY'
import sys, glob, os
from PIL import Image
src, out = sys.argv[1], sys.argv[2]
for f in glob.glob(os.path.join(src, "*_color.tga")):
    b = os.path.basename(f)
    kind = "opacity" if "opacity" in b else ("head" if "head" in b else "body")
    im = Image.open(f)
    im = im.convert("RGBA" if kind == "opacity" else "RGB")
    im = im.resize((128, 128) if kind == "opacity" else (256, 256), Image.LANCZOS)
    im.save(out + "_" + kind + ".png", optimize=True)
    imp = out + "_" + kind + ".png.import"
    if kind != "opacity" and not os.path.exists(imp):
        open(imp, "w").write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n[params]\n\ncompress/mode=1\ncompress/lossy_quality=0.85\n')
PY
done
cd "$ROOT"
"$GODOT" --headless --import >/dev/null 2>&1 || true
"$GODOT" --headless -s res://tools/bake_people.gd
rm -rf "$ROOT/_rb_tmp"
"$GODOT" --headless --import >/dev/null 2>&1 || true
