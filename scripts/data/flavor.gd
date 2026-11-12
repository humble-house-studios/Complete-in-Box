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
