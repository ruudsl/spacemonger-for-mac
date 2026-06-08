#!/usr/bin/env python3
"""Generates web/og.png — a 1200x630 social-share card (sunburst on a dark
gradient). Pure standard library, no dependencies.  Run: python3 web/make_og.py
"""
import math
import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(__file__), "og.png")
W, H = 1200, 630


def hsv(h, s, v):
    i = int(h * 6.0); f = h * 6.0 - i
    p = v * (1 - s); q = v * (1 - f * s); t = v * (1 - (1 - f) * s); i %= 6
    return [(v, t, p), (q, v, p), (p, v, t), (p, q, v), (t, p, v), (v, p, q)][i]


def smooth(a, b, x):
    if a == b: return 0.0 if x < a else 1.0
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


def render():
    cx, cy = 360, H / 2          # sunburst centre (left third)
    max_r = 250.0
    hole_r = max_r * 0.30
    rings = 3
    thick = (max_r - hole_r) / rings
    seg_counts = [9, 14, 22]
    top = (34, 41, 58)
    bot = (15, 18, 28)

    px = bytearray(W * H * 4)
    for y in range(H):
        ty = y / (H - 1)
        bg = tuple(int(top[k] + (bot[k] - top[k]) * ty) for k in range(3))
        # soft glow towards the right where text will sit
        for x in range(W):
            r, g, b = bg
            # subtle radial glow near the sunburst
            gd = math.hypot(x - cx, y - cy)
            glow = max(0.0, 1.0 - gd / 720.0) * 0.10
            r = int(r + (120 - r) * glow * 0.4)
            g = int(g + (90 - g) * glow * 0.6)
            b = int(b + (180 - b) * glow)

            dx, dy = x - cx, y - cy
            dist = math.hypot(dx, dy)
            if hole_r <= dist <= max_r:
                depth = max(0, min(rings - 1, int((dist - hole_r) / thick)))
                local = (dist - hole_r) - depth * thick
                ang = math.atan2(dy, dx)
                if ang < 0: ang += 2 * math.pi
                count = seg_counts[depth]
                seg = ang / (2 * math.pi) * count
                seg_local = seg - int(seg)
                hue = (int(seg) / count + depth * 0.045 + 0.58) % 1.0
                sr, sg, sb = hsv(hue, 0.62 - depth * 0.05, 0.84 + depth * 0.05)
                ring_edge = min(local, thick - local)
                seg_pix = seg_local * (2 * math.pi * dist / count)
                seg_edge = min(seg_pix, (2 * math.pi * dist / count) - seg_pix)
                cov = smooth(0, 4, ring_edge) * smooth(0, 3, seg_edge)
                r = int(r + (sr * 255 - r) * cov)
                g = int(g + (sg * 255 - g) * cov)
                b = int(b + (sb * 255 - b) * cov)

            i = (y * W + x) * 4
            px[i] = max(0, min(255, r)); px[i+1] = max(0, min(255, g))
            px[i+2] = max(0, min(255, b)); px[i+3] = 255
    return px


def write_png(path, w, h, rgba):
    def chunk(typ, data):
        return struct.pack(">I", len(data)) + typ + data + struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff)
    raw = bytearray()
    stride = w * 4
    for y in range(h):
        raw.append(0); raw.extend(rgba[y*stride:(y+1)*stride])
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        f.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    print("Rendering og.png …")
    write_png(OUT, W, H, render())
    print("Wrote", OUT)
