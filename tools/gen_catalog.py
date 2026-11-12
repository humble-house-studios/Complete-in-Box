#!/usr/bin/env python3
"""Builds scripts/data/catalog_items.gd from the two research lists:
  docs/research/retro_gaming_top_500.txt  (games)
  docs/research/retro_hardware_top_250.txt (consoles + accessories)

Every real entry becomes a one-to-one PARODY item (the game uses parody names on
purpose, and no real cover art): same platform family, same rank, a value tier
and base price from its rank, plus a made-up year, publisher, genre, blurb,
rating and print run for the full-screen card. The original hand-made items in
scripts/data/catalog.gd stay; list entries that match one of them just add
their rank data to it instead of duplicating it.

Run:  python3 tools/gen_catalog.py
"""
import re, hashlib, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GAMES = os.path.join(ROOT, "docs/research/retro_gaming_top_500.txt")
HW = os.path.join(ROOT, "docs/research/retro_hardware_top_250.txt")
# Extra games read as their own sections (so the main list's ranks stay put).
MORE_GAMES = [os.path.join(ROOT, "docs/research/retro_gaming_n64_more.txt")]
OUT = os.path.join(ROOT, "scripts/data/catalog_items.gd")


def h(s, n):
    return int(hashlib.md5(s.encode()).hexdigest(), 16) % n


# ------------------------------------------------------------------ parody words
# Longest keys first; applied on word boundaries, case-sensitive.
SUBS = {
    # makers + platforms
    "Nintendo World Championships": "Funtendo World Championships",
    "Nintendo PlayStation": "Funtendo PlayStatia", "Nintendo PowerFest": "Funtendo PowerFeast",
    "Nintendo Campus Challenge": "Funtendo Campus Challenge", "Nintendo Power": "Funtendo Power",
    "Nintendo 64DD": "Funtendo 64DeeDee", "Nintendo 64": "Funtendo 64", "Nintendo DS Lite": "Funtendo Duo Lite",
    "Nintendo": "Funtendo", "Super Famicom Jr.": "Super Funicom Jr.", "Super Famicom": "Super Funicom",
    "Famicom": "Funicom", "Family BASIC": "Family BASIK", "SNES-CD": "SFES-CD", "SNES": "Super FES", "NES": "FES",
    "N64": "F64", "64DD": "64DeeDee", "GameCube": "FunCube", "Game Boy Advance SP": "PocketBoy Advance SP",
    "Game Boy Advance Micro": "PocketBoy Micro", "Game Boy Advance": "PocketBoy Advance", "Game Boy Color": "PocketBoy Color",
    "Game Boy Pocket": "PocketBoy Pocket", "Game Boy Light": "PocketBoy Light", "Game Boy Player": "PocketBoy Player",
    "Game Boy Camera": "PocketBoy Camera", "Game Boy Printer": "PocketBoy Printer", "Super Game Boy": "Super PocketBoy",
    "Game Boy": "PocketBoy", "PlayStation 2": "PlayStatia 2", "PocketStation": "PocketStatia", "PlayStation": "PlayStatia",
    "PS one": "PST one", "PS2": "PST2", "PSP": "PSPocket", "PS1": "PST", "Xbox 360": "Xbux 361", "Xbox": "Xbux",
    "Sega Genesis": "Saga Genesys", "Sega Saturn": "Saga Saturnine", "Sega Dreamcast": "Saga Dreamcaster", "Sega CD": "Saga CD",
    "Sega Sports": "Saga Sports", "Sega Rally": "Saga Rally", "Sega": "Saga", "Genesis": "Genesys", "Mega Drive": "Mega Drivel",
    "Saturn": "Saturnine", "Dreamcast": "Dreamcaster", "Neo Geo": "Neon Geo", "Atari": "Ataro", "Jaguar": "Jagwire",
    "Panther": "Panthar", "Pioneer LaserActive": "Pyoneer LazerActive", "3DO": "4DO", "Panasonic": "Panasonik", "Sharp": "Sharpe",
    "Konami": "Konamo", "Namco": "Namcoo", "Hori": "Horo", "Amstrad": "Amstrud", "JVC": "JBC", "X'Eye": "X'Ayy", "Coleco": "Colecko",
    "Sears": "Seers", "Star Wars": "Starr Warz", "Indiana Jones": "Indianna Bones", "WWF": "WWFF", "NFL": "NFFL",
    "Mortal Kombat": "Mortel Kombot", "Ken Griffey Jr.": "Ken Griffo Jr.", "Clay Fighter": "Clay Fightur", "Superman": "Supurman",
    "Toy Story": "Toy Storie", "Pikachu": "Pikapal", "Pokémon": "Pocket Critters", "Pokemon": "Pocket Critters",
    # hardware bits
    "Control Deck": "Control Dock", "R.O.B.": "R.O.B.B.", "Robotic Operating Buddy": "Robotic Operating Pal",
    "Zapper": "Zappr", "Power Pad": "Power Padd", "Power Glove": "Power Mitt", "Four Score": "Four Scour", "Satellite": "Satellyte",
    "Game Genie": "Game Jeannie", "U-Force": "U-Farce", "Roll 'N Rocker": "Roll 'N Rockr", "Miracle Piano": "Miracle Pianah",
    "PlayChoice-10": "PlayChoice-11", "Vs. System": "Vs. Sistem", "Titler": "Titlr", "Data Recorder": "Data Recordr",
    "Mario Paint": "Plumber Paint", "Super Scope": "Super Scoop", "Multitap": "Multitapp", "Justifier": "Justifyer",
    "Sufami Turbo": "Sufunny Turbo", "Satellaview": "Satelloview", "X-Band": "Z-Band", "Voice-Kun": "Voice-Kunn",
    "Funtastic": "Funtastick", "Expansion Pak": "Expansion Pakk", "Rumble Pak": "Rumble Brick", "Transfer Pak": "Transfer Pakk",
    "Controller Pak": "Controller Pakk", "Bio Sensor": "Bio Censor", "Voice Recognition": "Voice Wreck-ognition",
    "GameShark": "GameSnark", "WaveBird": "WaveByrd", "Broadband": "Broadbland", "DK Bongos": "DK Bongoes",
    "Dance Dance Revolution": "Dance Dance Revelation", "Action Replay": "Action Replai", "Freeloader": "Freeloadr",
    "Play-It-Loud": "Play-It-Louder", "e-Reader": "e-Readr", "Dual Analog": "Duel Analog", "DualShock": "DualShlock",
    "NegCon": "NegKon", "GunCon": "GunKon", "G-Con": "G-Kon", "JogCon": "JogKon", "Densha de Go!": "Densha de Gogo!",
    "Beatmania": "Beatmanias", "EyeToy": "EyeToi", "Guitar Hero": "Guitar Zero", "Mountain Dew": "Mountain Doo",
    "Steel Battalion": "Steel Battalium", "Gears of War": "Gears of Wart", "Star Wars R2-D2": "Star Warz R3-D3",
    "Kinect": "Kinnect", "HD DVD": "HD DVDee", "Halo": "Hallo", "VMU": "VMD", "Maracas": "Maracaz", "Samba de Amigo": "Samba de Amiga",
    "Dreameye": "Dreamseye", "Hello Kitty": "Hello Kitteh", "Net Yaroze": "Net Yaroza", "Linux Kit": "Linuks Kit", "32X": "33X",
    "Nomad": "Nomadd", "Pico": "Picco", "Teradrive": "Terradrive", "Wondermega": "Wondermegga", "Multi-Mega": "Multi-Megga",
    "Mega PC": "Megga PC", "Mega-LD": "Megga-LD", "Heavy Sixer": "Heavy Sixxer", "Light Sixer": "Light Sixxer", "Woody": "Woodie",
    "Vader": "Vadur", "Trak-Ball": "Trak-Bawl", "Divers 2000": "Divers 2001", "Code: Veronica": "Code: Veronika",
    "Debug Station": "Debugg Station", "Mother 3": "Mama 3",
    # franchises + titles
    "Super Mario RPG": "Super Plumber RPG", "Super Mario Bros.": "Super Plumber Bros.", "Super Mario Advance": "Super Plumber Advance",
    "Super Mario World": "Super Plumber World", "Super Mario Land": "Super Plumber Land", "Super Mario Kart": "Super Plumber Kart",
    "Super Mario Strikers": "Super Plumber Strykers", "Super Mario 64": "Plumber 64", "Mario & Luigi": "Plumber & Brother",
    "Luigi's Mansion": "Brother's Mansion", "Mario Kart": "Plumber Kart", "Mario Party": "Plumber Party", "Mario Golf": "Plumber Golf",
    "Mario Tennis": "Plumber Tennis", "Mario Superstar Baseball": "Plumber Superstar Basebrawl", "Paper Mario": "Paper Plumber",
    "Mario": "Plumber", "WarioWare": "WarbioWare", "Wario": "Warbio", "Yoshi": "Yoshu", "Kirby": "Kirbo",
    "The Legend of Zelda": "Legend of Zeldo", "Zelda": "Zeldo", "Link's Awakening": "Link's Wakening", "Adventure of Link": "Adventure of Linc",
    "Metroid": "Metrood", "Samus": "Samos", "Donkey Konga": "Donkey Kongaa", "Donkey Kong": "Donkey Kongo", "Diddy Kong": "Diddly Kongo",
    "Banjo-Kazooie": "Banjo-Kablooie", "Banjo-Tooie": "Banjo-Twooie", "Conker's Bad Fur Day": "Conker's Bad Fur Week",
    "Mega Man": "Mega Robo Man", "Dr. Wily": "Dr. Wilo", "Castlevania": "Castlevein", "Dracula": "Draculo", "Simon's Quest": "Simone's Quest",
    "Belmont": "Bellmont", "Final Fantasy": "Final Fantasia", "Dragon Warrior": "Dragon Worrier", "Dragon Quest": "Dragon Request",
    "Chrono Trigger": "Chrono Triggered", "Chrono Cross": "Chrono Crossed", "EarthBound": "EarthBond", "Street Fighter": "Street Brawler",
    "Super C": "Super K", "Contra": "Contro", "Gradius": "Gradios", "Ninja Gaiden": "Ninja Guidon", "Mike Tyson's": "Mike Thighson's",
    "Punch-Out!!": "Punch-Outt!!", "Duck Tales": "Duck Tails", "Chip 'n Dale": "Chip 'n Dave", "Rescue Rangers": "Rescue Strangers",
    "Darkwing Duck": "Darkwing Goose", "TaleSpin": "TailSpin", "TMNT": "TMNK", "Batman": "Batsman", "Joker": "Jokester",
    "Bucky O'Hare": "Bucky O'Bunny", "Felix the Cat": "Felix the Kat", "Battletoads": "Battlefrogs", "Double Dragon": "Double Dragoon",
    "Bionic Commando": "Bionic Commandeer", "Zombies Ate My Neighbors": "Zombies Ate My Landlord", "Star Fox": "Star Vixen",
    "F-Zero": "F-Zilch", "Pilotwings": "Pilotwangs", "Super Smash Bros.": "Super Bash Bros.", "GoldenEye 007": "GoldenSpy 00Heaven",
    "Perfect Dark": "Perfect Dusk", "Ocarina of Time": "Ocarina of Thyme", "Majora's Mask": "Majora's Masque",
    "Harvest Moon": "Harvest Moo", "Earthworm Jim": "Earthworm Tim", "Rayman": "Rayguy", "Turok": "Turuk",
    "Resident Evil": "Resident Weevil", "Silent Hill": "Silent Hull", "Metal Gear Solid": "Metal Gear Sneaky",
    "Crash Bandicoot": "Crash Bandicute", "Crash Team Racing": "Crash Team Raising", "Spyro": "Spiro",
    "Tony Hawk's Pro Skater": "Tony Hock's Pro Skater", "Gran Turismo": "Grand Tourismo", "Twisted Metal": "Twisted Mettle",
    "Tekken": "Tekkon", "Soul Calibur": "Soul Caliper", "Soul Blade": "Soul Blayde", "Persona": "Personna",
    "Shin Megami Tensei": "Shin Megumi Tensai", "Suikoden": "Suiko Saga", "Xenogears": "Xenogeers", "Xenosaga": "Xenosago",
    "Kingdom Hearts": "Kingdom Harts", "Okami": "Okamo", "Ico": "Ika", "Shadow of the Colossus": "Shadow of the Colossal",
    "Fatal Frame": "Fatal Frane", "Guilty Gear": "Guilty Geer", "Raiden": "Raydon", "Dark Cloud": "Dark Clod",
    "Dark Chronicle": "Dark Chronical", "Animal Crossing": "Critter Crossing", "Pikmin": "Pikmen", "Skies of Arcadia": "Skies of Arcadio",
    "Tales of Symphonia": "Tales of Symphonica", "Baten Kaitos": "Batten Kaitos", "Chibi-Robo!": "Chibi-Robbo!",
    "Eternal Darkness": "Eternal Dorkness", "Killer7": "Killer8", "Fire Emblem": "Fire Emblum", "Golden Sun": "Golden Son",
    "Advance Wars": "Advanced Wars", "Shantae": "Shanty", "Jet Grind Radio": "Jet Grind Radiant", "Space Channel 5": "Space Channel 6",
    "Rez": "Rezz", "Crazy Taxi": "Crazy Taxy", "Power Stone": "Power Pebble", "Marvel vs. Capcom": "Marble vs. Capcorn",
    "Sonic": "Sonik", "Shenmue": "Shenmoo", "Phantasy Star": "Phantasy Starr", "Seaman": "Seaguy", "Grandia": "Grandio",
    "Lodoss": "Lodess", "Ecco the Dolphin": "Ecco the Porpoise", "Virtua": "Virtuo", "Daytona USA": "Daytuna USA",
    "Dead or Alive": "Dead or Alivish", "Chu Chu Rocket": "Choo Choo Rocket", "Ikaruga": "Ikaruka", "Shining Force": "Shining Farce",
    "Landstalker": "Landstalkur", "Vectorman": "Vektorman", "Panzer Dragoon": "Panzer Dragun", "Metal Slug": "Metal Slog",
    "Pitfall": "Pitfell", "Yars' Revenge": "Yarr's Revenge", "Missile Command": "Missive Command", "Combat": "Combot",
    "Adventure": "Adventura", "Stadium Events": "Stadium Happenings", "Little Samson": "Lil' Samsin", "Bubble Bobble": "Bubble Bauble",
    "Panic Restaurant": "Panic Diner", "Flintstones": "Flintstoners", "Snow Bros.": "Snow Bruhs", "Mischief Makers": "Mischief Bakers",
    "Hybrid Heaven": "Hybrid Haven", "Under Defeat": "Under Defeet", "Border Down": "Border Downe", "Exelica": "Exelika",
    "Valkyrie Profile": "Valkyrie Profiel", "Pocky & Rocky": "Pocky & Rocko", "Demon's Crest": "Demon's Crust",
    "Journey to Silius": "Journey to Sillius", "Cobra Triangle": "Kobra Triangle", "Faxanadu": "Faxanudu", "Crystalis": "Crystallus",
    "Kid Icarus": "Kid Ikarus", "Life Force": "Life Forz", "Little Nemo": "Little Nimo", "Lolo": "Lala", "Wizards & Warriors": "Wizards & Worriers",
    "Kickle Cubicle": "Kickle Cubical", "Gargoyle's Quest": "Gargoyle's Request", "Rygar": "Rygarr", "Strider": "Strydur",
    "Shatterhand": "Shatterfist", "Blaster Master": "Blaster Mustard", "Section-Z": "Section-Zed", "Abadox": "Abadocks", "Cabal": "Kabal",
    "Guardian Legend": "Guardian Legund", "Image Fight": "Image Fright", "Zanac": "Zanack", "Recca": "Rekka", "Gun-Nac": "Gun-Nack",
    "Kabuki Quantum Fighter": "Kabuki Quantum Fryer", "Power Blade": "Power Blayde", "Metal Storm": "Metal Stormy",
    "Wild Gunman": "Wild Gunperson", "Pinball Quest": "Pinball Questt", "Mighty Final Fight": "Mighty Final Fright",
    "River City Ransom": "River City Ransum", "Project Doom": "Project Gloom", "Sunman": "Sunguy", "Clash at Demonhead": "Clash at Demonhed",
    "Wurm": "Wyrm", "Secret of Mana": "Secret of Manna", "Secret of Evermore": "Secret of Nevermore", "Lufia": "Lufio",
    "Sinistrals": "Sinistrels", "Illusion of Gaia": "Illusion of Gaya", "Terranigma": "Terranigmo", "Breath of Fire": "Breath of Fyre",
    "Dream Land": "Dream Lund", "Dream Course": "Dream Coarse", "Super Star": "Super Starr", "Act Raiser": "Act Razer",
    "Super Turrican": "Super Turrikan", "Axelay": "Axelei", "Gunforce": "Gunfarce", "Wild Guns": "Wild Gunz", "Run Saber": "Run Sabre",
    "Cybernator": "Cyberneater", "Metal Warriors": "Metal Worriers", "Ogre Battle": "Ogre Battel", "Tactics Ogre": "Tactics Ogrr",
    "Bomberman": "Boomerman", "Stunt Race FX": "Stunt Race FZ", "Plok": "Plonk", "Aero the Acro-Bat": "Aero the Acro-Rat",
    "Kamikaze Squirrel": "Kamikaze Chipmunk", "Wave Race": "Wave Rays", "1080° Snowboarding": "1081° Snowboarding",
    "Excitebike": "Excitebyke", "Quest 64": "Request 64", "Aidyn Chronicles": "Aidyn Chronicals", "Silicon Valley": "Silicone Valley",
    "Blast Corps": "Blast Corpz", "Jet Force Gemini": "Jet Force Jiminy", "Shadowman": "Shadowguy", "Command & Conquer": "Command & Concur",
    "Oracle of Seasons": "Oracle of Reasons", "Oracle of Ages": "Oracle of Wages", "Trading Card Game": "Trading Card Gamble",
    "Block Ball": "Block Bawl", "Golden Coins": "Golden Coinz", "Mystery Dungeon": "Mystery Dungeun", "Superstar Saga": "Superstar Sago",
    "Minish Cap": "Minish Capp", "Four Swords": "Four Swards", "Aria of Sorrow": "Aria of Sorrows", "Harmony of Dissonance": "Harmony of Dissidents",
    "Circle of the Moon": "Circle of the Moone", "Battle Network": "Battle Netwerk", "Cybeast Falzar": "Cyberbeast Falsar",
    "Amazing Mirror": "Amazing Mirrer", "Mega Microgames": "Mega Microgamez", "Mineral Town": "Mineral Towne", "Vagrant Story": "Vagrant Storey",
    "Parasite Eve": "Parasite Eva", "Nemesis": "Nemisis", "VR Missions": "VR Misions", "Wild Arms": "Wild Armz", "Alundra": "Alundro",
    "Legend of Mana": "Legend of Manna", "Legend of Dragoon": "Legend of Dragun", "Legend of Legaia": "Legend of Legaya",
    "Brigandine": "Brigandeen", "Tales of Destiny": "Tales of Destinee", "Star Ocean": "Star Oshun", "Ape Escape": "Ape Escapade",
    "MediEvil": "MediEvel", "Medievil": "MediEvel", "Parappa the Rapper": "Parappa the Napper", "Um Jammer Lammy": "Um Jammer Clammy",
    "Klonoa": "Klonoah", "Tomba!": "Tombo!", "Einhander": "Einhandler", "Tobal": "Tobul", "Rival Schools": "Rival Skools",
    "Bushido Blade": "Bushido Blayde", "Nocturne": "Nocturnal", "Digital Devil Saga": "Digital Devil Sago", "Rogue Galaxy": "Rogue Galaxie",
    "Rule of Rose": "Rule of Roze", "Haunting Ground": "Haunting Grounds", "Disaster Report": "Disaster Reporter",
    "Mushihimesama": "Mushihimesamo", "Psyvariar": "Psyvariarr", "Curse of Darkness": "Curse of Dorkness", "Echoes": "Echos",
    "Path of Radiance": "Path of Radiants", "Thousand-Year Door": "Thousand-Year Drawer", "Colosseum": "Collosseum",
    "Gale of Darkness": "Gale of Dorkness", "Sanity's Requiem": "Sanity's Requium", "Wind Waker": "Wind Wakker",
    "Twilight Princess": "Twilight Princes", "Air Ride": "Air Glide", "Toadstool Tour": "Toadstool Tours", "Double Dash": "Double Dish",
    "Cannon Spike": "Cannon Spyke", "Illbleed": "Illbled", "Project Justice": "Project Justis", "Cosmic Smash": "Cosmic Smosh",
    "Bangai-O": "Bangai-Oh", "Giga Wing": "Giga Wyng", "Mars Matrix": "Mars Matrics", "Karous": "Karouss", "Radirgy": "Radirgee",
    "Chaos Field": "Kaos Field", "Beyond Oasis": "Beyond Oasys", "Ranger-X": "Ranger-Y", "Alisia Dragoon": "Alisha Dragun",
    "Dynamite Headdy": "Dynamite Heady", "Zwei": "Zwo", "Tetris": "Tetrominoes",
}
KEYS = sorted(SUBS.keys(), key=len, reverse=True)
_ALPHA = re.compile(r"[A-Za-z]")


def parody(name):
    out = name
    done = []
    i = 0
    # Replace with placeholders so replaced text isn't replaced again.
    for k in KEYS:
        pat = r"(?<![A-Za-z])" + re.escape(k) + r"(?![A-Za-z])"
        if re.search(pat, out):
            tok = "\x00%d\x00" % len(done)
            out = re.sub(pat, tok, out)
            done.append(SUBS[k])
    for j, v in enumerate(done):
        out = out.replace("\x00%d\x00" % j, v)
    if out == name:
        out = mangle(name)
    return out


def mangle(name):
    words = name.split(" ")
    best = max(range(len(words)), key=lambda i: len(re.sub(r"[^A-Za-z]", "", words[i])))
    w = words[best]
    core = re.sub(r"[^A-Za-z]+$", "", w)
    tail = w[len(core):]
    rules = [("ia", "io"), ("er", "ur"), ("ck", "k"), ("c", "k"), ("ph", "f"), ("y", "ie"), ("s", "z"), ("o", "oo")]
    for a, b in rules:
        if a in core.lower()[1:]:
            idx = core.lower().rfind(a)
            core = core[:idx] + b + core[idx + len(a):]
            break
    else:
        core = core + "o"
    words[best] = core + tail
    return " ".join(words)


# ------------------------------------------------------------------ platforms
GAME_SECTIONS = {
    "NES": "FES", "SNES": "SFES", "N64": "F64", "GAME BOY / GAME BOY COLOR": "PBOY", "GAME BOY ADVANCE": "PBA",
    "PLAYSTATION": "PST", "PS2 / XBOX / DS / PSP / OTHER LATE RETRO": "PST2", "GAMECUBE": "FCUBE", "DREAMCAST": "DC",
    "GENESIS / MEGA DRIVE": "GEN", "SATURN": "SAT", "NEO GEO (AES / MVS / CD)": "NEO", "ATARI 2600": "A26",
    "N64 MORE": "F64",
}
SUFFIX_PLAT = {"NES": "FES", "SNES": "SFES", "N64": "F64", "Dreamcast": "DC", "PS1": "PST", "Hardware": None}
DISC_PLATS = {"PST", "PST2", "DC", "SAT", "FCUBE", "XBX", "PSPK"}


def hw_plat(section, name):
    n = name
    if section.startswith("PROTOTYPES"):
        for k, p in [("Nintendo PlayStation", "SFES"), ("Neptune", "GEN"), ("64DD", "F64"), ("Famicom", "FES"), ("Satellaview", "SFES"),
                     ("Saturn", "SAT"), ("Dreamcast", "DC"), ("PlayStation 2", "PST2"), ("PlayStation", "PST")]:
            if k in n:
                return p
        return "ODD"
    if "NES / FAMICOM" in section:
        return "FES"
    if "SNES" in section:
        return "SFES"
    if "N64" in section:
        return "F64"
    if "GAMECUBE" in section:
        return "FCUBE"
    if "GAME BOY" in section:
        if "Advance" in n:
            return "PBA"
        if "DS" in n:
            return "DUO"
        return "PBOY"
    if "SONY" in section:
        if n.startswith("PS2"):
            return "PST2"
        if n.startswith("PSP"):
            return "PSPK"
        return "PST"
    if "XBOX" in section:
        return "XBX"
    if "DREAMCAST" in section:
        return "DC"
    if "SEGA" in section:
        return "SAT" if "Saturn" in n else "GEN"
    if "ATARI" in section:
        return "A26"
    if "NEO GEO" in section:
        return "NEO"
    return "ODD"


ACC_WORDS = ["Controller", "Pad", "Pak", "Zapper", "Glove", "Score", "Satellite", "Max", "Advantage", "Genie", "Force", "Rocker",
             "Mouse", "Scope", "Multitap", "Justifier", "Adapter", "Cable", "Memory", "Camera", "Printer", "Remote", "Stand",
             "GunCon", "G-Con", "Guitar", "Gun", "Stick", "Keyboard", "Modem", "Wheel", "Maracas", "Microphone", "Dreameye",
             "VGA Box", "Mat", "Bongos", "Kinect", "Hard Disk", "HD DVD Drive", "EyeToy", "Communicator", "Playback Kit", "Sensor",
             "Recognition", "Recorder", "Start-Up Disc", "Freeloader", "Action Replay", "GameShark", "Trak-Ball", "e-Reader",
             "R.O.B.", "Piano", "NegCon", "JogCon", "Joystick", "Link Cable", "VMU", "Jump Pack", "Fishing", "Beatmania",
             "Densha", "Network Adapter", "Broadband", "Unit", "Power Flash", "Voice-Kun", "Duke", "Player", "Super Game Boy",
             "Sufami", "Data Recorder", "Twin Stick", "Light Gun", "Expansion"]
CONSOLE_OVERRIDE = ["Famicom Disk System", "Satellaview (Super", "Nintendo 64DD", "Jaguar CD", "Sega CD", "Game Boy Player", "Super Game Boy"]
FADS = ["Power Glove", "U-Force", "Roll 'N Rocker", "Kinect", "EyeToy", "Seaman", "Bio Sensor", "Voice-Kun", "Voice Recognition",
        "Miracle Piano", "Pinball", "Donkey Konga", "Maracas", "Dreameye", "Communicator"]


def hw_kind(name):
    if any(k in name for k in CONSOLE_OVERRIDE):
        return "console"
    if "Cabinet" in name or "MVS" in name:
        return "console"
    for w in ACC_WORDS:
        if w in name:
            return "acc"
    return "console"


# ------------------------------------------------------------------ metadata
ERA = {"FES": (1985, 1994), "SFES": (1991, 1998), "F64": (1996, 2002), "PBOY": (1989, 2002), "PBA": (2001, 2008),
       "PST": (1995, 2004), "PST2": (2000, 2009), "PSPK": (2005, 2012), "FCUBE": (2001, 2007), "XBX": (2001, 2010),
       "DC": (1999, 2007), "GEN": (1989, 1997), "SAT": (1995, 1999), "NEO": (1990, 2006), "A26": (1977, 1990),
       "DUO": (2006, 2010), "ODD": (1991, 1998), "MISC": (1988, 2000)}
MAKER = {"FES": "Funtendo", "SFES": "Funtendo", "F64": "Funtendo", "PBOY": "Funtendo", "PBA": "Funtendo", "FCUBE": "Funtendo",
         "DUO": "Funtendo", "PST": "Sonny", "PST2": "Sonny", "PSPK": "Sonny", "XBX": "Microsloth", "DC": "Saga", "GEN": "Saga",
         "SAT": "Saga", "NEO": "SNC", "A26": "Ataro", "ODD": "Oddware Labs", "MISC": "Various"}
PUBS = ["Konamo", "Capcorn", "Squire Soft", "Enox", "Hudsun Soft", "Tecmoo", "Namcoo", "Taitu", "Atlast", "Natsoom", "Rarr",
        "Intelligent Sistems", "HAL-ish Laboratory", "Gamefreek", "Sonsoft", "Treasur", "SNC", "Working Designz", "Ubisaft",
        "Midwhy", "Acclaimed", "Activizion", "Eidoh", "Saga AM3", "Smilebyte", "Sonik Team", "Naughty Dogg", "Insomniak",
        "Polyphony Digitul", "Bungee", "Nippon Ni", "Cavern", "Millstone", "G.rave", "Jaleko", "Irem-ish", "Vic Tokyoo",
        "Data Least", "Tradewest-ish", "Ocean Spray Software", "Psygnosiss", "Westwood Studious", "Retro Studious", "Monolith Softt"]
ACC_PUBS = ["Mad Kats", "Horo", "Nyco", "Datul", "Mayflesh", "Pelikan", "InterAct-ish", "Naki", "Gamester", "Logitek"]

GENRE_WORDS = [
    ("RPG", ["Final Fantasy", "Dragon", "Lufia", "Breath of Fire", "Persona", "Suikoden", "Chrono", "Star Ocean", "Tales of", "Xeno",
             "Wild Arms", "Legend of Dragoon", "Legaia", "Mana", "Golden Sun", "Pokémon Red", "Pokémon Blue", "Pokémon Yellow",
             "Pokémon Gold", "Pokémon Silver", "Pokémon Crystal", "Pokémon Emerald", "Pokémon Ruby", "Pokémon Sapphire", "FireRed",
             "LeafGreen", "Shin Megami", "Kingdom Hearts", "Grandia", "Skies of Arcadia", "Lodoss", "Phantasy Star", "Valkyrie",
             "EarthBound", "RPG", "Paper Mario", "Mario & Luigi", "Baten Kaitos", "Dark Cloud", "Dark Chronicle", "Rogue Galaxy",
             "Secret of Evermore", "Illusion of Gaia", "Terranigma", "Alundra", "Vagrant", "Quest 64", "Aidyn", "Crystalis",
             "Faxanadu", "Brigandine", "Digital Devil", "Mystery Dungeon", "Battle Network", "Xenogears", "Earthbound"]),
    ("Strategy", ["Fire Emblem", "Advance Wars", "Ogre", "Tactics", "Shining Force", "Command & Conquer", "Pikmin", "Brigandine"]),
    ("Shooter", ["Gradius", "Life Force", "Raiden", "Ikaruga", "Under Defeat", "Border Down", "Trigger Heart", "Psyvariar", "Mushihimesama",
                 "Giga Wing", "Mars Matrix", "Karous", "Radirgy", "Chaos Field", "Axelay", "Zanac", "Recca", "Gun-Nac", "Image Fight",
                 "Abadox", "Section-Z", "Guardian Legend", "Star Fox", "Einhander", "Rez", "Bangai-O", "GoldenEye", "Perfect Dark",
                 "Turok", "Metal Slug", "Contra", "Super C", "Wild Guns", "Cabal", "Missile Command", "Yars", "Gunforce", "Cybernator",
                 "Super Turrican", "Jet Force", "Virtua Cop", "Panzer Dragoon", "Halo", "Journey to Silius", "Blaster Master",
                 "Wild Gunman", "Cannon Spike", "Shadowman", "Vectorman", "Ranger-X", "Combat", "Metal Storm"]),
    ("Racing", ["Kart", "F-Zero", "Gran Turismo", "Crazy Taxi", "Daytona", "Rally", "Wave Race", "Excitebike", "Stunt Race",
                "Diddy Kong Racing", "Crash Team Racing", "Twisted Metal", "Snowboarding", "Air Ride", "Cobra Triangle", "Jet Grind"]),
    ("Fighting", ["Street Fighter", "Tekken", "Soul", "Guilty Gear", "Marvel", "Power Stone", "Smash", "Dead or Alive", "Rival Schools",
                  "Bushido", "Tobal", "Project Justice", "Punch-Out", "Mighty Final Fight", "Double Dragon", "River City", "Battletoads",
                  "TMNT"]),
    ("Puzzle", ["Lolo", "Kickle", "Cookie", "Bubble Bobble", "Chu Chu", "Block Ball", "Dream Course", "Bomberman", "WarioWare",
                "Pinball", "Snow Bros"]),
    ("Sports", ["Tennis", "Golf", "Baseball", "Striker", "Stadium", "Soccer", "Tony Hawk", "Cosmic Smash", "Championships",
                "Campus Challenge", "PowerFest"]),
    ("Horror", ["Resident Evil", "Silent Hill", "Fatal Frame", "Rule of Rose", "Haunting Ground", "Eternal Darkness", "Illbleed",
                "Parasite Eve", "Castlevania", "Demon's Crest", "Killer7", "Disaster Report", "Hybrid Heaven"]),
    ("Music", ["Parappa", "Um Jammer", "Space Channel", "Samba", "Donkey Konga"]),
    ("Adventure", ["Zelda", "Shenmue", "Okami", "Ico", "Shadow of the Colossus", "Pitfall", "Adventure", "Landstalker", "Beyond Oasis",
                   "Link's Awakening", "Oracle of", "Minish", "Metroid", "Seaman", "Ecco", "Clash at Demonhead"]),
    ("Life Sim", ["Harvest Moon", "Animal Crossing", "Chibi-Robo"]),
]
GENRES_FALLBACK = ["Platformer", "Action", "Platformer", "Action", "Adventure"]

BLURBS = {
    "RPG": ["Gather your party and save a world on the brink. Over 40 hours of adventure!",
            "A sweeping epic of crystals, betrayal and turn-based glory.",
            "Explore towns, dungeons and the dark secret at the heart of the kingdom."],
    "Strategy": ["Command your army across 30 tense battle maps. Every unit counts.",
                 "Plan, position, and outwit a cunning enemy general."],
    "Shooter": ["Blast through 7 stages of relentless enemy fire. Power-ups galore!",
                "Lock on, fire everything, and don't blink.", "One ship. One planet. Ten thousand bullets."],
    "Racing": ["Tear up 16 tracks at blistering speed. Split-screen for 2 players!",
               "Floor it. Drift it. Win it."],
    "Fighting": ["Pick your fighter and battle to become champion! Secret moves inside.",
                 "Combos, counters and one-on-one fury."],
    "Puzzle": ["Easy to learn, impossible to put down.", "Hundreds of brain-bending puzzles for the whole family."],
    "Sports": ["All the action of the real thing, right in your living room!", "Go for the gold in head-to-head competition."],
    "Horror": ["Something is waiting in the dark. Can you survive the night?", "Fear has a new home. Play with the lights on."],
    "Music": ["Tap to the rhythm and groove your way to the top!", "The beat is your weapon. Don't miss it."],
    "Adventure": ["Uncover ancient secrets in a world full of wonder.", "Your quest begins with a single step... and a wooden sword."],
    "Life Sim": ["Plant, fish, make friends and live the good life.", "A little town, a big heart, and a whole lot of turnips."],
    "Platformer": ["Run, jump and stomp across 8 colorful worlds!", "Hop into a bright new adventure packed with secrets!"],
    "Action": ["Non-stop action from start to finish!", "Fight your way through hordes of enemies to the final showdown."],
    "Hardware": ["Plug in and play. Everything you need to get started.", "The ultimate way to play. Accept no substitutes.",
                 "Precision engineered for serious players."],
}
RATING = {"Horror": "M", "Shooter": "T", "Fighting": "T", "Action": "T"}


# Exact genres for the extra lists (checked before GENRE_WORDS).
GENRE_EXACT = {
    "Clay Fighter: Sculptor's Cut": "Fighting", "Killer Instinct Gold": "Fighting", "WWF No Mercy": "Fighting",
    "Mortal Kombat Trilogy": "Fighting", "Bio F.R.E.A.K.S.": "Fighting", "Fighters Destiny": "Fighting",
    "Pokémon Puzzle League": "Puzzle", "Dr. Mario 64": "Puzzle", "Tetrisphere": "Puzzle", "Worms Armageddon": "Strategy",
    "Stunt Racer 64": "Racing", "Star Wars Episode I: Racer": "Racing", "San Francisco Rush 2049": "Racing",
    "Cruis'n World": "Racing", "Cruis'n USA": "Racing", "Road Rash 64": "Racing", "Extreme-G": "Racing",
    "Wipeout 64": "Racing", "Beetle Adventure Racing": "Racing", "Top Gear Rally": "Racing", "Ridge Racer 64": "Racing",
    "Snowboard Kids 2": "Racing", "Doom 64": "Shooter", "Duke Nukem 64": "Shooter", "Quake II": "Shooter",
    "Hexen": "Horror", "Star Wars: Rogue Squadron": "Shooter", "Shadows of the Empire": "Shooter",
    "Body Harvest": "Shooter", "Army Men: Sarge's Heroes": "Shooter", "Buck Bumble": "Shooter",
    "NFL Blitz": "Sports", "Ken Griffey Jr.'s Slugfest": "Sports", "Waialae Country Club Golf": "Sports",
    "Glover": "Platformer", "Chameleon Twist": "Platformer", "Gex 64: Enter the Gecko": "Platformer",
    "Rocket: Robot on Wheels": "Platformer", "Toy Story 2": "Platformer", "Bomberman Hero": "Platformer",
    "Mega Man 64": "Action", "Mystical Ninja Starring Goemon": "Adventure", "Goemon's Great Adventure": "Platformer",
    "Indiana Jones and the Infernal Machine": "Adventure", "Superman 64": "Action", "Rampage World Tour": "Action",
    "Gauntlet Legends": "RPG", "Hey You, Pikachu!": "Life Sim", "Mario Party 2": "Puzzle", "Mario Party": "Puzzle",
    "Ogre Battle 64": "Strategy", "Bomberman 64: The Second Attack": "Action",
}


def genre_of(name, kind):
    if kind != "game":
        return "Hardware"
    if name in GENRE_EXACT:
        return GENRE_EXACT[name]
    for g, words in GENRE_WORDS:
        for w in words:
            if w.lower() in name.lower():
                return g
    return GENRES_FALLBACK[h(name, len(GENRES_FALLBACK))]


# ------------------------------------------------------------------ value bands
GAME_BANDS = [(3, 16), (20, 60), (80, 280), (1000, 4500)]
CON_BANDS = [(20, 40), (40, 95), (120, 420), (1500, 5000)]
ACC_BANDS = [(4, 14), (16, 45), (60, 200), (900, 3000)]


def base_for(kind, tier, frac, key):
    lo, hi = (GAME_BANDS if kind == "game" else CON_BANDS if kind == "console" else ACC_BANDS)[tier]
    v = hi - (hi - lo) * frac
    v *= 0.92 + (h(key, 17) / 100.0)
    return max(1, int(round(v)))


def print_run(tier, key):
    ranges = [(400000, 3000000), (90000, 400000), (8000, 90000), (25, 8000)]
    lo, hi = ranges[tier]
    return lo + h(key + "run", hi - lo)


# ------------------------------------------------------------------ legacy merge
# Hand-made items already in catalog.gd that ARE on the lists.
LEGACY = {
    ("FES", "The Legend of Zelda"): "fes_zeldo", ("FES", "Castlevania III: Dracula's Curse"): "fes_vein3",
    ("FES", "Little Samson"): "fes_samsin", ("FES", "Stadium Events"): "fes_stadium",
    ("FES", "Nintendo World Championships 1990 Gray Cartridge"): "fes_wcup", ("FES", "NES Zapper (Gray)"): "fes_zapper",
    ("FES", "Power Glove"): "fes_mitt", ("FES", "NES Control Deck (Front-Loader)"): "fes_console",
    ("SFES", "Super Metroid"): "sfes_metrood", ("SFES", "Chrono Trigger"): "sfes_chrono", ("SFES", "Final Fantasy III"): "sfes_fantasia",
    ("SFES", "EarthBound"): "sfes_earthbond", ("SFES", "Super Mario World"): "sfes_world", ("SFES", "Donkey Kong Country"): "sfes_kongo",
    ("SFES", "SNES Model 1 (SNS-001)"): "sfes_console", ("SFES", "SNES Super Scope 6"): "sfes_bazooka",
    ("F64", "Super Mario 64"): "f64_plumber", ("F64", "GoldenEye 007"): "f64_spy", ("F64", "The Legend of Zelda: Ocarina of Time"): "f64_thyme",
    ("F64", "Banjo-Kazooie"): "f64_kablooie", ("F64", "Conker's Bad Fur Day"): "f64_conker", ("F64", "Mario Party 3"): "f64_party3",
    ("F64", "Nintendo 64 Console (Gray)"): "f64_console", ("F64", "Nintendo 64 Funtastic Jungle Green"): "f64_jungle",
    ("F64", "Nintendo 64 Rumble Pak"): "f64_rumble", ("PBOY", "Pokémon Red"): "pboy_critred",
    ("PBOY", "The Legend of Zelda: Link's Awakening"): "pboy_wakening", ("PBOY", "Pokémon Crystal"): "pboy_crystal",
    ("PBOY", "Game Boy (DMG-01)"): "pboy_dmg", ("PBOY", "Game Boy Camera"): "pboy_camera", ("PBOY", "Game Boy Light (Japan)"): "pboy_gold",
    ("GEN", "Phantasy Star IV"): "gen_starr", ("GEN", "Sega Genesis Model 1"): "gen_console", ("DC", "Sonic Adventure"): "dc_adventure",
    ("DC", "Shenmue"): "dc_shenmoo", ("DC", "Jet Grind Radio"): "dc_jetset", ("DC", "Power Stone 2"): "dc_rock2",
    ("DC", "Ikaruga (Japan)"): "dc_ikaruka", ("DC", "Dreamcast Console"): "dc_console", ("DC", "Dreamcast VMU"): "dc_vmd",
    ("PST", "Crash Bandicoot"): "pst_crash", ("PST", "Final Fantasy VII"): "pst_ff7", ("PST", "Castlevania: Symphony of the Night"): "pst_sotn",
    ("PST", "Suikoden II"): "pst_suiko2", ("PST", "Tomba!"): "pst_tombo", ("PST", "PlayStation SCPH-1001 (North America Launch)"): "pst_console",
    ("PST", "PlayStation Memory Card"): "pst_memcard", ("PST", "PlayStation DualShock"): "pst_dualpad",
    ("A26", "Pitfall!"): "a26_pitfell", ("A26", "Atari 2600 Four-Switch Woody"): "a26_console",
}


def parse(path):
    section = ""
    out = []
    for line in open(path, encoding="utf-8"):
        line = line.rstrip("\n")
        m = re.match(r"^== (.*) ==$", line)
        if m:
            section = m.group(1)
            continue
        m = re.match(r"^(\d+)\. (.*)$", line)
        if m:
            out.append((int(m.group(1)), m.group(2).strip(), section))
    return out


def slug(s):
    s = s.lower().replace("é", "e").replace("°", "")
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")[:28].strip("_")


def main():
    items = []
    seen = set()
    ids = set()
    merged = {}
    games = parse(GAMES)
    for extra in MORE_GAMES:
        games += parse(extra)
    hw = parse(HW)
    hw_names = {n for _, n, _ in hw}

    def add(rank, name, section, listname):
        if listname == "games":
            m = re.match(r"^(.*) \((NES|SNES|N64|Dreamcast|PS1|Hardware)\)$", name)
            if section.startswith("THE GRAILS") and m:
                title, tag = m.group(1), m.group(2)
                if tag == "Hardware":
                    return  # prototypes live in the hardware list too
                plat = SUFFIX_PLAT[tag]
            else:
                title = name
                plat = GAME_SECTIONS.get(section, "ODD")
                if title.startswith("Raiden Fighters"):
                    plat = "XBX"
            kind = "game"
        else:
            title = name
            plat = hw_plat(section, name)
            kind = hw_kind(name)
        key = (plat, title)
        if key in seen:
            return
        seen.add(key)
        # Rank inside its section -> tier + value.
        sec_items = [x for x in (games if listname == "games" else hw) if x[2] == section]
        pos = [x[1] for x in sec_items].index(name)
        frac = pos / max(1, len(sec_items) - 1)
        if section.startswith("THE GRAILS") or section.startswith("PROTOTYPES"):
            tier = 3 if pos < (5 if listname == "games" else 4) else 2
            frac = 0.0 if tier == 3 else (pos - 4) / max(1, len(sec_items) - 5)
            tfrac = pos / 5.0 if tier == 3 else frac
        else:
            if frac < 0.12:
                tier, tfrac = 2, frac / 0.12
            elif frac < 0.4:
                tier, tfrac = 1, (frac - 0.12) / 0.28
            else:
                tier, tfrac = 0, (frac - 0.4) / 0.6
        genre = genre_of(title, kind)
        lo, hi = ERA.get(plat, (1990, 2000))
        year = lo + h(title + "y", hi - lo + 1)
        if kind == "game":
            pub = MAKER[plat] if h(title + "p", 4) == 0 else PUBS[h(title + "pub", len(PUBS))]
        elif kind == "console":
            pub = MAKER[plat]
        else:
            pub = MAKER[plat] if h(title + "p", 2) == 0 else ACC_PUBS[h(title + "pub", len(ACC_PUBS))]
        tags = []
        if kind == "game" and plat in DISC_PLATS:
            tags.append("disc")
        if any(f in title for f in FADS):
            tags.append("fad")
        meta = {
            # Extra lists number from 1001 so they never clash; rank them on their own.
            "rank": rank - 1000 if rank > 1000 else rank, "list": "more" if rank > 1000 else listname, "real_section": section, "year": year, "pub": pub, "genre": genre,
            "blurb": BLURBS[genre][h(title + "b", len(BLURBS[genre]))],
            "rating": RATING.get(genre, "E") if kind == "game" else "", "run": print_run(tier, title),
        }
        if key in LEGACY:
            merged[LEGACY[key]] = meta
            return
        pname = parody(title)
        iid = (plat.lower() + "_" + slug(pname))
        base_id = iid
        k = 2
        while iid in ids:
            iid = "%s_%d" % (base_id, k)
            k += 1
        ids.add(iid)
        d = {"id": iid, "name": pname, "plat": plat, "kind": kind, "tier": tier,
             "base": base_for(kind, tier, tfrac, title), "tags": tags}
        d.update(meta)
        items.append(d)

    for r, n, s in games:
        add(r, n, s, "games")
    for r, n, s in hw:
        add(r, n, s, "hardware")

    # Write GDScript.
    def val(v):
        if isinstance(v, str):
            return json.dumps(v, ensure_ascii=False)
        if isinstance(v, list):
            return "[" + ", ".join(val(x) for x in v) + "]"
        return str(v)

    lines = ["class_name CatalogItems", "extends RefCounted",
             "## GENERATED by tools/gen_catalog.py from docs/research/*.txt. Do not edit by hand:",
             "## change the generator (or the lists) and run it again.",
             "## One-to-one parody of the top 500 collectible games and top 250 consoles/accessories.",
             "", "const ITEMS := ["]
    for d in items:
        lines.append("\t{" + ", ".join("%s: %s" % (json.dumps(k), val(v)) for k, v in d.items()) + "},")
    lines.append("]")
    lines.append("")
    lines.append("## Rank data for hand-made items that are also on the lists.")
    lines.append("const LEGACY_META := {")
    for k, m in merged.items():
        lines.append("\t%s: {%s}," % (json.dumps(k), ", ".join("%s: %s" % (json.dumps(a), val(b)) for a, b in m.items())))
    lines.append("}")
    open(OUT, "w", encoding="utf-8").write("\n".join(lines) + "\n")
    tiers = [0, 0, 0, 0]
    plats = {}
    for d in items:
        tiers[d["tier"]] += 1
        plats[d["plat"]] = plats.get(d["plat"], 0) + 1
    print("items", len(items), "merged", len(merged), "tiers", tiers)
    print("plats", plats)
    unchanged = [d["name"] for d in items if d["name"] in [n for _, n, _ in games + hw]]
    print("UNCHANGED", unchanged)
    if "--names" in sys.argv:
        for d in items:
            print(d["id"], "|", d["name"], "|", d["kind"], d["tier"], d["base"], d["genre"])


if __name__ == "__main__":
    main()
