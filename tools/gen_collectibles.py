#!/usr/bin/env python3
"""Builds scripts/data/catalog_cc.gd (no class_name: Catalog preloads it) from:
  docs/research/tcg_cards_top_250.txt  (trading cards + sealed product)
  docs/research/rare_coins_top_250.txt (US, world and ancient coins)

Cards become one-to-one PARODIES (parody names, original art) with everything the
card painter needs: set, number, rarity, type/colour/attribute, HP or cost, moves
or rules text, stats, artist, and a 3D subject for the art window. Coins keep
their (unbranded, historical) names and get denomination, metal, mint, diameter,
the obverse/reverse motif the coin painter draws, and the legends around the rim.

Run:  python3 tools/gen_collectibles.py
"""
import re, hashlib, json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CARDS = os.path.join(ROOT, "docs/research/tcg_cards_top_250.txt")
COINS = os.path.join(ROOT, "docs/research/rare_coins_top_250.txt")
OUT = os.path.join(ROOT, "scripts/data/catalog_cc.gd")


def h(s, n):
    return int(hashlib.md5(s.encode()).hexdigest(), 16) % n


# ------------------------------------------------------------------ card parody words
# Longest keys first; applied on word boundaries.
SUBS = {
    # Pokemon
    "Pokemon": "Pocket Critters", "Pikachu": "Pikapal", "Charizard": "Charblaze", "Charmander": "Charmandoo",
    "Blastoise": "Blastortle", "Venusaur": "Bloomasaur", "Rayquaza": "Skyquaza", "Umbreon": "Gloomeon",
    "Espeon": "Psyeon", "Lugia": "Lugeon", "Mewtwo": "Mewtoo", "Mew": "Mewl", "Gyarados": "Gyaradoze",
    "Tyranitar": "Tyrantar", "Ho-Oh": "Ho-Hum", "Giratina": "Giratino", "Gengar": "Gengrin", "Dragonite": "Dragonut",
    "Alakazam": "Alakazoom", "Zapdos": "Zapdoze", "Machamp": "Machomp", "Ninetales": "Ninetails", "Raichu": "Raichoo",
    "Typhlosion": "Typhlosizzle", "Feraligatr": "Ferocigatr", "Moltres": "Moltrez", "Articuno": "Articoolo",
    "Snorlax": "Snorelax", "Scyther": "Scythor", "Vaporeon": "Vapoureon", "Jolteon": "Jolteeon", "Flareon": "Flareeon",
    "Hitmonchan": "Hitmonpunch", "Chansey": "Chancey", "Clefairy": "Clefaery", "Lapras": "Laprass",
    "Aerodactyl": "Aerodactile", "Kabutops": "Kabutoptop", "Bulbasaur": "Bulbasoar", "Squirtle": "Squirtell",
    "Eevee": "Eevy", "Psyduck": "Psyquack", "Magikarp": "Magicarp", "Rattata": "Rattatat", "Diglett": "Digglet",
    "Kangaskhan": "Kangaskan", "Neo Destiny": "Neon Destiny", "Neo Genesis": "Neon Genesis",
    "Neo Revelation": "Neon Revelation", "Skyridge": "Skyreach", "Aquapolis": "Aquapolus", "Team Rocket": "Team Rockit",
    "Evolving Skies": "Evolving Sky", "Lost Origin": "Lost Originz", "Silver Tempest": "Silver Tempo",
    "Prismatic Evolutions": "Prismatic Evolution", "Hidden Fates": "Hidden Fakes", "Celebrations": "Celebrationz",
    "Dragon Frontiers": "Dragon Frontier", "EX Deoxys": "EX Deoxus", "EX Holon Phantoms": "EX Holon Phantomz",
    "POP Series": "POPP Series", "Gym Heroes": "Gym Heros", "Gym Challenge": "Gym Challenje",
    "Southern Islands": "Southern Isles", "Wizards Black Star": "Lizards Black Star", "CoroCoro": "KoroKoro",
    "Van Gogh": "Van Gough", "Blaine's": "Blane's", "Sabrina's": "Sabreena's",
    # Magic
    "Magic: The Gathering": "Magick: The Gatherening", "Black Lotus": "Bleak Lotus", "Mox": "Mocks",
    "Ancestral Recall": "Ancestral Recount", "Time Walk": "Time Stroll", "Timetwister": "Timetwirler",
    "The One Ring": "The Only Ring", "Shichifukujin Dragon": "Shichifukuji Dragon",
    "Library of Alexandria": "Library of Alexandrina", "Bazaar of Baghdad": "Bazaar of Bagdud",
    "Mishra's Workshop": "Misra's Workshop", "Tabernacle at Pendrell Vale": "Tabernacle at Pendrill Vale",
    "Time Vault": "Time Safe", "Chaos Orb": "Chaos Orbit", "Underground Sea": "Underground Lake",
    "Volcanic Island": "Volcanic Islet", "Tropical Island": "Tropical Islet", "Forcefield": "Forcefeeld",
    "Gaea's Cradle": "Gaia's Crib", "Imperial Seal": "Imperial Seel", "Lion's Eye Diamond": "Lion's Eye Diamante",
    "Juzam Djinn": "Juzzam Djinni", "Mana Drain": "Mana Drane", "Moat": "Moatt", "Candelabra of Tawnos": "Candelabra of Tawnoz",
    "Berserk": "Bersirk", "Wheel of Fortune": "Wheel of Fortunes", "Nicol Bolas": "Nicolo Bolas", "Badlands": "Badlandz",
    "Bayou": "Bayoo", "Taiga": "Taigah", "Tundra": "Tundrah", "Plateau": "Plateux", "Savannah": "Savanna",
    "Scrubland": "Scrublands", "Force of Will": "Force of Won't", "Jace, the Mind Sculptor": "Jayce, the Mind Sculptur",
    "Mana Crypt": "Mana Krypt", "Grim Monolith": "Grim Monolyth", "Chains of Mephistopheles": "Chains of Mephistofeles",
    "Ali from Cairo": "Ali from Kairo", "Sol Ring": "Soul Ring", "Demonic Tutor": "Demonic Tooter",
    "Sylvan Library": "Sylvan Librarian", "Mana Vault": "Mana Vaultt", "Serra Angel": "Sera Angel",
    "Shivan Dragon": "Shivvan Dragon", "Lord of Atlantis": "Lord of Atlantiss", "Lightning Bolt": "Lightning Boltz",
    "Dark Ritual": "Dark Rituel", "Counterspell": "Counterspel", "Llanowar Elves": "Llanowhere Elves",
    "Giant Growth": "Giant Groath", "Swords to Plowshares": "Swords to Plowshears", "Grizzly Bears": "Grizzled Bears",
    "Arabian Nights": "Arabian Knights", "Antiquities": "Antiquitees", "Urza's": "Urzo's", "Portal Three Kingdoms": "Portal Three Kingdums",
    "Mirage": "Mirrage", "Stronghold": "Stronghould", "Alliances": "Allyances", "Worldwake": "Worldwoke",
    "Lord of the Rings": "Lord of the Rangs", "Fallen Empires": "Fallen Empyres", "Legend of the Five Rings": "Legend of the Five Rangs",
    # Yu-Gi-Oh
    "Legend of Blue Eyes White Dragon": "Legend of Blue-Eyed Pale Dragon", "Blue-Eyes White Dragon": "Blue-Eyed Pale Dragon",
    "Blue-Eyes Shining Dragon": "Blue-Eyed Shiny Dragon", "Blue-Eyes Ultimate Dragon": "Blue-Eyed Ultimate Dragon",
    "Black Luster Soldier": "Black Lustre Soldier", "Dark Magician Girl": "Dark Magishan Gal", "Magician": "Magishan",
    "Red-Eyes Black Dragon": "Red-Eyed Coal Dragon", "Exodia": "Exodio", "Forbidden One": "Forbidden Won",
    "Crush Card Virus": "Crush Card Bug", "Stardust Dragon": "Stardusty Dragon", "Tactical Evolution": "Tactical Evolutian",
    "Obelisk the Tormentor": "Obelisk the Tormenter", "Slifer the Sky Dragon": "Slyfer the Sky Dragon",
    "Winged Dragon of Ra": "Winged Dragon of Rah", "Kaiba": "Kaibo", "Yugi": "Yugo", "Envoy of the Beginning": "Envoy of the Beginnin'",
    "Chaos Emperor Dragon": "Chaos Emperer Dragon", "Envoy of the End": "Envoy of the Endd", "Invasion of Chaos": "Invasion of Kaos",
    "Metal Raiders": "Metal Raidurs", "Jinzo": "Jinzou", "Pharaoh's Servant": "Pharoah's Servent", "Summoned Skull": "Summoned Skul",
    "Black Skull Dragon": "Black Skul Dragon", "Black Chaos": "Black Kaos", "Change of Heart": "Change of Hearts",
    "Mirror Force": "Mirror Forse", "Imperial Order": "Imperial Ordur", "Harpie's Feather Duster": "Harpy's Feather Duster",
    "Raigeki": "Raigekki", "Pot of Greed": "Pot of Grief", "Monster Reborn": "Monster Reborned", "Gaia the Fierce Knight": "Gaya the Fierce Knight",
    "Thousand Dragon": "Thousand Dragoon", "Relinquished": "Relinquisht", "Cyber Dragon": "Cyber Dragun",
    "Cybernetic Revolution": "Cybernetic Revolushun", "Dark Paladin": "Dark Paladeen", "Witch of the Black Forest": "Witch of the Black Forrest",
    "Sangan": "Sangun", "Kuriboh": "Kuribo", "Time Wizard": "Time Wizzard", "Baby Dragon": "Babby Dragon",
    "Celtic Guardian": "Celtik Guardian", "Mystical Elf": "Mystikal Elf", "Feral Imp": "Feral Impp", "Shonen Jump": "Shonen Jumpp",
    # Other games
    "Lorcana": "Lorecana", "Mickey Mouse": "Mikey Mouse", "Brave Little Tailor": "Brave Little Taylor", "Elsa": "Elza",
    "Stitch": "Stich", "World of Warcraft": "World of Warcrate", "Spectral Tiger": "Spectral Tigre", "Fires of Outland": "Fires of Outlandish",
    "Heroes of Azeroth": "Heroes of Azeroff", "Dragon Ball Z": "Dragon Brawl Z", "Dragon Ball Super": "Dragon Brawl Super",
    "Goku": "Gokku", "Vegeta": "Vejeta", "Saiyan Saga": "Sayan Saga", "Frieza Saga": "Freezer Saga", "Star Wars": "Starr Warz",
    "Darth Vader": "Darth Vadur", "Luke Skywalker": "Luke Skystroller", "Lightsaber": "Lightsabre", "A New Hope": "A New Hop",
    "Digimon": "Digimonz", "Omnimon": "Omnimonz", "Agumon": "Agumonz", "One Piece": "One Peace", "Monkey D. Luffy": "Monkey D. Luffo",
    "Shanks": "Shankz", "Romance Dawn": "Romance Dusk", "Paramount War": "Paramount Warr", "Flesh and Blood": "Flesh and Bones",
    "Fyendal's Spring Tunic": "Fyendel's Spring Tunic", "Welcome to Rathe": "Welcome to Wrath", "Duel Masters": "Duel Mastors",
    "Bolshack Dragon": "Bolshak Dragon", "Ragnarok": "Ragnarock", "Harry Potter": "Harry Plotter", "Albus Dumbledore": "Albus Bumblebore",
    "Hagrid": "Hagrud", "Marvel OverPower": "Marble OverPower", "Spider-Man": "Spyder-Man", "Wolverine": "Wolfverine",
    "Final Fantasy": "Final Fantasia", "Sephiroth": "Sephirath", "Bahamut": "Bahamoot", "Neopets": "Neopuppets",
    "Gandalf": "Gandolf", "Frodo Baggins": "Frodo Biggins", "Cardfight Vanguard": "Cardfite Vanguard", "Blaster Blade": "Blaster Blayde",
    "Weiss Schwarz": "Weiss Schwartz", "Vampire Eternal Struggle": "Vampyre Eternal Struggle", "Jyhad": "Jyhadd",
    "Rokugan": "Rokugen", "MetaZoo": "MetaZoom", "Tazo": "Tazzo",
}
_SUB_KEYS = sorted(SUBS, key=len, reverse=True)


def parody(s):
    out = s
    done = []
    for k in _SUB_KEYS:
        pat = r"(?<![A-Za-z])" + re.escape(k) + r"(?![A-Za-z])"
        if re.search(pat, out):
            # Placeholder so a replacement is never matched again.
            tok = "\x00%d\x00" % len(done)
            out = re.sub(pat, tok, out)
            done.append(SUBS[k])
    for i, v in enumerate(done):
        out = out.replace("\x00%d\x00" % i, v)
    return out


# ------------------------------------------------------------------ card data
PACK_WORDS = ["Booster Box", "Booster Pack", "Starter Deck", "Elite Trainer Box", "Collection", "Theme Deck"]

# Subject (3D emoji) for the art window, by substring of the REAL name. First match wins.
SUBJ = [
    ("Pikachu Illustrator", "hamster#ffd23f"), ("Pikachu", "hamster#ffd23f"), ("Raichu", "hamster#ff9a3d"),
    ("No. 1 Trainer", "trophy"), ("Trophy", "trophy"), ("Master's Key", "old_key"), ("Charmander", "lizard#ff8a3d"),
    ("Charizard", "dragon#ff8a3d"), ("Blastoise", "turtle#4f7cff"), ("Squirtle", "turtle#7fc6ff"), ("Venusaur", "sauropod#5ec46a"),
    ("Bulbasaur", "frog#5ec46a"), ("Rayquaza", "dragon#3aa856"), ("Umbreon", "black_cat"), ("Espeon", "cat#d48aff"),
    ("Mewtwo", "alien#c9a0ff"), ("Mew", "cat#ffa6d9"), ("Lugia", "bird#dfe8ff"), ("Gyarados", "snake#3a6fd6"),
    ("Tyranitar", "t_rex#5f8a4a"), ("Ho-Oh", "bird#ff6a3d"), ("Giratina", "dragon#4a3a5a"), ("Gengar", "ghost#8a5cd6"),
    ("Dragonite", "dragon#ffb04a"), ("Alakazam", "fox#e0b13a"), ("Zapdos", "bird#ffe14a"), ("Machamp", "person_wrestling"),
    ("Ninetales", "fox#ffe0a0"), ("Typhlosion", "hedgehog#ff8a3d"), ("Feraligatr", "crocodile"), ("Moltres", "bird#ff5a2a"),
    ("Articuno", "bird#9ad8ff"), ("Snorlax", "bear#3a5a7a"), ("Scyther", "beetle#5ec46a"), ("Vaporeon", "fox#4fa3ff"),
    ("Jolteon", "fox#ffe14a"), ("Flareon", "fox#ff7a3d"), ("Hitmonchan", "boxing_glove"), ("Chansey", "egg"),
    ("Clefairy", "person_fairy"), ("Lapras", "sauropod#6fa8ff"), ("Aerodactyl", "bat"), ("Kabutops", "beetle#c08a5a"),
    ("Eevee", "dog"), ("Psyduck", "duck"), ("Magikarp", "fish#ff5a3d"), ("Rattata", "rat"), ("Diglett", "worm"),
    ("Kangaskhan", "bear#b07a4a"), ("Pokemon 151", "sparkles"),
    ("Black Lotus", "blossom"), ("Mox", "gem_stone"), ("Ancestral Recall", "books"), ("Time Walk", "hourglass_not_done"),
    ("Timetwister", "counterclockwise_arrows_button"), ("One Ring", "ring"), ("Shichifukujin", "dragon#d23a3a"),
    ("World Champion", "trophy"), ("Library of Alexandria", "books"), ("Bazaar", "circus_tent"), ("Workshop", "hammer_and_wrench"),
    ("Tabernacle", "classical_building"), ("Time Vault", "locked"), ("Chaos Orb", "crystal_ball"), ("Underground Sea", "water_wave"),
    ("Volcanic", "volcano"), ("Tropical", "palm_tree"), ("Forcefield", "shield"), ("Cradle", "seedling"), ("Imperial Seal", "scroll"),
    ("Lion's Eye", "gem_stone"), ("Juzam", "woman_genie"), ("Mana Drain", "droplet"), ("Moat", "castle"), ("Candelabra", "candle"),
    ("Berserk", "angry_face_with_horns"), ("Wheel of Fortune", "game_die"), ("Nicol Bolas", "dragon_face"), ("Badlands", "desert"),
    ("Bayou", "crocodile"), ("Taiga", "snow_capped_mountain"), ("Tundra", "snowflake"), ("Plateau", "mountain"),
    ("Savannah", "lion"), ("Scrubland", "cactus"), ("Force of Will", "high_voltage"), ("Jace", "person_mage"),
    ("Mana Crypt", "coffin"), ("Grim Monolith", "moai"), ("Chains", "skull"), ("Ali from Cairo", "person_supervillain"),
    ("Sol Ring", "ring"), ("Demonic Tutor", "smiling_face_with_horns"), ("Sylvan Library", "open_book"), ("Mana Vault", "money_bag"),
    ("Serra Angel", "smiling_face_with_halo"), ("Shivan", "dragon#d23a3a"), ("Atlantis", "fish"), ("Lightning Bolt", "high_voltage"),
    ("Dark Ritual", "candle"), ("Counterspell", "magic_wand"), ("Llanowar", "person_elf"), ("Giant Growth", "seedling"),
    ("Swords to", "crossed_swords"), ("Grizzly", "bear"),
    ("Blue-Eyes", "dragon#dfe8ff"), ("Blue Eyes", "dragon#dfe8ff"), ("Dark Magician Girl", "person_mage#ff9ad8"), ("Magician", "person_mage#8a5cd6"),
    ("Red-Eyes", "dragon#3a2a2a"), ("Exodia", "ogre"), ("Arm of the", "mechanical_arm"), ("Leg of the", "ogre"),
    ("Black Luster", "person_superhero"), ("Crush Card", "microbe"), ("Stardust", "dragon#bfe6ff"), ("Obelisk", "moai#4f7cff"),
    ("Slifer", "dragon#d23a3a"), ("Winged Dragon of Ra", "eagle#ffcc33"), ("Chaos Emperor", "dragon_face"), ("Jinzo", "robot"),
    ("Summoned Skull", "skull"), ("Black Skull", "dragon_face"), ("Change of Heart", "red_heart"), ("Mirror Force", "mirror_ball"),
    ("Imperial Order", "scroll"), ("Harpie", "wing"), ("Raigeki", "high_voltage"), ("Pot of Greed", "amphora"),
    ("Monster Reborn", "smiling_face_with_halo"), ("Gaia", "horse"), ("Thousand Dragon", "dragon#b0a070"), ("Relinquished", "eye"),
    ("Cyber Dragon", "dragon#c0c8d8"), ("Dark Paladin", "person_mage"), ("Witch", "woman_genie"), ("Sangan", "alien_monster"),
    ("Kuriboh", "hedgehog#8b5a2b"), ("Time Wizard", "mantelpiece_clock"), ("Baby Dragon", "dragon#ffb04a"),
    ("Celtic", "person_elf"), ("Mystical Elf", "person_fairy"), ("Feral Imp", "ogre"),
    ("Mickey", "rat"), ("Spectral Tiger", "tiger"), ("Goku", "martial_arts_uniform"), ("Darth Vader", "military_helmet"),
    ("Omnimon", "robot"), ("Shanks", "pirate_flag"), ("Fyendal", "gloves"), ("Bolshack", "dragon#d23a3a"), ("Elsa", "snowflake"),
    ("Harry Potter", "magic_wand"), ("Spider-Man", "spider"), ("Sephiroth", "person_supervillain"), ("Faerie", "person_fairy"),
    ("Bahamut", "dragon#3a3a5a"), ("Luke", "person_superhero"), ("Gandalf", "person_mage"), ("Vegeta", "martial_arts_uniform"),
    ("Ragnarok", "dragon_face"), ("Blaster Blade", "crossed_swords"), ("Dumbledore", "person_mage"), ("Luffy", "pirate_flag"),
    ("Stitch", "alien"), ("Weiss", "princess"), ("Agumon", "t_rex"), ("Wolverine", "wolf"), ("Vampire", "person_vampire"),
    ("Rokugan", "japanese_castle"), ("Mystery Card", "alien"), ("Hagrid", "ogre"), ("Tazo", "hamster#ffd23f"),
    ("Lightsaber", "crossed_swords"), ("Frodo", "ring"), ("Basic Land", "mountain"),
]

CRIT_TYPE = [
    (["Charizard", "Charmander", "Moltres", "Ninetales", "Flareon", "Typhlosion", "Ho-Oh"], "Fire"),
    (["Blastoise", "Squirtle", "Gyarados", "Lapras", "Vaporeon", "Feraligatr", "Psyduck", "Magikarp", "Articuno"], "Water"),
    (["Venusaur", "Bulbasaur", "Scyther"], "Grass"),
    (["Pikachu", "Raichu", "Zapdos", "Jolteon"], "Lightning"),
    (["Mewtwo", "Mew", "Alakazam", "Gengar", "Espeon", "Lugia", "Giratina"], "Psychic"),
    (["Machamp", "Hitmonchan", "Kabutops", "Aerodactyl", "Diglett"], "Fighting"),
    (["Umbreon", "Dark ", "Tyranitar"], "Darkness"),
    (["Rayquaza", "Dragonite"], "Dragon"),
    (["No. 1 Trainer", "Master's Key", "Trophy"], "Trainer"),
]
MOVES = {
    "Fire": ["Fire Spin", "Ember", "Flamethrower", "Heat Wave", "Scorch"], "Water": ["Hydro Pump", "Bubble", "Water Gun", "Surf", "Tidal Splash"],
    "Grass": ["Solar Beam", "Vine Whip", "Leaf Blade", "Sleep Powder"], "Lightning": ["Thunder", "Thundershock", "Spark", "Static Bolt"],
    "Psychic": ["Psychic", "Barrier", "Confuse Ray", "Mind Shock", "Hypnosis"], "Fighting": ["Seismic Toss", "Karate Chop", "Dig", "Rock Slide"],
    "Darkness": ["Shadow Ball", "Bite", "Dark Pulse", "Night Slash"], "Dragon": ["Dragon Rush", "Hyper Beam", "Slam", "Outrage"],
    "Colorless": ["Tackle", "Body Slam", "Quick Attack", "Rest", "Scratch"], "Trainer": [],
}
MAGI_COLOR = [
    (["Lotus", "Mox", "Ring", "Vault", "Orb", "Crypt", "Monolith", "Candelabra", "Diamond", "Chains"], "Artifact"),
    (["Library", "Bazaar", "Workshop", "Tabernacle", "Sea", "Island", "Cradle", "Badlands", "Bayou", "Taiga", "Tundra",
      "Plateau", "Savannah", "Scrubland", "Land"], "Land"),
    (["Ancestral", "Time Walk", "Timetwister", "Mana Drain", "Force of Will", "Jace", "Counterspell", "Atlantis", "Imperial Seal", "Forcefield"], "Blue"),
    (["Juzam", "Demonic", "Dark Ritual", "Nicol Bolas", "Imperial"], "Black"),
    (["Wheel", "Shivan", "Lightning", "Chaos", "Shichifukujin", "Ali from"], "Red"),
    (["Berserk", "Sylvan", "Llanowar", "Giant Growth", "Grizzly"], "Green"),
    (["Moat", "Serra", "Swords", "World Champion"], "White"),
]
MAGI_LINE = {"Artifact": "Artifact", "Land": "Land", "Blue": "Sorcery", "Black": "Sorcery", "Red": "Instant", "Green": "Instant", "White": "Enchantment"}
CREATURES = {"Juzam Djinn": ("Djinn", "5/5", "2BB"), "Nicol Bolas": ("Elder Dragon Legend", "7/7", "2UUBBRR"),
             "Shichifukujin Dragon": ("Dragon", "0/0", "6RRR"), "Serra Angel": ("Angel", "4/4", "3WW"), "Shivan Dragon": ("Dragon", "5/5", "4RR"),
             "Lord of Atlantis": ("Merfolk", "2/2", "UU"), "Llanowar Elves": ("Elf Druid", "1/1", "G"), "Grizzly Bears": ("Bear", "2/2", "1G"),
             "Ali from Cairo": ("Human", "0/1", "2RR"), "Jace, the Mind Sculptor": ("Planeswalker", "3", "2UU"), "1996 World Champion": ("Legend", "*/*", "WUBRG")}
MAGI_COST = {"Artifact": ["0", "1", "2", "3", "4"], "Land": [""], "Blue": ["U", "1U", "UU", "2U"], "Black": ["B", "1B", "2B"],
             "Red": ["R", "1R", "2R"], "Green": ["G", "1G", "2G"], "White": ["W", "1W", "2WW"]}
YUGI_TYPE = [
    (["Spell", "Raigeki", "Pot of Greed", "Monster Reborn", "Change of Heart", "Harpie", "Crush Card"], "Spell"),
    (["Mirror Force", "Imperial Order"], "Trap"),
    (["Ultimate", "Black Skull", "Thousand Dragon", "Dark Paladin"], "Fusion"),
    (["Magician of Black Chaos", "Relinquished", "Black Luster Soldier"], "Ritual"),
    (["Envoy", "Exodia", "Jinzo", "Witch", "Sangan", "Kuriboh", "Cyber Dragon", "Stardust", "Obelisk", "Slifer", "Winged", "Time Wizard", "Dark Magician Girl", "Shining"], "Effect"),
]
ATTRS = ["DARK", "LIGHT", "FIRE", "WATER", "EARTH", "WIND", "DIVINE"]
ALT_GAMES = [("Lord of the Rings", "Lord of the Rangs TCG"), ("Lorcana", "Lorecana"), ("World of Warcraft", "World of Warcrate TCG"),
             ("Spectral", "World of Warcrate TCG"), ("Dragon Ball", "Dragon Brawl"), ("Goku", "Dragon Brawl"), ("Vegeta", "Dragon Brawl"),
             ("Star Wars", "Starr Warz CCG"), ("Darth", "Starr Warz CCG"), ("Luke", "Starr Warz CCG"), ("Lightsaber", "Starr Warz CCG"),
             ("Digimon", "Digimonz"), ("Omnimon", "Digimonz"), ("Agumon", "Digimonz"), ("One Piece", "One Peace"), ("Luffy", "One Peace"),
             ("Shanks", "One Peace"), ("Flesh and Blood", "Flesh and Bones"), ("Duel Masters", "Duel Mastors"), ("Bolshack", "Duel Mastors"),
             ("Ragnarok", "Duel Mastors"), ("Harry Potter", "Harry Plotter TCG"), ("Dumbledore", "Harry Plotter TCG"), ("Hagrid", "Harry Plotter TCG"),
             ("Marvel", "Marble OverPower"), ("Spider", "Marble OverPower"), ("Wolverine", "Marble OverPower"), ("Final Fantasy", "Final Fantasia TCG"),
             ("Sephiroth", "Final Fantasia TCG"), ("Bahamut", "Final Fantasia TCG"), ("Neopets", "Neopuppets TCG"), ("Faerie", "Neopuppets TCG"),
             ("Gandalf", "Lord of the Rangs TCG"), ("Frodo", "Lord of the Rangs TCG"), ("Vanguard", "Cardfite Vanguard"), ("Weiss", "Weiss Schwartz"),
             ("Vampire", "Vampyre: Eternal Struggle"), ("Rokugan", "Legend of the Five Rangs"), ("MetaZoo", "MetaZoom"), ("Mystery", "MetaZoom"),
             ("Tazo", "Snack Tazzos"), ("Squirtle", "Vending Stickers"), ("Basic Land", "Bulk Bin")]
ALT_COLORS = {"Lord of the Rangs TCG": "c9a227", "Lorecana": "4a3a8a", "World of Warcrate TCG": "8a5a2a", "Dragon Brawl": "e8892e",
              "Starr Warz CCG": "2b2b2b", "Digimonz": "3a6fd6", "One Peace": "c23a3a", "Flesh and Bones": "7a1f2a", "Duel Mastors": "3a8a5a",
              "Harry Plotter TCG": "6a2a8a", "Marble OverPower": "d64545", "Final Fantasia TCG": "5c6ad9", "Neopuppets TCG": "e0b13a",
              "Cardfite Vanguard": "3a8ad6", "Weiss Schwartz": "d0d0d8", "Vampyre: Eternal Struggle": "5a0a1a", "Legend of the Five Rangs": "8a2a2a",
              "MetaZoom": "2a6a4a", "Snack Tazzos": "ff9a3d", "Vending Stickers": "4fa3ff", "Bulk Bin": "8a8f99"}
CARD_PUB = {"CRIT": ["Critter Co.", "Lizards of the Coast"], "MAGI": ["Lizards of the Coast"], "YUGI": ["Konamo", "Upper Deck-ish"]}
ARTISTS = ["Mitsuhiro Arita", "Ken Sugimurra", "Kagemaru Himenoh-ish", "Keiji Kinebuchy", "Tomokazu Komiyama-ish", "Atsuko Nishidda",
           "Christopher Rush-Hour", "Mark Tedin-Tedout", "Douglas Shuler-ish", "Anson Maddox-ish", "Quinton Hoovered", "Rebecca Gay-Light",
           "Kazuki Takahashi-ish", "Naoyo Kimura-ish", "Ron Spencer-ish", "Pete Venters-ish", "Amy Weber-ish", "Drew Tucker-ish"]
FLAVOR_CARD = {
    "CRIT": ["It spits fire hot enough to melt boulders. Known to cause forest fires unintentionally.",
             "When several gather, their electricity could build and cause lightning storms.",
             "It is said to live deep in the ocean and only surface on stormy nights.",
             "Its body is wrapped in mystery. Nobody has seen it sleep.",
             "It stores energy in its cheeks. Do not pinch.", "It hides in tall grass and naps in the sun all day."],
    "MAGI": ["\"The flower blooms but once, and so does fortune.\"", "Knowledge is power, and power is everything.",
             "Some say it was forged before time began. Most say nothing and keep it in a binder.",
             "\"Tap it, and the world bends.\" - Archmage Urzo", "Flavor text intentionally left mysterious.",
             "The ground remembers every battle fought upon it."],
    "YUGI": ["This legendary dragon is a powerful engine of destruction.", "The ultimate wizard in terms of attack and defense.",
             "Once the five pieces are gathered, the game is over.", "A card of legend, sought by duelists everywhere.",
             "Heart of the cards not included.", "It appears only to those who believe in it."],
    "ALT": ["A fan favourite from the kitchen-table days.", "Pulled once in a blue moon, traded for a fortune.",
            "The card everybody wanted in the schoolyard.", "Still tournament legal somewhere, probably.",
            "The foil catches the light like nothing else.", "Lovingly kept in a sleeve since day one."],
}
PACK_BLURB = ["Sealed and unsearched. Every pack a lottery ticket.", "Factory sealed, crisp corners, untouched since the warehouse.",
              "Will you rip it or keep it? The eternal question.", "Shake it gently. Do not weigh it. Ok, maybe weigh it."]

# ------------------------------------------------------------------ coin data
COIN_COUNTRY = {"CENT": "United States", "SILV": "United States", "GOLD": "United States"}
WORLD_COUNTRY = [("London", "Great Britain"), ("Sydney", "Australia"), ("Perth", "Australia"), ("Ottawa", "Canada"), ("Pretoria", "South Africa"),
                 ("Mexico", "Mexico"), ("Segovia", "Spain"), ("Seville", "Spain"), ("Bydgoszcz", "Poland"), ("Tientsin", "China"), ("Shenyang", "China"),
                 ("Beijing", "China"), ("Kaifeng", "Song China"), ("Osaka", "Japan"), ("Boston", "Massachusetts Bay"), ("Philadelphia", "Continental Congress"),
                 ("Paris", "France"), ("Berlin", "Germany"), ("Vienna", "Austria"), ("Rome", "Rome"), ("Utrecht", "Netherlands"), ("Bern", "Switzerland"),
                 ("St Petersburg", "Russia"), ("Nassau", "Bahamas"), ("Douglas", "Isle of Man"), ("Athens", "Athens"), ("Syracuse", "Syracuse"),
                 ("Macedon", "Macedon"), ("Amphipolis", "Macedon"), ("Sardis", "Lydia"), ("Florence", "Florence"), ("Venice", "Venice"),
                 ("Constantinople", "Byzantium"), ("Damascus", "Umayyad Caliphate"), ("Aegina", "Aegina"), ("Ephesus", "Ionia"),
                 ("Alexandria", "Ptolemaic Egypt"), ("Jerusalem", "Judaea"), ("Tyre", "Phoenicia"), ("Lugdunum", "Rome"), ("Aachen", "Frankish Empire"),
                 ("Acre", "Kingdom of Jerusalem"), ("Trier", "Rome"), ("Winchester", "Anglo-Saxon England"), ("Istanbul", "Ottoman Empire"),
                 ("Samarkand", "Samanid Empire"), ("Bactria", "Kushan Empire"), ("Gaul", "Celtic Gaul"), ("Carthage", "Carthage"),
                 ("Antioch", "Seleucid Empire"), ("Edo", "Japan"), ("New York", "United States")]
# Obverse motif by name keyword (first match). The coin painter draws each one.
OBV = [("Eid Mar", "emperor"), ("Lincoln", "lincoln"), ("Wheat", "lincoln"), ("Indian", "indian"), ("Buffalo", "indian"),
       ("Jefferson", "colonial"), ("Monticello", "colonial"), ("Washington", "colonial"), ("Kennedy", "modern"), ("Franklin", "modern"),
       ("Eisenhower", "modern"), ("Peace", "liberty_rays"), ("Saint-Gaudens", "striding"), ("Ultra High Relief", "striding"),
       ("High Relief Double", "striding"), ("Walking Liberty", "striding"), ("Standing Liberty", "striding"), ("Silver Eagle", "striding"),
       ("Gold Eagle", "striding"), ("Panama", "striding"), ("Centenario", "striding"), ("Ducat", "striding"), ("Florin", "striding"),
       ("Mercury", "liberty_wings"), ("Shield", "shield"), ("Two Cent", "shield"), ("Flying Eagle", "eagle"), ("Cap and Rays", "eagle"),
       ("Seated", "seated"), ("Gobrecht", "seated"), ("Trade Dollar", "seated"), ("Twenty Cent", "seated"), ("Half Disme", "liberty"),
       ("Britannia", "seated"), ("Pine Tree", "tree"), ("Oak Tree", "tree"), ("Continental", "sun"), ("Brasher", "sun"),
       ("Maple", "monarch"), ("Panda", "temple"), ("Dragon Dollar", "monarch"), ("Long-Whisker", "monarch"), ("Chang Tso-lin", "monarch"),
       ("Japan 20 Yen", "dragon"), ("Keicho", "script"), ("Pillar", "pillars"), ("Reales", "arms"), ("Escudos", "arms"), ("Cob", "arms"),
       ("Krugerrand", "monarch"), ("Nugget", "monarch"), ("Vreneli", "liberty"), ("Rooster", "liberty"), ("Una and the Lion", "monarch"),
       ("Athens", "athena"), ("Owl", "athena"), ("Syracuse", "nymph"), ("Alexander", "helmet"), ("Lydia", "lion"), ("Aegina", "turtle"),
       ("Ephesus", "bee"), ("Roman Republic", "helmet"), ("Celtic", "emperor"), ("Carthage", "nymph"), ("Judaea", "chalice"),
       ("Umayyad", "script"), ("Samanid", "script"), ("Ottoman", "script"), ("Song Dynasty", "cash"), ("Chinese Cash", "cash"),
       ("Crusader", "cross"), ("Byzantine", "christ"), ("Edward", "monarch"), ("Victoria", "monarch"), ("George", "monarch"),
       ("Anne", "monarch"), ("Elizabeth", "monarch"), ("Henry", "monarch"), ("Nicholas", "monarch"), ("Constantine Rouble", "monarch"),
       ("Russia", "monarch"), ("Sigismund", "monarch"), ("Napoleon", "monarch"), ("Maria Theresa", "monarch"), ("Vittorio", "monarch"),
       ("Hidalgo", "colonial"), ("Charlemagne", "cross"), ("William", "monarch"), ("Aethelred", "monarch"), ("Coronation", "monarch"),
       ("Isle of Man", "monarch"), ("Bahamas", "monarch"), ("Canada", "monarch"), ("Germany", "eagle"), ("Mexico", "eagle"),
       ("Kushan", "emperor"), ("Seleucid", "emperor"), ("Ptolemy", "emperor"), ("Tyre", "emperor"), ("Augustus", "emperor"),
       ("Nero", "emperor"), ("Hadrian", "emperor"), ("Marcus", "emperor"), ("Tiberius", "emperor"), ("Trajan", "emperor"),
       ("Constantine", "emperor"), ("Gallienus", "emperor"), ("Aurelian", "emperor"), ("Late Roman", "emperor"),
       ("Venice Soldino", "striding"), ("Liberty Cap", "liberty_cap"), ("Flowing Hair", "liberty_flowing"), ("Chain", "liberty_flowing"),
       ("Wreath", "liberty_flowing"), ("Draped Bust", "liberty"), ("Capped Bust", "liberty_cap"), ("Classic Head", "liberty"),
       ("Braided Hair", "liberty"), ("Booby", "liberty"), ("Coronet", "liberty"), ("Morgan", "liberty"), ("Barber", "liberty"),
       ("Liberty Head", "liberty"), ("Stella", "liberty_flowing"), ("Three Cent", "liberty"), ("Mormon", "eye"), ("Wass Molitor", "liberty"),
       ("Mexico Peso", "monarch"), ("Edward III", "monarch")]
REV = [("Eid Mar", "daggers"), ("Buffalo", "bison"), ("Three-Legged", "bison"), ("Lincoln Cent", "wheat"), ("Wheat", "wheat"),
       ("Steel Lincoln", "wheat"), ("Bronze Lincoln", "wheat"), ("Jefferson", "building"), ("Monticello", "building"),
       ("Liberty Head Nickel", "denom"), ("Liberty Nickel", "denom"), ("Indian Head Cent", "wreath"), ("Flying Eagle Cent", "wreath"),
       ("Chain", "chain"), ("Continental", "chain"), ("Mercury", "fasces"), ("Franklin", "bell"), ("Stella", "star"), ("Three Dollar", "wreath"),
       ("Indian Princess", "wreath"), ("Seated Liberty Dime", "wreath"), ("Seated Dime", "wreath"), ("Barber Dime", "wreath"),
       ("Shield Nickel", "denom"), ("Two Cent", "wreath"), ("Three Cent", "denom"), ("Half Cent", "wreath"), ("Cent", "wreath"),
       ("Pine Tree", "denom"), ("Oak Tree", "denom"), ("Sovereign", "horseman"), ("Una and the Lion", "lion"), ("Jubilee Crown", "horseman"),
       ("Gothic Crown", "arms"), ("Victoria Crown", "horseman"), ("Coronation", "arms"), ("Five Guineas", "arms"), ("Maple", "maple"),
       ("Panda", "panda"), ("Krugerrand", "springbok"), ("Nugget", "kangaroo"), ("Britannia", "lion"), ("Dragon Dollar", "dragon"),
       ("Long-Whisker", "dragon"), ("Japan 20 Yen", "sun"), ("Chang Tso-lin", "wreath"), ("Pillar", "globe"), ("8 Reales", "eagle"),
       ("Escudos", "cross"), ("Cob", "cross"), ("Ducat", "lily"), ("Florin", "lily"), ("Leopard", "lion"), ("Rooster", "rooster"),
       ("Vreneli", "shield"), ("Thaler", "eagle"), ("Mark", "eagle"), ("Roubles", "eagle"), ("Rouble", "eagle"), ("Lire", "eagle"),
       ("Napoleon", "wreath"), ("Mexico", "eagle"), ("Canada Silver Dollar", "canoe"), ("Centennial", "goose"), ("Canada Gold", "arms"),
       ("Bahamas", "fish"), ("Isle of Man", "denom"), ("Mormon", "clasp"), ("Wass Molitor", "denom"), ("Panama-Pacific Fifty", "owl"),
       ("Athens", "owl"), ("Owl", "owl"), ("Syracuse", "chariot"), ("Alexander the Great Gold", "victory"), ("Alexander", "zeus"),
       ("Lydia", "punch"), ("Aegina", "punch"), ("Ephesus", "stag"), ("Ptolemy", "eagle"), ("Roman Republic", "dioscuri"),
       ("Judaea", "lily"), ("Tyre", "eagle"), ("Tribute", "seated"), ("Celtic", "horse"), ("Carthage", "horse"), ("Seleucid", "zeus"),
       ("Kushan", "god"), ("Umayyad", "script"), ("Samanid", "script"), ("Ottoman", "script"), ("Song Dynasty", "cash"), ("Cash Coin", "cash"),
       ("Crusader", "script"), ("Byzantine", "script"), ("Charlemagne", "temple"), ("Penny", "cross"), ("Groat", "cross"),
       ("Sixpence", "arms"), ("Noble", "ship"), ("Angel", "ship"), ("Edward III Florin", "lion"), ("Soldino", "lion"),
       ("Augustus", "temple"), ("Nero", "temple"), ("Hadrian", "seated"), ("Marcus", "seated"), ("Constantine", "victory"),
       ("Gallienus", "god"), ("Aurelian", "god"), ("Trajan", "temple"), ("Late Roman", "victory"), ("Brasher", "eagle"),
       ("Kennedy", "eagle"), ("Eisenhower", "eagle"), ("Peace", "eagle"), ("Morgan", "eagle"), ("Washington", "eagle"),
       ("Gobrecht", "eagle"), ("Trade Dollar", "eagle"), ("Seated", "eagle"), ("Barber", "eagle"), ("Standing", "eagle"),
       ("Walking", "eagle"), ("Saint-Gaudens", "eagle"), ("Double Eagle", "eagle"), ("Eagle", "eagle"), ("Twenty Cent", "eagle"),
       ("Half Disme", "eagle"), ("Half Dime", "eagle"), ("Dollar", "eagle"), ("Quarter", "eagle"), ("Half", "eagle"), ("Dime", "wreath")]
METAL_BLURB = {
    "gold": ["Struck in gold and never spent. Heavy for its size, warm in the hand.", "Gold doesn't tarnish. Collectors do, slowly, in auction rooms."],
    "silver": ["Silver with a soft tone around the rim. Do not clean it. Ever.", "Rings like a bell when you drop it. Please don't drop it."],
    "copper": ["Copper turns brown, red, then priceless. Original red is the dream.", "Big, brown and older than the country's highways."],
    "bronze": ["Pocket change once. Now it lives in a slab.", "Bronze, worn by a century of pockets and penny jars."],
    "nickel": ["Nickel wears fast. A sharp one is a real find.", "The date is the first thing to go on these."],
    "other": ["A strange metal for a strange coin.", "Odd metal, odd history, very odd prices."],
}


def _first(table, name, default):
    for k, v in table:
        for kk in (k if isinstance(k, list) else [k]):
            if kk in name:
                return v
    return default


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
            parts = [p.strip() for p in m.group(2).split("|")]
            out.append({"rank": int(m.group(1)), "name": parts[0], "detail": parts[1], "year": int(parts[2]), "code": parts[3], "section": section})
    return out


def slug(s):
    s = s.lower().replace("é", "e")
    return re.sub(r"[^a-z0-9]+", "_", s).strip("_")[:30].strip("_")


def tier_of(rows, r):
    sec = [x for x in rows if x["section"] == r["section"]]
    pos = sec.index(r)
    if r["section"] == "THE GRAILS":
        if pos < 8:
            return 3, pos / 8.0
        return 2, (pos - 8) / max(1, len(sec) - 9)
    frac = pos / max(1, len(sec) - 1)
    if frac < 0.12:
        return 2, frac / 0.12
    if frac < 0.4:
        return 1, (frac - 0.12) / 0.28
    return 0, (frac - 0.4) / 0.6


CARD_BANDS = [(4, 18), (24, 80), (100, 360), (1300, 6000)]
PACK_BANDS = [(18, 50), (60, 160), (180, 560), (1800, 7000)]
COIN_BANDS = [(6, 24), (30, 110), (130, 480), (1600, 8000)]


def base_for(bands, tier, frac, key):
    lo, hi = bands[tier]
    v = hi - (hi - lo) * frac
    v *= 0.92 + (h(key, 17) / 100.0)
    return max(1, int(round(v)))


# {card id: research row} for tools/fetch_retro_art.py (real card scans).
REAL = {}
CARD_ART = os.path.join(ROOT, "assets/temp_test/cards")


def card_items(rows):
    items = []
    ids = set()
    names = {}
    for r in rows:
        names[r["name"]] = names.get(r["name"], 0) + 1
    for r in rows:
        real, code, year = r["name"], r["code"], r["year"]
        tier, frac = tier_of(rows, r)
        is_pack = any(w in real for w in PACK_WORDS)
        kind = "pack" if is_pack else "card"
        pname = parody(real)
        pset = parody(r["detail"])
        if names[real] > 1 and not is_pack:
            pname = "%s (%s)" % (pname, pset)
        iid = code.lower() + "_" + slug(pname)
        b = iid
        k = 2
        while iid in ids:
            iid = "%s_%d" % (b, k)
            k += 1
        ids.add(iid)
        REAL[iid] = r
        key = real + r["detail"]
        tags = []
        if is_pack:
            tags.append("box" if ("Box" in real or "Collection" in real) else ("deck" if "Deck" in real else "foil"))
        if "Promo" in r["detail"] or "Prize" in r["detail"] or "Trophy" in real:
            tags.append("promo")
        subj = _first(SUBJ, real, "")
        if subj == "":
            subj = ["dragon#ffb04a", "sparkles", "glowing_star", "crown", "gem_stone"][h(real + "s", 5)]
        d = {"id": iid, "name": pname, "plat": code, "kind": kind, "tier": tier,
             "base": base_for(PACK_BANDS if is_pack else CARD_BANDS, tier, frac, key), "tags": tags,
             "rank": r["rank"], "list": "cards", "real_section": r["section"], "year": year}
        alt_game = _first(ALT_GAMES, real, "Indie TCG") if code == "ALT" else ""
        if code == "ALT":
            d["pub"] = ["Score-ish Ent.", "Bandi Namco", "Ravenspurr", "Upper Desk", "Fantasy Flighty"][h(real + "pub", 5)]
        else:
            pubs = CARD_PUB[code]
            d["pub"] = pubs[0] if len(pubs) == 1 else (pubs[1] if (code == "CRIT" and year <= 2003) else pubs[0])
        d["genre"] = "Card"
        d["set"] = pset
        d["game"] = alt_game
        d["subj"] = subj
        d["artist"] = ARTISTS[h(real + "art", len(ARTISTS))]
        total = [102, 64, 75, 110, 130, 165, 203, 295][h(r["detail"], 8)]
        d["num"] = "%d/%d" % (1 + h(real + "n", total), total)
        if is_pack:
            d["blurb"] = PACK_BLURB[h(real + "b", len(PACK_BLURB))]
            d["rarity"] = "Sealed"
            d["count"] = 36 if "Box" in real else (60 if "Deck" in real else (10 if "Collection" in real else 11))
            if "Booster Box" in real:
                d["count"] = 36
            elif "Elite Trainer" in real:
                d["count"] = 9
            elif "Starter" in real or "Deck" in real:
                d["count"] = 60
            elif "Collection" in real:
                d["count"] = 16
            else:
                d["count"] = 11 if code != "MAGI" else 15
            d["ctype"] = ""
        else:
            d["blurb"] = FLAVOR_CARD[code][h(real + "b", len(FLAVOR_CARD[code]))]
            g = lambda s, n: h(real + s, n)
            if code == "CRIT":
                ct = _first(CRIT_TYPE, real, "Colorless")
                d["ctype"] = ct
                d["rarity"] = "Gold Star" if "Gold Star" in real else ("Promo" if "promo" in tags else ["Common", "Uncommon", "Rare Holo", "Rare Holo"][tier])
                if "Alternate Art" in real or "Special Illustration" in real:
                    d["rarity"] = "Special Art Rare"
                if ct == "Trainer":
                    d["hp"] = 0
                    d["moves"] = []
                    d["text"] = "Trainer. " + ["Awarded to the champion. Not for play.", "Search your deck for any card. Then laugh."][g("t", 2)]
                else:
                    d["hp"] = [40, 50, 60, 70, 80, 90, 100, 120][min(7, tier * 2 + g("hp", 3))]
                    mv = MOVES[ct]
                    m1 = mv[g("m1", len(mv))]
                    m2 = mv[(mv.index(m1) + 1 + g("m2", len(mv) - 1)) % len(mv)]
                    d["moves"] = [[m1, 10 * (1 + g("d1", 4))], [m2, 10 * (3 + tier * 2 + g("d2", 4))]]
                    d["text"] = ""
                d["line"] = "Basic" if tier == 0 else ("Stage 1" if g("st", 2) == 0 else "Stage 2")
            elif code == "MAGI":
                col = _first(MAGI_COLOR, real, "Artifact")
                d["ctype"] = col
                d["rarity"] = ["Common", "Uncommon", "Rare", "Rare"][tier]
                cr = None
                for k2, v in CREATURES.items():
                    if k2 in real:
                        cr = v
                if cr:
                    d["line"] = ("Creature - " if cr[0] != "Planeswalker" else "Legendary ") + cr[0]
                    d["stat"] = cr[1]
                    d["cost"] = cr[2]
                    d["ctype"] = {"B": "Black", "U": "Blue", "R": "Red", "G": "Green", "W": "White"}.get(cr[2][-1], col) if len(set(c for c in cr[2] if c.isalpha())) == 1 else "Gold"
                else:
                    d["line"] = MAGI_LINE[col]
                    d["stat"] = ""
                    costs = MAGI_COST[col]
                    d["cost"] = costs[g("c", len(costs))]
                d["text"] = {"Artifact": "{T}, Sacrifice: Add three mana of any one colour.", "Land": "{T}: Add one mana of any colour you like. It's your card.",
                             "Blue": "Draw three cards. Then draw one more because it's fun.", "Black": "Destroy target creature. It can't be regenerated.",
                             "Red": "Deal 3 damage to any target.", "Green": "Target creature gets +3/+3 until end of turn.",
                             "White": "Creatures without flying can't attack you.", "Gold": "Flying. When this enters, everyone sighs."}[d["ctype"]]
            elif code == "YUGI":
                yt = _first(YUGI_TYPE, real, "Normal")
                d["ctype"] = yt
                d["rarity"] = ["Common", "Rare", "Super Rare", "Ultra Rare"][tier]
                if "Ghost" in real:
                    d["rarity"] = "Ghost Rare"
                if yt in ("Spell", "Trap"):
                    d["line"] = "[%s Card]" % yt
                    d["stat"] = ""
                    d["level"] = 0
                    d["attr"] = yt.upper()
                    d["text"] = {"Spell": "Draw 2 cards. Or destroy everything. Read it twice.", "Trap": "When your opponent attacks: destroy all their attack position monsters."}[yt]
                else:
                    lv = min(12, 2 + tier * 2 + g("lv", 4))
                    if "Obelisk" in real or "Slifer" in real or "Winged" in real:
                        lv = 10
                    d["level"] = lv
                    d["attr"] = "DIVINE" if lv == 10 and ("Obelisk" in real or "Slifer" in real or "Winged" in real) else ATTRS[g("at", 6)]
                    if "Dragon" in real:
                        race = "Dragon"
                    elif "Magician" in real or "Witch" in real or "Wizard" in real:
                        race = "Spellcaster"
                    elif "Skull" in real or "Imp" in real:
                        race = "Fiend"
                    else:
                        race = ["Warrior", "Machine", "Beast", "Fairy", "Spellcaster"][g("race", 5)]
                    d["line"] = "[%s/%s]" % (race, yt if yt != "Normal" else "Normal")
                    a = 100 * (lv * 250 // 100 + g("a", 4))
                    df = 100 * (lv * 200 // 100 + g("df", 5))
                    if "Blue-Eyes White" in real:
                        a, df = 3000, 2500
                    elif real == "Dark Magician":
                        a, df = 2500, 2100
                    elif "Exodia" in real:
                        a, df = 1000, 1000
                    d["stat"] = "ATK/%d DEF/%d" % (a, df)
                    d["text"] = "" if yt == "Normal" else "Cannot be Special Summoned. Only the bravest duelists may wield it."
            else:
                d["ctype"] = alt_game
                d["rarity"] = ["Common", "Uncommon", "Rare", "Secret Rare"][tier]
                d["line"] = ["Character", "Leader", "Hero", "Ally", "Champion"][g("ln", 5)]
                d["stat"] = "%d" % (1000 * (1 + tier + g("pw", 5)))
                d["cost"] = str(1 + g("c", 7))
                d["text"] = ["When played, draw a card.", "Rush. Cannot be blocked by small fry.", "Once per turn: gain 1 power for every fan in the room.",
                             "Exhaust: your opponent discards a card.", "Unique. You may only have one. You will want ten."][g("tx", 5)]
            d["accent"] = ALT_COLORS.get(alt_game, "8a8f99") if code == "ALT" else ""
        d["rating"] = ""
        ranges = [(300000, 4000000), (60000, 300000), (5000, 60000), (1, 4000)]
        lo, hi = ranges[tier]
        d["run"] = lo + h(real + "run", hi - lo)
        if real in ("Pikachu Illustrator", "The One Ring", "Tournament Black Luster Soldier", "No. 1 Trainer"):
            d["run"] = {"Pikachu Illustrator": 39, "The One Ring": 1, "Tournament Black Luster Soldier": 1, "No. 1 Trainer": 7}[real]
        items.append(d)
    return items


def coin_items(rows):
    items = []
    ids = set()
    for r in rows:
        real, code, year = r["name"], r["code"], r["year"]
        tier, frac = tier_of(rows, r)
        denom, metal, mint, dia = [p.strip() for p in r["detail"].split(";")]
        iid = code.lower() + "_" + slug(real)
        b = iid
        k = 2
        while iid in ids:
            iid = "%s_%d" % (b, k)
            k += 1
        ids.add(iid)
        country = COIN_COUNTRY.get(code) or _first(WORLD_COUNTRY, mint, mint)
        if code in ("CENT", "SILV", "GOLD"):
            country = "United States"
        mkey = metal if metal in ("gold", "silver", "copper", "bronze", "nickel") else ("silver" if "silver" in metal else ("copper" if "copper" in metal else "other"))
        obv = _first(OBV, real, "liberty" if code in ("CENT", "SILV", "GOLD") else "monarch")
        rev = _first(REV, real, "wreath" if code != "ANCT" else "script")
        if code == "ANCT" and obv == "monarch" and year < 1000:
            obv = "emperor"
        if country == "United States":
            leg1 = "LIBERTY" if year < 1838 or obv not in ("lincoln", "colonial", "modern") else "IN GOD WE TRUST"
            leg2 = "UNITED STATES OF AMERICA"
        elif code == "ANCT":
            leg1 = {"Athens": "ΑΘΕ", "Syracuse": "ΣΥΡΑΚΟΣΙΩΝ", "Macedon": "ΑΛΕΞΑΝΔΡΟΥ", "Rome": "CAESAR AVGVSTVS", "Byzantium": "IhS XPS",
                    "Florence": "FLORENTIA", "Venice": "S M VENETI", "Judaea": "SHEKEL ISRAEL"}.get(country, country.upper())
            leg2 = {"Athens": "ΑΘΕ", "Rome": "S C", "Macedon": "ΒΑΣΙΛΕΩΣ"}.get(country, denom.upper())
        else:
            leg1 = country.upper()
            leg2 = denom.upper()
        d = {"id": iid, "name": real, "plat": code, "kind": "coin", "tier": tier,
             "base": base_for(COIN_BANDS, tier, frac, real), "tags": [],
             "rank": r["rank"], "list": "coins", "real_section": r["section"], "year": year,
             "pub": ("%s Mint" % mint) if code != "ANCT" else mint, "genre": "Coin",
             "blurb": METAL_BLURB[mkey][h(real + "b", len(METAL_BLURB[mkey]))], "rating": "",
             "denom": denom, "metal": metal, "mint": mint, "dia": int(dia), "country": country,
             "obv": obv, "rev": rev, "legend": leg1, "legend2": leg2}
        if "Proof" in real:
            d["tags"].append("proof")
        if "Doubled" in real or "Micro" in real or "/" in real.split(" ")[0] or "No D" in real or "Three-Legged" in real or "No Cents" in real:
            d["tags"].append("error")
        ranges = [(2000000, 90000000), (200000, 2000000), (5000, 200000), (1, 5000)]
        lo, hi = ranges[tier]
        d["run"] = lo + h(real + "run", hi - lo)
        known = {"1913 Liberty Head Nickel": 5, "1804 Draped Bust Dollar": 15, "1933 Saint-Gaudens Double Eagle": 13, "1787 Brasher Doubloon": 7,
                 "1343 Edward III Double Leopard": 3, "1894-S Barber Dime": 24, "1870-S Seated Liberty Dollar": 12, "1943 Bronze Lincoln Cent": 20,
                 "1822 Capped Bust Half Eagle": 3, "1849 Double Eagle Pattern": 1, "1907 Ultra High Relief Double Eagle": 22}
        if real in known:
            d["run"] = known[real]
        items.append(d)
    return items


def main():
    cards = card_items(parse(CARDS))
    coins = coin_items(parse(COINS))
    for d in cards:
        for ext in ("jpg", "png"):
            f = os.path.join(CARD_ART, "%s_scan.%s" % (d["id"], ext))
            if os.path.exists(f):
                d["scan"] = "res://" + os.path.relpath(f, ROOT).replace(os.sep, "/")
                break

    def val(v):
        if isinstance(v, str):
            return json.dumps(v, ensure_ascii=False)
        if isinstance(v, list):
            return "[" + ", ".join(val(x) for x in v) + "]"
        if isinstance(v, bool):
            return "true" if v else "false"
        return str(v)

    lines = ["extends RefCounted",
             "## GENERATED by tools/gen_collectibles.py from docs/research/tcg_cards_top_250.txt and",
             "## rare_coins_top_250.txt. Do not edit by hand: change the generator (or the lists) and run it again.",
             "## No class_name (TV self-update): Catalog preloads this file.", ""]
    for nm, arr in (("CARDS", cards), ("COINS", coins)):
        lines.append("const %s := [" % nm)
        for d in arr:
            lines.append("\t{" + ", ".join("%s: %s" % (json.dumps(k), val(v)) for k, v in d.items()) + "},")
        lines.append("]")
        lines.append("")
    open(OUT, "w", encoding="utf-8").write("\n".join(lines))
    for nm, arr in (("cards", cards), ("coins", coins)):
        tiers = [0, 0, 0, 0]
        plats = {}
        for d in arr:
            tiers[d["tier"]] += 1
            plats[d["plat"]] = plats.get(d["plat"], 0) + 1
        print(nm, len(arr), "tiers", tiers, plats, "kinds", {k: sum(1 for d in arr if d["kind"] == k) for k in set(d["kind"] for d in arr)})
    raw = {r["name"] for r in parse(CARDS)}
    same = [d["name"] for d in cards if d["name"] in raw and not any(x in d["name"] for x in ["Base Set", "Booster", "Jungle", "Fossil"])]
    print("UNCHANGED card names:", same)
    if "--names" in sys.argv:
        for d in cards + coins:
            print(d["id"], "|", d["name"], "|", d["kind"], d["tier"], d["base"], d.get("ctype", ""), d.get("subj", ""), d.get("obv", ""), d.get("rev", ""))


if __name__ == "__main__":
    main()
