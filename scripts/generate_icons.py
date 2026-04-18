"""
NFCC icon + favicon generator.

Produces a matching set of icons for:
- Android launcher (mipmap-mdpi..xxxhdpi)
- F-Droid / Google Play listing (512x512)
- Flutter web (web/favicon.png, web/icons/*)
- Next.js landing page (nfcc-web/app/icon.png + favicon.ico)

Design: rounded NFC-blue square, bold white "N" monogram, subtle NFC signal
arcs in the lower-right. Matches AppColors.gradientNfc in the mobile app.

Run:
    python scripts/generate_icons.py
"""
from __future__ import annotations

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
FONT_PATH = "C:/Windows/Fonts/arialbd.ttf"

# Brand colors (match lib/ui/theme/app_theme.dart).
NFC_DEEP = (33, 150, 243)   # #2196F3
NFC_GLOW = (0, 176, 255)    # #00B0FF
NFC_DARK = (15, 70, 130)    # shadow side of gradient
WHITE = (255, 255, 255)


def _gradient(size: int) -> Image.Image:
    """Linear gradient top-left → bottom-right, NFC_DARK → NFC_GLOW."""
    img = Image.new("RGB", (size, size), NFC_DARK)
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size - 1)  # 0..1
            r = int(NFC_DARK[0] + (NFC_GLOW[0] - NFC_DARK[0]) * t)
            g = int(NFC_DARK[1] + (NFC_GLOW[1] - NFC_DARK[1]) * t)
            b = int(NFC_DARK[2] + (NFC_GLOW[2] - NFC_DARK[2]) * t)
            px[x, y] = (r, g, b)
    return img


def _rounded_mask(size: int, radius_ratio: float = 0.22) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    r = int(size * radius_ratio)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=r, fill=255)
    return mask


def _draw_nfc_arcs(img: Image.Image, size: int) -> None:
    """Subtle NFC signal arcs in the lower-right corner."""
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = int(size * 0.82), int(size * 0.82)
    max_r = int(size * 0.20)
    stroke = max(2, size // 64)
    for i, r_mul in enumerate((0.40, 0.65, 0.95)):
        r = int(max_r * r_mul)
        # Draw an arc sweeping from 200° to 340° (opening toward upper-left).
        alpha = 70 + i * 40
        d.arc(
            [cx - r, cy - r, cx + r, cy + r],
            start=200,
            end=340,
            fill=(255, 255, 255, alpha),
            width=stroke,
        )


def _draw_highlight(img: Image.Image, size: int) -> None:
    """Soft top highlight for a glossy feel."""
    h = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(h)
    d.ellipse(
        [-size * 0.25, -size * 0.55, size * 1.25, size * 0.45],
        fill=(255, 255, 255, 40),
    )
    h = h.filter(ImageFilter.GaussianBlur(radius=size * 0.04))
    img.paste(h, (0, 0), h)


def _draw_n(img: Image.Image, size: int) -> None:
    """Bold white 'N' centered, sized to ~62% of canvas."""
    d = ImageDraw.Draw(img)
    font_size = int(size * 0.70)
    font = ImageFont.truetype(FONT_PATH, font_size)
    text = "N"
    bbox = d.textbbox((0, 0), text, font=font)
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    # Align visual center (ignore font's top/side bearings).
    x = (size - w) / 2 - bbox[0]
    y = (size - h) / 2 - bbox[1] - size * 0.02
    # Soft shadow underneath for depth.
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.text((x, y + size * 0.02), text, font=font, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=size * 0.015))
    img.paste(shadow, (0, 0), shadow)
    d.text((x, y), text, font=font, fill=WHITE)


def render_icon(size: int) -> Image.Image:
    """Render a single-size square icon with transparent rounded corners."""
    # Super-sample for crisper downscale.
    ss = 3 if size <= 64 else 2
    big = size * ss
    base = _gradient(big).convert("RGBA")
    _draw_highlight(base, big)
    _draw_nfc_arcs(base, big)
    _draw_n(base, big)
    base.putalpha(_rounded_mask(big))
    return base.resize((size, size), Image.LANCZOS)


def render_ico(path: Path, sizes: list[int]) -> None:
    """Multi-resolution .ico."""
    path.parent.mkdir(parents=True, exist_ok=True)
    imgs = [render_icon(s) for s in sizes]
    imgs[0].save(path, format="ICO", sizes=[(s, s) for s in sizes])


def save(img: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG", optimize=True)
    print(f"  ->{path.relative_to(ROOT)}")


def main() -> None:
    print("Generating NFCC icons…\n")

    # ─ Master 1024 for archive / F-Droid reviewer reference ────────────
    master = render_icon(1024)
    save(master, ROOT / "docs" / "brand" / "nfcc-icon-1024.png")

    # ─ F-Droid / Google Play listing (Fastlane metadata at repo root) ──
    save(render_icon(512), ROOT / "fastlane" / "metadata" /
         "android" / "en-US" / "images" / "icon.png")

    # ─ Android launcher (mipmap) ───────────────────────────────────────
    mipmaps = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    res = ROOT / "nfcc_mobile" / "android" / "app" / "src" / "main" / "res"
    for folder, size in mipmaps.items():
        save(render_icon(size), res / folder / "ic_launcher.png")

    # ─ Flutter web (build target) ──────────────────────────────────────
    web = ROOT / "nfcc_mobile" / "web"
    save(render_icon(32), web / "favicon.png")  # Flutter uses this name
    for size in (192, 512):
        save(render_icon(size), web / "icons" / f"Icon-{size}.png")
        save(render_icon(size), web / "icons" / f"Icon-maskable-{size}.png")

    # ─ Next.js landing (nfcc-web) ──────────────────────────────────────
    nextjs = ROOT / "nfcc-web"
    save(render_icon(32), nextjs / "app" / "icon.png")          # /icon
    save(render_icon(180), nextjs / "app" / "apple-icon.png")   # /apple-icon
    render_ico(nextjs / "public" / "favicon.ico", [16, 32, 48])
    print(f"  ->{(nextjs / 'public' / 'favicon.ico').relative_to(ROOT)}")

    # ─ Root favicon (repo-wide) ────────────────────────────────────────
    render_ico(ROOT / "favicon.ico", [16, 32, 48])
    print(f"  ->favicon.ico")

    print("\nDone.")


if __name__ == "__main__":
    main()
