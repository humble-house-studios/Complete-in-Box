#!/usr/bin/env python3
"""Curates sprite packs into assets/sprites/cover/<category>/ (trimmed, max
128 px, palette PNG) and writes scripts/gfx/cover_sprites.gd listing them, for
the cover compositor (CoverComp).
SRC  = Kenney CC0 packs (OpenGameArt mirrors).
SRC2 = pixel-art packs by ansimuz (Gothicvania, Warped City, Sunny Land,
       Cyberpunk Street...), 200 Starships, Ninja Adventure, CraftPix freebies.
Animation strips are cut down to one frame.
Usage: python3 tools/gen_cover_sprites.py SRC_DIR SRC2_DIR"""
import os, sys, glob, shutil
from PIL import Image

SRC = sys.argv[1]
SRC2 = sys.argv[2] if len(sys.argv) > 2 else ""
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/sprites/cover")
TC = "kenney_toonCharacters1"
PICKS = {}

def add(cat, pattern, maxs=128, frames=1, idx=0, pixel=False, src=None, limit=0):
    files = sorted(f for f in glob.glob(os.path.join(src or SRC, pattern)) if "MACOSX" not in f)
    if limit:
        files = files[::max(1, len(files) // limit)][:limit]
    PICKS.setdefault(cat, []).extend((f, maxs, frames, idx, pixel) for f in files)

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

if os.path.isdir(OUT):
    shutil.rmtree(OUT)
manifest = {}
total = 0
for cat, files in PICKS.items():
    os.makedirs(os.path.join(OUT, cat), exist_ok=True)
    seen = set()
    for f, maxs, frames, idx, pixel in files:
        name = os.path.basename(f).replace(" ", "_").replace("(", "").replace(")", "")
        if name in seen:
            name = os.path.basename(os.path.dirname(f)).replace(" ", "_") + "_" + name
        seen.add(name)
        im = Image.open(f).convert("RGBA")
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
