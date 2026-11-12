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
# Seeded per item id (and per copy for provenance), so each item always tells
# the same story and every copy has its own past.

const ERA_LINE := {
	1970: ["Came out when arcades still smelled like cigarette smoke and quarters.", "Back when 'graphics' meant a square and a dream."],
	1980: ["Born in the boom years, when every kid begged for one at the mall.", "Hit shelves the same year as a dozen neon-coloured knockoffs.", "Sold in toy aisles right next to the action figures."],
	1990: ["Arrived in the console wars, when ads yelled about 'bits' at you.", "Launched with a TV ad that had way too much attitude.", "Rode the 90s wave of mail-in posters and magazine demos."],
	2000: ["Released as discs took over and cartridges started looking old.", "Came out in the era of memory cards and midnight launches.", "Sat on shelves while everyone talked about going online."],
	2010: ["A late arrival, made for the people who never stopped playing.", "Released when retro was already cool again."],
}

const DEV_LINE := {
	"RPG": ["The script was so long the translators worked in shifts.", "%s cut a whole second continent to fit the cart.", "A dev hid their cat's name in the save menu.", "The final boss was rewritten three weeks before ship."],
	"Shooter": ["Testers wore out four controllers on the last level alone.", "%s tuned the bullet patterns by playing it on a broken TV.", "The ship sprite started life as a drawing on a napkin."],
	"Adventure": ["The map was drawn by hand first, on graph paper taped together.", "%s shipped it with a secret room nobody found for six years.", "The manual had a fake treasure map folded inside."],
	"Platformer": ["The jump was tweaked over 200 times until it felt 'bouncy enough'.", "%s's mascot was nearly a sandwich instead.", "Level 1 was built last, once they knew how to teach the game."],
	"Action": ["The fight scenes were blocked out with action figures on a desk.", "%s cut the blood from the export. Kids noticed anyway."],
	"Horror": ["The fog wasn't style. The hardware couldn't draw any further.", "Testers refused to play it alone after dark.", "%s recorded the creepy sounds in a real basement."],
	"Fighting": ["Combos the designers never planned became the whole meta.", "%s balanced it by watching arcade crowds argue.", "One character was added because a tester begged."],
	"Racing": ["The cars were built from photos taken in a parking garage.", "%s raced the real track to time the laps.", "The soundtrack sold almost as well as the game."],
	"Sports": ["The rosters were outdated by the time it hit shelves.", "%s motion-captured an intern for every player.", "Office tournaments on it got... heated."],
	"Strategy": ["The AI cheats on hard. The devs admitted it later.", "%s's playtests took whole weekends.", "The manual was thicker than the box."],
	"Puzzle": ["Banned from the %s office because nobody did any work.", "The music has stuck in heads for decades.", "Designed in a weekend, polished for a year."],
	"Life Sim": ["Players kept finding things the devs never put in on purpose.", "%s got fan mail from grandmas."],
	"Music": ["The plastic peripheral cost more to make than the game.", "%s licensed the songs from a garage band nobody had heard of."],
	"Hardware": ["Engineers at %s fought over the colour for months.", "The first batch shipped with a fault they fixed quietly.", "The startup chime was recorded on the lead engineer's keyboard.", "Store demo units had their buttons worn smooth by kids."],
}

const RARE_LINE := [
	"Sold by the millions. Still, clean ones are getting harder to find.",
	"Common enough, but most copies were played to death.",
	"A short run that sold out fast and never came back.",
	"So few were made that collectors know most copies by name.",
]

const PAST_OWNER := [
	"Last seen in a church rummage sale, priced in pencil.",
	"Has a name written on the label in marker: KEVIN.",
	"Came out of a storage unit auction, still in a shoebox.",
	"A kid traded two others for it in 1995 and regretted it.",
	"Sat in a rental store until the store closed.",
	"Spent ten years in an attic in a box marked XMAS.",
	"Survived a basement flood. The box remembers.",
	"Bought new, played once, forgotten in a closet.",
	"Has a faded price sticker from a shop that's long gone.",
	"Owned by a speedrunner. The save file is ridiculous.",
	"Found behind a couch during a house move.",
	"A dad kept it 'for the kids' and never gave it to them.",
	"Has a store-stamp from a mall that's now a parking lot.",
	"Smells faintly of a smoker's living room. Classic.",
	"A tournament prize, once. The trophy is lost.",
	"Its last owner swore it was 'the rare one'. Was he right?",
]

const TIP_LINE := {
	"game": ["Check the label for sun fade before you pay.", "Matching serials on box and manual add value.", "Blow in it? Collectors say no. Everyone did anyway."],
	"console": ["Look at the vents: dust tells you how much it was played.", "Original box + inserts can double the price.", "Yellowed plastic is common. Even colour is not."],
	"acc": ["Loose cables are easy to find. Boxed ones aren't.", "Third-party versions are worth far less. Check the logo."],
	"misc": ["Paper stuff rarely survives. Clean copies are a treat."],
}

static func _era_key(year: int) -> int:
	return clampi(int(year / 10) * 10, 1970, 2010)

## Returns [[heading, text], ...] for the item card's history panel.
static func history(def: Dictionary, item: Dictionary) -> Array:
	var id := String(def.get("id", item.get("id", "")))
	var out: Array = []
	var year := int(def.get("year", 0))
	if year > 0:
		out.append(["ORIGIN", "%d. %s" % [year, pick(ERA_LINE[_era_key(year)], id + "era")]])
	var genre := String(def.get("genre", "Hardware" if String(item.get("kind", "game")) != "game" else ""))
	if DEV_LINE.has(genre):
		var line := pick(DEV_LINE[genre], id + "dev")
		if line.contains("%s"):
			line = line % String(def.get("pub", "The studio"))
		out.append(["BEHIND THE SCENES", line])
	out.append(["RARITY", String(RARE_LINE[clampi(int(item.get("tier", 0)), 0, 3)])])
	var copy_key := str(item.get("uid", 0)) + str(item.get("serial", 0)) + id
	out.append(["THIS COPY", pick(PAST_OWNER, copy_key)])
	out.append(["COLLECTOR TIP", pick(TIP_LINE.get(String(item.get("kind", "game")), TIP_LINE["game"]), id + "tip")])
	return out
