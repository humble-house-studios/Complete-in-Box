#!/usr/bin/env bash
# Grab an asset (or asset pack) from the web into the Godot project.
#
#   tools/grab.sh <url> <dest_folder>
#
#   tools/grab.sh https://opengameart.org/content/ui-pack assets/ui/kenney_ui
#   tools/grab.sh https://example.com/pack.zip            assets/audio/sfx/clicks
#   tools/grab.sh https://example.com/thing.glb           assets/models/thing
#
# <url> can be a direct file (zip/7z/rar/tar/glb/ogg/png/...) or an
# OpenGameArt-style HTML page (its downloadable attachments get fetched).
# It downloads, extracts nested archives, keeps only files Godot can use,
# converts audio to .ogg and 3D models to .glb, copies the result into
# <dest_folder> and appends "path | url | date" to assets/sources.txt.
#
# Needs: curl unzip 7z ffmpeg assimp python3
set -euo pipefail

[ $# -eq 2 ] || { sed -n '2,13p' "$0"; exit 1; }
URL=$1
ROOT=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
DEST=${2%/}
case "$DEST" in /*) DEST=$(realpath -m --relative-to="$ROOT" "$DEST");; esac
OUT="$ROOT/$DEST"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
DL="$TMP/dl"; X="$TMP/x"; mkdir -p "$DL" "$X"

log()  { printf '\033[1;34m[grab]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[grab] WARN:\033[0m %s\n' "$*" >&2; }

fetch() { # url -> file in $DL (name from URL)
  local u=$1 name
  name=$(python3 -I -c 'import sys,urllib.parse as p,os;print(os.path.basename(p.unquote(p.urlparse(sys.argv[1]).path)) or "download")' "$u")
  log "download $u"
  curl -fsSL --retry 3 --connect-timeout 20 -m 900 -o "$DL/$name" "$u"
}

# ---- 1. download ---------------------------------------------------------
fetch "$URL"
first=$(ls "$DL")
if file -b --mime-type "$DL/$first" | grep -q 'text/html'; then
  log "HTML page: looking for downloadable files"
  links=$(python3 -I - "$URL" "$DL/$first" <<'PY'
import re, sys, urllib.parse as p
base, html = sys.argv[1], open(sys.argv[2], errors="ignore").read()
# OpenGameArt (and many CMSes): <a href=".." ... download="..">
links = re.findall(r'<a href="([^"]+)"[^>]*\bdownload=', html)
if not links:  # generic fallback: links to archives / asset files
    ext = r'zip|7z|rar|tar|tgz|gz|glb|gltf|fbx|obj|dae|ogg|wav|mp3|flac|ttf|otf'
    links = re.findall(r'href="([^"]+\.(?:%s))(?:\?[^"]*)?"' % ext, html, re.I)
seen = []
for l in links:
    u = p.urljoin(base, l.replace("&amp;", "&"))
    if u not in seen: seen.append(u); print(u)
PY
)
  rm -f "$DL/$first"
  [ -n "$links" ] || { echo "No downloadable files found on $URL" >&2; exit 1; }
  while read -r l; do fetch "$l"; done <<<"$links"
fi

# ---- 2. extract (nested archives too) ------------------------------------
mv "$DL"/* "$X"/
for _ in 1 2 3; do
  found=0
  while IFS= read -r -d '' a; do
    found=1; d="${a%.*}"; mkdir -p "$d"
    log "extract ${a#$X/}"
    case "${a,,}" in
      *.zip)                  unzip -q -o "$a" -d "$d" || 7z x -y -o"$d" "$a" >/dev/null ;;
      *.tar|*.tar.gz|*.tgz)   tar -xf "$a" -C "$d" ;;
      *)                      7z x -y -o"$d" "$a" >/dev/null ;;
    esac
    rm -f "$a"
  done < <(find "$X" -type f \( -iname '*.zip' -o -iname '*.7z' -o -iname '*.rar' -o -iname '*.tar' -o -iname '*.tar.gz' -o -iname '*.tgz' \) -print0)
  [ $found = 1 ] || break
done

# collapse single wrapper folders (pack.zip -> pack/ -> pack/...)
while [ "$(find "$X" -mindepth 1 -maxdepth 1 | wc -l)" = 1 ] && [ -d "$X"/* ]; do
  w=$(echo "$X"/*); mv "$w" "$TMP/w"; rmdir "$X" 2>/dev/null || rm -rf "$X"; mv "$TMP/w" "$X"
done

# ---- 3. convert ----------------------------------------------------------
# audio -> .ogg (Godot plays ogg/wav natively; everything else gets converted)
while IFS= read -r -d '' f; do
  o="${f%.*}.ogg"
  if ffmpeg -nostdin -loglevel error -y -i "$f" -vn -c:a libvorbis -q:a 5 "$o"; then rm -f "$f"
  else warn "audio convert failed: ${f#$X/}"; rm -f "$o"; fi
done < <(find "$X" -type f \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.aif' -o -iname '*.aiff' -o -iname '*.m4a' -o -iname '*.opus' -o -iname '*.wma' -o -iname '*.aac' \) -print0)

# 3D -> .glb. If the pack already ships glb/gltf, use those and drop the rest.
if find "$X" -type f \( -iname '*.glb' -o -iname '*.gltf' \) | grep -q .; then
  find "$X" -type f \( -iname '*.fbx' -o -iname '*.obj' -o -iname '*.dae' -o -iname '*.3ds' -o -iname '*.blend' -o -iname '*.ply' -o -iname '*.stl' \) -delete
else
  # one source per model stem, best format first
  declare -A done_stem=()
  for ext in fbx obj dae 3ds ply stl blend; do
    while IFS= read -r -d '' f; do
      stem="${f%.*}"; key="${stem,,}"
      if [ -z "${done_stem[$key]:-}" ]; then
        if (cd "$(dirname "$f")" && assimp export "$(basename "$f")" "$(basename "$stem").glb" -f glb2 >/dev/null 2>&1); then
          done_stem[$key]=1; log "3D -> ${stem#$X/}.glb"
        else warn "3D convert failed: ${f#$X/}"; rm -f "$stem.glb"; fi
      fi
      rm -f "$f"
    done < <(find "$X" -type f -iname "*.$ext" -print0)
  done
fi

# ---- 4. keep only usable game files --------------------------------------
KEEP='png|jpg|jpeg|webp|svg|tga|bmp|exr|hdr|ktx|ogg|wav|glb|gltf|bin|ttf|otf|woff|woff2|fnt|tres|tscn|gdshader|json|xml|tmx|tsx'
find "$X" -name '__MACOSX' -prune -exec rm -rf {} +
find "$X" -type f | while IFS= read -r f; do
  b=$(basename "$f"); e="${b##*.}"; e="${e,,}"
  [[ "${b,,}" =~ ^(license|licence|readme|credits) && "$e" =~ ^(txt|md)$ ]] && continue
  [[ "$e" =~ ^($KEEP)$ ]] || rm -f "$f"
done
# pack-level preview/sample images at the top level only
find "$X" -maxdepth 1 -type f \( -iname 'preview*' -o -iname 'sample*' -o -iname 'render*' -o -iname 'thumbnail*' -o -iname 'cover*' \) -delete
find "$X" -type d -empty -delete
mkdir -p "$X"

n=$(find "$X" -type f | wc -l)
[ "$n" -gt 0 ] || { echo "Nothing usable left after filtering." >&2; exit 1; }

# ---- 5. install + log ----------------------------------------------------
mkdir -p "$OUT"
cp -r "$X"/. "$OUT"/
printf '%s | %s | %s\n' "$DEST" "$URL" "$(date +%F)" >> "$ROOT/assets/sources.txt"

log "added $n files to $DEST ($(du -sh "$OUT" | cut -f1))"
find "$OUT" -type f ! -name '*.import' | sed 's/.*\.//' | tr 'A-Z' 'a-z' | sort | uniq -c | sed 's/^/        /'
find "$OUT" -type f -size +10M -exec echo "        big file (LFS): {}" \;
log "next: godot --headless --path \"$ROOT\" --import"
