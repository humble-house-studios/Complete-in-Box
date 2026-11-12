class_name Flavor
extends RefCounted
## Little bits of writing that make the world feel lived in: condition notes on
## item cards, seller quotes at each venue, venue mood lines, and what the
## appraiser mutters. Picks are deterministic (seeded by an id) so a card's line
## doesn't change every time the screen redraws.

const COND := {
	"Damaged": ["Label's half peeled off.", "Someone chewed this.", "Rattles when you shake it.", "Sun-bleached and scuffed.", "Sticker residue everywhere."],
	"Loose": ["Just the cart. Blow in it.", "No box, no manual, no problem.", "Name written on the back in marker.", "Works if you hold it just right.", "Loose but clean."],
	"CIB": ["Box, manual, the little poster too.", "Complete in box. Corners a bit soft.", "Manual still smells like 1993.", "All the inserts. Even the warranty card.", "CIB. The collector's comfort food."],
	"Mint": ["Barely touched. Crisp corners.", "Looks like it never left the shelf.", "Mint. Don't breathe on it.", "Could pass for new under store lights."],
	"Sealed": ["Factory sealed. Seams intact.", "Still in the shrink wrap.", "Sealed. The price sticker's from 1997.", "Never opened. Never will be."],
}

const TIER := [
	"",
	"Collectors nod at this one.",
	"Hard to find. People ask about it.",
	"A grail. People lie awake about these.",
]

const SELLER := {
	"garage": ["\"My kid played it once. Maybe twice.\"", "\"Make me an offer, I just want the garage back.\"", "\"Everything on this table's a buck. Mostly.\"", "\"Found that in the attic. No idea what it is.\""],
	"flea": ["\"I know what it's worth, friend.\"", "\"Cash only. No returns. No refunds.\"", "\"That one? That's a rare one. Probably.\"", "\"Came in a lot from a storage unit.\""],
	"estate": ["\"Grandpa kept everything. Everything.\"", "\"We're pricing it to move. Please take it.\"", "\"Those were in the den. Untouched for years.\""],
	"storage": ["\"Bidding starts now. No peeking past the tape.\"", "\"Sold as-is. Could be gold, could be laundry.\""],
	"retro": ["\"Tested and working. Ninety-day warranty.\"", "\"Want me to grade that for you?\"", "\"Prices are firm. Ish.\""],
	"pawn": ["\"I'll give you forty. Take it or leave it.\"", "\"Everything in here's got a story.\"", "\"Don't ask where it came from.\""],
	"convention": ["\"Graded copies to your left, grails behind glass.\"", "\"Show special, today only.\"", "\"You won't see another one this weekend.\""],
	"ebay": ["\"Ships fast! Smoke-free home!\"", "\"Listed as VERY RARE L@@K.\"", "\"No lowballs, I know what I have.\""],
	"heritage": ["\"Lot four-fifty-one. Do I hear more?\"", "\"Authenticated, catalogued, insured.\"", "\"The room is quiet. The phones are not.\""],
}

const MOOD := {
	"garage": "Folding tables and a cooler of lemonade.",
	"flea": "Parasols, haggling, and the smell of kettle corn.",
	"estate": "A whole life, priced with masking tape.",
	"storage": "Roll the door. Pray.",
	"retro": "Glass cases and a CRT humming in the corner.",
	"pawn": "Bars on the windows, deals on the counter.",
	"convention": "Banners, cosplay and very serious collectors.",
	"ebay": "3 a.m., one tab open, finger on the bid button.",
	"heritage": "White gloves. Big money. Bigger egos.",
}

const PASS := [
	"The appraiser raises an eyebrow. \"Not bad at all.\"",
	"\"Now THAT's a shelf.\" The appraiser signs off.",
	"A nod, a stamp, a check. You're still in business.",
	"\"Respectable. Very respectable.\"",
]

const FAIL := [
	"The appraiser shakes their head. \"Not enough.\"",
	"\"I've seen better shelves at a yard sale.\"",
	"The stamp comes down. It says NO.",
]

const LOT := ["Taped shut. Heavy. Smells like a basement.", "Something rattles inside.", "Marked GAMES?? in marker.", "The tape says FRAGILE. Twice."]


static func pick(list: Array, key: Variant) -> String:
	if list.is_empty():
		return ""
	return String(list[absi(hash(key)) % list.size()])


static func cond_line(item: Dictionary) -> String:
	return pick(COND.get(String(item.get("cond", "Loose")), COND["Loose"]), str(item.get("uid", item.get("id", ""))) + String(item.get("cond", "")))


static func tier_line(item: Dictionary) -> String:
	return String(TIER[clampi(int(item.get("tier", 0)), 0, 3)])


static func seller(venue_id: String, key: Variant) -> String:
	return pick(SELLER.get(venue_id, []), key)


static func mood(venue_id: String) -> String:
	return String(MOOD.get(venue_id, ""))


# --- item history (inspect card) -------------------------------------------
# Built from many small parts, seeded by the item id (facts that never change)
# and by the copy (its own past), so two cards almost never read alike. All
# numbers stay inside believable ranges for the year, platform and print run.

const MONTHS := ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
const DISC_PLATS := ["PST", "PST2", "PSPK", "DC", "SAT", "FCUBE", "XBX", "DUO"]
const JP_FAMS := ["funtendo", "saga", "snc", "statia"]

const FIRST := ["Kenji", "Aiko", "Hiro", "Yuki", "Masa", "Rie", "Taro", "Emi", "Shin", "Nao", "Dave", "Lisa", "Mark", "Tina", "Greg", "Rob", "Jen", "Phil", "Karen", "Steve", "Marta", "Pete", "Dana", "Luis", "Ines", "Oli", "Sam", "Toby", "Wendy", "Raj", "Bea", "Carl", "Nina", "Ivan", "Hana", "Joel"]
const LAST := ["Tanaka", "Mori", "Sato", "Kobayashi", "Ishida", "Nakamura", "Ono", "Fujita", "Hayashi", "Kimura", "Miller", "Kowalski", "Brennan", "Okafor", "Lindqvist", "Garza", "Doyle", "Fischer", "Novak", "Price", "Ward", "Ruiz", "Hart", "Ellis", "Moreau", "Baker", "Quinn", "Sasaki"]
const CODE_B := ["Blue", "Iron", "Paper", "Night", "Echo", "Lantern", "Pebble", "Comet", "Velvet", "Static", "Orchid", "Granite", "Tin", "Neon", "Ember", "Frost", "Atlas", "Marble", "Signal", "Hollow"]
const CODE_C := ["Fox", "Sky", "Garden", "Engine", "Owl", "Tower", "River", "Moon", "Kite", "Saw", "Drum", "Bell", "Harbor", "Crane", "Spark", "Rook", "Canyon", "Lamp"]
const JP_CITIES := ["Kyoto", "Osaka", "Tokyo", "Sapporo", "Fukuoka", "Nagoya", "Kobe", "Yokohama"]
const STUDIO_CITIES := ["Redmond", "Austin", "Seattle", "Sheffield", "Leamington", "Dundee", "Montreal", "Vancouver", "San Mateo", "Irvine", "Chicago", "Lyon", "Stockholm", "Liverpool", "Hamburg"]

const ERA_LINE := {
	1970: ["Came out when arcades still smelled like cigarette smoke and quarters.", "Back when 'graphics' meant a square and a dream.", "Sold through department-store catalogues and electronics counters.", "Most families had never seen a video game at home yet."],
	1980: ["Born in the boom years, when every kid begged for one at the mall.", "Sold in toy aisles right next to the action figures.", "Arrived after the big crash, when stores were scared of games.", "Shipped while kids still traded tips on the school bus.", "Magazines printed its maps over three issues.", "Arrived when a cartridge was a birthday-sized present."],
	1990: ["Arrived in the console wars, when ads yelled about 'bits' at you.", "Launched with a TV ad that had way too much attitude.", "Rode the 90s wave of mail-in posters and magazine demos.", "Came out in the year of the tip hotline, at a dollar a minute.", "Rented every Friday night at video stores all over.", "Its demo kiosk was the most crowded spot in the toy store."],
	2000: ["Released as discs took over and cartridges started looking old.", "Came out in the era of memory cards and midnight launches.", "Sat on shelves while everyone talked about going online.", "Its trailer was passed around on burned demo discs.", "Forum threads argued about it for a decade."],
	2010: ["A late arrival, made for the people who never stopped playing.", "Released when retro was already cool again."],
}
const LIFE := ["early in the {p}'s life, when the library was still thin", "right in the {p}'s best years", "late in the {p}'s life, as everyone eyed the next thing", "in the {p}'s final year, almost nobody noticed it"]

const DEV_LINE := {
	"RPG": ["The script ran so long the translators worked in shifts.", "Cut a whole second continent to fit the cart.", "A designer hid their cat's name in the save menu.", "The final boss was rewritten three weeks before ship.", "The battle music was written in one night.", "The world map started as a doodle on a bar napkin.", "Testers lost track of time and missed their trains home.", "A secret ending needs a 40-hour item nobody found for years."],
	"Shooter": ["Testers wore out four controllers on the last level alone.", "Bullet patterns were tuned on a broken TV.", "The ship sprite started life as a drawing on a napkin.", "The slowdown on stage 4 was kept because it felt dramatic.", "The final stage was finished the night before mastering."],
	"Adventure": ["The map was drawn by hand on graph paper taped together.", "Shipped with a secret room nobody found for six years.", "The manual hid a fake treasure map inside.", "One puzzle was so hard the hint line got a full-time worker.", "Half the dungeon was cut and turned up in the sequel."],
	"Platformer": ["The jump was tweaked over 200 times until it felt 'bouncy'.", "The mascot was nearly a sandwich instead.", "Level 1 was built last, once they knew how to teach the game.", "A warp zone was left in from a debug build.", "The run speed was copied from a designer's dog."],
	"Action": ["Fight scenes were blocked out with action figures on a desk.", "The export cut the blood. Kids noticed anyway.", "The hero's voice is the sound guy shouting into a mug.", "A camera bug became the famous 'spin dodge'."],
	"Horror": ["The fog wasn't style. The hardware couldn't draw any further.", "Testers refused to play it alone after dark.", "The creepy sounds were recorded in a real basement.", "The door-opening loads were hiding the loading screens.", "The monster voices are a slowed-down cat."],
	"Fighting": ["Combos the designers never planned became the whole meta.", "Balanced by watching arcade crowds argue.", "One fighter was added because a tester begged.", "The secret character took a code nobody leaked for months."],
	"Racing": ["The cars were built from photos taken in a parking garage.", "A designer drove the real track to time the laps.", "The soundtrack sold almost as well as the game.", "Rubber-band AI was added after testers won every race."],
	"Sports": ["The rosters were out of date by the time it hit shelves.", "An intern was motion-captured for every single player.", "Office tournaments on it got... heated.", "The commentator recorded 3,000 lines in two days."],
	"Strategy": ["The AI cheats on hard. The devs admitted it later.", "Playtests took whole weekends.", "The manual was thicker than the box.", "A tester's battle plan became the tutorial."],
	"Puzzle": ["Banned from the office because nobody did any work.", "The music has stuck in heads for decades.", "Designed in a weekend, polished for a year.", "The first prototype ran on a calculator."],
	"Life Sim": ["Players kept finding things the devs never put in on purpose.", "Got fan mail from grandmas.", "The in-game calendar matched the real one by accident."],
	"Music": ["The plastic peripheral cost more to make than the game.", "Songs were licensed from a garage band nobody had heard of.", "Rhythm timing was checked against a metronome taped to the TV."],
	"Hardware": ["Engineers fought over the shell colour for months.", "The first batch shipped with a fault they fixed quietly.", "The startup chime was recorded on the lead engineer's keyboard.", "Store demo units had their buttons worn smooth by kids.", "The case was redesigned to stop kids jamming toast in it.", "Its cooling fan was swapped after a summer of complaints.", "The power brick weighs more than some games."],
}
const QUIRK := {
	"game": ["Some copies have a typo on the spine.", "Later prints fixed a save bug, so early ones are wanted.", "There's an unused level still in the code.", "The cover art was repainted for the export.", "A cheat code spells the lead's initials.", "The ending credits list a dog as 'morale officer'.", "One sound test track never plays in the game.", "The box art shows a scene that isn't in the game.", "The manual has a contest you can't enter any more.", "Retailers got a different shrink-wrap seal."],
	"console": ["Early units have a different sticker under the base.", "One revision runs quieter and is wanted for it.", "Has a hidden menu if you hold two buttons at power-on.", "The serial number tells you which factory built it.", "Its expansion port was barely ever used.", "Later models dropped a port to save money."],
	"acc": ["The cable length changed twice in production.", "Knockoffs outsold the real one three to one.", "Early ones have a slightly different logo.", "The pack-in instructions had a printing error."],
	"misc": ["Most copies got thrown out with the box.", "Shops gave them away free with a purchase."],
}
## Reception by review band (low, mid, high).
const RECEPTION := [
	["It flopped at launch, then grew a cult", "A famous review panned it, unfairly", "Magazines barely covered it", "Critics shrugged; kids didn't"],
	["Reviews were mixed", "Players found it on their own", "Word of mouth carried it", "It topped the rental charts", "It sold slowly but never stopped"],
	["Critics loved it", "It sold out its first shipment", "It won a pile of magazine awards", "It was the must-have gift that winter", "Shops ran out within a week"],
]
const TEAM_T := [
	"A team of {team} in {city}, led by {lead}, took {months} months. ",
	"{lead} led {team} people in {city} for {months} months. ",
	"Made in {city} over {months} months by {team} people under {lead}. ",
	"Built by {team} people in {city}. {lead} ran the project for {months} months. ",
]
const CODE_T := ["Inside it was called \"{code}\". ", "Its working title was \"{code}\". ", "Codename: \"{code}\". ", "The early builds were labelled \"{code}\". ", ""]
const ORIGIN_T := [
	"{month} {year}, first in {first_in} - {life}. {era}",
	"Out first in {first_in}, {month} {year}, {life}. {era}",
	"{era} Released {month} {year} in {first_in}, {life}.",
]

const PAST_PLACE := ["a church rummage sale", "a storage unit auction", "a closed-down rental store", "an attic box marked XMAS", "a flooded basement", "a bedroom closet", "a house move", "a flea market blanket", "a pawn shop back room", "a thrift store bin", "a school fundraiser", "an estate sale", "a dusty arcade office", "a car boot sale", "a toy drive leftover pile", "a garage sale 'everything $1' box", "a dorm room clean-out", "a radio station prize closet", "a warehouse returns pallet", "a grandparent's TV cabinet"]
const PAST_WHO := ["a kid named Kevin (name on the label in marker)", "a dad who kept it 'for the kids'", "a speedrunner with a ridiculous save file", "a collector who died with 3,000 games", "a rental store that wrote its code on the back", "two brothers who fought over it", "a game tester who kept a copy", "a teenager who sold it for gas money", "a shopkeeper who never put it out", "a family that moved overseas", "a tournament winner", "a babysitter who forgot to take it home", "a magazine writer's review pile", "someone who wrote their high score inside the manual"]
const PAST_MARK := ["Faint price sticker from a shop long gone.", "Smells faintly of a smoker's living room.", "A tiny tear on the corner of the box.", "Initials scratched into the back.", "A coffee ring on the manual.", "Still has the receipt folded inside.", "The original warranty card was never sent.", "A pencilled price inside the flap.", "Light sun fade on one side only.", "A sticker from a long-gone rental chain.", "No marks at all. Suspiciously clean.", "Somebody's school photo was tucked inside.", "A handwritten cheat list in the case.", "The plastic still squeaks."]

const TIP_LINE := {
	"game": ["Check the label for sun fade before you pay.", "Matching codes on box and manual add value.", "Blow in it? Collectors say no. Everyone did anyway.", "Look for the factory seal seam, not a reseal.", "The manual is often worth a third of the price.", "Hold the label to the light: reprints are glossier."],
	"console": ["Look at the vents: dust tells you how much it was played.", "Original box + inserts can double the price.", "Yellowed plastic is common. Even colour is not.", "Check the serial under the base matches the box.", "Test every port. Sellers never do."],
	"acc": ["Loose cables are easy to find. Boxed ones aren't.", "Third-party versions are worth far less. Check the logo.", "Check the plug pins: bent ones are the usual fail."],
	"misc": ["Paper stuff rarely survives. Clean copies are a treat."],
}


static func _r(key: Variant) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	return rng


static func _one(rng: RandomNumberGenerator, list: Array) -> String:
	return String(list[rng.randi_range(0, list.size() - 1)])


static func _person(rng: RandomNumberGenerator) -> String:
	return "%s %s" % [_one(rng, FIRST), _one(rng, LAST)]


static func _usd(x: float) -> String:
	return "$%d.99" % maxi(4, int(round(x)) - 1)


static func _num(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


static func _year_of(def: Dictionary, rng: RandomNumberGenerator) -> int:
	var y := int(def.get("year", 0))
	if y > 0:
		return y
	var era: Array = Catalog.ERA.get(String(def.get("plat", "MISC")), [1988, 2000])
	return rng.randi_range(int(era[0]), int(era[1]))


## Fixed facts about the item (same every time for this id).
static func facts(def: Dictionary) -> Dictionary:
	var id := String(def.get("id", ""))
	var rng := _r(id + "facts")
	var kind := String(def.get("kind", "game"))
	var plat := String(def.get("plat", "MISC"))
	var fam := String(Catalog.platform(plat).get("family", "misc"))
	var year := _year_of(def, rng)
	var tier := int(def.get("tier", 0))
	var f := {"year": year, "month": _one(rng, MONTHS)}
	f["first_in"] = "Japan" if JP_FAMS.has(fam) and rng.randf() < 0.7 else ("North America" if rng.randf() < 0.75 else "Europe")
	var era: Array = Catalog.ERA.get(plat, [year - 4, year + 4])
	var t := clampf(float(year - int(era[0])) / maxf(1.0, float(int(era[1]) - int(era[0]))), 0.0, 1.0)
	f["life"] = String(LIFE[clampi(int(t * 3.999), 0, 3)]).format({"p": String(Catalog.platform(plat).get("short", plat))})
	# Team size and dev time grow with the years.
	var grow := clampf((year - 1977) / 30.0, 0.0, 1.0)
	if kind == "game":
		f["team"] = rng.randi_range(2 + int(grow * 10), 6 + int(pow(grow, 2.2) * 110))
		f["months"] = rng.randi_range(5 + int(grow * 6), 14 + int(grow * 22))
		var cart := not DISC_PLATS.has(plat)
		var base := (rng.randf_range(39.0, 70.0) if cart and year < 2001 else rng.randf_range(29.0, 50.0))
		if plat in ["PBOY", "PBA", "PSPK", "DUO"]:
			base *= 0.75
		f["price"] = _usd(base)
		f["score"] = clampi(int(round(rng.randf_range(58.0, 88.0) + tier * 2.5 + (8.0 if int(def.get("rank", 999)) < 120 else 0.0))), 41, 98)
	else:
		f["team"] = rng.randi_range(12 + int(grow * 40), 60 + int(grow * 400))
		f["months"] = rng.randi_range(14, 48)
		var lo := 79.0 + grow * 100.0
		var hh := 0.45 if plat in ["PBOY", "PBA", "PSPK", "DUO"] else 1.0
		f["price"] = _usd(rng.randf_range(lo, lo * 2.4) * hh) if kind == "console" else _usd(rng.randf_range(12.0, 60.0))
		f["score"] = 0
	f["lead"] = _person(rng)
	if f["first_in"] == "Japan":
		f["lead"] = "%s %s" % [String(FIRST[rng.randi_range(0, 9)]), String(LAST[rng.randi_range(0, 9)])]
	f["city"] = _one(rng, JP_CITIES) if f["first_in"] == "Japan" or (JP_FAMS.has(fam) and kind != "game") else _one(rng, STUDIO_CITIES)
	f["code"] = "%s %s" % [_one(rng, CODE_B), _one(rng, CODE_C)]
	f["team_t"] = _one(rng, TEAM_T)
	f["code_t"] = _one(rng, CODE_T)
	f["origin_t"] = _one(rng, ORIGIN_T)
	var printed := int(def.get("run", 0))
	if printed <= 0:
		printed = int([1500000, 250000, 40000, 3000][clampi(tier, 0, 3)] * rng.randf_range(0.5, 1.6))
	f["printed"] = printed
	# Older stuff survives worse; consoles get kept, boxes get binned.
	var keep := clampf(0.04 + grow * 0.14, 0.03, 0.2) * rng.randf_range(0.6, 1.4)
	f["cib_left"] = maxi(1, int(printed * keep * (0.7 if kind == "game" else 1.0)))
	f["sealed_left"] = maxi(0, int(printed * keep * rng.randf_range(0.004, 0.03)))
	var sc := int(f["score"])
	f["reception"] = _one(rng, RECEPTION[0 if sc < 68 else (1 if sc < 84 else 2)])
	f["quirk"] = _one(rng, QUIRK.get(kind, QUIRK["game"]))
	f["dev"] = _one(rng, DEV_LINE.get(String(def.get("genre", "Hardware" if kind != "game" else "Action")), DEV_LINE["Action"]))
	f["era"] = _one(rng, ERA_LINE[clampi(int(year / 10) * 10, 1970, 2010)])
	f["tip"] = _one(rng, TIP_LINE.get(kind, TIP_LINE["game"]))
	return f


## This copy's own past (seeded by the copy, so every copy differs).
static func provenance(def: Dictionary, item: Dictionary, f: Dictionary) -> String:
	var key := "%s|%s|%s|%s" % [def.get("id", ""), item.get("uid", 0), item.get("serial", 0), item.get("variant", "")]
	var rng := _r(key)
	var y0 := int(f["year"])
	var found := rng.randi_range(mini(y0 + 2, 2024), 2025)
	var owners := rng.randi_range(1, 2 + clampi(int((2025 - y0) / 8), 0, 4))
	var line := "Found in %s, %d. Owned by %s" % [_one(rng, PAST_PLACE), found, _one(rng, PAST_WHO)]
	line += " - one of %d owner%s. " % [owners, "" if owners == 1 else "s"] if owners > 1 else ". "
	return line + _one(rng, PAST_MARK)


# --- title-tied lore, recurring developers, by-the-numbers ------------------

const STOP := ["the", "and", "of", "for", "with", "edition", "version", "game", "cartridge", "cart", "disc", "set", "pack", "bros", "deluxe"]
const SWAP := ["Quest", "Saga", "Zone", "Fury", "Dreams", "Tactics", "Unleashed", "Turbo", "Legends", "Panic", "Heroes", "Chronicles", "Blast", "Mania", "Odyssey", "Rumble", "Kingdom", "Overdrive", "Party", "Hustle", "Galaxy", "Rampage", "Express", "Dynasty"]
const JP_SUFFIX := ["Densetsu", "Monogatari", "Daisakusen", "-kun", "Paradise", "GP", "Spirits", "Gaiden", "Revolution", "DX", "Wars", "Club"]
const NICK_END := ["-y", "o", "ster", " Bros", "-tron", "zilla", "-man", " Jr."]
const ROLES := ["director", "designer", "lead programmer", "composer", "artist", "producer"]
const STUDIO_A := ["Pixel", "Bright", "Moon", "Turbo", "Sugar", "Comet", "Lucky", "Crunch", "Velvet", "Hyper", "Tiny", "Iron"]
const STUDIO_B := ["Soft", "Works", "Factory", "House", "Lab", "Arts", "Bit", "Studio"]

const TITLE_T := [
	"The title was almost \"{alt}\" until a focus group laughed out loud.",
	"\"{key}\" was a placeholder word. Nobody remembered to change it.",
	"Marketing wanted to call it \"{alt}\". The {role} threatened to quit.",
	"The \"{short}\" logo was redrawn {logo_n} times. Version {logo_pick} won by one vote.",
	"In Japan it was sold as \"{jp}\".",
	"The {letters}-letter name had to be squashed to fit the label.",
	"A trademark fight over the word \"{key}\" delayed it {delay} weeks.",
	"Early print ads spelled it \"{typo}\". {typo_n} thousand flyers went in the bin.",
	"Kids on the playground called it \"{nick}\".",
	"The European box called it \"{eu}\" for reasons nobody can explain.",
	"\"{key}\" was picked from a hat. The other slips said \"{swap1}\" and \"{swap2}\".",
	"The {role} named it after a {key_lower}-shaped stain on the office ceiling.",
	"Test audiences thought \"{short}\" was a breakfast cereal.",
	"A radio ad read the title {radio_n} times in 30 seconds.",
	"The working logo used a font stolen from a pizza menu. It stayed.",
	"Its title screen took longer to make than the first {lvl_n} levels.",
	"The name \"{short}\" was registered on a Friday, the cover painted over the weekend.",
	"Somebody suggested \"{short} {swap1}\". They now work in insurance.",
]
const SUB_T := [
	"The subtitle \"{sub}\" was added a week before the box went to print.",
	"\"{sub}\" was the {role}'s idea. Nobody asked what it meant.",
	"Fans just call it \"{short}\" and pretend \"{sub}\" isn't there.",
]
const SEQ_T := [
	"Number {seq} in the series, made in half the time of the last one.",
	"Sequel {seq}: the team slept under their desks for {months} months.",
	"Part {seq}. The {role} swore it would be the last. It wasn't.",
]

## Theme lines picked by words in the title.
const THEMES := {
	"plumb": ["The plumber has a moustache because the hardware couldn't draw a mouth.", "A real plumber was hired as a consultant. He mostly ate the snacks."],
	"robo": ["The robot's arm cannon started as a paint roller.", "A toaster in the break room was the model for the {key} boss."],
	"mega": ["\"Mega\" was added to the name to sound like it had more memory than it did."],
	"drag": ["The dragon's roar is a garbage truck reversing, slowed down.", "The dragon was cut down to fit the screen. Fans say it's 'cute now'."],
	"fanta": ["\"Final\" was in the name because the studio thought it would go bust. It didn't.", "Every save point was placed by the {role} counting steps on graph paper."],
	"zeld": ["The hero never speaks, because the text box was out of memory.", "The first dungeon is shaped like the {role}'s initials."],
	"crit": ["Over {crit_n} critters were designed; {crit_cut} were cut for being 'too soggy'.", "One critter is just a pile of sand with eyes. It's a fan favourite."],
	"pock": ["It was built to fit in a jeans pocket. Cargo shorts were consulted."],
	"vein": ["The castle music was written on a church organ at 3 a.m.", "Holy water was nearly a 'cup of tea' in early builds."],
	"sonik": ["The hero's speed was tuned until a tester felt slightly sick."],
	"race": ["The fastest car's stats were copied from the {role}'s own hatchback, times ten."],
	"kart": ["Banana peels were added after the {role} slipped on one in the car park."],
	"star": ["The star field is 64 dots. Fans have named every single one."],
	"space": ["Space was black because black is free. Budget art direction."],
	"ninja": ["The ninjas wear black because colour palettes were expensive."],
	"fight": ["A tester found a combo that does {combo}% damage. It was left in as a 'reward'."],
	"street": ["The street signs in the background are real shops near the studio."],
	"castle": ["The castle has {rooms} rooms. Speedrunners visit {rooms_speed}."],
	"dungeon": ["The dungeon map was pinned to a wall and darts decided the traps."],
	"world": ["The world map was printed and used as the office tablecloth."],
	"super": ["The \"Super\" in the title was legally required to sound important."],
	"monkey": ["The monkey animator spent a week at a zoo. The zoo sent a bill."],
	"kong": ["The giant ape's barrels were modelled on the studio's actual beer kegs."],
	"ghost": ["The ghost voice is the {role} humming in a stairwell."],
	"dead": ["The zombies walk slowly because the animator got bored at frame six."],
	"resident": ["The 'mansion' was the {role}'s aunt's house, roughly."],
	"silent": ["The fog was a trick to hide the draw distance, then became the whole mood."],
	"metal": ["The cardboard box stealth trick was found by a tester hiding from his boss."],
	"golf": ["The {role} has never played golf. You can tell on hole 9."],
	"soccer": ["Every player has the same face. Twelve fans noticed."],
	"wrest": ["The wrestlers' voices are all one guy with a cold."],
	"puzzle": ["The puzzles were tested on the {role}'s grandma. She beat all of them."],
	"block": ["The falling blocks were timed to the office clock's tick."],
	"party": ["Board rules were tested at a real birthday party. Two friendships ended."],
	"quest": ["The quest log was nearly a physical notebook in the box."],
	"legend": ["The legend in the title was made up during the ad campaign."],
	"war": ["The war map was played out with breakfast cereal first."],
	"tank": ["The tank treads sound is someone rubbing two cardboard tubes."],
	"jet": ["The jet sound is a hair dryer held close to the mic."],
	"kirb": ["The pink hero was white in early art. A marker ran out."],
	"bomb": ["The explosions are the {role} popping paper bags."],
	"duck": ["The dog that laughs at you was the {role}'s revenge on a tester."],
	"tetro": ["The falling shapes were named after the team's kids."],
	"cast": ["Half the cast were named after staff pets."],
	"adventure": ["The adventure took {beat}h to beat in testing and {beat2}h at retail."],
	"chrono": ["The time travel plot was rewritten every time someone went on holiday."],
	"pinball": ["The ball physics came from rolling a marble down a desk."],
	"console": ["The hardware team named the prototype after a sandwich shop."],
	"controller": ["The grips were shaped by squeezing modelling clay for an hour."],
}

const RUMORS := [
	"Beat {short} twice without saving to unlock {alt}.",
	"There's a secret {key_lower} level if you hold Select for {n} seconds.",
	"Blow on the cart {n} times and the {key_lower} turns gold.",
	"{lead} hid their phone number in the {short} credits.",
	"Typing {cheat} on the {short} title screen gives you {n} lives.",
	"A cousin's friend's dad worked on {short} and said {other} is hidden inside.",
	"If you lose on purpose {n} times, the {key_lower} apologises.",
	"Pause the last boss of {short} for {n} minutes and the music turns into {other}.",
	"{key} is secretly the villain's cousin. Page {page} of the manual 'proves' it.",
	"Leave {short} running overnight and a {key_lower} appears on the map.",
	"{co} put a curse on {n} copies of {short}. Yours might be one.",
	"Name your file {nick} and everything is upside down.",
]
const CHEAT_BITS := ["UP", "UP", "DOWN", "DOWN", "LEFT", "RIGHT", "B", "A", "SELECT", "START", "L", "R", "X", "Y"]

const LINK_T := [
	"{lead} ({lead_role}) also made {other}.",
	"{lead} came straight off {other} and reused half its code.",
	"{lead}'s next project was {other}. You can see the family resemblance.",
	"{lead} pitched this on a napkin at the {other} wrap party.",
	"Same {lead_role} as {other}: {lead}.",
	"{lead} snuck a {other} cameo into a background poster.",
]
const LINK2_T := [
	"{co} ({co_role}) later worked on {other2}.",
	"The music is by {co}, who also scored {other2}.",
	"{co} drew the box art for this and {other2} in the same month.",
	"{co} (also on {other2}) wrote the manual in one night.",
	"{co} left to work on {other2}. The goodbye cake was {key_lower}-shaped.",
]
const POACH_T := [
	"{lead} was poached from {pub2}, where they made {other}.",
	"{lead} quit {pub2} after {other} and started over here.",
]


## Extra title-tied lines, used to make any repeated line unique again.
const EXTRA_T := [
	"The {key_lower} sprite is {px} pixels tall.",
	"On {short}, that took {days} days to get right.",
	"The {short} team had {mugs} mugs and one kettle.",
	"{lead} still has the {key_lower} sketch framed at home.",
	"Copies of {short} sold in {month} outsold the rest of the year.",
	"Even the {short} manual mentions it, on page {page}.",
	"Fans of {short} made a {wiki}-page wiki about it.",
	"It got a {score2}/10 from a kid's zine called {zine}.",
	"The {short} launch party served {snack}.",
	"{co} says it was {lead}'s fault. {lead} says otherwise.",
	"The {key_lower} theme was hummed into an answering machine first.",
	"Tested on a {tv}-inch TV in a broom cupboard.",
	"Shipped in crates labelled \"{alt}\" to fool leakers.",
	"{short} was the {rank_say} title {pub} shipped that year.",
	"A {short} poster hung in {posters} rental stores.",
]
const ZINES := ["Rad Pixels", "Joypad Juniors", "Cart Club", "Button Mash Monthly", "The Cheat Sheet", "Couch Co-op", "Lunchbox Gamer", "Bit Bulletin"]
const SNACKS := ["warm cola and cold pizza", "cake shaped like the cart", "a single fruit platter", "120 hot dogs", "crisps in a hard hat", "a chocolate fountain that broke"]

static var _claims: Dictionary = {}
static var _fcache: Dictionary = {}
static var _by_pub: Dictionary = {}


## A fresh run: lines get handed out again, so nothing repeats within a run.
static func reset_claims() -> void:
	_claims.clear()
	_fcache.clear()


## Makes text unique this run: if another item already said it, keep adding
## title-tied extras until nobody has.
static func _uniq(text: String, owner: String, slot: String, rng: RandomNumberGenerator, f: Dictionary) -> String:
	var out := text
	for k in 6:
		var key := slot + out
		if not _claims.has(key) or _claims[key] == owner:
			_claims[key] = owner
			return out
		out = text + " " + String(EXTRA_T[rng.randi_range(0, EXTRA_T.size() - 1)]).format(f)
	return out


## Picks from list, preferring a line no other item has used this run.
static func _claim(rng: RandomNumberGenerator, list: Array, id: String, slot: String) -> String:
	var n := list.size()
	if n == 0:
		return ""
	var start := rng.randi_range(0, n - 1)
	for k in n:
		var line := String(list[(start + k) % n])
		var key := slot + line
		if not _claims.has(key) or _claims[key] == id:
			_claims[key] = id
			return line
	return String(list[start])


static func _pub_of(def: Dictionary) -> String:
	var pb := String(def.get("pub", ""))
	if pb != "":
		return pb
	if String(def.get("kind", "game")) != "game":
		return String(Catalog.MAKERS.get(String(Catalog.platform(String(def.get("plat", "MISC"))).get("family", "misc")), "Various"))
	var rng := _r(String(def.get("plat", "")) + String(def.get("genre", "")) + "studio")
	return "%s %s" % [_one(rng, STUDIO_A), _one(rng, STUDIO_B)]


static func _pub_items(pb: String) -> Array:
	if _by_pub.is_empty():
		for d in Catalog.ITEMS:
			var k := _pub_of(d)
			if not _by_pub.has(k):
				_by_pub[k] = []
			(_by_pub[k] as Array).append(d)
	return _by_pub.get(pb, [])


## Each publisher has a fixed staff, so names recur across its games.
static func _staff(pb: String, jp: bool) -> Array:
	var rng := _r(pb + "staff")
	var out: Array = []
	for i in 6:
		var fi := rng.randi_range(0, 9) if jp else rng.randi_range(10, FIRST.size() - 1)
		var la := rng.randi_range(0, 9) if jp else rng.randi_range(10, LAST.size() - 1)
		out.append({"name": "%s %s" % [FIRST[fi], LAST[la]], "role": ROLES[i % ROLES.size()]})
	return out


static func _other_title(rng: RandomNumberGenerator, list: Array, self_id: String) -> String:
	var pool := list.filter(func(d): return String(d["id"]) != self_id)
	if pool.is_empty():
		return ""
	return String(pool[rng.randi_range(0, pool.size() - 1)]["name"])


static func _title_bits(name: String, rng: RandomNumberGenerator) -> Dictionary:
	var short := name.split(":")[0].strip_edges()
	var sub := name.substr(short.length() + 1).strip_edges() if name.contains(":") else ""
	var words: Array = []
	var seq := ""
	for w in short.replace("'", "").replace(".", "").split(" ", false):
		var lw := w.to_lower()
		if lw in ["ii", "iii", "iv", "v", "vi", "vii", "2", "3", "4", "5", "6"]:
			seq = w
		elif w.length() >= 3 and not STOP.has(lw) and not w.is_valid_int():
			words.append(w)
	var key := short
	for w in words:
		if String(w).length() > key.length() or key == short:
			key = w
	var swap := _one(rng, SWAP)
	var alt := short.replace(key, swap) if key != short else short + " " + swap
	var typo := key
	if key.length() > 3:
		var i := rng.randi_range(1, key.length() - 2)
		typo = key.substr(0, i) + key[i + 1] + key[i] + key.substr(i + 2)
	return {"short": short, "sub": sub, "key": key, "key_lower": key.to_lower(), "alt": alt,
		"jp": "%s %s" % [key, _one(rng, JP_SUFFIX)], "eu": "%s %s" % [short, ["EX", "Plus", "Turbo", "'%02d" % rng.randi_range(90, 99), "Gold"][rng.randi_range(0, 4)]],
		"nick": key.substr(0, mini(4, key.length())) + _one(rng, NICK_END), "typo": typo,
		"swap1": _one(rng, SWAP), "swap2": _one(rng, SWAP), "letters": short.replace(" ", "").length(), "seq": seq}


## Everything the card says about the item, fixed per id within a run.
static func lore(def: Dictionary) -> Dictionary:
	var id := String(def.get("id", ""))
	if _fcache.has(id):
		return _fcache[id]
	var f := facts(def)
	var rng := _r(id + "lore")
	var kind := String(def.get("kind", "game"))
	f.merge(_title_bits(String(def.get("name", "")), rng))
	var pb := _pub_of(def)
	f["pub"] = pb
	var staff := _staff(pb, f["first_in"] == "Japan")
	var li := rng.randi_range(0, staff.size() - 1)
	var ci := (li + rng.randi_range(1, staff.size() - 1)) % staff.size()
	f["lead"] = staff[li]["name"]
	f["lead_role"] = staff[li]["role"]
	f["co"] = staff[ci]["name"]
	f["co_role"] = staff[ci]["role"]
	f["role"] = _one(rng, ROLES)
	var same := _pub_items(pb)
	f["other"] = _other_title(rng, same, id)
	f["other2"] = _other_title(rng, same, id)
	var fam_pool := Catalog.ITEMS.filter(func(d): return String(d.get("genre", "")) == String(def.get("genre", "")) and _pub_of(d) != pb)
	if fam_pool.is_empty():
		fam_pool = Catalog.ITEMS
	var far: Dictionary = fam_pool[rng.randi_range(0, fam_pool.size() - 1)]
	f["far"] = String(far["name"])
	f["pub2"] = _pub_of(far)
	# Numbers the templates use.
	f["logo_n"] = rng.randi_range(4, 61)
	f["logo_pick"] = rng.randi_range(2, int(f["logo_n"]))
	f["delay"] = rng.randi_range(2, 19)
	f["typo_n"] = rng.randi_range(3, 140)
	f["radio_n"] = rng.randi_range(6, 23)
	f["lvl_n"] = rng.randi_range(2, 9)
	f["crit_n"] = rng.randi_range(160, 400)
	f["crit_cut"] = rng.randi_range(11, 90)
	f["combo"] = rng.randi_range(101, 340)
	f["rooms"] = rng.randi_range(40, 260)
	f["rooms_speed"] = rng.randi_range(6, 19)
	f["beat"] = rng.randi_range(9, 70)
	f["beat2"] = int(f["beat"]) + rng.randi_range(3, 40)
	f["px"] = rng.randi_range(8, 64)
	f["days"] = rng.randi_range(2, 90)
	f["mugs"] = rng.randi_range(3, 40)
	f["page"] = rng.randi_range(2, 40)
	f["wiki"] = rng.randi_range(12, 4000)
	f["score2"] = rng.randi_range(3, 11)
	f["zine"] = _one(rng, ZINES)
	f["snack"] = _one(rng, SNACKS)
	f["tv"] = rng.randi_range(9, 32)
	f["posters"] = _num(rng.randi_range(40, 9000))
	f["rank_say"] = _one(rng, ["biggest", "weirdest", "loudest", "last", "first", "cheapest", "most-delayed"])
	var ch: Array = []
	for i in rng.randi_range(5, 8):
		ch.append(_one(rng, CHEAT_BITS))
	f["cheat"] = " ".join(ch)
	# Title-tied story.
	var tl: Array = []
	tl.append(_claim(rng, TITLE_T, id, "title").format(f))
	if String(f["sub"]) != "":
		tl.append(_claim(rng, SUB_T, id, "sub").format(f))
	if String(f["seq"]) != "":
		tl.append(_claim(rng, SEQ_T, id, "seq").format(f))
	var lname := String(def.get("name", "")).to_lower()
	var themed: Array = []
	for k in THEMES:
		if lname.contains(k):
			themed.append_array(THEMES[k])
	if not themed.is_empty():
		tl.append(_claim(rng, themed, id, "theme").format(f))
	f["title_story"] = " ".join(tl)
	# Who made it, and what else they made.
	var links: Array = []
	if String(f["other"]) != "":
		links.append(_claim(rng, LINK_T, id, "link").format(f))
	else:
		f["other"] = f["far"]
		links.append(_claim(rng, POACH_T, id, "poach").format(f))
	if String(f["other2"]) != "" and f["other2"] != f["other"]:
		links.append(_claim(rng, LINK2_T, id, "link2").format(f))
	f["links"] = " ".join(links)
	f["dev"] = _claim(rng, DEV_LINE.get(String(def.get("genre", "Hardware" if kind != "game" else "Action")), DEV_LINE["Action"]), id, "dev")
	f["quirk"] = _claim(rng, QUIRK.get(kind, QUIRK["game"]), id, "quirk")
	f["numbers"] = _numbers(def, f, rng)
	_fcache[id] = f
	return f


## Funny stats with believable ranges. Returns [[label, value], ...].
## Funny stats with believable ranges. Returns [[label, value], ...]; each
## value is re-rolled if another item already showed it this run.
static func _numbers(def: Dictionary, f: Dictionary, rng: RandomNumberGenerator) -> Array:
	var id := String(def.get("id", ""))
	var kind := String(def.get("kind", "game"))
	var genre := String(def.get("genre", "Action"))
	var plat := String(def.get("plat", ""))
	var cart := not DISC_PLATS.has(plat)
	var year := int(f["year"])
	var key := String(f["key"]).to_upper()
	var price := float(String(f["price"]).substr(1))
	var all: Array = []
	all.append(["IN TODAY'S MONEY", func(r: RandomNumberGenerator): return "$%d (%s)" % [int(price * (1.0 + maxf(0.0, 2025 - year) * 0.034) + r.randi_range(-3, 3)), _one(r, ["that's a lot of paper rounds", "or %d chocolate bars" % r.randi_range(40, 400), "two birthdays, minimum", "a month of chores", "%d weeks of pocket money" % r.randi_range(5, 60)])]])
	if kind == "game":
		var beat: Array = {"RPG": [28, 90], "Strategy": [20, 60], "Adventure": [10, 40], "Puzzle": [4, 999], "Sports": [6, 300], "Racing": [5, 25], "Fighting": [1, 4], "Shooter": [1, 8], "Platformer": [4, 18], "Horror": [6, 16]}.get(genre, [6, 20])
		var h := rng.randi_range(int(beat[0]), int(beat[1]))
		all.append(["HOURS TO BEAT", func(r: RandomNumberGenerator): return ("never (it doesn't end; record session %d h %02d m)" % [r.randi_range(20, 300), r.randi_range(0, 59)] if h > 400 else "%d h %02d m, or %d h if you read the signs" % [h, r.randi_range(0, 59), h + r.randi_range(1, 12)])])
		all.append(["SPEEDRUN RECORD", func(r: RandomNumberGenerator):
			var wr := maxi(1, int(h * 60 * r.randf_range(0.04, 0.3)))
			return "%d:%02d.%d by xX_%s%d_Xx" % [wr / 60, wr % 60, r.randi_range(0, 9), key.substr(0, 6), r.randi_range(1, 99)]])
		if cart and year < 2001:
			all.append(["BLOWS TO BOOT", func(r: RandomNumberGenerator): return "%.2f on average (it never helped)" % r.randf_range(1.2, 6.8)])
		all.append(["RAGE QUITS", func(r: RandomNumberGenerator): return "%d per player, mostly on level %d-%d" % [r.randi_range(2, 60), r.randi_range(1, 9), r.randi_range(1, 4)]])
		all.append(["SECRETS", func(r: RandomNumberGenerator): return "%d found, %d still hidden (probably)" % [r.randi_range(3, 80), r.randi_range(1, 9)]])
		all.append(["CONTROLLERS BROKEN", func(r: RandomNumberGenerator): return "~%d per 1,000 copies (%d thrown, %d sat on)" % [r.randi_range(20, 140), r.randi_range(5, 19), r.randi_range(1, 9)]])
		all.append(["MUM APPROVAL", func(r: RandomNumberGenerator): return "%d%% (\"%s\")" % [r.randi_range(4, 96), _one(r, ["is it violent?", "keep it down", "one more hour", "that's educational", "go outside", "who's %s?" % String(f["key"]), "dinner's ready", "not on a school night", "is that the %s one again?" % String(f["key"])])]])
		all.append(["RENTAL LATE FEES", func(r: RandomNumberGenerator): return "$%s paid nationwide" % _num(r.randi_range(9000, 2400000))])
		all.append(["FRIENDSHIPS ENDED", func(r: RandomNumberGenerator): return "%s (couch co-op incidents)" % _num(r.randi_range(12, 90000))])
		all.append(["BUGS SHIPPED", func(r: RandomNumberGenerator): return "%d, %s" % [r.randi_range(3, 240), _one(r, ["one of them now a feature", "speedrunners love %d of them" % r.randi_range(2, 9), "none fatal (allegedly)", "the %s one is famous" % String(f["key_lower"])])]])
		all.append(["MANUAL", func(r: RandomNumberGenerator): return "%d pages, %d of them warnings, %d about %s" % [r.randi_range(12, 64), r.randi_range(1, 6), r.randi_range(1, 9), String(f["key"])]])
		all.append(["TIMES \"%s\" APPEARS" % key, func(r: RandomNumberGenerator): return "%s in text, %d out loud" % [_num(r.randi_range(14, 3100)), r.randi_range(0, 40)]])
		all.append(["%s PLUSHIES SOLD" % key, func(r: RandomNumberGenerator): return "%s (%s)" % [_num(r.randi_range(400, 90000)), _one(r, ["the plush was better than the game", "%d recalled for being too soft" % r.randi_range(10, 900), "one is in a museum", "they squeak"])]])
		all.append(["SOUNDTRACK", func(r: RandomNumberGenerator): return "%d tracks, %d stuck in your head since %d" % [r.randi_range(8, 70), r.randi_range(1, 3), year + r.randi_range(0, 3)]])
		all.append(["CHEAT CODE", func(r: RandomNumberGenerator):
			var ch: Array = []
			for i in r.randi_range(5, 9):
				ch.append(_one(r, CHEAT_BITS))
			return " ".join(ch)])
		all.append(["BOX VS GAME", func(r: RandomNumberGenerator): return "%d heroes on the box, %d in the game, %d explosions on the box, %d in the game" % [r.randi_range(2, 7), r.randi_range(1, 2), r.randi_range(2, 12), r.randi_range(0, 3)]])
		all.append(["HINT LINE CALLS", func(r: RandomNumberGenerator): return "%s at $1.99 a minute" % _num(r.randi_range(2000, 600000))])
		all.append(["WEIGHT", func(r: RandomNumberGenerator): return "%.1f g%s" % [r.randf_range(58, 95) if cart else r.randf_range(88, 130), " (feels heavier)" if cart else " with the manual"]])
		all.append(["PLAYGROUND RUMOR", func(r: RandomNumberGenerator):
			var g := f.duplicate()
			g["n"] = r.randi_range(3, 120)
			return "\"" + _one(r, RUMORS).format(g) + "\""])
		all.append(["SAVE FILES DELETED", func(r: RandomNumberGenerator): return "%s by little siblings" % _num(r.randi_range(300, 400000))])
		all.append(["SICK DAYS FAKED", func(r: RandomNumberGenerator): return "%s the week %s came out" % [_num(r.randi_range(500, 200000)), String(f["short"])]])
	else:
		var hw := kind == "console"
		all.append(["WEIGHT", func(r: RandomNumberGenerator): return "%.2f kg" % (r.randf_range(0.9, 3.6) if hw else r.randf_range(0.08, 0.5))])
		all.append(["BOOT TIME", func(r: RandomNumberGenerator): return "%.1f s (plus %d s staring at the logo)" % [r.randf_range(0.4, 9.0), r.randi_range(2, 8)]])
		all.append(["POWER DRAW", func(r: RandomNumberGenerator): return "%d W, %d W in summer (vibes)" % [r.randi_range(6, 160), r.randi_range(10, 200)]])
		all.append(["FAN NOISE", func(r: RandomNumberGenerator): return "%d dB (\"%s\")" % [r.randi_range(18, 54), _one(r, ["a polite hairdryer", "a cat purring", "a distant lawnmower", "basically silent", "a tiny jet"])]])
		all.append(["WARRANTY CLAIMS", func(r: RandomNumberGenerator): return "%.1f%% (mostly %s)" % [r.randf_range(0.4, 9.0), _one(r, ["dropped down stairs", "juice spills", "the dog", "'it just stopped'", "kicked during a boss fight"])]])
		all.append(["TOAST INSERTED", func(r: RandomNumberGenerator): return "%d reported cases, %d with jam" % [r.randi_range(3, 900), r.randi_range(0, 60)]])
		all.append(["CABLE LENGTH", func(r: RandomNumberGenerator): return "%.2f m (always 30 cm too short)" % r.randf_range(1.0, 3.2)])
		all.append(["UNITS IN ATTICS", func(r: RandomNumberGenerator): return "~%s" % _num(int(int(f["printed"]) * r.randf_range(0.05, 0.3)))])
		all.append(["CHRISTMAS MORNINGS", func(r: RandomNumberGenerator): return "%s made, %s ruined (no batteries)" % [_num(r.randi_range(5000, 900000)), _num(r.randi_range(40, 9000))]])
		all.append(["SCREWS", func(r: RandomNumberGenerator): return "%d, %d of them a weird shape on purpose" % [r.randi_range(6, 34), r.randi_range(2, 8)]])
		all.append(["DEMO KIOSKS", func(r: RandomNumberGenerator): return "%s, %d still bolted down somewhere" % [_num(r.randi_range(400, 30000)), r.randi_range(1, 60)]])
		all.append(["YELLOWING", func(r: RandomNumberGenerator): return "%.1f%% of units (%s)" % [r.randf_range(4, 80), _one(r, ["sun is undefeated", "the grey ones went beige", "window-sill units first", "smokers' homes worst", "the %s logo stays white, weirdly" % String(f["key"])])]])
		all.append(["%s NICKNAMES" % key, func(r: RandomNumberGenerator): return "%d, the rudest is \"%s\"" % [r.randi_range(3, 40), String(f["nick"])]])
	var idx: Array = range(all.size())
	for i in idx.size():
		var j := rng.randi_range(i, idx.size() - 1)
		var t: int = idx[i]
		idx[i] = idx[j]
		idx[j] = t
	var out: Array = []
	for i in mini(7, idx.size()):
		var e: Array = all[idx[i]]
		var gen: Callable = e[1]
		var val := String(gen.call(rng))
		for tries in 8:
			var ck := "num" + String(e[0]) + val
			if not _claims.has(ck) or _claims[ck] == id:
				_claims[ck] = id
				break
			val = String(gen.call(rng))
			if tries == 7:
				val += " (%s, %d)" % [String(f["short"]), year]
		out.append([e[0], val])
	return out


static func numbers(def: Dictionary) -> Array:
	return lore(def)["numbers"]


## Returns [[heading, text], ...] for the item card's history panel. Every
## line is unique this run (copy lines per copy, the rest per item).
static func history(def: Dictionary, item: Dictionary) -> Array:
	var f := lore(def)
	var id := String(def.get("id", ""))
	if f.has("hist"):
		var cached: Array = (f["hist"] as Array).duplicate()
		cached.insert(7, ["THIS COPY", _copy_line(def, item, f)])
		return cached
	var rng := _r(id + "uniq")
	var out: Array = []
	out.append(["ORIGIN", String(f["origin_t"]).format(f)])
	out.append(["THE NAME", String(f["title_story"])])
	out.append(["BEHIND THE SCENES", String(f["team_t"]).format(f) + String(f["code_t"]).format(f) + String(f["dev"])])
	out.append(["THE PEOPLE", "Published by %s. %s" % [f["pub"], f["links"]]])
	var launch := "Sold for %s new." % f["price"]
	if int(f["score"]) > 0:
		launch += " %s - magazines averaged %d%%." % [f["reception"], f["score"]]
	out.append(["LAUNCH", launch])
	var left := "About %s made. Maybe %s still complete in box" % [_num(int(f["printed"])), _num(int(f["cib_left"]))]
	left += ", and %s sealed." % _num(int(f["sealed_left"])) if int(f["sealed_left"]) > 0 else ". Sealed ones are basically myths."
	out.append(["SURVIVORS", left])
	out.append(["DID YOU KNOW", String(f["quirk"])])
	out.append(["COLLECTOR TIP", String(f["tip"])])
	for row in out:
		row[1] = _uniq(String(row[1]), id, String(row[0]), rng, f)
	f["hist"] = out.duplicate()
	out.insert(7, ["THIS COPY", _copy_line(def, item, f)])
	return out


static func _copy_line(def: Dictionary, item: Dictionary, f: Dictionary) -> String:
	var ck := "%s|%s|%s" % [def.get("id", ""), item.get("uid", 0), item.get("serial", 0)]
	return _uniq(provenance(def, item, f), ck, "copy", _r(ck + "u"), f)
