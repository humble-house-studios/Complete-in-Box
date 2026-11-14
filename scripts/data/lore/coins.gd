extends RefCounted
## Rare coins lore: Aunt June's world. No class_name: Flavor preloads it.
## Her letters and epilogue; the rest falls back to the base text.

const SENDER := "june@pawn"
## [subject, body, the Buyer's P.S.]
const LETTERS := [
	["pawn ticket", "Hon,\n\nThe shop's yours. Everything has a tag, and every tag lies by about thirty percent.\n\nI worked for c0mplete_set for nineteen years. Never paid full price for anything. Except once.\n\n- June", "P.S. She paid in full. Eventually. - c0mplete_set"],
	["heads or tails", "Hon,\n\nA coin has two sides and an edge. Collectors forget the edge. That's where the truth gets stamped.\n\nThe appraiser flips one before every visit. I never once saw it land.\n\n- June", "P.S. It always lands. - c0mplete_set"],
	["the strike", "Hon,\n\nCoins get graded too. MS-70 is perfect. Nobody's perfect.\n\nNineteen years I worked beside the appraiser. Never saw him eat, blink or sit down.\n\n- June", "P.S. He sits at night. In his case. - c0mplete_set"],
	["the ledger", "Hon,\n\nI kept his books. Every debt traces back to one line, 1890: one coin, lent to a man who wanted the complete set of everything.\n\nInterest compounds daily. At 4:51 a.m.\n\n- June", "P.S. Interest never sleeps. Neither do I. - c0mplete_set"],
	["the appraiser", "Hon,\n\nI finally asked the appraiser his name. He showed me his own slab label, worn smooth.\n\nLOT 1. 1890. 4:51 A.M. He came up short first. He's graded the rest of us ever since.\n\n- June", "P.S. He's very good at it. He had to be. - c0mplete_set"],
	["mint marks", "Hon,\n\nA tiny letter on a coin tells you where it was struck. His coins carry one I'd never seen. A little frame.\n\nThey were struck in the Gallery.\n\n- June", "P.S. Everything I own comes home eventually. - c0mplete_set"],
	["the haggle", "Hon,\n\nI haggled with him nineteen years. Got him down to one collector per world. Then I came up a dime short.\n\nWorst deal I ever made. I made it for you.\n\n- June", "P.S. She drives a hard bargain. I drive harder. - c0mplete_set"],
	["paid in full", "Hon,\n\nYou can't pay this debt in cash. I tried. Only in full: every line on his want list, one run, no gaps.\n\nPay it in full, hon. And bring a crowbar for my case.\n\n- June", "P.S. Cash is also accepted. Yours. - c0mplete_set"],
]
const EPILOGUE := ["change back", "Hon,\n\nThey cracked my case at 4:51. Counted my fingers. All there. Not bad for a dime short.\n\nNext row, a woman taps a stopped watch on her glass. Elsa. She knows why it's always 4:51. Get her out and she'll tell you.\n\n- June"]
