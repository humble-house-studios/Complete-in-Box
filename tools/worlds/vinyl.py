"""Vinyl records (Midnight Marv Okafor's world) for tools/gen_worlds.py.

Pages / platforms: ROCK Rock & Pop, JAZZ Jazz & Blues, SOUL Soul & Funk,
PUNK Punk, Indie & Metal, HIPH Hip-Hop & Dance. Kinds: record (an LP, a 45,
a 12-inch or a 78) and crate (a milk crate you can flip through, like a wax box).
List columns used: name = title, detail = why it matters, team = artist,
pos = label, wiki = the album's page (real sleeves, square like the record).
Def extras: artist, imprint (the record label), fmt (LP / 7in / 12in / 78).
"""

LIST = "vinyl_records_top_250.txt"
GRAILS = {"ROCK": 2, "JAZZ": 1, "SOUL": 1, "PUNK": 1, "HIPH": 1}
## Wikipedia lead images shaped like a sleeve (square) are used as the whole front.
COVER_ASPECT = 1.0
PHOTO_ASPECT = 1.0
NO_PHOTO_KINDS = ("crate",)

## Same value bands as books and comics so the worlds play alike.
RECORD_BANDS = [(4, 18), (24, 80), (100, 360), (1300, 6000)]
CRATE_BANDS = [(18, 50), (60, 160), (180, 560), (1800, 7000)]

## Real titles -> parody titles.
TITLES = {
    "Yesterday and Today": "Yesterday and Toady", "The Freewheelin' Bob Dylan": "The Freewheelin' Rob Dillon",
    "The Velvet Underground & Nico": "The Velour Underground & Nicko", "Please Please Me": "Please Please Mee",
    "That's All Right": "That's All Rite", "Sgt. Pepper's Lonely Hearts Club Band": "Sgt. Salt's Lonely Hearts Club Band",
    "Led Zeppelin": "Lead Zeppelyn", "The Beatles": "The Beedles (White Album)", "Elvis Presley": "Elvys Presly",
    "Pet Sounds": "Pet Sounz", "Abbey Road": "Abbey Rode", "Are You Experienced": "Are You Experiensed",
    "The Dark Side of the Moon": "The Dark Side of the Spoon", "Their Satanic Majesties Request": "Their Majestic Satanities Request",
    "Born to Run": "Born to Jog", "Thriller": "Chiller", "Rumours": "Rumourz", "Purple Rain": "Purple Drizzle",
    "Hotel California": "Motel California", "Basement Rock Crate": "Basement Rock Crate",
    "Terraplane Blues": "Terraplain Blues", "Kind of Blue": "Kinda Blue", "Blue Train": "Blue Trane", "A Love Supreme": "A Love Supremo",
    "Strange Fruit": "Strange Fruits", "Moanin'": "Moanin' & Groanin'", "Somethin' Else": "Somethin' Elsie", "Time Out": "Time Owt",
    "Mingus Ah Um": "Mingle Ah Um", "The Shape of Jazz to Come": "The Shape of Jazz to Comb", "Saxophone Colossus": "Saxophone Colossal",
    "Hoochie Coochie Man": "Hootchy Kootchy Man", "Ella and Louis": "Ellie and Lewis", "Lady in Satin": "Lady in Sateen",
    "Sunday at the Village Vanguard": "Sunday at the Village Avant-Garde", "Getz/Gilberto": "Gets/Gilbertoh",
    "Live at the Regal": "Live at the Regale", "Bitches Brew": "Witches Brew", "Head Hunters": "Head Huntterz",
    "Jazz Club Estate Crate": "Jazz Club Estate Crate",
    "Do I Love You (Indeed I Do)": "Do I Love You (Indeed I Doo)", "What's Going On": "What's Goin' On?", "Live at the Apollo": "Live at the Apolloh",
    "Songs in the Key of Life": "Songs in the Key of Lyfe", "Otis Blue": "Otys Blue",
    "I Never Loved a Man the Way I Love You": "I Never Loved a Man the Way I Love Ewe", "Maggot Brain": "Maggot Brane",
    "There's a Riot Goin' On": "There's a Diet Goin' On", "Superfly": "Superfli", "Catch a Fire": "Catch a Fyre",
    "Hot Buttered Soul": "Hot Buttered Sole", "Mothership Connection": "Mothership Connekshun", "Where Did Our Love Go": "Where Did Our Glove Go",
    "My Girl": "My Gurl", "I Want You Back": "I Want You Bach", "Let's Stay Together": "Let's Stay Togetha", "Stand by Me": "Stand by Mee",
    "Love to Love You Baby": "Love to Love You Babey", "Saturday Night Fever": "Saturday Night Fervor", "Soul Club 45s Crate": "Soul Club 45s Crate",
    "God Save the Queen": "God Shave the Queen", "Bleach": "Bleech", "Never Mind the Bollocks": "Never Mind the Pillocks", "Ramones": "Ramonez",
    "Unknown Pleasures": "Unknown Pressures", "Black Sabbath": "Black Sabbatical", "Nevermind": "Nevermynd", "London Calling": "London Stalling",
    "In the Aeroplane Over the Sea": "In the Aeroplane Over the Tea", "Kill 'Em All": "Bill 'Em All", "Horses": "Horsies",
    "The Queen Is Dead": "The Queen Is Napping", "Marquee Moon": "Marquis Moon", "Loveless": "Loveles", "OK Computer": "OK Compooter",
    "Damaged": "Damajed", "Doolittle": "Doolittel", "Fresh Fruit for Rotting Vegetables": "Fresh Fruit for Rotting Veg", "Iron Maiden": "Iron Maydon",
    "Punk Flea Market Crate": "Punk Flea Market Crate",
    "Rapper's Delight": "Rapper's Delite", "Illmatic": "Illmattic", "Enter the Wu-Tang (36 Chambers)": "Enter the Woo-Tang (37 Chambers)",
    "Paid in Full": "Paid in Fool", "Straight Outta Compton": "Straight Outta Crompton",
    "It Takes a Nation of Millions to Hold Us Back": "It Takes a Nation of Billions to Hold Us Back", "The Message": "The Massage",
    "Ready to Die": "Ready to Dye", "Blue Monday": "Blue Mundane", "Planet Rock": "Planet Rok", "Madvillainy": "Madvillanny",
    "The Chronic": "The Chronik", "3 Feet High and Rising": "3 Feet High and Ryzing", "Strings of Life": "Strings of Light",
    "Endtroducing.....": "Endtroducing....?", "Donuts": "Doughnutz", "Trans-Europe Express": "Trans-Europa Expresso", "Homework": "Homewerk",
    "Selected Ambient Works 85-92": "Selected Ambient Werks 85-92", "DJ Battle Crate": "DJ Battle Crate",
}
ARTISTS = {
    "The Beatles": "The Beedles", "Bob Dylan": "Rob Dillon", "The Velvet Underground": "The Velour Underground", "Elvis Presley": "Elvys Presly",
    "Led Zeppelin": "Lead Zeppelyn", "The Beach Boys": "The Peach Boys", "The Jimi Hendrix Experience": "The Jimmy Hendricks Experience",
    "Pink Floyd": "Pink Lloyd", "The Rolling Stones": "The Rolling Scones", "Bruce Springsteen": "Bruce Springstone", "Michael Jackson": "Michael Jaxon",
    "Fleetwood Mac": "Fleetwood Mack", "Prince": "Prynce", "Eagles": "The Beagles",
    "Robert Johnson": "Robert Johnstone", "Miles Davis": "Myles Davies", "John Coltrane": "John Coltrain", "Billie Holiday": "Billie Holliday",
    "Art Blakey and the Jazz Messengers": "Art Blakely & the Jazz Messagers", "Cannonball Adderley": "Cannonball Adderly",
    "The Dave Brubeck Quartet": "The Dave Brewbeck Quartet", "Charles Mingus": "Charles Mingle", "Ornette Coleman": "Ornette Colemann",
    "Sonny Rollins": "Sunny Rollins", "Muddy Waters": "Muddy Watters", "Ella Fitzgerald and Louis Armstrong": "Ellie Fitzgerold & Lewis Armstrung",
    "Bill Evans Trio": "Bill Evens Trio", "Stan Getz and Joao Gilberto": "Stan Gets & Joao Gilbertoh", "B.B. King": "B.B. Kingg",
    "Herbie Hancock": "Herbie Handcock",
    "Frank Wilson": "Frank Willson", "Marvin Gaye": "Marvin Gaze", "James Brown": "James Browne", "Stevie Wonder": "Stevie Wander",
    "Otis Redding": "Otis Reading", "Aretha Franklin": "Areetha Franklyn", "Funkadelic": "Funkadellic", "Sly and the Family Stone": "Shy & the Family Stone",
    "Curtis Mayfield": "Curtis Mayfeld", "Bob Marley and the Wailers": "Rob Marley & the Whalers", "Isaac Hayes": "Isaac Haze",
    "Parliament": "Parlament", "The Supremes": "The Supremos", "The Temptations": "The Temptashuns", "The Jackson 5": "The Jaxon 5",
    "Al Green": "Al Greene", "Ben E. King": "Ben E. Kingg", "Donna Summer": "Donna Sommer", "Bee Gees": "The Bee Jeez",
    "Sex Pistols": "Sex Pistolz", "Nirvana": "Nervana", "Ramones": "Ramonez", "Joy Division": "Joy Divizion", "Black Sabbath": "Black Sabbatical",
    "The Clash": "The Clatter", "Neutral Milk Hotel": "Neutral Milk Motel", "Metallica": "Metallicka", "Patti Smith": "Patty Smyth",
    "The Smiths": "The Smyths", "Television": "Televisione", "My Bloody Valentine": "My Bloody Valentyne", "Radiohead": "Radiohedd",
    "Black Flag": "Black Flagg", "Pixies": "Pixees", "Dead Kennedys": "Dead Kenneths", "Iron Maiden": "Iron Maydon",
    "The Sugarhill Gang": "The Sugarhill Gange", "Nas": "Naz", "Wu-Tang Clan": "Woo-Tang Clan", "Eric B. & Rakim": "Eric C. & Rakeem",
    "N.W.A": "N.W.B", "Public Enemy": "Public Energy", "Grandmaster Flash and the Furious Five": "Grandmaster Flash & the Furious Six",
    "The Notorious B.I.G.": "The Notorious B.I.Z.", "New Order": "New Ordur", "Afrika Bambaataa": "Afrika Bambootaa", "Madvillain": "Madvillian",
    "Dr. Dre": "Dr. Drey", "De La Soul": "De La Sole", "Rhythim Is Rhythim": "Rhythmic Is Rhythmic", "DJ Shadow": "DJ Shadoe",
    "J Dilla": "J Dillah", "Kraftwerk": "Kraftwerck", "Daft Punk": "Daft Plunk", "Aphex Twin": "Apex Twin",
    "Various": "Various Artists",
}
LABELS = {
    "Capitol": "Capitoll", "Columbia": "Colombia", "Verve": "Verv", "Parlophone": "Parlaphone", "Sun": "Son Records", "Atlantic": "Atlantik",
    "Apple": "Appel", "RCA Victor": "RCB Victor", "Track": "Trak", "Harvest": "Harvust", "Decca": "Deka", "Epic": "Epik",
    "Warner Bros.": "Warner Brothas", "Asylum": "Asylom", "Vocalion": "Vocalian", "Blue Note": "Blue Notte", "Impulse!": "Impulz!",
    "Commodore": "Commodoor", "Prestige": "Prestij", "Chess": "Chez", "Riverside": "Riversyde", "ABC-Paramount": "ABD-Paramount",
    "Soul": "Sole", "Tamla": "Tamlah", "King": "Kingg", "Volt": "Voltt", "Westbound": "Westbownd", "Curtom": "Curtomm", "Island": "Islund",
    "Enterprise": "Enterprize", "Casablanca": "Casablanka", "Motown": "Mowtown", "Gordy": "Gordie", "Hi": "Hiya", "Atco": "Atko",
    "Oasis": "Oasys", "RSO": "RSOH", "A&M": "A&N", "Sub Pop": "Sub Popp", "Virgin": "Virgyn", "Sire": "Syre", "Factory": "Factori",
    "Vertigo": "Vertygo", "DGC": "DGB", "CBS": "CBX", "Merge": "Merj", "Megaforce": "Megaforse", "Arista": "Aristah", "Rough Trade": "Rough Trayd",
    "Elektra": "Elecktra", "Creation": "Creashun", "SST": "SSD", "4AD": "5AD", "Cherry Red": "Cherri Red", "EMI": "EMU",
    "Sugar Hill": "Sugar Hil", "Loud": "Lowd", "4th & B'way": "5th & B'way", "Ruthless": "Ruthles", "Def Jam": "Def Jamm", "Bad Boy": "Bad Boi",
    "Tommy Boy": "Tommi Boy", "Stones Throw": "Stones Thrown", "Death Row": "Death Rowe", "Transmat": "Transmatt", "Mo' Wax": "Mo' Waxx",
    "Kling Klang": "Kling Klong", "Apollo": "Apolo", "Various": "Various",
}
## Words in the detail line that name real people, places or products.
DETAIL_SUBS = [("St. Thomas", "St. Tomas"), ("Staten Island", "Staten Islund"), ("Memphis", "Memfis"), ("Manchester", "Manchestor"),
               ("Brooklyn", "Brooklin"), ("Detroit", "Detroyt"), ("Chicago", "Chicaggo"), ("Delta", "Delta-ish")]

## Format per tags: 7-inch single, 12-inch single, 10-inch 78, or an LP.
def _fmt(tags):
    if "78" in tags:
        return "78"
    if "twelve" in tags:
        return "12in"
    if "single" in tags:
        return "7in"
    return "LP"


BLURB = {
    "ROCK": ["Gatefold sleeve, a little ring wear and somebody's name in biro on the back.",
             "Played at every party in 1971. Still plays, mostly.", "The inner sleeve has a coffee ring and the lyrics.",
             "Bought the week it came out with paper-round money."],
    "JAZZ": ["Deep groove, heavy vinyl, liner notes longer than some novels.",
             "The run-out groove is etched with the engineer's initials.", "A sleeve photo shot in a smoky club at two in the morning.",
             "Some jazz fan kept this one in a plastic outer sleeve for sixty years. Bless them."],
    "SOUL": ["A dancefloor filler. The grooves are worn smooth at the good bit.",
             "The label colour alone tells a dealer which year it was pressed.", "Northern soul DJs would fight over this one. Literally.",
             "There's a DJ's initials written on the label in marker."],
    "PUNK": ["A photocopied insert, a spray-painted sleeve and a needle-skip at track four.",
             "Somebody wrote the band's name on their school bag after buying this.", "Pressed in a small run by a label run from a bedroom.",
             "Still smells faintly of a gig in a basement."],
    "HIPH": ["The breaks are scratched white from a hundred block parties.", "A DJ's copy: a sticker on the label hides the title from rivals.",
             "The drum break on side B has been sampled a thousand times.", "Bought from the trunk of a car outside the club."],
}
CRATE_BLURB = ["A milk crate of records from a house clearance. The top one is a polka album. Keep digging.",
               "Somebody's whole record collection, alphabetised until about the letter F.",
               "Heavy enough to hurt your back. Damp at one corner. Marv would flip it anyway.",
               "Marv's marker on the side: UNFLIPPED."]
## The fakes and dodges record dealers watch for.
TELLS_KNOWN = {
    "Yesterday and Today": "A 'peeled' butcher cover is worth less than one still pasted over: look for the tell-tale steaming marks.",
    "The Freewheelin' Bob Dylan": "The real one lists the four pulled songs on the label and plays them; counterfeits only print them.",
    "The Velvet Underground & Nico": "Reissues print the banana; the original sticker peels off a pink banana underneath.",
    "Kind of Blue": "First press: 'Columbia' six times around the label, and the sides listed wrong on the label.",
    "Blue Train": "Originals have a deep groove ring pressed into the label and the 'ear' (an RVG stamp) in the run-out.",
    "Do I Love You (Indeed I Do)": "Bootlegs have been pressed for decades. The real one has a slightly different run-out etching.",
    "God Save the Queen": "Counterfeit A&M copies abound: check the matrix number scratched in the run-out groove.",
    "Bleach": "The first press is white vinyl, limited to a thousand. Coloured-vinyl reissues look the same at a glance.",
    "Rapper's Delight": "Later pressings shortened the label credits. The long version on the original runs over fourteen minutes.",
}
TELLS = {
    "record": ["A reissue posing as an original: check the matrix numbers in the run-out groove.",
               "A resealed sleeve: the shrink-wrap is too tight and the seam is in the wrong place.",
               "Ring wear airbrushed out of the sleeve photo in the listing.", "A warp you can see when you sight across the edge.",
               "A 'Near Mint' record with hairline scratches that only show under a lamp.", "The insert and poster are photocopies.",
               "Counterfeit label: the print is fuzzy and the colours are off.", "Mono labels on a stereo record: someone swapped the sleeves."],
    "crate": ["Picked over: the good ones went to the dealer before you got here.", "Stored in a hot loft: half of them are warped.",
              "The sleeves are original, the records inside are not."],
}


def _detail(s):
    for a, b in DETAIL_SUBS:
        s = s.replace(a, b)
    return s


def make_item(r, tier, frac, u):
    h = u["h"]
    real = r["name"]
    code = r["code"]
    kind = "crate" if r["kind"] == "crate" else "record"
    pname = TITLES.get(real, real)
    tags = list(r["tags"])
    if kind == "crate":
        tags.append("box")
    iid = code.lower() + "_" + u["slug"](pname)
    artist = ARTISTS.get(r["team"], r["team"])
    d = {"id": iid, "name": pname, "plat": code, "kind": kind, "tier": tier,
         "base": u["base_for"](CRATE_BANDS if kind == "crate" else RECORD_BANDS, tier, frac, real),
         "tags": tags, "real_section": r["section"], "pub": LABELS.get(r["pos"], r["pos"]), "genre": "Record",
         "set": pname, "artist": artist, "imprint": LABELS.get(r["pos"], r["pos"]), "note": _detail(r["detail"]), "wiki": r["wiki"]}
    if kind == "crate":
        d["blurb"] = CRATE_BLURB[h(real + "b", len(CRATE_BLURB))]
        d["count"] = 40 + h(real + "c", 60)
        d["rarity"] = "Crate"
        d["tell"] = TELLS["crate"][h(real + "t", len(TELLS["crate"]))]
        d["fmt"] = "crate"
    else:
        d["blurb"] = _detail(r["detail"]) + ". " + BLURB[code][h(real + "b", len(BLURB[code]))]
        d["fmt"] = _fmt(tags)
        if "debut" in tags:
            d["rarity"] = "Debut"
        elif "single" in tags:
            d["rarity"] = "Single"
        else:
            d["rarity"] = ["Bargain Bin", "Collectable", "Sought After", "Holy Grail"][tier]
        d["tell"] = TELLS_KNOWN.get(real, TELLS["record"][h(real + "t", len(TELLS["record"]))])
        d["tracks"] = (2 if d["fmt"] in ("7in", "78") else 2 + h(real + "tr", 3)) if "single" in tags else 8 + h(real + "tr", 8)
    # Pressings: 78s in the hundreds, 60s LPs in the thousands, hits in the millions.
    if r["year"] < 1950:
        d["run"] = 300 + h(real + "run", 4000)
    else:
        ranges = [(200000, 900000), (40000, 200000), (8000, 40000), (500, 8000)]
        lo, hi = ranges[tier]
        d["run"] = lo + h(real + "run", hi - lo)
    if real == "Do I Love You (Indeed I Do)":
        d["run"] = 3
    if real == "God Save the Queen":
        d["run"] = 300
    d["rating"] = ""
    return d
