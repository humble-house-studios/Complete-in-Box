#!/usr/bin/env python3
"""Curates Microsoft Fluent 3D emoji renders (MIT, github.com/microsoft/fluentui-emoji)
into assets/sprites/subject/ and writes scripts/gfx/subjects.gd.

They are glossy CG renders, like late-90s CGI box art, so a cover can show what
its title is about: DONKEY KONGO 64 gets a gorilla and bananas, a KART game a
racing car, a golf game a golfer. WORDS maps title words to subjects, GENRE gives
fallbacks per genre, PERKS gives each perk card its picture.
A subject entry can carry a tint: "Smiling face with smiling eyes#ff9ec8".
People come in three skin tones.

Usage: git clone --depth 1 --filter=blob:none --sparse https://github.com/microsoft/fluentui-emoji.git CLONE
       python3 tools/gen_subjects.py CLONE"""
import os, re, sys, subprocess, shutil
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/sprites/subject")
GD = os.path.join(ROOT, "scripts/gfx/subjects.gd")
SIZE = 128
TONES = ["Light", "Medium", "Dark"]

# Title words (lower case, as they appear in the parody names) -> subjects.
WORDS = {
    # franchise parodies
    "plumber": ["Man mechanic", "Mushroom", "Glowing star", "Brick", "Coin"],
    "bros": ["Man mechanic", "Mushroom", "Collision"],
    "donkey": ["Gorilla", "Banana"], "kongo": ["Gorilla", "Banana", "Wood"], "diddly": ["Monkey", "Banana", "Racing car"],
    "kirbo": ["Smiling face with smiling eyes#ffa6d0", "Glowing star", "Cloud"], "kirbo's": ["Smiling face with smiling eyes#ffa6d0", "Glowing star", "Cherries"],
    "zeldo": ["Person elf", "Shield", "Crossed swords", "Person fairy"], "link": ["Person elf", "Shield", "Crossed swords"],
    "link's": ["Person elf", "Shield", "Spiral shell"], "ocarina": ["Person elf", "Flute", "Person fairy"], "thyme": ["Person elf", "Hourglass not done"],
    "majora's": ["Performing arts", "Full moon face", "Person elf"], "masque": ["Performing arts", "Full moon face"],
    "castlevein": ["Person vampire", "Bat", "Castle", "Candle", "Skull"], "draculo": ["Person vampire", "Bat", "Coffin"],
    "metrood": ["Astronaut", "Alien", "Ringed planet", "Jellyfish"],
    "resident": ["Person zombie", "Biohazard", "Syringe"], "weevil": ["Person zombie", "Biohazard", "Drop of blood"],
    "final": ["Person mage", "Crystal ball", "Crossed swords", "Gem stone"], "fantasia": ["Person mage", "Crystal ball", "Chicken", "Dragon"],
    "phantasy": ["Person mage", "Ringed planet", "Dagger"], "chrono": ["Mantelpiece clock", "Person mage", "Crossed swords"],
    "robo": ["Robot", "High voltage", "Mechanical arm"], "megabot": ["Robot", "High voltage"],
    "sonik": ["Hedgehog#4f7cff", "Ring", "High voltage"], "tails": ["Fox", "Airplane", "Ring"],
    "vixen": ["Fox", "Airplane", "Rocket"], "starr": ["Fox", "Rocket", "Ringed planet"],
    "harvest": ["Farmer", "Cow", "Sheaf of rice", "Chicken"], "moo": ["Cow", "Farmer", "Glass of milk"],
    "earthworm": ["Worm", "Water pistol", "Cow"], "tim": ["Worm"],
    "duck": ["Duck"], "goose": ["Duck"], "battlefrogs": ["Frog", "Boxing glove"], "frog": ["Frog"],
    "spiro": ["Dragon#c07bff", "Gem stone", "Fire"], "bandicute": ["Raccoon", "Package", "Red apple"], "crash": ["Package", "Collision", "Raccoon"],
    "critters": ["Lizard", "Hamster#ffd23a", "Turtle", "Dragon face", "Bird", "Snail"], "pikapal": ["Hamster#ffd23a", "High voltage"],
    "yoshu's": ["Sauropod", "Egg", "Cherries"], "turuk": ["T-rex", "Bow and arrow", "Sauropod"], "dinosaur": ["T-rex", "Sauropod", "Volcano"],
    "banjo": ["Bear", "Bird", "Banjo", "Puzzle piece"], "twooie": ["Bear", "Bird"], "kazooie": ["Bear", "Bird"],
    "pikmen": ["Seedling", "Blossom", "Ant", "Rocket"], "chip": ["Chipmunk", "Acorn"], "dave": ["Chipmunk"], "chipmunk": ["Chipmunk"],
    "ninja": ["Ninja", "Dagger"], "shinobi": ["Ninja"], "goemon": ["Ninja", "Japanese castle", "Coin"],
    "conker's": ["Chipmunk", "Beer mug", "Collision"], "fur": ["Chipmunk"],
    "boomerman": ["Bomb", "Collision", "Fire"], "bomberman": ["Bomb"],
    "tetrominoes": ["Brick", "Puzzle piece"], "tetrisphure": ["Brick", "Globe with meridians"], "puzzle": ["Puzzle piece", "Gem stone"],
    "doom": ["Ogre", "Smiling face with horns", "Fire", "Skull"], "dooom": ["Ogre", "Smiling face with horns", "Fire", "Skull"],
    "quakeo": ["Ogre", "Skull", "Collision"], "hexeno": ["Person mage", "Skull", "Fire"], "duke": ["Military helmet", "Collision", "Sunglasses"],
    "gex": ["Lizard", "Television"], "chameleoon": ["Lizard", "Tongue"], "glovur": ["Gloves", "Magic wand", "Castle"],
    "roket": ["Robot", "Roller coaster"], "body": ["Alien monster", "Bug"], "buck": ["Honeybee"], "bumbleo": ["Honeybee", "Blossom"],
    "worms": ["Worm", "Bomb", "Collision"], "indianna": ["Cowboy hat face", "Compass", "Moai"], "bones": ["Skull", "Moai"],
    "toy": ["Teddy bear", "Rocket", "Kick scooter"], "supurman": ["Person superhero", "Cityscape"], "rampageo": ["Gorilla", "Cityscape", "Collision"],
    "gauntleto": ["Person mage", "Crossed swords", "Shield", "Old key"], "army": ["Military helmet", "Crossed flags"],
    "starr warz": ["Rocket"], "warz": ["Rocket", "Flying saucer", "Comet"], "rogue": ["Rocket", "Collision"],
    "pocky": ["Raccoon", "Japanese castle"], "rocko": ["Raccoon"], "lufio": ["Person mage", "Shield"], "personna": ["Performing arts", "Joker"],
    "suiko": ["Scroll", "Crossed swords", "Japanese castle"], "emblum": ["Shield", "Crossed swords", "Crown"],
    "worrier": ["Dragon", "Droplet#4fa3ff", "Shield"], "worriers": ["Dragon", "Droplet#4fa3ff", "Shield"],
    "ogre": ["Ogre", "Crossed swords"], "ogrr": ["Ogre", "Crossed swords"], "metal": ["Military helmet", "Package", "Satellite antenna"],
    "sneaky": ["Package", "Military helmet", "Eyes"], "slog": ["Military helmet", "Bomb"], "contro": ["Military helmet", "Collision", "Alien"],
    "rayguy": ["Person superhero", "Glowing star"], "pilotwangs": ["Small airplane", "Parachute", "Helicopter"],
    "excitebyke": ["Motorcycle", "Chequered flag"], "tmnk": ["Turtle", "Ninja", "Pizza"], "batsman": ["Bat", "Cityscape at dusk"],
    "flintstoners": ["Sauropod", "Rock", "Meat on bone"], "plok": ["Clown face", "Flea"], "felix": ["Black cat"],
    "darkwing": ["Duck", "Crescent moon"], "tailspin": ["Bear", "Airplane"], "nimo": ["Bed", "Crescent moon"],
    "gargoyle's": ["Smiling face with horns", "Castle"], "megumi": ["Person mage"], "shenmoo": ["Martial arts uniform", "Japanese castle"],
    "taxy": ["Taxi", "Cityscape"], "crazy": ["Taxi"], "pitfell": ["Palm tree", "Crocodile", "Snake"], "spiderman": ["Spider"],
    "silent": ["Fog", "Ghost", "Radio"], "hull": ["Fog", "Ghost"], "fatal": ["Camera with flash", "Ghost"], "frane": ["Camera with flash", "Ghost"],
    "dorkness": ["New moon face", "Skull"], "parasite": ["Microbe", "Dna"], "eva": ["Microbe", "Dna"],
    "tekkon": ["Boxing glove", "Martial arts uniform"], "punch": ["Boxing glove"], "outt": ["Boxing glove"],
    "kombot": ["Dragon face", "Skull", "Martial arts uniform"], "instinkt": ["Wolf", "Boxing glove"], "fightur": ["Boxing glove", "Brick"],
    "fighturs": ["Boxing glove", "Martial arts uniform"], "f.r.e.a.k.z.": ["Robot", "Mechanical arm"], "wwff": ["Person wrestling", "Trophy"],
    "kart": ["Racing car", "Chequered flag", "Banana"], "tourismo": ["Racing car", "Chequered flag"], "stunto": ["Racing car", "Collision"],
    "snowbooard": ["Snowboarder", "Snow-capped mountain"], "snowboarding": ["Snowboarder", "Snow-capped mountain"], "snow": ["Snowman", "Snowflake"],
    "racer": ["Racing car", "Chequered flag"], "racing": ["Racing car", "Chequered flag"], "rallie": ["Sport utility vehicle", "Chequered flag"],
    "cruiz'n": ["Automobile", "Palm tree"], "rash": ["Motorcycle"], "beetle": ["Beetle", "Automobile"], "wipeoout": ["Rocket", "Chequered flag"],
    "extreme": ["Motorcycle", "Rocket"], "rush": ["Racing car", "Cityscape"], "taxi": ["Taxi"],
    "hock's": ["Skateboard"], "skater": ["Skateboard"], "blitzo": ["American football"], "blitz": ["American football"],
    "slugfest": ["Baseball"], "golf": ["Person golfing", "Flag in hole"], "tennis": ["Tennis", "Person bouncing ball"],
    "soccer": ["Soccer ball", "Goal net"], "striker": ["Soccer ball", "Goal net"], "baseball": ["Baseball"], "stadium": ["Stadium", "Trophy"],
    "pinball": ["Pool 8 ball", "Slot machine"], "bass": ["Fish", "Fishing pole"], "fishing": ["Fishing pole", "Fish"],
    "marble": ["Crystal ball", "Pool 8 ball"], "cookie": ["Cookie"], "diner": ["Hamburger", "Hot dog"], "bakers": ["Pie", "Cupcake"],
    "choo": ["Locomotive"], "snap": ["Camera with flash", "Lizard"], "dance": ["Mirror ball", "Musical notes"], "party": ["Party popper", "Game die", "Balloon"],
    # more parody titles
    "kobra": ["Snake", "Speedboat"], "triangle": ["Speedboat"], "ikarus": ["Wing", "Bow and arrow"], "gradios": ["Rocket", "Moai"],
    "forz": ["Rocket", "Microbe"], "punch outt": ["Boxing glove", "Trophy"], "punch-outt": ["Boxing glove", "Trophy"], "kickle": ["Penguin", "Snowflake"],
    "rygarr": ["Shield", "Ogre"], "strydur": ["Ninja", "Dagger"], "shatterfist": ["Mechanical arm", "Boxing glove"],
    "section-zed": ["Rocket", "Satellite"], "abadocks": ["Alien monster", "Microbe"], "kabal": ["Military helmet", "Bomb"],
    "zanack": ["Rocket", "Comet"], "rekka": ["Rocket", "Fire"], "gun-nack": ["Rocket", "Coin"], "axelei": ["Rocket", "Ringed planet"],
    "einhandler": ["Mechanical arm", "Rocket"], "raydon": ["Rocket", "Collision"], "psyvariarr": ["Rocket", "Comet"],
    "mushihimesamo": ["Beetle", "Butterfly"], "giga": ["Airplane"], "wyng": ["Airplane", "Wing"], "radirgee": ["Rocket", "Sparkles"],
    "karouss": ["Rocket", "Shield"], "rezz": ["Atom symbol", "Musical notes"], "bangai-oh": ["Robot", "Rocket"], "ikaruka": ["Airplane", "Yin yang"],
    "sky": ["Airplane", "Cloud"], "raid": ["Airplane", "Bomb"], "vice": ["Detective", "Cityscape at dusk"], "gloom": ["Skull"],
    "demonhed": ["Smiling face with horns", "Fire"], "gaya": ["Globe showing europe-africa", "Moai"], "terranigmo": ["Globe showing asia-australia", "Seedling"],
    "razer": ["Smiling face with halo", "Bow and arrow", "Castle"], "turrikan": ["Robot", "High voltage"], "f-zilch": ["Racing car", "Rocket"],
    "fz": ["Racing car"], "plonk": ["Clown face"], "corpz": ["Building construction", "Collision"], "bash": ["Boxing glove", "Collision"],
    "request": ["Person mage", "Crystal ball"], "aidyn": ["Crossed swords", "Shield"], "chronicals": ["Scroll"], "shadowguy": ["Skull", "Bust in silhouette"],
    "oracle": ["Crystal ball", "Person elf"], "reasons": ["Mantelpiece clock"], "wages": ["Coin"], "warbio": ["Garlic", "Money bag", "Castle"],
    "warbioware": ["Garlic", "Video game", "Collision"], "microgamez": ["Video game"], "shanty": ["Woman genie", "Palm tree"],
    "vagrant": ["Crossed swords", "Dagger"], "storey": ["Scroll"], "alundro": ["Crossed swords", "Crescent moon"], "brigandeen": ["Crossed flags", "Shield"],
    "destinee": ["Crystal ball", "Crossed swords"], "mettle": ["Clown face", "Collision", "Police car"], "ape": ["Monkey", "Banana"],
    "escapade": ["Monkey"], "medievel": ["Skull", "Shield"], "parappa": ["Dog", "Microphone"], "napper": ["Microphone", "Musical notes"],
    "jammer": ["Guitar"], "clammy": ["Guitar", "Musical notes"], "klonoah": ["Rabbit", "Crescent moon"], "phantomile": ["Crescent moon"],
    "tombo": ["Pig", "Monkey"], "tobul": ["Martial arts uniform", "Robot"], "geer": ["Guitar", "Collision", "Crossed swords"],
    "skools": ["School", "Boxing glove"], "xenosago": ["Robot", "Ringed planet"], "xenogeers": ["Robot", "Mechanical arm"],
    "okamo": ["Wolf", "Cherry blossom"], "ika": ["Rocket", "Yin yang"], "roze": ["Rose", "Teddy bear"], "haunting": ["Ghost", "Dog"],
    "grounds": ["Castle"], "disaster": ["Collision", "Cityscape"], "reporter": ["Rolled-up newspaper", "Camera"],
    "killer8": ["Skull", "Water pistol"], "killer7": ["Skull"], "symphonica": ["Musical score", "Crossed swords"], "batten": ["Wing", "Flower playing cards"],
    "kaitos": ["Wing", "Flower playing cards"], "chibi-robbo": ["Robot", "Electric plug"], "crossing": ["House with garden", "Raccoon"],
    "pebble": ["Rock", "Boxing glove"], "spyke": ["Water pistol", "Robot"], "daytuna": ["Racing car", "Chequered flag"], "seaguy": ["Fish", "Fishing pole"],
    "grandio": ["Compass", "Sailboat"], "illbled": ["Drop of blood", "Circus tent"], "ecco": ["Dolphin", "Water wave"], "porpoise": ["Dolphin"],
    "justis": ["Boxing glove", "School"], "alivish": ["Martial arts uniform"], "smosh": ["Tennis", "Rocket"], "matrics": ["Ringed planet", "Rocket"],
    "mars": ["Ringed planet"], "kaos": ["Collision", "Rocket"], "farce": ["Crossed swords", "Shield"], "landstalkur": ["Old key", "Gem stone"],
    "oasys": ["Desert", "Cactus"], "ranger-y": ["Robot", "Motorcycle"], "vektorman": ["Robot", "Collision"], "heady": ["Clown face", "Performing arts"],
    "rally": ["Sport utility vehicle", "Chequered flag"], "combot": ["Military helmet", "Bomb"], "samsin": ["Bell", "Bear"], "earthbond": ["Baseball", "Globe showing americas"],
    "goldenspy": ["Detective", "Water pistol"], "00heaven": ["Detective", "Satellite"], "kablooie": ["Bear", "Bird"], "kumbat": ["Dragon face", "Skull"],
    "streets": ["Cityscape at dusk", "Boxing glove"], "wrath": ["Boxing glove"], "zapman": ["High voltage", "Robot"], "extra-terrible": ["Alien", "Telephone"],
    "pak-muncher": ["Cherries", "Ghost"], "stunt": ["Racing car", "Collision"], "blast": ["Bomb", "Collision"], "valkyrie": ["Wing", "Shield"],
    "profiel": ["Wing", "Crossed swords"], "defeet": ["Helicopter", "Bomb"], "border": ["Rocket"], "downe": ["Rocket", "Collision"],
    "faxanudu": ["Shield", "Old key"], "kid": ["Wing"], "super k": ["Robot"],
}

# Generic title words: used after the specific ones above, so STAR VIXEN shows
# the fox first and the star second.
WEAK = {
    "dragon": ["Dragon", "Dragon face", "Fire"], "dragun": ["Dragon", "Dragon face"], "dragoon": ["Dragon", "Crossed swords"], "wyrm": ["Dragon"],
    "ghost": ["Ghost"], "fright": ["Ghost", "Jack-o-lantern"], "zombies": ["Person zombie", "House"], "zombie": ["Person zombie"],
    "vampire": ["Person vampire", "Bat"], "demon's": ["Smiling face with horns", "Fire"], "devil": ["Smiling face with horns"], "evil": ["Smiling face with horns", "Skull"],
    "fire": ["Fire"], "fyre": ["Fire"], "flame": ["Fire"], "blaze": ["Fire"], "ice": ["Ice", "Snowflake"], "frost": ["Snowflake"],
    "sword": ["Crossed swords"], "blayde": ["Dagger", "Crossed swords"], "sabre": ["Dagger"], "soul": ["Crossed swords", "Ghost"],
    "knight": ["Shield", "Crossed swords"], "guardian": ["Shield"], "legend": ["Shield", "Scroll", "Compass"], "legends": ["Shield", "Scroll"],
    "quest": ["Compass", "World map", "Old key"], "questt": ["Compass", "Old key"], "journey": ["Compass", "World map"],
    "adventure": ["Compass", "World map"], "adventura": ["Compass", "World map", "Desert island"], "adventures": ["Compass", "World map"],
    "space": ["Rocket", "Ringed planet", "Flying saucer", "Astronaut"], "star": ["Glowing star", "Rocket"], "galaxy": ["Milky way", "Rocket"],
    "alien": ["Alien", "Flying saucer"], "planet": ["Ringed planet"], "station": ["Satellite", "Ringed planet"], "jet": ["Airplane", "Rocket"],
    "aero": ["Bat", "Airplane"], "acro": ["Bat"], "skies": ["Airplane", "Cloud"], "wangs": ["Small airplane"],
    "king": ["Crown"], "kingdom": ["Crown", "Castle", "Old key"], "harts": ["Red heart", "Old key", "Crown"], "queen": ["Crown", "Princess"],
    "prince": ["Prince", "Crown"], "princess": ["Princess", "Crown"], "castle": ["Castle"], "fortress": ["Castle"],
    "monkey": ["Monkey"], "cat": ["Cat"], "dog": ["Dog"], "kat": ["Cat"], "rat": ["Rat", "Cheese wedge"], "bear": ["Bear"], "fox": ["Fox"],
    "squirrel": ["Chipmunk"], "kamikaze": ["Chipmunk"], "bunny": ["Rabbit"], "o'bunny": ["Rabbit"], "turtle": ["Turtle"], "shark": ["Shark"],
    "whale": ["Whale"], "octopus": ["Octopus"], "spider": ["Spider", "Spider web"], "bee": ["Honeybee"], "bug": ["Bug"], "fish": ["Fish"],
    "wolf": ["Wolf"], "lion": ["Lion"], "tiger": ["Tiger"], "horse": ["Horse"], "pig": ["Pig"], "cow": ["Cow"], "chicken": ["Chicken"],
    "music": ["Musical notes", "Guitar"], "rock": ["Guitar", "Rock"], "guitar": ["Guitar"], "band": ["Drum", "Guitar"], "dj": ["Headphone"],
    "pirate": ["Pirate flag", "Sailboat"], "ship": ["Ship"], "sea": ["Water wave"], "island": ["Desert island", "Palm tree"],
    "wave": ["Water wave"], "river": ["Canoe"], "city": ["Cityscape", "Cityscape at dusk"], "street": ["Cityscape at dusk", "Boxing glove"],
    "world": ["Globe showing americas"], "earth": ["Globe showing americas"], "moon": ["Crescent moon"], "sun": ["Sun with face"], "sunguy": ["Sun with face"],
    "dream": ["Crescent moon", "Sparkles", "Cloud"], "dreams": ["Crescent moon", "Sparkles"], "night": ["Night with stars"], "dark": ["New moon face", "Bat"],
    "darkness": ["New moon face", "Skull"], "shadow": ["Bust in silhouette"], "shadowz": ["Bust in silhouette"], "black": ["Black heart"],
    "gold": ["Trophy", "Coin", "Crown"], "golden": ["Trophy", "Coin"], "ruby": ["Gem stone#ff3b5c"], "sapphire": ["Gem stone#3b7bff"],
    "emerald": ["Gem stone#2fd17a"], "crystal": ["Gem stone", "Crystal ball"], "crystallus": ["Gem stone"], "silver": ["Gem stone#d0d4e0"],
    "red": ["Red apple"], "blue": ["Blue heart"], "yellow": ["Yellow heart"], "green": ["Green heart"],
    "magic": ["Magic wand", "Person mage"], "mystic": ["Crystal ball", "Person mage"], "mystikal": ["Crystal ball", "Ninja"],
    "wizards": ["Person mage", "Magic wand"], "manna": ["Person mage", "Seedling"], "secret": ["Old key", "Locked"],
    "time": ["Hourglass not done", "Mantelpiece clock"], "clock": ["Mantelpiece clock"], "tower": ["Tokyo tower"],
    "war": ["Military helmet", "Bomb"], "wars": ["Military helmet", "Bomb", "Crossed flags"], "battle": ["Crossed swords", "Shield"],
    "battel": ["Crossed swords", "Shield"], "command": ["Military helmet", "Crossed flags"], "commandeer": ["Mechanical arm", "Military helmet"],
    "bionic": ["Mechanical arm"], "gun": ["Water pistol"], "gunz": ["Water pistol"], "blaster": ["Water pistol", "Collision"],
    "trigger": ["Bullseye"], "hunter": ["Bow and arrow"], "seeds": ["Seedling"], "ancient": ["Amphora", "Moai"], "mummy": ["Funeral urn"],
    "valley": ["Mountain"], "peak": ["Snow-capped mountain"], "mountain": ["Mountain"], "volcano": ["Volcano"], "desert": ["Desert", "Cactus"],
    "jungle": ["Palm tree", "Gorilla"], "wild": ["Cactus", "Cowboy hat face"], "west": ["Cowboy hat face", "Cactus"], "gunfarce": ["Military helmet"],
    "atom": ["Atom symbol"], "quantum": ["Atom symbol"], "digital": ["Desktop computer", "Robot"], "netwerk": ["Desktop computer", "Satellite antenna"],
    "online": ["Globe with meridians", "Desktop computer"], "cyber": ["Robot", "Desktop computer"], "cyberneater": ["Robot", "Mechanical arm"],
    "silicone": ["Robot", "Desktop computer"], "heart": ["Red heart"], "haven": ["Smiling face with halo"], "heaven": ["Smiling face with halo"],
    "hybrid": ["Robot", "Dna"], "trading": ["Flower playing cards"], "card": ["Flower playing cards", "Joker"], "cards": ["Joker"],
    "circus": ["Circus tent", "Clown face"], "clown": ["Clown face"], "carnival": ["Ferris wheel"], "egg": ["Egg"], "pizza": ["Pizza"],
    "chef": ["Cook"], "cook": ["Cook"], "kitchen": ["Cook"], "restaurant": ["Cook", "Hamburger"], "panic": ["Exploding head"],
    "bubble": ["Bubbles"], "bauble": ["Bubbles", "Dragon face"], "mischief": ["Smirking face"], "lost": ["Compass", "Desert island"],
    "revenge": ["Angry face with horns"], "return": ["Boomerang"], "rescue": ["Firefighter", "Ambulance"], "fireman": ["Firefighter"],
    "police": ["Police officer", "Police car"], "cop": ["Police officer", "Police car light"], "detective": ["Detective", "Magnifying glass tilted left"],
    "spy": ["Detective", "Sunglasses"], "agent": ["Detective", "Sunglasses"], "007": ["Detective", "Water pistol"], "goldeneye": ["Detective", "Satellite"],
    "perfect": ["Woman detective", "Alien"], "surf": ["Person surfing"], "skate": ["Skateboard"], "bike": ["Bicycle"], "bmx": ["Bicycle"],
    "hockey": ["Ice hockey"], "boxing": ["Boxing glove"], "wrestling": ["Person wrestling"], "bowling": ["Bowling"], "basketball": ["Basketball"],
    "football": ["American football"], "volleyball": ["Volleyball"], "ski": ["Skier"], "olympic": ["Sports medal"], "champion": ["Trophy"],
    "championships": ["Trophy", "Sports medal"], "challenge": ["Trophy"], "powerfeast": ["Trophy", "Video game"], "campus": ["Graduation cap", "Trophy"],
}

# Fallback subjects per genre (titles with no matching word).
GENRE = {
    "Platformer": ["Hedgehog", "Fox", "Raccoon", "Frog", "Monkey", "Mushroom", "Glowing star", "Coin", "Cherries", "Bear", "Rabbit", "Penguin", "Chipmunk"],
    "Action": ["Ninja", "Person superhero", "Person supervillain", "Collision", "Bomb", "Military helmet", "Fire", "Robot", "Dagger"],
    "Adventure": ["Compass", "World map", "Old key", "Person elf", "Shield", "Castle", "Scroll", "Desert island", "Cowboy hat face"],
    "RPG": ["Person mage", "Dragon", "Crossed swords", "Crystal ball", "Shield", "Crown", "Gem stone", "Person elf", "Ogre", "Magic wand", "Person fairy"],
    "Strategy": ["Chess pawn", "Crossed flags", "Castle", "Shield", "Crown", "Military helmet", "World map"],
    "Shooter": ["Rocket", "Flying saucer", "Alien monster", "Ringed planet", "Comet", "Satellite", "Alien", "Astronaut"],
    "Racing": ["Racing car", "Motorcycle", "Chequered flag", "Trophy", "Automobile", "Sport utility vehicle"],
    "Fighting": ["Boxing glove", "Martial arts uniform", "Person superhero", "Person supervillain", "Collision", "Person wrestling", "Ninja"],
    "Puzzle": ["Puzzle piece", "Brick", "Gem stone", "Bubbles", "Game die", "Candy", "Glowing star", "Pool 8 ball"],
    "Sports": ["Soccer ball", "Basketball", "Baseball", "American football", "Tennis", "Ice hockey", "Trophy", "Person golfing"],
    "Horror": ["Ghost", "Skull", "Person zombie", "Person vampire", "Jack-o-lantern", "Coffin", "Spider web", "Bat", "Headstone"],
    "Music": ["Guitar", "Microphone", "Headphone", "Musical notes", "Drum", "Saxophone", "Mirror ball", "Singer"],
    "Life Sim": ["House with garden", "Cat", "Dog", "Potted plant", "Farmer", "Cow", "Seedling", "Teddy bear", "Hamster"],
}

# Perk and upgrade pictures: [main, extras...].
PERKS = {
    "price_guide": ["Open book", "Heavy dollar sign", "Magnifying glass tilted right"],
    "silver_tongue": ["Money-mouth face", "Speech balloon", "Handshake"],
    "early_bird": ["Baby chick", "Sunrise", "Alarm clock"],
    "extra_hour": ["Alarm clock", "Hourglass not done"],
    "box_and_manual": ["Package", "Open book", "Video game"],
    "shrink_wrap": ["Wrapped gift", "Sparkles"],
    "hoarder": ["Card file box", "Package", "Books"],
    "moms_basement": ["Couch and lamp", "Door", "Joystick"],
    "power_seller": ["Megaphone", "Money with wings", "Chart increasing"],
    "sticker_gun": ["Label", "Heavy dollar sign"],
    "funtendo_kid": ["Video game", "Joystick", "Mushroom"],
    "saga_does": ["Joystick", "High voltage", "Hedgehog#4f7cff"],
    "disc_jockey": ["Optical disk", "Headphone", "Dvd"],
    "completionist": ["Check mark button", "Trophy", "Sports medal"],
    "piggy_bank": ["Pig face", "Coin", "Money bag"],
    "lucky_lots": ["Four leaf clover", "Game die", "Wrapped gift"],
    "flipper": ["Dolphin", "Coin", "Chart increasing"],
    "hype_beast": ["Fire", "Megaphone", "Running shoe"],
    "time_capsule": ["Hourglass not done", "Amphora", "Mantelpiece clock"],
    "grader_buddy": ["Hundred points", "Magnifying glass tilted right", "Sports medal"],
    "bubble_wrap": ["Bubbles", "Package"],
    "nostalgia": ["Videocassette", "Goggles", "Television"],
    "curator": ["Framed picture", "Classical building", "Bellhop bell"],
    "coupon": ["Scissors", "Ticket", "Receipt"],
    "eagle_eye": ["Eagle", "Eye", "Magnifying glass tilted left"],
    "whale": ["Spouting whale", "Gem stone", "Money bag"],
    "lunchbox": ["Bento box", "Sandwich"],
    "console_wars": ["Crossed swords", "Joystick", "Video game"],
    "up_shelf": ["Books", "Hammer and wrench"],
    "up_time": ["Watch", "Alarm clock"],
    "up_perk_slot": ["Backpack", "Sparkles"],
    "up_interest": ["Bank", "Chart increasing", "Coin"],
    "up_reroll": ["Ticket", "Game die", "Counterclockwise arrows button"],
}

PEOPLE = {"Woman genie", "Man mechanic", "Person elf", "Person fairy", "Person vampire", "Person zombie", "Person mage", "Farmer", "Ninja",
          "Person superhero", "Person supervillain", "Person golfing", "Person bouncing ball", "Snowboarder", "Person wrestling",
          "Prince", "Princess", "Police officer", "Detective", "Woman detective", "Person surfing", "Skier", "Firefighter",
          "Cook", "Singer", "Astronaut", "Speaking head", "Cowboy hat face", "Woman mage", "Man mage", "Woman elf", "Man vampire"}
NO_TONE = {"Speaking head", "Cowboy hat face", "Skier", "Snowboarder"}


def key(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def main():
    clone = sys.argv[1]
    names = set()
    for lst in list(WORDS.values()) + list(WEAK.values()) + list(GENRE.values()) + list(PERKS.values()):
        for e in lst:
            names.add(e.split("#")[0])
    files = subprocess.run(["git", "-C", clone, "ls-files"], capture_output=True, text=True).stdout.splitlines()
    have = {}
    for f in files:
        m = re.match(r"assets/([^/]+)/(?:([^/]+)/)?3D/[^/]+_3d(?:_[a-z-]+)?\.png$", f)
        if m:
            have.setdefault(m.group(1), {})[m.group(2) or ""] = f
    want = {}
    missing = []
    for n in sorted(names):
        if n not in have:
            missing.append(n)
            continue
        var = have[n]
        if "" in var:
            want[n] = [var[""]]
        elif n in PEOPLE and n not in NO_TONE:
            want[n] = [var[t] for t in TONES if t in var] or [var.get("Default")]
        else:
            want[n] = [var.get("Default") or list(var.values())[0]]
    if missing:
        print("MISSING", missing)
    paths = sorted({p for ps in want.values() for p in ps})
    subprocess.run(["git", "-C", clone, "sparse-checkout", "set", "--no-cone"] + ["/" + p for p in paths], check=True)
    if os.path.isdir(OUT):
        for f in os.listdir(OUT):
            if f.endswith(".png"):
                os.remove(os.path.join(OUT, f))
    os.makedirs(OUT, exist_ok=True)
    sprites = {}
    for n, ps in sorted(want.items()):
        k = key(n)
        out = []
        for i, p in enumerate(ps):
            im = Image.open(os.path.join(clone, p)).convert("RGBA")
            bb = im.getchannel("A").point(lambda a: 255 if a > 10 else 0).getbbox()
            if bb:
                im = im.crop(bb)
            im.thumbnail((SIZE, SIZE), Image.LANCZOS)
            fn = "%s%s.png" % (k, "" if len(ps) == 1 else "_%d" % i)
            im.save(os.path.join(OUT, fn), optimize=True)
            imp = os.path.join(OUT, fn + ".import")
            if not os.path.exists(imp):
                # Lossy WebP in the build: ~4x smaller, invisible at cover size.
                open(imp, "w").write('[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\n\n'
                                     '[params]\n\ncompress/mode=1\ncompress/lossy_quality=0.85\n')
            out.append("res://assets/sprites/subject/" + fn)
        sprites[k] = out

    def ref(e):
        n, _, tint = e.partition("#")
        return key(n) + ("#" + tint if tint else "") if n in want else None

    def table(d):
        lines = []
        for k2, lst in d.items():
            refs = [r for r in (ref(e) for e in lst) if r]
            if refs:
                lines.append('\t"%s": [%s],' % (k2, ", ".join('"%s"' % r for r in refs)))
        return "\n".join(lines)

    with open(GD, "w") as f:
        f.write("extends RefCounted\n")
        f.write("## GENERATED by tools/gen_subjects.py (edit the generator, not this file).\n")
        f.write("## Glossy 3D renders (Microsoft Fluent emoji, MIT) that covers and perk cards\n")
        f.write("## use to show what a title is about. A ref can end in #rrggbb (a tint).\n")
        f.write("## No class_name (the TV app's self-update can't add global classes):\n")
        f.write("## load it with preload(\"res://scripts/gfx/subjects.gd\").\n\n")
        f.write("const SPRITES := {\n")
        for k2, ps in sprites.items():
            f.write('\t"%s": [%s],\n' % (k2, ", ".join('"%s"' % p for p in ps)))
        f.write("}\n\n## Title words -> subjects.\nconst WORDS := {\n" + table(WORDS) + "\n}\n\n")
        f.write("## Generic title words (used after WORDS).\nconst WEAK := {\n" + table(WEAK) + "\n}\n\n")
        f.write("## Fallback subjects per genre.\nconst GENRE := {\n" + table(GENRE) + "\n}\n\n")
        f.write("## Perk / upgrade (up_<id>) pictures: main first.\nconst PERKS := {\n" + table(PERKS) + "\n}\n")
    print("subjects", len(sprites), "files", sum(len(v) for v in sprites.values()))


if __name__ == "__main__":
    main()
