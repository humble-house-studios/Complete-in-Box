extends RefCounted
## Rare books lore: Professor Iris Halloway's world. No class_name: Flavor
## preloads it. Iris's letters, marginalia and epilogue are used when you
## inherit her estate; the rest whenever the run deals in books.
##
## The spine: Iris catalogued everything, so she catalogued the Buyer. She
## traced c0mplete_set through a century of bookplates and auction records
## and found the same name on every one. She wrote him a twelve-page letter
## asking what he wanted. He answered in one word: "You." She is shelved
## under H, between two other collectors, in a case like a slipcase.

const COLLECTOR := "Professor Iris"
const SENDER := "i.halloway@faculty"
## Her diary is the notes she pencilled in the margins of her own books.
const DIARY_NAME := "Iris's marginalia"

## [subject, body, the Buyer's P.S.] one per ante.
const LETTERS := [
	["Chapter I: provenance", "Dear reader,\n\nIf this letter has reached you, my library has too. Eleven thousand volumes, every one catalogued in pencil on the back flyleaf. Never ink. Ink is for people who are sure.\n\nThe man who wants them signs c0mplete_set. He does not read. He acquires.\n\nStart with the shelf by the window. That's where I kept the books I could bear to lose.\n\n- I. H.", "P.S. She kept nothing she could bear to lose. Check the window shelf. - c0mplete_set"],
	["Chapter II: condition", "Dear reader,\n\nBooksellers describe condition in a private language. Fine. Near Fine. Very Good, which means not very good. Foxing is the brown freckling of old paper. A cocked spine leans like a tired man.\n\nThe jacket matters more than the book. A naked Gatsby is a hundredth of a dressed one. Vanity, all of it.\n\nThe appraiser reads condition reports for pleasure.\n\n- I. H.", "P.S. He's read yours. Very Good. Which means not very good. - c0mplete_set"],
	["Chapter III: points", "Dear reader,\n\nA first edition is proved by its points: the typo on page 181, the wrong colour cloth, the missing full stop. Mistakes make the money. Correct copies are just books.\n\nI spent twenty years looking for the Buyer's points. The same bookplate in a Folio and a paperback. The same name in every auction record back to 1890.\n\nThe same handwriting, too.\n\n- I. H.", "P.S. Very good, Professor. Twenty years. Most collectors never look. - c0mplete_set"],
	["Chapter IV: the box lot", "Dear reader,\n\nAt every house clearance there's a box nobody wants: sermons, almanacs, a broken encyclopaedia. Buy it. The good book always hides at the bottom, between two Reader's Digests.\n\nI found my own name at the bottom of one once. An index card in my handwriting, dated before I was born. HALLOWAY, I. - SHELVED.\n\nI didn't write it. I don't think I didn't write it.\n\n- I. H.", "P.S. Shelving is a kindness. Nothing on a shelf gets lost. - c0mplete_set"],
	["Chapter V: the clamshell", "Dear reader,\n\nThe finest books are kept in clamshell boxes: cloth over board, lined with felt, the title stamped in gold on the spine. You open the box and the book lies there, perfectly safe, never to be read again.\n\nHe made one for Arlo. Cloth, felt, gold: GRADE 9.8, NEAR FINE IN JACKET.\n\nMine is in the post. I can hear it on the stairs.\n\n- I. H.", "P.S. Measured to fit. You won't feel a thing. - c0mplete_set"],
	["Chapter VI: the catalogue", "Dear reader,\n\nI wrote to him. Twelve pages, footnoted, asking what exactly he wanted with us.\n\nHe answered on a library slip, in one word. I won't write the word here. You'll know it when he says it to you.\n\nHis catalogue has ten volumes, one per world. The last is called THE GALLERY. Every entry has a call number. Mine is filed under H.\n\n- I. H.", "P.S. The word was 'you'. I'm not a man of many words. - c0mplete_set"],
	["Chapter VII: the author", "Dear reader,\n\nEvery book has an author, even the anonymous ones. Pride and Prejudice was 'by a Lady'. Frankenstein had no name on it at all.\n\nThe Buyer's catalogue has no author either. But the bookplate in every volume is a drawing of an old man holding a game cartridge. Underneath: EX LIBRIS A.\n\nYour great-uncle's first name began with A, I believe.\n\n- I. H.", "P.S. Footnote 1: the author is always the last to be credited. - c0mplete_set"],
	["Chapter VIII: the last page", "Dear reader,\n\nThe last page of a catalogue is the index. Here is mine.\n\nHe is not collecting books. He is completing a set: every line of his want list, in one sitting. Fill it, and the catalogue is closed. A closed catalogue stops acquiring.\n\nKeep your spines straight and your jackets unclipped. And when you open the last clamshell, read me aloud. I have been waiting a very long time to be read.\n\n- I. H.", "P.S. Fine. In jacket. As issued. - c0mplete_set"],
]

## [where you found it, the note]. Pencilled in the margins of her own books.
const DIARY := [
	["pencilled in the margin of Paradise Mislaid", "Sept 1979. Bought my first rare book at a church sale for a quarter. Inside the cover, a bookplate: EX LIBRIS c0mplete_set, and a call number. The call number was my student ID. I've told no one."],
	["on the endpaper of a Victorian Parlour lot", "April 1991. Arlo came to borrow a price guide. He asked if I'd ever had a letter from 'the Buyer'. I asked how he knew the word. He put the guide back and left without it."],
	["under a footnote in a Dicshunary", "Nov 2004. Traced his bookplate through a hundred and thirty years of auction records. Same name, same hand, same old man in the drawing. Either he is very old, or he is very many people. Or he is somebody's great-uncle."],
	["in the gutter of the last page of the Gootenberg", "The study door is locked from the outside. I have tea and eleven thousand books. I have read the end of his catalogue. The last call number is not mine. It isn't Arlo's either. It is yours."],
]

const EPILOGUE := ["Afterword", "Dear reader,\n\nThey lifted the lid of the clamshell at dawn and I sat up and sneezed. Felt. Of course it was felt.\n\nThe library is yours: eleven thousand books, and the pencil notes in all of them. Read them. Books are for reading. Cases are for coffins.\n\nNext shelf down, I can hear someone winding a clock that hasn't run in years. Mind the watchmaker; she counts everything twice.\n\nAnd reader: when you reach the Gallery, don't look at the bookplate on the last frame.\n\n- Professor Iris Halloway, emerita"]

const PASS := [
	"The appraiser opens each book to the copyright page. \"First printing. Good.\"",
	"\"Spines tight. Hinges sound.\" He sounds almost happy.",
	"He holds a jacket to the light for a long, long time. \"Not a facsimile.\"",
	"\"Near Fine in a Very Good jacket,\" he writes, twice.",
	"He checks the census of known copies. \"Fewer than twenty. The Buyer likes fewer than twenty.\"",
	"\"No book-club dot. No remainder mark.\" He seems disappointed.",
	"He taps a box lot with his pen. \"Uncatalogued. The professor would approve.\"",
	"\"Collation complete,\" he says, and closes his case.",
	"He reads one sentence aloud from every book. He doesn't seem to enjoy it.",
	"\"First edition,\" he says. \"He collects those too.\"",
	"He slips an acid-free bookmark into his own notebook before he leaves.",
	"\"To be continued in a later printing,\" he says on his way out.",
]
const FAIL := [
	"\"Cocked spine.\" He's looking at your posture.",
	"He finds the book-club dot you hoped he'd miss.",
	"\"Facsimile jacket,\" he says, though it isn't. It doesn't matter.",
	"\"Out of print,\" he reads off his clipboard.",
	"He measures you for a clamshell box. Cloth, felt, gold.",
	"\"The professor came up short in this library too.\"",
	"\"Foxing. Toning at the edges.\" He's not talking about the books.",
	"He reads your total aloud, then the target, slowly, like a footnote.",
	"\"Reading copy,\" he says, and stamps your hand WITHDRAWN.",
	"He writes a call number on a slip and tucks it into your pocket.",
	"\"Every book ends,\" he says. \"Most of them on a shelf.\"",
	"He doesn't shake your hand. He catalogues it.",
]

const SELLER := {
	"estatelib": ["\"Dad's books. Fifty cents a foot, or make me an offer on the wall.\"", "\"He never let us touch those ones. Is that good?\"", "\"Some of them are in Latin. I think that's Latin.\"", "\"There's more in the attic, but the stairs are rotten.\""],
	"booksale": ["\"Hardbacks a dollar, paperbacks a quarter. Bag day starts at four.\"", "\"Please don't scan every book with your phone. It upsets the volunteers.\"", "\"All proceeds go to the new roof.\"", "\"That box came from the library basement. Nobody's opened it.\""],
	"bookshop": ["\"Handle the jackets by the edges, please.\"", "\"We send the good ones out for a proper description. Bring me your firsts.\"", "\"That's the auction record. The record is wrong, but it's the record.\"", "\"The locked case? Ask nicely.\""],
	"bookauction": ["\"Lot 112, first edition, first state, in the jacket. We start at the reserve.\"", "\"From the library of a distinguished collector, recently shelved.\"", "\"A bid on the phone. And another in the room.\"", "\"Fair warning... fair warning...\""],
}
const MOOD := {
	"estatelib": "A dead professor's library, floor to ceiling, and heirs who measure books by the yard.",
	"booksale": "Folding tables, a church hall, and dealers elbowing past the volunteers.",
	"bookshop": "Rolling ladders, a glass case of firsts, and a bookseller who whispers prices.",
	"bookauction": "Catalogued lots, phone bidders and a hammer that never hesitates.",
}
const EVENTS := {
	"box": ["A box of books on the porch", "\"Cleared out my aunt's study. %s and they're yours, I'm not carrying them back.\" Something %s thumps inside."],
	"collector": ["A bibliographer saw your shelf", "\"I'll give you %s cash for that %s. It's the last gap in my census.\" It's worth %s, and it scores on your shelf."],
	"leak": ["Damp in the study", "The ceiling is weeping over your %s. A dehumidifier costs %s. Or the pages cockle and foxing blooms, and that means Reading Copy."],
}
const TIPS := [
	"Iris's rule: pencil, never ink. Ink is for people who are sure.",
	"An author's first book is a debut. The appraiser counts them.",
	"Box lots dig into books from the same shelf of the library.",
	"A Fine copy in the jacket can be worth a hundred times a reading copy.",
	"Book-club editions have no price on the flap and a dot on the back. Worth a third.",
	"Ex-library copies are stamped and pocketed. Somebody loved them. Collectors don't.",
	"The points prove a first: a typo, a wrong colour, a missing full stop.",
	"A facsimile jacket on a real first is the oldest trick in the trade.",
	"Have your firsts described at the bookshop before the appraiser sees them.",
	"Every book ends. Make sure yours ends on a good page.",
]
const PAST_PLACE := ["a professor's study, under H", "a church-hall book sale on bag day", "a country house library sold by the yard", "a lending library's basement",
	"a second-hand bookshop's locked case", "a house clearance in the rain", "a seaside boarding house's bookshelf", "a university library's discard trolley", "a bookseller's going-out-of-business sale", "a damp garage (the top box)"]
const PAST_WHO := ["a reader who underlined every sentence", "a bibliographer with a pencil and a census", "Professor Iris (I. H. pencilled on the back flyleaf)", "a bookseller who never priced it",
	"a speculator who bought ten and kept one", "the author's dentist", "a schoolteacher who read it to three classes", "a collector who came up short (the bookplate reads EX LIBRIS c0mplete_set)"]
const PAST_MARK := ["A pencilled price on the flyleaf, rubbed out.", "A pressed flower between pages 40 and 41.", "A bus ticket used as a bookmark.", "Smells of pipe smoke and a library.",
	"A bookseller's ticket inside the back board.", "Iris's pencil: 'Ask about the binding.'", "Perfectly tight. Suspiciously tight.", "A coffee ring on the front board, faint as a halo."]

const CURSE := {
	"title": "SHELVED & CATALOGUED",
	"line": "You came up short. The Buyer's bibliographer describes you, boxes you in a clamshell and shelves you under H.",
	"label": "c0mplete_set LIBRARY  •  FINE BOOKS",
	"case": "book",
}

const INTRO := {
	"title": "RARE BOOKS",
	"sub": "Professor Iris's world",
	"line": "The locked case at Foxed & Folio. Every first in its jacket, every jacket in mylar. Iris is shelved in the corner, under H.",
	"scene": "bookshop",
}
