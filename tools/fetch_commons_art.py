#!/usr/bin/env python3
"""Real photos from Wikimedia Commons for consoles, accessories and coins (test-only).

    python3 tools/fetch_commons_art.py hw [find] [save] [sheet OUT.png] [--force] [--only ID_PART]
    python3 tools/fetch_commons_art.py coins [find] [save] [sheet OUT.png] [--force] [--only ID_PART]

hw     every console / accessory tools/gen_catalog.py builds that has no photo
       yet (fetch_retro_art.py only knows a Wikipedia article for the plain
       models). Searches Commons (file namespace, bitmaps) with the item name,
       scores each hit on its file name (every key word of the name, colour
       words above all; Evan-Amos's white-backdrop product shots get a bonus),
       cuts the white backdrop out -> assets/temp_test/games/<id>_photo.png.
coins  every coin tools/gen_collectibles.py builds. Searches Commons for the
       coin (year + type), prefers the National Numismatic Collection shots
       ("NNC-US-1933-G$20-...": obverse and reverse side by side). A wide
       picture is split into its two faces, each face is cropped to its disc
       -> assets/temp_test/coins/<id>_obv.jpg (+ <id>_rev.jpg).

find   (default) searches and stores the candidates in .cache/commons_<mode>.json
save   downloads the best candidate of each item (PICKS pins one by hand)
sheet  a contact sheet of what was saved, to check by eye

Every file is logged in assets/temp_test/MANIFEST.txt and assets/sources.txt.
Runs the generator again at the end so the catalog picks the pictures up.
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
import fetch_retro_art as fra  # noqa: E402  (get, cutout)

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, ".cache")
API = "https://commons.wikimedia.org/w/api.php"
BAD = ("logo", "screenshot", "diagram", "motherboard", "pcb", "mainboard", "inside", "internal", "disassembled", "teardown",
       "opened", "chip", "schematic", "map", "chart", "label", "manual", "magazine", "advert", "ad ", "poster", "sign", "store",
       "museum", "exhibit", "display", "collection", "booth", "e3", "convention", "gamescom", "pile", "lot", "games", "shelf",
       "close-up", "closeup", "detail", "port", "ports", "connector", "plug", "underside", "bottom", "back", "rear", "sticker",
       "stamp", "banknote", "medal", "token")

# File-name word aliases: one key word of an item name -> words a file may use instead.
ALIAS = {"nintendo 64": ["n64", "nintendo64"], "game boy color": ["gbc", "gameboy color", "gameboycolor", "game boy colour"],
         "game boy advance sp": ["gba sp", "gbasp", "gameboy advance sp", "agb sp"],
         "game boy advance": ["gba", "gameboy advance", "gameboyadvance"], "game boy micro": ["gb micro", "gameboy micro"],
         "game boy pocket": ["gb pocket", "gameboy pocket", "gbp"], "game boy": ["gameboy", "dmg"],
         "playstation 2": ["ps2", "playstation2"], "ps2": ["playstation 2", "playstation2", "ps2"], "playstation": ["ps1", "psx", "psone"],
         "ps one": ["psone", "ps one", "ps1"], "gamecube": ["game cube", "gcn", "gc"], "dreamcast": ["dc"], "xbox 360": ["x360", "xbox360"],
         "sega genesis": ["genesis", "mega drive", "megadrive"], "super famicom": ["sfc", "superfamicom"], "famicom": ["fc"],
         "snes": ["super nintendo", "super nes", "snes"], "nes": ["nintendo entertainment system", "nes"],
         "nintendo ds lite": ["ds lite", "dslite", "nds lite"], "psp": ["playstation portable"], "atari 2600": ["2600", "vcs"],
         "neo geo": ["neogeo", "neo-geo"], "dualshock": ["dual shock"],
         # Edition colour names -> the plain colour a file name uses.
         "dandelion": ["yellow"], "grape": ["purple"], "kiwi": ["green", "lime"], "berry": ["red", "magenta", "pink"],
         "teal": ["turquoise", "blue"], "fuchsia": ["pink", "magenta"], "indigo": ["purple"], "arctic": ["white"],
         "jungle": ["green"], "fire": ["orange"], "ice": ["blue"], "smoke": ["black", "grey", "gray"], "watermelon": ["red"],
         "spice": ["orange"], "onyx": ["black"], "platinum": ["silver"], "pikachu": ["pokemon"], "gray": ["grey"]}
STOP = {"the", "of", "a", "an", "and", "edition", "with", "for", "console", "model", "set", "japan", "bundle", "limited", "series",
        "system", "unit", "&", "s", "in", "de"}
WHOLE = ["nintendo 64", "game boy color", "game boy advance sp", "game boy advance", "game boy micro", "game boy pocket", "game boy",
         "playstation 2", "ps one", "xbox 360", "sega genesis", "super famicom", "nintendo ds lite", "atari 2600", "neo geo"]
COLOURS = {"berry", "dandelion", "grape", "kiwi", "teal", "fuchsia", "indigo", "arctic", "orange", "black", "pearl", "pink", "onyx",
           "flame", "tribal", "jungle", "green", "fire", "ice", "blue", "purple", "watermelon", "red", "smoke", "gold", "silver",
           "white", "clear", "crystal", "platinum", "spice", "ceramic", "satin", "ocean", "sakura", "lavender", "felicia", "lime",
           "pikachu", "zelda", "halo", "skeleton", "atomic", "hello", "kitty", "light", "gray", "grey"}

# id -> Commons file (Evan-Amos's product photos, checked by eye), or
# [file, "tint"] = that photo of the plain model recoloured to the edition.
# Items left out keep their painted art / rendered model.
T = "tint"
PICKS = {
    "fes_fes_deluxe_set_with_r_o_b_b": "NES-ROB.jpg", "fes_fes_action_set": "NES-Console-Set.jpg",
    "fes_fes_top_loader_fes_101": "NES-101-Console-Set.jpg", "fes_funicom_hvc_001": "Nintendo-Famicom-Console-Set-FL.jpg",
    "fes_funicom_av": "Nintendo-AV-Famicom-Console-FL.jpg", "fes_sharpe_twin_funicom": "Sharp-Twin-Famicom-Console.jpg",
    "fes_funicom_network_system": "Nintendo-Famicom-Modem-Network-System-01.jpg",
    "fes_fes_zappr_orange": "Nintendo-Entertainment-System-NES-Zapper-Orange-R.jpg", "fes_fes_satellyte": "NES-Satellite.jpg",
    "fes_fes_max": "NES-MAX-Controller-FL.jpg",
    "sfes_super_fes_model_2_sns_101": "Nintendo-Super-NES-Console-101-FL.jpg",
    "sfes_super_funicom_shvc_001": "Nintendo-Super-Famicom-Console-FL.jpg", "sfes_super_fes_plumber_paint_bund": "SNES-Mouse-and-Pad.jpg",
    "f64_console": "Nintendo-64-Console-FL.jpg", "f64_funtendo_64_funtastick_fire": "N64-Console-Orange.jpg",
    "f64_jungle": ["Nintendo-64-Console-FL.jpg", T], "f64_funtendo_64_funtastick_ice_b": ["Nintendo-64-Console-FL.jpg", T],
    "f64_funtendo_64_funtastick_grape": ["Nintendo-64-Console-FL.jpg", T], "f64_funtendo_64_funtastick_water": ["Nintendo-64-Console-FL.jpg", T],
    "f64_funtendo_64_funtastick_smoke": ["Nintendo-64-Console-FL.jpg", T],
    "f64_funtendo_64_controller_pakk": "Nintendo-64-Controller-Pak.jpg", "f64_funtendo_64_gamesnark": "GameShark-Pro-N64.jpg",
    "f64_funtendo_64_gold_controller": ["N64-Controller-Gray.jpg", T], "f64_funtendo_64_atomic_purple_co": ["N64-Controller-Gray.jpg", T],
    "fcube_funcube_jet_black": ["Nintendo-GameCube-Console-FL.jpg", T], "fcube_funcube_platinum": "GameCube-Silver-Optional-Set.jpg",
    "fcube_funcube_spice_orange": ["Nintendo-GameCube-Console-FL.jpg", T], "fcube_funcube_pocketboy_player_sta": "GameCube-Game-Boy-Player.jpg",
    "fcube_funcube_broadbland_adapter": "Nintendo-GameCube-Broadband-Adapter-01.jpg", "fcube_funcube_modem_adapter": "Nintendo-GameCube-Modem-Adapter-01.jpg",
    "pboy_pocketboy_pocket": "Game-Boy-Pocket-FL.jpg", "pboy_gold": "Game-Boy-Light-FL.jpg",
    "pboy_pocketboy_pocket_clear_editi": ["Game-Boy-Pocket-FL.jpg", T],
    "pboy_pocketboy_color_dandelion": "Game-Boy-Color-Yellow.jpg", "pboy_pocketboy_color_grape": "Game-Boy-Color-Purple.jpg",
    "pboy_pocketboy_color_berry": ["Game-Boy-Color-Yellow.jpg", T], "pboy_pocketboy_color_kiwi": ["Game-Boy-Color-Yellow.jpg", T],
    "pboy_pocketboy_color_teal": ["Game-Boy-Color-Yellow.jpg", T],
    "pba_pocketboy_advance_fuchsia": "Nintendo-Game-Boy-Advance-Pink-FL.jpg", "pba_pocketboy_advance_arctic": "Nintendo-Game-Boy-Advance-White-FL.jpg",
    "pba_pocketboy_advance_black": "Nintendo-Game-Boy-Advance-Black-FL.jpg",
    "pba_pocketboy_advance_indigo": ["Nintendo-Game-Boy-Advance-White-FL.jpg", T], "pba_pocketboy_advance_orange": ["Nintendo-Game-Boy-Advance-White-FL.jpg", T],
    "pba_pocketboy_advance_sp_ags_101": "Game-Boy-Advance-SP-Mk2.png",
    "pba_pocketboy_advance_sp_pearl_p": ["Game-Boy-Advance-SP-Mk1-Blue.jpg", T], "pba_pocketboy_advance_sp_onyx": ["Game-Boy-Advance-SP-Mk1-Blue.jpg", T],
    "pba_pocketboy_advance_sp_flame": ["Game-Boy-Advance-SP-Mk1-Blue.jpg", T], "pba_pocketboy_advance_sp_tribal": ["Game-Boy-Advance-SP-Mk1-Blue.jpg", T],
    "pst_playstatia_scph_1000_japan_l": "PlayStation-SCPH-1000-with-Controller.jpg", "pst_console": "PSX-Console-wController.jpg",
    "pst_playstatia_scph_5501": "Sony-PlayStation-5501-Console-FL.jpg", "pst_playstatia_scph_7501": "Sony-PlayStation-5501-Console-FR.jpg",
    "pst_pst_one": "PSone-Console-Set-NoLCD.jpg", "pst_pst_one_lcd_screen": "Sony-PSone-Console-wScreen-Open-FL.jpg",
    "pst_dualpad": "PSX-DualShock-Controller.jpg", "pst_playstatia_multitapp": "PlayStation-Multitap-Adaptor.jpg",
    "pst_memcard": "PSX-Memory-Card.jpg", "pst_playstatia_gunkon_namcoo": "Namco-GunCon-PS1.jpg", "pst_playstatia_g_kon_45_namcoo": "Namco-GunCon-PS1.jpg",
    "pst2_pst2_scph_10000_japan_launch": "Sony-PlayStation-2-30001-Console-FL.jpg",
    "pst2_pst2_ceramic_white_japan": ["Sony-PlayStation-2-30001-Console-FL.jpg", T], "pst2_pst2_satin_silver": ["Sony-PlayStation-2-30001-Console-FL.jpg", T],
    "pst2_pst2_ocean_blue_japan": ["Sony-PlayStation-2-30001-Console-FL.jpg", T], "pst2_pst2_sakura_pink_japan": ["Sony-PlayStation-2-30001-Console-FL.jpg", T],
    "pst2_pst2_slimline_pink": ["PS2-slim-console.jpg", T], "pst2_pst2_network_adapter": "Sony-PlayStation-2-Network-Adaptor-Front.jpg",
    "pst2_pst2_hard_disk_drive": "Sony-PlayStation-2-Hard-Drive-40GB.jpg", "pst2_pst2_multitapp": "Sony-PlayStation-2-Multitap.jpg",
    "pst2_pst2_dvd_remote": "PS2-DVD-Remote.jpg", "pst2_pst2_vertical_stand": "PS2-Fat-Console-Vert.jpg",
    "pspk_pspocket_1000_ceramic_white": ["PSP-1000.png", T], "pspk_pspocket_1000_ice_silver": ["PSP-1000.png", T],
    "pspk_pspocket_1000_felicia_blue": ["PSP-1000.png", T], "pspk_pspocket_1000_lavender_purpl": ["PSP-1000.png", T],
    "xbx_xbux_crystal_edition": ["Xbox-Console-FL.jpg", T], "xbx_xbux_lime_green": ["Xbox-Console-FL.jpg", T],
    "xbx_xbux_developer_kit": "Xbox-Debug-Kit.jpg", "xbx_xbux_controller_s": "Xbox-Controller-S-FR.jpg",
    "xbx_xbux_crystal_controller": ["Xbox-Controller-S-FR.jpg", T], "xbx_xbux_dvd_playback_kit": "Xbox-Remote-wReceiver.jpg",
    "xbx_xbux_361_elite": "Microsoft-Xbox-360-Elite-Console-FL.jpg", "xbx_xbux_361_kinnect": "Xbox-360-Kinect-Standalone.png",
    "dc_console": "Sega-Dreamcast-Console-FL.jpg", "dc_saga_dreamcaster_saga_sports": "Sega-Dreamcast-Sports-Black-Console.jpg",
    "dc_dreamcaster_light_gun": "Sega-Dreamcast-Lightgun-FL.jpg", "dc_dreamcaster_arcade_stick": "Sega-Dreamcast-Arcade-Stick.jpg",
    "dc_dreamcaster_keyboard": "Sega-Dreamcast-Keyboard.jpg", "dc_dreamcaster_mouse": "Sega-Dreamcast-Mouse-BR.jpg",
    "dc_dreamcaster_broadbland_adapt": "Sega-Dreamcast-Broadband-Adapter-BL.jpg", "dc_dreamcaster_modem": "Sega-Dreamcast-Modem-Dialup-BL.jpg",
    "dc_dreamcaster_jump_pack": "Dreamcast-Jump-Pack.jpg", "dc_dreamcaster_microphone": "Dreamcast-Microphone.jpg",
    "dc_dreamcaster_vga_box": "Sega-Dreamcast-VGA-Kuro-Box.jpg",
    "gen_saga_genesys_model_2": "Sega-Genesis-Mod2-Set.jpg", "gen_saga_genesys_model_3": "Sega-Genesis-Mod3-Set.jpg",
    "a26_ataro_2600_light_sixxer": "Atari-2600-Light-Sixer-FL.jpg", "a26_ataro_2600_vadur": "Atari-2600-Vader-FL.jpg",
    "a26_ataro_2600_jr": "Atari-2600-Jr-FL.jpg", "a26_ataro_2600_seers_video_arcad": "Atari-2600-Video-Arcade-II-FL.jpg",
    "neo_neon_geo_aes_controller": "Neo-Geo-CD-Controller-FL.jpg", "neo_neon_geo_aes_arcade_stick": "Neo-Geo-AES-Controller-FL.jpg",
    "neo_neon_geo_aes_memory_card": "Neo-Geo-Memory-Card.jpg", "neo_neon_geo_cd_front_loader": "Neo-Geo-CD-FrontLoader-wController-FL.jpg",
}


def api(params, pause=0.4):
    params = dict(params, format="json")
    return fra.jget(API + "?" + urllib.parse.urlencode(params), pause=pause, headers=["Accept: application/json"])


_searched = {}


def search(q, n=30):
    """[(title, thumb url, w, h, user, mime)] of bitmap files matching q (cached)."""
    if (q, n) in _searched:
        return _searched[(q, n)]
    for k in range(4):
        j = api({"action": "query", "generator": "search", "gsrnamespace": 6, "gsrlimit": n, "gsrsearch": q + " filetype:bitmap",
             "prop": "imageinfo", "iiprop": "url|size|user|mime", "iiurlwidth": 640}, pause=0.4 + k * 5)
        if "query" in j or "batchcomplete" in j:
            break
    out = []
    for p in sorted(j.get("query", {}).get("pages", {}).values(), key=lambda p: p.get("index", 99)):
        ii = (p.get("imageinfo") or [{}])[0]
        if not ii.get("thumburl") or ii.get("mime", "") not in ("image/jpeg", "image/png", "image/webp"):
            continue
        out.append((p["title"], ii["thumburl"], ii.get("width", 0), ii.get("height", 0), ii.get("user", ""), ii.get("mime", "")))
    _searched[(q, n)] = out
    return out


def norm(s):
    s = s.lower().replace("é", "e").replace("_", " ").replace("-", " ")
    return re.sub(r"[^a-z0-9$ ]+", " ", s)


def toks(s):
    return [w for w in norm(s).split() if w]


def has(fname, phrase):
    """Does the file name hold the phrase (or one of its aliases)?"""
    f = " " + " ".join(toks(fname)) + " "
    glued = f.replace(" ", "")
    for p in [phrase] + ALIAS.get(phrase, []):
        p2 = " ".join(toks(p))
        if " " + p2 + " " in f or (len(p2) > 5 and p2.replace(" ", "") in glued):
            return True
    return False


def key_parts(name):
    """Item name -> the phrases a file name must show (platform first)."""
    n = re.sub(r"\(.*?\)", " ", name)
    n = norm(n)
    parts = []
    for w in WHOLE:
        if (" " + w + " ") in (" " + n + " "):
            parts.append(w)
            n = (" " + n + " ").replace(" " + w + " ", " ")
            break
    parts += [w for w in n.split() if w not in STOP and len(w) > 1]
    return parts


def hw_score(name, hit):
    title, _u, w, h, user, _m = hit
    t = title[5:].rsplit(".", 1)[0]
    low = " " + " ".join(toks(t)) + " "
    if any((" " + b + " ") in low for b in BAD) and not any((" " + b + " ") in (" " + norm(name) + " ") for b in BAD):
        return -99
    parts = key_parts(name)
    if not parts:
        return -99
    s = 0
    miss = 0
    for k, p in enumerate(parts):
        if has(t, p):
            s += 6 if k == 0 else (5 if p in COLOURS else 3)
        else:
            miss += 1
            s -= 7 if (p in COLOURS or k == 0) else 3
    # Colours the item does not have = a different edition.
    for c in COLOURS:
        if (" " + c + " ") in low and c not in parts and not any(c in p or c in ALIAS.get(p, []) for p in parts):
            s -= 4
    if user == "Evan-Amos":
        s += 4
    if min(w, h) < 300:
        s -= 3
    return s


def hw_queries(name):
    n = re.sub(r"\(.*?\)", " ", name)
    n = re.sub(r"\s+", " ", n).strip()
    qs = [n]
    short = n.replace("Nintendo 64 Funtastic", "N64").replace("Nintendo 64", "N64").replace("Game Boy Advance", "GBA")
    short = short.replace("Game Boy Color", "Game Boy Color").replace("PlayStation", "PlayStation")
    if short != n:
        qs.append(short)
    if "Funtastic" in n:
        qs.append(n.replace(" Funtastic", ""))
    parts = key_parts(name)
    if parts and parts[0] in WHOLE:
        base = " ".join(w.capitalize() for w in parts[0].split())
        qs.append(base)
        for p in parts[1:]:
            qs.append(base + " " + p)
    return qs


# ------------------------------------------------------------------ bulk index

def original(url):
    """Thumbnail url -> the full file (thumbnails get throttled from here)."""
    m = re.match(r"(.*)/thumb/(\w/\w\w/[^/]+)/\d+px-[^/]+$", url.split("?")[0])
    return "%s/%s" % (m.group(1), m.group(2)) if m else url


def fetch_img(url, pause=20.0, tries=7):
    """Picture bytes, waiting out Wikimedia's throttle pages (429 / HTML):
    upload.wikimedia.org allows only a slow trickle from cloud machines."""
    for k in range(tries):
        time.sleep(pause + (2 ** k) * 30 * (k > 0))
        r = subprocess.run(["curl", "-sS", "-L", "-m", "180", "-A", fra.UA, url if k % 2 else original(url)], capture_output=True)
        b = r.stdout
        if b[:3] == b"\xff\xd8\xff" or b[:8] == b"\x89PNG\r\n\x1a\n" or b[:4] == b"RIFF":
            return b
    return b""


def thumb(url, width=500):
    """Full Commons file url -> its thumbnail url."""
    url = url.split("?")[0]
    m = re.match(r"(https://upload\.wikimedia\.org/wikipedia/commons)/(\w/\w\w)/(.+)$", url)
    if not m:
        return url
    name = m.group(3)
    return "%s/thumb/%s/%s/%dpx-%s" % (m.group(1), m.group(2), name, width, name)


def index(name, params):
    """Every file of a big Commons listing (500 per request, cached): the
    search API is rate-limited to about one call in 30 s from here, a listing
    is a handful of calls. [(title, thumb url, w, h, user, mime)]"""
    f = os.path.join(CACHE, "commons_index_%s.json" % name)
    if os.path.exists(f):
        return [tuple(x[:1] + [thumb(x[1].split("?")[0].replace("/thumb/", "/"))] + x[2:]) for x in json.load(open(f))]
    part = f + ".part"
    out, cont = [], {}
    if os.path.exists(part):
        saved = json.load(open(part))
        out, cont = [tuple(x) for x in saved["out"]], saved["cont"]
    while True:
        for k in range(8):
            j = api(dict(params, action="query", list="allimages", ailimit=500, aiprop="url|size|user|mime", **cont),
                    pause=1.0 + k * 20)
            if "query" in j:
                break
        else:
            raise SystemExit("Commons keeps refusing: run it again later (it resumes)")
        for im in j.get("query", {}).get("allimages", []):
            if im.get("mime") in ("image/jpeg", "image/png"):
                out.append(("File:" + im["name"].replace("_", " "), thumb(im["url"]), im.get("width", 0), im.get("height", 0),
                            im.get("user", ""), im.get("mime", "")))
        print("  index", name, len(out), flush=True)
        if "continue" not in j:
            break
        cont = {"aicontinue": j["continue"]["aicontinue"]}
        os.makedirs(CACHE, exist_ok=True)
        json.dump({"out": out, "cont": cont}, open(part, "w"))
    os.makedirs(CACHE, exist_ok=True)
    json.dump(out, open(f, "w"))
    if os.path.exists(part):
        os.remove(part)
    return out


# ------------------------------------------------------------------ hw

def hw_items(only):
    import gen_catalog
    _items, _merged, real, _g, _h = gen_catalog.collect()
    out = []
    for iid, (title, plat, kind) in real.items():
        if kind == "game" or (only and only not in iid):
            continue
        out.append((iid, title, plat, kind))
    return out


def find_hw(force, only):
    f = os.path.join(CACHE, "commons_hw.json")
    cand = json.load(open(f)) if os.path.exists(f) else {}
    for iid, title, plat, kind in hw_items(only):
        if iid in cand and not force:
            continue
        if fra.have("games", iid, "photo") and not force and "--all" not in sys.argv:
            continue
        hits = {h[0]: h for h in index("evan_amos", {"aiuser": "Evan-Amos", "aisort": "timestamp"})}
        if "--search" in sys.argv:
            for q in hw_queries(title)[:1]:
                for hit in search(q, 50):
                    hits[hit[0]] = hit
        scored = sorted(((hw_score(title, h), h) for h in hits.values()), key=lambda x: -x[0])
        cand[iid] = {"name": title, "hits": [[s] + list(h) for s, h in scored[:6]]}
        best = scored[0] if scored else None
        print("%-40s %s" % (iid, ("%3d %s" % (best[0], best[1][0])) if best else "-"), flush=True)
        os.makedirs(CACHE, exist_ok=True)
        json.dump(cand, open(f, "w"), indent=1)
    return cand


# Edition colour (real name word) -> shell colour, for the recoloured fallback.
EDITION_RGB = [("Atomic Purple", (128, 90, 190)), ("Jungle Green", (64, 165, 76)), ("Fire Orange", (242, 115, 38)),
               ("Ice Blue", (128, 190, 242)), ("Grape Purple", (115, 64, 153)), ("Watermelon Red", (230, 64, 76)),
               ("Smoke Black", (52, 52, 56)), ("Pikachu", (250, 216, 51)), ("Gold", (230, 184, 64)), ("Berry", (216, 51, 115)),
               ("Dandelion", (250, 216, 51)), ("Kiwi", (153, 204, 51)), ("Teal", (51, 165, 178)), ("Grape", (115, 64, 153)),
               ("Fuchsia", (230, 76, 178)), ("Indigo", (76, 64, 165)), ("Arctic", (235, 240, 245)), ("Orange", (242, 128, 38)),
               ("Black", (30, 30, 34)), ("Pearl Pink", (242, 190, 204)), ("Onyx", (30, 30, 34)), ("Flame", (216, 51, 38)),
               ("Tribal", (51, 64, 153)), ("Jet Black", (22, 22, 24)), ("Platinum", (204, 204, 214)), ("Spice Orange", (242, 140, 25)),
               ("Ceramic White", (237, 237, 235)), ("Satin Silver", (190, 194, 204)), ("Ocean Blue", (51, 102, 190)),
               ("Sakura Pink", (242, 178, 204)), ("Pink", (242, 178, 204)), ("Ice Silver", (204, 209, 219)),
               ("Felicia Blue", (115, 153, 216)), ("Lavender Purple", (178, 153, 216)), ("Lime Green", (140, 216, 51)),
               ("Crystal", (200, 220, 222)), ("Clear", (200, 215, 222))]


def edition_rgb(name):
    for word, rgb in EDITION_RGB:
        if word.lower() in name.lower():
            return rgb
    return None


def recolour(src, rgb, dst):
    """A real photo of the plain model with its shell (the photo's dominant
    colour) repainted in the edition's colour; buttons, screen and logos stay."""
    im = Image.open(src).convert("RGBA")
    px = im.load()
    w, h = im.size
    opaque = [px[x, y][:3] for x in range(0, w, 3) for y in range(0, h, 3) if px[x, y][3] > 200]
    if not opaque:
        return False
    # Dominant colour: the fullest bucket of a coarse histogram.
    buckets = {}
    for c in opaque:
        k = (c[0] // 32, c[1] // 32, c[2] // 32)
        buckets[k] = buckets.get(k, 0) + 1
    k = max(buckets, key=buckets.get)
    dom = [sum(c[i] for c in opaque if (c[0] // 32, c[1] // 32, c[2] // 32) == k) / buckets[k] for i in range(3)]
    dl = max(1.0, 0.3 * dom[0] + 0.59 * dom[1] + 0.11 * dom[2])
    tl = 0.3 * rgb[0] + 0.59 * rgb[1] + 0.11 * rgb[2]
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a < 8:
                continue
            d = ((r - dom[0]) ** 2 + (g - dom[1]) ** 2 + (b - dom[2]) ** 2) ** 0.5
            m = max(0.0, min(1.0, (110 - d) / 50))
            if m <= 0:
                continue
            lum = (0.3 * r + 0.59 * g + 0.11 * b) / dl
            # Shading kept relative to the new colour (dark colours keep a sheen).
            nr, ng, nb = [min(255, max(0, c * lum if tl > 60 else c + (lum - 1) * 60)) for c in rgb]
            px[x, y] = (int(r + (nr - r) * m), int(g + (ng - g) * m), int(b + (nb - b) * m), a)
    im.save(dst, optimize=True)
    return True


def base_photo(iid, title):
    """The photo of the plain model this edition is a recolour of."""
    import gen_catalog
    _i, _m, real, _g, _h = gen_catalog.collect()
    art = fra.hw_article(title)
    plat = real.get(iid, ("", "", ""))[1]
    best = None
    for oid, (t2, p2, k2) in real.items():
        if oid == iid or k2 == "game" or p2 != plat:
            continue
        f = next((os.path.join(ROOT, "assets/temp_test/games/%s_photo.%s" % (oid, e)) for e in ("png", "jpg")
                  if os.path.exists(os.path.join(ROOT, "assets/temp_test/games/%s_photo.%s" % (oid, e)))), None)
        if not f:
            continue
        common = len(os.path.commonprefix([t2.lower(), title.lower()]))
        same_art = art and fra.hw_article(t2) == art
        sc = common + (20 if same_art else 0) - (8 if edition_rgb(t2) else 0)
        if common >= 8 and (best is None or sc > best[0]):
            best = (sc, f, t2)
    return best


def save_hw(cand, force, only):
    """Saves the hand-picked photos (PICKS) from the Evan-Amos listing."""
    by = {h[0][5:]: h for h in index("evan_amos", {"aiuser": "Evan-Amos", "aisort": "timestamp"})}
    names = {}
    for iid, title, _p, _k in hw_items(""):
        names[iid] = title
    got = 0
    for iid, pick in PICKS.items():
        if only and only not in iid:
            continue
        if fra.have("games", iid, "photo") and not force:
            continue
        f, tint = (pick[0], True) if isinstance(pick, list) else (pick, False)
        hit = by.get(f)
        if not hit:
            print("  not listed", iid, f)
            continue
        rel = "assets/temp_test/games/%s_photo.jpg" % iid
        data = fetch_img(hit[1])
        if not data:
            print("  no data", iid)
            continue
        try:
            fra.save(data, os.path.join(ROOT, rel), 0.0)
        except Exception as e:  # not a picture
            print("  skip", iid, e)
            continue
        png = fra.cutout(os.path.join(ROOT, rel))
        if tint:
            rgb = edition_rgb(names.get(iid, ""))
            out = os.path.join(ROOT, "assets/temp_test/games/%s_photo.png" % iid)
            if rgb and recolour(png, rgb, out):
                if png != out:
                    os.remove(png)
                png = out
        fwa.log(os.path.relpath(png, ROOT), hit[1].replace("/thumb/", "/").rsplit("/", 1)[0] + (" (recoloured)" if tint else ""))
        got += 1
        print("ok", iid, "<-", f, "tint" if tint else "", flush=True)
    print("hw photos saved", got)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_catalog.py")])


# ------------------------------------------------------------------ coins

COIN_TYPE = [  # name words -> Commons search words for the type
    ("Saint-Gaudens", "Saint-Gaudens double eagle"), ("Indian Head Cent", "Indian Head cent"), ("Lincoln", "Lincoln cent"),
    ("Liberty Head Nickel", "Liberty Head nickel"), ("Buffalo", "Buffalo nickel"), ("Jefferson", "Jefferson nickel"),
    ("Shield Nickel", "Shield nickel"), ("Flying Eagle", "Flying Eagle cent"), ("Morgan", "Morgan dollar"), ("Peace Dollar", "Peace dollar"),
    ("Mercury", "Mercury dime"), ("Barber", "Barber"), ("Seated Liberty", "Seated Liberty"), ("Walking Liberty", "Walking Liberty half dollar"),
    ("Standing Liberty", "Standing Liberty quarter"), ("Franklin", "Franklin half dollar"), ("Kennedy", "Kennedy half dollar"),
    ("Washington", "Washington quarter"), ("Roosevelt", "Roosevelt dime"), ("Draped Bust", "Draped Bust"), ("Capped Bust", "Capped Bust"),
    ("Flowing Hair", "Flowing Hair"), ("Trade Dollar", "Trade dollar"), ("Indian Head", "Indian Head"), ("Liberty Head", "Liberty Head"),
    ("Chain Cent", "chain cent"), ("Wreath Cent", "wreath cent"), ("Large Cent", "large cent"), ("Two-Cent", "two-cent piece"),
    ("Three-Cent", "three-cent"), ("Twenty-Cent", "twenty-cent piece"), ("Half Cent", "half cent"), ("Eisenhower", "Eisenhower dollar"),
    ("Sacagawea", "Sacagawea dollar"), ("Susan B", "Susan B. Anthony dollar"), ("Brasher", "Brasher doubloon"), ("Gobrecht", "Gobrecht dollar")]

# US coins -> the Smithsonian NNC photo of that design (obverse and reverse
# side by side). Same design = same look; the year matches where the NNC has
# that very coin (1913 Liberty nickel, 1822 half eagle, 1849 pattern...).
# First rule whose words are all in the name wins; "!" = must not contain.
NNC_RULES = [
    (["1933", "Saint-Gaudens"], "NNC-US-1933-G$20-Saint Gaudens.jpg"),
    (["Ultra High Relief"], "NNC-US-1907-G$20-Saint Gaudens (Roman, ultra high relief, wire edge).jpg"),
    (["1907 High Relief"], "NNC-US-1907-G$20-Saint Gaudens (Roman, high relief).jpg"),
    (["Saint-Gaudens"], "NNC-US-1908-D-G$20-Saint Gaudens (Arabic & motto).jpg"),
    (["Flowing Hair Silver Dollar"], "NNC-US-1795-$1-Flowing hair.jpg"),
    (["Draped Bust Dollar"], "NNC-US-1798-$1-Draped bust (heraldic eagle).jpg"),
    (["1913 Liberty Head Nickel"], "NNC-US-1913-5C-Liberty Nickel (cents).jpg"),
    (["No Cents Liberty Nickel"], "NNC-US-1883-5C-Liberty Nickel (no cents).jpg"),
    (["Liberty Head Nickel"], "NNC-US-1887-5C-Liberty Nickel (cents).jpg"),
    (["1822 Capped Bust Half Eagle"], "NNC-US-1822-G$5-Capped Head (large diameter).jpg"),
    (["Capped Bust Half Eagle"], "NNC-US-1795-G$5-Turban Head (small eagle).jpg"),
    (["Double Eagle Pattern"], "NNC-US-1849-G$20-Liberty Head (Twenty D.).jpg"),
    (["Seated Liberty Dollar"], "NNC-US-1873-1$-Seated Liberty (motto).jpg"),
    (["Barber Dime"], "NNC-US-1892-10C-Barber Dime.jpg"),
    (["Steel Lincoln"], "NNC-US-1943-1C-Lincoln Cent (wheat, zinc-coated steel).jpg"),
    (["Lincoln Cent", "!19 6", "!1969", "!1972", "!1983", "!1995"], "NNC-US-1909-1C-Lincoln Cent (wheat).jpg"),
    (["Wheat Penny"], "NNC-US-1909-1C-Lincoln Cent (wheat).jpg"),
    (["Chain Cent"], "NNC-US-1793-1C-Flowing Hair Cent (chain).jpg"),
    (["Wreath Cent"], "NNC-US-1793-1C-Flowing Hair Cent (wreath).jpg"),
    (["Liberty Cap Cent"], "NNC-US-1794-1C-Liberty Cap Cent.jpg"),
    (["Draped Bust Cent"], "NNC-US-1803-1C-Draped Bust Cent.jpg"),
    (["Flying Eagle Cent"], "NNC-US-1858-1C-Flying Eagle Cent.jpg"),
    (["Buffalo Nickel"], "NNC-US-1913-5C-Buffalo Nickel (TyII-line).jpg"),
    (["Indian Head Cent"], "NNC-US-1860-1C-Indian Head Cent (wreath & shield).jpg"),
    (["Liberty Cap Half Cent"], "NNC-US-1794-½C-Liberty Cap Half Cent (right).jpg"),
    (["Classic Head Half Cent"], "NNC-US-1828-½C-Classic Head Half Cent (proof).jpg"),
    (["Braided Hair Half Cent"], "NNC-US-1844-½C-Braided Hair Half Cent (proof).jpg"),
    (["Shield Nickel With Rays"], "NNC-US-1866-5C-Shield Nickel (rays).jpg"),
    (["Shield Nickel"], "NNC-US-1873-5C-Shield Nickel (stars).jpg"),
    (["Three Cent Nickel"], "NNC-US-1865-3C-Three-Cent, Nickel.jpg"),
    (["Booby Head Cent"], "NNC-US-1839-1C-Matron Head Cent.jpg"),
    (["Jefferson Nickel"], "NNC-US-1938-5C-Jefferson Nickel.jpg"),
    (["Monticello Nickel"], "NNC-US-1938-5C-Jefferson Nickel.jpg"),
    (["Seated Dime"], "NNC-US-1860-10C-Seated Liberty (legend).jpg"),
    (["Morgan Dollar"], "NNC-US-1878-CC-1$-Morgan dollar.jpg"),
    (["Gobrecht Dollar"], "NNC-US-1836-1$-Gobrecht dollar (plain edge & name).jpg"),
    (["Seated Liberty Quarter"], "NNC-US-1873-25C-Seated Liberty (no arrows).jpg"),
    (["Trade Dollar"], "NNC-US-1873-1$-Seated Liberty (Trade dollar).jpg"),
    (["Peace Dollar"], "NNC-US-1921-1$-Peace dollar.jpg"),
    (["Draped Bust Dime"], "NNC-US-1797-10C-Draped Bust (small eagle).jpg"),
    (["Indian Princess Three Dollar"], "NNC-US-1854-G$3-Indian Princess Head.jpg"),
    (["Flowing Hair Stella"], "NNC-US-1879-G$4-Stella Pattern (Flowing Hair).jpg"),
    (["Coiled Hair Stella"], "NNC-US-1880-G$4-Stella Pattern (Coiled Hair).jpg"),
    (["Draped Bust Eagle"], "NNC-US-1797-G$10-Turban Head (heraldic eagle).jpg"),
    (["1854-O Liberty Double Eagle"], "NNC-US-1849-G$20-Liberty Head (Twenty D.).jpg"),
    (["Paquet Reverse"], "NNC-US-1849-G$20-Liberty Head (Twenty D.).jpg"),
    (["Liberty Head Double Eagle"], "NNC-US-1877-G$20-Liberty Head (Twenty Dollars & motto).jpg"),
    (["No Stars Quarter Eagle"], "NNC-US-1796-G$2½-Turban Head (no stars).jpg"),
    (["Liberty Head Quarter Eagle"], "NNC-US-1848-G$2½-Liberty Head (CAL).jpg"),
    (["Rolled Edge Indian Eagle"], "NNC-US-1907-G$10-Indian Head (no motto).jpg"),
    (["Indian Head Eagle"], "NNC-US-1908-G$10-Indian Head (motto).jpg"),
    (["Classic Head Half Eagle"], "NNC-US-1834-G$5-Classic Head.jpg"),
    (["1853 Liberty Gold Dollar"], "NNC-US-1849-G$1-Liberty head (Ty1).jpg"),
    (["Gold Dollar", "!Louisiana"], "NNC-US-1856-G$1-Indian head (Ty3).jpg"),
    (["Indian Head Quarter Eagle"], "NNC-US-1908-G$2½-Indian Head.jpg"),
    (["Indian Head Half Eagle"], "NNC-US-1908-G$5-Indian Head.jpg"),
    (["Liberty Head Eagle"], "NNC-US-1866-G$10-Liberty Head (new style & motto).jpg"),
    (["Liberty Head Half Eagle"], "NNC-US-1866-G$5-Liberty Head (motto).jpg"),
]


def nnc_file(name):
    for words, f in NNC_RULES:
        if all((w[1:] not in name) if w.startswith("!") else (w in name) for w in words):
            return f
    return ""


COIN_BAD = ("banknote", "note", "stamp", "medal", "token", "box", "holder", "slab", "pcgs", "ngc", "map", "portrait", "painting",
            "statue", "building", "die", "dies", "press", "hoard", "pile", "lot", "roll", "bag", "jewelry", "pendant")


def coin_rows(only):
    import gen_collectibles as gc
    coins = gc.coin_items(gc.parse(gc.COINS))
    return [d for d in coins if not only or only in d["id"]]


def coin_queries(d):
    name = d["name"]
    qs = []
    if d["country"] == "United States":
        yr = re.match(r"\d{4}", name)
        typ = next((t for k, t in COIN_TYPE if k in name), "")
        base = re.sub(r"\b(Proof|Doubled Die|Obverse|Reverse|Close AM|Wide AM|Overdate|No Motto|With Motto|Pattern|Ultra High Relief|High Relief)\b", "", name)
        qs.append("NNC US %s %s" % (yr.group(0) if yr else d["year"], typ or base))
        qs.append(re.sub(r"\s+", " ", base).strip())
    else:
        qs.append(name)
        qs.append("%s %s %s coin" % (d["country"], d["denom"], d["year"] if d["year"] > 0 else ""))
    return qs


def coin_score(d, hit):
    title, _u, w, h, user, _m = hit
    t = title[5:].rsplit(".", 1)[0]
    low = " " + " ".join(toks(t)) + " "
    if any((" " + b + " ") in low for b in COIN_BAD):
        return -99
    s = 0
    yr = abs(int(d["year"]))
    m = re.match(r"(\d{3,4})", d["name"])
    want_year = m.group(1) if m else str(yr)
    years = re.findall(r"(?<!\d)(\d{3,4})(?!\d)", t)
    if want_year in years:
        s += 8
    elif years and d["year"] > 1000:
        s -= 6
    words = [w2 for w2 in toks(re.sub(r"^\d{4}(-[A-Z]+)?\s*", "", d["name"])) if w2 not in STOP and len(w2) > 2]
    for w2 in words:
        if (" " + w2 + " ") in low or w2 in low.replace(" ", ""):
            s += 3
        else:
            s -= 1
    mint = re.match(r"\d{4}-([A-Z]{1,2})\b", d["name"])
    if mint:
        s += 3 if re.search(r"\b%s\b" % mint.group(1).lower(), low) or ("%s %s" % (want_year, mint.group(1).lower())) in low else -2
    if t.startswith("NNC"):
        s += 4
    if "obverse" in low or "reverse" in low or " obv" in low or " rev" in low:
        s += 1
    if min(w, h) < 200:
        s -= 3
    return s


def find_coins(force, only):
    f = os.path.join(CACHE, "commons_coins.json")
    cand = json.load(open(f)) if os.path.exists(f) else {}
    for d in coin_rows(only):
        iid = d["id"]
        if iid in cand and not force:
            continue
        hits = {}
        if nnc_file(d["name"]):
            cand[iid] = {"name": d["name"], "hits": []}
            continue
        if "--search" not in sys.argv:
            continue  # one search per coin, ~30 s each from here: opt in
        if True:
            for q in coin_queries(d)[:1]:
                for hit in search(q, 20):
                    hits[hit[0]] = hit
        scored = sorted(((coin_score(d, h), h) for h in hits.values()), key=lambda x: -x[0])
        cand[iid] = {"name": d["name"], "hits": [[s] + list(h) for s, h in scored[:6]]}
        best = scored[0] if scored else None
        print("%-40s %s" % (iid, ("%3d %s" % (best[0], best[1][0])) if best else "-"), flush=True)
        os.makedirs(CACHE, exist_ok=True)
        json.dump(cand, open(f, "w"), indent=1)
    os.makedirs(CACHE, exist_ok=True)
    json.dump(cand, open(f, "w"), indent=1)
    return cand


def disc(im):
    """Crops a coin photo to its disc: the bounding box of what is not the
    backdrop (sampled at the corners), squared around the centre."""
    rgb = im.convert("RGB")
    w, h = rgb.size
    corners = [rgb.getpixel((x, y)) for x, y in ((1, 1), (w - 2, 1), (1, h - 2), (w - 2, h - 2))]
    bgc = tuple(sorted(c[i] for c in corners)[1] for i in range(3))
    diff = ImageChops.difference(rgb, Image.new("RGB", rgb.size, bgc)).convert("L").point(lambda v: 255 if v > 34 else 0)
    diff = diff.filter(ImageFilter.MedianFilter(5))
    bb = diff.getbbox()
    if not bb or (bb[2] - bb[0]) < w * 0.3 or (bb[3] - bb[1]) < h * 0.3:
        bb = (0, 0, w, h)
    cx, cy = (bb[0] + bb[2]) / 2, (bb[1] + bb[3]) / 2
    side = max(bb[2] - bb[0], bb[3] - bb[1]) * 1.02
    box = (int(cx - side / 2), int(cy - side / 2), int(cx + side / 2), int(cy + side / 2))
    sq = Image.new("RGB", (int(side), int(side)), bgc)
    sq.paste(rgb.crop((max(0, box[0]), max(0, box[1]), min(w, box[2]), min(h, box[3]))), (max(0, -box[0]), max(0, -box[1])))
    return sq.resize((256, 256), Image.LANCZOS)


def faces(data):
    """A coin picture -> [obverse, reverse?]. Side-by-side pairs are split."""
    im = Image.open(io.BytesIO(data))
    if im.mode in ("RGBA", "LA", "P"):
        im = im.convert("RGBA")
        bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
        bg.alpha_composite(im)
        im = bg
    im = im.convert("RGB")
    w, h = im.size
    if w > h * 1.6:
        return [disc(im.crop((0, 0, w // 2, h))), disc(im.crop((w - w // 2, 0, w, h)))]
    if h > w * 1.6:
        return [disc(im.crop((0, 0, w, h // 2))), disc(im.crop((0, h - h // 2, w, h)))]
    return [disc(im)]


def save_coins(cand, force, only):
    got = 0
    out = os.path.join(ROOT, "assets", "temp_test", "coins")
    os.makedirs(out, exist_ok=True)
    for iid, c in cand.items():
        if only and only not in iid:
            continue
        rel = "assets/temp_test/coins/%s_obv.jpg" % iid
        if os.path.exists(os.path.join(ROOT, rel)) and not force:
            continue
        hits = c["hits"]
        nf = nnc_file(c["name"])
        if nf:
            by = {h[0][5:]: h for h in index("nnc_us", {"aiprefix": "NNC-US-"})}
            if nf in by:
                hits = [[99] + list(by[nf])]
        pick = PICKS.get(iid)
        if pick is not None:
            hits = [h for h in hits if h[1] == pick]
        elif not hits or hits[0][0] < 9:
            continue
        if not hits:
            continue
        hit = hits[0]
        data = fetch_img(hit[2].replace("/500px-", "/960px-"))
        if not data:
            continue
        try:
            fs = faces(data)
        except Exception as e:  # not a picture
            print("  skip", iid, e)
            continue
        # A single face: look for its other side among the hits (obv <-> rev).
        if len(fs) == 1:
            t = hit[1]
            other = t.replace("obverse", "reverse").replace("Obverse", "Reverse").replace("obv", "rev").replace("Obv", "Rev")
            if other == t:
                other = t.replace("reverse", "obverse").replace("Reverse", "Obverse").replace("rev", "obv").replace("Rev", "Obv")
            mate = next((h for h in c["hits"] if h[1] == other and other != t), None)
            if mate:
                d2 = fetch_img(mate[2])
                try:
                    f2 = faces(d2)[0]
                    fs = [f2, fs[0]] if re.search(r"rev", t, re.I) and not re.search(r"obv", t, re.I) else [fs[0], f2]
                except Exception:
                    pass
        for k, im in enumerate(fs[:2]):
            r2 = "assets/temp_test/coins/%s_%s.jpg" % (iid, "obv" if k == 0 else "rev")
            im.save(os.path.join(ROOT, r2), quality=86, optimize=True)
            fra_imp(os.path.join(ROOT, r2))
            fwa.log(r2, hit[2])
        got += 1
        print("ok", iid, len(fs), "<-", hit[1], flush=True)
    print("coin photos saved", got)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_collectibles.py")])


def fra_imp(path):
    imp = path + ".import"
    if not os.path.exists(imp):
        open(imp, "w").write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
                             '[params]\n\ncompress/mode=1\ncompress/lossy_quality=0.8\n')


def sheet(mode, cand, path):
    ids = list(cand.keys())
    cw = 128
    cols = 10
    img = Image.new("RGB", (cols * cw, ((len(ids) + cols - 1) // cols) * (cw + 14)), (40, 40, 48))
    dr = ImageDraw.Draw(img)
    for k, iid in enumerate(ids):
        x, y = (k % cols) * cw, (k // cols) * (cw + 14)
        if mode == "hw":
            fs = [os.path.join(ROOT, "assets/temp_test/games/%s_photo.%s" % (iid, e)) for e in ("png", "jpg")]
        else:
            fs = [os.path.join(ROOT, "assets/temp_test/coins/%s_%s.jpg" % (iid, s)) for s in ("obv", "rev")]
        fs = [f for f in fs if os.path.exists(f)]
        for j, f in enumerate(fs[:2] if mode == "coins" else fs[:1]):
            im = Image.open(f).convert("RGBA")
            sz = cw - 4 if mode == "hw" else cw // 2 - 2
            im.thumbnail((sz, sz))
            bg = Image.new("RGBA", im.size, (200, 200, 210, 255))
            bg.alpha_composite(im)
            img.paste(bg.convert("RGB"), (x + 2 + j * (cw // 2), y + 2))
        dr.text((x + 2, y + cw), iid[:22], fill=(255, 255, 200))
    img.save(path)
    print("sheet", path)


def main():
    a = [x for x in sys.argv[1:]]
    force = "--force" in a
    only = a[a.index("--only") + 1] if "--only" in a else ""
    mode = a[0] if a else "hw"
    steps = [x for x in a[1:] if x in ("find", "save", "sheet")] or ["find", "save"]
    f = os.path.join(CACHE, "commons_%s.json" % mode)
    cand = json.load(open(f)) if os.path.exists(f) else {}
    if "find" in steps:
        cand = (find_hw if mode == "hw" else find_coins)(force and "save" not in steps, only)
    if "save" in steps:
        (save_hw if mode == "hw" else save_coins)(cand, force, only)
    if "sheet" in steps:
        sheet(mode, cand, a[a.index("sheet") + 1])


if __name__ == "__main__":
    main()
