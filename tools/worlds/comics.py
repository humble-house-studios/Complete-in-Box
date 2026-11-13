"""Comics (Uncle Hector's world) for tools/gen_worlds.py.

Pages / platforms by era: GLDN Golden Age, SLVR Silver Age, BRNZ Bronze Age,
MODN Modern, INDY Indie, Manga & Underground. Kinds: comic (a single issue)
and longbox (a box of comics you can dig through, like a wax box).
List columns used: name = title + issue, detail = why it matters,
team = publisher, pos = key character, wiki = cover / character pages.
"""
import re

LIST = "comics_top_250.txt"
GRAILS = {"GLDN": 2, "SLVR": 2, "BRNZ": 1, "MODN": 1, "INDY": 1}
## Wikipedia lead images shaped like a cover are used as the whole front.
COVER_ASPECT = 0.66
PHOTO_ASPECT = 0.9
NO_PHOTO_KINDS = ("longbox",)

COMIC_BANDS = [(4, 18), (24, 80), (100, 360), (1300, 6000)]
BOX_BANDS = [(18, 50), (60, 160), (180, 560), (1800, 7000)]

## Real names -> parody names (titles, characters, publishers). Longest first.
SUBS = [
    ("Amazing Spider-Man", "Amazin' Spyder-Man"), ("Spider-Man", "Spyder-Man"), ("Spider-Verse", "Spyder-Verse"),
    ("Spider-Gwen", "Spyder-Gwen"), ("Superman", "Supraman"), ("Batman Adventures", "Batmun Adventures"), ("Batman", "Batmun"),
    ("Wonder Woman", "Wander Woman"), ("Captain America Comics", "Captain Amerigo Comics"), ("Captain America", "Captain Amerigo"),
    ("Captain Marvel", "Captain Marbel"), ("Ms. Marvel", "Ms. Marbel"), ("Marvel Premiere", "Marbel Premier"),
    ("Marvel Spotlight", "Marbel Spotlite"), ("Marvel Comics", "Marbel Comics"), ("Marvel", "Marbel"),
    ("Action Comics", "Akshun Comics"), ("Detective Comics", "Detektiv Comics"), ("Fantastic Four", "Fantastik Four"),
    ("Incredible Hulk", "Incredible Hulc"), ("Hulk", "Hulc"), ("Uncanny X-Men", "Uncanni Ex-Men"), ("X-Men", "Ex-Men"),
    ("Iron Man", "Irun Man"), ("Iron Fist", "Irun Fist"), ("Thor", "Thorr"), ("Avengers", "Avengerz"),
    ("Justice League", "Justice Leeg"), ("Flash Comics", "Flasch Comics"), ("Flash", "Flasch"), ("Green Lantern", "Green Lanturn"),
    ("Green Arrow", "Green Arro"), ("Silver Surfer", "Silver Surfur"), ("Doctor Strange", "Doctor Stranje"), ("Ant-Man", "Aunt-Man"),
    ("Daredevil", "Daredevvil"), ("Black Panther", "Black Panter"), ("Kingpin", "Kingpinn"), ("Poison Ivy", "Poison Ivie"),
    ("Wolverine", "Wolvereen"), ("Punisher", "Punnisher"), ("Thanos", "Thanoz"), ("Swamp Thing", "Swamp Thang"),
    ("Star Wars", "Star Warz"), ("Luke Skywalker", "Luke Skyrunner"), ("Moon Knight", "Moon Nite"), ("Ghost Rider", "Ghost Ryder"),
    ("Gwen Stacy", "Gwen Stacey"), ("Elektra", "Elecktra"), ("New Teen Titans", "New Teen Tytans"), ("Deathstroke", "Deathstrok"),
    ("Conan the Barbarian", "Conann the Barbarian"), ("Conan", "Conann"), ("Howard the Duck", "Howie the Duck"),
    ("Venom", "Venum"), ("New Mutants", "New Mutantz"), ("Deadpool", "Deadpull"), ("Harley Quinn", "Harlee Quinn"),
    ("The Dark Knight Returns", "The Dark Nite Returns"), ("Watchmen", "Watchmenn"), ("Walking Dead", "Walkin' Dead"),
    ("Rick Grimes", "Rick Grymes"), ("Ultimate Fallout", "Ultimate Fallin'"), ("Miles Morales", "Miles Moralez"), ("Spawn", "Spawwn"),
    ("Sandman", "Sandmann"), ("Edge of", "Edje of"), ("Carnage", "Karnage"), ("Saga", "Sagga"), ("The Killing Joke", "The Killin' Joke"),
    ("Gambit", "Gambitt"), ("Kingdom Come", "Kingdom Comes"), ("Invincible", "Invinsible"),
    ("Teenage Mutant Ninja Turtles", "Teenage Mutant Ninja Tortoises"), ("TMNT", "TMNT-ish"), ("Zap Comix", "Zapp Comix"),
    ("Akira", "Akirra"), ("Kaneda", "Kanedda"), ("Cerebus", "Cereboss"), ("Hellboy", "Hellboi"), ("Seed of Destruction", "Seed of Distraction"),
    ("Fone Bone", "Phone Bone"), ("Bone", "Bonne"), ("Dark Horse Presents", "Dark Hoarse Presents"), ("Dark Horse", "Dark Hoarse"),
    ("Dragon Ball", "Dragon Bawl"), ("Goku", "Gokku"), ("One Piece", "One Peace"), ("Luffy", "Luffie"), ("The Crow", "The Krow"),
    ("Raw", "Rawr"), ("ElfQuest", "ElfQuesst"), ("Love and Rockets", "Love and Rokkets"), ("Usagi Yojimbo", "Usagi Yojimbro"),
    ("Asterix the Gaul", "Asterisk the Gaul"), ("Asterix", "Asterisk"), ("Tintin", "Tinntin"), ("Scott Pilgrim", "Scott Pilgrum"),
    ("Strangers in Paradise", "Strangers in Paradice"), ("Hate", "Haet"), ("Showcase", "Showkase"),
    ("Brave and the Bold", "Brave and the Bald"), ("Strange Tales", "Strange Talez"), ("Tales to Astonish", "Tales to Astonnish"),
    ("Tales of Suspense", "Tales of Suspence"), ("Journey into Mystery", "Journey into Mistery"), ("Amazing Fantasy", "Amazin' Fantasy"),
    ("Whiz Comics", "Wizz Comics"), ("All Star Comics", "All Starr Comics"), ("All-American Comics", "All-Amerikan Comics"),
    ("Pep Comics", "Pepp Comics"), ("More Fun Comics", "More Funn Comics"), ("Sensation Comics", "Sensashun Comics"),
    ("Planet Comics", "Planit Comics"), ("Tales from the Crypt", "Tales from the Krypt"), ("Crypt Keeper", "Krypt Keeper"),
    ("Four Color", "Four Kolor"), ("Donald Duck", "Ronald Duck"), ("Crime Does Not Pay", "Crime Doesn't Pay"), ("Giant-Size", "Jumbo-Size"),
    ("Werewolf by Night", "Werewolf by Nite"), ("Human Torch", "Human Torchh"), ("Robin", "Robbin"), ("Archie", "Arkie"),
    ("Spectre", "Spektre"), ("Joker", "Jokker"), ("Storm", "Storrm"), ("Cyclops", "Cyclopps"), ("Kitty Pryde", "Kitty Pride"),
    ("Kamala Khan", "Kamala Kan"), ("Dream", "Dreem"), ("Rorschach", "Rorshack"), ("Mr. Natural", "Mr. Naturall"),
    ("Katchoo", "Katchu"), ("Buddy Bradley", "Buddy Bradlee"), ("Cutter", "Kutter"), ("Maggie", "Maggy"), ("Usagi", "Usagy"),
    ("Alana", "Alanna"), ("Marv", "Marve"),
]
PUBS = {
    "DC": "DK Comics", "Marvel": "Marbel", "Timely": "Timelee", "Fawcett": "Fawcette", "MLJ": "MLJ-ish", "Fiction House": "Fiction Haus",
    "EC": "EZ Comics", "Dell": "Dells", "Lev Gleason": "Lev Gleeson", "Image": "Imaje", "Mirage": "Mirrage", "Dark Horse": "Dark Hoarse",
    "Shueisha": "Shueysha", "Fantagraphics": "Fantagraffix", "Epic": "Epik", "Oni": "Onni", "Caliber": "Calibur", "Casterman": "Kasterman",
    "Dargaud": "Dargo", "Antarctic": "Antartic", "Cartoon Books": "Cartoon Bookz", "Aardvark-Vanaheim": "Aardvark-Vanahome",
    "Apex Novelties": "Apex Novelteez", "WaRP": "WaRPP", "Raw Books": "Rawr Books", "Various": "Various",
}

BLURB = {
    "GLDN": ["Printed on paper that crumbles if you breathe on it. Ten cents at the drugstore in a year of rationing.",
             "Kids read these to pieces and mothers burned the rest. That's why so few are left.",
             "Brittle, yellowed and worth more than the house it was found in.",
             "Somebody's dad kept this in a footlocker through a war."],
    "SLVR": ["Twelve cents, a spinner rack and a universe being invented month by month.",
             "The Marbel age begins: heroes with problems, and readers who wrote in.",
             "Every kid had one. Every mum threw it out. Some survived in attics.",
             "The paper has gone the colour of weak tea. The story hasn't aged a day."],
    "BRNZ": ["Thirty cents, newsprint and a whole lot of attitude.",
             "The decade heroes got gritty and comics got serious.",
             "Bought off a newsstand, read on a school bus, kept in a shoebox.",
             "Somebody wrote their name in pen inside the cover. Classic."],
    "MODN": ["Bagged and boarded the day it came out, for the price of a sandwich.",
             "The speculator boom printed millions. This one people actually wanted.",
             "Pulled from the new-releases wall on a Wednesday.",
             "Variant covers, foil logos and a market that went bang."],
    "INDY": ["Self-published, photocopied, stapled at a kitchen table.",
             "From the small presses, the head shops and the far side of the world.",
             "A print run small enough to count by hand.",
             "Cult classic. The fans know. Everyone else is catching up."],
}
BOX_BLURB = ["A longbox nobody has sorted since it was taped shut. Smells like a basement.",
             "Somebody's whole childhood, alphabetised in marker on the side.",
             "Heavy enough to hurt. Damp at one corner. Promising.",
             "Hector's handwriting on the lid: DO NOT SELL."]
## The fakes and restoration comics are known for.
TELLS_KNOWN = {
    "Action Comics #1": "Facsimile reprints by the thousand: the real one has a 10 cent price and brittle cream paper.",
    "Detective Comics #27": "Married covers: a nicer cover stapled to a different, worse interior.",
    "Amazing Fantasy #15": "Colour touch on the spine: the restored ones glow purple under a blacklight.",
    "Incredible Hulk #181": "The Mark Jewelers insert edition passes for newsstand. Check the middle staple.",
    "Star Wars #1": "The 35 cent price variant is faked with a pasted-on price box. Look for a halo round the 35.",
    "New Mutants #98": "Pressed to hide spine ticks. Fine, unless the seller calls it untouched.",
}
TELLS = {
    "comic": ["Colour touch on the cover: a restored copy is worth half.", "Pressed flat to hide creases: legal, but say so.",
              "A married cover from another copy.", "Trimmed edges to look sharp: measure it.", "A facsimile reprint passed off as real.",
              "Missing a coupon page: check the back pages.", "Rusted staples swapped for new ones."],
    "longbox": ["Picked over: the keys were pulled before you got here.", "Stacked wet at the bottom: mildew.",
                "Taped shut twice. Somebody looked."],
}
PRICE = {"GLDN": "10¢", "SLVR": "12¢", "BRNZ": "35¢", "MODN": "$1.95", "INDY": "$2.00"}


def _sub(s):
    keys = [a for a, _ in SUBS]
    m = dict(SUBS)
    keys.sort(key=len, reverse=True)
    return re.sub("|".join(re.escape(k) for k in keys), lambda x: m[x.group(0)], s)


def make_item(r, tier, frac, u):
    h = u["h"]
    real = r["name"]
    code = r["code"]
    kind = "longbox" if r["kind"] == "longbox" else "comic"
    pname = _sub(real)
    tags = list(r["tags"])
    if kind == "longbox":
        tags.append("box")
    iid = code.lower() + "_" + u["slug"](pname)
    m = re.search(r"#(\d+)", real)
    issue = m.group(1) if m else ("1" if "one" in tags else "")
    d = {"id": iid, "name": pname, "plat": code, "kind": kind, "tier": tier,
         "base": u["base_for"](BOX_BANDS if kind == "longbox" else COMIC_BANDS, tier, frac, real),
         "tags": tags, "real_section": r["section"], "pub": PUBS.get(r["team"], _sub(r["team"])), "genre": "Comic",
         "set": _sub(real.split("#")[0].strip()), "issue": issue, "char": _sub(r["pos"]) if r["pos"] != "-" else "",
         "note": _sub(r["detail"]), "price": PRICE[code], "wiki": r["wiki"]}
    if kind == "longbox":
        d["blurb"] = BOX_BLURB[h(real + "b", len(BOX_BLURB))]
        d["count"] = 150 + h(real + "c", 150)
        d["rarity"] = "Longbox"
        d["tell"] = TELLS["longbox"][h(real + "t", len(TELLS["longbox"]))]
    else:
        d["blurb"] = _sub(r["detail"]) + ". " + BLURB[code][h(real + "b", len(BLURB[code]))]
        d["rarity"] = "Key Issue" if "key" in tags else ("First Issue" if "one" in tags else ["Reader", "Collectable", "Sought After", "Holy Grail"][tier])
        d["tell"] = TELLS_KNOWN.get(real, TELLS["comic"][h(real + "t", len(TELLS["comic"]))])
        d["pages"] = 32 + 4 * h(real + "p", 13) if code != "INDY" else 24 + 8 * h(real + "p", 25)
    ranges = [(150000, 900000), (40000, 150000), (2000, 40000), (50, 2000)]
    lo, hi = ranges[tier]
    d["run"] = lo + h(real + "run", hi - lo)
    if code == "GLDN" and tier >= 2:
        d["run"] = 50 + h(real + "run", 300)
    d["rating"] = ""
    return d
