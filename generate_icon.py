#!/usr/bin/env python3
"""
LinkSaver app icon — logo_widget.dart ile birebir aynı:
  - Gradient: #E8456A (sol-üst) → #4F72FF (sağ-alt)   [topLeft→bottomRight]
  - İkon: Asıl MaterialIcons-Regular.otf font dosyasıyla Icons.link_rounded (0xf85a)
  - Köşe yuvarlaklığı: size * 0.28
"""
import os
from PIL import Image, ImageDraw, ImageFont

ICON_DIR    = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
FONT_PATH   = "/Users/emineaydinli/Documents/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"
LINK_CHAR   = chr(0xf85a)   # Icons.link_rounded codepoint

COLOR_A = (232, 69, 106)    # #E8456A  sol-üst (pembe)
COLOR_B = (79,  114, 255)   # #4F72FF  sağ-alt (mavi)

SIZES = {
    "Icon-App-20x20@1x.png":       20,
    "Icon-App-20x20@2x.png":       40,
    "Icon-App-20x20@3x.png":       60,
    "Icon-App-29x29@1x.png":       29,
    "Icon-App-29x29@2x.png":       58,
    "Icon-App-29x29@3x.png":       87,
    "Icon-App-40x40@1x.png":       40,
    "Icon-App-40x40@2x.png":       80,
    "Icon-App-40x40@3x.png":      120,
    "Icon-App-60x60@2x.png":      120,
    "Icon-App-60x60@3x.png":      180,
    "Icon-App-76x76@1x.png":       76,
    "Icon-App-76x76@2x.png":      152,
    "Icon-App-83.5x83.5@2x.png":  167,
    "Icon-App-1024x1024@1x.png": 1024,
}


# ── 1. Gradient arka plan ─────────────────────────────────────────────────────

def make_gradient(size: int) -> Image.Image:
    """topLeft (pembe) → bottomRight (mavi) lineer gradient."""
    img = Image.new("RGBA", (size, size))
    px  = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            t = max(0.0, min(1.0, t))
            r = int(COLOR_A[0] + (COLOR_B[0] - COLOR_A[0]) * t)
            g = int(COLOR_A[1] + (COLOR_B[1] - COLOR_A[1]) * t)
            b = int(COLOR_A[2] + (COLOR_B[2] - COLOR_A[2]) * t)
            px[x, y] = (r, g, b, 255)
    return img


# ── 2. Asıl Material font glyph'ini çiz ──────────────────────────────────────

def draw_link_icon(canvas: Image.Image, size: int):
    """
    Flutter'ın kullandığı MaterialIcons-Regular.otf fontunu yükleyip
    Icons.link_rounded (0xf85a) glyph'ini tam ortaya çizer.
    icon_size = size * 0.58  (logo_widget.dart ile aynı oran)
    """
    icon_px = int(size * 0.58)

    font = ImageFont.truetype(FONT_PATH, icon_px)

    # Glyph bounding box'ını hesapla (tam ortaya konumlandırmak için)
    tmp = Image.new("RGBA", (size * 2, size * 2), (0, 0, 0, 0))
    d   = ImageDraw.Draw(tmp)
    bbox = d.textbbox((0, 0), LINK_CHAR, font=font)
    glyph_w = bbox[2] - bbox[0]
    glyph_h = bbox[3] - bbox[1]

    # Canvas merkezine göre offset
    x = (size - glyph_w) // 2 - bbox[0]
    y = (size - glyph_h) // 2 - bbox[1]

    draw = ImageDraw.Draw(canvas)
    draw.text((x, y), LINK_CHAR, font=font, fill=(255, 255, 255, 255))


# ── 3. Tam ikonu birleştir ────────────────────────────────────────────────────

def make_icon(size: int) -> Image.Image:
    img = make_gradient(size)
    draw_link_icon(img, size)
    return img


# ── 4. Tüm boyutlara kaydet ───────────────────────────────────────────────────

def main():
    os.makedirs(ICON_DIR, exist_ok=True)
    master = make_icon(1024)

    for filename, px_size in SIZES.items():
        path = os.path.join(ICON_DIR, filename)
        icon = master if px_size == 1024 else master.resize(
            (px_size, px_size), Image.LANCZOS)
        # iOS şeffaflık kabul etmez — beyaz zemine yapıştır
        bg = Image.new("RGB", icon.size, (255, 255, 255))
        if icon.mode == "RGBA":
            bg.paste(icon, mask=icon.split()[3])
        else:
            bg.paste(icon)
        bg.save(path, "PNG", optimize=True)
        print(f"  ✓ {filename:42s} ({px_size}px)")

    print(f"\nTüm ikonlar → {ICON_DIR}/")


if __name__ == "__main__":
    main()
