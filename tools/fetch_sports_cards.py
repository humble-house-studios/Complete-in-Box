#!/usr/bin/env python3
"""Real sports card scans, FRONT and BACK, for the sports world (test-only).

    python3 tools/fetch_sports_cards.py [crawl] [save] [sheet OUT.png] [--force]

Source: The Cardboard Connection (cardboardconnection.com). Its set reviews
("1986-87 Fleer Basketball Cards") and player guides ("Michael Jordan Rookie
Cards") show the key cards as real scans, usually front AND back
("...-Michael-Jordan-57-RC-...-back.jpg"), hosted on cconnect.s3.amazonaws.com.

  crawl  visits likely set / player pages for every line of
         docs/research/sports_cards_top_250.txt (pages cached in
         .cache/cardboard/, the site 503s if you go fast: ~6 s per page) and
         scores every card picture by its file name (surname, year, set words,
         card number; "back" = the back). Wax lines look for the box / pack.
  save   downloads the best front + back into assets/temp_test/sports/
         <id>_scan.jpg / <id>_back.jpg (card shape, 360 tall, lossy import),
         logs them, then reruns gen_worlds.py sports ("scan" / "back" fields).
  sheet  a contact sheet of what was picked, to check by eye.

PICKS below pins a file by hand when the scoring is wrong (or "" = none).
"""
import datetime
import io
import json
import os
import re
import subprocess
import sys
import time
import unicodedata

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_worlds  # noqa: E402

from PIL import Image, ImageChops, ImageDraw  # noqa: E402

ROOT = gen_worlds.ROOT
SITE = "https://www.cardboardconnection.com/"
CACHE = os.path.join(ROOT, ".cache", "cardboard")
UA = "Mozilla/5.0 (CollectorsCurseAssetFetch/1.0; game test assets)"
H = 360
ASPECT = 2.5 / 3.5
SPORT = {"BASE": "baseball", "HOOP": "basketball", "GRID": "football", "PUCK": "hockey", "FUTB": "soccer"}
SPLIT_SEASON = ("HOOP", "PUCK")
CAND = os.path.join(CACHE, "candidates.json")

# id -> {"front": url or "", "back": url or "", "pages": [extra slugs to crawl]}
# Library of Congress (Benjamin K. Edwards collection) has T206 fronts and backs.
LOC = "https://tile.loc.gov/storage-services/service/pnp/bbc/"
PICKS = {
    "base_ty_kobb_1909": {"front": LOC + "0900/0930/0939fv.jpg", "back": LOC + "0900/0930/0939bv.jpg"},
}


def ascii_slug(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode()
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")


def get(url, binary=False, tries=4):
    for k in range(tries):
        r = subprocess.run(["curl", "-sS", "-L", "-m", "60", "-A", UA, "-w", "\n%{http_code}", url], capture_output=True)
        body, _, code = r.stdout.rpartition(b"\n")
        code = code.decode().strip()
        if code == "200":
            return body
        if code == "404":
            return b""
        time.sleep(15 + k * 20)
    return b""


def page(slug):
    """A site page, cached. Returns its HTML ('' = missing)."""
    os.makedirs(CACHE, exist_ok=True)
    f = os.path.join(CACHE, slug.replace("/", "_") + ".html")
    if os.path.exists(f):
        return open(f, encoding="utf-8", errors="ignore").read()
    time.sleep(4)
    html = get(SITE + slug).decode("utf-8", "ignore")
    open(f, "w", encoding="utf-8").write(html)
    print("  page", slug, "ok" if html else "-", flush=True)
    return html


def images(html):
    out = set()
    for u in re.findall(r'https?://[^"\'\s>]+?/wp-content/uploads/[^"\'\s>]+?\.(?:jpe?g|png)', html, re.I):
        u = re.sub(r"-\d+x\d+(\.\w+)$", r"\1", u)
        u = u.replace("https://www.cardboardconnection.com/", "https://cconnect.s3.amazonaws.com/")
        if "-thumb-" in u.lower():
            continue
        out.add(u)
    return out


def season(r):
    y = r["year"]
    return "%d-%02d" % (y, (y + 1) % 100) if r["code"] in SPLIT_SEASON else str(y)


def set_slug(r):
    s = r["detail"].split("#")[0]
    s = re.sub(r"\b(rookie patch auto|patch auto|auto|rc|red portrait|superfractor.*|championship ticket.*|young guns|series \d|scoring leader|sticker)\b", "", s, flags=re.I)
    return ascii_slug(s)


def players(r):
    """Player names on the line (Bird / Magic / Erving = three)."""
    return [p.strip() for p in re.split(r"/|&", r["name"]) if p.strip()]


INDEX = os.path.join(CACHE, "index.json")  # set-review slugs from the site's category pages


def slugs(r):
    sp = SPORT[r["code"]]
    st = set_slug(r)
    se = season(r)
    out = []
    if os.path.exists(INDEX) and st:
        words = [w for w in st.split("-") if w]
        known = [k for k in json.load(open(INDEX)) if k.startswith(se + "-") or k.startswith(str(r["year"]) + "-")]
        hits = [k for k in known if all(w in k.split("-") for w in words)]
        hits = [k for k in hits if sp in k or not any(o in k for o in SPORT.values())]
        hits.sort(key=lambda k: (("review" in k) or ("box" in k), len(k)))
        out += hits[:3]
    if st:
        out += ["%s-%s-%s-cards" % (se, st, sp), "%s-%s-%s" % (se, st, sp), "%s-%s-cards" % (se, st)]
        if se != str(r["year"]):
            out.append("%s-%s-%s-cards" % (r["year"], st, sp))
    if r["kind"] != "wax":
        for p in players(r)[:1]:
            ps = ascii_slug(p)
            out += ["%s-rookie-cards" % ps, "%s-%s-cards-rookie-cards-checklist-and-buying-guide" % (ps, sp),
                    "%s-cards-rookie-cards-checklist-and-buying-guide" % ps, "%s-rookie-card-checklist" % ps,
                    "top-10-%s-cards" % ps, "top-10-%s-rookie-cards" % ps, "top-%s-cards" % ps]
    return out


def tokens(u):
    name = os.path.basename(u).rsplit(".", 1)[0]
    return ascii_slug(name).split("-")


def score(r, u):
    """(front score, is back) for a picture of line r; None = not this card."""
    t = tokens(u)
    tl = "-".join(t)
    yr = str(r["year"])
    y2 = season(r).split("-")[-1] if r["code"] in SPLIT_SEASON else ""
    s = 0
    if r["kind"] == "wax":
        if not any(w in t for w in ("box", "wax", "pack", "packs", "wrapper", "hobby", "sealed")):
            return None
        s += 3 if yr in t else -5
        for w in ascii_slug(set_slug(r)).split("-"):
            if w and w in t:
                s += 2
        return s, False
    sur = ascii_slug(players(r)[0].split()[-1].replace(".", "")).split("-")[-1]
    if r["name"].startswith("Bird"):
        sur = "bird"
    if sur not in t and not (sur in tl):
        return None
    if any(w in t for w in ("box", "wrapper", "pack", "packs", "lot", "logo", "graph", "chart")):
        return None
    s += 4
    s += 4 if yr in t else (-6 if any(re.fullmatch(r"(19|20)\d\d", x) and x != yr for x in t) else 0)
    if y2 and y2 in t:
        s += 1
    for w in set_slug(r).split("-"):
        if len(w) > 2 and w in t:
            s += 2
    num = re.search(r"#\s*(\w+)", r["detail"])
    if num and num.group(1).lower() in t:
        s += 3
    if "rc" in t or "rookie" in t:
        s += 1 if "rc" in r["tags"] else 0
    for w in ("auto", "autograph", "patch", "refractor", "parallel", "variation", "insert", "printing", "plate", "jersey", "relic"):
        if w in t and w not in r["detail"].lower():
            s -= 2
    return s, ("back" in t or "reverse" in t and "negative" not in t)


def crawl(force=False):
    conf = gen_worlds.load_conf("sports")
    rows = gen_worlds.parse(os.path.join(ROOT, "docs", "research", conf.LIST))
    items = gen_worlds.build("sports")
    by = {(d["plat"], d["rank"]): d for d in items}
    cand = json.load(open(CAND)) if os.path.exists(CAND) and not force else {}
    for r in rows:
        d = by[(r["code"], r["rank"])]
        iid = d["id"]
        if iid in cand and not force:
            continue
        print(iid, flush=True)
        seen = {}
        todo = slugs(r) + PICKS.get(iid, {}).get("pages", [])
        visited = set()
        hops = 0
        while todo:
            sl = todo.pop(0)
            if sl in visited:
                continue
            visited.add(sl)
            html = page(sl)
            if not html:
                continue
            for u in images(html):
                sc = score(r, u)
                if sc is not None:
                    seen[u] = sc
            # Good enough: a strong front and a back -> stop crawling this line.
            if any(v[0] >= 11 and not v[1] for v in seen.values()) and (r["kind"] == "wax" or any(v[1] and v[0] >= 8 for v in seen.values())):
                break
            # One hop into linked guides / set pages about this card.
            if hops < 4 and r["kind"] != "wax":
                sur = ascii_slug(players(r)[0]).split("-")[-1]
                for link in re.findall(r'href="https://www\.cardboardconnection\.com/([a-z0-9-]+)"', html):
                    if link in visited or link in todo:
                        continue
                    if (sur in link and ("rookie" in link or "cards" in link)) or (str(r["year"]) in link and set_slug(r) and set_slug(r) in link):
                        todo.append(link)
                        hops += 1
                        if hops >= 4:
                            break
        fronts = sorted([(v[0], u) for u, v in seen.items() if not v[1]], reverse=True)
        backs = sorted([(v[0], u) for u, v in seen.items() if v[1]], reverse=True)
        cand[iid] = {"fronts": fronts[:8], "backs": backs[:8]}
        print("  ->", fronts[0] if fronts else "-", "|", backs[0] if backs else "-", flush=True)
        json.dump(cand, open(CAND, "w"), indent=1)
    return cand


BRANDS = {"topps", "chee", "opc", "bowman", "fleer", "upper", "donruss", "score", "leaf", "goudey", "parkhurst", "panini",
          "prizm", "chrome", "sp", "playoff", "contenders", "exquisite", "treasures", "hoops", "skybox", "megacracks", "traded",
          "gold", "finest", "stadium", "ultra"}


def same_card(front, back):
    """A back only counts when it names the same year and maker as the front."""
    a, b = set(tokens(front)), set(tokens(back))
    years = lambda t: {x for x in t if re.fullmatch(r"(19|20)\d\d", x)}
    return years(a) == years(b) and (a & BRANDS) == (b & BRANDS)


def pick(iid, c):
    p = PICKS.get(iid, {})
    f = p.get("front", c["fronts"][0][1] if c["fronts"] and c["fronts"][0][0] >= 6 else "")
    b = p.get("back", "")
    if "back" not in p and f and c["backs"]:
        # The back that matches the front's file name best.
        stem = set(tokens(f))
        same = [sb for sb in c["backs"] if same_card(f, sb[1])]
        if same:
            best = max(same, key=lambda sb: (len(stem & set(tokens(sb[1]))), sb[0]))
            if best[0] >= 6 or len(stem & set(tokens(best[1]))) >= 4:
                b = best[1]
    return f, b


def trim(im):
    """Cuts a flat background (white / black / grey) off the scan's edges."""
    bg = Image.new(im.mode, im.size, im.getpixel((2, 2)))
    diff = ImageChops.difference(im, bg).convert("L").point(lambda v: 255 if v > 28 else 0)
    bb = diff.getbbox()
    if bb and (bb[2] - bb[0]) * (bb[3] - bb[1]) > im.size[0] * im.size[1] * 0.35:
        im = im.crop(bb)
    return im


def save_card(data, path):
    im = Image.open(io.BytesIO(data))
    if im.mode in ("RGBA", "LA", "P"):
        im = im.convert("RGBA")
        bg = Image.new("RGBA", im.size, (255, 255, 255, 255))
        bg.alpha_composite(im)
        im = bg
    im = trim(im.convert("RGB"))
    w, h = im.size
    if w > h * 1.1:  # sideways card (most backs): stand it up
        im = im.rotate(90, expand=True)
        w, h = im.size
    ar = w / h
    if ar > ASPECT:
        nw = int(h * ASPECT)
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = int(w / ASPECT)
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im = im.resize((int(round(H * ASPECT)), H), Image.LANCZOS)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path, quality=86, optimize=True)
    imp = path + ".import"
    if not os.path.exists(imp):
        open(imp, "w").write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
                             '[params]\n\ncompress/mode=1\ncompress/lossy_quality=0.8\n')


def log(rel, url):
    day = datetime.date.today().isoformat()
    for f in ("assets/temp_test/MANIFEST.txt", "assets/sources.txt"):
        p = os.path.join(ROOT, f)
        old = open(p, encoding="utf-8").read() if os.path.exists(p) else ""
        lines = [ln for ln in old.splitlines() if not ln.startswith(rel + " |")]
        lines.append("%s | %s" % (rel, url) + ("" if "MANIFEST" in f else " | %s" % day))
        open(p, "w", encoding="utf-8").write("\n".join(lines) + "\n")


def save_all(cand, force=False):
    out = os.path.join(ROOT, "assets", "temp_test", "sports")
    got = 0
    for iid, c in cand.items():
        f, b = pick(iid, c)
        for kind, url in (("scan", f), ("back", b)):
            rel = "assets/temp_test/sports/%s_%s.jpg" % (iid, kind)
            dst = os.path.join(ROOT, rel)
            if not url:
                continue
            if os.path.exists(dst) and not force:
                continue
            time.sleep(1)
            data = get(url, True)
            if not data:
                print("  miss", iid, kind, url)
                continue
            try:
                save_card(data, dst)
            except Exception as e:  # not an image
                print("  skip", iid, kind, e)
                continue
            # The old painted-frame scan (png) gives way to the real card.
            old = os.path.join(out, "%s_%s.png" % (iid, kind))
            for o in (old, old + ".import"):
                if os.path.exists(o):
                    os.remove(o)
            log(rel, url)
            got += 1
        print(iid, "front" if f else "-", "back" if b else "-")
    print("saved", got)
    gen_worlds.build("sports")


def sheet(cand, path):
    out = os.path.join(ROOT, "assets", "temp_test", "sports")
    ids = list(cand.keys())
    cw, ch = 130, 182
    cols = 10
    rows = (len(ids) + cols // 2 - 1) // (cols // 2)
    img = Image.new("RGB", (cols * cw, rows * (ch + 16)), (40, 40, 48))
    dr = ImageDraw.Draw(img)
    for k, iid in enumerate(ids):
        x = (k % (cols // 2)) * 2 * cw
        y = (k // (cols // 2)) * (ch + 16)
        for j, kind in enumerate(("scan", "back")):
            f = os.path.join(out, "%s_%s.jpg" % (iid, kind))
            if os.path.exists(f):
                im = Image.open(f).convert("RGB").resize((cw - 4, ch - 4))
                img.paste(im, (x + j * cw + 2, y + 2))
        dr.text((x + 2, y + ch), iid[:34], fill=(255, 255, 200))
    img.save(path)
    print("sheet", path)


def main():
    a = sys.argv[1:]
    force = "--force" in a
    cand = crawl(force and "crawl" in a) if ("crawl" in a or not os.path.exists(CAND)) else json.load(open(CAND))
    if "save" in a or not a or a == ["--force"]:
        save_all(cand, force)
    if "sheet" in a:
        sheet(cand, a[a.index("sheet") + 1])


if __name__ == "__main__":
    main()
