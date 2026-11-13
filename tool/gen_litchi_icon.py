"""Generate the LitchiViewer lychee icon set.

Design: a lychee fruit (red bumpy body + stem + two leaves) on a warm
near-white rounded-square background. Rendered with supersampling for smooth
edges, then exported to every platform the client needs:

  - clients/windows/runner/resources/app_icon.ico   (multi-size, tray + exe)
  - clients/assets/litchi_logo.png                  (1024, Flutter UI asset)
  - clients/android/app/src/main/res/mipmap-*/...   (legacy + adaptive)
  - clients/ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png

Run:  python clients/tool/gen_litchi_icon.py
"""

from __future__ import annotations

import math
import os
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]

# ---- palette -------------------------------------------------------------
LYCHEE_LIGHT = (245, 132, 138)
LYCHEE_BASE = (227, 77, 89)      # 荔枝红 / lychee red (brand primary)
LYCHEE_DARK = (176, 42, 54)
LYCHEE_DEEP = (146, 30, 42)
LEAF_LIGHT = (110, 205, 138)
LEAF_DARK = (44, 152, 88)
STEM = (122, 82, 48)
STEM_DARK = (92, 60, 34)
BG_TOP = (255, 244, 245)
BG_BOT = (255, 223, 227)

SS = 4  # supersampling factor


def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(len(a)))


def _leaf_layer(length: int, width: int, col_a, col_b) -> Image.Image:
    """Build a single leaf on a tight canvas (RGBA), pointing +x."""
    pad = 4
    W = length + pad * 2
    H = width + pad * 2
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pts = []
    n = 48
    cy = H / 2
    for i in range(n + 1):
        t = i / n
        px = pad + t * length
        w = math.sin(t * math.pi) * width * 0.5
        pts.append((px, cy - w))
    for i in range(n, -1, -1):
        t = i / n
        px = pad + t * length
        w = math.sin(t * math.pi) * width * 0.5
        pts.append((px, cy + w))
    d.polygon(pts, fill=col_a + (255,))
    d.line([(pad, cy), (pad + length, cy)], fill=col_b + (255,), width=max(1, int(width * 0.09)))
    return img


def draw_lychee(size: int, with_background: bool) -> Image.Image:
    """Render a lychee at `size` px (RGBA). with_background adds the squircle."""
    S = size * SS
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))

    if with_background:
        radius = int(S * 0.225)
        bg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        gd = ImageDraw.Draw(bg)
        for y in range(S):
            gd.line([(0, y), (S, y)], fill=lerp(BG_TOP, BG_BOT, y / S) + (255,))
        mask = Image.new("L", (S, S), 0)
        ImageDraw.Draw(mask).rounded_rectangle([0, 0, S - 1, S - 1], radius=radius, fill=255)
        img.paste(bg, (0, 0), mask)

    cx, cy = S * 0.5, S * 0.56
    r = S * 0.285

    # body circle mask
    body_mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(body_mask).ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)

    # 1) opaque base
    body = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(body).ellipse([cx - r, cy - r, cx + r, cy + r], fill=LYCHEE_BASE + (255,))

    # 2) radial shading (concentric, lit from top-left)
    shade = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    steps = 200
    lx, ly = cx - r * 0.38, cy - r * 0.40
    for i in range(steps, 0, -1):
        t = i / steps
        rr = r * t
        col = lerp(LYCHEE_LIGHT, LYCHEE_DARK, min(1.0, t * 1.05))
        ox = cx + (lx - cx) * (1 - t) * 0.55
        oy = cy + (ly - cy) * (1 - t) * 0.55
        sd.ellipse([ox - rr, oy - rr, ox + rr, oy + rr], fill=col + (255,))
    body = Image.alpha_composite(body, shade)

    # 3) bumpy skin texture (semi-transparent dots, clipped later)
    tex = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    td = ImageDraw.Draw(tex)
    spacing = r * 0.20
    dot = spacing * 0.30
    row = 0
    y = cy - r
    while y <= cy + r:
        x = cx - r + (spacing * 0.5 if row % 2 else 0)
        while x <= cx + r:
            jx = math.sin((x + y) * 12.9898) * spacing * 0.12
            jy = math.cos((x - y) * 7.233) * spacing * 0.12
            px, py = x + jx, y + jy
            up = (px - cx) + (py - cy) < 0
            col = (255, 205, 208, 70) if up else (150, 32, 44, 80)
            td.ellipse([px - dot, py - dot, px + dot, py + dot], fill=col)
            x += spacing
        y += spacing * 0.87
        row += 1
    body = Image.alpha_composite(body, tex)

    # 4) glossy highlight
    gloss = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).ellipse(
        [cx - r * 0.72, cy - r * 0.86, cx - r * 0.10, cy - r * 0.18],
        fill=(255, 255, 255, 60),
    )
    body = Image.alpha_composite(body, gloss)

    # clip body to circle
    body.putalpha(Image.composite(body.getchannel("A"), Image.new("L", (S, S), 0), body_mask))
    img = Image.alpha_composite(img, body)

    # 5) stem
    d2 = ImageDraw.Draw(img)
    stem_w = max(2, int(r * 0.14))
    stem_top = cy - r - S * 0.085
    d2.line([(cx, cy - r + r * 0.10), (cx + r * 0.05, stem_top)], fill=STEM + (255,), width=stem_w)
    d2.line([(cx + r * 0.05, stem_top), (cx + r * 0.06, stem_top - stem_w)], fill=STEM_DARK + (255,), width=stem_w)

    # 6) two leaves
    def place_leaf(anchor_x, anchor_y, length, width, angle):
        leaf = _leaf_layer(int(length), int(width), LEAF_DARK, LEAF_LIGHT)
        leaf = leaf.rotate(angle, resample=Image.BICUBIC, expand=True)
        img.alpha_composite(leaf, (int(anchor_x - leaf.width * 0.5), int(anchor_y - leaf.height * 0.5)))

    top_x, top_y = cx + r * 0.05, stem_top
    place_leaf(top_x - S * 0.10, top_y - S * 0.02, S * 0.30, S * 0.13, 32)
    place_leaf(top_x + S * 0.08, top_y - S * 0.04, S * 0.32, S * 0.14, -28)

    return img.resize((size, size), Image.LANCZOS)


def make_background_icon(size: int) -> Image.Image:
    """Squircle background with centered lychee (for app/launcher icons)."""
    S = size * SS
    canvas = draw_lychee(size, with_background=True)
    return canvas


def save_png(img: Image.Image, path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path)


def main():
    # 1) Windows .ico (multi-size, includes 16/24/32/48/64/128/256)
    ico_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    ico_base = make_background_icon(256)
    ico_path = ROOT / "clients/windows/runner/resources/app_icon.ico"
    ico_path.parent.mkdir(parents=True, exist_ok=True)
    ico_base.save(ico_path, format="ICO", sizes=ico_sizes)
    print("wrote", ico_path)

    # 2) Flutter UI asset (transparent-ish squircle, 1024)
    save_png(make_background_icon(1024), ROOT / "clients/assets/litchi_logo.png")
    print("wrote clients/assets/litchi_logo.png")

    # 3) Android legacy + adaptive
    mipmap = ROOT / "clients/android/app/src/main/res"
    legacy = {48: "mdpi", 72: "hdpi", 96: "xhdpi", 144: "xxhdpi", 192: "xxxhdpi"}
    for px, dpi in legacy.items():
        save_png(make_background_icon(px), mipmap / f"mipmap-{dpi}/ic_launcher.png")
    # adaptive foreground: lychee centered on transparent 108dp canvas (scales)
    fg = {108: "mdpi", 162: "hdpi", 216: "xhdpi", 324: "xxhdpi", 432: "xxxhdpi"}
    for px, dpi in fg.items():
        inner = int(px * 0.62)
        fruit = draw_lychee(inner, with_background=False)
        canvas = Image.new("RGBA", (px, px), (0, 0, 0, 0))
        canvas.alpha_composite(fruit, ((px - inner) // 2, (px - inner) // 2))
        save_png(canvas, mipmap / f"mipmap-{dpi}/ic_launcher_foreground.png")
    print("wrote android mipmaps")

    # 4) iOS app icons (from Contents.json sizes)
    ios = ROOT / "clients/ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_map = {
        "icon_20x20@2x.png": 40, "icon_20x20@3x.png": 60,
        "icon_29x29@2x.png": 58, "icon_29x29@3x.png": 87,
        "icon_40x40@2x.png": 80, "icon_40x40@3x.png": 120,
        "icon_60x60@2x.png": 120, "icon_60x60@3x.png": 180,
        "icon_64x64@2x.png": 128,
        "icon_76x76@2x.png": 152, "icon_83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, px in ios_map.items():
        save_png(make_background_icon(px), ios / name)
    print("wrote ios app icons")

    # 5) macOS app icons
    mac = ROOT / "clients/macos/Runner/Assets.xcassets/AppIcon.appiconset"
    mac_sizes = {"app_icon_16.png": 16, "app_icon_32.png": 32, "app_icon_64.png": 64,
                 "app_icon_128.png": 128, "app_icon_256.png": 256, "app_icon_512.png": 512,
                 "app_icon_1024.png": 1024}
    for name, px in mac_sizes.items():
        save_png(make_background_icon(px), mac / name)
    print("wrote macos app icons")

    # 6) legacy asset name kept in sync
    save_png(make_background_icon(512), ROOT / "clients/assets/nex_logo.png")
    print("wrote clients/assets/nex_logo.png")


if __name__ == "__main__":
    main()