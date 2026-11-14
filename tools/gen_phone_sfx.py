#!/usr/bin/env python3
"""Synthesizes the landline sounds (numpy + ffmpeg), mono ogg:
  phone_ring    - an old rotary phone's double bell, two bursts
  phone_pickup  - handset lifted: clunk, a breath of line hiss
Run: python3 tools/gen_phone_sfx.py   (then godot --headless --import)
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio", "sfx")
rng = np.random.default_rng(1977)


def bell(freq, n, decay):
    t = np.arange(n) / SR
    out = np.zeros(n)
    for mult, amp in [(1.0, 1.0), (2.76, 0.5), (5.4, 0.28), (8.9, 0.12)]:
        out += amp * np.sin(2 * np.pi * freq * mult * t + rng.uniform(0, 6.28)) * np.exp(-t / (decay / mult ** 0.5))
    return out


def ring_burst(sec):
    n = int(SR * sec)
    out = np.zeros(n + SR)
    strikes = int(sec * 22)
    for i in range(strikes):
        at = int(i * SR / 22 + rng.integers(-40, 40))
        f = 1320.0 if i % 2 == 0 else 1580.0
        b = bell(f * rng.uniform(0.997, 1.003), int(SR * 0.5), 0.11) * rng.uniform(0.85, 1.0)
        out[max(0, at):max(0, at) + len(b)] += b
    return out


def save(name, x):
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.85
    pcm = (x * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as f:
        path = f.name
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-ac", "1", "-c:a", "libvorbis", "-q:a", "3", os.path.join(OUT, name + ".ogg")], check=True)
    os.remove(path)


a = ring_burst(0.75)
gap = np.zeros(int(SR * 0.28))
ring = np.concatenate([a[: int(SR * 1.0)], gap, ring_burst(0.75)])
save("phone_ring", ring)

n = int(SR * 0.6)
t = np.arange(n) / SR
clunk = np.sin(2 * np.pi * 180 * t) * np.exp(-t / 0.02) + 0.6 * rng.normal(size=n) * np.exp(-t / 0.008)
late = np.zeros(n)
k = int(SR * 0.09)
late[k:] = (0.5 * rng.normal(size=n - k) * np.exp(-t[: n - k] / 0.006))
hiss = 0.05 * rng.normal(size=n) * np.clip((t - 0.1) / 0.1, 0, 1) * np.exp(-np.clip(t - 0.3, 0, 9) / 0.12)
save("phone_pickup", clunk + late + hiss)
print("ok")
