#!/usr/bin/env python3
"""tools/wiki/<world>.json -> scripts/data/facts_<world>.gd (run via tools/wiki_facts.py build).

Each item gets:
  "stats": [[LABEL, value], ...]   real infobox numbers, labels per category (BY THE NUMBERS)
  "hist":  [[HEADING, text], ...]  the most fact-packed real sentences, sorted into panels
  "year":  first year in the release / publication field (0 = unknown)
Everything real is run through the parody tables, so names stay in-universe.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(HERE)
DATA = os.path.join(HERE, "wiki")

# ------------------------------------------------------------------ parody table
BRANDS = [
    ("Nintendo Entertainment System", "Funtendo FES"), ("Super Nintendo Entertainment System", "Super FES"),
    ("Super NES", "Super FES"), ("Nintendo", "Funtendo"), ("Famicom", "Funicom"), ("GameCube", "FunCube"),
    ("Game Boy", "PocketBoy"), ("Nintendo DS", "Funtendo Duo"), ("Wii U", "Wee U"), ("Wii", "Wee"), ("Switch", "Swatch"),
    ("PlayStation", "PlayStatia"), ("Sony Computer Entertainment", "Sonny Computer Entertainment"), ("Sony", "Sonny"),
    ("Sega Genesis", "Saga Genesys"), ("Mega Drive", "Mega Driv"), ("Genesis", "Genesys"), ("Dreamcast", "Dreamcaster"),
    ("Sega Saturn", "Saga Saturnine"), ("Sega", "Saga"), ("SEGA", "SAGA"), ("Microsoft", "Microsloth"), ("Xbox", "Xbux"),
    ("Atari", "Ataro"), ("Neo Geo", "Neon Geo"), ("SNK", "SNC"), ("TurboGrafx", "TurboGrafix"), ("Mario", "Marrio"),
    ("Luigi", "Luiggi"), ("Bowser", "Bowzer"), ("Donkey Kong", "Donkee Kong"), ("Zelda", "Zeldo"), ("Link", "Lynk"),
    ("Kirby", "Kirbo"), ("Metroid", "Metrood"), ("Samus", "Samos"), ("Pokémon", "Pocket Critters"), ("Pokemon", "Pocket Critters"),
    ("Pikachu", "Pikapal"), ("Sonic the Hedgehog", "Sonik the Hedgehog"), ("Sonic", "Sonik"), ("Mega Man", "Mega Robo Man"),
    ("Castlevania", "Castlevein"), ("Final Fantasy", "Final Fantasia"), ("Dragon Quest", "Dragon Quast"), ("Dragon Warrior", "Dragon Worrier"),
    ("Square Enix", "Squire Enox"), ("Squaresoft", "Squire Soft"), ("Square", "Squire"), ("Enix", "Enox"), ("Konami", "Konamo"),
    ("Capcom", "Capcorn"), ("Hudson Soft", "Hudsun Soft"), ("Hudson", "Hudsun"), ("Tecmo", "Tecmoo"), ("Namco", "Namcoo"),
    ("Bandai", "Bandoo"), ("Taito", "Taitu"), ("Atlus", "Atlast"), ("Natsume", "Natsoom"), ("Rareware", "Rarrware"), ("Rare", "Rarr"),
    ("HAL Laboratory", "HAL Labratory"), ("Game Freak", "Game Freek"), ("Treasure", "Treazure"), ("Irem", "Irum"),
    ("Activision", "Activizion"), ("Electronic Arts", "Electrick Arts"), ("Ubisoft", "Uboosoft"), ("Midway", "Midwhey"),
    ("Acclaim", "Akclaim"), ("THQ", "THC-ish"), ("Sunsoft", "Sunsoff"), ("Jaleco", "Jalecko"), ("Data East", "Data Yeast"),
    ("Wizards of the Coast", "Lizards of the Coast"), ("Wizards", "Lizards"), ("Magic: The Gathering", "Magick: The Gatherening"), ("Yu-Gi-Oh!", "Yu-Gi-Whoa!"),
    ("Yu-Gi-Oh", "Yu-Gi-Whoa"), ("The Pokémon Company", "Critter Co."), ("Game Informer", "Game Informant"), ("Famitsu", "Famitsoo"),
    ("Nintendo Power", "Funtendo Power"), ("Electronic Gaming Monthly", "Electronic Gaming Muchly"), ("IGN", "IGM"),
    ("GameSpot", "GameSpott"), ("Metacritic", "Metacritick"), ("GameRankings", "GameRankinz"), ("eBay", "eBuy"), ("Amazon", "Amazin"),
    ("Topps", "Toppz"), ("Upper Deck", "Upper Dekk"), ("Panini", "Panino"), ("Fleer", "Fleeb"), ("Marvel", "Marbel"),
    ("DC Comics", "DK Comics"), ("Billboard", "Billbored"), ("Rolling Stone", "Rolling Stoned"), ("Beatles", "Beedles"),
    ("Professional Coin Grading Service", "Professional Coin Grading Servis"), ("PCGS", "PCGZ"), ("NGC", "NGZ"), ("PSA", "PZA"),
    ("Beckett", "Beckit"), ("CGC", "CGZ"), ("Heritage Auctions", "Heritige Auctions"), ("Sotheby's", "Sotheboys"),
    ("Christie's", "Christy's"), ("Guinness World Records", "Guinniss World Records"), ("Disney", "Dizzney"),
    ("Coca-Cola", "Coca-Kola"), ("McDonald's", "McDougal's"), ("Walmart", "Wallmart"), ("Toys \"R\" Us", "Toys \"Я\" Us"),
    ("Blockbuster", "Blockbustr"), ("Hasbro", "Hasbroo"), ("Mattel", "Mattell"), ("Wikipedia", "the encyclopedia"),
]


def _pairs(obj):
    if isinstance(obj, dict):
        return [(k, v) for k, v in obj.items() if isinstance(k, str) and isinstance(v, str)]
    if isinstance(obj, (list, tuple)):
        return [tuple(p) for p in obj if isinstance(p, (list, tuple)) and len(p) == 2 and all(isinstance(x, str) for x in p)]
    return []


def _word_diffs(pairs):
    """Same-length real / parody titles -> {real word: parody word} where it's consistent."""
    seen = {}
    bad = set()
    for real, fake in pairs:
        a, b = real.split(), fake.split()
        if len(a) != len(b):
            continue
        for x, y in zip(a, b):
            x2, y2 = x.strip(":,.!?'\"()"), y.strip(":,.!?'\"()")
            if x2 == y2 or len(x2) < 4 or not x2[:1].isupper():
                continue
            if seen.get(x2, y2) != y2:
                bad.add(x2)
            seen[x2] = y2
    return [(k, v) for k, v in seen.items() if k not in bad]


_TABLES = {}
# Parody-table keys that are also everyday words: never replace these in prose.
COMMON = {"Image", "Epic", "Various", "Score", "Leaf", "Allen", "SP", "Playoff", "Golf Stars", "Sport Stars", "Hemmets", "Mirage",
          "Caliber", "Antarctic", "Oni", "Dell", "Exquisite", "Prizm", "Young Guns", "Superfractor", "Bundesliga", "Raw Books"}


def table(world):
    if world in _TABLES:
        return _TABLES[world]
    pairs = []
    import gen_worlds
    if world in ("comics", "books", "vinyl", "sports"):
        conf = gen_worlds.load_conf(world)
        for name in dir(conf):
            if name.isupper() and name not in ("BRAND_PUB", "BLURB", "TELLS", "TELLS_KNOWN", "POS_STATS", "PRICE", "GRAILS"):
                pairs += [p for p in _pairs(getattr(conf, name)) if len(p[0]) > 2 and p[0] != p[1] and len(p[0]) < 60
                          and p[0].strip() not in COMMON]
    pairs += BRANDS
    import gen_catalog
    import gen_collectibles
    pairs += _pairs(gen_catalog.SUBS) + _pairs(gen_collectibles.SUBS)
    _TABLES[world] = pairs
    return pairs


class Sub:
    def __init__(self, pairs):
        pairs = list(pairs) + [(a[4:], b[4:]) for a, b in pairs if a.startswith("The ") and b.startswith("The ")]
        m = {}
        for a, b in pairs:
            a = a.strip()
            if len(a) < 3 or a == b or a in m:
                continue
            m[a] = b
        self.m = m
        keys = sorted(m, key=len, reverse=True)
        self.rx = re.compile(r"(?<![A-Za-z0-9])(" + "|".join(re.escape(k) for k in keys) + r")(?![a-rt-z]|s[a-z])") if keys else None

    def __call__(self, s):
        if self.rx:
            s = self.rx.sub(lambda x: self.m[x.group(1)], s)
        return s.replace("..", ".").replace(".,", ",")


def _mangle_person(name):
    import gen_catalog
    words = name.split()
    if not (2 <= len(words) <= 4) or any(ch.isdigit() for ch in name) or not all(w[:1].isupper() for w in words):
        return None
    if words[0] in ("The", "A") or re.search(r"\b(Company|Inc|Ltd|Co|Corp|Corporation|Studios?|Games|Entertainment|Records|Music|Group|"
                                             r"Interactive|Software|Productions?|Media|Press|Publishing|Comics|Mint|Bank|Society|Team|Club|"
                                             r"University|Museum|Library|Orchestra|Band|Brothers)\b", name):
        return None
    last = words[-1]
    if last in ("Jr.", "Sr.", "II", "III") and len(words) > 2:
        last = words[-2]
    if len(last) < 4:
        return None
    new = gen_catalog.mangle(last)
    return [(name, name.replace(last, new)), (last, new)]


PEOPLE_KEYS = {"director", "directors", "producer", "producers", "designer", "designers", "programmer", "programmers", "artist", "artists",
               "writer", "writers", "composer", "composers", "author", "illustrator", "coverartist", "creators", "creator", "pencillers",
               "inkers", "editors", "editor", "obversedesigner", "reversedesigner", "designer", "engraver", "photographer"}


def _norm(k):
    k = re.sub(r"\(s\)|\(es\)", "", k.lower())
    return re.sub(r"[^a-z0-9]", "", k)


# ------------------------------------------------------------------ stats
STAT_KEYS = {
    "games": [("developer", "DEVELOPER"), ("publisher", "PUBLISHER"), ("director", "DIRECTOR"), ("producer", "PRODUCER"),
              ("designer", "DESIGNER"), ("programmer", "PROGRAMMER"), ("artist", "ARTIST"), ("writer", "WRITER"), ("composer", "COMPOSER"),
              ("series", "SERIES"), ("engine", "ENGINE"), ("released", "RELEASED"), ("release", "RELEASED"), ("genre", "GENRE"), ("modes", "MODES"), ("mode", "MODES"),
              ("manufacturer", "MAKER"), ("type", "TYPE"), ("generation", "GENERATION"), ("releasedate", "LAUNCHED"), ("introprice", "LAUNCH PRICE"),
              ("price", "LAUNCH PRICE"), ("discontinued", "DISCONTINUED"), ("unitssold", "UNITS SOLD"), ("unitsshipped", "UNITS SOLD"),
              ("media", "MEDIA"), ("cpu", "CPU"), ("memory", "MEMORY"), ("storage", "STORAGE"), ("display", "DISPLAY"), ("graphics", "GRAPHICS"),
              ("sound", "SOUND"), ("controllers", "CONTROLLERS"), ("controllerinput", "INPUT"), ("connectivity", "CONNECTS"), ("power", "POWER"),
              ("topgame", "BEST SELLER"), ("bestselling", "BEST SELLER"), ("compatibility", "PLAYS"), ("predecessor", "BEFORE IT"),
              ("successor", "AFTER IT"), ("platforms", "PLATFORMS"), ("platform", "PLATFORM")],
    "cards": [("creator", "CREATED BY"), ("designer", "DESIGNED BY"), ("firstgame", "FIRST GAME"), ("firstappearance", "FIRST SEEN"),
              ("species", "SPECIES"), ("type", "TYPE"), ("voice", "VOICE"), ("japaneseva", "VOICE (JP)"), ("englishva", "VOICE (EN)"),
              ("publisher", "PUBLISHER"), ("players", "PLAYERS"), ("playingtime", "GAME TIME"), ("setuptime", "SETUP"), ("released", "RELEASED"),
              ("years", "PRINTED"), ("cards", "CARDS"), ("genre", "GENRE"), ("designers", "DESIGNED BY"), ("skills", "SKILLS"),
              ("ageRange", "AGES"), ("agerange", "AGES"), ("random", "LUCK")],
    "coins": [("country", "COUNTRY"), ("value", "FACE VALUE"), ("mass", "WEIGHT"), ("diameter", "DIAMETER"), ("thickness", "THICKNESS"),
              ("edge", "EDGE"), ("composition", "METAL"), ("gold", "GOLD"), ("silver", "SILVER"), ("years", "YEARS STRUCK"),
              ("yearsofminting", "YEARS STRUCK"), ("mintage", "MINTAGE"), ("obversedesign", "FRONT"), ("obversedesigner", "DESIGNER"),
              ("designer", "DESIGNER"), ("reversedesign", "BACK"), ("reversedesigner", "BACK BY"), ("obversedesigndate", "DESIGNED"),
              ("mintmarks", "MINT MARKS"), ("unit", "UNIT"), ("shape", "SHAPE"), ("alignment", "ALIGNMENT"), ("orientation", "ALIGNMENT")],
    "sports": [("position", "POSITION"), ("birthdate", "BORN"), ("birthplace", "HOMETOWN"), ("height", "HEIGHT"), ("heightft", "HEIGHT"),
               ("weight", "WEIGHT"), ("weightlb", "WEIGHT"), ("bats", "BATS"), ("throws", "THROWS"), ("shoots", "SHOOTS"),
               ("debutyear", "DEBUT"), ("debutdate", "DEBUT"), ("finalyear", "LAST SEASON"), ("draftyear", "DRAFTED"), ("draftpick", "PICK"),
               ("nickname", "NICKNAME"), ("number", "NUMBER"), ("careernumber", "NUMBER"), ("team", "TEAM"), ("currentteam", "TEAM"),
               ("halloffame", "HALL OF FAME"), ("hofyear", "HALL OF FAME"), ("induction", "HALL OF FAME"), ("deathdate", "DIED"),
               ("college", "COLLEGE"), ("league", "LEAGUE"), ("highlights", "HIGHLIGHTS")],
    "comics": [("publisher", "PUBLISHER"), ("date", "COVER DATE"), ("publishdate", "COVER DATE"), ("pubdate", "COVER DATE"),
               ("writers", "WRITER"), ("writer", "WRITER"), ("artists", "ARTIST"), ("artist", "ARTIST"), ("pencillers", "PENCILS"),
               ("inkers", "INKS"), ("colorists", "COLOURS"), ("letterers", "LETTERS"), ("editors", "EDITOR"), ("creators", "CREATED BY"),
               ("maincharteam", "FEATURING"), ("characters", "FEATURING"), ("issues", "ISSUES"), ("issue", "ISSUES"), ("schedule", "SCHEDULE"),
               ("format", "FORMAT"), ("genre", "GENRE"), ("debut", "DEBUT"), ("firstappearance", "FIRST SEEN"), ("alteregos", "SECRET IDENTITY"),
               ("alterego", "SECRET IDENTITY"), ("powers", "POWERS"), ("abilities", "POWERS")],
    "books": [("author", "AUTHOR"), ("illustrator", "ILLUSTRATOR"), ("coverartist", "COVER ART"), ("country", "COUNTRY"), ("language", "LANGUAGE"),
              ("series", "SERIES"), ("genre", "GENRE"), ("publisher", "PUBLISHER"), ("pubdate", "PUBLISHED"), ("releasedate", "PUBLISHED"),
              ("published", "PUBLISHED"), ("pages", "PAGES"), ("mediatype", "FORMAT"), ("precededby", "BEFORE IT"), ("followedby", "SEQUEL"),
              ("setin", "SET IN"), ("dedication", "DEDICATED TO"), ("date", "DATE"), ("printer", "PRINTER")],
    "vinyl": [("artist", "ARTIST"), ("released", "RELEASED"), ("recorded", "RECORDED"), ("studio", "STUDIO"), ("venue", "VENUE"),
              ("genre", "GENRE"), ("length", "LENGTH"), ("label", "LABEL"), ("producer", "PRODUCER"), ("writer", "WRITTEN BY"),
              ("songwriter", "WRITTEN BY"), ("bside", "B-SIDE"), ("aside", "A-SIDE"), ("format", "FORMAT"), ("type", "TYPE")],
}
MAX_STATS = 7
SKIP_VAL = re.compile(r"(\.jpe?g|\.png|\.svg|\.gif|px\b|^upright|^thumb|^File:|^Image:|^\W*$|Template:|^Category:|\{\{|\}\})", re.I)


def _short(vals, n=46):
    vals = [v for v in vals if v and not SKIP_VAL.search(v)]
    if not vals:
        return ""
    out = vals[0]
    for v in vals[1:3]:
        if len(out) + len(v) + 2 > n:
            break
        out += ", " + v
    out = re.sub(r"^\([^)]*\)[\s:,]*", "", out)
    out = re.sub(r"\s+", " ", out).strip(" ,;")
    if len(out) > n + 14:
        out = out[:n + 10].rsplit(" ", 1)[0] + "..."
    return out


def _stats(world, box, sents, sub):
    fields = {}
    for _, f in box:
        for k, v in f.items():
            fields.setdefault(_norm(k), v)
    rows = []
    used = set()
    for key, label in STAT_KEYS[world]:
        if label in used or key not in fields:
            continue
        v = _short(fields[key])
        if not v or v.lower() in ("yes", "no", "none", "n/a"):
            continue
        if label in ("HEIGHT", "WEIGHT") and world == "sports":
            v = _units(fields, key) or v
        rows.append([label, sub(v)])
        used.add(label)
    # Stat lines of a player's infobox: stat1label / stat1value.
    if world == "sports":
        for i in range(1, 6):
            lab, val = fields.get("stat%dlabel" % i), fields.get("stat%dvalue" % i)
            if lab and val:
                rows.insert(min(len(rows), 2 + i), [_short(lab, 24).upper(), _short(val, 24)])
    # Review scores.
    if world == "games":
        rv = []
        for key, name, scale in (("mc", "Metacritic", "/100"), ("fam", "Famitsoo", ""), ("gr", "GameRankinz", "%"), ("ign", "IGM", ""),
                                 ("egm", "EGM", ""), ("np", "Funtendo Power", ""), ("edge", "Edge", "")):
            hit = next((fields[k] for k in fields if (k == key or (k.startswith(key) and len(k) <= len(key) + 4 and k[len(key):].isalpha()))), None)
            if hit:
                v = _short(hit, 14)
                if v and re.search(r"\d", v):
                    rv.append("%s %s%s" % (name, v, scale if "/" not in v and "%" not in v else ""))
        if rv:
            rows.insert(min(len(rows), 4), ["REVIEWS", ", ".join(rv[:3])])
    # Numbers only the prose has.
    blob = " ".join(s for _, s in sents)
    lead = " ".join(s for sec, s in sents[:6])
    NAME = r"((?:[A-Z][\w&.'\-]*|of|and|de)(?: (?:[A-Z][\w&.'\-]*|of|and|de))*)"
    for verb, label in (("developed", "DEVELOPER"), ("published", "PUBLISHER"), ("manufactured", "MAKER"), ("designed", "DESIGNER"),
                        ("composed", "COMPOSER"), ("written", "WRITER"), ("illustrated", "ILLUSTRATOR"), ("directed", "DIRECTOR"),
                        ("produced", "PRODUCER"), ("released", "PUBLISHER"), ("recorded", "ARTIST"), ("engraved", "ENGRAVER"), ("struck", "STRUCK AT")):
        if len(rows) >= MAX_STATS or any(r[0] == label for r in rows):
            continue
        m = re.search(r"\b" + verb + r" (?:and [a-z]+ )?by " + NAME, lead)
        if m and len(m.group(1)) < 40 and not m.group(1).startswith(("The ", "A ")):
            rows.append([label, m.group(1).rstrip(".")])
    if not any(r[0] in ("RELEASED", "LAUNCHED", "PUBLISHED", "COVER DATE", "BORN", "YEARS STRUCK") for r in rows):
        m = re.search(r"\b(?:released|published|launched|issued|struck|minted|introduced|first sold)\b[^.]{0,60}?\b(?:in|on) ((?:[A-Z][a-z]+ )?(?:\d{1,2}, )?(?:1[5-9]\d\d|20[0-2]\d))", lead)
        if m:
            rows.append(["RELEASED" if world in ("games", "vinyl", "cards") else "FIRST OUT", m.group(1)])
    m = re.search(r"\b(sold|shipped|sales of|selling)\b[^.]{0,40}?\b((?:over |more than |nearly |about |approximately |around |an estimated )?[\d.,]+ (?:million|billion|thousand)?\s*(?:copies|units|consoles|records|systems|cards|packs)?)", blob)
    if m and "UNITS SOLD" not in used and re.search(r"(million|billion|thousand|copies|units|records)", m.group(2)):
        rows.append(["SOLD", m.group(2).strip()])
    m = re.search(r"\b(?:sold|auctioned|bought|purchased|went)\b[^.]{0,50}?\bfor\b (?:a record )?((?:US)?\$[\d.,]+(?: million| billion)?)", blob)
    if m:
        rows.append(["BIG SALE", m.group(1).replace("US$", "$").rstrip(".,")])
    if world == "coins" and "MINTAGE" not in used:
        m = re.search(r"\b(?:only|just|mintage of|total of)\s+([\d,]+)\s+(?:were|was|coins|pieces|struck|minted)", blob)
        if m:
            rows.append(["MINTAGE", m.group(1)])
    return rows[:MAX_STATS]


def _units(fields, key):
    if key.startswith("height"):
        ft, inch = fields.get("heightft"), fields.get("heightin")
        if ft:
            return "%s ft %s in" % (ft[0], inch[0] if inch else "0")
    if key.startswith("weight"):
        lb = fields.get("weightlb") or fields.get("weightlbs")
        if lb:
            return "%s lb" % lb[0]
    return ""


def _year(world, box, sents):
    fields = {}
    for _, f in box:
        for k, v in f.items():
            fields.setdefault(_norm(k), v)
    for key in ("released", "release", "releasedate", "pubdate", "published", "date", "publishdate", "years", "yearsofminting"):
        if key in fields:
            m = re.search(r"\b(1[0-9]\d\d|20[0-2]\d)\b", " ".join(fields[key]))
            if m:
                return int(m.group(1))
    return 0


# ------------------------------------------------------------------ history panels
PANELS = {
    "games": [("BEHIND THE SCENES", r"develop|production|creation|concept|design|background|history|origin|making|prototype"),
              ("LAUNCH", r"release|marketing|launch|promotion|distribution|localiz|translation|version|port"),
              ("RECEPTION", r"reception|sales|critical|commercial|review|response|performance|award"),
              ("HOW IT PLAYS", r"gameplay|plot|story|synopsis|setting|characters|features|hardware|specification|technical|design|games|library|accessor"),
              ("LEGACY", r"legacy|impact|influence|aftermath|re-?release|remake|sequel|cultural|popular culture|value|collect|rarity|surviv|competition|emulat|homebrew")],
    "cards": [("ORIGIN", r"concept|creation|design|develop|origin|history|background|printing"),
              ("IN THE GAME", r"appearance|gameplay|video game|trading card|card game|anime|in other media|abilities|rules|format|play"),
              ("RECEPTION", r"reception|popularity|response|critical|impact"),
              ("COLLECTOR LORE", r"value|sale|auction|collect|rarity|price|market|legacy|merchandise|banned|restricted|reserved")],
    "coins": [("THE STORY", r"background|history|origin|inception|legislation|authoriz|preparation|conception"),
              ("MINTING", r"production|mint|striking|design|creation|struck|coinage"),
              ("THE DESIGN", r"design|description|obverse|reverse|motif"),
              ("COLLECTOR LORE", r"collect|value|rarity|surviv|known specimens|provenance|sale|auction|legacy|aftermath|varieties|hoard|release|recall|melt")],
    "sports": [("EARLY DAYS", r"early life|youth|childhood|amateur|high school|college|education|background"),
               ("ON THE FIELD", r"career|professional|season|19\d\d|20\d\d|major league|minor league|nba|nfl|nhl|club|international|playing|draft|olympic|rookie"),
               ("OFF THE FIELD", r"personal|death|later life|retirement|business|post-|broadcasting|politic|philanthrop|outside"),
               ("LEGACY", r"legacy|honors|honours|awards|hall of fame|accomplish|achievement|records|statistics|memorabilia|card")],
    "comics": [("BEHIND THE PANELS", r"creation|concept|develop|background|history|origin|publication|production|creators"),
               ("THE STORY", r"plot|story|synopsis|contents|summary|fictional|characters|premise"),
               ("RECEPTION", r"reception|sales|response|critical|impact|popularity|circulation"),
               ("COLLECTOR LORE", r"value|collect|copies|sale|auction|census|legacy|record|price|reprint|rarity|cultural")],
    "books": [("WRITING IT", r"background|writing|composition|develop|creation|origin|inspiration|history|conception|production|printing"),
              ("THE STORY", r"plot|summary|synopsis|story|contents|themes|characters|structure|style|description"),
              ("PUBLICATION", r"publication|release|editions|publishing|printing|first edition|censor|ban"),
              ("RECEPTION", r"reception|critical|response|reviews|sales|controvers"),
              ("COLLECTOR LORE", r"legacy|influence|copies|census|provenance|surviv|auction|sale|value|collect|adaptation|cultural")],
    "vinyl": [("IN THE STUDIO", r"background|recording|production|composition|writing|develop|history|sessions|origin"),
              ("THE MUSIC", r"music|lyrics|songs|style|composition|themes|content|tracks"),
              ("THE SLEEVE", r"artwork|cover|packaging|sleeve|design|title|label"),
              ("RELEASE", r"release|promotion|marketing|single|pressing|withdrawn|banned|controvers|reissue"),
              ("THE CHARTS", r"reception|chart|commercial|critical|sales|performance|reviews"),
              ("LEGACY", r"legacy|influence|accolade|ranking|value|collect|cover version|sample|impact|cultural")],
}
LOWDOWN = {"games": "THE LOWDOWN", "cards": "THE LOWDOWN", "coins": "THE LOWDOWN", "sports": "THE PLAYER", "comics": "THE ISSUE",
           "books": "THE BOOK", "vinyl": "THE RECORD"}
FUN = re.compile(r"\b(million|billion|record|first|only|last|largest|biggest|most|best-selling|bestselling|rarest|rare|highest|lowest|fewer than|never|"
                 r"banned|recalled|lawsuit|sued|secret|hidden|accident|originally|nicknamed|named after|inspired|Guinness|auction|stolen|"
                 r"destroyed|melted|unique|famous|legend|cult|controvers|censor|prototype|cancel|scrapped|surviv|unreleased|limited|"
                 r"youngest|oldest|fastest|perfect|unanimous|forgot|joke|refused|fired|mistake|error|misprint|counterfeit|fake|"
                 r"worth|\$|¥|£|€)\b|[$¥£€]", re.I)
PRONOUN = re.compile(r"^(It|This|These|Those|He|She|They|His|Her|Its|Their|The two|Both|However|Also|In addition|Additionally|Furthermore|Meanwhile|Instead)\b")
BADS = re.compile(r"(citation needed|ISBN|pp\.|\bp\. \d|Retrieved|\bibid\b|\[\s*\]|\{|\}|=|http|www\.|\|)", re.I)


def _score(s):
    sc = 0.0
    sc += min(3, len(re.findall(r"\d[\d,.]*", s))) * 1.5
    sc += min(3, len(FUN.findall(s))) * 2.5
    if PRONOUN.match(s):
        sc -= 2.5
    if len(s) > 230:
        sc -= 2
    if len(s) < 60:
        sc -= 1.5
    if BADS.search(s):
        sc -= 20
    if re.search(r"^[^.]{0,40}\b(he|she|they|it)\b (said|stated|expressed|noted|added|argued|felt|called|described|wrote|claimed)\b", s):
        sc -= 4
    return sc


KW_PANEL = {
    "BEHIND THE SCENES": r"\b(developed|designed|created|directed|produced|programmed|development|composed|team)\b",
    "LAUNCH": r"\b(released|launched|published|debuted|ported|localized|launch)\b",
    "RECEPTION": r"\b(sold|reception|acclaim|praised|critics|rated|review|reviewers|best-selling|commercial)\b",
    "LEGACY": r"\b(legacy|influenc|considered|regarded|remake|sequel|remaster|rare|auction|collector|greatest)\b",
    "ON THE FIELD": r"\b(season|games|played|scored|drafted|traded|won|MVP|All-Star|championship|goals|points|touchdowns|home runs)\b",
    "LEGACY ": r"\b(Hall of Fame|inducted|regarded|greatest|legacy|retired)\b",
    "THE STORY": r"\b(story|plot|follows|tells|narrat|character)\b",
    "MINTING": r"\b(struck|minted|mint|designed|engraver|coinage)\b",
    "COLLECTOR LORE": r"\b(auction|collector|specimens|known|surviv|sold|rarest|value|worth|price)\b",
    "IN THE STUDIO": r"\b(recorded|produced|studio|sessions|wrote)\b",
    "THE CHARTS": r"\b(chart|peaked|number one|Billboard|sold|certified|platinum|gold)\b",
    "RELEASE": r"\b(released|issued|withdrawn|single|pressing)\b",
    "PUBLICATION": r"\b(published|first edition|printed|copies|publisher)\b",
    "WRITING IT": r"\b(wrote|written|began|inspired|manuscript|draft)\b",
    "EARLY DAYS": r"\b(born|grew up|childhood|high school|college)\b",
    "ORIGIN": r"\b(designed|created|illustrated|printed|introduced)\b",
    "BEHIND THE PANELS": r"\b(created|written|drawn|editor|published)\b",
}


def _tidy(s):
    """Drop pronunciation guides, native spellings and inflation notes; fix spacing."""
    s = re.sub(r"\s*\((?:equivalent to|about|approx\.?) [^)]*\)", "", s)
    s = re.sub(r"\s*\([^()]*?(?:/[^/]*/|Japanese:|Hepburn|pronounced|lit\.|romanized|Korean:|Chinese:|IPA)[^()]*\)", "", s)
    s = re.sub(r"\s+'s\b", "'s", s)
    s = re.sub(r"\(\s*[;,]?\s*\)", "", s)
    return re.sub(r"\s{2,}", " ", s).strip()


def _same(a, b):
    wa = set(re.findall(r"[a-z0-9]{3,}", a.lower()))
    wb = set(re.findall(r"[a-z0-9]{3,}", b.lower()))
    return len(wa & wb) > 0.5 * min(len(wa), len(wb)) if wa and wb else False


def _join(a, b, cap=270):
    return a + " " + b if b and len(a) + len(b) + 1 <= cap else a


def _hist(world, sents, kind, seed=""):
    """seed != "": the article is shared with other items (a card's species, a coin's
    series), so pick among the good sentences by seed instead of always the best."""
    import hashlib

    def choose(cand, tag):
        if not seed or not cand:
            return cand[0] if cand else ""
        good = [c for c in cand[:8] if _score(c) >= _score(cand[0]) - 4] or cand[:1]
        return good[int(hashlib.md5((seed + tag).encode()).hexdigest(), 16) % len(good)]

    sents = [(sec, re.sub(r"\s+([,.;:!?])", r"\1", _tidy(s))) for sec, s in sents if not BADS.search(s) and re.match(r"^[A-Z\"'‘“]", s)
             and s.count("(") == s.count(")") and s.count('"') % 2 == 0]
    if not sents:
        return []
    panels = list(PANELS[world])
    if not any(n == "COLLECTOR LORE" for n, _ in panels):
        panels.insert(len(panels) - 1, ("COLLECTOR LORE", r"value|collect|rarity|price|auction"))
    money = re.compile(r"\b(sells?|sold for|resold|auction|auctioned|eBuy|collectors?|collectible|rarest|rarity|mint condition|graded|USD|"
                       r"price guide|worth)\b|\$[\d,.]+", re.I)
    used = set()
    out = []
    lead = [s for sec, s in sents if sec == "lead"]
    if lead and seed:
        pick1 = choose(sorted(lead, key=lambda x: -_score(x)), "lead")
        out.append(["THE BACKSTORY", pick1])
        used.add(pick1)
        lead = []
    if lead:
        first = lead[0]
        nxt = lead[1] if len(lead) > 1 else ""
        out.append([LOWDOWN[world] if kind not in ("wax", "pack", "crate", "longbox", "booklot") else "THE LOWDOWN", _join(first, nxt if not PRONOUN.match(nxt) or len(first) < 140 else "", 300)])
        used.add(first)
        if out[0][1] != first:
            used.add(nxt)
    pools = {}
    for name, rx in panels:
        r = re.compile(rx, re.I)
        if name == "COLLECTOR LORE":
            # Anything about prices, sales and rarity, from any section: it's a collecting game.
            pools[name] = [s for sec, s in sents if money.search(s) and s not in used]
        else:
            pools[name] = [s for sec, s in sents if sec != "lead" and r.search(sec) and s not in used and not money.search(s)]
    # Lead-only articles (or empty sections): sort sentences by keywords instead.
    for name, _ in panels:
        if len(pools[name]) < 2:
            kw = KW_PANEL.get(name) or KW_PANEL.get(name + " ")
            if kw:
                r = re.compile(kw, re.I)
                pools[name] += [s for _, s in sents if r.search(s) and s not in used and s not in pools[name]]
    for name, _ in panels:
        cand = sorted([s for s in pools[name] if s not in used and not any(_same(s, u) for u in used)], key=lambda s: -_score(s))
        if not cand or _score(cand[0]) < 1.0:
            continue
        best = choose(cand, name)
        used.add(best)
        # One follow-up sentence from the same pool when both are short.
        two = next((s for s in cand[:4] if s not in used and _score(s) > 3 and len(best) + len(s) < 250), "")
        if two:
            used.add(two)
        out.append([name, _join(best, two)])
    rest = sorted([s for _, s in sents if s not in used], key=lambda s: -_score(s))
    if seed and rest:
        k = int(hashlib.md5((seed + "rest").encode()).hexdigest(), 16) % min(len(rest), 6)
        rest = rest[k:] + rest[:k]
    extra = 0
    for s in rest[:12]:
        if extra < 2 and _score(s) >= 4.0 and not any(_same(s, u) for u in used):
            out.append(["DID YOU KNOW" if extra == 0 else "ONE MORE THING", s])
            used.add(s)
            extra += 1
    return out[:7]


# ------------------------------------------------------------------ build
def _item_subs(world, it, rec, defs):
    """Real name -> parody name pairs that only make sense for this item."""
    d = defs.get(it, {})
    pairs = []
    real = rec.get("real", "")
    name = d.get("name", "")
    title = rec.get("title", "")
    if name and real and world != "sports":  # a sports row's real name is the player, not the card
        pairs.append((real, name))
        rb = re.sub(r"\s*\([^)]*\)$", "", real)
        pb = re.sub(r"\s*\([^)]*\)$", "", name)
        pairs.append((rb, pb))
        if title and title != real and world == "games":
            import gen_catalog
            tb = re.sub(r"\s*\([^)]*\)$", "", title)
            pairs.append((tb, gen_catalog.parody(tb)))
    # The article's own subject (a player, an author, a band): its surname alone too.
    for a, b in table(world):
        if title and a == re.sub(r"\s*\([^)]*\)$", "", title) and " " in a:
            pairs += _word_diffs([(a, b)])
    for _, f in rec.get("boxes", []):
        for k, vals in f.items():
            if _norm(k) in PEOPLE_KEYS:
                for v in vals:
                    for p in (_mangle_person(v.strip()) or []):
                        pairs.append(p)
    return pairs


def _defs():
    """id -> catalog def (name, kind...) read from the generated catalogs."""
    out = {}
    for f in os.listdir(os.path.join(ROOT, "scripts", "data")):
        if f.startswith("catalog") and f.endswith(".gd"):
            for line in open(os.path.join(ROOT, "scripts", "data", f), encoding="utf-8"):
                m = re.search(r'"id": "([^"]+)", "name": "((?:[^"\\]|\\.)*)", "plat": "([^"]+)", "kind": "([^"]+)"', line)
                if m:
                    out[m.group(1)] = {"name": json.loads('"' + m.group(2) + '"'), "plat": m.group(3), "kind": m.group(4)}
    return out


def build_world(world, defs):
    path = os.path.join(DATA, world + ".json")
    if not os.path.exists(path):
        print("  no %s (run fetch first)" % path)
        return {}
    data = json.load(open(path, encoding="utf-8"))
    base = table(world)
    if world in ("games", "cards"):
        base = base + _word_diffs([(r["real"], defs[i]["name"]) for i, r in data.items() if i in defs])
    out = {}
    for iid, rec in data.items():
        if iid not in defs:
            continue
        sub = Sub(_item_subs(world, iid, rec, defs) + base)
        kind = defs[iid]["kind"]
        sents = [(sec, sub(s)) for sec, s in rec["sents"]]
        stats = _stats(world, rec["boxes"], sents, sub)
        hist = _hist(world, sents, kind, iid if rec.get("shared") else "")
        if not stats and not hist:
            continue
        yr = _year(world, rec["boxes"], rec["sents"])
        if yr == 0:
            for lab, v in stats:
                m = re.search(r"\b(1[5-9]\d\d|20[0-2]\d)\b", v) if lab in ("RELEASED", "FIRST OUT", "PUBLISHED", "LAUNCHED", "COVER DATE") else None
                if m:
                    yr = int(m.group(1))
                    break
        out[iid] = {"stats": stats, "hist": [[h, sub(t)] for h, t in hist], "year": yr}
    return out


def write(world, facts):
    lines = ["extends RefCounted",
             "## GENERATED by tools/wiki_facts.py build %s from Wikipedia (tools/wiki/%s.json)." % (world, world),
             "## Real stats and history per item, parodied. Do not edit by hand.",
             "## No class_name (TV self-update): Flavor loads this file when it's needed.", "",
             "const FACTS := {"]
    for iid, f in facts.items():
        lines.append("\t%s: %s," % (json.dumps(iid), json.dumps(f, ensure_ascii=False)))
    lines.append("}")
    lines.append("")
    p = os.path.join(ROOT, "scripts", "data", "facts_%s.gd" % world)
    open(p, "w", encoding="utf-8").write("\n".join(lines))
    print("  %s: %d items -> %s (%d KB)" % (world, len(facts), os.path.relpath(p, ROOT), os.path.getsize(p) // 1024))


def main(worlds):
    defs = _defs()
    for w in worlds:
        write(w, build_world(w, defs))


def show(iid):
    defs = _defs()
    for w in ("games", "cards", "coins", "sports", "comics", "books", "vinyl"):
        p = os.path.join(DATA, w + ".json")
        if os.path.exists(p) and iid in json.load(open(p, encoding="utf-8")):
            f = build_world(w, defs).get(iid)
            print(json.dumps(f, indent=1, ensure_ascii=False))
            return
    print("not found")
