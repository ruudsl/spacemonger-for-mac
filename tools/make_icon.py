#!/usr/bin/env python3
"""Generates the SpaceMonger app icon (a sunburst on a dark squircle) as PNGs.

Pure standard library: renders a high-res master and box-downsamples to every
size the asset catalog needs. No external dependencies.
"""
import math
import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "SpaceMonger",
                   "Assets.xcassets", "AppIcon.appiconset")

MASTER = 1024  # master render size


def hsv_to_rgb(h, s, v):
    i = int(h * 6.0)
    f = h * 6.0 - i
    p = v * (1.0 - s)
    q = v * (1.0 - f * s)
    t = v * (1.0 - (1.0 - f) * s)
    i %= 6
    r, g, b = [(v, t, p), (q, v, p), (p, v, t),
               (p, q, v), (t, p, v), (v, p, q)][i]
    return r, g, b


def smoothstep(edge0, edge1, x):
    if edge0 == edge1:
        return 0.0 if x < edge0 else 1.0
    t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
    return t * t * (3 - 2 * t)


def rounded_rect_sdf(px, py, half, radius):
    qx = abs(px) - (half - radius)
    qy = abs(py) - (half - radius)
    ax = max(qx, 0.0)
    ay = max(qy, 0.0)
    return math.hypot(ax, ay) + min(max(qx, qy), 0.0) - radius


def render(size):
    cx = cy = size / 2.0
    margin = size * 0.06
    half = size / 2.0 - margin
    corner = half * 2 * 0.2237

    max_r = half * 0.80
    hole_r = max_r * 0.30
    rings = 3
    thickness = (max_r - hole_r) / rings
    seg_counts = [9, 14, 22]

    # Top/bottom background gradient (dark navy/teal).
    top = (34, 41, 58)
    bot = (16, 20, 31)

    px = bytearray(size * size * 4)

    for y in range(size):
        ty = y / (size - 1)
        bg = tuple(int(top[k] + (bot[k] - top[k]) * ty) for k in range(3))
        for x in range(size):
            dx = x - cx
            dy = y - cy

            # Squircle alpha (1.5px feather).
            sdf = rounded_rect_sdf(dx, dy, half, corner)
            alpha = 1.0 - smoothstep(-1.5, 0.5, sdf)
            if alpha <= 0.0:
                continue

            r, g, b = bg
            dist = math.hypot(dx, dy)

            if hole_r <= dist <= max_r:
                depth = int((dist - hole_r) / thickness)
                depth = max(0, min(rings - 1, depth))
                local = (dist - hole_r) - depth * thickness  # 0..thickness

                angle = math.atan2(dy, dx)
                if angle < 0:
                    angle += 2 * math.pi
                frac = angle / (2 * math.pi)

                count = seg_counts[depth]
                seg = frac * count
                seg_idx = int(seg)
                seg_local = seg - seg_idx  # 0..1 within segment

                hue = (seg_idx / count + depth * 0.045 + 0.58) % 1.0
                sat = 0.66 - depth * 0.05
                val = 0.82 + depth * 0.06
                sr, sg, sb = hsv_to_rgb(hue, sat, val)

                # Gaps: feather near ring and segment edges -> show background.
                ring_edge = min(local, thickness - local)
                ring_cov = smoothstep(0.0, size * 0.006, ring_edge)
                seg_pix = seg_local * (2 * math.pi * dist / count)
                seg_edge = min(seg_pix, (2 * math.pi * dist / count) - seg_pix)
                seg_cov = smoothstep(0.0, size * 0.004, seg_edge)
                cov = ring_cov * seg_cov

                r = int(bg[0] + (sr * 255 - bg[0]) * cov)
                g = int(bg[1] + (sg * 255 - bg[1]) * cov)
                b = int(bg[2] + (sb * 255 - bg[2]) * cov)

            # Center dot rim.
            if dist <= hole_r:
                rim = smoothstep(hole_r - size * 0.012, hole_r, dist) * \
                      (1.0 - smoothstep(hole_r, hole_r + size * 0.012, dist))
                glow = 0.35 * rim
                r = int(r + (210 - r) * glow)
                g = int(g + (215 - g) * glow)
                b = int(b + (230 - b) * glow)

            i = (y * size + x) * 4
            a = int(255 * alpha)
            px[i] = max(0, min(255, r))
            px[i + 1] = max(0, min(255, g))
            px[i + 2] = max(0, min(255, b))
            px[i + 3] = a
    return px


def downsample(master, msize, target):
    if target == msize:
        return master
    out = bytearray(target * target * 4)
    block = msize / target
    for y in range(target):
        y0 = int(y * block)
        y1 = max(y0 + 1, int((y + 1) * block))
        for x in range(target):
            x0 = int(x * block)
            x1 = max(x0 + 1, int((x + 1) * block))
            sr = sg = sb = sa = 0
            n = 0
            for yy in range(y0, y1):
                base = (yy * msize + x0) * 4
                for xx in range(x0, x1):
                    j = base + (xx - x0) * 4
                    sr += master[j]
                    sg += master[j + 1]
                    sb += master[j + 2]
                    sa += master[j + 3]
                    n += 1
            o = (y * target + x) * 4
            out[o] = sr // n
            out[o + 1] = sg // n
            out[o + 2] = sb // n
            out[o + 3] = sa // n
    return out


def write_png(path, size, rgba):
    def chunk(typ, data):
        return (struct.pack(">I", len(data)) + typ + data +
                struct.pack(">I", zlib.crc32(typ + data) & 0xffffffff))
    sig = b"\x89PNG\r\n\x1a\n"
    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    stride = size * 4
    raw = bytearray()
    for y in range(size):
        raw.append(0)
        raw.extend(rgba[y * stride:(y + 1) * stride])
    idat = zlib.compress(bytes(raw), 9)
    with open(path, "wb") as f:
        f.write(sig)
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", idat))
        f.write(chunk(b"IEND", b""))


def main():
    print("Rendering master %dx%d…" % (MASTER, MASTER))
    master = render(MASTER)
    sizes = [16, 32, 64, 128, 256, 512, 1024]
    for s in sizes:
        print("  -> icon_%d.png" % s)
        data = downsample(master, MASTER, s)
        write_png(os.path.join(OUT, "icon_%d.png" % s), s, data)
    print("Done.")


if __name__ == "__main__":
    main()
