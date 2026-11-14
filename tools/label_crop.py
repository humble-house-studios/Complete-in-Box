#!/usr/bin/env python3
"""Where the artwork sits on a real box scan, for the loose cart's sticker.

A box front carries the platform's trade dress around the art: the N64's red
side band with the logo and the feature icons, the NES's black "NINTENDO
ENTERTAINMENT SYSTEM" banner on top and the seal strip at the bottom, the
Genesis's striped top band. A cart sticker is just the art and the title, so
tools/gen_catalog.py stores this crop (x, y, w, h as fractions) as the def's
"label_crop" and ItemModels._cart shows only that part of the box art.
"""
from PIL import Image


def _red(p):
    r, g, b = p
    return r > 150 and g < 95 and b < 95 and r - max(g, b) > 80


def _band_cols(im, test, frac):
    w, h = im.size
    px = im.load()
    out = []
    for x in range(w):
        n = sum(1 for y in range(0, h, 3) if test(px[x, y]))
        out.append(n / len(range(0, h, 3)) >= frac)
    return out


def _side_band(im):
    """N64: where the red side band starts -> (left, right) of the art (fractions).
    The band is busy (white logo, icons, seals), so look for the edge where
    the red share jumps: red right of it, little red left of it."""
    w, h = im.size
    px = im.load()
    col = [sum(1 for y in range(0, h, 2) if _red(px[x, y])) / len(range(0, h, 2)) for x in range(w)]

    def mean(a, b):
        a, b = max(0, a), min(w, b)
        return sum(col[a:b]) / max(1, b - a)
    s = max(3, int(w * 0.03))
    best, bx = 0.0, w
    for x in range(int(w * 0.68), int(w * 0.9)):
        inside = mean(x, x + s)
        if inside < 0.2 or mean(x, w) < 0.22:
            continue
        jump = inside - mean(x - s, x)
        if jump > best:
            best, bx = jump, x
    right = bx if best > 0.15 else w
    if right == w:
        # A darker or busier band: the right sixth still reads as red overall.
        soft = sum(1 for x in range(int(w * 0.84), w, 2) for y in range(0, h, 3)
                   if px[x, y][0] > px[x, y][1] + 60 and px[x, y][0] > px[x, y][2] + 40 and px[x, y][0] > 110)
        if soft / (len(range(int(w * 0.84), w, 2)) * len(range(0, h, 3))) > 0.3:
            right = int(w * 0.82)
    best, lx = 0.0, 0
    for x in range(int(w * 0.1), int(w * 0.32)):
        inside = mean(x - s, x)
        if inside < 0.35 or mean(0, x) < 0.35:
            continue
        jump = inside - mean(x, x + s)
        if jump > best:
            best, lx = jump, x
    left = lx if best > 0.15 else 0
    return left / w, right / w


def _dark_rows_top(im, limit):
    """Rows from the top that are a near-black banner."""
    w, h = im.size
    px = im.load()
    y = 0
    while y < h * limit:
        dark = sum(1 for x in range(0, w, 3) if sum(px[x, y]) < 150) / len(range(0, w, 3))
        if dark < 0.55:
            break
        y += 1
    return y / h


def label_crop(path, plat, japan=False):
    im = Image.open(path).convert("RGB")
    if plat == "F64":
        if japan:
            return (0.0, 0.0, 1.0, 1.0)
        # Every US box has the side band at about 82% (some are grey or white,
        # so when the red edge is not found, cut there anyway).
        _l, r = _side_band(im)
        if not 0.74 < r < 0.88:
            r = 0.82
        return (0.0, 0.0, round(r, 3), 1.0)
    if plat == "FES":
        # The thin banner on top, the seal / logo strip at the bottom.
        top = min(_dark_rows_top(im, 0.06), 0.04) + 0.005
        return (0.0, round(top, 3), 1.0, round(0.875 - top, 3))
    if japan:
        return (0.0, 0.0, 1.0, 1.0)
    if plat == "PBOY":
        # The "GAME BOY" band down the left, the Nintendo strip at the bottom.
        return (0.165, 0.0, 0.835, 0.93)
    if plat == "PBA":
        return (0.165, 0.0, 0.835, 0.93)
    if plat == "SFES":
        # The black stripe down the right, the SUPER NINTENDO band at the bottom.
        return (0.0, 0.0, 0.84, 0.84)
    if plat == "GEN":
        w, h = im.size
        px = im.load()
        pts = [(x, y) for x in range(int(w * 0.02), int(w * 0.14), 2) for y in range(int(h * 0.2), int(h * 0.8), 4)]
        if sum(1 for p in pts if _red(px[p])) / len(pts) > 0.35:
            # The red "GENESIS" band down the left side, SEGA strip at the bottom.
            return (0.17, 0.0, 0.83, 0.9)
        # The early grid boxes: a framed picture on a black grid.
        return (0.06, 0.08, 0.88, 0.88)
    return (0.0, 0.0, 1.0, 1.0)
