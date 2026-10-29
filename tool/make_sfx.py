"""Synthesizes the game's sound effects: soft marimba and bell tones.

Writes 16-bit mono WAV files into assets/sfx/. Every sound is original,
so there's nothing to license or credit.
"""
import math
import os
import struct
import sys
import wave

RATE = 22050
OUT = sys.argv[1]
os.makedirs(OUT, exist_ok=True)


def note(freq, start, dur, vol=1.0, kind="marimba"):
    """One struck note as (start_sample, samples)."""
    n = int(dur * RATE)
    out = []
    for i in range(n):
        t = i / RATE
        if kind == "marimba":
            # Warm fundamental plus a quick-fading bright overtone
            v = math.sin(2 * math.pi * freq * t) * math.exp(-t * 7)
            v += 0.35 * math.sin(2 * math.pi * freq * 4 * t) * math.exp(-t * 28)
        elif kind == "bell":
            v = math.sin(2 * math.pi * freq * t) * math.exp(-t * 4.5)
            v += 0.4 * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-t * 9)
            v += 0.2 * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-t * 16)
        elif kind == "soft":
            # Rounded tone with a gentle wobble, for the friendly "uh-oh"
            wob = 1 + 0.012 * math.sin(2 * math.pi * 6 * t)
            v = math.sin(2 * math.pi * freq * wob * t) * math.exp(-t * 5)
            v += 0.15 * math.sin(2 * math.pi * freq * 2 * t) * math.exp(-t * 9)
        elif kind == "pop":
            # A tiny pop: pitch drops fast
            f = freq * (1 - 0.45 * min(1, t / dur))
            v = math.sin(2 * math.pi * f * t) * math.exp(-t * 40)
        # 5 ms fade-in and 15 ms fade-out so nothing clicks
        v *= min(1, t / 0.005, (n - i) / (0.015 * RATE))
        out.append(v * vol)
    return int(start * RATE), out


def render(name, notes, length):
    buf = [0.0] * int(length * RATE)
    for start, samples in notes:
        for i, v in enumerate(samples):
            if start + i < len(buf):
                buf[start + i] += v
    peak = max(abs(v) for v in buf) or 1
    scale = 0.5 / peak  # about -6 dB, gentle on small speakers
    # 20 ms fade-out at the very end
    fade = int(0.02 * RATE)
    for i in range(fade):
        buf[-1 - i] *= i / fade
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(v * scale * 32767)) for v in buf))
    print(name, f"{length:.2f}s")


C5, E5, G5, A5 = 523.25, 659.25, 783.99, 880.0
C6, E6, G6, C7 = 1046.5, 1318.5, 1568.0, 2093.0
B5 = 987.77
C4, E4, G4 = 261.63, 329.63, 392.0

render("correct", [note(G5, 0, 0.5), note(C6, 0.11, 0.6)], 0.75)
render("wrong", [note(E4, 0, 0.35, 0.8, "soft"), note(C4, 0.17, 0.5, 0.8, "soft")], 0.7)
render("found", [note(f, i * 0.06, 0.6, 0.8, "bell") for i, f in enumerate([C6, E6, G6, C7])], 0.95)
render(
    "catch",
    [note(f, i * 0.09, 0.7) for i, f in enumerate([C5, E5, G5, C6])]
    + [note(E6, 0.4, 0.9, 0.6, "bell"), note(G6, 0.4, 0.9, 0.4, "bell")],
    1.3,
)
render(
    "levelup",
    [note(f, i * 0.12, 0.6) for i, f in enumerate([C5, E5, G5])]
    + [note(C6, 0.38, 1.2, 1.0, "bell"), note(E6, 0.38, 1.2, 0.6, "bell"), note(G5, 0.38, 1.2, 0.5)],
    1.7,
)
render("gem", [note(B5, 0, 0.25, 0.9, "bell"), note(E6, 0.08, 0.6, 0.9, "bell")], 0.7)
render("tap", [note(880, 0, 0.06, 1.0, "pop")], 0.08)
