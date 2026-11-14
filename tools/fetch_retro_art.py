#!/usr/bin/env python3
"""Fetches real pictures for the retro games and the trading cards (test-only).

    python3 tools/fetch_retro_art.py games [--force] [--only ID_PART]
    python3 tools/fetch_retro_art.py cards [--force] [--only ID_PART]

games: every item tools/gen_catalog.py builds (the parody of a real game or
       console). Games get the real box cover (the Wikipedia lead image of the
       game's article, found by a search with the platform name) cropped to the
       platform's box front shape -> assets/temp_test/games/<id>_scan.jpg.
       Consoles and accessories get the article's product photo (kept whole)
       -> <id>_photo.jpg.
cards: every single card tools/gen_collectibles.py builds. Magic from Scryfall,
       Pokemon from the Pokemon TCG API, Yu-Gi-Oh! from YGOPRODeck, matched on
       the real name and set -> assets/temp_test/cards/<id>_scan.jpg.
       Sealed product and the other games keep their painted art.

Every file is logged in assets/temp_test/MANIFEST.txt and assets/sources.txt.
Runs the generator again at the end so the catalog picks the pictures up.
Test-only assets: swap them before shipping.
"""
import io
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fetch_world_art as fwa  # noqa: E402  (log)

from PIL import Image, ImageFilter  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UA = "CollectorsCurseAssetFetch/1.0 (game test assets)"
H = 256

# Box front shape per platform (ItemModels.GAME_BOX x / y).
BOX = {"FES": 0.72, "SFES": 1.39, "F64": 1.39, "GEN": 0.72, "A26": 0.76, "PBOY": 0.91, "PST": 1.11, "DC": 1.11,
       "PST2": 0.71, "XBX": 0.71, "FCUBE": 0.73, "PSPK": 0.62, "SAT": 0.82, "NEO": 0.74, "PBA": 0.91, "DUO": 1.07}
PLAT_WORDS = {"FES": "NES", "SFES": "Super NES", "F64": "Nintendo 64", "PBOY": "Game Boy", "PBA": "Game Boy Advance",
              "PST": "PlayStation", "PST2": "PlayStation 2", "XBX": "Xbox", "FCUBE": "GameCube", "DC": "Dreamcast",
              "GEN": "Genesis", "SAT": "Saturn", "NEO": "Neo Geo", "A26": "Atari 2600", "PSPK": "PSP", "DUO": "Nintendo DS",
              "ODD": "", "MISC": ""}
STOP = {"the", "of", "a", "an", "and", "edition", "japan", "game", "video", "video game", "&", "ii", "for", "in", "to", "on",
        "version", "console", "model", "with", "bundle", "limited", "sealed", "cib", "complete", "in", "box"}


def get(url, tries=4, pause=1.0, headers=(), timeout=90):
    for k in range(tries):
        time.sleep(pause + k * (15 if "wikipedia.org/w/" in url else 5))
        cmd = ["curl", "-sS", "-L", "-m", str(timeout), "-A", UA]
        for hd in headers:
            cmd += ["-H", hd]
        r = subprocess.run(cmd + [url], capture_output=True)
        if r.returncode == 0 and r.stdout and not r.stdout.startswith(b"You are making too many") \
                and b"Too Many Requests" not in r.stdout[:300]:
            return r.stdout
    return b""


def jget(url, **kw):
    try:
        return json.loads(get(url, **kw) or b"{}")
    except ValueError:
        return {}


def words(s):
    s = re.sub(r"\(.*?\)", " ", s.lower()).replace("é", "e")
    return [w for w in re.findall(r"[a-z0-9']+", s) if w not in STOP]


def overlap(want, got):
    a = set(words(want))
    if not a:
        return 0.0
    b = set(words(got))
    return len(a & b) / len(a)


def save(data, path, aspect=0.0):
    """aspect > 0: crop (or letterbox on a blurred copy when far off) to that
    width/height, H tall. aspect == 0: keep the whole picture, H on its long side."""
    im = Image.open(io.BytesIO(data))
    if im.mode in ("RGBA", "LA", "P"):
        im = im.convert("RGBA")
        bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
        bg.alpha_composite(im)
        im = bg
    im = im.convert("RGB")
    w, h = im.size
    if aspect <= 0:
        s = H / max(w, h)
        im = im.resize((max(1, int(w * s)), max(1, int(h * s))), Image.LANCZOS)
    else:
        ar = w / h
        tw, th = max(1, int(round(H * aspect))), H
        if max(ar, aspect) / min(ar, aspect) <= 1.22:
            if ar > aspect:
                nw = int(h * aspect)
                im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
            else:
                nh = int(w / aspect)
                im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
            im = im.resize((tw, th), Image.LANCZOS)
        else:
            bg = im.resize((tw, th), Image.LANCZOS).filter(ImageFilter.GaussianBlur(10))
            s = min(tw / w, th / h)
            fg = im.resize((max(1, int(w * s)), max(1, int(h * s))), Image.LANCZOS)
            bg.paste(fg, ((tw - fg.size[0]) // 2, (th - fg.size[1]) // 2))
            im = bg
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, quality=86, optimize=True)


def store(world, iid, kind, url, aspect, force, **kw):
    rel = "assets/temp_test/%s/%s_%s.jpg" % (world, iid, kind)
    full = os.path.join(ROOT, rel)
    data = get(url, **kw)
    if data and len(data) < 400 and data.strip().endswith(b".png") and "/Named_Boxarts/" in url:
        # A git symlink in libretro-thumbnails: the file holds the real file's name.
        url = url.rsplit("/", 1)[0] + "/" + urllib.parse.quote(data.decode("utf-8", "replace").strip().split("/")[-1])
        data = get(url, **kw)
    if not data:
        return False
    try:
        save(data, full, aspect)
    except Exception as e:  # bad picture: skip it
        print("  skip", iid, e)
        return False
    fwa.log(rel, url)
    return True


def have(world, iid, kind):
    return any(os.path.exists(os.path.join(ROOT, "assets/temp_test/%s/%s_%s.%s" % (world, iid, kind, e))) for e in ("jpg", "png"))


def cutout(path):
    """Product photo on a plain light backdrop -> PNG with that backdrop clear,
    so the box painter can stand it on its own studio backdrop."""
    from PIL import ImageDraw
    im = Image.open(path).convert("RGB")
    w, h = im.size
    key = (255, 0, 255)
    work = im.copy()
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1), (w // 2, 0), (w // 2, h - 1), (0, h // 2), (w - 1, h // 2)):
        if sum(work.getpixel((x, y))) >= 3 * 222 and work.getpixel((x, y)) != key:
            ImageDraw.floodfill(work, (x, y), key, thresh=34)
    px = work.load()
    a = Image.new("L", (w, h), 255)
    ap = a.load()
    clear = 0
    for yy in range(h):
        for xx in range(w):
            if px[xx, yy] == key:
                ap[xx, yy] = 0
                clear += 1
    if clear < w * h * 0.08:
        return path  # no clean backdrop: keep the photo as it is
    a = a.filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.6))
    out = im.convert("RGBA")
    out.putalpha(a)
    png = path[:-4] + ".png"
    out.save(png, optimize=True)
    os.remove(path)
    return png


# ------------------------------------------------------------------ games

def wiki_search(q, n=5):
    """Search hits in order, each with its lead image: [(title, thumb url, file)]."""
    j = jget("https://en.wikipedia.org/w/api.php?" + urllib.parse.urlencode({
        "action": "query", "format": "json", "generator": "search", "gsrsearch": q, "gsrlimit": n,
        "prop": "pageimages", "piprop": "thumbnail|name", "pithumbsize": 500, "pilicense": "any"}), pause=3.0)
    pages = sorted(j.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 99))
    return [(p["title"], p.get("thumbnail", {}).get("source", ""), p.get("pageimage", "")) for p in pages]


def game_query(title):
    t = re.sub(r"\((Japan|Gold|Gray|Grey|NES|SNES|N64|PS1)\)", "", title)
    t = re.sub(r"\b(Gray|Gold|Grey) Cartridge\b", "", t)
    return re.sub(r"\s+", " ", t).strip()


# Real box scans for every console: github.com/libretro-thumbnails (No-Intro names).
LIBRETRO = {"FES": ["Nintendo_-_Nintendo_Entertainment_System"], "SFES": ["Nintendo_-_Super_Nintendo_Entertainment_System"],
            "F64": ["Nintendo_-_Nintendo_64"], "PBOY": ["Nintendo_-_Game_Boy", "Nintendo_-_Game_Boy_Color"],
            "PBA": ["Nintendo_-_Game_Boy_Advance"], "PST": ["Sony_-_PlayStation"], "PST2": ["Sony_-_PlayStation_2"],
            "XBX": ["Microsoft_-_Xbox"], "FCUBE": ["Nintendo_-_GameCube"], "DC": ["Sega_-_Dreamcast"],
            "GEN": ["Sega_-_Mega_Drive_-_Genesis"], "SAT": ["Sega_-_Saturn"], "NEO": ["SNK_-_Neo_Geo", "SNK_-_Neo_Geo_CD"],
            "A26": ["Atari_-_2600"], "PSPK": ["Sony_-_PlayStation_Portable"], "DUO": ["Nintendo_-_Nintendo_DS"]}
LR_CACHE = os.path.join(os.environ.get("TMPDIR", "/tmp"), "libretro_lists")
BAD_TAGS = ("beta", "proto", "sample", "demo", "switch online", "virtual console", "kiosk", "taikenban", "pirate", "hack",
            "unl", "aftermarket", "competition cart", "classic mini", "ique", "debug", "(gamecube)", "(wii", "(e-reader")


def lr_names(repo):
    """Every box art file name in a libretro-thumbnails repo (cached)."""
    os.makedirs(LR_CACHE, exist_ok=True)
    f = os.path.join(LR_CACHE, repo + ".txt")
    if not os.path.exists(f):
        d = os.path.join(LR_CACHE, repo)
        if not os.path.exists(d):
            subprocess.run(["git", "clone", "-q", "--filter=blob:none", "--no-checkout", "--depth", "1",
                            "https://github.com/libretro-thumbnails/%s.git" % repo, d])
        r = subprocess.run(["git", "-C", d, "ls-tree", "-r", "--name-only", "HEAD"], capture_output=True, text=True)
        open(f, "w").write("\n".join(n[len("Named_Boxarts/"):] for n in r.stdout.splitlines() if n.startswith("Named_Boxarts/")))
    return [n for n in open(f).read().splitlines() if n.endswith(".png")]


def nkey(s):
    """No-Intro name or list title -> comparable key ("&" and ":" are "_" in
    libretro file names, so both sides drop them along with "and")."""
    base = re.sub(r"\s*\(.*$", "", s).replace("&amp;", "&")
    m = re.match(r"^(.*?), (The|A|An)( - .*|: .*)?$", base)
    if m:
        base = m.group(2) + " " + m.group(1) + (m.group(3) or "")
    base = base.lower().replace("é", "e").replace("&", " ").replace("_", " ")
    base = re.sub(r"\b(and|version)\b", " ", base)
    base = re.sub(r"^\s*the\b", "", base)
    base = re.sub(r"\bii\b", "2", re.sub(r"\biii\b", "3", base))
    return re.sub(r"[^a-z0-9]+", "", base)


_lr_keys = {}


def lr_keys(repo):
    """[(name, lowercase tags, key, head key)] per repo, computed once."""
    if repo not in _lr_keys:
        _lr_keys[repo] = [(n, n[:-4].lower(), nkey(n), nkey(re.split(r" - |: ", n)[0]), nkey(re.sub(r" - ", " ", n)))
                          for n in lr_names(repo) if not any(b in n.lower() for b in BAD_TAGS)]
    return _lr_keys[repo]


def lr_pick(title, plat):
    want_jp = "(Japan)" in title
    key = nkey(game_query(title.replace("(Japan)", "")))
    best = None
    for repo in LIBRETRO.get(plat, []):
        for n, tags, k, head, joined in lr_keys(repo):
            score = 0
            if k == key:
                score = 100
            elif head == key or joined == key:
                score = 90
            elif len(key) > 8 and (k.startswith(key) or key.startswith(k)) and min(len(k), len(key)) / max(len(k), len(key)) > 0.8 \
                    and re.findall(r"\d+", k) == re.findall(r"\d+", key):
                score = 60
            if not score:
                continue
            if "(usa" in tags:
                score += 0 if want_jp else 8
            elif "(world" in tags:
                score += 6
            elif "(japan" in tags:
                score += 9 if want_jp else 2
            elif "(europe" in tags:
                score += 4
            if "(rev" in tags:
                score -= 1
            if best is None or score > best[0]:
                best = (score, repo, n)
    if best is None:
        import difflib
        allk = {}
        for repo in LIBRETRO.get(plat, []):
            for n, _t, k, _h, _j in lr_keys(repo):
                allk.setdefault(k, (0, repo, n))
        m = difflib.get_close_matches(key, list(allk.keys()), n=1, cutoff=0.88)
        if m and re.findall(r"\d+", m[0]) == re.findall(r"\d+", key):
            best = allk[m[0]]
    if best is None:
        return "", ""
    url = "https://raw.githubusercontent.com/libretro-thumbnails/%s/master/Named_Boxarts/%s" % (best[1], urllib.parse.quote(best[2]))
    return url, best[2]


# Hardware list name (prefix) -> Wikipedia article whose lead photo shows it.
# Colour / special editions are left out: their 3D render is tinted right.
HW_ARTICLES = [
    ("Nintendo PlayStation", "Super NES CD-ROM"), ("Sega Neptune", "Sega Neptune"), ("Atari Panther", "Atari Panther"),
    ("Nintendo 64DD", "64DD"), ("Famicom Disk System", "Family Computer Disk System"), ("Satellaview Modem", "Satellaview"),
    ("Satellaview", "Satellaview"), ("PlayStation Net Yaroze", "Net Yaroze"), ("Pioneer LaserActive", "LaserActive"),
    ("3DO FZ-1", "3DO Interactive Multiplayer"), ("NES Control Deck", "Nintendo Entertainment System"),
    ("Famicom (HVC-001)", "Family Computer"), ("Sharp Twin Famicom", "Twin Famicom"), ("Famicom 3D System", "Famicom 3D System"),
    ("Family BASIC", "Family BASIC"), ("R.O.B.", "R.O.B."), ("NES Zapper (Gray)", "NES Zapper"), ("Power Pad", "Power Pad"),
    ("Power Glove", "Power Glove"), ("NES Four Score", "NES Four Score"), ("NES Max", "NES Max"), ("NES Advantage", "NES Advantage"),
    ("Game Genie", "Game Genie"), ("U-Force", "U-Force"), ("Roll 'N Rocker", "Roll 'n Rocker"),
    ("Miracle Piano", "Miracle Piano Teaching System"), ("PlayChoice-10", "PlayChoice-10"), ("Vs. System", "Nintendo Vs. System"),
    ("SNES Model 1", "Super Nintendo Entertainment System"), ("Super Famicom (SHVC-001)", "Super Famicom"),
    ("SNES Mouse", "Super NES Mouse"), ("SNES Super Scope", "Super Scope"), ("Super Game Boy", "Super Game Boy"),
    ("SNES Justifier", "Konami Justifier"), ("Sufami Turbo", "Sufami Turbo"),
    ("X-Band", "XBAND"), ("Nintendo Power Flash", "Nintendo Power (cartridge)"), ("Nintendo 64 Console", "Nintendo 64"),
    ("Nintendo 64 Expansion Pak", "Expansion Pak"), ("Nintendo 64 Rumble Pak", "Rumble Pak"), ("Nintendo 64 Transfer Pak", "Transfer Pak"),
    ("Nintendo 64 Controller Pak", "Controller Pak"), ("Nintendo 64 Mouse", "Nintendo 64 Mouse"), ("Nintendo 64 GameShark", "GameShark"),
    ("Nintendo 64 Voice Recognition", "Voice Recognition Unit"), ("GameCube Indigo", "GameCube"), ("GameCube Panasonic Q", "Panasonic Q"),
    ("GameCube Game Boy Player", "Game Boy Player"), ("GameCube WaveBird", "WaveBird Wireless Controller"),
    ("GameCube DK Bongos", "DK Bongos"), ("GameCube Broadband Adapter", "GameCube Broadband Adapter"), ("GameCube Freeloader", "Freeloader (video game accessory)"),
    ("GameCube Action Replay", "Action Replay"), ("Game Boy (DMG-01)", "Game Boy"), ("Game Boy Pocket", "Game Boy Pocket"),
    ("Game Boy Light", "Game Boy Light"), ("Game Boy Camera", "Game Boy Camera"), ("Game Boy Printer", "Game Boy Printer"),
    ("Game Boy Color Atomic Purple", "Game Boy Color"), ("Game Boy Advance Glacier", "Game Boy Advance"),
    ("Game Boy Advance SP AGS-001", "Game Boy Advance SP"), ("Game Boy Advance Micro", "Game Boy Micro"),
    ("Game Boy Advance Wireless", "Game Boy Advance Wireless Adapter"), ("Game Boy Advance e-Reader", "Nintendo e-Reader"),
    ("PlayStation SCPH-1001", "PlayStation (console)"), ("PS one", "PS one"), ("PocketStation", "PocketStation"),
    ("PlayStation Dual Analog", "Dual Analog Controller"), ("PlayStation DualShock", "DualShock"), ("PlayStation Mouse", "PlayStation Mouse"),
    ("PlayStation Link Cable", "PlayStation Link Cable"), ("PlayStation Memory Card", "PlayStation Memory Card"), ("PlayStation NegCon", "NeGcon"),
    ("PlayStation GunCon", "GunCon"), ("PlayStation JogCon", "JogCon"), ("PlayStation Analog Joystick", "PlayStation Analog Joystick"),
    ("PS2 SCPH-30001", "PlayStation 2"), ("PS2 Slimline", "PlayStation 2"), ("PS2 Network Adapter", "PlayStation 2 Network Adapter"),
    ("PS2 Hard Disk", "PlayStation 2 HDD"), ("PS2 EyeToy", "EyeToy"), ("PS2 Guitar Hero", "Guitar Hero (video game)"),
    ("PSP-1000 Piano Black", "PlayStation Portable"), ("Xbox Original Console", "Xbox (console)"), ("Xbox Duke", "Xbox controller"),
    ("Xbox Steel Battalion", "Steel Battalion"), ("Xbox Communicator", "Xbox Communicator"), ("Xbox 360 Elite", "Xbox 360"),
    ("Xbox 360 Kinect", "Kinect"), ("Xbox 360 HD DVD", "Xbox 360 HD DVD Player"), ("Dreamcast Console", "Dreamcast"),
    ("Dreamcast VMU", "VMU"), ("Dreamcast Dreameye", "Dreameye"), ("Dreamcast Fishing", "Dreamcast Fishing Controller"),
    ("Sega Genesis Model 1", "Sega Genesis"), ("Sega CD Model 2", "Sega CD"), ("Sega CD", "Sega CD"), ("Sega 32X", "32X"),
    ("Sega Nomad", "Genesis Nomad"), ("Sega Pico", "Sega Pico"), ("Sega Teradrive", "TeraDrive"), ("Sega Multi-Mega", "Sega Multi-Mega"),
    ("JVC X'Eye", "JVC X'Eye"), ("Amstrad Mega PC", "Amstrad Mega PC"), ("Sega Mega-LD", "LaserActive"),
    ("Sega Saturn Skeleton", "Sega Saturn"), ("Atari 2600 Heavy Sixer", "Atari 2600"), ("Atari 2600 Four-Switch", "Atari 2600"),
    ("Atari 2600 Jr.", "Atari 2600 Jr."), ("Neo Geo AES Console", "Neo Geo (system)"), ("Neo Geo CD", "Neo Geo CD"),
    ("Neo Geo MVS", "Neo Geo (system)"), ("Nintendo DS Lite", "Nintendo DS Lite"), ("Sega Dreamcast Hello Kitty", "Dreamcast"),
]


def hw_article(name):
    for pre, art in HW_ARTICLES:
        if name.startswith(pre):
            return art
    return ""


def lead_images(titles):
    """Lead image + file name for many exact article titles (40 per request)."""
    out = {}
    titles = sorted(set(titles))
    for i in range(0, len(titles), 25):
        chunk = titles[i:i + 25]
        j = jget("https://en.wikipedia.org/w/api.php?" + urllib.parse.urlencode({
            "action": "query", "format": "json", "titles": "|".join(chunk), "prop": "pageimages|pageprops",
            "piprop": "thumbnail|name", "pithumbsize": 500, "pilicense": "any", "redirects": 1, "ppprop": "disambiguation"}),
            pause=30.0, tries=10)
        if "query" not in j:
            print("  wiki batch failed", flush=True)
        q = j.get("query", {})
        back = {}
        for n in q.get("normalized", []) + q.get("redirects", []):
            back[n["to"]] = back.get(n["from"], n["from"])
        for pg in q.get("pages", {}).values():
            if "disambiguation" in pg.get("pageprops", {}):
                continue
            t = pg.get("thumbnail", {}).get("source", "")
            if t:
                hit = (pg["title"], t, pg.get("pageimage", ""))
                out[back.get(pg["title"], pg["title"])] = hit
                out[pg["title"]] = hit
    return out


def good_cover(f, is_game):
    f = f.lower()
    if f.endswith(".svg") or "logo" in f and is_game:
        return False
    return True


def fetch_games(force, only):
    import gen_catalog
    _items, _merged, real, _g, _h = gen_catalog.collect()
    todo = []
    for iid, (title, plat, kind) in real.items():
        if only and only not in iid:
            continue
        what = "scan" if kind == "game" else "photo"
        if have("games", iid, what) and not force:
            continue
        todo.append((iid, title, plat, kind, what))
    got = miss = 0
    # 0) Games: the real box scan from libretro-thumbnails.
    rest = []
    for iid, title, plat, kind, what in todo:
        if kind == "game":
            url, nm = lr_pick(title, plat)
            if url and store("games", iid, what, url, BOX.get(plat, 0.75), force, pause=0.05):
                got += 1
                print("box", iid, "<-", nm, flush=True)
                continue
        rest.append((iid, title, plat, kind, what))
    todo = rest
    if "--wiki" not in sys.argv:
        todo = [t for t in todo if t[3] != "game"]
    # 1) Exact Wikipedia article titles, batched: "X (video game)" first, then "X".
    cands = {}
    for iid, title, plat, kind, what in todo:
        n = game_query(title)
        if kind == "game":
            cands[iid] = [n + " (video game)", n + " (%s)" % PLAT_WORDS.get(plat, ""), n]
        else:
            cands[iid] = [hw_article(title)] if hw_article(title) else []
    leads = lead_images([t for c in cands.values() for t in c])
    print("lead images", len(leads), "for", len(todo))
    for iid, title, plat, kind, what in todo:
        is_game = kind == "game"
        name = game_query(title)
        pick = next((leads[t] for t in cands[iid] if t in leads and good_cover(leads[t][2], is_game)), None)
        if pick is None and "--search" in sys.argv:
            # 2) Search with the platform name (slow: Wikipedia rate-limits searches).
            q = "%s %s %s" % (name, PLAT_WORDS.get(plat, ""), "video game" if is_game else "")
            for t, thumb, f in wiki_search(q.strip()):
                if not thumb or not good_cover(f, is_game):
                    continue
                score = overlap(name.split(":")[0] if is_game else name, t)
                if score < (0.6 if is_game else 0.34):
                    continue
                if is_game and re.search(r"\b(series|franchise|character)\b", t.lower()):
                    continue
                pick = (t, thumb, f)
                break
        if pick is None:
            miss += 1
            print("miss", iid, "|", title, flush=True)
            continue
        ok = store("games", iid, what, pick[1], BOX.get(plat, 0.75) if is_game else 0.0, force, pause=0.6)
        if ok and not is_game:
            jpg = os.path.join(ROOT, "assets/temp_test/games/%s_photo.jpg" % iid)
            png = cutout(jpg)
            if png != jpg:
                fwa.log(os.path.relpath(png, ROOT), pick[1])
        got += ok
        print("ok " if ok else "bad", iid, "<-", pick[0], "|", pick[2], flush=True)
    print("games fetched", got, "missed", miss)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_catalog.py")])


# ------------------------------------------------------------------ cards

STRIP = ["Alternate Art", "Alt Art", "Full Art", "1st Edition", "First Edition", "Shadowless", "Holo", "Ghost Rare",
         "Ultimate Rare", "Secret Rare", "Ultra Rare", "Starlight Rare", "Prismatic", "Collector's Rare", "Foil",
         "Borderless", "Serialized", "Showcase", "Extended Art", "Gold Rare", "Promo", "Tournament", "Japanese",
         "Trophy", "Secret", "Rainbow", "Manga Rare", "Special Illustration", "Illustration Rare"]


def clean(name):
    n = name
    for s in STRIP:
        n = re.sub(r"\b%s\b" % re.escape(s), "", n, flags=re.I)
    return re.sub(r"\s+", " ", n).strip(" -")


_scry_sets = None


def scry_set(name):
    global _scry_sets
    if _scry_sets is None:
        j = jget("https://api.scryfall.com/sets", pause=0.2, headers=["Accept: application/json"])
        _scry_sets = [(s["name"], s["code"]) for s in j.get("data", [])]
    want = name.lower().strip()
    alias = {"alpha": "Limited Edition Alpha", "beta": "Limited Edition Beta", "unlimited": "Unlimited Edition",
             "revised": "Revised Edition"}
    want = alias.get(want, name).lower()
    for n, c in _scry_sets:
        if n.lower() == want:
            return c
    best, bc = 0.0, ""
    for n, c in _scry_sets:
        sc = overlap(want, n)
        if sc > best:
            best, bc = sc, c
    return bc if best >= 0.75 else ""


def magic(r):
    name = clean(r["name"])
    hdr = ["Accept: application/json"]
    code = scry_set(r["detail"])
    for q in ([('!"%s" e:%s' % (name, code))] if code else []) + ['!"%s"' % name, name]:
        j = jget("https://api.scryfall.com/cards/search?" + urllib.parse.urlencode(
            {"q": q, "unique": "prints", "order": "released", "dir": "asc"}), pause=0.15, headers=hdr)
        for c in j.get("data", []):
            iu = c.get("image_uris") or (c.get("card_faces") or [{}])[0].get("image_uris") or {}
            if iu.get("large") or iu.get("normal"):
                return iu.get("large") or iu.get("normal"), "%s [%s]" % (c["name"], c.get("set", ""))
    return "", ""


_ptcg_sets = None
_ptcg_cards = {}
PTCG = "https://raw.githubusercontent.com/PokemonTCG/pokemon-tcg-data/master/"
PROMO_SETS = ["basep", "np", "dpp", "hsp", "bwp", "xyp", "smp", "swshp", "svp"]


def ptcg_set(name):
    """Set id from the Pokemon TCG data files (the API itself often fails)."""
    global _ptcg_sets
    if _ptcg_sets is None:
        _ptcg_sets = [(st["name"], st["id"]) for st in json.loads(get(PTCG + "sets/en.json", pause=0.1) or b"[]")]
        print("pokemon sets", len(_ptcg_sets))
    want = {"base set": "base", "ex deoxys": "deoxys", "pokemon 151": "151", "ex holon phantoms": "holon phantoms",
            "wizards black star promo": "wizards black star promos"}.get(name.lower(), name.lower())
    for n, i in _ptcg_sets:
        if n.lower() == want:
            return i
    best, bi = 0.0, ""
    for n, i in _ptcg_sets:
        sc = overlap(want, n)
        if sc > best:
            best, bi = sc, i
    return bi if best >= 0.75 else ""


def ptcg_cards(sid):
    if sid not in _ptcg_cards:
        try:
            _ptcg_cards[sid] = json.loads(get(PTCG + "cards/en/%s.json" % sid, pause=0.1, timeout=90) or b"[]")
        except ValueError:
            _ptcg_cards[sid] = []
    return _ptcg_cards[sid]


def pokemon(r):
    raw = r["name"]
    alt = bool(re.search(r"alternate art|alt art|special illustration", raw, re.I))
    name = clean(raw)
    star = False
    if name.lower().startswith("gold star "):
        name, star = name[10:], True
    crystal = name.lower().startswith("crystal ")
    if crystal:
        name = name[8:]
    sid = ptcg_set(r["detail"])
    for sets in ([sid] if sid else PROMO_SETS):
        pool = []
        for st in sets if isinstance(sets, list) else [sets]:
            pool += ptcg_cards(st)
        cards = [c for c in pool if overlap(name, c["name"]) >= 0.99 and len(words(c["name"])) <= len(words(name)) + 2]
        if star:
            cards = [c for c in cards if "☆" in c["name"] or "★" in c["name"] or "Star" in c.get("rarity", "")] or cards
        if crystal:
            cards = [c for c in cards if "Crystal" in c.get("rarity", "") or "Crystal" in c["name"]] or cards
        exact = [c for c in cards if c["name"].lower() == name.lower()]
        cards = exact or cards
        if not cards:
            continue

        def num(c):
            m = re.match(r"\d+", c.get("number", ""))
            return int(m.group(0)) if m else 0
        cards.sort(key=num, reverse=alt)
        c = cards[0]
        img = c.get("images", {})
        if img.get("large") or img.get("small"):
            return img.get("large") or img.get("small"), "%s [%s %s]" % (c["name"], c["id"], c.get("number", ""))
    return "", ""


def yugioh(r):
    name = clean(r["name"])
    for p in ({"name": name}, {"fname": name}):
        j = jget("https://db.ygoprodeck.com/api/v7/cardinfo.php?" + urllib.parse.urlencode(p), pause=0.2)
        data = j.get("data", [])
        data = [d for d in data if overlap(name, d["name"]) >= 0.99]
        if data:
            d = data[0]
            ims = d.get("card_images", [{}])
            return ims[0].get("image_url", ""), d["name"]
    return "", ""


def fetch_cards(force, only):
    import gen_collectibles as gc
    gc.card_items(gc.parse(gc.CARDS))
    got = miss = 0
    for iid, r in gc.REAL.items():
        if only and only not in iid:
            continue
        if any(w in r["name"] for w in gc.PACK_WORDS):
            continue
        if have("cards", iid, "scan") and not force:
            continue
        fn = {"MAGI": magic, "CRIT": pokemon, "YUGI": yugioh}.get(r["code"])
        if fn is None:
            continue
        url, what = fn(r)
        if not url:
            miss += 1
            print("miss", iid, "|", r["name"], "|", r["detail"], flush=True)
            continue
        pause = 0.15 if "scryfall" in url else 0.5
        ok = store("cards", iid, "scan", url, 0.716, force, pause=pause)
        got += ok
        print("ok " if ok else "bad", iid, "<-", what, flush=True)
    print("cards fetched", got, "missed", miss)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_collectibles.py")])


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    force = "--force" in sys.argv
    only = ""
    if "--only" in sys.argv:
        only = sys.argv[sys.argv.index("--only") + 1]
        args = [a for a in args if a != only]
    what = args[0] if args else "games"
    if what in ("games", "all"):
        fetch_games(force, only)
    if what in ("cards", "all"):
        fetch_cards(force, only)


if __name__ == "__main__":
    main()
