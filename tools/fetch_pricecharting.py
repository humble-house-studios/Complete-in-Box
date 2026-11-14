#!/usr/bin/env python3
"""Real product photos from PriceCharting for consoles, accessories and coins (test-only).

    python3 tools/fetch_pricecharting.py hw [find] [save] [sheet OUT.png] [--force] [--only ID_PART]
    python3 tools/fetch_pricecharting.py coins [find] [save] [sheet OUT.png] [--force] [--only ID_PART]

PriceCharting (pricecharting.com) lists every console colour edition,
accessory and US / world coin with a stock photo. Wikimedia throttles
downloads from cloud machines to a trickle; this is the quick source.

find   searches each item's real name (search-products) and scores the
       product pages it lists by their url words; best pick per item in
       .cache/pc_<mode>.json
save   downloads the pick's main photo (images.pricecharting.com/<id>/1600.jpg):
       hw    -> assets/temp_test/games/<id>_photo.png (white backdrop cut out),
                replacing recoloured stand-ins (tools/fetch_commons_art.py)
       coins -> assets/temp_test/coins/<id>_obv.jpg (cropped to the disc;
                the reverse stays painted unless Commons had it)
sheet  contact sheet of what was saved

PICKS pins a product url by hand ("" = keep what there is).
Every file is logged in assets/temp_test/MANIFEST.txt and assets/sources.txt.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fetch_world_art as fwa  # noqa: E402  (log)
import fetch_retro_art as fra  # noqa: E402  (save, cutout)
import fetch_commons_art as fca  # noqa: E402  (faces, disc)

from PIL import Image, ImageDraw  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, ".cache")
SITE = "https://www.pricecharting.com"
UA = "Mozilla/5.0 (CollectorsCurseAssetFetch/1.0; game test assets)"
STOP = {"the", "of", "a", "an", "and", "edition", "with", "for", "console", "system", "japan", "in", "de", "s", "&"}

# id -> product path (after /game/), checked by eye, or "" = no good match
# (the item keeps its painted art / rendered model).
PICKS = {
    # hardware
    "sfes_funtendo_playstatia_sfes_cd": "playstation/nintendo-playstation-system", "gen_saga_neptune_prototype": "",
    "odd_ataro_jagwire_vr_prototype": "", "sat_saga_saturnine_hi_saturnine": "jp-sega-saturn/sega-hitachi-hi-saturn-console-model-1",
    "sat_saga_saturnine_v_saturnine": "", "dc_saga_dreamcaster_divers_2001": "jp-sega-dreamcast/divers-2000-cx-1",
    "dc_saga_dreamcaster_hello_kitte": "jp-sega-dreamcast/hello-kitty-dreamcast-system", "dc_saga_dreamcaster_resident_we": "",
    "dc_saga_dreamcaster_samba_de_am": "jp-sega-dreamcast/samba-de-amigo-bundle", "pst_playstatia_dtl_h2000_debugg": "",
    "pst2_playstatia_2_linuks_kit": "", "fes_sharpe_funicom_titlr": "famicom/famicom-titler-an-510-editor",
    "fes_funicom_network_system": "famicom/family-computer-network-system", "fes_funicom_data_recordr": "famicom/famicom-data-recorder",
    "fes_fes_zappr_orange": "nes/zapper-light-gun", "fes_fes_satellyte": "nes/nes-satellite-4-controller-port",
    "fes_fes_max": "nes/nes-max-controller", "fes_game_jeannie_fes": "nes/game-genie", "fes_u_farce": "",
    "fes_roll_n_rockr": "nes/roll-%26-rocker", "fes_miracle_pianah_teaching_syst": "nes/miracle-piano",
    "fes_playchoice_11_arcade_cabinet": "", "fes_vs_sistem_arcade_cabinet": "", "sfes_super_fes_model_2_sns_101": "",
    "sfes_super_funicom_shvc_001": "super-famicom/super-famicom-console", "sfes_super_funicom_jr_shvc_101": "super-famicom/super-famicom-jr",
    "sfes_super_fes_plumber_paint_bund": "super-nintendo/mario-paint-mouse-bundle", "sfes_super_fes_multitapp_super_mu": "super-nintendo/super-multitap",
    "sfes_super_fes_super_advantage": "super-nintendo/super-advantage-controller", "sfes_sufunny_turbo": "super-famicom/sufami-turbo",
    "sfes_satelloview_modem_unit": "super-famicom/satellaview", "sfes_voice_kunn_super_funicom": "",
    "f64_console": "nintendo-64/nintendo-64-system", "f64_funtendo_64_pikapal_edition": "nintendo-64/pikachu-nintendo-64-system",
    "f64_funtendo_64_gold_controller": "nintendo-64/gold-controller", "f64_funtendo_64_atomic_purple_co": "nintendo-64/atomic-purple-controller",
    "f64_funtendo_64_pikapal_controll": "jp-nintendo-64/pikachu-blue-and-yellow-controller", "f64_funtendo_64_mouse": "jp-nintendo-64/nintendo-64-mouse",
    "fcube_funcube_jet_black": "gamecube/black-gamecube-system", "fcube_funcube_platinum": "gamecube/platinum-gamecube-system",
    "fcube_funcube_spice_orange": "jp-gamecube/spice-orange-gamecube-system", "fcube_funcube_panasonik_q_japan": "jp-gamecube/panasonic-q-gamecube-console",
    "fcube_funcube_pocketboy_player_sta": "pal-gamecube/game-boy-player-start-up-disc", "fcube_funcube_dk_bongoes": "gamecube/donkey-kong-jungle-beat-bongos-bundle",
    "fcube_funcube_dance_dance_revelati": "", "fcube_funcube_component_cable": "gamecube/digital-av-component-cable",
    "fcube_funcube_digital_av_cable": "gamecube/digital-av-component-cable", "fcube_funcube_memory_card_1019": "gamecube/64mb-1019-block-memory-card",
    "fcube_funcube_action_replai": "gamecube/action-replay", "fcube_funcube_freeloadr": "gamecube/freeloader",
    "pboy_pocketboy_pocket": "gameboy/silver-game-boy-pocket", "pboy_pocketboy_pocket_pikapal_edi": "",
    "pboy_pocketboy_pocket_clear_editi": "gameboy/clear-game-boy-pocket", "pboy_gold": "jp-gameboy/gameboy-light-silver",
    "pboy_pocketboy_play_it_louder_ser": "gameboy/gameboy-green-play-it-loud", "pboy_pocketboy_color_dandelion": "gameboy-color/game-boy-color-yellow",
    "pboy_pocketboy_color_pikapal_edit": "gameboy-color/pokemon-special-edition-gameboy-color-system",
    "pboy_pocketboy_color_pocket_critt": "gameboy-color/pokemon-gold-and-silver-special-edition-gameboy-color",
    "pba_pocketboy_advance_fuchsia": "gameboy-advance/gameboy-advance-fuchsia-pink", "pba_pocketboy_advance_indigo": "gameboy-advance/indigo-gameboy-advance-system",
    "pba_pocketboy_advance_arctic": "jp-gameboy-advance/game-boy-advance-arctic-white", "pba_pocketboy_advance_orange": "gameboy-advance/orange-gameboy-advance-system",
    "pba_pocketboy_advance_black": "gameboy-advance/black-gameboy-advance-system", "pba_pocketboy_advance_sp_ags_101": "gameboy-advance/graphite-gameboy-advance-sp-ags-101",
    "pba_pocketboy_advance_sp_pearl_p": "pal-gameboy-advance/game-boy-advance-sp-pearl-pink", "pba_pocketboy_advance_sp_onyx": "gameboy-advance/gameboy-advance-sp-onyx",
    "pba_pocketboy_advance_sp_flame": "pal-gameboy-advance/gameboy-advance-sp-flame-red", "pba_pocketboy_advance_sp_tribal": "gameboy-advance/tribal-gameboy-advance-sp",
    "pba_pocketboy_advance_sp_fes_edi": "pal-gameboy-advance/game-boy-advance-sp-classic-nes-edition",
    "pba_pocketboy_advance_sp_funicom": "jp-gameboy-advance/gameboy-advance-sp-famicom-color-edition",
    "pba_pocketboy_advance_sp_pikapal": "gameboy-advance/pikachu-gameboy-advance-sp", "pba_pocketboy_advance_sp_zeldo_e": "gameboy-advance/zelda-edition-gameboy-advance-sp",
    "pba_pocketboy_micro_funicom_edit": "jp-gameboy-advance/game-boy-micro-famicom", "pba_pocketboy_micro_mama_3_editi": "jp-gameboy-advance/gba-micro-mother-3-edition",
    "pba_pocketboy_micro_20th_anniver": "gameboy-advance/gba-micro-20th-anniversary-edition",
    "duo_funtendo_duo_lite_zeldo_gold": "nintendo-ds/gold-zelda-nintendo-ds-lite-limited-edition",
    "duo_funtendo_duo_lite_pocket_cri": "jp-nintendo-ds/nintendo-ds-lite-console-pokemon-daisuki-club-edition",
    "pst_playstatia_scph_1000_japan_l": "jp-playstation/playstation-1-system", "pst_console": "playstation/playstation-system",
    "pst_playstatia_scph_5501": "playstation/playstation-system", "pst_playstatia_scph_7501": "playstation/playstation-system",
    "pst_pst_one": "", "pst_pst_one_lcd_screen": "playstation/psone-slim-console-with-lcd-screen-combo",
    "pst_dualpad": "playstation-2/black-dual-shock-controller", "pst_playstatia_multitapp": "playstation/multi-tap-adaptor",
    "pst_memcard": "playstation/ps1-memory-card", "pst_playstatia_gunkon_namcoo": "playstation/namco-guncon-light-gun",
    "pst_playstatia_g_kon_45_namcoo": "playstation/namco-guncon-light-gun", "pst_playstatia_justifyer_konamo": "playstation/konami-justifier",
    "pst_playstatia_densha_de_gogo_co": "jp-playstation/densha-de-go-controller", "pst_playstatia_beatmanias_contro": "jp-playstation/beatmania-controller",
    "pst_playstatia_dance_dance_revel": "playstation-2/dance-dance-revolution-super-deluxe-dance-pad",
    "pst2_pst2_scph_10000_japan_launch": "jp-playstation-2/playstation-2-system", "pst2_pst2_ceramic_white_japan": "jp-playstation-2/ceramic-white-playstation-2-system",
    "pst2_pst2_satin_silver": "pal-playstation-2/playstation-2-satin-silver", "pst2_pst2_ocean_blue_japan": "jp-playstation-2/playstation-2-ocean-blue",
    "pst2_pst2_sakura_pink_japan": "jp-playstation-2/playstation-2-system-sakura-pink", "pst2_pst2_slimline_pink": "jp-playstation-2/pink-slim-playstation-2-system",
    "pst2_pst2_network_adapter": "playstation-2/network-adaptor", "pst2_pst2_hard_disk_drive": "", "pst2_pst2_multitapp": "playstation-2/multi-tap-adaptor",
    "pst2_pst2_dvd_remote": "playstation-2/dvd-remote-control", "pst2_pst2_vertical_stand": "playstation-2/vertical-console-stand",
    "pst2_pst2_gunkon_2": "playstation-2/guncon-2", "pst2_pst2_guitar_zero_guitar": "playstation-2/guitar-hero-sg-guitar-controller-red",
    "pspk_pspocket_1000_ceramic_white": "jp-psp/psp-1000-ceramic-white", "pspk_pspocket_1000_ice_silver": "",
    "pspk_pspocket_1000_felicia_blue": "jp-psp/sony-psp-2000-felicia-blue", "pspk_pspocket_1000_lavender_purpl": "jp-psp/sony-psp-2000-lavender",
    "xbx_xbux_hallo_edition": "xbox/xbox-system-green-halo-edition", "xbx_xbux_mountain_doo_edition": "xbox/mountain-dew-limited-edition-xbox-system",
    "xbx_xbux_crystal_edition": "pal-xbox/xbox-premium-edition-system-crystal-limited-edition", "xbx_xbux_lime_green": "",
    "xbx_xbux_developer_kit": "xbox/xbox-xdk-development-kit", "xbx_xbux_controller_s": "xbox/black-s-type-controller",
    "xbx_xbux_crystal_controller": "xbox/crystal-s-type-controller", "xbx_xbux_hallo_controller": "xbox/green-halo-edition-s-type-controller",
    "xbx_xbux_memory_unit": "xbox/xbox-memory-unit", "xbx_xbux_dvd_playback_kit": "xbox/dvd-movie-playback-kit",
    "xbx_xbux_communicator": "xbox/microsoft-xbox-communicator", "xbx_xbux_361_hallo_3_limited_edi": "xbox-360/xbox-360-system-halo-3-limited-edition",
    "xbx_xbux_361_gears_of_wart_3_lim": "xbox-360/xbox-360-gears-of-war-3-limited-edition", "xbx_xbux_361_star_warz_r3_d3_edi": "",
    "xbx_xbux_361_elite": "xbox-360/xbox-360-system-elite-120gb", "xbx_xbux_361_kinnect": "xbox-360/kinect-sensor",
    "dc_console": "sega-dreamcast/sega-dreamcast-console", "dc_dreamcaster_fishing_controll": "sega-dreamcast/fishing-rod-controller",
    "dc_dreamcaster_maracaz": "sega-dreamcast/maracas-controller", "dc_dreamcaster_light_gun": "jp-sega-dreamcast/dreamcast-light-gun",
    "dc_dreamcaster_arcade_stick": "sega-dreamcast/sega-dreamcast-arcade-stick", "dc_dreamcaster_keyboard": "sega-dreamcast/sega-dreamcast-keyboard",
    "dc_dreamcaster_mouse": "sega-dreamcast/sega-dreamcast-mouse", "dc_dreamcaster_broadbland_adapt": "sega-dreamcast/sega-dreamcast-broadband-adapter",
    "dc_dreamcaster_modem": "", "dc_dreamcaster_jump_pack": "sega-dreamcast/jump-pack", "dc_dreamcaster_microphone": "sega-dreamcast/microphone",
    "dc_dreamcaster_racing_wheel": "sega-dreamcast/concept-4-racing-wheel", "dc_dreamcaster_twin_stick": "jp-sega-dreamcast/sega-dreamcast-twin-stick-controller",
    "dc_dreamcaster_dreamseye": "jp-sega-dreamcast/dreameye", "dc_dreamcaster_vga_box": "jp-sega-dreamcast/sega-dreamcast-vga-box",
    "gen_saga_genesys_model_2": "sega-genesis/sega-genesis-model-2-console", "gen_saga_genesys_model_3": "",
    "gen_saga_wondermegga": "jp-sega-mega-drive/jvc-wondermega-rg-m1", "gen_jbc_x_ayy": "sega-genesis/sega-genesis-jvc-x%27eye",
    "gen_saga_megga_ld": "", "a26_ataro_2600_jr": "", "a26_ataro_2600_seers_video_arcad": "atari-2600/sears-video-arcade-system",
    "a26_ataro_2600_colecko_gemini": "atari-2600/coleco-gemini-video-game-system", "a26_ataro_2600_trak_bawl": "atari-2600/trak-ball-controller",
    "neo_neon_geo_aes_controller": "neo-geo-aes/neo-geo-aes-joystick", "neo_neon_geo_aes_arcade_stick": "neo-geo-aes/neo-geo-aes-joystick",
    "neo_neon_geo_aes_memory_card": "neo-geo-aes/neo-geo-memory-card", "neo_neon_geo_mvs_arcade_cabinet": "", "neo_neon_geo_mvs_1_slot": "",
    "neo_neon_geo_mvs_4_slot": "", "neo_neon_geo_mvs_6_slot": "", "neo_neon_geo_cd_front_loader": "jp-neo-geo-cd/neo-geo-cd-front-loader",
    # coins
    "gold_1870_s_indian_princess_three_d": "coins-three-dollar-gold/1860-s", "gold_1874_indian_princess_three_dol": "coins-three-dollar-gold/1867",
    "gold_1854_indian_princess_three_dol": "coins-three-dollar-gold/1854-proof", "gold_1861_d_liberty_gold_dollar": "coins-gold-dollar/1861",
    "gold_1875_liberty_head_gold_dollar": "coins-gold-dollar/1881", "gold_1853_liberty_gold_dollar": "coins-gold-dollar/1849",
    "gold_1910_d_indian_head_quarter_eag": "coins-indian-head-quarter-eagle/1911-d-strong-d", "silv_1876_cc_twenty_cent_piece": "coins-twenty-cent/1875-cc",
    "cent_1916_doubled_die_buffalo_nicke": "coins-buffalo-nickel/1916-proof", "cent_1869_9_indian_head_cent": "",
    "cent_1995_doubled_die_lincoln_cent": "", "cent_1939_doubled_monticello_nickel": "", "silv_1792_half_disme": "",
    "gold_1796_no_stars_quarter_eagle": "", "gold_1849_mormon_five_dollar": "", "gold_1855_wass_molitor_fifty_dollar": "",
    "gold_1903_louisiana_purchase_gold_d": "", "gold_1926_sesquicentennial_quarter": "",
    "cent_1793_chain_cent": "", "gold_1915_s_panama_pacific_fifty_do": "", "gold_1856_s_liberty_head_gold_dolla": "",
    "gold_1915_s_panama_pacific_quarter": "", "gold_1926_indian_head_eagle": "", "cent_1944_wheat_penny": "coins-lincoln-wheat-penny/1944",
    "silv_1878_8_tail_feathers_morgan_do": "", "silv_1901_morgan_dollar": "coins-morgan-dollar/1901",
    "wrld_1776_continental_currency_doll": "", "wrld_1987_britannia_gold": "", "wrld_1989_australia_gold_nugget": "",
}


def get(url, pause=1.2):
    time.sleep(pause)
    for k in range(4):
        r = subprocess.run(["curl", "-sS", "-L", "-m", "60", "-A", UA, "-w", "\n%{http_code} %{url_effective}", url],
                           capture_output=True)
        body, _, tail = r.stdout.rpartition(b"\n")
        code, _, eff = tail.decode("utf-8", "replace").partition(" ")
        if code == "200":
            return body, eff
        if code == "404":
            return b"", eff
        time.sleep(10 + k * 20)
    return b"", url


def words(s):
    s = s.lower().replace("é", "e").replace("'", "")
    return [w for w in re.findall(r"[a-z0-9]+", s) if w not in STOP]


def search(q):
    """[product path] for a query; a single hit redirects straight to it."""
    body, eff = get(SITE + "/search-products?type=prices&q=" + urllib.parse.quote_plus(q))
    m = re.search(r"/game/([^?#]+)", eff)
    if m:
        return [m.group(1)]
    html = body.decode("utf-8", "ignore")
    out = []
    for p in re.findall(r'href="https://www\.pricecharting\.com/game/([^"?#]+)"', html):
        if p not in out:
            out.append(p)
    return out[:20]


def photo(path):
    """The product page's main photo (1600 px variant) or ''."""
    body, _ = get(SITE + "/game/" + path)
    m = re.search(r"https://storage\.googleapis\.com/images\.pricecharting\.com/([^/\"']+)/(?:1600|240)\.jpg", body.decode("utf-8", "ignore"))
    return "https://storage.googleapis.com/images.pricecharting.com/%s/1600.jpg" % m.group(1) if m else ""


# ------------------------------------------------------------------ scoring

def hw_score(name, kind, path):
    plat, _, slug = path.partition("/")
    sw = set(words(slug.replace("-", " ")))
    pw = set(words(plat.replace("-", " ")))
    want = words(re.sub(r"\(.*?\)", " ", name))
    if not want:
        return -99
    s = 0
    for w in want:
        if w in sw:
            s += 3
        elif w in pw:
            s += 1
        else:
            s -= 2
    # Extra words in the product name = a different edition / bundle.
    s -= 0.7 * len([w for w in sw if w not in want and w not in ("system", "console", "nintendo", "sony", "sega", "microsoft")])
    if plat.startswith(("pal-", "jp-")) and "japan" not in name.lower():
        s -= 3
    if "(Japan)" in name and plat.startswith("jp-"):
        s += 3
    if kind == "console" and ("controller" in sw or "game" in sw and "boy" not in sw):
        s -= 4
    if any(w in sw for w in ("lot", "bundle", "box", "manual", "only")) and not any(w in want for w in ("bundle", "box")):
        s -= 3
    return s


def coin_score(d, path):
    plat, _, slug = path.partition("/")
    if not plat.startswith("coins"):
        return -99
    name = re.sub(r"^(\d{4})/(\d)", r"\1\2", d["name"])  # 1918/7-D -> 19187-D (overdates)
    yr = re.match(r"(\d{3,5})", name)
    s = 0
    if yr and re.match(r"%s\b" % yr.group(1), slug):
        s += 8
    elif yr:
        s -= 8
    mint = re.match(r"\d{4}-([A-Z]{1,2})\b", name)
    sw = slug.split("-")
    if mint:
        s += 3 if mint.group(1).lower() in sw else -3
    elif len(sw) > 1 and len(sw[1]) <= 2 and sw[1].isalpha() and sw[1] not in ("vdb",):
        s -= 2  # a mint mark the coin does not have
    typ = set(words(re.sub(r"^\d{4}\S*\s*", "", name)))
    tw = set(words(plat.replace("coins-", "").replace("-", " ") + " " + slug.replace("-", " ")))
    s += 2 * len(typ & tw) - len(typ - tw)
    if "proof" in sw and "Proof" not in name:
        s -= 3
    return s


# ------------------------------------------------------------------ find / save

def hw_items(only):
    import gen_catalog
    _i, _m, real, _g, _h = gen_catalog.collect()
    out = []
    for iid, (title, plat, kind) in real.items():
        if kind == "game" or (only and only not in iid):
            continue
        out.append((iid, title, plat, kind))
    return out


def recoloured():
    """Ids whose photo is a recoloured stand-in (logged by fetch_commons_art)."""
    out = set()
    p = os.path.join(ROOT, "assets/temp_test/MANIFEST.txt")
    for ln in open(p, encoding="utf-8"):
        if "(recoloured)" in ln or "recoloured from" in ln:
            m = re.search(r"games/(.+?)_photo\.", ln)
            if m:
                out.add(m.group(1))
    return out


def find(mode, force, only):
    f = os.path.join(CACHE, "pc_%s.json" % mode)
    cand = json.load(open(f)) if os.path.exists(f) else {}
    if mode == "hw":
        tint = recoloured()
        todo = [(iid, t, k) for iid, t, _p, k in hw_items(only) if not fra.have("games", iid, "photo") or iid in tint]
    else:
        import gen_collectibles as gc
        todo = [(d["id"], d["name"], d) for d in gc.coin_items(gc.parse(gc.COINS)) if not only or only in d["id"]]
        todo = [t for t in todo if not os.path.exists(os.path.join(ROOT, "assets/temp_test/coins/%s_obv.jpg" % t[0]))]
    for iid, name, extra in todo:
        if iid in cand and not force:
            continue
        q = re.sub(r"\(.*?\)", " ", name)
        q = re.sub(r"\s+", " ", q).strip()
        paths = search(q)
        if mode == "hw":
            scored = sorted(((hw_score(name, extra, p), p) for p in paths), reverse=True)
        else:
            scored = sorted(((coin_score(extra, p), p) for p in paths), reverse=True)
        cand[iid] = {"name": name, "hits": scored[:5]}
        print("%-38s %s" % (iid, ("%5.1f %s" % scored[0]) if scored else "-"), flush=True)
        os.makedirs(CACHE, exist_ok=True)
        json.dump(cand, open(f, "w"), indent=1)
    return cand


def save(mode, cand, force, only):
    got = 0
    tint = recoloured() if mode == "hw" else set()
    for iid, c in cand.items():
        if only and only not in iid:
            continue
        path = PICKS.get(iid)
        if path is None:
            need = 6 if mode == "hw" else 8
            path = c["hits"][0][1] if c["hits"] and c["hits"][0][0] >= need else ""
        if not path:
            continue
        if mode == "hw":
            if fra.have("games", iid, "photo") and iid not in tint and not force:
                continue
        elif os.path.exists(os.path.join(ROOT, "assets/temp_test/coins/%s_obv.jpg" % iid)) and not force:
            continue
        url = photo(path)
        if not url:
            print("  no photo", iid, path)
            continue
        data, _ = get(url, pause=0.5)
        if not data:
            continue
        src = SITE + "/game/" + path
        try:
            if mode == "hw":
                for e in ("png", "jpg"):
                    old = os.path.join(ROOT, "assets/temp_test/games/%s_photo.%s" % (iid, e))
                    if os.path.exists(old):
                        os.remove(old)
                rel = "assets/temp_test/games/%s_photo.jpg" % iid
                fra.save(data, os.path.join(ROOT, rel), 0.0)
                png = fra.cutout(os.path.join(ROOT, rel))
                rel = os.path.relpath(png, ROOT)
                _relog(rel, src)
            else:
                face = fca.faces(data)[0]
                rel = "assets/temp_test/coins/%s_obv.jpg" % iid
                os.makedirs(os.path.dirname(os.path.join(ROOT, rel)), exist_ok=True)
                face.save(os.path.join(ROOT, rel), quality=86, optimize=True)
                fca.fra_imp(os.path.join(ROOT, rel))
                _relog(rel, src)
        except Exception as e:  # not a picture
            print("  skip", iid, e)
            continue
        got += 1
        print("ok", iid, "<-", path, flush=True)
    print("saved", got)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_catalog.py" if mode == "hw" else "gen_collectibles.py")])


def _relog(rel, url):
    """Log a file, replacing an older line for the same path."""
    for f in ("assets/temp_test/MANIFEST.txt", "assets/sources.txt"):
        p = os.path.join(ROOT, f)
        lines = [ln for ln in open(p, encoding="utf-8").read().splitlines()
                 if not ln.startswith(rel.rsplit(".", 1)[0] + ".")]
        open(p, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    fwa.log(rel, url)


def sheet(mode, cand, out):
    ids = list(cand.keys())
    cw, cols = 150, 10
    img = Image.new("RGB", (cols * cw, ((len(ids) + cols - 1) // cols) * (cw + 26)), (60, 60, 70))
    dr = ImageDraw.Draw(img)
    for k, iid in enumerate(ids):
        x, y = (k % cols) * cw, (k // cols) * (cw + 26)
        fs = ([os.path.join(ROOT, "assets/temp_test/games/%s_photo.%s" % (iid, e)) for e in ("png", "jpg")] if mode == "hw"
              else [os.path.join(ROOT, "assets/temp_test/coins/%s_obv.jpg" % iid)])
        f = next((f for f in fs if os.path.exists(f)), None)
        if f:
            im = Image.open(f).convert("RGBA")
            im.thumbnail((cw - 4, cw - 4))
            bg = Image.new("RGBA", im.size, (215, 215, 222, 255))
            bg.alpha_composite(im)
            img.paste(bg.convert("RGB"), (x + 2, y + 2))
        dr.text((x + 2, y + cw), iid[:24], fill=(255, 255, 160))
        dr.text((x + 2, y + cw + 12), (cand[iid]["hits"][0][1].split("/")[-1][:24] if cand[iid]["hits"] else "-"), fill=(180, 220, 255))
    img.save(out)
    print("sheet", out)


def main():
    a = sys.argv[1:]
    force = "--force" in a
    only = a[a.index("--only") + 1] if "--only" in a else ""
    mode = a[0] if a else "hw"
    steps = [x for x in a[1:] if x in ("find", "save", "sheet")] or ["find", "save"]
    f = os.path.join(CACHE, "pc_%s.json" % mode)
    cand = json.load(open(f)) if os.path.exists(f) else {}
    if "find" in steps:
        cand = find(mode, force and "save" not in steps, only)
    if "save" in steps:
        save(mode, cand, force, only)
    if "sheet" in steps:
        sheet(mode, cand, a[a.index("sheet") + 1])


if __name__ == "__main__":
    main()
