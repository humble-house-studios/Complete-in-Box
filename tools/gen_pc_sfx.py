#!/usr/bin/env python3
"""Synthesizes the home PC sounds (numpy + ffmpeg), written as mono ogg:
  key1..key6  - mechanical keyboard keystrokes (typing out the Buyer's letters)
  pc_boot     - power switch, CRT degauss thoom, hard drive spin-up, seeks, POST beep
  pc_off      - CRT power-off: relay clunk, collapsing whine, static crackle
Run: python3 tools/gen_pc_sfx.py   (then godot --headless --import)
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")
rng = np.random.default_rng(1993)


def t_of(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack, decay):
    t = np.arange(n) / SR
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return a * np.exp(-t / decay)


def lowpass(x, cutoff):
    # One-pole low-pass, run twice for a softer slope.
    a = np.exp(-2 * np.pi * cutoff / SR)
    for _ in range(2):
        y = np.zeros_like(x)
        acc = 0.0
        for i, v in enumerate(x):
            acc = (1 - a) * v + a * acc
            y[i] = acc
        x = y
    return x


def highpass(x, cutoff):
    return x - lowpass(x, cutoff)


def bandnoise(n, lo, hi):
    return highpass(lowpass(rng.standard_normal(n), hi), lo)


def place(buf, sig, at):
    i = int(at * SR)
    j = min(len(buf), i + len(sig))
    buf[i:j] += sig[: j - i]


def norm(x, peak=0.9):
    m = np.max(np.abs(x)) or 1.0
    return x / m * peak


def write(name, x):
    x = norm(x)
    # Tiny fades so nothing clicks at the edges.
    f = min(len(x) // 4, int(SR * 0.004))
    x[:f] *= np.linspace(0, 1, f)
    x[-f:] *= np.linspace(1, 0, f)
    pcm = (x * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        path = tmp.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    out = os.path.join(OUT, name + ".ogg")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-ac", "1", "-c:a", "libvorbis", "-q:a", "5", out], check=True)
    os.remove(path)
    print("wrote", out)


def keystroke(seed):
    r = np.random.default_rng(seed)
    n = int(SR * 0.11)
    x = np.zeros(n)
    # Top of the press: a sharp plastic tick.
    tick = bandnoise(int(SR * 0.006), 2500, 9000) * env(int(SR * 0.006), 0.0002, 0.0012)
    place(x, tick * r.uniform(0.6, 0.9), 0.0)
    # Bottoming out: a woody thock (damped low tones + filtered noise).
    bt = r.uniform(0.007, 0.013)
    tn = int(SR * 0.07)
    tt = np.arange(tn) / SR
    f1 = r.uniform(170, 260)
    thock = (np.sin(2 * np.pi * f1 * tt) + 0.5 * np.sin(2 * np.pi * f1 * 2.7 * tt)) * env(tn, 0.0004, r.uniform(0.010, 0.016))
    thock += bandnoise(tn, 300, 3000) * env(tn, 0.0002, 0.005) * 0.8
    place(x, thock, bt)
    # Spring ping, very faint.
    pn = int(SR * 0.05)
    ping = np.sin(2 * np.pi * r.uniform(2800, 3800) * np.arange(pn) / SR) * env(pn, 0.0005, 0.012) * 0.08
    place(x, ping, bt + 0.002)
    # Key coming back up: a softer second click.
    up = bandnoise(int(SR * 0.005), 1500, 7000) * env(int(SR * 0.005), 0.0002, 0.0015) * r.uniform(0.15, 0.3)
    place(x, up, bt + r.uniform(0.045, 0.07))
    return x


def boot():
    dur = 2.6
    x = np.zeros(int(SR * dur))
    # Power switch: a chunky click.
    sw = bandnoise(int(SR * 0.02), 200, 5000) * env(int(SR * 0.02), 0.0002, 0.004)
    place(x, sw * 1.0, 0.0)
    # CRT degauss: a big low "thoom" with mains buzz, decaying.
    dn = int(SR * 1.1)
    dt = np.arange(dn) / SR
    hum = (np.sin(2 * np.pi * 60 * dt) + 0.6 * np.sin(2 * np.pi * 120 * dt) + 0.3 * np.sign(np.sin(2 * np.pi * 60 * dt)) * 0.4)
    thoom = hum * env(dn, 0.01, 0.28) * 0.9 + lowpass(rng.standard_normal(dn), 400) * env(dn, 0.005, 0.12) * 1.5
    place(x, thoom, 0.05)
    # Flyback whine settling in, very quiet and high.
    wn = int(SR * (dur - 0.2))
    wt = np.arange(wn) / SR
    whine = np.sin(2 * np.pi * 7800 * wt) * np.clip(wt / 0.4, 0, 1) * 0.012
    place(x, whine, 0.15)
    # Hard drive spinning up: rising partials and air noise.
    hn = int(SR * 2.2)
    ht = np.arange(hn) / SR
    f = 60 + 520 * (1 - np.exp(-ht / 0.7))
    ph = 2 * np.pi * np.cumsum(f) / SR
    spin = (np.sin(ph) * 0.5 + np.sin(ph * 2.01) * 0.25 + np.sin(ph * 3.02) * 0.12) * np.clip(ht / 0.3, 0, 1)
    spin *= 0.18 * (0.7 + 0.3 * np.clip(ht / 1.2, 0, 1))
    spin += bandnoise(hn, 400, 3000) * 0.05 * np.clip(ht / 0.5, 0, 1)
    place(x, spin, 0.25)
    # Head seeks: little scratchy clicks.
    for at in [1.15, 1.22, 1.31, 1.46, 1.52, 1.78, 1.83]:
        sk = bandnoise(int(SR * 0.012), 800, 6000) * env(int(SR * 0.012), 0.0003, 0.003)
        place(x, sk * rng.uniform(0.25, 0.45), at)
    # POST beep.
    bn = int(SR * 0.16)
    bt = np.arange(bn) / SR
    beep = np.sign(np.sin(2 * np.pi * 1000 * bt)) * 0.18 * np.clip(bt / 0.003, 0, 1) * np.clip((0.16 - bt) / 0.01, 0, 1)
    place(x, lowpass(beep, 5000), 2.05)
    return x


def power_off():
    dur = 1.2
    x = np.zeros(int(SR * dur))
    # Relay clunk.
    cl = bandnoise(int(SR * 0.04), 100, 3000) * env(int(SR * 0.04), 0.0003, 0.008)
    place(x, cl * 1.0, 0.0)
    # The picture collapsing: a quick falling zip.
    zn = int(SR * 0.35)
    zt = np.arange(zn) / SR
    f = 2600 * np.exp(-zt / 0.08) + 90
    zip_ = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(zn, 0.002, 0.12) * 0.35
    place(x, zip_, 0.02)
    # Static crackle on the tube as it discharges.
    sn = int(SR * 0.9)
    st = np.arange(sn) / SR
    crackle = rng.standard_normal(sn) * (rng.random(sn) < 0.0025) * 0.5
    crackle = highpass(crackle, 1500) * np.exp(-st / 0.3)
    place(x, crackle, 0.05)
    # Flyback whine dying away.
    wn = int(SR * 0.9)
    wt = np.arange(wn) / SR
    whine = np.sin(2 * np.pi * (7800 - 3000 * wt) * wt) * np.exp(-wt / 0.25) * 0.03
    place(x, whine, 0.0)
    # Low hum fading out.
    hn = int(SR * 0.7)
    ht = np.arange(hn) / SR
    place(x, np.sin(2 * np.pi * 60 * ht) * np.exp(-ht / 0.18) * 0.35, 0.0)
    return x


if __name__ == "__main__":
    for k in range(6):
        write("key%d" % (k + 1), keystroke(100 + k))
    write("pc_boot", boot())
    write("pc_off", power_off())
