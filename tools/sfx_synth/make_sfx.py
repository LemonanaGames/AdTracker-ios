"""Synthesizes the game's original UI sound effects (no third-party audio).

Usage (from repo root):  python3 tools/sfx_synth/make_sfx.py app/assets/sfx
Pure standard library; deterministic output. Mono 44.1 kHz 16-bit WAV.
"""
import math, random, struct, sys, wave
from pathlib import Path

SR = 44100
random.seed(7)

def env(t, dur, attack=0.004, release=None):
    release = release or dur * 0.8
    if t < attack:
        return t / attack
    return max(0.0, math.exp(-(t - attack) / (release / 4.0)))

def tone(freq, dur, vol=0.5, shape="sine", attack=0.004, release=None, glide=0.0, vibrato=0.0):
    out = []
    phase = 0.0
    n = int(SR * dur)
    for i in range(n):
        t = i / SR
        f = freq * (1 + glide * t / dur) * (1 + vibrato * math.sin(2 * math.pi * 7 * t))
        phase += 2 * math.pi * f / SR
        if shape == "sine":
            s = math.sin(phase)
        elif shape == "tri":
            s = 2 / math.pi * math.asin(math.sin(phase))
        else:  # soft square (few harmonics)
            s = sum(math.sin(phase * k) / k for k in (1, 3, 5)) * 0.8
        out.append(s * vol * env(t, dur, attack, release))
    return out

def noise(dur, vol=0.3, lp=0.2, sweep=0.0):
    out, prev = [], 0.0
    for i in range(int(SR * dur)):
        t = i / SR
        a = min(0.99, max(0.01, lp + sweep * t / dur))
        prev = prev + a * (random.uniform(-1, 1) - prev)
        out.append(prev * vol * env(t, dur, 0.01, dur * 0.7))
    return out

def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    length = max(int(o * SR) + len(tr) for tr, o in zip(tracks, offsets))
    out = [0.0] * length
    for tr, o in zip(tracks, offsets):
        start = int(o * SR)
        for i, s in enumerate(tr):
            out[start + i] += s
    peak = max(1e-9, max(abs(s) for s in out))
    gain = min(1.0, 0.89 / peak)
    return [s * gain for s in out]

def write(path, samples):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s)) * 32767)) for s in samples))

def build():
    C5, E5, G5, C6, E6, G6 = 523.25, 659.25, 783.99, 1046.5, 1318.5, 1568.0
    return {
        # UI tap: tiny woody tick
        "tap": mix(tone(1800, 0.035, 0.35, "tri", 0.001, 0.02), noise(0.02, 0.15, 0.6)),
        # follower pop: bubbly upward blip
        "pop": tone(520, 0.12, 0.6, "sine", 0.002, 0.08, glide=1.2),
        # coins: two bright pings
        "coin": mix(tone(E6, 0.09, 0.45, "sq", 0.001, 0.06), tone(G6 * 1.335, 0.32, 0.45, "sq", 0.001, 0.25), offsets=[0, 0.075]),
        # publish: airy whoosh + rising tone
        "publish": mix(noise(0.45, 0.5, 0.05, sweep=0.5), tone(300, 0.45, 0.35, "tri", 0.05, 0.3, glide=2.0)),
        # level up: major arpeggio with sparkle
        "level_up": mix(*[tone(f, 0.5, 0.35, "tri", 0.003, 0.4) for f in (C5, E5, G5, C6)],
                        tone(E6, 0.6, 0.18, "sine", 0.003, 0.5, vibrato=0.004),
                        offsets=[0, 0.08, 0.16, 0.24, 0.3]),
        # unlock: warm chord swell
        "unlock": mix(*[tone(f, 0.9, 0.3, "sine", 0.12, 0.7) for f in (C5 / 2, G5 / 2, E5, G5)]),
        # story message blip
        "message": mix(tone(G5, 0.08, 0.4, "sine", 0.002, 0.05), tone(C6, 0.14, 0.4, "sine", 0.002, 0.1), offsets=[0, 0.07]),
        # soft "nope"
        "error": mix(tone(220, 0.16, 0.5, "tri", 0.002, 0.1, glide=-0.3), tone(165, 0.2, 0.4, "tri", 0.002, 0.14), offsets=[0, 0.08]),
        # purchase: register ka-ching
        "purchase": mix(noise(0.05, 0.3, 0.7), tone(C6, 0.12, 0.4, "sq", 0.001, 0.08), tone(G6, 0.4, 0.4, "sq", 0.001, 0.3), offsets=[0, 0.03, 0.1]),
    }

if __name__ == "__main__":
    out = Path(sys.argv[1] if len(sys.argv) > 1 else "app/assets/sfx")
    out.mkdir(parents=True, exist_ok=True)
    for name, samples in build().items():
        write(out / f"{name}.wav", samples)
        print(f"{name}.wav  {len(samples) / SR:.2f}s")
