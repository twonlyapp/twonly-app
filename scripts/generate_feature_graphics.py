#!/usr/bin/env python3
"""Compose the German and English Play Store banners from real screenshots.

Requires Pillow: python3 -m pip install Pillow
Run from any directory: python3 scripts/generate_feature_graphics.py
Uses the bundled Open Sans font in scripts/fonts (license alongside it).

The original Android captures are preferred when available. Otherwise the app
panels are extracted from metadata's existing store screenshots. The original
screenshots are never modified. Outputs are opaque 1024 x 500 RGB PNGs.
"""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SIZE = (1024, 500)
SCALE = 3
GREEN = (87, 204, 153)
INK = (14, 58, 44)
MUTED = (25, 77, 58)
CREAM = (225, 249, 235)
COPY = {
    "de-DE": {
        "language": "de",
        "headline": ("Momente", "privat teilen."),
        "encryption": "Ende-zu-Ende verschlüsselt.",
        "privacy": "Ohne Werbung und Tracking.",
    },
    "en-US": {
        "language": "en",
        "headline": ("Share moments", "privately."),
        "encryption": "End-to-end encrypted.",
        "privacy": "No ads. No tracking.",
    },
}


def px(value):
    return round(value * SCALE)


def font(size, style="Regular"):
    """Render with the requested Open Sans weight on every platform."""
    face = ImageFont.truetype(str(ROOT / "scripts/fonts/OpenSans.ttf"), px(size))
    face.set_variation_by_name(style)
    return face


def load_screenshot(locale, name, raw_dir):
    raw_path = raw_dir / COPY[locale]["language"] / f"{name}.png"
    if raw_path.is_file():
        with Image.open(raw_path) as source:
            shot = source.convert("RGB")
        meta_path = raw_path.with_suffix(".json")
        if not meta_path.is_file():
            raise ValueError(f"Missing system-bar crop metadata: {meta_path}")
        meta = json.loads(meta_path.read_text())
        shot = shot.crop((0, int(meta["top"]), shot.width,
                          shot.height - int(meta["bottom"])))
        print(f"Source: {raw_path.relative_to(ROOT) if raw_path.is_relative_to(ROOT) else raw_path}")
        return shot

    # The framed metadata screenshots have a solid green border. Their
    # app panel is the long region with mostly non-green rows beneath the
    # caption. Sample across each row so a green avatar cannot split the panel.
    path = ROOT / "metadata" / locale / "images/phoneScreenshots" / f"{name}.png"
    with Image.open(path) as source:
        shot = source.convert("RGB")
    background = shot.getpixel((0, 0))
    sample_x = range(round(shot.width * 0.2), round(shot.width * 0.8),
                     max(1, shot.width // 80))

    def foreground(x, y):
        return max(abs(a - b) for a, b in
                   zip(shot.getpixel((x, y)), background)) > 12

    runs = []
    start = None
    for y in range(shot.height):
        inside_panel = sum(foreground(x, y) for x in sample_x) >= len(sample_x) * 0.82
        if inside_panel and start is None:
            start = y
        elif not inside_panel and start is not None:
            runs.append((start, y))
            start = None
    if start is not None:
        runs.append((start, shot.height))
    top, bottom = max(runs, key=lambda run: run[1] - run[0])
    if bottom - top < shot.height * 0.5:
        raise ValueError(f"Could not locate the app panel in {path}")
    # At the panel's midpoint its straight sides give the horizontal bounds.
    y = (top + bottom) // 2
    foreground_x = [i for i in range(shot.width) if foreground(i, y)]
    print(f"Source: {path.relative_to(ROOT)} (app panel only)")
    return shot.crop((min(foreground_x), top, max(foreground_x) + 1, bottom))


def place_card(canvas, screenshot, center, height, angle):
    """Scale and rotate actual pixels; apply only an outer mask and shadow."""
    height = px(height)
    width = round(height * screenshot.width / screenshot.height)
    card = screenshot.resize((width, height), Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", card.size)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius=px(17), fill=255,
    )
    card.putalpha(mask)
    card = card.rotate(angle, Image.Resampling.BICUBIC, expand=True)
    x = px(center[0]) - card.width // 2
    y = px(center[1]) - card.height // 2
    # Keep every screen inside the output canvas rather than cutting off UI.
    if x < 0 or y < 0 or x + card.width > canvas.width or y + card.height > canvas.height:
        raise ValueError("Screenshot card extends beyond the banner")
    shadow_mask = Image.new("L", canvas.size)
    shadow_mask.paste(card.getchannel("A"), (x, y + px(10)))
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(px(14)))
    shadow = Image.new("RGBA", canvas.size, INK + (0,))
    shadow.putalpha(shadow_mask.point(lambda alpha: round(alpha * 0.19)))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(card, (x, y))


def text(draw, position, value, face, fill=INK, max_width=500):
    if draw.textlength(value, font=face) > px(max_width):
        raise ValueError(f"Text exceeds its column: {value}")
    draw.text((px(position[0]), px(position[1])), value, font=face, fill=fill, anchor="lt")


def compose(locale, raw_dir):
    copy = COPY[locale]
    canvas = Image.new("RGBA", tuple(px(value) for value in SIZE), GREEN + (255,))
    draw = ImageDraw.Draw(canvas)
    draw.ellipse(tuple(px(value) for value in (600, -30, 1170, 540)), fill=(132, 222, 181))

    title_face = font(60, "ExtraBold")
    while max(draw.textlength(line, font=title_face) for line in copy["headline"]) > px(495):
        title_face = font(title_face.size / SCALE - 1, "ExtraBold")
    second_width = draw.textlength(copy["headline"][1], font=title_face) / SCALE
    draw.rounded_rectangle(tuple(px(value) for value in
                                 (51, 207, 64 + second_width + 14, 283)),
                           radius=px(13), fill=CREAM)
    text(draw, (64, 141), copy["headline"][0], title_face)
    text(draw, (64, 213), copy["headline"][1], title_face)

    # A short rule separates the headline from the privacy facts.
    draw.line(tuple(px(value) for value in (64, 315, 110, 315)), fill=INK, width=px(2))
    text(draw, (64, 333), copy["encryption"], font(17, "Bold"), max_width=490)
    text(draw, (64, 360), copy["privacy"], font(17), fill=MUTED, max_width=490)

    place_card(canvas, load_screenshot(locale, "01_chat_list", raw_dir),
               center=(864, 244), height=381, angle=-8)
    place_card(canvas, load_screenshot(locale, "02_share_image", raw_dir),
               center=(735, 259), height=401, angle=7)
    return canvas.convert("RGB").resize(SIZE, Image.Resampling.LANCZOS)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--raw-dir", type=Path,
                        default=ROOT / "build/store_screenshots/raw/android")
    parser.add_argument("--output-root", type=Path, default=ROOT / "metadata",
                        help="Root containing de-DE/ and en-US/ (default: metadata)")
    args = parser.parse_args()
    # Compose both successfully before replacing either existing banner.
    banners = {locale: compose(locale, args.raw_dir) for locale in COPY}
    for locale, banner in banners.items():
        path = args.output_root / locale / "images/featureGraphic.png"
        path.parent.mkdir(parents=True, exist_ok=True)
        banner.save(path, format="PNG", optimize=True)
        print(f"Saved: {path} ({banner.width} x {banner.height}, {banner.mode})")


if __name__ == "__main__":
    main()
