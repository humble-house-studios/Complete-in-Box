extends RefCounted
## Pop culture lore: Cousin Dale's world. No class_name: Flavor preloads it.
## Dale's letters, auction notes and epilogue are used when you inherit his
## estate; the rest whenever the run deals in toys, props and posters.
##
## The spine: Dale never left his computer chair. For twenty-two years he sold
## toys online as dales_deals, and every auction was won in the last second by
## the same bidder: c0mplete_set, who always paid in full and always left the
## same feedback. Dale sold the toys, then the props, then the posters off his
## walls, then the chair. His last listing was himself: one cousin, mint on
## card. He hangs on the peg wall at Mint on Card, still in the blister.

const COLLECTOR := "Cousin Dale"
const SENDER := "dales_deals@fleabay"
## His diary is the private notes he kept on his own auction listings.
const DIARY_NAME := "Dale's listing notes"

## [subject, body, the Buyer's P.S.] one per ante.
const LETTERS := [
	["RE: your inheritance (AUCTION ENDED)", "Hey cuz,\n\nYou got my room. Four thousand toys, all photographed, all listed once.\n\nEvery auction I ever ran, the same bidder won it in the last second. Username: c0mplete_set. Paid in full. Every time.\n\n- Dale", "P.S. A+++ seller. Would buy again. - c0mplete_set"],
	["RE: grading", "Hey cuz,\n\nMint on Card means the bubble's never been opened. Loose means somebody loved it. Played With means somebody loved it a lot.\n\nThe appraiser tilts every bubble to the light, looking for yellowing. On you.\n\n- Dale", "P.S. Slight shelf wear. - c0mplete_set"],
	["RE: the feedback", "Hey cuz,\n\nI read all 11,000 of his feedback comments last night. Every one says the same thing: ITEM AS DESCRIBED.\n\nExcept one, from 1998, on a figure I sold before I was born: ARLO SENDS HIS REGARDS.\n\n- Dale", "P.S. Always read the feedback. - c0mplete_set"],
	["RE: a figure on the peg", "Hey cuz,\n\nFound a carded figure at the swap meet today. It was me. Same hair, same chair, tiny keyboard accessory.\n\nThe card said COLLECT THEM ALL and a release date a year from now. 4:51 p.m. I didn't buy it. Somebody will.\n\n- Dale", "P.S. Limited run. - c0mplete_set"],
	["RE: the blister", "Hey cuz,\n\nThe Buyer carded Arlo like that: shrink, card, bubble, a 9.8 sticker. Hung on a peg.\n\nThere's a heat sealer humming outside my bedroom door. I'm listing everything at a penny, no reserve, so he has to bid on all of it first.\n\n- Dale", "P.S. Penny auctions. How quaint. - c0mplete_set"],
	["RE: the account", "Hey cuz,\n\nI looked his account up. Member since 1952. Before the internet. Before the phone line came to our street.\n\nThe shipping address is Arlo's house. The billing address is older. Arlo called him Uncle Mort.\n\n- Dale", "P.S. Ships from one address. Collects from many. - c0mplete_set"],
	["RE: the watchlist", "Hey cuz,\n\nYou can see a bidder's watchlist if you know where to click. His has every collector we know on it, in order.\n\nAt the very bottom: a painting. Then your username.\n\n- Dale", "P.S. Watching. - c0mplete_set"],
	["RE: last listing", "Hey cuz,\n\nWhat I couldn't put in a listing: every collector he wins ends up hung on his wall. The way out is the want list: every line, in one run.\n\nCut the bubble on my card. Gently. I'm in there.\n\n- Dale", "P.S. Sold. - c0mplete_set"],
]

## [where you found it, the note]. Notes Dale kept on his own listings.
const DIARY := [
	["in the notes on listing #1 (a loose Leonardoh)", "1998. First thing I ever sold. Listed it at nine at night, sniped at 8:59:59 the next night by a bidder with zero feedback. c0mplete_set. He paid by money order. The envelope smelled like a basement."],
	["in the draft of an unlisted Super-Fellow Lunchbox", "2006. Arlo came round and asked who my best customer was. I showed him. He went quiet and told me never to sell anything with a face on it. I'd already sold four thousand things with faces on them."],
	["in a listing note under 'item specifics'", "2014. Sold the posters off my walls. Then the walls. Then the house, in lots. He won every lot. Mum still lives in Lot 3. She says it's very nicely kept."],
	["on the last draft, never published", "The chair is the only thing left. He's asked me to list it. He wants the listing to include the person sitting in it. Condition: never removed from packaging. I've typed it all out. I just haven't pressed the button. I think you have to press it for me. Don't."],
]

const EPILOGUE := ["auction closed", "Hey cuz,\n\nThey cut my bubble at 4:51 and the air smelled like a new toy shop. Best smell there is.\n\nNext case down, someone's reading footnotes out loud and never gets to the end. The professor. Iris. Ask her what she wrote in the margin of the last page.\n\n- Dale, logging off"]

const PASS := [
	"The appraiser tilts a bubble to the light. \"No yellowing. Good.\"",
	"\"Card's flat. Corners are sharp.\" He sounds almost happy.",
	"He checks the copyright date on a figure's foot. \"Original. Not a re-release.\"",
	"\"Mint on Card,\" he writes, and underlines it twice.",
	"He sniffs a lunchbox flask. \"1963. Soup. Tomato.\"",
	"He holds a poster up by the corners. \"Folded, but honestly folded.\"",
	"He reads a studio letter twice, then folds it back the same way.",
	"\"Screen used,\" he says. \"He likes things that have been watched.\"",
	"He presses a figure's button. It still works. He seems disappointed.",
	"\"Complete in box,\" he says. \"Even the little gun. Nobody keeps the little gun.\"",
	"He measures a one-sheet: 27 by 41 inches exactly. He nods.",
	"\"To be continued in the next wave,\" he says on his way out.",
]
const FAIL := [
	"\"Yellowed bubble.\" He's looking at your eyes.",
	"He finds the reproduction card you hoped he'd miss.",
	"\"Re-release,\" he says, though it isn't. It doesn't matter.",
	"\"Discontinued,\" he reads off his clipboard.",
	"He measures you for a blister. Twelve inches won't do.",
	"\"Dale came up short in this room too.\"",
	"\"Played with. Loose. Missing accessories.\" He's not talking about the toys.",
	"He reads your total aloud, then the target, slowly, like a TV advert's small print.",
	"\"Played With,\" he says, and writes NO RETURNS on your forehead.",
	"He clips a punched cardback to your collar, with a peg hole ready.",
	"\"Every toy ends up in a chest,\" he says. \"Most of them in an attic.\"",
	"He doesn't shake your hand. He bubble-wraps it.",
]

const SELLER := {
	"toyswap": ["\"Loose figures a dollar each, carded ones on the back table, don't touch the back table.\"", "\"My son's. He's forty. He doesn't need them.\"", "\"That one's a reproduction. Probably. Make me an offer.\"", "\"Lunchboxes are five. The flasks are extra, they still smell of soup.\""],
	"attictoys": ["\"Gran kept everything. Everything. Mind the third rung.\"", "\"There's a chest up there nobody's opened since the eighties.\"", "\"The posters were lining the drawers. Is that bad?\"", "\"Take what you want, we need the loft back by Sunday.\""],
	"toyshop": ["\"Handle the cards by the edges, please. The edges.\"", "\"We send the good ones off to be graded. Bring me your carded stuff.\"", "\"The props are behind glass for a reason.\"", "\"Back room? Ask nicely.\""],
	"propauction": ["\"Lot 77: screen used, with a letter from the studio. Bidding opens at the reserve.\"", "\"From the estate of a well-known online seller, recently carded.\"", "\"Phone bidder in the room. Phone bidder always wins.\"", "\"Going once... going twice...\""],
}
const MOOD := {
	"toyswap": "A school gym on a Sunday, folding tables, tubs of loose figures, and somebody's dad selling only lunchboxes.",
	"attictoys": "A pull-down ladder, a single bulb, and everything a family stopped playing with in 1986.",
	"toyshop": "A peg wall of carded figures, posters on the ceiling, and a glass case of things that were in films.",
	"propauction": "Studio letters, phone bidders, and auctions that end while everyone else is asleep.",
}
const EVENTS := {
	"box": ["A toy chest on the porch", "\"Cleared out the kids' room. %s and it's yours, I'm not carrying it back.\" Something %s rattles inside."],
	"collector": ["A completist saw your shelf", "\"I'll give you %s cash for that %s. It's the last one I need for the full wave.\" It's worth %s, and it scores on your shelf."],
	"leak": ["The ceiling's leaking", "Water is dripping on your %s. A plastic sheet costs %s. Or the card goes soft, the bubble lifts, and it's Played With."],
}
const TIPS := [
	"Dale's rule: never open the bubble. Ever.",
	"Screen-used props score with the Screen Used perk. Ask for the studio letter.",
	"Toy chests, prop crates and poster tubes open up into pieces from the same aisle.",
	"A Mint on Card figure can be worth fifty times a loose one.",
	"Reproduction cards are too bright and too stiff. Collectors notice.",
	"Check the copyright date on the foot: a re-release says a later year.",
	"A one-sheet is 27 by 41 inches. If it isn't, it isn't.",
	"Have your carded figures graded at the toy shop before the appraiser sees them.",
	"Collect them all. That's what it says on the back. It's a warning.",
	"Every toy ends up in a chest. Make sure yours ends up on a shelf.",
]
const PAST_PLACE := ["a school gym swap meet at 8 a.m.", "a loft clearance, under the water tank", "a toy shop's back room, behind the till", "a studio backlot skip",
	"a cinema's projection booth", "a car boot sale in the rain", "a toy distributor's warehouse sale", "a fan convention dealer's room", "a closing-down sale at a department store", "Cousin Dale's room (the top shelf)"]
const PAST_WHO := ["a kid who played with it every day for a year", "a completist with a spreadsheet and a torch", "Cousin Dale (dales_deals on the back in marker)", "a dealer who never priced it",
	"a speculator who bought ten carded and kept one", "a set dresser who took it home after the wrap", "a cinema manager who never threw anything away", "a collector who came up short (the card reads SOLD TO: c0mplete_set)"]
const PAST_MARK := ["A price sticker half peeled off the bubble.", "A name in biro on the foot.", "A cinema's stamp on the back of the poster.", "Smells of a loft and a long summer.",
	"A studio inventory tag on a loop of string.", "Dale's marker on the card: 'DO NOT OPEN.'", "Perfectly clean. Suspiciously clean.", "A thumbprint in the dust on the bubble, faint as a fossil."]

const CURSE := {
	"title": "CARDED & BLISTERED",
	"line": "You came up short. The Buyer's packers shrink you, seal you in a blister on a cardback and hang you on the peg wall: collect them all.",
	"label": "c0mplete_set TOYS  •  MINT ON CARD",
	"case": "toy",
}

const INTRO := {
	"title": "POP CULTURE",
	"sub": "Cousin Dale's world",
	"line": "Mint on Card after hours. A peg wall of figures, posters on the ceiling, and Dale on the top peg, still in the bubble.",
	"line_pre": "Mint on Card after hours. A peg wall of figures, posters on the ceiling, and an empty peg at the top.",
	"scene": "toyshop",
}
