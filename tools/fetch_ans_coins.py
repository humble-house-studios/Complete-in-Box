#!/usr/bin/env python3
"""Real coin photos (obverse AND reverse) from the American Numismatic Society
collection database (numismatics.org/search), for the world and ancient coins
PriceCharting does not list, and any US coin still without a photo (test-only).

    python3 tools/fetch_ans_coins.py [find] [save] [sheet OUT.png] [--force] [--only ID_PART] [--all]

find   searches each coin (name without the year, then with it) and scores
       every result that has photos on its title (name words, year, metal);
       picks in .cache/ans_coins.json. One request every 5 s (the site's
       crawl delay).
save   downloads the pick's obv / rev photos (width350) -> cropped to the
       disc -> assets/temp_test/coins/<id>_obv.jpg / _rev.jpg, logged in
       MANIFEST.txt / sources.txt; reruns gen_collectibles.py.
--all  also replaces coins that only have a front (from PriceCharting).

PICKS pins a result by collection number ("" = keep the painted coin).
"""
import html as htmllib
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fetch_world_art as fwa  # noqa: E402  (log)
import fetch_commons_art as fca  # noqa: E402  (faces, disc, fra_imp)
import fetch_pricecharting as fpc  # noqa: E402  (_relog)

from PIL import Image, ImageDraw  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CACHE = os.path.join(ROOT, ".cache")
SITE = "https://numismatics.org/search/results?q="
UA = "Mozilla/5.0 (CollectorsCurseAssetFetch/1.0; game test assets)"
STOP = {"the", "of", "a", "an", "and", "by", "bc", "ad", "proof", "coin", "set", "year", "great", "s"}
GOLD = {"gold", "aureus", "solidus", "stater", "sovereign", "ducat", "florin", "noble", "angel", "guinea", "guineas", "escudos",
        "doubloon", "dinar", "krugerrand", "maple", "panda", "nugget", "britannia", "eagle", "vreneli", "napoleon"}

# id -> ANS collection number (e.g. "1944.100.12345"), checked by eye, or "" = keep the painted coin.
PICKS = {
    "cent_1793_chain_cent": "1946.143.10", "cent_1836_classic_head_half_cent_pr": "1906.99.31", "silv_1792_half_disme": "1932.51.38",
    "silv_1918_7_s_standing_liberty_quar": "1918.204.2", "silv_1942_1_mercury_dime": "1942.123.5",
    "silv_1878_8_tail_feathers_morgan_do": "1908.93.69", "gold_1856_s_liberty_head_gold_dolla": "",
    "gold_1926_indian_head_eagle": "1926.999.37", "wrld_1898_japan_20_yen": "0000.999.26498",
    "wrld_1967_south_africa_krugerrand": "2023.3.1", "wrld_1979_canada_gold_maple_leaf": "1983.206.1", "wrld_1987_britannia_gold": "",
    "wrld_1898_france_rooster_20_francs": "", "wrld_1898_mexico_cap_and_rays_8_rea": "2023.49.173", "wrld_1971_mexico_peso": "",
    "anct_410_bc_syracuse_decadrachm_by": "1997.9.64", "anct_315_bc_alexander_the_great_gol": "",
    "anct_600_bc_lydia_electrum_stater": "1960.170.369", "anct_340_bc_ephesus_bee_tetradrachm": "0000.999.19117",
    "anct_440_bc_athens_owl_tetradrachm": "1909.999.65", "anct_30_ad_tyre_shekel": "", "anct_1279_edward_i_penny": "1941.131.184",
    "anct_337_constantine_follis": "", "anct_1200_song_dynasty_cash": "1986.160.5", "anct_250_kushan_gold_dinar": "",
    "anct_350_late_roman_bronze": "", "anct_1600_elizabeth_i_sixpence": "1961.8.205", "anct_1820_chinese_cash_coin": "",
    "cent_1918_7_d_buffalo_nickel": "1918.236.1", "cent_1869_9_indian_head_cent": "0000.999.20251",
    "gold_1879_flowing_hair_stella": "1882.1.2", "gold_1796_no_stars_quarter_eagle": "1908.93.246",
    "gold_1874_indian_princess_three_dol": "1908.93.264", "wrld_1839_una_and_the_lion_five_pou": "1946.89.12",
    "wrld_1910_china_long_whisker_dragon": "1932.999.48", "anct_14_ad_tiberius_tribute_penny": "1987.26.133",
    "anct_1000_anglo_saxon_aethelred_pen": "1992.45.1", "anct_66_ad_judaea_shekel_of_year_on": "1944.100.62980",
    "anct_1550_spanish_cob_2_reales": "1969.222.1021", "anct_44_bc_eid_mar_denarius_of_brut": "", "wrld_1966_mexico_hidalgo_10_pesos": "",
    "anct_1066_william_the_conqueror_pen": "",
    # Checked by eye and dropped: a cut fragment, a New Zealand crown, photos with a ruler in the frame.
    "wrld_1652_massachusetts_oak_tree_sh": "", "wrld_1935_great_britain_george_v_ju": "", "anct_1180_crusader_bezant": "",
    "wrld_1808_napoleon_40_francs": "", "wrld_1883_germany_prussia_20_mark": "", "wrld_1872_netherlands_ducat": "",
}

# Better search words where the coin's own name finds nothing.
ALT_Q = {
    "anct_1343_edward_iii_double_leopard": "Edward III leopard", "anct_44_bc_eid_mar_denarius_of_brut": "Brutus denarius",
    "wrld_1902_russia_37_roubles_50_kope": "37 1/2 rouble", "gold_1870_s_indian_princess_three_d": "Gold 3 Dollar 1870",
    "gold_1854_indian_princess_three_dol": "Gold 3 Dollar 1854", "gold_1874_indian_princess_three_dol": "Gold 3 Dollar 1874",
    "gold_1879_flowing_hair_stella": "4 dollar 1879", "gold_1880_coiled_hair_stella": "4 dollar 1880",
    "gold_1796_no_stars_quarter_eagle": "2 1/2 dollar 1796", "gold_1849_mormon_five_dollar": "Mormon 5 dollar",
    "gold_1855_wass_molitor_fifty_dollar": "Wass Molitor", "gold_1915_s_panama_pacific_fifty_do": "Panama-Pacific 50 dollar",
    "gold_1915_s_panama_pacific_quarter": "Panama-Pacific 2 1/2 dollar", "gold_1926_sesquicentennial_quarter": "Sesquicentennial 2 1/2 dollar",
    "gold_1856_s_liberty_head_gold_dolla": "Gold Dollar 1856", "wrld_1937_edward_viii_sovereign": "Edward VIII",
    "wrld_1839_una_and_the_lion_five_pou": "Una and the lion", "wrld_1703_queen_anne_vigo_five_guin": "Anne VIGO",
    "wrld_1825_russia_constantine_rouble": "Constantine rouble", "wrld_1609_spain_segovia_100_escudos": "100 escudo Segovia",
    "wrld_1621_poland_sigismund_iii_100": "Sigismund III 100 ducat", "wrld_1907_mexico_50_pesos_pattern": "50 peso Mexico",
    "wrld_1910_china_long_whisker_dragon": "dollar dragon Xuantong", "wrld_1911_china_chang_tso_lin_dolla": "Zhang Zuolin dollar",
    "wrld_1732_mexico_pillar_8_reales": "8 real Philip V Mexico 1732", "wrld_1714_spain_cob_8_escudos_royal": "8 escudo Philip V 1714",
    "wrld_1853_great_britain_gothic_crow": "crown Victoria 1853", "wrld_1919_italy_vittorio_emanuele_1": "100 lira Vittorio Emanuele III",
    "wrld_1982_china_gold_panda": "panda gold", "wrld_1989_australia_gold_nugget": "nugget Australia gold",
    "wrld_1913_canada_gold_five_dollars": "5 dollar George V Canada", "wrld_1947_mexico_50_pesos_centenario": "50 peso 1947",
    "wrld_1897_russia_nicholas_ii_15_rou": "15 rouble Nicholas II", "wrld_1935_swiss_vreneli_20_francs": "20 franc Switzerland gold",
    "wrld_1890_great_britain_victoria_cr": "crown Victoria 1890", "wrld_1935_great_britain_george_v_ju": "crown George V 1935",
    "wrld_1924_germany_weimar_3_mark": "3 mark Weimar", "wrld_1938_canada_silver_dollar": "dollar George VI Canada 1938",
    "wrld_1953_coronation_crown": "crown Elizabeth II 1953", "wrld_1967_canada_centennial_silver": "dollar Canada 1967",
    "wrld_1969_isle_of_man_crown": "crown Isle of Man", "wrld_1966_mexico_hidalgo_10_pesos": "10 peso 1956 silver Mexico",
    "wrld_1972_bahamas_proof_set_coin": "Bahamas dollar silver", "wrld_1971_mexico_peso": "peso Morelos",
    "wrld_1915_austria_4_ducat_restrike": "4 ducat Franz Joseph", "wrld_1987_britannia_gold": "Britannia Elizabeth II gold",
    "wrld_1898_france_rooster_20_francs": "20 franc Third Republic rooster", "anct_330_constantine_the_great_soli": "Solidus of Constantine I",
    "anct_1066_william_the_conqueror_pen": "penny of William I", "anct_450_bc_aegina_turtle_stater": "Stater Aegina",
    "anct_66_ad_judaea_shekel_of_year_on": "shekel Jewish War", "anct_14_ad_tiberius_tribute_penny": "Denarius of Tiberius",
    "anct_1000_anglo_saxon_aethelred_pen": "penny of Aethelred II", "anct_1500_ottoman_akce": "akce",
    "anct_300_bc_carthage_horse_shekel": "Carthage shekel", "anct_1100_byzantine_anonymous_folli": "Anonymous follis",
    "anct_1550_spanish_cob_2_reales": "2 real Philip II", "anct_315_bc_alexander_the_great_gol": "Stater of Alexander III",
    "anct_325_bc_alexander_the_great_tet": "Tetradrachm of Alexander III", "anct_337_constantine_follis": "Follis of Constantine I",
    "anct_30_ad_tyre_shekel": "shekel Tyre", "anct_250_kushan_gold_dinar": "Dinar Kushan", "anct_350_late_roman_bronze": "Constantius II",
    "anct_1180_crusader_bezant": "bezant", "cent_1918_7_d_buffalo_nickel": "5 cent 1918", "cent_1869_9_indian_head_cent": "Cent 1869",
    "cent_1995_doubled_die_lincoln_cent": "Cent 1995", "cent_1939_doubled_monticello_nickel": "5 cent 1939",
}


def get(url, pause=5.0):
    time.sleep(pause)
    for k in range(4):
        r = subprocess.run(["curl", "-sS", "-L", "-m", "60", "-A", UA, "-w", "\n%{http_code}", url], capture_output=True)
        body, _, code = r.stdout.rpartition(b"\n")
        if code.strip() == b"200":
            return body
        if code.strip() in (b"404", b"400"):
            return b""
        print("  http", code.strip().decode(), url[:80], flush=True)
        time.sleep(20 + k * 30)
    return b""


def results(q):
    """[(number, title, date, obv url, rev url)] of results with photos."""
    h = get(SITE + urllib.parse.quote(q)).decode("utf-8", "ignore")
    out = []
    for doc in h.split('<div class="row result-doc">')[1:]:
        m = re.search(r'collection/([0-9A-Za-z.]+)">([^<]+)</a>', doc)
        obv = re.search(r'href="(https://numismatics\.org/collectionimages/[^"]+\.obv\.width350\.jpg)"', doc)
        rev = re.search(r'href="(https://numismatics\.org/collectionimages/[^"]+\.rev\.width350\.jpg)"', doc)
        if not m or not obv:
            continue
        dt = re.search(r"<dt>Date</dt><dd>([^<]*)</dd>", doc)
        out.append((m.group(1), htmllib.unescape(m.group(2)), dt.group(1) if dt else "", obv.group(1), rev.group(1) if rev else ""))
    return out


def words(s):
    s = s.lower().replace("é", "e").replace("ä", "a").replace("ö", "o")
    return [w for w in re.findall(r"[a-z]+", s) if w not in STOP and len(w) > 1]


def queries(d):
    name = d["name"]
    core = re.sub(r"^\d+\s*(BC|AD)?\s*", "", name)
    core = re.sub(r"^\d{4}(/\d)?(-[A-Z]+)?\s*", "", core)
    core = re.sub(r"\b(Proof|Set Coin|Pattern|Restrike)\b", "", core)
    core = re.sub(r"^\S*\d\S*\s+", "", core)  # what is left of a date (/7-S)
    core = re.sub(r"\s+", " ", re.sub(r"[^A-Za-z0-9 ]+", " ", core)).strip()
    qs = [core]
    if d["id"] in ALT_Q:
        qs = [ALT_Q[d["id"]]]
    elif d["year"] > 0:
        qs.append("%s %d" % (core, d["year"]))
    return qs


def score(d, r):
    num, title, date, obv, rev = r
    t = set(words(title))
    want = [w for w in words(re.sub(r"^\d+\s*(BC|AD)?\s*", "", d["name"]))]
    if not want:
        return -99
    s = 0.0
    for w in want:
        s += 3 if w in t or any(x.startswith(w[:5]) for x in t if len(w) > 5) else -1.5
    y = abs(int(d["year"]))
    yrs = [int(x) for x in re.findall(r"\b(\d{3,4})\b", title + " " + date)]
    if d["year"] > 1000 and yrs:
        s += 4 if y in yrs else (1 if any(abs(y - z) <= 5 for z in yrs) else -2)
    metal = d["metal"].lower()
    if "gold" in title.lower() and "gold" not in metal and "electrum" not in metal:
        s -= 4
    if "silver" in title.lower() and "gold" in metal:
        s -= 4
    if "gold" in metal and "gold" in title.lower():
        s += 2
    if rev:
        s += 1
    return s


def coins(only):
    import gen_collectibles as gc
    return [d for d in gc.coin_items(gc.parse(gc.COINS)) if not only or only in d["id"]]


def have(iid, side):
    return os.path.exists(os.path.join(ROOT, "assets/temp_test/coins/%s_%s.jpg" % (iid, side)))


def find(force, only):
    f = os.path.join(CACHE, "ans_coins.json")
    cand = json.load(open(f)) if os.path.exists(f) else {}
    for d in coins(only):
        iid = d["id"]
        redo = "--alt" in sys.argv and iid in ALT_Q and iid not in PICKS
        if iid in cand and not force and not redo:
            continue
        if have(iid, "obv") and ("--all" not in sys.argv or have(iid, "rev")):
            continue
        seen = {}
        for q in queries(d):
            for r in results(q):
                seen[r[0]] = r
            if any(score(d, r) >= 8 for r in seen.values()):
                break
        scored = sorted(((score(d, r), r) for r in seen.values()), key=lambda x: -x[0])
        cand[iid] = {"name": d["name"], "hits": [[s] + list(r) for s, r in scored[:5]]}
        print("%-38s %s" % (iid, ("%5.1f %s | %s" % (scored[0][0], scored[0][1][1][:70], scored[0][1][2])) if scored else "-"), flush=True)
        os.makedirs(CACHE, exist_ok=True)
        json.dump(cand, open(f, "w"), indent=1)
    return cand


def save(cand, force, only):
    got = 0
    for iid, c in cand.items():
        if only and only not in iid:
            continue
        if have(iid, "rev") and not force:
            continue
        pick = PICKS.get(iid)
        hits = c["hits"]
        if pick is not None:
            hits = [h for h in hits if h[1] == pick]
        elif hits and hits[0][0] < 7:
            hits = []
        if not hits:
            continue
        h = hits[0]
        for side, url in (("obv", h[4]), ("rev", h[5])):
            if not url:
                continue
            data = get(url, pause=1.0)
            if not data:
                continue
            try:
                im = fca.faces(data)[0]
            except Exception as e:  # not a picture
                print("  skip", iid, side, e)
                continue
            rel = "assets/temp_test/coins/%s_%s.jpg" % (iid, side)
            os.makedirs(os.path.dirname(os.path.join(ROOT, rel)), exist_ok=True)
            im.save(os.path.join(ROOT, rel), quality=86, optimize=True)
            fca.fra_imp(os.path.join(ROOT, rel))
            fpc._relog(rel, "http://numismatics.org/collection/" + h[1])
        got += 1
        print("ok", iid, "<-", h[1], h[2][:60], flush=True)
    print("saved", got)
    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "gen_collectibles.py")])


def sheet(cand, out):
    ids = list(cand.keys())
    cw, cols = 150, 8
    img = Image.new("RGB", (cols * cw, ((len(ids) + cols - 1) // cols) * (cw // 2 + 40)), (60, 60, 70))
    dr = ImageDraw.Draw(img)
    for k, iid in enumerate(ids):
        x, y = (k % cols) * cw, (k // cols) * (cw // 2 + 40)
        for j, side in enumerate(("obv", "rev")):
            f = os.path.join(ROOT, "assets/temp_test/coins/%s_%s.jpg" % (iid, side))
            if os.path.exists(f):
                im = Image.open(f).convert("RGB")
                im.thumbnail((cw // 2 - 2, cw // 2 - 2))
                img.paste(im, (x + 1 + j * cw // 2, y + 1))
        dr.text((x + 2, y + cw // 2 + 2), iid[5:28], fill=(255, 255, 160))
        h = cand[iid]["hits"]
        dr.text((x + 2, y + cw // 2 + 14), (h[0][2][:26] if h else "-"), fill=(180, 220, 255))
    img.save(out)
    print("sheet", out)


def main():
    a = sys.argv[1:]
    force = "--force" in a
    only = a[a.index("--only") + 1] if "--only" in a else ""
    steps = [x for x in a if x in ("find", "save", "sheet")] or ["find", "save"]
    f = os.path.join(CACHE, "ans_coins.json")
    cand = json.load(open(f)) if os.path.exists(f) else {}
    if "find" in steps:
        cand = find(force and "save" not in steps, only)
    if "save" in steps:
        save(cand, force, only)
    if "sheet" in steps:
        sheet(cand, a[a.index("sheet") + 1])


if __name__ == "__main__":
    main()
