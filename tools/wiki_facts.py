#!/usr/bin/env python3
"""Real facts for every catalog item, from its Wikipedia article.

Wikipedia's API throttles cloud sessions hard, so the text comes from bulk dumps
instead (no rate limits), in this order:

    python3 tools/wiki_facts.py hf        # stream the Wikipedia text dump (HF wikimedia/wikipedia, 41 parquet, ~7 min)
    python3 tools/wiki_facts.py resolve   # Wikipedia search run by Wikidata's servers, for names that aren't a title
    python3 tools/wiki_facts.py hf        # again (delete .cache/hf/*.done first) for the titles search found
    curl -sSL -o .cache/sw.zip https://huggingface.co/datasets/wikimedia/structured-wikipedia/resolve/main/20240916.en/enwiki_namespace_0.zip
    python3 tools/wiki_facts.py sw        # Wikimedia's structured dump (18 GB zip): infoboxes + sections
    python3 tools/wiki_facts.py boil      # pick the best article per item + Wikidata stats -> tools/wiki/<world>.json
    python3 tools/wiki_facts.py build     # -> scripts/data/facts_<world>.gd (tools/wiki_build.py)
    python3 tools/wiki_facts.py show ID   # one item's facts

Worlds: games (retro games + hardware), cards (TCG cards + packs), coins, sports, comics, books, vinyl.
Each item has candidate titles (its real name from the research lists, "(video game)",
search hits...); cards and coins without their own page fall back to a family
article (the Pokemon species, Power Nine, Barber coinage...) marked "shared", and
the builder then spreads different sentences over the items sharing it. Caches
live in .cache/ (gitignored); tools/wiki/*.json is committed so build needs no
network. (fetch / dbp = the old Wikipedia API and DBpedia paths, kept for the
few full wikitext articles already cached.)
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(HERE)
CACHE = os.path.join(ROOT, ".cache", "wiki")
DATA = os.path.join(HERE, "wiki")
UA = "CollectorsCurseFacts/1.0 (game item trivia)"
API = "https://en.wikipedia.org/w/api.php"
WORLDS = ["games", "cards", "coins", "sports", "comics", "books", "vinyl"]


# ------------------------------------------------------------------ items
def _strip_paren(s):
    return re.sub(r"\s*\([^)]*\)\s*$", "", s).strip()


def items(world):
    """[{id, kind, plat, real, cands, need, subs}] for one world."""
    out = []
    if world == "games":
        import gen_catalog
        import fetch_retro_art as fra
        _, _, real, _, _ = gen_catalog.collect()
        for iid, (title, plat, kind) in real.items():
            t = title.strip()
            base = _strip_paren(t)
            c = []
            if kind == "game":
                base2 = re.sub(r"\s+(Gray|Gold|Grey)?\s*Cartridge$", "", base)
                base2 = re.sub(r"\s+(19|20)\d\d$", "", base2)
                for b in dict.fromkeys([base, base2]):
                    c += [b + " (video game)", b]
                for b in dict.fromkeys([base, base2]):
                    c += ["The " + b, b.replace(" - ", ": ")]
                if ":" in base:
                    c.append(base.split(":")[0].strip() + " (video game)")
                need = ["video game", "Infobox video game", "Infobox VG", " game", "Game"]
            else:
                art = fra.hw_article(t)
                if art:
                    c.append(art)
                c += [base, re.sub(r"\s+(Model \d|SCPH-\d+|\(.*\))$", "", base)]
                need = ["console", "controller", "Nintendo", "Sega", "Sony", "Atari", "accessory", "peripheral", "Microsoft", "game"]
            out.append({"id": iid, "kind": kind, "plat": plat, "real": t, "cands": list(dict.fromkeys(c)), "need": need})
    elif world in ("cards", "coins"):
        import gen_collectibles as gc
        if world == "cards":
            ds = gc.card_items(gc.parse(gc.CARDS))
        else:
            rows = gc.parse(gc.COINS)
            ds = gc.coin_items(rows)
            for d, r in zip(ds, rows):
                gc.REAL[d["id"]] = r
        for d in ds:
            r = gc.REAL.get(d["id"])
            if r is None:
                continue
            name = r["name"]
            c = []
            if world == "cards":
                core = re.sub(r"\s+(Full Art|Enchanted|Loot Card|Starter|Booster Box|Booster Pack|Starter Deck|Theme Deck|Elite Trainer Box|Collection)$", "", name)
                core = re.sub(r"^(Gold Star|Shining|Dark|Light|1st Edition)\s+", "", core) if d["kind"] == "card" else core
                c += [name, core, core + " (Pokémon)", core + " (Magic: The Gathering)", core + " (card)"]
                need = ["Pokémon", "Magic", "Yu-Gi-Oh", "card", "Duel", "trading"]
            else:
                y = re.match(r"^(-?\d+)(?:/\d)?(-[A-Z]+)?\s+(BC\s+|AD\s+)?(.*)$", name)
                rest = y.group(4) if y else name
                rest = re.sub(r"^(Doubled Die|Proof|High Relief|Ultra High Relief|Pattern)\s+", "", rest)
                low = re.sub(r"\b(Cent|Penny|Nickel|Dime|Quarter|Half Dollar|Dollar|Eagle|Double Eagle|Half Eagle|Quarter Eagle|Half Dime|Disme|Half Disme|Sovereign|Shilling|Mark|Pesos|Ducat|Tetradrachm|Decadrachm|Shekel|Angel|Reales|Sestertius|Sixpence|Gold Dollar|Three-Dollar Piece|Trade Dollar)\b",
                             lambda m: m.group(1).lower(), rest)
                yr = y.group(1) if y else ""
                dn = re.search(r"\b(double eagle|half eagle|quarter eagle|eagle|half dollar|trade dollar|dollar|cent|nickel|dime|quarter|half disme|disme)$", low)
                c += [name, (yr + " " + low).strip(), low]
                if dn and yr:
                    c.append(yr + " " + dn.group(1))
                c += [rest]
                need = ["coin", "mint", "Mint", "struck", "numismat"]
            fb = _card_family(name, d, r) if world == "cards" else _coin_family(name, r)
            out.append({"id": d["id"], "kind": d["kind"], "plat": d["plat"], "real": name, "cands": list(dict.fromkeys(c)), "need": need, "family": fb,
                        "row": r})
    else:
        import gen_worlds
        conf = gen_worlds.load_conf(world)
        rows = gen_worlds.parse(os.path.join(ROOT, "docs", "research", conf.LIST))
        pages = {}
        for r in rows:
            pages.setdefault(r["code"], []).append(r)
        ids = set()
        need = {"sports": ["player", "baseball", "basketball", "football", "hockey", "soccer", "sport", "card"],
                "comics": ["comic", "Comic"], "books": ["novel", "book", "Book", "published", "poem", "edition"],
                "vinyl": ["album", "single", "song", "record", "Album", "Single"]}[world]
        for r in rows:
            tier, frac = gen_worlds.tier_of(pages[r["code"]], r, conf.GRAILS.get(r["code"], 1))
            d = conf.make_item(r, tier, frac, {"h": gen_worlds.h, "slug": gen_worlds.slug, "base_for": gen_worlds.base_for})
            iid = d["id"]
            k = 2
            while iid in ids:
                iid = "%s_%d" % (d["id"], k)
                k += 1
            ids.add(iid)
            c = [t.strip() for t in r["wiki"].split(";") if t.strip()]
            if world == "vinyl" and r["kind"] != "crate":
                c += [r["name"] + " (album)", r["name"] + " (song)", r["name"]]
            if world == "books" and r["kind"] != "booklot":
                c += [r["name"] + " (novel)", r["name"]]
            out.append({"id": iid, "kind": d["kind"], "plat": d["plat"], "real": r["name"], "cands": list(dict.fromkeys(c)), "need": need,
                        "row": r, "def": d})
    found = _found()
    for it in out:
        it["cands"] = [c for c in it["cands"] if len(c) > 2] + found.get(it["id"], [])
    return out


POWER_NINE = {"Black Lotus", "Ancestral Recall", "Time Walk", "Timetwister", "Mox Pearl", "Mox Sapphire", "Mox Jet", "Mox Ruby", "Mox Emerald"}
DUALS = {"Volcanic Island", "Underground Sea", "Tropical Island", "Scrubland", "Badlands", "Bayou", "Plateau", "Savannah", "Taiga", "Tundra"}
ALT_GAME = [("Lord of the Rings", "The Lord of the Rings Trading Card Game"), ("One Ring", "The Lord of the Rings Trading Card Game"),
            ("Lorcana", "Disney Lorcana"), ("Elsa", "Disney Lorcana"), ("World of Warcraft", "World of Warcraft Trading Card Game"),
            ("Spectral Tiger", "World of Warcraft Trading Card Game"), ("Final Fantasy", "Final Fantasy Trading Card Game"),
            ("Bahamut", "Final Fantasy Trading Card Game"), ("Vanguard", "Cardfight!! Vanguard"), ("Neopets", "Neopets Trading Card Game"),
            ("Dragon Ball", "Dragon Ball Super Card Game"), ("Goku", "Dragon Ball Super Card Game"), ("One Piece", "One Piece Card Game"),
            ("Luffy", "One Piece Card Game"), ("Digimon", "Digimon Card Game"), ("Flesh and Blood", "Flesh and Blood (card game)"),
            ("Star Wars", "Star Wars Customizable Card Game"), ("Weiss", "Weiß Schwarz"), ("Duel Masters", "Duel Masters Trading Card Game"),
            ("MetaZoo", "MetaZoo"), ("Marvel", "Marvel Snap"), ("Keyforge", "KeyForge"), ("Vampire", "Vampire: The Eternal Struggle")]


def _card_family(name, d, r):
    """Shared articles for a card without its own page: its species / set / game."""
    plat = d["plat"]
    out = []
    if plat == "CRIT":
        sp = re.sub(r"^(Gold Star|Shining|Dark|Light|Crystal|Team Rocket's|Misty's|Brock's|Sabrina's|Blaine's|Giovanni's|Lt\. Surge's|Erika's|Koga's)\s+", "", name)
        sp = re.sub(r"\s+(ex|EX|GX|V|VMAX|VSTAR|δ|Star|LV\.X|Prime|BREAK|Alternate Art|Special Illustration|Full Art|with .*|Illustrator|Family Event Trophy|Trophy|Promo)(\s.*)?$", "", sp)
        out += [sp, sp + " (Pokémon)", "Pokémon Trading Card Game"]
    elif plat == "MAGI":
        if name in POWER_NINE:
            out.append("Power Nine")
        if name in DUALS:
            out += ["Dual land", "Land (Magic: The Gathering)"]
        out += ["Magic: The Gathering core sets, 1993–2007", "Magic: The Gathering"]
    elif plat == "YUGI":
        out += ["Yu-Gi-Oh! Trading Card Game"]
    else:
        for k, v in ALT_GAME:
            if k in name or k in r.get("detail", ""):
                out.append(v)
                break
    return out


COIN_SERIES = [("Saint-Gaudens", "Saint-Gaudens double eagle"), ("Indian Head Eagle", "Indian Head eagle"), ("Indian Head Half Eagle", "Indian Head gold pieces"),
               ("Indian Head Quarter Eagle", "Indian Head gold pieces"), ("Liberty Head Double Eagle", "Double eagle"), ("Liberty Head Eagle", "Eagle (United States coin)"),
               ("Coronet", "Coronet head"), ("Liberty Head Nickel", "Liberty Head nickel"), ("Liberty Nickel", "Liberty Head nickel"),
               ("Buffalo Nickel", "Buffalo nickel"), ("Jefferson Nickel", "Jefferson nickel"), ("Shield Nickel", "Shield nickel"),
               ("Lincoln Cent", "Lincoln cent"), ("Wheat Penny", "Lincoln cent"), ("Indian Head Cent", "Indian Head cent"), ("Flying Eagle", "Flying Eagle cent"),
               ("Large Cent", "Large cent (United States coin)"), ("Half Cent", "Half cent (United States coin)"), ("Two Cent", "Two-cent piece (United States)"),
               ("Three Cent", "Three-cent piece"), ("Draped Bust Cent", "Draped Bust"), ("Classic Head", "Classic Head"), ("Braided Hair", "Braided Hair"),
               ("Booby Head", "Coronet large cent"), ("Morgan Dollar", "Morgan dollar"), ("Peace Dollar", "Peace dollar"), ("Trade Dollar", "Trade dollar (United States coin)"),
               ("Eisenhower Dollar", "Eisenhower dollar"), ("Seated Liberty Dollar", "Seated Liberty dollar"), ("Gobrecht", "Gobrecht dollar"),
               ("Flowing Hair Silver Dollar", "Flowing Hair dollar"), ("Flowing Hair Half Dime", "Flowing Hair"), ("Draped Bust Dollar", "Draped Bust dollar"),
               ("Barber Dime", "Barber coinage"), ("Barber Quarter", "Barber coinage"), ("Barber Half", "Barber coinage"), ("Mercury Dime", "Mercury dime"),
               ("Roosevelt Dime", "Roosevelt dime"), ("Seated Liberty", "Seated Liberty coinage"), ("Seated", "Seated Liberty coinage"),
               ("Standing Liberty Quarter", "Standing Liberty quarter"), ("Washington Quarter", "Washington quarter"), ("Walking Liberty", "Walking Liberty half dollar"),
               ("Franklin Half", "Franklin half dollar"), ("Kennedy Half", "Kennedy half dollar"), ("Capped Bust Half Dollar", "Capped Bust half dollar"),
               ("Capped Bust", "Capped Bust"), ("Twenty Cent", "Twenty-cent piece (United States coin)"), ("Half Disme", "Half disme"), ("Disme", "Disme"),
               ("Half Dime", "Half dime"), ("Three Dollar", "Three-dollar piece"), ("Stella", "Stella (United States coin)"), ("Gold Dollar", "Gold dollar"),
               ("Louisiana Purchase", "Louisiana Purchase Exposition"), ("Sovereign", "Sovereign (British coin)"), ("Maple Leaf", "Canadian Gold Maple Leaf"),
               ("Krugerrand", "Krugerrand"), ("Oak Tree", "Oak Tree shilling"), ("Pine Tree", "Pine Tree shilling"), ("Tetradrachm", "Tetradrachm"),
               ("Decadrachm", "Decadrachm"), ("Denarius", "Denarius"), ("Eid Mar", "Eid Mar"), ("Aureus", "Aureus"), ("Solidus", "Solidus (coin)"),
               ("Sestertius", "Sestertius"), ("Ducat", "Ducat"), ("Shekel", "First Jewish–Roman War coinage"), ("Angel", "Angel (coin)"),
               ("Noble", "Noble (English coin)"), ("Leopard", "Leopard (coin)"), ("Reales", "Spanish dollar"), ("Cob", "Cob (coin)"),
               ("Sixpence", "Sixpence (British coin)"), ("Shilling", "Shilling (British coin)"), ("Florin", "Florin (British coin)"), ("Crown", "Crown (British coin)"),
               ("Pesos", "Mexican peso"), ("Mark", "German gold mark"), ("Roubles", "Russian ruble"), ("Cash Coin", "Cash (Chinese coin)"),
               ("Napoleon", "Napoléon (coin)"), ("Thaler", "Thaler"), ("Guinea", "Guinea (coin)"), ("Doubloon", "Doubloon"), ("Panda", "Chinese Gold Panda"),
               ("Britannia", "Britannia (coin)"), ("Kookaburra", "Australian Silver Kookaburra"), ("Nugget", "Australian Gold Nugget"), ("Libertad", "Libertad (coin)")]
COIN_DENOM = [("Double Eagle", "Double eagle"), ("Half Eagle", "Half eagle"), ("Quarter Eagle", "Quarter eagle"), ("Eagle", "Eagle (United States coin)"),
              ("Half Dollar", "Half dollar (United States coin)"), ("Dollar", "Dollar coin (United States)"), ("Quarter", "Quarter (United States coin)"),
              ("Dime", "Dime (United States coin)"), ("Nickel", "Nickel (United States coin)"), ("Cent", "Penny (United States coin)"), ("Penny", "Penny (United States coin)")]


def _coin_family(name, r):
    out = []
    for k, v in COIN_SERIES:
        if k in name:
            out.append(v)
            break
    for k, v in COIN_DENOM:
        if k in name:
            out.append(v)
            break
    return out


# ------------------------------------------------------------------ fetching
def _key(title):
    return hashlib.md5(title.replace("_", " ").strip().encode()).hexdigest()


def _cache_get(title):
    p = os.path.join(CACHE, _key(title) + ".json")
    if os.path.exists(p):
        return json.load(open(p, encoding="utf-8"))
    return None


def _get(params, tries=10):
    url = API + "?" + urllib.parse.urlencode(params)
    for k in range(tries):
        r = subprocess.run(["curl", "-sS", "-L", "-m", "90", "-A", UA, url], capture_output=True)
        body = r.stdout
        if r.returncode == 0 and body[:1] == b"{":
            try:
                return json.loads(body)
            except ValueError:
                pass
        wait = 40 + k * 30
        print("    busy (%s), waiting %ds" % (body[:40], wait), flush=True)
        time.sleep(wait)
    return {}


def fetch_titles(titles, per=40, pause=32.0):
    """Download every title not already cached (wikitext + disambiguation flag)."""
    os.makedirs(CACHE, exist_ok=True)
    todo = [t for t in dict.fromkeys(titles) if _cache_get(t) is None]
    print("  %d titles to fetch (%d requests)" % (len(todo), (len(todo) + per - 1) // per), flush=True)
    for i in range(0, len(todo), per):
        chunk = todo[i:i + per]
        params = {"action": "query", "format": "json", "formatversion": 2, "titles": "|".join(chunk), "redirects": 1,
                  "prop": "revisions|pageprops", "rvprop": "content", "rvslots": "main", "ppprop": "disambiguation"}
        pages = {}
        q = {}
        cont = {}
        while True:
            j = _get(dict(params, **cont))
            q = j.get("query", q) if "query" in j else q
            for pg in j.get("query", {}).get("pages", []):
                old = pages.get(pg["title"], {})
                if "revisions" in pg or not old:
                    pages[pg["title"]] = pg
            if "continue" not in j:
                break
            cont = j["continue"]
            time.sleep(pause / 2)
        # requested title -> final page (+ section fragment of a redirect)
        fwd = {}
        for n in q.get("normalized", []):
            fwd[n["from"]] = (n["to"], "")
        for rd in q.get("redirects", []):
            fwd[rd["from"]] = (rd["to"], rd.get("tofragment", ""))
        for t in chunk:
            cur, frag = t, ""
            for _ in range(4):
                if cur in fwd:
                    cur, f = fwd[cur]
                    frag = f or frag
                else:
                    break
            pg = pages.get(cur, {})
            text = ""
            if pg.get("revisions"):
                text = pg["revisions"][0].get("slots", {}).get("main", {}).get("content", "")
            rec = {"asked": t, "title": cur if text else "", "frag": frag, "text": text,
                   "disambig": "disambiguation" in pg.get("pageprops", {})}
            json.dump(rec, open(os.path.join(CACHE, _key(t) + ".json"), "w", encoding="utf-8"), ensure_ascii=False)
        print("  fetched %d/%d" % (min(i + per, len(todo)), len(todo)), flush=True)
        time.sleep(pause)


def _section(text, frag):
    """The part of a list article a redirect points at (e.g. one Pokemon in a list)."""
    if not frag:
        return text
    m = re.search(r"^(=+)\s*" + re.escape(frag) + r"\s*\1\s*$", text, re.M)
    if not m:
        m = re.search(r"\{\{\s*anchor\s*\|[^}]*" + re.escape(frag), text, re.I)
        if not m:
            return text
    start = m.start()
    lvl = len(m.group(1)) if m.re.pattern.startswith("^(=+)") else 3
    nxt = re.compile(r"^={2,%d}[^=].*?=+\s*$" % lvl, re.M).search(text, m.end())
    return text[start:nxt.start() if nxt else len(text)]


# ------------------------------------------------------------------ DBpedia (no throttling)
DBP = "https://dbpedia.org/sparql"
DBP_CACHE = os.path.join(ROOT, ".cache", "dbp")


def _iri(title):
    t = title.strip().replace(" ", "_")
    t = t[:1].upper() + t[1:]
    return "<http://dbpedia.org/resource/" + "".join(c if c not in '<>"{}|^`\\%' else urllib.parse.quote(c) for c in t) + ">"


def _dbp_get(title):
    p = os.path.join(DBP_CACHE, _key(title) + ".json")
    if os.path.exists(p):
        rec = json.load(open(p, encoding="utf-8"))
        if rec.get("v") == 2:
            return rec
    return None


def _label(v):
    if v.startswith("http://dbpedia.org/resource/"):
        v = urllib.parse.unquote(v.rsplit("/", 1)[1]).replace("_", " ")
        v = re.sub(r"\s*\([^)]*\)$", "", v)
    return v


def _sparql(q):
    for k in range(6):
        r = subprocess.run(["curl", "-sS", "-m", "180", "-G", "-A", UA, "-H", "Accept: application/sparql-results+json",
                            "--data-urlencode", "query=" + q, DBP], capture_output=True)
        try:
            return json.loads(r.stdout.decode("utf-8", "replace"), strict=False)["results"]["bindings"]
        except (ValueError, KeyError):
            print("    dbpedia retry", r.stdout[:60], flush=True)
            time.sleep(10 + k * 15)
    return None


def _dbp_batch(chunk):
    """Rows for a chunk: abstracts in one query, infobox properties in small ones
    (the endpoint stops at 10,000 rows, so big chunks lose data)."""
    vals = " ".join(_iri(t) for t in chunk)
    head = "VALUES ?q { %s } OPTIONAL { ?q dbo:wikiPageRedirects ?r0 } BIND(COALESCE(?r0, ?q) AS ?r) "
    rows = _sparql(("SELECT ?q ?r ?p ?o WHERE { " + head + "{ ?r dbo:abstract ?o . FILTER(lang(?o) = \"en\") BIND(dbo:abstract AS ?p) } UNION "
                    "{ ?r dbo:wikiPageDisambiguates ?o . BIND(dbo:wikiPageDisambiguates AS ?p) } }") % vals)
    if rows is None:
        return None
    for i in range(0, len(chunk), 5):
        sub = " ".join(_iri(t) for t in chunk[i:i + 5])
        more = _sparql(("SELECT ?q ?r ?p ?o WHERE { " + head + "?r ?p ?o . FILTER(STRSTARTS(STR(?p), \"http://dbpedia.org/property/\")) "
                        "FILTER(?p != dbp:wikiPageUsesTemplate || STRSTARTS(STR(?o), \"http://dbpedia.org/resource/Template:Infobox\") "
                        "|| STRSTARTS(STR(?o), \"http://dbpedia.org/resource/Template:Video_game_reviews\")) "
                        "FILTER(!isLiteral(?o) || lang(?o) = \"\" || lang(?o) = \"en\") }") % sub)
        if more is None:
            return None
        rows += more
    return rows


def fetch_dbpedia(titles, per=25, threads=4):
    from concurrent.futures import ThreadPoolExecutor
    os.makedirs(DBP_CACHE, exist_ok=True)
    todo = [t for t in dict.fromkeys(titles) if _dbp_get(t) is None]
    chunks = [todo[i:i + per] for i in range(0, len(todo), per)]
    print("  dbpedia: %d titles (%d queries)" % (len(todo), len(chunks)), flush=True)

    def run(chunk):
        rows = _dbp_batch(chunk)
        if rows is None:
            return
        by = {}
        for b in rows:
            q = urllib.parse.unquote(b["q"]["value"].rsplit("/", 1)[1]).replace("_", " ")
            rec = by.setdefault(q, {"title": "", "abstract": "", "props": {}, "templates": [], "disambig": False})
            rec["title"] = urllib.parse.unquote(b["r"]["value"].rsplit("/", 1)[1]).replace("_", " ")
            p = b["p"]["value"]
            o = b["o"]["value"]
            if p.endswith("/abstract"):
                rec["abstract"] = o
            elif p.endswith("wikiPageDisambiguates"):
                rec["disambig"] = True
            elif p.endswith("wikiPageUsesTemplate"):
                n = _label(o).replace("Template:", "")
                if n.lower().startswith(("infobox", "video game reviews", "music ratings", "album ratings")):
                    rec["templates"].append(n.lower())
            else:
                k2 = p.rsplit("/", 1)[1]
                lst = rec["props"].setdefault(k2, [])
                v = _label(o)
                if v not in lst and len(lst) < 8:
                    lst.append(v)
        for t in chunk:
            key = t.strip().replace("_", " ")
            key = key[:1].upper() + key[1:]
            rec = by.get(key, {"title": "", "abstract": "", "props": {}, "templates": [], "disambig": False})
            rec["asked"] = t
            rec["v"] = 2
            json.dump(rec, open(os.path.join(DBP_CACHE, _key(t) + ".json"), "w", encoding="utf-8"), ensure_ascii=False)

    done = 0
    with ThreadPoolExecutor(threads) as ex:
        for _ in ex.map(run, chunks):
            done += 1
            if done % 10 == 0:
                print("  dbpedia %d/%d" % (done, len(chunks)), flush=True)


def _dbp_ok(rec, it):
    if not rec or not rec["abstract"] or rec["disambig"] or "may refer to" in rec["abstract"][:300]:
        return False
    blob = rec["abstract"][:1500] + " ".join(rec["templates"])
    return any(w in blob for w in it["need"])


def pick(it):
    for t in it["cands"]:
        rec = _cache_get(t)
        if not rec or not rec["text"] or rec["disambig"]:
            continue
        txt = rec["text"]
        if txt.lstrip().upper().startswith("#REDIRECT"):
            continue
        head = txt[:6000]
        if re.search(r"\{\{\s*(disambig|dab|hndis|geodis)", head, re.I) or "may refer to:" in head[:2500]:
            continue
        if not any(w in head for w in it["need"]):
            continue
        return rec
    return None


def fetch_dbp(worlds):
    for w in worlds:
        its = items(w)
        print("%s: %d items" % (w, len(its)), flush=True)
        fetch_dbpedia([c for it in its if pick(it) is None for c in it["cands"]])
        boil(w, its)


def fetch(worlds):
    for w in worlds:
        its = items(w)
        print("%s: %d items" % (w, len(its)), flush=True)
        # Pass 1: the first two candidates each; pass 2: the rest for the misses.
        fetch_titles([c for it in its for c in it["cands"][:2]])
        miss = [it for it in its if pick(it) is None]
        print("  %d misses after pass 1" % len(miss), flush=True)
        fetch_titles([c for it in miss for c in it["cands"][2:]])
        boil(w, its)


# ------------------------------------------------------------------ boiling down
def _clean_wikitext(s):
    import mwparserfromhell as mw
    code = mw.parse(s)
    for tpl in code.filter_templates(recursive=False):
        name = str(tpl.name).strip().lower()
        keep = None
        if name in ("lang", "nihongo", "nihongo2", "transl", "transliteration"):
            ps = [p for p in tpl.params if not p.showkey]
            if name.startswith("nihongo") and ps:
                keep = str(ps[0].value)
            elif len(ps) >= 2:
                keep = str(ps[-1].value)
        elif name in ("convert", "cvt") and len(tpl.params) >= 2:
            keep = "%s %s" % (str(tpl.params[0].value).strip(), str(tpl.params[1].value).strip())
        elif name in ("us$", "usd", "us dollar"):
            keep = "$" + str(tpl.params[0].value).strip() if tpl.params else ""
        elif name in ("¥", "yen", "jpy") and tpl.params:
            keep = "¥" + str(tpl.params[0].value).strip()
        elif name in ("£", "gbp") and tpl.params:
            keep = "£" + str(tpl.params[0].value).strip()
        elif name in ("vgrelease", "video game release", "start date", "start date and age", "release date", "film date", "birth date",
                      "death date", "birth date and age", "death date and age", "dts", "date") and tpl.params:
            ps = [str(p.value).strip() for p in tpl.params if not p.showkey]
            months = ["", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
            if name in ("vgrelease", "video game release"):
                keep = " ".join(ps[1:2]) if len(ps) >= 2 else ""
                keep = keep + (" (" + ps[0] + ")" if ps else "")
            elif len(ps) >= 3 and ps[0].isdigit() and ps[1].isdigit():
                keep = "%s %s %s" % (ps[2], months[int(ps[1])] if 0 < int(ps[1]) < 13 else ps[1], ps[0])
            elif len(ps) >= 2 and ps[0].isdigit() and ps[1].isdigit():
                keep = "%s %s" % (months[int(ps[1])] if 0 < int(ps[1]) < 13 else ps[1], ps[0])
            elif ps:
                keep = ps[0]
        elif name in ("plainlist", "flatlist", "unbulleted list", "ubl", "hlist", "plain list", "flat list") and tpl.params:
            vals = []
            for p in tpl.params:
                v = str(p.value)
                if p.showkey and str(p.name).strip() not in [str(i) for i in range(1, 30)]:
                    continue
                vals += [x for x in v.split("\n")]
            keep = "\n".join(vals)
        elif name in ("sfn", "efn", "refn", "citation needed", "cn", "clarify", "when", "who", "by whom", "dubious", "nbsp", "snd",
                      "sfnp", "harvnb", "r", "rp", "ref", "nowrap", "small", "abbr"):
            if name in ("nowrap", "small") and tpl.params:
                keep = str(tpl.params[0].value)
            elif name == "abbr" and tpl.params:
                keep = str(tpl.params[0].value)
            elif name == "nbsp":
                keep = " "
            elif name == "snd":
                keep = " - "
            else:
                keep = ""
        elif name in ("ndash", "mdash", "spaced ndash", "spaced en dash"):
            keep = " - "
        elif name in ("ill", "interlanguage link") and tpl.params:
            keep = str(tpl.params[0].value)
        elif name in ("cvt", "inflation", "formatprice", "format price") and tpl.params:
            keep = str(tpl.params[-1].value) if name != "inflation" else ""
        if keep is not None:
            try:
                code.replace(tpl, keep)
            except ValueError:
                pass
    out = code.strip_code(normalize=True, collapse=True, keep_template_params=False)
    out = re.sub(r"<[^>]+>", "", out)
    out = re.sub(r"\[\d+\]", "", out)
    out = out.replace(" ", " ")
    return out


def _value(s):
    """An infobox value as short plain text lines."""
    import mwparserfromhell as mw
    s = re.sub(r"<ref[^>]*/>", "", s, flags=re.S)
    s = re.sub(r"<ref.*?</ref>", "", s, flags=re.S)
    s = re.sub(r"<br\s*/?>", "\n", s, flags=re.I)
    s = re.sub(r"<!--.*?-->", "", s, flags=re.S)
    txt = _clean_wikitext(s)
    lines = [re.sub(r"\s+", " ", ln).strip(" *,;:") for ln in txt.split("\n")]
    return [ln for ln in lines if ln]


def _infobox(text):
    import mwparserfromhell as mw
    code = mw.parse(text)
    for tpl in code.filter_templates(recursive=False):
        name = str(tpl.name).strip()
        low = name.lower()
        if low.startswith("infobox") or low.startswith("video game reviews") or low in ("album ratings", "music ratings", "coin infobox", "infobox coin"):
            pass
        else:
            continue
        fields = {}
        for p in tpl.params:
            k = str(p.name).strip().lower()
            try:
                v = _value(str(p.value))
            except Exception:
                v = []
            if v:
                fields[k] = v
        yield low, fields


def _sentences(text):
    """[(section, sentence)] from the article body (lead section = 'lead')."""
    body = re.sub(r"<ref[^>]*/>", "", text, flags=re.S)
    body = re.sub(r"<ref.*?</ref>", "", body, flags=re.S)
    body = re.sub(r"<!--.*?-->", "", body, flags=re.S)
    body = re.sub(r"\{\|.*?\|\}", "", body, flags=re.S)  # tables
    out = []
    sec = "lead"
    parts = re.split(r"^(={2,5})\s*(.*?)\s*\1\s*$", body, flags=re.M)
    chunks = [("lead", parts[0])]
    for i in range(1, len(parts) - 2, 3):
        chunks.append((parts[i + 1], parts[i + 2]))
    skip = re.compile(r"^(references|notes|external links|see also|further reading|bibliography|sources|citations|footnotes|track listing|personnel|filmography|discography)", re.I)
    top = "lead"
    for title, chunk in chunks:
        if skip.match(title.strip()):
            continue
        try:
            plain = _clean_wikitext(chunk)
        except Exception:
            continue
        for para in plain.split("\n"):
            para = para.strip()
            if len(para) < 40 or para.startswith(("|", "!", "{", "Category:", "File:", "Thumb", "thumb")):
                continue
            # sentence split, not on abbreviations / initials / decimals
            ss = re.split(r"(?<!\b[A-Z])(?<!\bMr)(?<!\bDr)(?<!\bSt)(?<!\bNo)(?<!\bvs)(?<!\bJr)(?<!\bSr)(?<!\bInc)(?<!\bCo)(?<!\bLtd)(?<=[.!?])\s+(?=[A-Z\"'(0-9])", para)
            for s in ss:
                s = re.sub(r"\s+", " ", s).strip()
                s = re.sub(r"\s+([,.;:])", r"\1", s)
                s = re.sub(r"\(\s*[;,]?\s*\)", "", s).replace("  ", " ")
                if 35 <= len(s) <= 320 and s[-1:] in ".!?\"'":
                    out.append((title, s))
    return out


def _split(para):
    out = []
    for s in re.split(r"(?<!\b[A-Z])(?<!\bMr)(?<!\bDr)(?<!\bSt)(?<!\bNo)(?<!\bvs)(?<!\bJr)(?<!\bSr)(?<!\bInc)(?<!\bCo)(?<!\bLtd)(?<=[.!?])\s+(?=[A-Z\"'(0-9])", para):
        s = re.sub(r"\s+", " ", s).strip()
        if 35 <= len(s) <= 320 and s[-1:] in ".!?\"'":
            out.append(s)
    return out


def _keep(sents, n=90):
    """The lead plus the sentences most likely to make a panel (keeps the repo light)."""
    import wiki_build
    lead = [x for x in sents if x[0] == "lead"][:8]
    rest = [x for x in sents if x[0] != "lead" and wiki_build._score(x[1]) > 0]
    rest.sort(key=lambda x: -wiki_build._score(x[1]))
    keep = set(map(tuple, lead + rest[:n]))
    return [list(x) for x in sents if tuple(x) in keep]


def _sw_pick(it):
    for t in it["cands"]:
        rec = _sw_get(t)
        if not rec:
            continue
        head = rec.get("abstract", "")[:3000] + " ".join(n for n, _ in rec["boxes"])
        if "may refer to" in head[:400] or not any(w in head for w in it["need"]):
            continue
        return rec
    return None


def _hf_pick(it):
    for t in it["cands"]:
        rec = _hf_get(t)
        if not rec:
            continue
        head = rec["text"][:3000]
        if "may refer to" in head[:400] or not any(w in head for w in it["need"]):
            continue
        return rec
    return None


def boil(world, its):
    """Best source per item: full wikitext (infobox + sections) if cached, else the
    dump's plain text; Wikidata adds structured stats either way."""
    os.makedirs(DATA, exist_ok=True)
    path = os.path.join(DATA, world + ".json")
    picks = {}
    shared = set()
    for it in its:
        rec = pick(it)
        if rec is not None:
            picks[it["id"]] = ("wiki", rec)
            continue
        sw = _sw_pick(it)
        if sw is not None:
            picks[it["id"]] = ("sw", sw)
            continue
        h = _hf_pick(it)
        if h is not None:
            picks[it["id"]] = ("hf", h)
            continue
        fam = dict(it, cands=it.get("family", []))
        sw = _sw_pick(fam) or _sw_pick(dict(fam, need=[" "]))
        if sw is not None:
            picks[it["id"]] = ("sw", sw)
            shared.add(it["id"])
    wd_fetch(world, [r["title"] for _, r in picks.values()])
    out = {}
    for it in its:
        if it["id"] not in picks:
            continue
        src, rec = picks[it["id"]]
        wd = _wd_get(rec["title"]) or {}
        if src == "wiki":
            text = _section(rec["text"], rec["frag"])
            boxes = list(_infobox(rec["text"] if rec["frag"] == "" else text))
            sents = _sentences(text)
        elif src == "sw":
            boxes = [(n, {k: [x.strip() for x in v.split("\n") if x.strip()] for k, v in f.items()}) for n, f in rec["boxes"]]
            sents = [(sec, x) for sec, para in rec["secs"] for x in _split(para)]
        else:
            boxes = []
            sents = _hf_sentences(rec["text"])
        if wd:
            boxes.append(("wikidata", wd))
        out[it["id"]] = {"real": it["real"], "title": rec["title"], "frag": rec.get("frag", ""), "src": src, "shared": it["id"] in shared,
                         "boxes": boxes, "sents": _keep(sents)}
    json.dump(out, open(path, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    print("  %s: %d / %d items have an article -> %s" % (world, len(out), len(its), os.path.relpath(path, ROOT)), flush=True)
    miss = [it["real"] for it in its if it["id"] not in out]
    if miss:
        print("  no article (%d):" % len(miss), "; ".join(miss[:400]), flush=True)


# ------------------------------------------------------------------ Wikipedia dump on Hugging Face (no throttling)
HF = "https://huggingface.co/datasets/wikimedia/wikipedia/resolve/main/20231101.en/train-%05d-of-00041.parquet"
HF_DIR = os.path.join(ROOT, ".cache", "hf")


def _nt(t):
    """Loose title key: case, accents, punctuation and a leading 'The' don't matter."""
    import unicodedata
    t = unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode().lower()
    t = re.sub(r"^the\s+", "", t)
    return re.sub(r"[^a-z0-9]+", "", t)


def _hf_get(title):
    p = os.path.join(HF_DIR, "art", _key(_nt(title)) + ".json")
    if os.path.exists(p):
        return json.load(open(p, encoding="utf-8"))
    return None


def hf_scan(worlds):
    """Stream all 41 dump files once and keep every article a candidate title names."""
    import pyarrow.parquet as pq
    from concurrent.futures import ThreadPoolExecutor
    want = set()
    for w in worlds:
        for it in items(w):
            for c in it["cands"]:
                want.add(_nt(c))
    os.makedirs(os.path.join(HF_DIR, "art"), exist_ok=True)
    print("hf: looking for %d titles" % len(want), flush=True)

    def dl(i):
        f = os.path.join(HF_DIR, "part%02d.parquet" % i)
        done = f + ".done"
        if os.path.exists(done):
            return None
        subprocess.run(["curl", "-sSL", "-m", "1200", "--retry", "5", "-o", f, HF % i], check=False)
        return f

    found = 0
    with ThreadPoolExecutor(2) as ex:
        for i, f in zip(range(41), ex.map(dl, range(41))):
            if f is None:
                continue
            try:
                pf = pq.ParquetFile(f)
                for g in range(pf.metadata.num_row_groups):
                    titles = pf.read_row_group(g, columns=["title"]).column("title").to_pylist()
                    hits = [k for k, t in enumerate(titles) if _nt(t) in want]
                    if not hits:
                        continue
                    texts = pf.read_row_group(g, columns=["text"]).column("text")
                    for k in hits:
                        rec = {"title": titles[k], "text": texts[k].as_py()}
                        p = os.path.join(HF_DIR, "art", _key(_nt(titles[k])) + ".json")
                        old = json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None
                        # Two titles with one key (e.g. "Dune" / "The Dune"): keep the longer article.
                        if old is None or len(old["text"]) < len(rec["text"]):
                            json.dump(rec, open(p, "w", encoding="utf-8"), ensure_ascii=False)
                        found += 1
                open(f + ".done", "w").close()
            except Exception as e:  # noqa: BLE001
                print("  part %d failed: %s" % (i, e), flush=True)
            os.remove(f)
            print("  part %d/41 scanned, %d articles so far" % (i + 1, found), flush=True)


def _hf_sentences(text):
    """[(section, sentence)] from the dump's plain text (headings are short lines)."""
    out = []
    sec = "lead"
    skip = re.compile(r"^(references|notes|external links|see also|further reading|bibliography|sources|citations|footnotes|track listing|personnel)", re.I)
    skipping = False
    for line in text.split("\n"):
        ln = line.strip()
        if not ln:
            continue
        if len(ln) < 70 and not re.search(r"[.!?:\"']$", ln) and len(ln.split()) <= 8:
            sec = ln
            skipping = bool(skip.match(ln))
            continue
        if skipping:
            continue
        out += [(sec, s) for s in _split(ln)]
    return out


# ------------------------------------------------------------------ Wikidata (structured stats, bulk SPARQL)
WD = "https://query.wikidata.org/sparql"
WD_DIR = os.path.join(ROOT, ".cache", "wd")
# property -> infobox-style key (the names wiki_build.STAT_KEYS reads), per world
WD_PROPS = {
    "games": {"P178": "developer", "P123": "publisher", "P57": "director", "P162": "producer", "P287": "designer", "P86": "composer",
              "P179": "series", "P577": "released", "P136": "genre", "P404": "modes", "P408": "engine", "P2664": "unitssold",
              "P176": "manufacturer", "P2284": "introprice", "P880": "cpu", "P2928": "memory", "P155": "predecessor", "P156": "successor",
              "P2669": "discontinued", "P571": "releasedate"},
    "cards": {"P170": "creator", "P4584": "firstappearance", "P123": "publisher", "P577": "released", "P287": "designer"},
    "coins": {"P17": "country", "P3934": "value", "P2067": "mass", "P2386": "diameter", "P2610": "thickness", "P186": "composition",
              "P287": "designer", "P1092": "mintage", "P571": "years", "P170": "designer"},
    "sports": {"P413": "position", "P569": "birthdate", "P19": "birthplace", "P2048": "height", "P2067": "weight", "P1618": "number",
               "P647": "draftyear", "P1449": "nickname", "P570": "deathdate", "P69": "college"},
    "comics": {"P123": "publisher", "P577": "date", "P50": "writers", "P110": "artists", "P674": "characters", "P179": "series"},
    "books": {"P50": "author", "P110": "illustrator", "P123": "publisher", "P577": "pubdate", "P1104": "pages", "P136": "genre",
              "P407": "language", "P495": "country", "P155": "precededby", "P156": "followedby", "P840": "setin"},
    "vinyl": {"P175": "artist", "P577": "released", "P264": "label", "P162": "producer", "P2047": "length", "P136": "genre",
              "P483": "studio", "P676": "writer", "P86": "writer"},
}
UNIT = {"gram": "g", "kilogram": "kg", "millimetre": "mm", "centimetre": "cm", "metre": "m", "second": "s", "minute": "min",
        "United States dollar": "$", "Japanese yen": "¥", "pound sterling": "£"}


def _wd_get(title):
    p = os.path.join(WD_DIR, _key(title) + ".json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None


def wd_fetch(world, titles, per=40):
    os.makedirs(WD_DIR, exist_ok=True)
    props = WD_PROPS[world]
    todo = [t for t in dict.fromkeys(titles) if _wd_get(t) is None]
    print("  wikidata: %d titles" % len(todo), flush=True)
    for i in range(0, len(todo), per):
        chunk = todo[i:i + per]
        vals = " ".join(json.dumps(t, ensure_ascii=False) + "@en" for t in chunk)
        pv = " ".join("wdt:" + p for p in props)
        pq = " ".join("p:" + p for p in props)
        q = ("SELECT ?t ?p ?vLabel ?amt ?uLabel WHERE { VALUES ?t { %s } ?a schema:about ?item; schema:isPartOf <https://en.wikipedia.org/>; schema:name ?t . "
             "{ VALUES ?p { %s } ?item ?p ?v . FILTER(!isLiteral(?v) || datatype(?v) != xsd:decimal) } UNION "
             "{ VALUES ?pp { %s } ?item ?pp ?st . ?st ?psv ?qv . ?qv wikibase:quantityAmount ?amt; wikibase:quantityUnit ?u . "
             "FILTER(STRSTARTS(STR(?psv), \"http://www.wikidata.org/prop/statement/value/\")) BIND(?pp AS ?p) } "
             "SERVICE wikibase:label { bd:serviceParam wikibase:language \"en\". } }") % (vals, pv, pq)
        rows = None
        for k in range(5):
            r = subprocess.run(["curl", "-sS", "-m", "120", "-G", "-A", UA, "-H", "Accept: application/sparql-results+json",
                                "--data-urlencode", "query=" + q, WD], capture_output=True)
            try:
                rows = json.loads(r.stdout)["results"]["bindings"]
                break
            except (ValueError, KeyError):
                print("    wikidata retry", r.stdout[:80], flush=True)
                time.sleep(10 + 20 * k)
        if rows is None:
            continue
        got = {t: {} for t in chunk}
        for b in rows:
            t = b["t"]["value"]
            pid = b["p"]["value"].rsplit("/", 1)[1]
            key = props.get(pid)
            if not key or t not in got:
                continue
            if "amt" in b:
                amt = b["amt"]["value"].lstrip("+")
                try:
                    f = float(amt)
                    amt = ("%d" % f if f == int(f) else ("%.2f" % f).rstrip("0").rstrip(".")) if abs(f) < 1e15 else amt
                    if f >= 10000 and f == int(f):
                        amt = "{:,}".format(int(f))
                except ValueError:
                    pass
                u = UNIT.get(b.get("uLabel", {}).get("value", ""), "")
                v = (u + amt) if u in ("$", "¥", "£") else (amt + (" " + u if u else ""))
            else:
                v = b.get("vLabel", {}).get("value", "")
                if re.match(r"^\d{4}-\d\d-\d\dT", v):
                    v = v[:4] if v[5:10] == "01-01" else v[:10]
                if re.match(r"^Q\d+$", v) or v.startswith("http"):
                    continue
            lst = got[t].setdefault(key, [])
            if v and v not in lst and len(lst) < 6:
                lst.append(v)
        for t in chunk:
            json.dump(got[t], open(os.path.join(WD_DIR, _key(t) + ".json"), "w", encoding="utf-8"), ensure_ascii=False)
        time.sleep(1.5)


# ------------------------------------------------------------------ search for the misses (Wikipedia search run by Wikidata's servers)
HINT = {"games": "video game", "cards": "trading card", "coins": "coin", "sports": "", "comics": "comic book", "books": "book", "vinyl": "album"}
FOUND = os.path.join(DATA, "search.json")


def _found():
    return json.load(open(FOUND, encoding="utf-8")) if os.path.exists(FOUND) else {}


def _nt_words(t):
    import unicodedata
    return unicodedata.normalize("NFKD", t).encode("ascii", "ignore").decode().lower()


def _search(qs):
    q = ("SELECT ?title ?ord WHERE { SERVICE wikibase:mwapi { bd:serviceParam wikibase:endpoint \"en.wikipedia.org\"; wikibase:api \"Search\"; "
         "mwapi:srsearch %s; mwapi:srlimit \"3\"; wikibase:limit \"once\". ?title wikibase:apiOutput mwapi:title. ?ord wikibase:apiOrdinal true. } }") % json.dumps(qs, ensure_ascii=False)
    for k in range(4):
        r = subprocess.run(["curl", "-sS", "-m", "60", "-G", "-A", UA, "-H", "Accept: application/sparql-results+json",
                            "--data-urlencode", "query=" + q, WD], capture_output=True)
        try:
            rows = json.loads(r.stdout)["results"]["bindings"]
            rows.sort(key=lambda b: int(b["ord"]["value"]))
            return [b["title"]["value"] for b in rows]
        except (ValueError, KeyError):
            time.sleep(5 + 10 * k)
    return []


def resolve(worlds):
    from concurrent.futures import ThreadPoolExecutor
    found = _found()
    for w in worlds:
        its = [it for it in items(w) if pick(it) is None and _hf_pick(it) is None and it["id"] not in found]
        its = [it for it in its if not re.search(r"\b(Lot|Box|Crate|Longbox|Bundle)$", it["real"])]
        print("%s: searching %d misses" % (w, len(its)), flush=True)

        def one(it):
            name = re.sub(r"\s*\([^)]*\)$", "", it["real"])
            if w == "games" and it["kind"] != "game":
                hint = "console" if it["kind"] == "console" else "accessory"
            else:
                hint = HINT[w]
            hits = _search(("%s %s" % (name, hint)).strip())
            bad = re.compile(r"^(List of|Lists of|Index of|Timeline of)", re.I)
            stop = {"the", "of", "and", "a", "an", "in", "on", "for", "edition", "video", "game", "console", "coin", "card", "album", "book"}
            words = {x for x in re.findall(r"[a-z0-9]+", _nt_words(name)) if x not in stop and len(x) > 1}

            def close(t):
                tw = set(re.findall(r"[a-z0-9]+", _nt_words(re.sub(r"\s*\([^)]*\)$", "", t))))
                return words and len(words & tw) >= max(1, (len(words) + 1) // 2)
            return it["id"], [t for t in hits if not bad.match(t) and close(t)][:2]

        with ThreadPoolExecutor(3) as ex:
            for iid, hits in ex.map(one, its):
                found[iid] = hits
        json.dump(found, open(FOUND, "w", encoding="utf-8"), ensure_ascii=False, indent=0)
        print("  %s: %d found" % (w, sum(1 for it in its if found.get(it["id"]))), flush=True)


# ------------------------------------------------------------------ Wikimedia's structured dump on Hugging Face (infoboxes + sections)
SW_URL = "https://huggingface.co/datasets/wikimedia/structured-wikipedia/resolve/main/20240916.en/enwiki_namespace_0.zip"
SW_DIR = os.path.join(ROOT, ".cache", "sw")


def _sw_get(title):
    p = os.path.join(SW_DIR, _key(_nt(title)) + ".json")
    return json.load(open(p, encoding="utf-8")) if os.path.exists(p) else None


def _sw_flat(parts, sec, out):
    for p in parts or []:
        t = p.get("type")
        if t == "section":
            _sw_flat(p.get("has_parts"), p.get("name") or sec, out)
        elif t == "paragraph" and p.get("value"):
            out.append((sec, p["value"]))
        elif t in ("list",):
            for li in p.get("has_parts") or []:
                if li.get("value"):
                    out.append((sec, li["value"]))


def _sw_fields(parts, out):
    for p in parts or []:
        if p.get("type") == "field" and p.get("name"):
            v = p.get("value") or ""
            if not v and p.get("values"):
                v = "\n".join(p["values"])
            if v:
                out.setdefault(p["name"], v)
        _sw_fields(p.get("has_parts"), out)


def sw_scan(worlds):
    import io
    import zipfile
    import requests
    from concurrent.futures import ThreadPoolExecutor
    want = set()
    for w in worlds:
        for it in items(w):
            for c in it["cands"] + it.get("family", []):
                want.add(_nt(c))
    os.makedirs(SW_DIR, exist_ok=True)
    local = os.path.join(ROOT, ".cache", "sw.zip")  # curl it first: range reads on the CDN are very slow
    if os.path.exists(local):
        url, size = None, 0
    else:
        r = requests.head(SW_URL, allow_redirects=True, timeout=60)
        url, size = r.url, int(r.headers["content-length"])

    def src():
        return open(local, "rb") if url is None else io.BufferedReader(Http(), 1 << 20)

    class Http(io.RawIOBase):
        def __init__(self):
            self.s = requests.Session()
            self.pos = 0
            self.buf = b""
            self.b0 = 0

        def seekable(self):
            return True

        def readable(self):
            return True

        def tell(self):
            return self.pos

        def seek(self, o, wh=0):
            self.pos = o if wh == 0 else (self.pos + o if wh == 1 else size + o)
            return self.pos

        def readinto(self, b):
            n = len(b)
            if not (self.b0 <= self.pos and self.pos + n <= self.b0 + len(self.buf)):
                end = min(size, self.pos + max(n, 16 << 20)) - 1
                for k in range(6):
                    try:
                        self.buf = self.s.get(url, headers={"Range": "bytes=%d-%d" % (self.pos, end)}, timeout=120).content
                        break
                    except Exception:  # noqa: BLE001
                        time.sleep(5 + 10 * k)
                self.b0 = self.pos
            o = self.pos - self.b0
            d = self.buf[o:o + n]
            b[:len(d)] = d
            self.pos += len(d)
            return len(d)

    members = [m for m in zipfile.ZipFile(src()).infolist() if m.filename.endswith(".jsonl") and "MACOSX" not in m.filename]
    print("sw: %d files, looking for %d titles" % (len(members), len(want)), flush=True)
    rx = re.compile(rb'^\{"name":\s*"((?:[^"\\]|\\.)*)"')

    def scan(m):
        done = os.path.join(SW_DIR, "done_" + os.path.basename(m.filename))
        if os.path.exists(done):
            return 0
        z = zipfile.ZipFile(src())
        n = 0
        with z.open(m) as f:
            for line in f:
                mm = rx.match(line)
                if not mm:
                    continue
                try:
                    name = json.loads(b'"' + mm.group(1) + b'"')
                except ValueError:
                    continue
                if _nt(name) not in want:
                    continue
                d = json.loads(line)
                secs = []
                _sw_flat(d.get("sections"), "lead", secs)
                boxes = []
                for ib in d.get("infoboxes") or []:
                    fl = {}
                    _sw_fields(ib.get("has_parts"), fl)
                    boxes.append([(ib.get("name") or "infobox").lower(), fl])
                rec = {"title": name, "abstract": d.get("abstract", ""), "boxes": boxes,
                       "secs": [(("lead" if sc in ("Abstract", "lead") else sc), t) for sc, t in secs]}
                p = os.path.join(SW_DIR, _key(_nt(name)) + ".json")
                json.dump(rec, open(p, "w", encoding="utf-8"), ensure_ascii=False)
                n += 1
        open(done, "w").close()
        print("  %s: %d" % (m.filename, n), flush=True)
        return n

    with ThreadPoolExecutor(4) as ex:
        total = sum(ex.map(scan, members))
    print("sw: %d articles" % total, flush=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        sys.exit(0)
    cmd, rest = args[0], args[1:]
    if cmd == "fetch":
        fetch(rest or WORLDS)
    elif cmd == "resolve":
        resolve(rest or WORLDS)
    elif cmd == "sw":
        sw_scan(rest or WORLDS)
    elif cmd == "hf":
        hf_scan(rest or WORLDS)
    elif cmd == "dbp":
        fetch_dbp(rest or WORLDS)
    elif cmd == "boil":
        for w in rest or WORLDS:
            boil(w, items(w))
    elif cmd == "build":
        import wiki_build
        wiki_build.main(rest or WORLDS)
    elif cmd == "show":
        import wiki_build
        wiki_build.show(rest[0])
