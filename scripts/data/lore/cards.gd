extends RefCounted
## Trading cards lore: the Pruitt Twins' world. No class_name: Flavor preloads it.
## The twins' letters and epilogue; the rest falls back to the base text.

const INTRO := {
	"title": "TRADING CARDS",
	"sub": "The Pruitt Twins' world",
	"line": "A wall of sealed boxes, a grading counter, and two cases side by side. Share nicely.",
	"line_pre": "A wall of sealed boxes, a grading counter, and the Pruitt twins' binders. Share nicely.",
	"scene": "cardshop",
}

const SENDER := "pruitt.x2"
## [subject, body, the Buyer's P.S.]
const LETTERS := [
	["two of everything", "Hi you,\n\nWe're the twins. Pip writes, Wren corrects. Two of every card: one to play, one to keep.\n\nThat rule kept us safe for years. Then we finished a set. Never finish a set.\n\n- P & W", "P.S. I kept one of each. - c0mplete_set"],
	["pull rates", "Hi you,\n\nEvery box prints its odds. One rare a pack. One holo a box. One grail a case.\n\nHis appraiser has odds too. One collector per world. (We checked. - W)\n\n- P & W", "P.S. Ten worlds. Ten collectors. Excellent odds. - c0mplete_set"],
	["4:51", "Hi you,\n\nThe appraiser came at 4:51 a.m. Both clocks agreed.\n\nHe didn't knock. He stood on the porch sorting us through the window. Holo. Non-holo.\n\n- P & W", "P.S. Punctuality is a courtesy. - c0mplete_set"],
	["the signature", "Hi you,\n\nWe compared his letters under the lamp. Two handwritings. The new one is Arlo's. The old one is spidery, on letters from 1962.\n\nHe isn't a person. He's a position.\n\n- P & W", "P.S. Positions get filled. - c0mplete_set"],
	["error card", "Hi you,\n\nMisprints are worth the most. We found one in his binder: our photo, the wrong name.\n\nYour name. (It's not a misprint. - W)\n\n- P & W", "P.S. I don't print errors. - c0mplete_set"],
	["the trade", "Hi you,\n\nHe offered a trade. One of us goes in the case, the other walks.\n\nWe said no. He said, 'Then both.' Pip says he smiled. He doesn't have a face to smile with. - W", "P.S. You're both right. - c0mplete_set"],
	["the frame", "Hi you,\n\nUnder his vault is a gallery. At the end, an empty frame with a blank brass plate. At 4:51 it shows names.\n\nWe saw ours. Then a third, still being engraved.\n\n- P & W", "P.S. Three makes a set. - c0mplete_set"],
	["complete", "Hi you,\n\nLast card. He can't stand a gap, so give him none: every line on his want list, in one run. A finished set needs no keeper.\n\nOne to play, one to keep. Play. Come get us.\n\n- P & W", "P.S. Two cases, side by side. Still warm. - c0mplete_set"],
]
const EPILOGUE := ["out of the sleeve", "Hi you,\n\nOur case opened at 4:51. Wren cried. Pip didn't. (He did. - W)\n\nOne row down, a lady in a top-loader is knitting with no yarn. Her plate says ROSE. She asked for you by name.\n\nWe never told her your name.\n\n- P & W"]
