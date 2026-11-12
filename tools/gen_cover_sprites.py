#!/usr/bin/env python3
"""Curates CC0 Kenney sprite packs (downloaded to SRC) into
assets/sprites/cover/<category>/ (trimmed, max 128 px, palette PNG) and writes
scripts/gfx/cover_sprites.gd listing them, for BoxArt's cover compositor.
Usage: python3 tools/gen_cover_sprites.py SRC_DIR"""
import os, sys, glob, shutil
from PIL import Image

SRC = sys.argv[1]
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets/sprites/cover")
TC = "kenney_toonCharacters1"
PICKS = {}

def add(cat, pattern, maxs=128):
    files = sorted(glob.glob(os.path.join(SRC, pattern)))
    PICKS.setdefault(cat, []).extend((f, maxs) for f in files)

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

if os.path.isdir(OUT):
    shutil.rmtree(OUT)
manifest = {}
total = 0
for cat, files in PICKS.items():
    os.makedirs(os.path.join(OUT, cat), exist_ok=True)
    seen = set()
    for f, maxs in files:
        name = os.path.basename(f).replace(" ", "_").replace("(", "").replace(")", "")
        if name in seen:
            name = os.path.basename(os.path.dirname(f)).replace(" ", "_") + "_" + name
        seen.add(name)
        im = Image.open(f).convert("RGBA")
        bb = im.getbbox()
        if bb:
            im = im.crop(bb)
        s = maxs / max(im.size)
        if s < 1:
            im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))), Image.LANCZOS)
        im = im.quantize(colors=64, method=Image.Quantize.FASTOCTREE, dither=Image.Dither.NONE)
        dst = os.path.join(OUT, cat, name)
        im.save(dst, optimize=True)
        total += os.path.getsize(dst)
        manifest.setdefault(cat, []).append("res://assets/sprites/cover/%s/%s" % (cat, name))
lines = ["class_name CoverSprites", "extends RefCounted",
         "## GENERATED by tools/gen_cover_sprites.py: CC0 Kenney sprites for box covers, by category.", "",
         "const SPRITES := {"]
for cat, paths in manifest.items():
    lines.append('\t"%s": [' % cat)
    for p in paths:
        lines.append('\t\t"%s",' % p)
    lines.append("\t],")
lines.append("}")
open(os.path.join(ROOT, "scripts/gfx/cover_sprites.gd"), "w").write("\n".join(lines) + "\n")
print({k: len(v) for k, v in manifest.items()}, "bytes", total)
