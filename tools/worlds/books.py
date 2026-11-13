"""Rare books (Professor Iris Halloway's world) for tools/gen_worlds.py.

Pages / platforms: ANTQ Antiquarian, CLSC 19th-Century Classics, MODF Modern
Firsts, GENR Genre Firsts, KIDS Children's & Illustrated. Kinds: book (one
volume) and booklot (a box lot you can dig through, like a wax box).
List columns used: name = title, detail = why it matters, team = author,
pos = publisher, wiki = the book's page (first-edition covers, title pages).
"""
import re

LIST = "rare_books_top_250.txt"
GRAILS = {"ANTQ": 2, "CLSC": 1, "MODF": 1, "GENR": 1, "KIDS": 1}
## Wikipedia lead images shaped like a book's front are used as the whole front.
COVER_ASPECT = 0.68
PHOTO_ASPECT = 0.9
NO_PHOTO_KINDS = ("booklot",)

## Same value bands as comics and cards so the worlds play alike.
BOOK_BANDS = [(4, 18), (24, 80), (100, 360), (1300, 6000)]
LOT_BANDS = [(18, 50), (60, 160), (180, 560), (1800, 7000)]

## Real titles -> parody titles.
TITLES = {
    "Gutenberg Bible": "Gootenberg Bible", "Shakespeare First Folio": "Shakespear First Folio", "The Birds of America": "The Burds of America",
    "Bay Psalm Book": "Bay Palm Book", "Principia Mathematica": "Principia Mathematicka", "De revolutionibus orbium coelestium": "De Revolutionibus Orbium Celestial",
    "Hypnerotomachia Poliphili": "Hypnero-Tomaccia Poliphilly", "De humani corporis fabrica": "De Humani Corporis Fabricka",
    "Nuremberg Chronicle": "Nurembird Chronicle", "Don Quixote": "Don Quicksote", "Euclid's Elements": "Euclyd's Elements",
    "Paradise Lost": "Paradise Mislaid", "A Dictionary of the English Language": "A Dicshunary of the English Language",
    "Micrographia": "Mikrographia", "Robinson Crusoe": "Robinson Cruiso", "Gulliver's Travels": "Gulliber's Travels",
    "The Wealth of Nations": "The Wealth of Notions", "Common Sense": "Common Cents", "Book of Hours": "Book of Ours",
    "Country House Library Lot": "Country House Library Lot",
    "Tamerlane and Other Poems": "Tamberlane and Other Poems", "On the Origin of Species": "On the Origin of Speeches",
    "Pride and Prejudice": "Pride and Prejudyce", "Frankenstein": "Frankensteen", "Moby-Dick": "Moby-Duck",
    "A Christmas Carol": "A Christmas Carroll", "Leaves of Grass": "Leafs of Grass", "Jane Eyre": "Jane Ayre",
    "Wuthering Heights": "Withering Heights", "Beeton's Christmas Annual": "Beeten's Christmas Annual", "Dracula": "Drackula",
    "Adventures of Huckleberry Finn": "Adventures of Huckleberry Fynn", "Uncle Tom's Cabin": "Uncle Tim's Cabin",
    "The Picture of Dorian Gray": "The Picture of Dorian Grey", "Great Expectations": "Grate Expectations", "Emma": "Emmah",
    "Crime and Punishment": "Crime and Punnishment", "The Time Machine": "The Thyme Machine", "Little Women": "Little Wimmen",
    "Victorian Parlour Book Lot": "Victorian Parlour Book Lot",
    "The Great Gatsby": "The Grate Gatsbee", "Ulysses": "Ulisees", "The Catcher in the Rye": "The Catcher in the Wry",
    "To Kill a Mockingbird": "To Kill a Mockingburd", "Nineteen Eighty-Four": "Nineteen Eighty-Fore", "The Sun Also Rises": "The Sun Also Rizes",
    "The Grapes of Wrath": "The Grapes of Rath", "Invisible Man": "Invisibel Man", "Brave New World": "Brave Knew World",
    "Lolita": "Lolitta", "On the Road": "On the Rode", "Catch-22": "Catch-23", "Their Eyes Were Watching God": "Their Eyes Were Watching the Sky",
    "The Sound and the Fury": "The Sound and the Furry", "Mrs Dalloway": "Mrs Dallowey", "Howl and Other Poems": "Yowl and Other Poems",
    "Gone with the Wind": "Gone with the Wend", "One Hundred Years of Solitude": "One Hundred Years of Solitood", "Beloved": "Beloveth",
    "Book Club Remainders Box": "Book Club Remainders Box",
    "The Hobbit": "The Hobbitt", "The Lord of the Rings": "The Lord of the Wrings", "Casino Royale": "Casino Royal",
    "The Maltese Falcon": "The Maltease Falcon", "The Shadow over Innsmouth": "The Shadow over Inn's Mouth", "Dune": "Doon",
    "The Mysterious Affair at Styles": "The Mysterious Affair at Stiles", "The Big Sleep": "The Big Nap", "Carrie": "Karrie",
    "Foundation": "Foundashun", "Fahrenheit 451": "Farenheight 451", "The Hound of the Baskervilles": "The Hound of the Basketvilles",
    "Do Androids Dream of Electric Sheep?": "Do Androids Dream of Electric Goats?", "Neuromancer": "Neuromantic",
    "A Game of Thrones": "A Game of Thrones-ish", "I, Robot": "Eye, Robot", "Interview with the Vampire": "Interview with the Vampyre",
    "The Hitchhiker's Guide to the Galaxy": "The Hitchhiker's Guide to the Galaxxy", "The Shining": "The Shyning",
    "Pulp Paperback Spinner Lot": "Pulp Paperback Spinner Lot",
    "Harry Potter and the Philosopher's Stone": "Harry Plotter and the Philosopher's Scone", "Alice's Adventures in Wonderland": "Alyce's Adventures in Wunderland",
    "The Tale of Peter Rabbit": "The Tale of Peter Rabbet", "The Wonderful Wizard of Oz": "The Wonderful Wizard of Ozz", "Winnie-the-Pooh": "Winnie-the-Pew",
    "The Cat in the Hat": "The Cat in the Hatt", "The Lion, the Witch and the Wardrobe": "The Lion, the Witch and the Cupboard",
    "The Little Prince": "The Little Prints", "Where the Wild Things Are": "Where the Mild Things Are", "Treasure Island": "Treasure Islund",
    "Charlie and the Chocolate Factory": "Charley and the Chocolate Factory", "The Wind in the Willows": "The Wind in the Pillows",
    "Charlotte's Web": "Charlotte's Webb", "Peter Pan in Kensington Gardens": "Peter Pann in Kensington Gardens",
    "Anne of Green Gables": "Ann of Green Gabels", "Goodnight Moon": "Goodnite Moon", "The Very Hungry Caterpillar": "The Very Hungry Caterpiller",
    "Curious George": "Curious Georg", "Madeline": "Madelyne", "School Library Discard Box": "School Library Discard Box",
}
AUTHORS = {
    "Johannes Gutenberg": "Johannes Gootenberg", "William Shakespeare": "William Shakespear", "John James Audubon": "John James Audobon",
    "Isaac Newton": "Isaac Nooton", "Nicolaus Copernicus": "Nicolaus Copurnicus", "Francesco Colonna": "Francesco Colonnade",
    "Andreas Vesalius": "Andreas Vesalious", "Hartmann Schedel": "Hartmann Shedel", "Miguel de Cervantes": "Miguel de Servantes",
    "Euclid": "Euclyd", "John Milton": "John Miltonn", "Samuel Johnson": "Samuel Johnstone", "Robert Hooke": "Robert Hook",
    "Daniel Defoe": "Daniel Defo", "Jonathan Swift": "Jonathan Swiffed", "Adam Smith": "Adam Smyth", "Thomas Paine": "Thomas Payne",
    "Edgar Allan Poe": "Edgar Allen Po", "Charles Darwin": "Charles Darwyn", "Jane Austen": "Jane Austin", "Mary Shelley": "Mary Shellee",
    "Herman Melville": "Herman Mellville", "Charles Dickens": "Charles Dickins", "Walt Whitman": "Walt Whitmann",
    "Charlotte Brontë": "Charlotte Bronty", "Emily Brontë": "Emily Bronty", "Arthur Conan Doyle": "Arthur Conan Doil",
    "Bram Stoker": "Bram Stoaker", "Mark Twain": "Mark Twayne", "Harriet Beecher Stowe": "Harriet Beecher Stow", "Oscar Wilde": "Oscar Wylde",
    "Fyodor Dostoevsky": "Fyodor Dostoyevski", "H. G. Wells": "H. G. Wels", "Louisa May Alcott": "Louisa May Alcot",
    "F. Scott Fitzgerald": "F. Scot Fitzgerold", "James Joyce": "James Joice", "J. D. Salinger": "J. D. Sallinger", "Harper Lee": "Harper Leigh",
    "George Orwell": "George Orwel", "Ernest Hemingway": "Ernest Hemmingway", "John Steinbeck": "John Steinbek", "Ralph Ellison": "Ralph Elison",
    "Aldous Huxley": "Aldous Huxly", "Vladimir Nabokov": "Vladimir Nabokoff", "Jack Kerouac": "Jack Kerouack", "Joseph Heller": "Joseph Hellur",
    "Zora Neale Hurston": "Zora Neale Hurstonne", "William Faulkner": "William Faulknor", "Virginia Woolf": "Virginia Wolfe",
    "Allen Ginsberg": "Allen Ginsburg", "Margaret Mitchell": "Margaret Mitchel", "Gabriel García Márquez": "Gabriel Garcia Marques",
    "Toni Morrison": "Toni Morisson", "J. R. R. Tolkien": "J. R. R. Tolkeen", "Ian Fleming": "Ian Flemming", "Dashiell Hammett": "Dashiell Hammet",
    "H. P. Lovecraft": "H. P. Lovecroft", "Frank Herbert": "Frank Herbertt", "Agatha Christie": "Agatha Kristie", "Raymond Chandler": "Raymond Chandlor",
    "Stephen King": "Stephen Kingg", "Isaac Asimov": "Isaac Asimoff", "Ray Bradbury": "Ray Bradberry", "Philip K. Dick": "Philip K. Dik",
    "William Gibson": "William Gibsonne", "George R. R. Martin": "George R. R. Martyn", "Anne Rice": "Anne Ryce", "Douglas Adams": "Douglas Addams",
    "J. K. Rowling": "J. K. Rowlands", "Lewis Carroll": "Lewis Carrol", "Beatrix Potter": "Beatrix Plotter", "L. Frank Baum": "L. Frank Bawm",
    "A. A. Milne": "A. A. Milnes", "Dr. Seuss": "Dr. Zeuss", "C. S. Lewis": "C. S. Louis", "Antoine de Saint-Exupéry": "Antoine de Saint-Exupery-ish",
    "Maurice Sendak": "Maurice Sendack", "Robert Louis Stevenson": "Robert Louis Stephenson", "Roald Dahl": "Roald Dall",
    "Kenneth Grahame": "Kenneth Graham", "E. B. White": "E. B. Whyte", "J. M. Barrie": "J. M. Barry", "L. M. Montgomery": "L. M. Montgomerie",
    "Margaret Wise Brown": "Margaret Wise Browne", "Eric Carle": "Eric Karle", "H. A. Rey": "H. A. Ray", "Ludwig Bemelmans": "Ludwig Bemmelmans",
    "Various": "Various hands",
}
PUBS = {
    "Gutenberg & Fust": "Gootenberg & Fust", "Jaggard & Blount": "Jaggerd & Blunt", "Robert Havell": "Robert Haval", "Stephen Daye": "Stephen Day",
    "Royal Society": "Royale Society", "Petreius": "Petreyus", "Aldus Manutius": "Aldus Manootius", "Oporinus": "Oporynus",
    "Anton Koberger": "Anton Koburger", "Juan de la Cuesta": "Juan de la Questa", "Erhard Ratdolt": "Erhard Ratdolf", "Samuel Simmons": "Samuel Simmonds",
    "Strahan": "Strahann", "W. Taylor": "W. Tailor", "Benjamin Motte": "Benjamin Mott", "Strahan & Cadell": "Strahann & Cadel", "Robert Bell": "Robert Belle",
    "Calvin Thomas": "Calvin Tomas", "John Murray": "John Murrey", "T. Egerton": "T. Edgerton", "Lackington": "Lackingtonne", "Harper & Brothers": "Harpur & Brothers",
    "Chapman & Hall": "Chapman & Hal", "self-published": "self-published", "Smith, Elder & Co.": "Smyth, Elder & Co.", "Thomas Cautley Newby": "Thomas Cautley Newbee",
    "Ward Lock": "Ward Lok", "Archibald Constable": "Archibald Constabel", "Chatto & Windus": "Chatto & Windows", "John P. Jewett": "John P. Juett",
    "Lippincott's": "Lippincot's", "The Russian Messenger": "The Russian Messengerr", "Heinemann": "Hyneman", "Roberts Brothers": "Robberts Brothers",
    "Scribner": "Scribbner", "Shakespeare and Company": "Shakespear and Company", "Little, Brown": "Little, Browne", "J. B. Lippincott": "J. B. Lippincot",
    "Secker & Warburg": "Seeker & Warburg", "Viking": "Vikking", "Random House": "Randumb House", "Olympia Press": "Olimpia Press",
    "Simon & Schuster": "Simon & Shooster", "Cape & Smith": "Cape & Smyth", "Hogarth Press": "Hogworth Press", "City Lights": "City Lites",
    "Macmillan": "MacMillun", "Sudamericana": "Sudamerikana", "Knopf": "Knopff", "George Allen & Unwin": "George Allen & Unwind",
    "Jonathan Cape": "Jonathan Capes", "Visionary": "Visionery", "Chilton Books": "Chillton Books", "John Lane": "John Lain", "Doubleday": "Doubledey",
    "Gnome Press": "Gnome Pressed", "Ballantine": "Ballantyne", "George Newnes": "George Noons", "Ace": "Aice", "Bantam": "Bantum", "Pan Books": "Pann Books",
    "Bloomsbury": "Bloomsberry", "privately printed": "privately printed", "George M. Hill": "George M. Hil", "Methuen": "Methuin",
    "Geoffrey Bles": "Geoffrey Blessed", "Reynal & Hitchcock": "Reynal & Hitchcok", "Harper & Row": "Harpur & Row", "Cassell": "Cassel",
    "Hodder & Stoughton": "Hodder & Stoughtonne", "L. C. Page": "L. C. Paige", "World Publishing": "Whirled Publishing",
    "Houghton Mifflin": "Houghton Mufflin", "Various": "Various", "-": "a monastery scriptorium",
}
## Words in the detail line that name real people or products.
DETAIL_SUBS = [("Sherlock Holmes", "Sherlok Holmz"), ("Holmes", "Holmz"), ("Poirot", "Poirott"), ("Philip Marlowe", "Philip Marlow"),
               ("Tolkien", "Tolkeen"), ("Fleming", "Flemming"), ("Lovecraft", "Lovecroft"), ("Christie", "Kristie"), ("Chandler", "Chandlor"),
               ("King's", "Kingg's"), ("Wells's", "Wels's"), ("Melville's", "Mellville's"), ("Whitman", "Whitmann"), ("Poe's", "Po's"),
               ("Darwin", "Darwyn"), ("Newton's", "Nooton's"), ("Hemingway's", "Hemmingway's"), ("Salinger", "Sallinger"), ("Steinbeck's", "Steinbek's"),
               ("Kerouac", "Kerouack"), ("Shepard", "Sheppard"), ("Rackham", "Rackam"), ("Sense and Sensibility", "Cents and Sensibility"),
               ("Currer Bell", "Currer Belle"), ("Ellis Bell", "Ellis Belle"), ("Catch-18", "Catch-19"), ("Prince Regent", "Prince Regent-ish"),
               ("Christie's", "Kristie's")]

BLURB = {
    "ANTQ": ["Calfskin, hand-set type and a smell like a cathedral.", "Older than most countries. Heavier than most dogs.",
             "Somebody's name is written on the flyleaf in iron-gall ink, three hundred years ago.",
             "The pages are rag paper: they'll outlast the building they're in."],
    "CLSC": ["Cloth boards, gilt on the spine, and a lending-library label inside the cover.",
             "Most copies were read to bits in circulating libraries. This one survived.",
             "Three volumes, uncut pages, foxing like freckles.", "A Victorian bestseller. Now it's a museum piece."],
    "MODF": ["The dust jacket is worth more than the book under it.", "First edition, first printing, and the price still on the flap.",
             "The points are all there: the typo, the bad page number, the right binding.", "Bought new for two dollars by someone who never cracked the spine."],
    "GENR": ["Dismissed as trash when it came out. Now it lives behind glass.", "A small first printing: the publisher didn't think it would sell.",
             "Lurid jacket, cheap paper, and a fan club that will pay anything.", "The book that started a genre. Or at least a franchise."],
    "KIDS": ["Most copies were loved to death by children. That's the problem.", "Crayon on the endpapers, a name in pencil, a story everybody knows.",
             "Libraries bought the first printing and stamped every one.", "Picture-book first editions survive about as well as birthday cake."],
}
LOT_BLURB = ["A cardboard box of books from a house clearance, taped shut. Smells like a church.",
             "Somebody's whole library, packed by a removal man who didn't read.",
             "Heavy enough to hurt. Damp at one corner. The professor would open it anyway.",
             "Iris's pencil on the lid: UNCATALOGUED."]
## The forgeries and dodges rare books are known for.
TELLS_KNOWN = {
    "The Great Gatsby": "Facsimile dust jackets everywhere: the real one says 'jay Gatsby' in lower case on the back.",
    "Harry Potter and the Philosopher's Stone": "First printing: 'Joanne Rowling' on the copyright page, '1 wand' twice in the list, 10 9 8 7 6 5 4 3 2 1.",
    "The Hobbit": "Later printings have a different jacket blurb: check for the 'Dodgson' misprint on the flap.",
    "The Catcher in the Rye": "Book club copies look identical. Feel for the blind stamp dot on the back board.",
    "Shakespeare First Folio": "Leaves 'made up' from other copies, washed and inlaid to look whole.",
    "The Sun Also Rises": "First state has 'stoppped' with three p's on page 181.",
    "Tamerlane and Other Poems": "Forgers have tried this one for a century. The real wrappers are tea-coloured and nearly blank.",
}
TELLS = {
    "book": ["A facsimile dust jacket on a real first: jackets are half the value.", "A book-club edition passed off as a first: no price on the flap.",
             "Later printing with the number line doctored.", "Remainder mark on the bottom edge, inked out.", "Signature 'signed' by a secretary.",
             "Plates cut out and sold separately: count them.", "Rebacked: a new spine on old boards.", "Ex-library stamps bleached off the title page."],
    "booklot": ["Picked over: the firsts were pulled before you got here.", "Stacked in a damp garage: mildew and foxing.", "Taped twice. Somebody looked."],
}


def _detail(s):
    for a, b in DETAIL_SUBS:
        s = s.replace(a, b)
    return s


def make_item(r, tier, frac, u):
    h = u["h"]
    real = r["name"]
    code = r["code"]
    kind = "booklot" if r["kind"] == "booklot" else "book"
    pname = TITLES.get(real, real)
    tags = list(r["tags"])
    if kind == "booklot":
        tags.append("box")
    iid = code.lower() + "_" + u["slug"](pname)
    author = AUTHORS.get(r["team"], r["team"])
    d = {"id": iid, "name": pname, "plat": code, "kind": kind, "tier": tier,
         "base": u["base_for"](LOT_BANDS if kind == "booklot" else BOOK_BANDS, tier, frac, real),
         "tags": tags, "real_section": r["section"], "pub": PUBS.get(r["pos"], r["pos"]), "genre": "Book",
         "set": pname, "author": author, "note": _detail(r["detail"]), "wiki": r["wiki"]}
    if kind == "booklot":
        d["blurb"] = LOT_BLURB[h(real + "b", len(LOT_BLURB))]
        d["count"] = 40 + h(real + "c", 80)
        d["rarity"] = "Box Lot"
        d["tell"] = TELLS["booklot"][h(real + "t", len(TELLS["booklot"]))]
    else:
        d["blurb"] = _detail(r["detail"]) + ". " + BLURB[code][h(real + "b", len(BLURB[code]))]
        d["rarity"] = "Author's Debut" if "debut" in tags else ["Reading Copy", "Collectable", "Sought After", "Cornerstone"][tier]
        d["tell"] = TELLS_KNOWN.get(real, TELLS["book"][h(real + "t", len(TELLS["book"]))])
        lo, hi = {"ANTQ": (300, 1200), "CLSC": (220, 640), "MODF": (180, 480), "GENR": (160, 520), "KIDS": (24, 260)}[code]
        d["pages"] = lo + h(real + "p", hi - lo)
        # Old books were bound in leather or cloth; modern firsts wear a jacket.
        d["binding"] = "leather" if r["year"] < 1800 else ("cloth" if r["year"] < 1920 and "jacket" not in tags else "jacket")
        if "paperback original" in r["detail"].lower():
            d["binding"] = "paperback"
    # Print runs: incunabula in the hundreds, modern firsts in the thousands.
    if r["year"] < 1700:
        d["run"] = 50 + h(real + "run", 900)
    elif r["year"] < 1900:
        d["run"] = 500 + h(real + "run", 4500)
    else:
        ranges = [(40000, 120000), (8000, 40000), (2000, 8000), (300, 2000)]
        lo, hi = ranges[tier]
        d["run"] = lo + h(real + "run", hi - lo)
    if real.startswith("Harry Potter"):
        d["run"] = 500
    if real == "The Hobbit":
        d["run"] = 1500
    d["rating"] = ""
    return d
