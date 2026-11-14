extends RefCounted
## Sports cards lore: Grandma Rose's world. No class_name: Flavor preloads it.
## Per-collector text (letters, diary, epilogue) is used when you inherit
## Rose's estate; per-world text (appraiser, sellers, events, tips, the loss
## ending) whenever the run deals in sports cards.
##
## The spine: the Buyer collects collectors, one per world, graded and cased in
## the vault. Rose was the third. She kept everything sealed, so the Buyer kept
## her sealed too. Her clues point at the Gallery: a frame with no painting yet.

const COLLECTOR := "Grandma Rose"
const SENDER := "rose.p"

## [subject, body, the Buyer's P.S.] one per ante. Rose wrote these before she
## was sealed and queued them to send "if I don't come back from the show".
const LETTERS := [
	["if you're reading this", "Sweetheart,\n\nIf this reached you, I didn't come home from the Sunday show. Don't fuss. Put the kettle on.\n\nThe man who wants my cards signs c0mplete_set. Be polite. Be fast.\n\nLove, Rose", "P.S. She was polite. Not fast enough. - c0mplete_set"],
	["corners", "Sweetheart,\n\nA card is four corners and a story. Buyers check the corners first. Then they check you.\n\nYour grandfather proposed with a Mantel instead of a ring. I got the better end.\n\nLove, Rose", "P.S. I have the Mantel now. And the ring. - c0mplete_set"],
	["rookies", "Sweetheart,\n\nEveryone is worth the most at the start. A rookie card is a bet that a boy becomes a legend.\n\nThe appraiser never looks at faces. Only grades. And his watch.\n\nLove, Rose", "P.S. Faces fade. Grades are forever. - c0mplete_set"],
	["wax", "Sweetheart,\n\nSixty years and I never opened a pack. Unopened, it can still be anything.\n\nHe asked what was in my boxes. I said hope and stale gum. He laughed. It sounded like your great-uncle.\n\nLove, Rose", "P.S. I opened one of hers. Commons. - c0mplete_set"],
	["the slab", "Sweetheart,\n\nA graded card goes in a slab with a number. Ten is perfect. Nobody is a ten.\n\nHis labels have no card names. Just lot numbers, dates, and the same time: 4:51 A.M.\n\nLove, Rose", "P.S. Everyone is sealed at 4:51. It's tidier. - c0mplete_set"],
	["population report", "Sweetheart,\n\nHe keeps a population report for collectors. I found our family. LOT 8, Mort: 9.0. LOT 9, Arlo: 9.8. The twins: two of them, 8.5 each.\n\nYour name is at the bottom. In pencil.\n\nLove, Rose", "P.S. Pencil can be erased. Ink can't. - c0mplete_set"],
	["the gallery", "Sweetheart,\n\nI went to see where he keeps us. Rows of glass under a gallery. At the end, an empty frame.\n\nSomeone was behind it, sweetheart. Breathing on the glass. From the inside.\n\nLove, Rose", "P.S. I like to keep an eye on things. - c0mplete_set"],
	["the last show", "Sweetheart,\n\nWhat I worked out too late: he doesn't want cards. He wants the set. Fill every line on his want list in one run, and a finished set has to stop.\n\nKeep the corners sharp. Come and get me.\n\nLove, Rose", "P.S. I'll leave the light on. - c0mplete_set"],
]

## [where you found it, the page]. Rose's scrapbook, not Arlo's diary.
const DIARY := [
	["tucked behind a 1952 Toppz in a top-loader", "June 3, 1961. Sold my first card today for a dollar. A man in a grey coat bought it. He paid in a sealed envelope and the envelope had my name on it already. I spent the dollar. I kept the envelope."],
	["inside a wax box, under the gum", "April 1987. Arlo phoned. He says the man in the grey coat has been at every show this year. He says he buys collections, then the collectors. Arlo laughs when he says it. Arlo is not laughing."],
	["pressed between two penny sleeves", "October 1999. My appraisal came back 9.6. Not the cards. Me. The letter said I was 'nearly mint, minor wear at the corners'. I've been holding very still since."],
	["written on the back of a checklist card", "Last page. The man keeps his own collection upstairs, in a gallery. Paintings, all facing the wall. All but one frame, empty, waiting. I know who it's waiting for. It isn't me."],
]

## Shown after a win when Rose is the estate you played: the freed collector writes back.
const EPILOGUE := ["out of the plastic", "Sweetheart,\n\nThey opened my case at 4:51. The seal cracked like a fresh pack. You did that.\n\nThree cases down, a radio plays through the glass. Same song, over and over, at the wrong speed. That's Marv. Play him at 45.\n\nLove, Rose"]

## The appraiser at the end of a stop.
const PASS := [
	"The appraiser runs a thumb along every top-loader. \"Corners. Good.\"",
	"\"Centering acceptable.\" He almost smiles.",
	"He holds a rookie up to the chandelier for a long time. \"Fine. Fine.\"",
	"\"The Buyer likes a clean slab.\" He writes a number you can't read.",
	"He checks the backs. All of them. \"No trimming. Rose taught you well.\"",
	"\"Surface is clean.\" He sounds disappointed.",
	"He weighs a wax pack in his palm. \"Unsearched. Good.\"",
	"\"Population: low. Value: acceptable. You: pending.\"",
	"He photographs your shelf for the Buyer's report. The flash takes a long time to fade.",
	"\"You'd grade a nine,\" he says. You don't think he means the cards.",
	"He taps the glass of a slab twice. \"Still sealed. Keep it that way.\"",
	"\"The Buyer collects winners,\" he says, closing his case. \"For now, that's you.\"",
]
const FAIL := [
	"\"Soft corners.\" He says it about you.",
	"He finds the crease you hoped he wouldn't. He always finds it.",
	"\"Trimmed,\" he says, though it isn't. It doesn't matter now.",
	"He reads the target out loud, then your total, slowly.",
	"\"Off-centre,\" he says, measuring you with a loupe.",
	"He reaches for a slab without a card in it yet.",
	"\"Rose came up short in this room too.\"",
	"He writes a grade on a label. It has your name on it.",
	"\"Junk wax,\" he sighs. \"Printed by the billion. Like collectors.\"",
	"He opens the case. It's lined with velvet, cut to your shape.",
	"\"The Buyer prefers his collectors mint. We'll make do.\"",
	"He shakes your hand. His grip doesn't let go.",
]

## Seller quotes per venue (quoted in the item sheet).
const SELLER := {
	"ballroom": ["\"Dime box on the left, slabs on the right. Don't confuse them.\"", "\"Book value? Son, I wrote the book.\"", "\"Graded a 9 at the last show. They're tough on the corners these days.\"", "\"Cash only. The card reader died in '96.\""],
	"shoebox": ["\"It's all my kid's stuff. Took it with him to college, brought it back in a flood.\"", "\"Everything's a dollar. Unless you want it. Then it's two.\"", "\"Eighty-seven Toppz. Thousands of 'em. Worth a fortune someday, right?\"", "\"Watch out for the rubber bands, they've welded on.\""],
	"dugout": ["\"New wax drops Friday. Limit two per customer. You can't be a third customer.\"", "\"We submit for grading every Monday. Ten-week turnaround, give or take a decade.\"", "\"That's a fair price. I know because I priced it.\"", "\"Don't sleeve it in front of me. I'll cry.\""],
	"breaks": ["\"LFG! Random team, fifty bucks a spot!\"", "\"Pulled live, shipped in a top-loader and team bag!\"", "\"Chat says it's a fake. Chat says everything is a fake.\"", "\"Next box is the big one. I can feel it.\""],
}
const MOOD := {
	"ballroom": "Chandeliers, folding tables and a carpet with a pattern you'll dream about.",
	"shoebox": "A garage that smells of cardboard and somebody else's childhood.",
	"dugout": "Wax on the walls, slabs in the case, a TV playing a game from 1986.",
	"breaks": "Forty thousand viewers and one guy with scissors.",
}
## Doorbell events in this world's words: same rules as the base events.
const EVENTS := {
	"box": ["A shoebox at the door", "\"My dad's old cards, %s, sight unseen. He'd want them to go to someone who sleeves.\" Something %s slides around inside."],
	"collector": ["A dealer saw your shelf", "\"I'll give you %s cash for that %s, today. I've got a buyer flying in.\" It's worth %s, and it scores on your shelf."],
	"leak": ["Humidity warning", "The basement dehumidifier just died, right under your %s. A new one costs %s. Or the card warps, and warped means Creased."],
}
const TIPS := [
	"Rose's rule: sleeve first, then admire.",
	"Rookie cards are bets on the future. Bet cheap.",
	"Wax boxes rip into cards of the same sport. The gum is free.",
	"A Gem Mint card is worth many times a Very Good one. Corners are money.",
	"Refractors throw rainbows. Collectors throw money at them.",
	"Junk wax: the 80s printed so many cards that most are worth the cardboard.",
	"The appraiser checks the back too. Trimmed edges are the classic sin.",
	"A card printed before 1980 has survived bicycle spokes. Respect it.",
	"Grade your best card at The Dugout before the Buyer's appraiser sees it.",
	"Every player was a rookie once. So were you.",
]
## Item card history bits for this world.
const PAST_PLACE := ["a hotel ballroom show in 1991", "a shoebox under a bed", "a rubber-banded stack in a desk drawer", "a dad's garage sale", "a card shop's back case", "a bicycle spoke (somehow it survived)", "a church bazaar", "an attic trunk", "a bowling-alley vending machine", "a team-signing line in the rain"]
const PAST_WHO := ["a kid who traded his whole binder for it", "a dad who 'saved it for the grandkids'", "a dealer who never put it on the table", "a team equipment manager", "a collector who kept everything in triple sleeves", "Grandma Rose (R.P. pencilled on the penny sleeve)", "a breaker who pulled it live for 40,000 viewers", "a collector who came up short (the slab label reads c0mplete_set)"]
const PAST_MARK := ["A faint rubber-band dent on one edge.", "Still smells of bubble gum.", "Penny sleeve yellowed with age.", "A pencil price on the back, crossed out three times.", "Perfect corners. Suspiciously perfect.", "A team stamp on the back from a giveaway night.", "Someone wrote 'MINE' on the top-loader.", "The slab has a hairline scratch shaped like a signature."]

## The loss ending in this world: GRADED & SEALED becomes SLABBED.
const CURSE := {
	"title": "SLABBED",
	"line": "You came up short. The Buyer's grader seals you in a slab with a number on it.",
	"label": "GCA SPORTS  •  SPECIMEN: YOU",
	"case": "slab",
}

## The intro the first time you enter this world.
const INTRO := {
	"title": "SPORTS CARDS",
	"sub": "Grandma Rose's world",
	"line": "Sunday. The Ramadoh ballroom. Somewhere in a dime box is a rookie worth a house.",
	"scene": "ballroom",
}
