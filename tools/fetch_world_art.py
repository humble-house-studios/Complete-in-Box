#!/usr/bin/env python3
"""Fetches real pictures for a world's items into assets/temp_test/<world>/.

    python3 tools/fetch_world_art.py sports [--force]

For every line of the world's research list (see tools/gen_worlds.py):
  photo = the Wikipedia lead image of the line's "Wikipedia title" column
          (a player, a person, a brand page for wax boxes)
  scan  = for vintage cards (before 1975), a real scan of that card from
          Wikimedia Commons when a search finds one whose file name has the
          player's surname and a card word in it
Images are cropped to the card's photo window shape and saved as small PNGs
(256 px tall). Every file is logged in assets/temp_test/MANIFEST.txt and
assets/sources.txt (path | url | date). Run gen_worlds.py afterwards so the
catalog picks the pictures up. Test-only assets: swap them later.
"""
import datetime
import io
import json
import os
import subprocess
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_worlds  # noqa: E402

from PIL import Image  # noqa: E402

ROOT = gen_worlds.ROOT
UA = "CollectorsCurseAssetFetch/1.0 (game test assets)"
CARD_WORDS = ["card", "t206", "goudey", "topps", "bowman", "leaf", "parkhurst", "chicle", "fleer", "o-pee-chee", "alifabolaget", "hemmets"]


def get(url, tries=4):
    """curl with a polite pause; backs off when Wikimedia says slow down."""
    for k in range(tries):
        time.sleep(1.5 + k * 6)
        r = subprocess.run(["curl", "-sS", "-L", "-m", "40", "-A", UA, url], capture_output=True)
        if r.returncode == 0 and not r.stdout.startswith(b"You are making too many") and b"Too Many Requests" not in r.stdout[:300]:
            return r.stdout
    return b""


def api(base, params):
    params["format"] = "json"
    return json.loads(get(base + "?" + urllib.parse.urlencode(params)) or b"{}")


def wiki_images(titles):
    """Lead images for many pages at once (50 per request): {title: url}."""
    out = {}
    titles = sorted(set(titles))
    for i in range(0, len(titles), 40):
        chunk = titles[i:i + 40]
        j = api("https://en.wikipedia.org/w/api.php", {"action": "query", "titles": "|".join(chunk), "prop": "pageimages",
                                                        "pithumbsize": 400, "redirects": 1, "pilicense": "any"})
        q = j.get("query", {})
        back = {}
        for n in q.get("normalized", []) + q.get("redirects", []):
            back[n["to"]] = back.get(n["from"], n["from"])
        for p in q.get("pages", {}).values():
            t = p.get("thumbnail", {}).get("source", "")
            if t:
                out[back.get(p["title"], p["title"])] = t
                out[p["title"]] = t
    return out


def commons_scan(query, surname):
    j = api("https://commons.wikimedia.org/w/api.php", {"action": "query", "list": "search", "srnamespace": 6,
                                                         "srsearch": query, "srlimit": 10})
    for hit in j.get("query", {}).get("search", []):
        t = hit["title"]
        low = t.lower()
        if surname.lower() in low and any(w in low for w in CARD_WORDS) and low.endswith((".jpg", ".jpeg", ".png")):
            info = api("https://commons.wikimedia.org/w/api.php", {"action": "query", "titles": t, "prop": "imageinfo",
                                                                    "iiprop": "url", "iiurlwidth": 400})
            for p in info.get("query", {}).get("pages", {}).values():
                ii = p.get("imageinfo", [{}])[0]
                if ii.get("thumburl"):
                    return ii["thumburl"]
    return ""


def save(data, path, aspect):
    """Crops to width/height = aspect (centred, a little high for faces), 256 tall."""
    im = Image.open(io.BytesIO(data)).convert("RGB")
    w, h = im.size
    if w / h > aspect:
        nw = int(h * aspect)
        x = (w - nw) // 2
        im = im.crop((x, 0, x + nw, h))
    else:
        nh = int(w / aspect)
        y = int((h - nh) * 0.2)
        im = im.crop((0, y, w, y + nh))
    im = im.resize((max(1, int(256 * aspect)), 256), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, optimize=True)


def log(rel, url):
    day = datetime.date.today().isoformat()
    for f in ("assets/temp_test/MANIFEST.txt", "assets/sources.txt"):
        p = os.path.join(ROOT, f)
        line = "%s | %s" % (rel, url) + ("" if "MANIFEST" in f else " | %s" % day)
        old = open(p, encoding="utf-8").read() if os.path.exists(p) else ""
        if rel + " |" in old:
            continue
        with open(p, "a", encoding="utf-8") as fh:
            if not old and "MANIFEST" in f:
                fh.write("# Test-only sourced files (path | source URL). Swap before shipping.\n")
            fh.write(line + "\n")


def main():
    world = sys.argv[1]
    force = "--force" in sys.argv
    items = gen_worlds.build(world)
    conf = gen_worlds.load_conf(world)
    rows = gen_worlds.parse(os.path.join(ROOT, "docs", "research", conf.LIST))
    by_rank = {(r["code"], r["rank"]): r for r in rows}
    out_dir = os.path.join(ROOT, "assets", "temp_test", world)
    got = 0
    titles = []
    for r in rows:
        titles += [t.strip() for t in r["wiki"].split(";") if t.strip() and t.strip() != "-"]
    imgs = wiki_images(titles)
    print("lead images", len(imgs))
    for d in items:
        r = by_rank[(d["plat"], d["rank"])]
        cands = [t.strip() for t in r["wiki"].split(";") if t.strip() and t.strip() != "-"]
        if not cands or d["kind"] in getattr(conf, "NO_PHOTO_KINDS", ()):
            continue
        title = next((t for t in cands if imgs.get(t)), cands[0])
        rel = "assets/temp_test/%s/%s_photo.png" % (world, d["id"])
        if force or not (os.path.exists(os.path.join(ROOT, rel)) or os.path.exists(os.path.join(ROOT, rel.replace("_photo.", "_scan.")))):
            url = imgs.get(title, "")
            if url:
                data = get(url)
                if data:
                    try:
                        cover = getattr(conf, "COVER_ASPECT", 0.0)
                        im = Image.open(io.BytesIO(data))
                        ar = im.size[0] / max(1, im.size[1])
                        if cover > 0 and abs(ar - cover) < 0.12:
                            # Shaped like the item's own cover: use it as the whole front.
                            rel = rel.replace("_photo.", "_scan.")
                            save(data, os.path.join(ROOT, rel), cover)
                        else:
                            save(data, os.path.join(ROOT, rel), getattr(conf, "PHOTO_ASPECT", 0.78))
                        log(rel, url)
                        got += 1
                    except Exception as e:  # bad image: skip it
                        print("skip", d["id"], e)
        if getattr(conf, "SCAN_SEARCH", False) and d["kind"] == "scard" and r["year"] < 1975:
            rel2 = "assets/temp_test/%s/%s_scan.png" % (world, d["id"])
            if force or not os.path.exists(os.path.join(ROOT, rel2)):
                surname = r["name"].split()[-1]
                url = commons_scan("%d %s %s card" % (r["year"], r["detail"].split("#")[0].strip(), r["name"]), surname)
                if url:
                    data = get(url)
                    if data:
                        try:
                            save(data, os.path.join(ROOT, rel2), 0.714)
                            log(rel2, url)
                            got += 1
                        except Exception as e:
                            print("skip scan", d["id"], e)
        print(d["id"], "photo" if os.path.exists(os.path.join(ROOT, rel)) else "-",
              "scan" if os.path.exists(os.path.join(out_dir, d["id"] + "_scan.png")) else "")
    print("fetched", got)
    gen_worlds.build(world)


if __name__ == "__main__":
    main()
