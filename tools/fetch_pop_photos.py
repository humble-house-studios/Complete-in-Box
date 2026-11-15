#!/usr/bin/env python3
"""Real product photos for the pop culture world, cut out of their backdrop (test-only).

    python3 tools/fetch_pop_photos.py find [--only ID_PART]   candidates per item -> .cache/pop_cands.json
    python3 tools/fetch_pop_photos.py sheet OUT_DIR             contact sheets of the candidates (pick by eye)
    python3 tools/fetch_pop_photos.py save [--force]            PICKS -> assets/temp_test/pop/<id>_cut.png

Sources, in order: Wikimedia Commons file search with a hand-written query per
piece (QUERY), then every image on the piece's Wikipedia article, then
PriceCharting (LEGO sets). One request per item (generator=search +
imageinfo), paced for Wikimedia's limits on cloud machines.
`save` downloads the picked file at 800 px and removes the backdrop with rembg
(isnet-general-use), crops to the object and saves a 320 px tall RGBA PNG. The
painter (pop_art.gd) composes it into the blister bubble / window box / plaque,
and ItemModels stands it in 3D when a piece has no real model.
PICKS[real name] = candidate index (from the sheet), or a Commons file title.
"""
import io
import json
import os
import subprocess
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_worlds  # noqa: E402
import fetch_world_art as fwa  # noqa: E402

from PIL import Image, ImageDraw  # noqa: E402

ROOT = gen_worlds.ROOT
CACHE = os.path.join(ROOT, ".cache", "pop")
CANDS = os.path.join(ROOT, ".cache", "pop_cands.json")
UA = "CollectorsCurseAssetFetch/1.0 (game test assets)"
API = "https://commons.wikimedia.org/w/api.php"
WAPI = "https://en.wikipedia.org/w/api.php"

## Commons search per piece (real names as in the research list).
QUERY = {
    "Rocket-Firing Boba Fett": "Boba Fett action figure Kenner", "G.I. Joe Prototype": "G.I. Joe 1964 action figure",
    "Vinyl Cape Jawa": "Jawa action figure", "Luke Skywalker Double-Telescoping Lightsaber": "Luke Skywalker action figure Kenner",
    "Star Wars Early Bird Certificate Package": "Kenner Star Wars action figures 1978", "He-Man": "He-Man action figure",
    "Optimus Prime": "Optimus Prime G1 toy", "Leonardo": "Teenage Mutant Ninja Turtles action figure Leonardo",
    "Mego Superman": "Mego action figure", "Captain Action": "Captain Action figure", "Steve Austin, The Six Million Dollar Man": "Six Million Dollar Man action figure",
    "Lion-O": "ThunderCats action figure", "Captain Kirk": "Mego Star Trek Kirk figure", "Super Powers Batman": "Super Powers Collection Batman figure",
    "Red Ranger": "Power Rangers action figure", "Spawn": "Spawn action figure McFarlane", "Slimer": "Slimer toy", "Micronauts Time Traveler": "Micronauts toy",
    "Stretch Armstrong": "Stretch Armstrong toy", "Kenner Warehouse Case Lot": "Kenner toy box",
    "Pink Rear-Loading Beach Bomb": "Hot Wheels Beach Bomb", "Steiff Teddy Bear": "Steiff teddy bear antique", "Barbie #1 Ponytail": "Barbie 1959 doll",
    "Millennium Falcon Ultimate Collector's Series": "Lego Millennium Falcon 10179", "Princess the Bear": "Princess Beanie Baby",
    "Cabbage Patch Kid": "Cabbage Patch Kids doll", "Evel Knievel Stunt Cycle": "Evel Knievel stunt cycle toy", "Furby": "Furby 1998",
    "Tamagotchi": "Tamagotchi 1996", "Rubik's Cube": "Rubik's Cube", "Tickle Me Elmo": "Tickle Me Elmo", "Mr. Potato Head": "Mr. Potato Head toy",
    "Easy-Bake Oven": "Easy-Bake Oven", "Etch A Sketch": "Etch A Sketch", "Lite-Brite": "Lite-Brite", "Slinky": "Slinky toy",
    "Matchbox Road Roller": "Matchbox Lesney road roller", "View-Master": "View-Master viewer", "Polly Pocket": "Polly Pocket compact",
    "Attic Toy Chest": "toy chest antique", "Ruby Slippers": "Ruby slippers Smithsonian", "Robby the Robot": "Robby the Robot",
    "Aston Martin DB5": "Aston Martin DB5 Goldfinger", "The Subway Dress": "Marilyn Monroe white dress", "1966 Batmobile": "1966 Batmobile",
    "The Maltese Falcon": "Maltese Falcon statuette", "Gingham Dress": "Dorothy Gale dress Wizard of Oz", "Indiana Jones's Fedora": "Indiana Jones fedora",
    "DeLorean Time Machine": "DeLorean time machine", "Luke Skywalker's Lightsaber": "Graflex flash lightsaber", "Rosebud Sled": "Rosebud sled Citizen Kane",
    "Proton Pack": "Ghostbusters proton pack", "Hoverboard": "Back to the Future hoverboard", "Superman Cape": "Christopher Reeve Superman costume",
    "Captain Kirk's Command Chair": "Star Trek captain's chair", "Freddy Krueger's Glove": "Freddy Krueger glove", "Golden Gun": "Golden Gun James Bond prop",
    "Gizmo": "Gizmo Gremlins puppet", "Wilson": "Wilson volleyball Cast Away", "Studio Prop Auction Crate": "wooden crate stencil",
    "Superman Lunchbox": "Superman lunch box", "Hopalong Cassidy Lunchbox": "Hopalong Cassidy lunch box", "Little Orphan Annie Decoder Pin": "Orphan Annie decoder",
    "The Beatles Lunchbox": "Beatles lunch box", "Pez Make-A-Face": "Pez dispenser vintage", "Howdy Doody Marionette": "Howdy Doody puppet",
    "Captain Midnight Decoder Badge": "Captain Midnight Code-O-Graph", "The Jetsons Lunchbox": "Jetsons lunch box", "Star Wars Lunchbox": "Star Wars lunch box",
    "Kiss Lunchbox": "Kiss lunch box", "Davy Crockett Coonskin Cap": "coonskin cap", "Mouseketeer Ears": "Mouseketeer ears hat",
    "Happy Meal Circus Wagon": "Happy Meal box", "Garbage Pail Kids Wax Pack": "Garbage Pail Kids", "Pet Rock": "Pet Rock", "Lava Lamp": "Lava lamp",
    "Mood Ring": "Mood ring", "Magic 8 Ball": "Magic 8-Ball", "Pac-Mania Fan Button": "pinback button 1980s", "Flea Market Lunchbox Stack": "lunch boxes collection",
    "Theatre Basement Poster Tube": "poster tube",
}
## Picked by eye from the contact sheets: real name -> candidate index (or a "File:" title).
## (index, "box") = the photo is the real box / lunchbox lid itself: saved as <id>_box.png and
## painted as the whole front instead of inside a bubble.
PICKS = {
    "G.I. Joe Prototype": 8, "Luke Skywalker Double-Telescoping Lightsaber": 2, "Optimus Prime": 2, "Captain Kirk": 0,
    "Steve Austin, The Six Million Dollar Man": 2, "Lion-O": 1, "Slimer": 8, "Barbie #1 Ponytail": 8,
    "Millennium Falcon Ultimate Collector's Series": (0, "box"), "Steiff Teddy Bear": 0, "Princess the Bear": 0, "Cabbage Patch Kid": 7,
    "Evel Knievel Stunt Cycle": 0, "Furby": 1, "Tamagotchi": 3, "Rubik's Cube": 11, "Mr. Potato Head": 9, "Etch A Sketch": 6,
    "Slinky": 6, "View-Master": 3, "Ruby Slippers": 4, "Robby the Robot": 6, "Aston Martin DB5": 7, "The Subway Dress": 11,
    "1966 Batmobile": 1, "Gingham Dress": 0, "Indiana Jones's Fedora": 7, "DeLorean Time Machine": 5, "Luke Skywalker's Lightsaber": 1,
    "Proton Pack": 1, "Hoverboard": 4, "Superman Cape": 2, "Gizmo": 0,
    "Superman Lunchbox": (11, "box"), "Little Orphan Annie Decoder Pin": 3, "The Beatles Lunchbox": (5, "box"), "Pez Make-A-Face": 2,
    "Howdy Doody Marionette": 0, "The Jetsons Lunchbox": 0, "Kiss Lunchbox": (2, "box"), 
    "Mouseketeer Ears": 0, "Happy Meal Circus Wagon": 5, "Garbage Pail Kids Wax Pack": (3, "box"), "Lava Lamp": 3, "Mood Ring": 5,
    "Magic 8 Ball": 5,
}
## Words that mark a file as the wrong thing (cosplay, people, logos, maps).
BAD = ["cosplay", "costume", "logo", "map", "signature", "svg", "comic-con", "celebration", "portrait", "convention", "statue of", "pdf", "djvu"]


def get(url, pause=1.2, tries=5):
    for k in range(tries):
        time.sleep(pause + k * 15)
        r = subprocess.run(["curl", "-sS", "-L", "-m", "60", "-A", UA, url], capture_output=True)
        if r.returncode == 0 and r.stdout and not r.stdout.startswith(b"You are making too many") and b"Too Many Requests" not in r.stdout[:400]:
            return r.stdout
    return b""


def api(base, params, pause=4.0):
    params["format"] = "json"
    raw = get(base + "?" + urllib.parse.urlencode(params), pause)
    try:
        return json.loads(raw or b"{}")
    except ValueError:
        return {}


def commons(q, n=8):
    """[{title, thumb, w, h}] for a Commons file search, one request."""
    j = api(API, {"action": "query", "generator": "search", "gsrsearch": "filetype:bitmap " + q, "gsrnamespace": 6, "gsrlimit": n,
                  "prop": "imageinfo", "iiprop": "url|size", "iiurlwidth": 320})
    pages = sorted(j.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 99))
    out = []
    for p in pages:
        ii = (p.get("imageinfo") or [{}])[0]
        t = p.get("title", "")
        if not ii.get("thumburl") or any(b in t.lower() for b in BAD):
            continue
        out.append({"title": t, "thumb": ii["thumburl"], "w": ii.get("width", 0), "h": ii.get("height", 0)})
    return out


def openverse(q, n=12):
    """[{title, thumb, url, w, h, src}] from Openverse (Flickr, Commons and other CC collections)."""
    raw = get("https://api.openverse.org/v1/images/?" + urllib.parse.urlencode({"q": q, "page_size": n, "mature": "false"}), 3.5)
    try:
        j = json.loads(raw or b"{}")
    except ValueError:
        return []
    out = []
    for r in j.get("results", []):
        t = r.get("title") or ""
        if any(b in t.lower() for b in BAD):
            continue
        out.append({"title": t, "thumb": r.get("thumbnail") or r.get("url"), "url": r.get("url"), "w": r.get("width") or 0,
                    "h": r.get("height") or 0, "src": r.get("foreign_landing_url") or r.get("url")})
    return out


def article_images(title, n=8):
    """Images used on a Wikipedia article (beyond its lead image), one request."""
    j = api(WAPI, {"action": "query", "generator": "images", "titles": title, "gimlimit": 30, "redirects": 1,
                   "prop": "imageinfo", "iiprop": "url|size", "iiurlwidth": 320})
    out = []
    for p in j.get("query", {}).get("pages", {}).values():
        ii = (p.get("imageinfo") or [{}])[0]
        t = p.get("title", "")
        low = t.lower()
        if not ii.get("thumburl") or any(b in low for b in BAD) or low.endswith((".svg", ".gif", ".ogg", ".ogv", ".webm")):
            continue
        if any(w in low for w in ["icon", "ambox", "question_book", "wiki", "commons-logo", "padlock", "edit-clear", "folder"]):
            continue
        out.append({"title": t, "thumb": ii["thumburl"], "w": ii.get("width", 0), "h": ii.get("height", 0)})
    return out[:n]


def rows():
    conf = gen_worlds.load_conf("pop")
    items = {d["rank"] * 10 + ["FIGS", "TOYS", "PROP", "POST", "MEMO"].index(d["plat"]): d for d in gen_worlds.build("pop")}
    out = []
    for r in gen_worlds.parse(os.path.join(ROOT, "docs", "research", conf.LIST)):
        d = items[r["rank"] * 10 + ["FIGS", "TOYS", "PROP", "POST", "MEMO"].index(r["code"])]
        out.append((r, d))
    return out


def find(only):
    cands = json.load(open(CANDS)) if os.path.exists(CANDS) else {}
    for r, d in rows():
        real = r["name"]
        if r["kind"] == "poster" or (only and only not in d["id"]):
            continue
        if real in cands and cands[real] and not only:
            continue
        got = openverse(QUERY.get(real, real))
        cands[real] = got[:12]
        print(d["id"], len(got), flush=True)
        os.makedirs(os.path.dirname(CANDS), exist_ok=True)
        json.dump(cands, open(CANDS, "w"), indent=1)


def thumb(url):
    os.makedirs(CACHE, exist_ok=True)
    f = os.path.join(CACHE, str(abs(hash(url)) % 10 ** 12) + ".jpg")
    if not os.path.exists(f):
        data = get(url, 0.6)
        if data:
            open(f, "wb").write(data)
    return f if os.path.exists(f) else ""


def sheet(out_dir):
    """One sheet per 8 items: a row each, candidates left to right with their index."""
    cands = json.load(open(CANDS))
    os.makedirs(out_dir, exist_ok=True)
    names = [r["name"] for r, d in rows() if r["name"] in cands]
    for s in range(0, len(names), 8):
        img = Image.new("RGB", (12 * 130 + 220, 8 * 140), (40, 40, 48))
        dr = ImageDraw.Draw(img)
        for k, real in enumerate(names[s:s + 8]):
            y = k * 140
            dr.text((6, y + 60), real[:30], fill=(255, 255, 255))
            for i, c in enumerate(cands[real][:12]):
                f = thumb(c["thumb"])
                if not f:
                    continue
                try:
                    t = Image.open(f).convert("RGB")
                    t.thumbnail((124, 120))
                    img.paste(t, (220 + i * 130, y + 4))
                    dr.text((222 + i * 130, y + 124), str(i), fill=(255, 220, 80))
                except Exception:
                    pass
        p = os.path.join(out_dir, "pop_cands_%02d.png" % (s // 8))
        img.save(p)
        print(p)


def cutout(data):
    from rembg import remove, new_session
    global _SESSION
    if "_SESSION" not in globals():
        _SESSION = new_session("isnet-general-use")
    im = Image.open(io.BytesIO(data)).convert("RGBA")
    im.thumbnail((800, 800))
    cut = remove(im, session=_SESSION)
    box = cut.getchannel("A").point(lambda a: 255 if a > 24 else 0).getbbox()
    if box:
        cut = cut.crop(box)
    h = 320
    cut = cut.resize((max(1, int(cut.width * h / cut.height)), h), Image.LANCZOS)
    if cut.width > 640:
        cut = cut.resize((640, max(1, int(cut.height * 640 / cut.width))), Image.LANCZOS)
    return cut


def save(force):
    cands = json.load(open(CANDS))
    out_dir = os.path.join(ROOT, "assets", "temp_test", "pop")
    n = 0
    for r, d in rows():
        real = r["name"]
        pick = PICKS.get(real, None)
        if pick is None or pick == -1:
            continue
        mode = "cut"
        if isinstance(pick, tuple):
            pick, mode = pick
        c = cands.get(real, [])[pick] if isinstance(pick, int) else {"url": pick, "src": pick, "title": pick}
        rel = "assets/temp_test/pop/%s_%s.png" % (d["id"], mode)
        if os.path.exists(os.path.join(ROOT, rel)) and not force:
            continue
        url = c["url"]
        title = c["title"]
        data = get(url, 1.0)
        if not data:
            print("no data", real)
            continue
        try:
            cutout(data).save(os.path.join(ROOT, rel), optimize=True)
        except Exception as e:
            print("skip", real, e)
            continue
        fwa.log(rel, c.get("src") or url)
        n += 1
        print(d["id"], "<-", title, flush=True)
    print("saved", n)
    gen_worlds.build("pop")


def main():
    a = sys.argv[1:]
    only = a[a.index("--only") + 1] if "--only" in a else ""
    if a[0] == "find":
        find(only)
    elif a[0] == "sheet":
        sheet(a[1])
    elif a[0] == "save":
        save("--force" in a)


if __name__ == "__main__":
    main()
