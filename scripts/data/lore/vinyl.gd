extends RefCounted
## Vinyl records lore: Midnight Marv Okafor's world. No class_name: Flavor
## preloads it. Marv's letters, liner notes and epilogue are used when you
## inherit his estate; the rest whenever the run deals in records.
##
## The spine: Marv hosted the 3 a.m. show on WMRV for thirty years, and one
## listener called in every night: c0mplete_set, requesting a record Marv
## didn't own yet. Marv always found it by the next night. Then the caller
## asked for the one record Marv could never find: the master tape of his own
## voice. Marv is pressed and sleeved in the corner of Needle Drop Records,
## filed under M, still in the shrink.

const COLLECTOR := "Midnight Marv"
const SENDER := "marv@wmrv-3am"
## His diary is the notes he wrote on the inner sleeves of his records.
const DIARY_NAME := "Marv's liner notes"

## [subject, body, the Buyer's P.S.] one per ante.
const LETTERS := [
	["Side A, track 1: the request line", "Hey night owl,\n\nIf you're reading this, you've got my crates. Eleven thousand records, every one filed, every one played at least once on air. That was the rule.\n\nThere's one listener who called the request line every night at three. Never gave a name. Just a username, like the internet was already a thing in 1987: c0mplete_set.\n\nStart with the crate by the boiler. Those are the ones I could stand to lose.\n\n- Marv", "P.S. He never could stand to lose anything. Flip the boiler crate. - c0mplete_set"],
	["Side A, track 2: grading", "Hey night owl,\n\nRecord people grade on a funny scale. Mint means unplayed. Near Mint means played by a careful person. Very Good means not very good. Poor means it still goes round.\n\nThe sleeve matters as much as the wax. Ring wear, seam splits, a price sticker torn half off. Everything leaves a mark.\n\nThe appraiser holds every record up to the lamp. He's looking for scratches. On you.\n\n- Marv", "P.S. He found three. Very Good Plus. Not bad for your age. - c0mplete_set"],
	["Side A, track 3: the run-out groove", "Hey night owl,\n\nThe truth about a record is scratched in the run-out groove, the bit after the music stops. Matrix numbers. Initials. Sometimes a little message from the engineer.\n\nI found one on a record I've owned since 1979. Etched in the dead wax, tiny: FOR C0MPLETE_SET, ON REQUEST.\n\nThe record came out before I ever took a call from him.\n\n- Marv", "P.S. Always read the dead wax. Everyone leaves a message there eventually. - c0mplete_set"],
	["Side A, track 4: the crate", "Hey night owl,\n\nAt every basement clear-out there's a crate nobody wants: polka, Christmas albums, a broken box set. Flip it anyway. The good one always hides behind the Herb Alpert.\n\nI found a sleeve with my own photo on it once. The record inside was blank. The title was just a date, about a year from when I'm writing this.\n\nI put it back. I'm not sure that was allowed.\n\n- Marv", "P.S. It's still in the crate. Front of the crate now. - c0mplete_set"],
	["Side B, track 1: the shrink-wrap", "Hey night owl,\n\nA sealed record is a funny thing. It's worth more because nobody's heard it. All that music, safe in the shrink, never once played.\n\nHe sealed Arlo like that. I saw the photo. Shrink-wrap, hype sticker, GRADE 9.8. A record nobody gets to play.\n\nThere's a crinkle of plastic outside the studio door tonight. I'm playing the long version of everything.\n\n- Marv", "P.S. Shrink-wrap keeps the dust off. You're welcome. - c0mplete_set"],
	["Side B, track 2: the last request", "Hey night owl,\n\nLast night he asked for a record I don't own. First time in thirty years.\n\nHe asked for the master tape of my show. All of it. Every night, every dedication, every time I said his name on air.\n\nHe's got ten crates, he says. One per world. The last one's called THE GALLERY, and it's nearly full.\n\n- Marv", "P.S. Every collection needs its liner notes. Yours are very good, Marv. - c0mplete_set"],
	["Side B, track 3: the voice", "Hey night owl,\n\nI played his calls back off the logging tape tonight. Thirty years of them, sped up, slowed down.\n\nAt 33 RPM it's a stranger. At 45 it's a younger man, and he's laughing. He sounds like he's standing in a room full of game cartridges.\n\nYour great-uncle's name was Arlo, wasn't it? He had a laugh like that.\n\n- Marv", "P.S. Never play a man at the wrong speed. It's rude. - c0mplete_set"],
	["Side B, track 4: the run-out", "Hey night owl,\n\nLast track. Here's the bit I couldn't say on air.\n\nHe isn't collecting records. He's filling a want list: one line per night, every line in one sitting. Fill the whole list and the set is complete. A complete set stops asking.\n\nKeep your needle clean and your sleeves square. And when you cut the shrink on my crate, drop the needle on track one. I've been waiting a long time to be played.\n\n- Marv", "P.S. Near Mint. Still sealed. As issued. Goodnight, Marv. - c0mplete_set"],
]

## [where you found it, the note]. Written on the inner sleeves of his records.
const DIARY := [
	["on the inner sleeve of a Kinda Blue", "Oct 1987. First night on the graveyard shift. Phone lit up at 3:00 exactly. A man asked for a record I'd never heard of. I said I'd find it. I found it in a thrift store the next morning, on top of the pile, like it was waiting."],
	["on the inner sleeve of a Soul Club 45", "March 1993. Arlo came to the station with a box of game cartridges and asked if the request line ever called after three. He went white when I said the name. He left the cartridges behind. I still have them."],
	["on a DJ's run-out note in Blue Trane", "July 2006. Checked the station logs back to 1952. The 3 a.m. request line has had a caller every night since the station opened. Same username on every slip. Either he's very old, or he's very many people. Or he's somebody's great-uncle."],
	["inside the last sleeve in the boiler crate", "The studio door is locked from the outside. I have a turntable and eleven thousand records. He's asked for the final request. It isn't my tape and it isn't Arlo's either. It's the next voice on the line. It's yours."],
]

const EPILOGUE := ["The run-out groove", "Hey night owl,\n\nThey cut the shrink-wrap at dawn and the first thing I heard was the hiss of a needle on an empty groove. Sweetest sound in the world.\n\nThe crates are yours: eleven thousand records, and a note on every inner sleeve. Play them. Records are for playing. Sleeves are for the dead.\n\nOne crate over I can hear somebody counting comics out loud, never finishing. Uncle Hector, I think. He always did lose count at the good bit.\n\nAnd night owl: when you get to the Gallery, don't call the request line.\n\n- Midnight Marv Okafor, WMRV, signing off"]

const PASS := [
	"The appraiser holds a record up to the lamp and tilts it. \"No scratches. Good.\"",
	"\"Matrix numbers check out.\" He sounds almost happy.",
	"He sniffs a sleeve. \"Basement. But a dry basement.\"",
	"\"Near Mint in a Very Good Plus jacket,\" he writes, twice.",
	"He checks the run-out groove with a loupe. \"First pressing. The Buyer likes firsts.\"",
	"\"No cut-out notch. No club code.\" He seems disappointed.",
	"He taps a crate with his pen. \"Unflipped. Marv would approve.\"",
	"\"Plays through without a skip,\" he says, and closes his case.",
	"He drops the needle on one record, listens to a bar, lifts it. He doesn't seem to enjoy it.",
	"\"Original pressing,\" he says. \"He collects those too.\"",
	"He slides a record back into its sleeve without touching the grooves. Impressive.",
	"\"To be continued on side two,\" he says on his way out.",
]
const FAIL := [
	"\"Ring wear.\" He's looking at the bags under your eyes.",
	"He finds the cut-out notch you hoped he'd miss.",
	"\"Reissue,\" he says, though it isn't. It doesn't matter.",
	"\"Out of print,\" he reads off his clipboard.",
	"He measures you for a sleeve. Twelve inches won't do.",
	"\"Marv came up short in this basement too.\"",
	"\"Warped. Surface noise throughout.\" He's not talking about the records.",
	"He reads your total aloud, then the target, at 33 RPM. Slowly.",
	"\"Poor,\" he says, and writes PLAYS THROUGH on your forehead.",
	"He writes a catalogue number on a slip and tucks it into your pocket.",
	"\"Every record ends,\" he says. \"Most of them in a crate.\"",
	"He doesn't shake your hand. He shrink-wraps it.",
]

const SELLER := {
	"basementcrates": ["\"Uncle's records. A dollar each, or make me an offer on the lot.\"", "\"He never let us touch those ones. Is that good?\"", "\"Some of these are heavy. Like, really heavy. Shellac?\"", "\"There's more by the boiler, but it floods.\""],
	"recordfair": ["\"Dollar bin's under the table. Everything else is marked.\"", "\"Please don't play them on your phone app. It upsets the other dealers.\"", "\"I'll do you three for twenty. Don't tell my wife.\"", "\"That crate came from a radio station clear-out. Nobody's flipped it.\""],
	"recordshop": ["\"Handle them by the edges, please.\"", "\"We send the good ones out to be graded. Bring me your originals.\"", "\"That's the auction record. Somebody overpaid at three in the morning.\"", "\"Behind the counter? Ask nicely.\""],
	"diskogz": ["\"Lot 112: first pressing, matrix A1/B1, in shrink. Bidding opens at the reserve.\"", "\"From the collection of a well-known late-night DJ, recently sleeved.\"", "\"Seller grades conservatively. Seller says that about everything.\"", "\"Ending in 3... 2...\""],
}
const MOOD := {
	"basementcrates": "A dead DJ's basement, crates to the rafters, and a nephew who wants the boiler back.",
	"recordfair": "Trestle tables in a leisure centre, a hundred dealers, and early birds with torches.",
	"recordshop": "A wall of sleeves, a listening deck, and an owner who knows what everything's worth.",
	"diskogz": "Matrix numbers, grading arguments, and auctions that end at three in the morning.",
}
const EVENTS := {
	"box": ["A crate of records on the porch", "\"Cleared out my dad's basement. %s and they're yours, I'm not carrying them back.\" Something %s rattles inside."],
	"collector": ["A completist saw your shelf", "\"I'll give you %s cash for that %s. It's the last gap in my discography.\" It's worth %s, and it scores on your shelf."],
	"leak": ["The radiator's leaking", "Water is pooling under your %s. A drip tray costs %s. Or the sleeve gets soaked and the record warps, and that means Poor."],
}
const TIPS := [
	"Marv's rule: every record gets played at least once.",
	"Singles count: 45s, 78s and 12-inches. The appraiser loves a single.",
	"Crates flip into records from the same crate of the shop.",
	"A sealed first pressing can be worth a hundred times a party copy.",
	"Record-club pressings have a club code on the back. Worth a third.",
	"A cut-out notch means it went to the bargain bin. Collectors notice.",
	"Read the run-out groove: the matrix numbers prove a first pressing.",
	"A resealed reissue in fresh shrink is the oldest trick in the trade.",
	"Have your originals graded at the record shop before the appraiser sees them.",
	"Every record ends. Make sure yours ends on a good track.",
]
const PAST_PLACE := ["a radio station's record library, under M", "a leisure-centre record fair at 7 a.m.", "a dead DJ's basement, by the boiler", "a charity shop's 50p box",
	"a record shop's behind-the-counter pile", "a car boot sale in the rain", "a jukebox route operator's garage", "a club's DJ booth after closing", "a pressing plant's reject bin", "a damp loft (the top crate)"]
const PAST_WHO := ["a DJ who wrote cue marks on the label", "a completist with a spreadsheet and a torch", "Midnight Marv (WMRV on the back in marker)", "a dealer who never priced it",
	"a speculator who bought ten sealed and kept one", "the drummer's mother", "a teenager who played it every day for a year", "a collector who came up short (the sleeve reads FILED: c0mplete_set)"]
const PAST_MARK := ["A price sticker half torn off the shrink.", "A name in biro on the back of the sleeve.", "A ticket stub from the gig used as a bookmark in the gatefold.", "Smells of incense and a basement.",
	"A radio station's library stamp on the label.", "Marv's marker on the inner sleeve: 'Play loud.'", "Perfectly flat. Suspiciously flat.", "A coffee ring on the back, faint as a halo."]

const CURSE := {
	"title": "PRESSED & SLEEVED",
	"line": "You came up short. The Buyer's engineer presses you flat, sleeves you in shrink-wrap and files you in the crate under M.",
	"label": "c0mplete_set RECORDS  •  ORIGINAL PRESSING",
	"case": "record",
}

const INTRO := {
	"title": "VINYL RECORDS",
	"sub": "Midnight Marv's world",
	"line": "Needle Drop Records after hours. A wall of sleeves, a deck still spinning, and Marv in the corner, still in the shrink.",
	"scene": "recordshop",
}
