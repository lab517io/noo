#!/usr/bin/env python3
"""Regenerate the Android launcher icons from docs/play-assets/icon-512.png.

Emits the legacy square mipmaps plus the adaptive-icon foreground/monochrome
layers; the background is the flat brand colour in res/values/ic_launcher_background.xml.
Run after changing the source icon:  python3 scripts/gen_android_icons.py
Requires Pillow.
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs/play-assets/icon-512.png")
RES = os.path.join(ROOT, "client/android/app/src/main/res")
BG = (0x67, 0x50, 0xA4)

# density -> legacy px, adaptive px (108dp)
DENSITIES = {
    "mdpi": (48, 108),
    "hdpi": (72, 162),
    "xhdpi": (96, 216),
    "xxhdpi": (144, 324),
    "xxxhdpi": (192, 432),
}

src = Image.open(SRC).convert("RGBA")

# --- legacy square icons -------------------------------------------------
for d, (legacy, _) in DENSITIES.items():
    out = os.path.join(RES, f"mipmap-{d}", "ic_launcher.png")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    src.resize((legacy, legacy), Image.LANCZOS).save(out, optimize=True)
    print("wrote", out)

# --- extract the white glyph as an alpha mask ----------------------------
flat = Image.new("RGB", src.size, BG)
flat.paste(src, mask=src.split()[3])
r, g, b = flat.split()
px_r, px_g, px_b = r.load(), g.load(), b.load()
mask = Image.new("L", src.size)
mp = mask.load()
for y in range(src.size[1]):
    for x in range(src.size[0]):
        # colour = BG*(1-a) + white*a, solved per channel and averaged
        a = ((px_r[x, y] - BG[0]) / (255 - BG[0])
             + (px_g[x, y] - BG[1]) / (255 - BG[1])
             + (px_b[x, y] - BG[2]) / (255 - BG[2])) / 3
        mp[x, y] = max(0, min(255, round(a * 255)))

bbox = mask.getbbox()
glyph = mask.crop(bbox)
print("glyph bbox", bbox, "->", glyph.size)

# --- adaptive foreground / monochrome ------------------------------------
# Adaptive icons are 108dp canvases; masks show at most the centre 72dp and
# only the centre 66dp circle is guaranteed. Size the glyph so its whole
# bounding box — corners included — fits inside that 66dp circle.
SAFE_CIRCLE_DP = 66.0
for d, (_, canvas) in DENSITIES.items():
    scale = canvas / 108.0
    diag = (glyph.size[0] ** 2 + glyph.size[1] ** 2) ** 0.5
    ratio = (SAFE_CIRCLE_DP * scale) / diag
    gw, gh = max(1, round(glyph.size[0] * ratio)), max(1, round(glyph.size[1] * ratio))
    g_small = glyph.resize((gw, gh), Image.LANCZOS)

    fg = Image.new("RGBA", (canvas, canvas), (255, 255, 255, 0))
    white = Image.new("RGBA", (gw, gh), (255, 255, 255, 255))
    fg.paste(white, ((canvas - gw) // 2, (canvas - gh) // 2), g_small)

    for name in ("ic_launcher_foreground.png", "ic_launcher_monochrome.png"):
        out = os.path.join(RES, f"mipmap-{d}", name)
        fg.save(out, optimize=True)
        print("wrote", out, fg.size)
