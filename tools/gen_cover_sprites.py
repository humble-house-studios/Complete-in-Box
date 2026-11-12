#!/usr/bin/env python3
"""Curates sprite packs into assets/sprites/cover/<category>/ (trimmed, max
128 px, palette PNG) and writes scripts/gfx/cover_sprites.gd listing them, for
the cover compositor (CoverComp).
SRC  = Kenney CC0 packs (OpenGameArt mirrors).
SRC2 = pixel-art packs by ansimuz (Gothicvania, Warped City, Sunny Land,
       Cyberpunk Street...), 200 Starships, Ninja Adventure, CraftPix freebies.
SRC3 = character art from GitHub: Superpowers asset packs (CC0), Battle for
       Wesnoth units (GPL, team colour recoloured), Tuxemon monsters
       (CC-BY-SA), SuperTux creatures (GPL/CC-BY-SA), Freedoom monsters (BSD),
       Shattered Pixel Dungeon (GPL).
Animation strips and sheets are cut down to one frame.
Usage: python3 tools/gen_cover_sprites.py SRC_DIR SRC2_DIR SRC3_DIR"""
import os, sys, glob, shutil
from PIL import Image

SRC = sys.argv[1]
SRC2 = sys.argv[2] if len(sys.argv) > 2 else ""
SRC3 = sys.argv[3] if len(sys.argv) > 3 else ""
import re, random
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/sprites/cover")
TC = "kenney_toonCharacters1"
PICKS = {}

def add(cat, pattern, maxs=128, frames=1, idx=0, pixel=False, src=None, limit=0, cut=None):
    """frames: cells across a strip (-1 = square cells); cut: (x, y, w, h)
    crop, "blob" (first sprite of a sheet), or ("tc", rgb) team colour."""
    files = sorted(f for f in glob.glob(os.path.join(src or SRC, pattern), recursive=True) if "MACOSX" not in f)
    if limit:
        files = files[::max(1, len(files) // limit)][:limit]
    PICKS.setdefault(cat, []).extend((f, maxs, frames, idx, pixel, cut) for f in files)

def gh(cat, pattern, maxs=128, cut=None, limit=0, pixel=True, files=None):
    """Character art from SRC3 (GitHub repos)."""
    if not SRC3:
        return
    if files is not None:
        PICKS.setdefault(cat, []).extend((os.path.join(SRC3, f), maxs, 1, 0, pixel, cut) for f in files)
    else:
        add(cat, pattern, maxs, 1, 0, pixel, SRC3, limit, cut)

def first_blob(im):
    """The first sprite on a sheet: the top-left large connected shape, plus
    any loose bits (weapons, hats) touching its box."""
    a = im.getchannel("A")
    w, h = im.size
    px = a.load()
    seen = bytearray(w * h)
    comps = []
    for y in range(h):
        for x in range(w):
            if seen[y * w + x] or px[x, y] <= 8:
                continue
            stack = [(x, y)]
            seen[y * w + x] = 1
            x0 = x1 = x
            y0 = y1 = y
            n = 0
            while stack:
                cx, cy = stack.pop()
                n += 1
                x0, x1, y0, y1 = min(x0, cx), max(x1, cx), min(y0, cy), max(y1, cy)
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < w and 0 <= ny < h and not seen[ny * w + nx] and px[nx, ny] > 8:
                            seen[ny * w + nx] = 1
                            stack.append((nx, ny))
            comps.append((x0, y0, x1 + 1, y1 + 1, n))
    if not comps:
        return im
    big = max(c[4] for c in comps)
    main = [c for c in comps if c[4] >= big * 0.3]
    hh = sorted(c[3] - c[1] for c in main)[len(main) // 2]
    first = min(main, key=lambda c: (c[1] // max(1, hh), c[0]))
    fx0, fy0, fx1, fy1 = bx0, by0, bx1, by1 = first[:4]
    for c in comps:
        # Bits overlapping the shape's own box (not a growing one, or a whole
        # row of touching frames would chain together).
        if c is not first and c[0] < fx1 and c[2] > fx0 and c[1] < fy1 and c[3] > fy0 and c[4] < first[4]:
            bx0, by0, bx1, by1 = min(bx0, c[0]), min(by0, c[1]), max(bx1, c[2]), max(by1, c[3])
    out = im.crop((bx0, by0, bx1, by1))
    # Frames that touch each other come out as a strip: take its first cell.
    for _ in range(2):
        if out.width > out.height * 1.45:
            out = out.crop((0, 0, out.width // max(1, round(out.width / (out.height * 1.1))), out.height))
        elif out.height > out.width * 2.2:
            out = out.crop((0, 0, out.width, out.height // max(1, round(out.height / (out.width * 1.2)))))
        bb = out.getbbox()
        if bb:
            out = out.crop(bb)
    return out


def team_colour(im, rgb):
    """Wesnoth marks team colour in magenta: repaint it."""
    im = im.copy()
    p = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = p[x, y]
            if a and r > g + 40 and b > g + 30 and abs(r - b) < 110:
                k = (r + b) / 2 / 255.0
                p[x, y] = (min(255, int(rgb[0] * k + g)), min(255, int(rgb[1] * k + g)), min(255, int(rgb[2] * k + g)), a)
    return im

def px(cat, pattern, maxs=128, frames=1, idx=0, limit=0):
    """Pixel art from SRC2: kept crisp (nearest only)."""
    if SRC2:
        add(cat, pattern, maxs, frames, idx, True, SRC2, limit)

poses = ["idle", "cheer0", "cheer1", "jump", "kick", "attack0", "attackKick", "run0", "show", "hold", "think", "walk0", "slide", "fall", "interact"]
for who, cat in [("Male person", "hero_person"), ("Female person", "hero_person"), ("Male adventurer", "hero_adventurer"),
                 ("Female adventurer", "hero_adventurer"), ("Robot", "hero_robot"), ("Zombie", "hero_zombie")]:
    for p in poses:
        add(cat, f"{TC}/{who}/PNG/Poses/*_{p}.png")
add("hero_cute", "platformerGraphicsDeluxe_Updated/Player/p*_front.png")
add("hero_cute", "platformerGraphicsDeluxe_Updated/Player/p*_jump.png")
add("hero_cute", "JumperPack_Kenney/PNG/Players/bunny*_stand.png")
add("hero_cute", "JumperPack_Kenney/PNG/Players/bunny*_jump.png")
add("hero_cute", "Abstract_Platformer_370_assets/PNG/Players/Player */*_front.png")
add("hero_cute", "Abstract_Platformer_370_assets/PNG/Players/Player */*_jump.png")
for e in ["slimeWalk1", "flyFly1", "snailWalk1", "fishSwim1", "blockerMad", "pokerMad"]:
    add("enemy", f"platformerGraphicsDeluxe_Updated/Enemies/{e}.png", 96)
for e in ["flyMan_fly", "spikeMan_stand", "wingMan1", "springMan_stand", "spikeBall1", "sun1"]:
    add("enemy", f"JumperPack_Kenney/PNG/Enemies/{e}.png", 96)
add("enemy", "Abstract_Platformer_370_assets/PNG/Enemies/enemy*_1.png", 96)
add("enemy", "Abstract_Platformer_370_assets/PNG/Enemies/enemy*_3.png", 96)
add("animal", "kenney_animalPackRedux/PNG/Round/*.png", 96)
add("fish", "Fish/Fish/*.png", 96)
add("ship", "SpaceShooterRedux/PNG/playerShip*.png", 96)
add("ship", "SpaceShooterRedux/PNG/ufo*.png", 96)
add("ship", "Alien_UFO_pack/PNG/ship*_manned.png", 96)
add("enemy_ship", "SpaceShooterRedux/PNG/Enemies/*.png", 96)
add("meteor", "SpaceShooterRedux/PNG/Meteors/meteor*_big*.png", 96)
add("meteor", "SpaceShooterRedux/PNG/Meteors/meteor*_med*.png", 64)
add("vehicle", "racing-pack/PNG/Cars/car_*_1.png", 96)
add("vehicle", "racing-pack/PNG/Cars/car_*_3.png", 96)
add("vehicle", "racing-pack/PNG/Motorcycles/*.png", 96)
for n in ["castleSmall", "castleSmallAlt", "castleWall", "tower", "towerAlt", "towerSmall", "pyramid", "pyramidMayan"]:
    add("building_fantasy", f"Background_Elements_Redux/PNG/Default/{n}.png", 128)
for n in ["house1", "house2", "houseAlt1", "houseAlt2", "houseSmall1", "houseSmall2", "fence", "fenceIron"]:
    add("building_town", f"Background_Elements_Redux/PNG/Default/{n}.png", 128)
add("tree", "Background_Elements_Redux/PNG/Default/tree*.png", 128)
add("tree", "Background_Elements_Redux/PNG/Default/bush*.png", 64)
add("tree", "Background_Elements_Redux/PNG/Default/cactus*.png", 96)
add("cloud", "Background_Elements_Redux/PNG/Default/cloud*.png", 96)
add("sky_body", "Background_Elements_Redux/PNG/Default/sun.png", 96)
add("sky_body", "Background_Elements_Redux/PNG/Default/moon*.png", 96)
for n in ["coinGold", "gemBlue", "gemGreen", "gemRed", "gemYellow", "keyYellow", "keyRed", "star", "mushroomRed", "mushroomBrown", "bomb", "fireball", "flagRed", "flagBlue"]:
    add("item", f"platformerGraphicsDeluxe_Updated/Items/{n}.png", 64)
add("item", "SpaceShooterRedux/PNG/Power-ups/powerup*_bolt.png", 48)
add("item", "SpaceShooterRedux/PNG/Power-ups/star_*.png", 48)
add("backdrop", "platformerGraphicsDeluxe_Updated/bg*.png", 200)
add("backdrop", "Abstract_Platformer_370_assets/PNG/Backgrounds/set*_background.png", 200)
add("backdrop", "JumperPack_Kenney/PNG/Background/bg_layer*.png", 200)
add("hills", "Abstract_Platformer_370_assets/PNG/Backgrounds/set*_hills.png", 200)


# ---- second wave: pixel-art packs -------------------------------------------
GV = " gothicvania patreon collection"
GVP = "gothicvania_patreon_collection/" + GV
CEM = "gothicvania-cemetery-files_1/gothicvania-cemetery-files/PNG"
WC = "warped_city_files/warped city files"
SL = "sunny-land-files/Sunny-land-assets-files/PNG"
for a in ["hero-idle/hero-idle-1", "hero-attack/hero-attack-3", "hero-jump/hero-jump-2", "hero-run/hero-run-3", "hero-crouch/hero-crouch"]:
    px("hero_gothic", f"{CEM}/Sprites/hero/{a}.png")
for d in ["jump-attack", "crouch-slash", "climb"]:
    px("hero_gothic", f"{GVP}/Gothic-hero-p2-Files/PNG/sprites/{d}/*_0002_*.png")
px("hero_gothic", f"{GVP}/Gothic-hero-Files/PNG/gothic-hero-idle.png", frames=4)
px("hero_gothic", f"{GVP}/Gothic-hero-Files/PNG/gothic-hero-attack.png", frames=6, idx=3)
px("hero_gothic", f"{GVP}/Gothic-hero-Files/PNG/gothic-hero-run.png", frames=12, idx=4)
for m in ["skeleton/skeleton-1", "skeleton-clothed/skeleton-clothed-3", "skeleton-rise/skeleton-rise-4", "ghost/ghost-1", "ghost-halo/ghost-halo-2", "hell-gato/hell-gato-1"]:
    px("monster_gothic", f"{CEM}/Sprites/{m}.png")
px("monster_gothic", f"{GVP}/Hell-Hound-Files/PNG/hell-hound-idle.png", frames=6)
px("monster_gothic", f"{GVP}/Hell-Beast-Files/PNG/with-stroke/hell-beast-idle.png", frames=6)
px("monster_gothic", f"{GVP}/demon-Files/PNG/demon-idle.png", frames=6)
px("monster_gothic", f"{GVP}/demon-Files/PNG/demon-attack.png", frames=11, idx=7)
px("monster_gothic", f"{GVP}/Nightmare-Files/PNG/nightmare-galloping.png", frames=4, idx=1)
px("monster_gothic", f"{GVP}/Ghost-Files/PNG/ghost-idle.png", frames=7)
px("monster_gothic", f"{GVP}/Fire-Skull-Files/PNG/fire-skull.png", frames=8)
for b in "123":
    px("boss", f"bosses-pixel-art-sprite-sheet-pack/{b}/Idle.png", frames=4)
    px("boss", f"bosses-pixel-art-sprite-sheet-pack/{b}/Attack1.png", frames=-1, idx=2)
for m in ["witch", "zombie"]:
    px("monster_gothic", f"monsters_1/{m}.png", frames=-1, idx=0)
for m, n in [("bat", 3), ("ghost", 3), ("frog", 3), ("skeleton", 4)]:
    px("monster_chibi", f"chibi-monsters-files/chibi-monsters-files/Sprites/{m}.png", frames=n)
for a in ["idle/idle-1", "run-shoot/run-shoot-3", "jump/jump-2", "shoot/shoot", "back-jump/back-jump-2", "climb/climb-1"]:
    px("hero_cyber", f"{WC}/SPRITES/player/{a}.png")
for who in ["1 Biker/Biker", "2 Punk/Punk", "3 Cyborg/Cyborg"]:
    px("hero_cyber", f"3_cyberpunk_characters/{who}_idle.png", frames=4)
    px("hero_cyber", f"3_cyberpunk_characters/{who}_run.png", frames=6, idx=2)
    px("hero_cyber", f"3_cyberpunk_characters/{who}_attack3.png", frames=8, idx=4)
    px("hero_cyber", f"3_cyberpunk_characters/{who}_punch.png", frames=6, idx=3)
px("hero_cyber", "megabot_assets_files/megabot/png files/player/idle.png")
for m in ["drone/drone-1", "turret/turret-1"]:
    px("foe_cyber", f"{WC}/SPRITES/misc/{m}.png")
px("foe_cyber", "megabot_assets_files/megabot/png files/enemy/enemy1.png")
for a in ["idle/player-idle-1", "jump/player-jump-1", "run/player-run-3", "climb/player-climb-1"]:
    px("hero_pixel", f"{SL}/sprites/player/{a}.png")
for a in ["walk-side/walk-side-1", "run-down/run-down-2", "walk-front-lift/walk-front-lift-1", "run-side/run-side-3"]:
    px("hero_pixel", f"legend_of_faune_files/legend of faune files/Sprites/Player/sprites/{a}.png")
for a in ["Idle__000", "Run__003", "Jump_Attack__004", "Attack__004", "Throw__002", "Jump__004", "Slide__002", "Jump_Throw__003"]:
    add("hero_ninja", f"NinjaAdventure/png/{a}.png", 128, src=SRC2)
for a in ["frog/idle/frog-idle-1", "opossum/opossum-1", "eagle/eagle-attack-1", "frog/jump/frog-jump-1"]:
    px("critter", f"{SL}/sprites/{a}.png")
px("item", f"{SL}/sprites/cherry/cherry-1.png")
px("item", f"{SL}/sprites/gem/gem-1.png")
add("ship", "200Starships/200Starships/Shaded/ship_1*.png", 96, src=SRC2, limit=30)
add("enemy_ship", "200Starships/200Starships/Shaded/ship_[2-9]*.png", 96, src=SRC2, limit=30)
for f in ["gothic-castle-background", ]:
    px("backdrop_gothic", f"{GVP}/Gothic-Castle-Files/PNG/layers/{f}.png", 336)
for f in ["background"]:
    px("backdrop_gothic", f"{CEM}/Environment/{f}.png", 336)
for f in ["bg-graveyard"]:
    px("backdrop_gothic", f"gothicvania-cemetery-files_1/gothicvania-cemetery-files/demo/assets/environment/{f}.png", 336)
px("backdrop_gothic", f"{GVP}/night-town-background-files/night-town-background-previewx1.png", 336)
for f in ["bg-1", "bg-2"]:
    px("backdrop_cyber", f"{WC}/demo/assets/environment/{f}.png", 336)
for f in ["skyline-a", "skyline-b", "near-buildings-bg"]:
    px("backdrop_cyber", f"{WC}/ENVIRONMENT/background/{f}.png", 336)
for f in ["back-buildings", "far-buildings"]:
    px("backdrop_cyber", f"cyberpunk-street-files/cyberpunk-street-files/PNG/layers/{f}.png", 336)
px("backdrop_cyber", "cyberpunk-street-files/cyberpunk-street-files/PNG/cyberpunk-street.png", 336)
px("backdrop_cyber", "megabot_assets_files/megabot/png files/bg.png", 336)
px("backdrop_nature", f"{SL}/environment/layers/back.png", 336)
px("backdrop_nature", "Magic-Cliffs-Environment/Magic-Cliffs-Environment/PREVIEWS/magic-cliffs-PREVIEWx1.png", 336)
px("backdrop_nature", "Magic-Cliffs-Environment/Magic-Cliffs-Environment/PNG/sky.png", 336)
px("backdrop_nature", "fort_of_illusion_files/Fort of Illusion Files/Previews/Fort-of-Illusion.png", 336)
px("backdrop_nature", "fort_of_illusion_files/Fort of Illusion Files/Layers/mountains.png", 336)
for f in ["tree-1", "tree-3", "statue", "stone-1", "stone-3", "bush-large"]:
    px("scenery_gothic", f"{CEM}/Environment/sliced-objects/{f}.png")
px("tree", "legend_of_faune_files/legend of faune files/Environment/PNG/tree.png")
for f in ["antenna", "hotel-sign", "banner-big/banner-big-1", "banner-neon/banner-neon-1", "banner-side/banner-side-2", "control-box-3"]:
    px("scenery_cyber", f"{WC}/ENVIRONMENT/props/{f}.png")

# ---- third wave: character art from open-source games on GitHub ------------
SP = "superpowers-asset-packs"
for n in ["caverman", "caverman-2", "egg-shell", "egg-shell-2", "girl", "girl-2", "lion", "lion-2"]:
    gh("hero_toon", f"{SP}/prehistoric-platformer/characters/playable/{n}.png", cut="blob")
for n in ["blacksmith", "hunter", "warrior", "old-man", "dragon-man", "little-boy", "girl-1", "boy-1"]:
    gh("hero_toon", f"{SP}/prehistoric-platformer/characters/npc/{n}.png", cut="blob")
for n in ["tyrannosaurus-1", "tyrannosaurus-2", "mini-tyrannosaurus-1", "pterodactyl-1", "plant-1", "lizard-2", "turtle-1", "insect-1", "dragon-1", "bat-2"]:
    gh("monster_big", f"{SP}/prehistoric-platformer/monsters/{n}.png", cut="blob")
for n in ["boar", "giant", "octopus", "yeti", "chest"]:
    gh("monster_big", f"{SP}/rpg-battle-system/monster/{n}.png")
for n, wh in [("dragon/sprite-sheet-2-258x209", (258, 209)), ("mimic/sprite-sheet-231x172", (231, 172)), ("mushroom/sprite-sheet-192x163", (192, 163)),
              ("ghost/sprite-sheet-112x93", (112, 93)), ("slime/sprite-sheet-141x107", (141, 107)), ("snake/sprite-sheet-147x94", (147, 94)),
              ("bat/sprite-sheet-121x89", (121, 89)), ("dino/sprite-sheet-154x118", (154, 118)), ("reptile/sprite-sheet- 248x151", (248, 151))]:
    gh("monster_big", f"{SP}/rpg-battle-system/monster/{n}.png", cut=(0, 0) + wh)
gh("hero_fantasy", f"{SP}/rpg-battle-system/char/Wizard.png")
for k in range(1, 15):
    gh("hero_western", f"{SP}/western-fps-2d/characters/{k}.png", cut="blob")
for k in range(1, 7):
    gh("critter", f"{SP}/western-fps-2d/animals/{k}.png", cut="blob")
gh("portrait", f"{SP}/ninja-adventure/characters/faceset/[0-9]*.png")
for k in [1, 2, 3, 5, 6, 7, 9, 10, 12, 14, 16, 18, 20, 22, 24]:
    gh("hero_tiny", f"{SP}/ninja-adventure/characters/{k}.png", cut=(0, 0, 16, 16))
for k in range(1, 23, 2):
    gh("monster_chibi", f"{SP}/ninja-adventure/monsters/{k}.png", cut=(0, 0, 16, 16))
for k in [1, 3, 4, 7, 8, 9]:
    gh("ship", f"{SP}/space-shooter/ships/{k}.png")
# Battle for Wesnoth: base unit portraits, recoloured into team colours.
if SRC3:
    U = os.path.join(SRC3, "wesnoth/data/core/images/units")
    bad = re.compile(r"(attack|defend|die|death|melee|ranged|idle|magic|leading|bob|fly|moving|breath|fire|blade|sword|bow|staff|spear|heal|hit|run|ColorMap|-[nsew]{1,2}(-|$)|\d|dying|cast|hide|swim|sling|axe|whip|club|dagger|knife|mace|lance|torch|throw|net|kick|shoot|crossbow|charge|slam|teleport|lightning|curse|halo|glow|shield|mask|thrust|claw|bite|fang|smash|stomp|crush|spit|sting|tail|wing|shadow|soar|flag|-lo|low|water|victory|default|sink|fog)")
    def units(dirs, n, seed):
        fs = []
        for d in dirs:
            fs += [f for f in glob.glob(os.path.join(U, d, "**/*.png"), recursive=True) if not bad.search(os.path.basename(f)[:-4])]
        fs.sort()
        random.Random(seed).shuffle(fs)
        return [os.path.relpath(f, SRC3) for f in fs[:n]]
    TEAMS = [(220, 30, 30), (40, 90, 230), (40, 170, 60), (150, 50, 200), (240, 140, 20), (20, 170, 180)]
    for i, f in enumerate(units(["human-loyalists", "human-magi", "human-outlaws", "elves-wood", "dwarves", "merfolk", "dunefolk", "human-peasants"], 40, 1)):
        gh("hero_fantasy", None, cut=("tc", TEAMS[i % 6]), files=[f])
    for i, f in enumerate(units(["orcs", "goblins", "trolls", "ogres", "undead", "undead-skeletal", "undead-necromancers", "undead-spirit", "drakes", "nagas", "saurians", "woses", "bats"], 40, 2)):
        gh("foe_fantasy", None, cut=("tc", TEAMS[(i + 3) % 6]), files=[f])
    for f in units(["monsters"], 30, 3):
        gh("monster_big", None, cut=("tc", TEAMS[0]), files=[f])
# Tuxemon: the front view of each monster.
gh("monster_cute", "tuxemon/mods/tuxemon/gfx/sprites/battle/*-sheet.png", cut=(0, 0, 64, 64), limit=60)
gh("hero_tiny", "tuxemon/mods/tuxemon/gfx/sprites/player/adventurer*.png", cut="blob")
# SuperTux creatures: one walking frame each.
if SRC3:
    for d in sorted(glob.glob(os.path.join(SRC3, "supertux/data/images/creatures/*/"))):
        name = os.path.basename(d.rstrip("/"))
        if name in ["overlays", "iceblock", "crusher", "dispenser", "darttrap", "stalactite", "bag", "laptop", "totem", "kugelblitz", "flame", "dive_mine", "willowisp", "angrystone", "tumbleweed", "ghoul", "short_fuse", "gold_bomb", "livefire"]:
            continue
        for pat in ["left-0.png", "walk-0.png", "idle-0.png", "*left*-0.png", "*walk*-0.png", "*-0.png", "*.png"]:
            hits = sorted(glob.glob(os.path.join(d, "**", pat), recursive=True))
            if hits:
                gh("hero_cute" if name in ["tux", "penny", "nolok"] else "monster_cute", None, files=[os.path.relpath(hits[0], SRC3)], pixel=False)
                break
# Freedoom monsters, front view (frame A, angle 1).
for n in ["poss", "spos", "cpos", "troo", "sarg", "head", "boss", "bos2", "skul", "fatt", "cybr", "spid", "bspi", "pain", "skel", "vile"]:
    gh("foe_doom", f"freedoom/sprites/{n}a1.png")
# Shattered Pixel Dungeon: first frame of each sheet.
for n in ["rat", "gnoll", "skeleton", "golem", "succubus", "king", "tengu", "dm300", "monk", "necromancer", "ghoul", "elemental", "scorpio", "brute", "shaman", "eye", "crab", "slime", "goo", "warlock", "wraith", "imp", "bat", "snake", "guard"]:
    gh("monster_chibi", f"spd/core/src/main/assets/sprites/{n}.png", cut="blob")

if os.path.isdir(OUT):
    shutil.rmtree(OUT)
manifest = {}
total = 0
for cat, files in PICKS.items():
    os.makedirs(os.path.join(OUT, cat), exist_ok=True)
    seen = set()
    for f, maxs, frames, idx, pixel, cut in files:
        name = os.path.basename(f).replace(" ", "_").replace("(", "").replace(")", "")
        if name in seen:
            name = os.path.basename(os.path.dirname(f)).replace(" ", "_") + "_" + name
        seen.add(name)
        im = Image.open(f).convert("RGBA")
        if cut == "blob":
            im = first_blob(im)
        elif isinstance(cut, tuple) and cut[0] == "tc":
            im = team_colour(im, cut[1])
            name = name.replace(".png", "_%s.png" % os.path.basename(os.path.dirname(f)))
        elif isinstance(cut, tuple):
            im = im.crop((cut[0], cut[1], cut[0] + cut[2], cut[1] + cut[3]))
        n = frames if frames > 0 else max(1, round(im.width / im.height))
        if n > 1:
            fw = im.width // n
            im = im.crop((fw * idx, 0, fw * (idx + 1), im.height))
            name = name.replace(".png", "_f%d.png" % idx)
        bb = im.getbbox()
        if bb:
            im = im.crop(bb)
        if cat.startswith("backdrop_") and im.width > im.height * 1.1:
            # Covers are portrait: keep a square-ish window from the middle.
            cw = int(im.height * 1.0)
            x0 = (im.width - cw) // 2
            im = im.crop((x0, 0, x0 + cw, im.height))
        s = maxs / max(im.size)
        if s < 1:
            im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.NEAREST if pixel else Image.LANCZOS)
        im = im.quantize(colors=64, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
        dst = os.path.join(OUT, cat, name)
        im.save(dst, optimize=True)
        total += os.path.getsize(dst)
        manifest.setdefault(cat, []).append("res://assets/sprites/cover/%s/%s" % (cat, name))
lines = ["class_name CoverSprites", "extends RefCounted",
         "## GENERATED by tools/gen_cover_sprites.py: sprites for box covers, by category.", "",
         "const SPRITES := {"]
for cat, paths in manifest.items():
    lines.append('\t"%s": [' % cat)
    for p in paths:
        lines.append('\t\t"%s",' % p)
    lines.append("\t],")
lines.append("}")
open(os.path.join(ROOT, "scripts/gfx/cover_sprites.gd"), "w").write("\n".join(lines) + "\n")
print({k: len(v) for k, v in manifest.items()}, "bytes", total)
