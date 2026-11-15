"""Pop culture (Cousin Dale's world) for tools/gen_worlds.py.

Pages / platforms: FIGS Action Figures, TOYS Toys & Fads, PROP Props & Costumes,
POST Posters, MEMO Lunchboxes & Keepsakes. Kinds: toy (figures, toys, lunchboxes,
badges...), prop (screen-used props and costumes), poster (one-sheets) and toybox
(a box lot you dig through, like a wax box: toy chest, prop crate, poster tube).
List columns used: name, detail = the real-world record, team = maker or studio,
pos = form (picks the 3D model and the packaging), wiki = the item's page.
Def extras: maker, form, record (the real-world fact, parodied), screen (bool).
"""

LIST = "pop_culture_top_250.txt"
GRAILS = {"FIGS": 2, "TOYS": 1, "PROP": 2, "POST": 1, "MEMO": 1}
## Film pages lead with the poster itself (27x41 inches): use it as the whole front.
COVER_ASPECT = 0.0
COVER_ASPECT_KIND = {"poster": 0.675}
## Poster scans on Wikipedia run from 0.62 to 0.78 wide.
COVER_TOLERANCE = 0.12
PHOTO_ASPECT = 1.0
NO_PHOTO_KINDS = ("toybox",)

## Same value bands as records and books so the worlds play alike.
TOY_BANDS = [(4, 18), (24, 80), (100, 360), (1300, 6000)]
BOX_BANDS = [(18, 50), (60, 160), (180, 560), (1800, 7000)]

## Real names -> parody names.
TITLES = {
    "Rocket-Firing Boba Fett": "Rocket-Firing Bobo Fett", "G.I. Joe Prototype": "G.I. Jo Prototype", "Vinyl Cape Jawa": "Vinyl Cape Jawwa",
    "Luke Skywalker Double-Telescoping Lightsaber": "Luke Skyrunner Double-Telescoping Laser Sword",
    "Star Wars Early Bird Certificate Package": "Star Wares Early Bird Certificate", "He-Man": "He-Mann", "Optimus Prime": "Optimal Prime",
    "Leonardo": "Leonardoh", "Mego Superman": "Meego Super-Fellow", "Captain Action": "Captain Acton",
    "Steve Austin, The Six Million Dollar Man": "Steve Boston, The Six Billion Dollar Man", "Lion-O": "Lyon-O", "Captain Kirk": "Captain Kirque",
    "Super Powers Batman": "Super Powwers Bat-Guy", "Red Ranger": "Red Rangerr", "Spawn": "Spawnn", "Slimer": "Slymer",
    "Micronauts Time Traveler": "Microbots Time Traveller", "Stretch Armstrong": "Stretch Armstrang", "Kenner Warehouse Case Lot": "Kenor Warehouse Case Lot",
    "Pink Rear-Loading Beach Bomb": "Pink Rear-Loading Beach Bomm", "Steiff Teddy Bear": "Stieff Teddy Bear", "Barbie #1 Ponytail": "Barbee #1 Ponytail",
    "Millennium Falcon Ultimate Collector's Series": "Millennial Falcon Ultimate Builder's Set", "Princess the Bear": "Princess the Bear",
    "Cabbage Patch Kid": "Cabbage Patch Kidd", "Evel Knievel Stunt Cycle": "Evil Kanevil Stunt Cycle", "Furby": "Furbee", "Tamagotchi": "Tamagotchu",
    "Rubik's Cube": "Rubek's Cube", "Tickle Me Elmo": "Tickle Me Elmer", "Mr. Potato Head": "Mr. Potatoe Head", "Easy-Bake Oven": "Easy-Baik Oven",
    "Etch A Sketch": "Etch-O-Sketch", "Lite-Brite": "Lyte-Bryte", "Slinky": "Slinkee", "Matchbox Road Roller": "Matchbocks Road Roller",
    "View-Master": "View-Mastor", "Polly Pocket": "Pollie Pocket", "Attic Toy Chest": "Attic Toy Chest",
    "Ruby Slippers": "Ruby Slippers", "Robby the Robot": "Robbie the Robot", "Aston Martin DB5": "Austin Marten DB5", "The Subway Dress": "The Subway Dress",
    "1966 Batmobile": "1966 Bat-Cruiser", "The Maltese Falcon": "The Maltese Pigeon", "Gingham Dress": "Gingham Dress",
    "Indiana Jones's Fedora": "Indiana Joans's Fedora", "DeLorean Time Machine": "DeLorian Time Machine",
    "Luke Skywalker's Lightsaber": "Luke Skyrunner's Laser Sword", "Rosebud Sled": "Rosebud Sled", "Proton Pack": "Proton Pack", "Hoverboard": "Hoverboard",
    "Superman Cape": "Super-Fellow Cape", "Captain Kirk's Command Chair": "Captain Kirque's Command Chair", "Freddy Krueger's Glove": "Freddy Kroogar's Glove",
    "Golden Gun": "Golden Gun", "Gizmo": "Gizmoe", "Wilson": "Wilsen", "Studio Prop Auction Crate": "Studio Prop Auction Crate",
    "Metropolis": "Metropoliss", "Dracula": "Drakula", "London After Midnight": "London After Midnite", "The Mummy": "The Mummie",
    "King Kong": "King Kongo", "Frankenstein": "Frankenstine", "Bride of Frankenstein": "Bride of Frankenstine", "The Black Cat": "The Black Kat",
    "Casablanca": "Casablanka", "The Wizard of Oz": "The Wizard of Ozz", "Gone with the Wind": "Gone with the Draught", "Vertigo": "Vertygo",
    "Breakfast at Tiffany's": "Breakfast at Tiffiny's", "Psycho": "Psykho", "2001: A Space Odyssey": "2002: A Space Odyssey",
    "Star Wars Style A": "Star Wares Style A", "Jaws": "Jawz", "Woodstock": "Woodstack", "The Beatles at Shea Stadium": "The Beedles at Shay Stadium",
    "Theatre Basement Poster Tube": "Theatre Basement Poster Tube",
    "Superman Lunchbox": "Super-Fellow Lunchbox", "Hopalong Cassidy Lunchbox": "Hopalong Cassidee Lunchbox",
    "Little Orphan Annie Decoder Pin": "Little Orphan Andie Decoder Pin", "The Beatles Lunchbox": "The Beedles Lunchbox", "Pez Make-A-Face": "Pezz Make-A-Face",
    "Howdy Doody Marionette": "Howdy Dowdy Marionette", "Captain Midnight Decoder Badge": "Captain Midnite Decoder Badge",
    "The Jetsons Lunchbox": "The Jetsams Lunchbox", "Star Wars Lunchbox": "Star Wares Lunchbox", "Kiss Lunchbox": "Kyss Lunchbox",
    "Davy Crockett Coonskin Cap": "Davey Crockitt Coonskin Cap", "Mouseketeer Ears": "Mousekateer Ears", "Happy Meal Circus Wagon": "Happy Meel Circus Wagon",
    "Garbage Pail Kids Wax Pack": "Garbage Pale Kids Wax Pack", "Pet Rock": "Pet Rock", "Lava Lamp": "Lava Lamp", "Mood Ring": "Mood Ring",
    "Magic 8 Ball": "Mystic 8 Ball", "Pac-Mania Fan Button": "Puck-Mania Fan Button", "Flea Market Lunchbox Stack": "Flea Market Lunchbox Stack",
}
MAKERS = {
    "Kenner": "Kenor", "Hasbro": "Hasbo", "Mattel": "Mattle", "Playmates": "Playmites", "Mego": "Meego", "Ideal": "Ideel", "LJN": "LJM",
    "Bandai": "Bandy", "McFarlane Toys": "McFarland Toys", "Steiff": "Stieff", "Lego": "Legoh", "Ty": "Tie Inc.", "Coleco": "Colleco",
    "Tiger Electronics": "Tyger Electronics", "Tyco": "Tyko", "Ohio Art": "Ohio Arts", "James Industries": "James Industrees", "Lesney": "Lesny",
    "Sawyer's": "Sawyers'", "Bluebird Toys": "Bluebyrd Toys", "MGM": "MGN", "Eon Productions": "Ion Productions", "20th Century Fox": "21st Century Fax",
    "Warner Bros.": "Warner Brothas", "Lucasfilm": "Lucasfilmz", "Universal": "Universel", "RKO": "RKQ", "Columbia Pictures": "Colombia Pictures",
    "Desilu": "Desilou", "New Line Cinema": "New Lyne Cinema", "DreamWorks": "DreamWerks", "UFA": "UFB", "Selznick International": "Selsnick International",
    "Paramount": "Paramont", "Woodstock Ventures": "Woodstack Ventures", "Sid Bernstein": "Sid Burnstein", "Aladdin": "Aladdyn", "Ovaltine": "Ovaltyne",
    "Pez": "Pezz", "NBC": "NBZ", "King-Seeley Thermos": "King-Seely Thermoss", "Disney": "Dizney", "McDonald's": "McDougal's", "Topps": "Toppz Co.",
    "Rock Bottom Productions": "Rock Bottom Productions", "Crestworth": "Crestwerth", "Marvin Wernick": "Marvin Wernik", "Alabe Crafts": "Alabee Crafts",
    "Hanna-Barbera": "Hanna-Barbara", "Various": "Various",
}
## Real people, places, brands and titles in the record line -> parody (longest first).
DETAIL_SUBS = [
    ("Teenage Mutant Ninja Turtles", "Teenage Mutant Ninja Tortoises"), ("Masters of the Universe", "Masters of the Universal"),
    ("Mighty Morphin Power Rangers", "Mighty Morphing Power Rangerrs"), ("Back to the Future Part II", "Back to the Futura Part II"),
    ("Back to the Future", "Back to the Futura"), ("Raiders of the Lost Ark", "Raiders of the Lost Arc"), ("A Nightmare on Elm Street", "A Nightmare on Elm Avenue"),
    ("The Seven Year Itch", "The Seven Year Twitch"), ("The Wizard of Oz", "The Wizard of Ozz"), ("Forbidden Planet", "Forbidden Plannet"),
    ("Profiles in History", "Profiles in Hysteria"), ("The Real Ghostbusters", "The Real Ghostbusterz"), ("Ghostbusters", "Ghostbusterz"),
    ("Star Wars", "Star Wares"), ("Star Trek", "Star Trik"), ("Citizen Kane", "Citizen Kain"), ("Cast Away", "Cast Astray"), ("Goldfinger", "Goldfingers"),
    ("Gremlins", "Gremlinz"), ("ThunderCats", "ThunderKats"), ("Micronauts", "Microbots"), ("McFarlane Toys", "McFarland Toys"),
    ("Hot Wheels", "Hot Wheelz"), ("Beanie Baby", "Beany Baby"), ("Mattel-branded", "Mattle-branded"), ("Mickey Mouse Club", "Mikey Mouse Club"),
    ("Marilyn Monroe", "Marilyn Monrow"), ("Christopher Reeve", "Christopher Reave"), ("Steven Spielberg", "Steven Spielburg"), ("Tom Hanks", "Tom Hanx"),
    ("Boris Karloff", "Boris Karlov"), ("Karloff and Lugosi", "Karlov and Lugozi"), ("Karloff", "Karlov"), ("Bogart and Bergman", "Bogarde and Burgman"),
    ("Audrey Hepburn", "Audrey Hepburne"), ("Hitchcock", "Hitchcok"), ("Fritz Lang", "Fritz Lange"), ("Heinz Schulz-Neudamm", "Heinz Schultz-Neudam"),
    ("Saul Bass", "Saul Bas"), ("Roger Kastel", "Roger Castel"), ("Tom Jung", "Tom Jang"), ("Arnold Skolnick", "Arnold Skolnik"),
    ("George Barris", "George Barrie"), ("Lincoln Futura", "Lincon Futura"), ("Elsa Lanchester", "Elsa Lancaster"), ("Don Levine", "Don Levene"),
    ("Gary Dahl", "Gary Dahle"), ("Edward Craven Walker", "Edward Raven Walker"), ("Princess Diana", "a princess"), ("Bond's", "The spy's"),
    ("Scaramanga", "Scaramango"), ("Graflex", "Grafflex"), ("Empire State", "Empire Estate"), ("Gimbels", "Gimbles"), ("New York", "New Yawk"),
    ("Heritage", "Heritidge"), ("Hake's", "Hayke's"), ("Bonhams", "Bonhamz"), ("Christie's", "Christy's"), ("Sotheby's", "Sothebids"),
    ("Kenner", "Kenor"), ("Hasbro", "Hasbo"), ("Mattel", "Mattle"), ("Mego", "Meego"), ("Ideal", "Ideel"), ("Bandai", "Bandy"),
    ("Ovaltine", "Ovaltyne"), ("Aladdin", "Aladdyn"), ("McDonald's", "McDougal's"), ("Topps", "Toppz"), ("Lesney", "Lesny"), ("Sawyer's", "Sawyers'"),
    ("Universal", "Universel"), ("King-Seeley Thermos", "King-Seely Thermoss"), ("Code-O-Graph", "Code-O-Gram"), ("Lego", "Legoh"),
    ("the NSA", "a spy agency"), ("DC line", "comic-book line"), ("Autobot", "Autobott"), ("Lion-O", "Lyon-O"),
]
for _real, _fake in TITLES.items():
    if _real != _fake and len(_real) > 6 and (_real, _fake) not in DETAIL_SUBS:
        DETAIL_SUBS.append((_real, _fake))
DETAIL_SUBS.sort(key=lambda p: -len(p[0]))

## Shop blurbs per page (one is picked per item, after the record line).
BLURB = {
    "FIGS": ["The bubble's still clear and the card's only a little bent at the peg hole.", "A kid's name on the foot in biro. Collectors call that provenance.",
             "Came out of a shoebox marked DO NOT TOUCH, which nobody obeyed.", "The cardback lists figures you could 'collect them all'. Nobody did."],
    "TOYS": ["Every child on the street had one, which is exactly why nobody kept one.", "The box has a price sticker from a shop that closed in 1984.",
             "Batteries not included. Batteries still inside, unfortunately.", "Somebody's mum kept it in the loft, and somebody's mum was a saint."],
    "PROP": ["Comes with a letter from the studio and a story from the seller. Only one of them is notarised.",
             "Under the paint you can see where the prop shop rebuilt it between takes.", "Photo-matched to a frame of the film, if you squint.",
             "It looks smaller in person. Everything from the movies does."],
    "POST": ["Folded into eighths, the way cinemas got them, and pinned in a foyer for a fortnight.", "A drawing-pin hole in each corner and a snipe at the bottom.",
             "Found lining the walls of a projection booth.", "The colours are still loud. The lithographers knew what they were doing."],
    "MEMO": ["The latch still clicks. The flask inside smells of 1963.", "Bought with box tops and a dime in the mail. Six to eight weeks for delivery.",
             "Scuffed from a thousand playground trips and one memorable fight.", "Kept in a drawer with the birthday cards."],
}
BOX_BLURB = {
    "FIGS": ["A brown shipper case, still taped, marked with a warehouse number and 12 ASST.", "The case is dented. The figures inside might not be."],
    "TOYS": ["The lid's painted with a circus. It rattles when you tip it.", "A loft clearance chest: dolls, cars, and one suspicious jack-in-the-box."],
    "PROP": ["Stencilled PROPS DEPT - STAGE 7. Packed with straw and secrets.", "A studio clear-out crate: half junk, half history."],
    "POST": ["A cardboard tube of folded one-sheets from an old cinema basement.", "Rolled tight, rubber-banded, labelled MISC 70s in marker."],
    "MEMO": ["A wobbling tower of tin lunchboxes tied up with string.", "Somebody's whole school career in a stack of lunchboxes."],
}
## The fakes and dodges dealers watch for.
TELLS_KNOWN = {
    "Rocket-Firing Boba Fett": "Real prototypes have the L-shaped slot in the backpack; fakes cut the slot themselves, too clean.",
    "Vinyl Cape Jawa": "The vinyl cape is the most reproduced piece in the hobby: originals have a tiny arm hole and a matte finish.",
    "Barbie #1 Ponytail": "No holes in the feet, no #1: the originals stood on copper-tubed pegs.",
    "Pink Rear-Loading Beach Bomb": "Shop Beach Bombs load from the side. Only the prototype loads from the back.",
    "Princess the Bear": "The 'rare' first editions sold online for thousands are as common as dust. Check the tag generation, not the hype.",
    "Ruby Slippers": "Several pairs were made. The ones he wants have felt on the soles, so they made no sound on the yellow brick road.",
    "Metropolis": "Reprints are smaller and printed in dots. Originals are stone lithographs: no dots under the loupe.",
    "Star Wars Style A": "The first printing says 'STAR WARS' with no 'Episode IV' and has a tiny code in the corner.",
    "Luke Skywalker Double-Telescoping Lightsaber": "Collectors fake these by gluing a thin tip into a normal saber. Real ones slide out in two parts.",
    "Steiff Teddy Bear": "No button in the ear, no Stieff. Some fakes even add a button: real ones are pressed tin.",
}
TELLS = {
    "toy": ["A reproduction card: too bright, too stiff, and the peg hole is the wrong shape.", "A resealed bubble: look for glue lines along the edge.",
            "'Complete' with reproduction weapons. The real ones are a slightly different plastic.", "Sun-faded on one side from a shop window.",
            "A broken thumb under the bubble that only shows when you tilt it.", "The box is real. The toy inside is from a later year.",
            "The price sticker was peeled off and the card tore a little.", "A re-release posing as an original: check the copyright date on the base."],
    "prop": ["No studio letter: just a seller with a good story.", "Screen-matched to a photo... of a different scene.",
             "A fan replica with very convincing aged paint.", "The costume label inside was ironed on last week.",
             "A stunt double's version, sold as the hero prop.", "Made in the right year, for the wrong film."],
    "poster": ["A reprint on glossy paper. Originals are matte and folded.", "The edges are trimmed to hide tears.",
               "Wrong size: a one-sheet is 27 by 41 inches, and this isn't.", "A video-shop poster sold as the theatrical one.",
               "Linen backing that hides restored paper losses.", "Colour touched in where the folds wore through."],
    "toybox": ["Picked over: the good ones went to a dealer before you got here.", "Stored in a damp garage: half of it is mildewed.",
               "The box is old. The contents went in last Tuesday."],
}


def _detail(s):
    for a, b in DETAIL_SUBS:
        s = s.replace(a, b)
    return s


def make_item(r, tier, frac, u):
    h = u["h"]
    real = r["name"]
    code = r["code"]
    kind = r["kind"] if r["kind"] in ("toy", "prop", "poster", "toybox") else "toy"
    pname = TITLES.get(real, real)
    tags = list(r["tags"])
    if kind == "toybox":
        tags.append("box")
    iid = code.lower() + "_" + u["slug"](pname)
    maker = MAKERS.get(r["team"], r["team"])
    form = r["pos"] or "boxed"
    rec = _detail(r["detail"])
    d = {"id": iid, "name": pname, "plat": code, "kind": kind, "tier": tier,
         "base": u["base_for"](BOX_BANDS if kind == "toybox" else TOY_BANDS, tier, frac, real),
         "tags": tags, "real_section": r["section"], "pub": maker, "genre": {"prop": "Screen Used", "poster": "One-Sheet", "toybox": "Box Lot"}.get(kind, "Toy"),
         "set": pname, "maker": maker, "form": form, "note": rec, "record": rec, "wiki": r["wiki"]}
    if kind == "toybox":
        d["blurb"] = BOX_BLURB[code][h(real + "b", len(BOX_BLURB[code]))]
        d["count"] = 12 + h(real + "c", 30)
        d["rarity"] = "Box Lot"
        d["tell"] = TELLS["toybox"][h(real + "t", len(TELLS["toybox"]))]
    else:
        d["blurb"] = rec + ". " + BLURB[code][h(real + "b", len(BLURB[code]))]
        if "proto" in tags:
            d["rarity"] = "Prototype"
        elif "screen" in tags:
            d["rarity"] = ["Background Prop", "Production Made", "Screen Used", "Hero Prop"][tier]
        elif "premium" in tags:
            d["rarity"] = "Mail-Away"
        elif "fad" in tags:
            d["rarity"] = "Craze"
        else:
            d["rarity"] = ["Toy Box", "Collectable", "Sought After", "Holy Grail"][tier]
        d["tell"] = TELLS_KNOWN.get(real, TELLS[kind][h(real + "t", len(TELLS[kind]))])
    # How many were made: toys by the hundred thousand, posters in the thousands, props a handful.
    if kind == "prop":
        d["run"] = 1 + h(real + "run", 6)
    elif kind == "poster":
        d["run"] = [(30000, 120000), (8000, 30000), (1500, 8000), (300, 1500)][tier][0] + h(real + "run", 6000)
    elif "proto" in tags:
        d["run"] = 1 + h(real + "run", 20)
    else:
        lo, hi = [(400000, 3000000), (100000, 400000), (20000, 100000), (2000, 20000)][tier]
        d["run"] = lo + h(real + "run", hi - lo)
    fixed_runs = {"Pink Rear-Loading Beach Bomb": 2, "Dracula": 1, "London After Midnight": 1, "Barbie #1 Ponytail": 350000,
                  "Rubik's Cube": 350000000, "Furby": 40000000, "Tamagotchi": 82000000, "Pet Rock": 1500000, "Tickle Me Elmo": 1000000,
                  "Hopalong Cassidy Lunchbox": 600000, "Ruby Slippers": 4, "Robby the Robot": 1, "Aston Martin DB5": 4, "DeLorean Time Machine": 3,
                  "Rocket-Firing Boba Fett": 30, "G.I. Joe Prototype": 1, "Millennium Falcon Ultimate Collector's Series": 50000}
    if real in fixed_runs:
        d["run"] = fixed_runs[real]
    d["screen"] = "screen" in tags
    d["rating"] = ""
    return d
