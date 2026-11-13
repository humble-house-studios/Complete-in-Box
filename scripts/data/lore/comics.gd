extends RefCounted
## Comics lore: Uncle Hector's world. No class_name: Flavor preloads it.
## Hector's letters, ledger pages and epilogue are used when you inherit his
## estate; the rest whenever the run deals in comics.
##
## The spine: Hector kept everything, so the Buyer kept him. He found the
## Buyer's own catalogue in a longbox and read ahead: every collector is an
## issue in a run, and the run ends at the Gallery with an empty frame.

const COLLECTOR := "Uncle Hector"
const SENDER := "hector.longbox"
## The diary is a ledger he kept on index cards between the dividers.
const DIARY_NAME := "Hector's ledger"

## [subject, body, the Buyer's P.S.] one per ante.
const LETTERS := [
	["#1 (of 8)", "Kid,\n\nIf you got this, the garage is yours. All of it. Twenty-six thousand books in four hundred longboxes, and I know where every one is. Mostly.\n\nThe man who wants them signs c0mplete_set. He doesn't want the comics. He wants the run. Every issue, no gaps.\n\nStart with the boxes marked KEEP. Never sell those.\n\n- Hector", "P.S. Every box in that garage is marked KEEP. - c0mplete_set"],
	["#2: condition", "Kid,\n\nA comic's grade is the first thing a buyer asks and the last thing you can fix. Spine ticks, corner bends, a coupon cut out of the back. Every flaw is a number off.\n\nDon't let anyone tell you restoration is a crime. Lying about it is.\n\nThe appraiser hates restored books. He hates them more than he hates people.\n\n- Hector", "P.S. Purple labels are for collectors who cheat. Yours is a different colour. - c0mplete_set"],
	["#3: first appearances", "Kid,\n\nThe books that matter are the firsts. First appearance, first issue, first time somebody drew a thing nobody had drawn before.\n\nI found my own first appearance in one of HIS longboxes once. A ledger card with my name and a date, before I'd bought a single comic.\n\nI kept collecting anyway. What else was I going to do?\n\n- Hector", "P.S. Everyone has a first appearance. Yours was filed years ago. - c0mplete_set"],
	["#4: the longboxes", "Kid,\n\nA longbox holds about three hundred books if you don't cram it. I crammed it.\n\nDig through the boxes at shows. Nobody else will. The keys are always at the back, behind the Archie doubles.\n\nI heard the appraiser counting my boxes through the garage door. He counted to four hundred and one. I only own four hundred.\n\n- Hector", "P.S. The extra one was for you. - c0mplete_set"],
	["#5: the slab", "Kid,\n\nThey grade a comic, seal it in plastic and print a label: title, issue, grade, page quality. Off-white to white pages. Once it's slabbed, nobody reads it again.\n\nThat's what he does to us. You don't read a slabbed collector. You just look.\n\nArlo's label said 9.8, white pages. Best grade in the family. Nobody ever asked how.\n\n- Hector", "P.S. I asked. He answered very honestly. - c0mplete_set"],
	["#6: the catalogue", "Kid,\n\nI finally found his catalogue. Ten volumes, one per world. Games, cards, sports, records, comics, coins, watches, toys, books.\n\nThe tenth volume is just called THE GALLERY. Every page is a frame. All the frames are full except the last one.\n\nThe last frame's caption has a date and no name.\n\n- Hector", "P.S. I'll fill in the name when it's dry. - c0mplete_set"],
	["#7: continuity", "Kid,\n\nComics have continuity. Every issue picks up where the last one stopped. Every hero hands the costume to the next.\n\nArlo handed it to me. I'm handing it to you. Somebody handed it to Arlo, and I don't think he was a stranger to him.\n\nRead the credits. Read who signs the letters column.\n\n- Hector", "P.S. Letters column, issue #1. Look at the signature. - c0mplete_set"],
	["#8: the final issue", "Kid,\n\nLast card in the ledger. Here's the spoiler I wish someone had given me.\n\nHe's not collecting comics. He's finishing a run. One collector per world, and the run only ends when every issue is filled: every line on his want list, in one go.\n\nFill the list, and the series is complete. Complete series get put away. Complete series stop.\n\nKeep your corners sharp and your spine straight. Come get me out of this bag.\n\n- Hector", "P.S. To be continued. - c0mplete_set"],
]

## [where you found it, the card]. Index cards between the longbox dividers.
const DIARY := [
	["filed between two Archies, under A", "June 1971. Bought my first longbox off a guy at a swap meet. He wouldn't take money, only my signature on a card. The card said HECTOR, ISSUE #1. I laughed. I still have the box."],
	["taped inside a longbox lid", "March 1986. Arlo came by and wouldn't come in. Said the garage looked like the Buyer's vault, just messier. I asked how he'd know. He changed the subject to the weather."],
	["tucked in a 1993 polybag", "November 1993. The speculator boom. Everyone's buying ten copies of everything. The Buyer bought one copy of me. Appraised at 4.0: 'Good, heavy wear, complete.' Fair."],
	["in a mylar sleeve, labelled LAST", "The garage door won't open from the inside any more. That's fine. I've got light and four hundred boxes. I've read the end of his catalogue. The last frame in the Gallery isn't for me. It isn't even for Arlo."],
]

const EPILOGUE := ["#1 (second printing)", "Kid,\n\nThey cut the bag open at dawn. First thing I did was check my own corners. Not bad. A little soft. I'll live.\n\nThe garage is yours, all four hundred and one boxes. Read them. Actually read them. That's what they're for.\n\nNext case down the row, I can hear coins being counted. That'll be your Aunt June, haggling with the glass.\n\nAnd kid: in the Gallery, don't read the last caption out loud.\n\n- Hector"]

const PASS := [
	"The appraiser flips each book to the back cover. \"Coupons intact. Good.\"",
	"\"Spines straight. Staples clean.\" He sounds almost happy.",
	"He holds a key issue up to the light for a long, long time. \"Acceptable.\"",
	"\"Off-white to white pages.\" He writes it down twice.",
	"He checks the census on a tablet. \"Low population. The Buyer likes a low population.\"",
	"\"No colour touch. No pressing.\" He seems disappointed he can't call you a liar.",
	"He taps a longbox with his pen. \"Unsorted. Hector would approve.\"",
	"\"Continuity maintained,\" he says, and closes his case.",
	"He photographs every cover for the Buyer's catalogue. The flash leaves spots.",
	"\"First appearances,\" he says. \"He collects those too.\"",
	"He bags and boards his clipboard before he leaves.",
	"\"To be continued,\" he says on his way out. It sounds like a threat.",
]
const FAIL := [
	"\"Spine roll.\" He's looking at your posture.",
	"He finds the cut-out coupon you hoped he'd miss.",
	"\"Restored,\" he says, though it isn't. It doesn't matter.",
	"\"Cancelled after a short run,\" he reads off his clipboard.",
	"He opens a mylar bag cut to your size.",
	"\"Hector came up short in this garage too.\"",
	"\"Brittle pages. Tanning at the edges.\" He's not talking about the comics.",
	"He reads your total out loud, then the target, slowly, like a recap page.",
	"\"Reading copy,\" he says, and slides a backing board behind you.",
	"He prints a label: SPECIMEN: YOU. Page quality: cream.",
	"\"Every run ends with a final issue,\" he says.",
	"He doesn't shake your hand. He slabs it.",
]

const SELLER := {
	"comiccon": ["\"Longboxes are five bucks a book, or make me an offer on the whole run.\"", "\"Got that one signed this morning. Line was four hours.\"", "\"CGX 9.8, white pages. Price is firm. Ish.\"", "\"Don't touch the wall books with bare hands.\""],
	"atticfind": ["\"Grandpa's comics. Mice got the bottom box, but the top's fine.\"", "\"Dollar each? I just want them out of the attic.\"", "\"Some of these are older than me. Is that good?\"", "\"There's more under the insulation. Mind the nails.\""],
	"comicshop": ["\"New books on Wednesday. Back issues in the bins. Don't mix them up.\"", "\"We submit for grading every month. Bring me your keys.\"", "\"That's guide price. The guide is wrong, but it's the guide.\"", "\"Want me to add it to your pull list?\""],
	"comicauction": ["\"Key issue, unrestored, live now!\"", "\"Pedigree copy from the Wisconsin collection.\"", "\"Graded 9.6, white pages, three bidders already.\"", "\"Reserve not met. Yet.\""],
}
const MOOD := {
	"comiccon": "Artist alley, cosplayers, and a back corner of longboxes nobody's dug through yet.",
	"atticfind": "An attic that smells of newsprint and mouse. Bring a torch.",
	"comicshop": "Wall books in mylar, back-issue bins, and a guy who remembers your pull list.",
	"comicauction": "Slabbed keys, live bids and a buyer's premium that hurts.",
}
const EVENTS := {
	"box": ["A longbox on the porch", "\"Found this in my late uncle's garage. %s and it's yours, I'm not opening it.\" Something %s shifts inside."],
	"collector": ["A completist saw your shelf", "\"I'll give you %s cash for that %s. It's the last gap in my run.\" It's worth %s, and it scores on your shelf."],
	"leak": ["The basement is flooding", "The water's an inch from your %s. A dehumidifier and some crates cost %s. Or the pages ripple, and rippled means Poor."],
}
const TIPS := [
	"Hector's rule: bag it, board it, then brag about it.",
	"Key issues are first appearances. The appraiser counts them.",
	"Longboxes dig into comics of the same era. Mice not included.",
	"A Near Mint book is worth many times a Fine one. Spines are money.",
	"Restored copies get purple labels. They're worth half.",
	"Newsstand copies have barcodes. Fewer survived than shop copies.",
	"Golden Age paper turns brown and brittle. Handle with clean hands.",
	"The 1990s printed millions of foil covers. Most are worth the foil.",
	"Grade your keys at the comic shop before the appraiser sees them.",
	"Every run gets cancelled eventually. Make sure yours ends on a high.",
]
const PAST_PLACE := ["a spinner rack in a 1960s drugstore", "a garage of four hundred longboxes", "an attic under the insulation", "a barber shop waiting table",
	"a newsstand's back room", "a convention dollar bin", "a soldier's footlocker", "a college dorm closet", "a comic shop's going-out-of-business sale", "a flooded basement (the top box)"]
const PAST_WHO := ["a kid who traced every panel", "a completist with a ten-volume checklist", "Uncle Hector (H. in pencil on the back cover)", "a newsagent who never sold it",
	"a speculator who bought ten and sold nine", "an artist who drew the cover", "a reader who kept it for the letters page", "a collector who came up short (the bag is sealed c0mplete_set)"]
const PAST_MARK := ["A pencilled price on the cover, crossed out.", "Spine roll from being read on a bus.", "A coupon cut from the back page.", "Smells of newsprint and a basement.",
	"A store stamp on the inside cover.", "A letter column note: 'Hector, keep writing in!'", "Perfectly flat. Suspiciously flat.", "A fingerprint in ink on the last page."]

const CURSE := {
	"title": "BAGGED & BOARDED",
	"line": "You came up short. The Buyer's grader bags you, boards you and seals you in a slab.",
	"label": "CGX COMICS  •  UNIVERSAL GRADE",
	"case": "comic",
}

const INTRO := {
	"title": "COMICS",
	"sub": "Uncle Hector's world",
	"line": "The back-issue wall. Every book in mylar, every key behind glass. Hector's in the last bag on the left.",
	"scene": "comicshop",
}
