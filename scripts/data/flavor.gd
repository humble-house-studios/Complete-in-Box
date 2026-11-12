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


## Returns [[heading, text], ...] for the item card's history panel.
static func history(def: Dictionary, item: Dictionary) -> Array:
	var f := facts(def)
	var kind := String(def.get("kind", item.get("kind", "game")))
	var out: Array = []
	out.append(["ORIGIN", String(f["origin_t"]).format(f)])
	out.append(["BEHIND THE SCENES", String(f["team_t"]).format(f) + String(f["code_t"]).format(f) + String(f["dev"])])
	var launch := "Sold for %s new." % f["price"]
	if int(f["score"]) > 0:
		launch += " %s - magazines averaged %d%%." % [f["reception"], f["score"]]
	out.append(["LAUNCH", launch])
	var left := "About %s made. Maybe %s still complete in box" % [_num(int(f["printed"])), _num(int(f["cib_left"]))]
	left += ", and %s sealed." % _num(int(f["sealed_left"])) if int(f["sealed_left"]) > 0 else ". Sealed ones are basically myths."
	out.append(["SURVIVORS", left])
	out.append(["DID YOU KNOW", String(f["quirk"])])
	out.append(["THIS COPY", provenance(def, item, f)])
	out.append(["COLLECTOR TIP", String(f["tip"])])
	return out
