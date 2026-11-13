"""Sports cards (Grandma Rose's world) for tools/gen_worlds.py.

Pages / platforms: BASE baseball, HOOP basketball, GRID football, PUCK hockey,
FUTB soccer & other sports. Kinds: scard (a single) and wax (packs and boxes).
"""

LIST = "sports_cards_top_250.txt"
## GRAILS per page: the top N lines of each page.
## Kinds painted without a fetched photo (wax art is all drawn).
SCAN_SEARCH = True
PHOTO_ASPECT = 0.78
NO_PHOTO_KINDS = ("wax",)
GRAILS = {"BASE": 2, "HOOP": 2, "GRID": 1, "PUCK": 1, "FUTB": 1}

## Same value bands as the TCG world so the two play alike.
CARD_BANDS = [(4, 18), (24, 80), (100, 360), (1300, 6000)]
WAX_BANDS = [(18, 50), (60, 160), (180, 560), (1800, 7000)]

PLAYERS = {
    "Honus Wagner": "Honus Waggoner", "Mickey Mantle": "Mickey Mantel", "Babe Ruth": "Babe Rooth",
    "Mike Trout": "Mike Troutt", "Jackie Robinson": "Jackie Robison", "Roberto Clemente": "Roberto Clemento",
    "Ty Cobb": "Ty Kobb", "Hank Aaron": "Hank Aron", "Shohei Ohtani": "Shohei Ohtanni", "Willie Mays": "Willie Mayes",
    "Sandy Koufax": "Sandy Kofax", "Ken Griffey Jr.": "Ken Griffin Jr.", "Nolan Ryan": "Nolan Rhyan",
    "Derek Jeter": "Derek Jetter", "Cal Ripken Jr.": "Cal Ripkin Jr.", "Pete Rose": "Pete Rosé",
    "Billy Ripken": "Billy Ripkin",
    "Michael Jordan": "Michael Jorden", "LeBron James": "LeBrawn James", "George Mikan": "George Mikkan",
    "Lew Alcindor": "Lew Alcinder", "Kobe Bryant": "Kobi Bryan", "Stephen Curry": "Stephen Kurry",
    "Wilt Chamberlain": "Wilt Chamberlin", "Bird / Magic / Erving": "Byrd / Majic / Ervin", "Bill Russell": "Bill Russel",
    "Luka Doncic": "Luka Donchic", "Giannis Antetokounmpo": "Giannis Antetokoumbo", "Victor Wembanyama": "Victor Wembanyamo",
    "Shaquille O'Neal": "Shaquille O'Neil", "Tim Duncan": "Tim Dunkin", "Kevin Durant": "Kevin Durrant",
    "Zion Williamson": "Zion Williamsen", "Dennis Rodman": "Dennis Rodmann",
    "Tom Brady": "Tom Braidy", "Joe Namath": "Joe Namuth", "Jim Brown": "Jim Browne", "Bronko Nagurski": "Bronko Nagurskee",
    "Patrick Mahomes": "Patrick Mahomez", "Walter Payton": "Walter Peyton", "Johnny Unitas": "Johnny Unitus",
    "Joe Montana": "Joe Montanna", "Jerry Rice": "Jerry Ryce", "Peyton Manning": "Peyton Manninger",
    "Barry Sanders": "Barry Sandors", "Dan Marino": "Dan Marini", "John Elway": "John Ellway", "Emmitt Smith": "Emmit Smyth",
    "Lawrence Taylor": "Lawrence Tayler", "Joe Burrow": "Joe Burrough", "Justin Herbert": "Justin Herbet", "Bo Jackson": "Bo Jaxon",
    "Wayne Gretzky": "Wayne Gretsky", "Bobby Orr": "Bobby Oar", "Gordie Howe": "Gordie How", "Mario Lemieux": "Mario Lemieu",
    "Maurice Richard": "Maurice Richart", "Connor McDavid": "Connor MacDavid", "Sidney Crosby": "Sidney Crosbie",
    "Jean Beliveau": "Jean Belliveau", "Patrick Roy": "Patrick Roi", "Alex Ovechkin": "Alex Ovechkine",
    "Terry Sawchuk": "Terry Sawchuck", "Steve Yzerman": "Steve Izerman", "Connor Bedard": "Connor Bedarde",
    "Mark Messier": "Mark Messiér", "Jaromir Jagr": "Jaromir Jager", "Martin Brodeur": "Martin Brodure", "Eric Lindros": "Eric Lindross",
    "Pele": "Pelê", "Lionel Messi": "Lionel Messy", "Diego Maradona": "Diego Maradonna", "Cassius Clay": "Cassius Klay",
    "Tiger Woods": "Tigre Woods", "Cristiano Ronaldo": "Cristiano Ronaldoh", "Kylian Mbappe": "Kylian Mbappo",
    "Johan Cruyff": "Johan Kruyff", "Ayrton Senna": "Ayrton Sena", "Erling Haaland": "Erling Haland",
    "Zinedine Zidane": "Zinedine Zidan", "Lewis Hamilton": "Lewis Hamiltin", "Arnold Palmer": "Arnold Palmar",
    "Mike Tyson": "Mike Tison", "Ronaldo Nazario": "Ronaldó Nazário", "Jude Bellingham": "Jude Bellingam",
    "Usain Bolt": "Usain Bolte", "Conor McGregor": "Conor MacGreggor",
}

## Card makers and set words, longest first when applied.
BRANDS = [
    ("Playoff Contenders", "Playoff Contendaz"), ("National Treasures", "National Treasurez"), ("National Chicle", "National Chiclet"),
    ("Upper Deck", "Upper Dekk"), ("O-Pee-Chee", "O-Pee-Cheep"), ("Topps Chrome", "Toppz Chrome"), ("Bowman Chrome", "Bowmann Chrome"),
    ("Allen & Ginter", "Alan & Ginger"), ("Mega Craques", "Mega Craquez"), ("Megacracks", "Megacrackers"), ("Alifabolaget", "Alfabolaget"),
    ("Hemmets Journal", "Hemmets Journel"), ("Panini", "Panino"), ("Exquisite", "Exquizite"), ("Young Guns", "Young Gunz"),
    ("Parkhurst", "Parkhearst"), ("Goudey", "Gouday"), ("Bowman", "Bowmann"), ("Topps", "Toppz"), ("Fleer", "Fleeb"),
    ("Prizm", "Prism"), ("Score", "Scor"), ("Leaf", "Leef"), ("SP Authentic", "SP Authentik"), ("SP Foil", "SP Foyl"),
    ("Superfractor", "Superfractor"), ("Bundesliga", "Bundesliga"), ("UCL", "Champions Cup"), ("F1", "Formula Fast"),
    ("Formula One Grid", "Formula Won Grid"), ("UFC", "UCF"), ("Calciatori", "Calciatorini"), ("World Cup", "World Cupp"),
]
BRAND_PUB = [("Topps", "Toppz Co."), ("Fleer", "Fleeb Corp."), ("Upper Deck", "Upper Dekk"), ("Bowman", "Bowmann Gum"),
             ("Panini", "Panino"), ("Prizm", "Panino"), ("National Treasures", "Panino"), ("Exquisite", "Upper Dekk"),
             ("O-Pee-Chee", "O-Pee-Cheep Ltd."), ("Parkhurst", "Parkhearst"), ("Goudey", "Gouday Gum Co."), ("Leaf", "Leef Gum"),
             ("Playoff", "Playoff Inc-ish"), ("Score", "Scor Board"), ("SP ", "Upper Dekk"), ("T206", "American Tobacky Co."),
             ("National Chicle", "National Chiclet"), ("Megacracks", "Panino"), ("Mega Craques", "Panino"), ("Alifabolaget", "Alfabolaget"),
             ("Hemmets", "Hemmets Journel"), ("Calciatori", "Panino"), ("Golf Stars", "Donrust"), ("Sport Stars", "Donrust"),
             ("Formula One", "Grid Cards Ltd."), ("Allen", "Toppz Co.")]
TEAM_WORDS = [
    ("Yankees", "Yankers"), ("Pirates", "Pilots"), ("Angels", "Angles"), ("Dodgers", "Dodgerz"), ("Tigers", "Tygers"),
    ("Braves", "Bravos"), ("Giants", "Giantz"), ("Mariners", "Marinerz"), ("Mets", "Metz"), ("Orioles", "Oreos"),
    ("Reds", "Redz"), ("Bulls", "Bullz"), ("Cavaliers", "Cavs-aliers"), ("Lakers", "Lakerz"), ("Warriors", "Worriers"),
    ("Celtics", "Celtix"), ("Mavericks", "Mavs-ericks"), ("Bucks", "Buckz"), ("Spurs", "Spurz"), ("Magic", "Majik"),
    ("SuperSonics", "SuperSonix"), ("Pelicans", "Pelicanz"), ("Pistons", "Pistonz"), ("Patriots", "Patriotz"),
    ("Jets", "Jetz"), ("Browns", "Brownz"), ("Bears", "Bearz"), ("Chiefs", "Chiefz"), ("Colts", "Coltz"),
    ("49ers", "48ers"), ("Lions", "Lionz"), ("Dolphins", "Dolfins"), ("Broncos", "Broncoz"), ("Cowboys", "Cowpokes"),
    ("Bengals", "Bengalz"), ("Chargers", "Chargerz"), ("Raiders", "Raiderz"), ("Oilers", "Oilerz"), ("Bruins", "Bruinz"),
    ("Red Wings", "Red Wingz"), ("Penguins", "Penguinz"), ("Canadiens", "Canadienz"), ("Capitals", "Capitalz"),
    ("Blackhawks", "Blackhawkz"), ("Devils", "Devilz"), ("Flyers", "Flyerz"), ("Barcelona", "Barcelonia"),
    ("Juventus", "Juventas"), ("Borussia Dortmund", "Borussia Dortmunt"), ("Sporting CP", "Sporting CPU"),
    ("Argentinos Juniors", "Argentinos Juniorz"), ("Golden State", "Golden Statt"),
]

CARD_BLURB = {
    "BASE": ["Pulled from a shoebox under a bed in 1974. Smells like bubble gum and dust.",
             "The card every dad swears he had and his mom threw out.",
             "Baseball's oldest hobby in one cardboard rectangle. Corners are everything.",
             "A legend at the plate. A legend on the price guide."],
    "HOOP": ["The card that made a generation of kids buy plastic sleeves.",
             "Flat cardboard, huge leap. Centering decides the price.",
             "Pulled live on stream; the chat went quiet, then insane.",
             "A rookie year frozen mid-dunk."],
    "GRID": ["Thick old stock, sharp corners rare as a perfect season.",
             "Every quarterback card is a bet on Sundays ten years out.",
             "The back has stats from a year nobody remembers losing.",
             "Grass stains not included. Mostly."],
    "PUCK": ["Printed in Canada on stock rough enough to skate on.",
             "The blue border chips if you look at it wrong.",
             "Kept in a skate bag for a decade. Somehow fine.",
             "The rink smelled like this card."],
    "FUTB": ["From a sticker album traded across a schoolyard in three languages.",
             "The world's game, the world's hardest card to find clean.",
             "Swapped for two doubles and a promise.",
             "A champion before anybody knew to keep it."],
}
WAX_BLURB = ["Sealed wax. The gum inside has fossilised into a weapon.",
             "Unopened since the year it was printed. Every pack a lottery ticket.",
             "Shrink-wrapped and taped. Somebody resisted for decades.",
             "Factory sealed box, the kind people rip on camera for strangers."]
## The fakes and restoration each card is known for (shown on the card and by the appraiser).
TELLS_KNOWN = {
    "Honus Wagner": "Reprints everywhere: the real one has a 'Piedmont' back and soft cream stock.",
    "Mickey Mantle": "Trimmed edges are the classic sin: measure it, the real one is 2-5/8 inches wide.",
    "Babe Ruth": "Recoloured corners hide wear. Look for ink sitting on top of the paper.",
    "Michael Jordan": "Counterfeits with dull gloss and fuzzy print dots. Real ones glow under a blacklight check.",
    "Wayne Gretzky": "The OPC is centred badly by nature. Perfect centring on this one is a warning sign.",
    "Tom Brady": "Ticket autos get faked with a signature pen at the card show. Check the sticker isn't new.",
    "LeBron James": "Patch swaps: the jersey window gets reopened and a fancier patch slipped in.",
    "Mike Trout": "Superfractor fakes are reprinted chrome with a hand-numbered 1/1. The real foil swirls.",
    "Billy Ripken": "The famous error card gets 'corrected' copies passed off as the scarce black-box ones.",
}
TELLS = {
    "scard": ["Trimmed edges: sharp corners that are slightly too small.", "Pressed out a crease: tilt it under a lamp.",
              "Recoloured corners with a fine marker.", "A reprint on modern glossy stock.", "Re-centred by trimming one side.",
              "A cleaned surface that lost its original gloss.", "A signature that sits on top of the gloss, not in it."],
    "wax": ["Resealed with fresh wax and an iron: the folds are too neat.", "Searched packs: someone weighed them first.",
            "Re-shrinkwrapped box with the wrong seams.", "Gum stains in the wrong places."],
}
POS_STATS = {
    "P": ["W", "ERA", "SO"], "C": ["PTS", "REB", "BLK"], "SS": ["AVG", "HR", "SB"], "2B": ["AVG", "HR", "RBI"],
    "RF": ["AVG", "HR", "RBI"], "CF": ["AVG", "HR", "RBI"], "P/DH": ["HR", "ERA", "SO"], "SG": ["PTS", "AST", "STL"],
    "SF": ["PTS", "REB", "AST"], "PG": ["PTS", "AST", "3PM"], "PF": ["PTS", "REB", "BLK"], "QB": ["YDS", "TD", "INT"],
    "RB": ["YDS", "TD", "AVG"], "WR": ["REC", "YDS", "TD"], "FB": ["YDS", "TD", "AVG"], "LB": ["TKL", "SACK", "INT"],
    "LW": ["G", "A", "PTS"], "RW": ["G", "A", "PTS"], "D": ["G", "A", "+/-"], "G": ["W", "GAA", "SV%"],
    "FW": ["APP", "GOALS", "CAPS"], "MF": ["APP", "GOALS", "ASSISTS"],
}


def _sub(s, table):
    """One pass, longest match first, so a replacement is never replaced again."""
    import re
    keys = sorted((a for a, _ in table), key=len, reverse=True)
    m = dict(table)
    return re.sub("|".join(re.escape(k) for k in keys), lambda x: m[x.group(0)], s)


def _pub(detail):
    for a, b in BRAND_PUB:
        if a in detail:
            return b
    return "Toppz Co."


def make_item(r, tier, frac, u):
    h = u["h"]
    real = r["name"]
    kind = "wax" if r["kind"] == "wax" else "scard"
    code = r["code"]
    key = real + r["detail"]
    if kind == "wax":
        pname = _sub(real, BRANDS)
        player = ""
    else:
        player = PLAYERS.get(real, real)
        pname = "%s %d %s" % (player, r["year"], _sub(r["detail"].split("#")[0].strip(), BRANDS))
    tags = list(r["tags"])
    if kind == "wax":
        tags.append("box" if "Box" in real else "foil")
    iid = code.lower() + "_" + u["slug"](("%s %d" % (player, r["year"])) if kind == "scard" else pname)
    d = {"id": iid, "name": pname, "plat": code, "kind": kind, "tier": tier,
         "base": u["base_for"](WAX_BANDS if kind == "wax" else CARD_BANDS, tier, frac, key), "tags": tags,
         "real_section": r["section"], "pub": _pub(r["detail"] + " " + real), "genre": "Card",
         "set": _sub(r["detail"], BRANDS), "player": player, "team": _sub(r["team"], TEAM_WORDS), "pos": r["pos"],
         "wiki": r["wiki"]}
    if kind == "wax":
        d["blurb"] = WAX_BLURB[h(real + "b", len(WAX_BLURB))]
        d["count"] = 24 if "Box" in real else 12
        d["rarity"] = "Sealed Wax"
        d["tell"] = TELLS["wax"][h(real + "t", len(TELLS["wax"]))]
    else:
        d["blurb"] = CARD_BLURB[code][h(real + "b", len(CARD_BLURB[code]))]
        d["rarity"] = "Rookie Card" if "rc" in tags else ["Base", "Star", "Key Card", "Iconic"][tier]
        d["tell"] = TELLS_KNOWN.get(real, TELLS["scard"][h(real + "t", len(TELLS["scard"]))])
        num = r["detail"].split("#")[1].split()[0] if "#" in r["detail"] else str(1 + h(real + "n", 400))
        d["num"] = "#" + num
        cols = POS_STATS.get(r["pos"], ["G", "PTS", "W"])
        d["stats"] = [[c, str(5 + h(real + c, 60 if c not in ("AVG", "ERA", "GAA", "SV%") else 1))] for c in cols]
        for st in d["stats"]:
            if st[0] == "AVG":
                st[1] = ".%d" % (260 + h(real + "avg", 90))
            elif st[0] == "ERA":
                st[1] = "%.2f" % (1.8 + h(real + "era", 200) / 100.0)
            elif st[0] == "GAA":
                st[1] = "%.2f" % (1.9 + h(real + "gaa", 150) / 100.0)
            elif st[0] == "SV%":
                st[1] = ".%d" % (895 + h(real + "sv", 30))
    ranges = [(400000, 5000000), (60000, 400000), (4000, 60000), (1, 4000)]
    lo, hi = ranges[tier]
    d["run"] = lo + h(real + "run", hi - lo)
    if "1/1" in r["detail"]:
        d["run"] = 1
    d["rating"] = ""
    return d
