#!/usr/bin/env python3
"""Generate localized App Store artwork and device screenshots using Pillow.

    python3 scripts/generate_app_store_assets.py

Reads the real iPhone captures and captions from the screenshot workflow.
Writes Header, Search, iPhone 6.1/6.3-inch and iPad 12.9/13-inch assets to
docs/screenshots/output/app-store/<language>/. iPad exports use the same iPhone
captures, fitted proportionally onto a larger canvas. All exports are RGB PNGs.
Open Sans is bundled with its license in scripts/fonts/.
"""

import argparse
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from generate_feature_graphics import COPY, CREAM, GREEN, INK, MUTED, ROOT


DEVICES = {
    "iphone-6.1": (1179, 2556),
    "iphone-6.3": (1206, 2622),
    "ipad-12.9": (2048, 2732),
    "ipad-13": (2064, 2752),
}
CREATIVES = {"header": (3840, 1646), "search": (3840, 2560)}
FONT = ROOT / "scripts/fonts/OpenSans.ttf"
LOCALES = {copy["language"]: locale for locale, copy in COPY.items()}


def font(size, style="Regular"):
    face = ImageFont.truetype(str(FONT), round(size))
    face.set_variation_by_name(style)
    return face


def wrap(draw, value, face, width):
    lines, line = [], ""
    for word in value.split():
        candidate = f"{line} {word}".strip()
        if draw.textlength(candidate, font=face) <= width:
            line = candidate
        else:
            if not line or draw.textlength(word, font=face) > width:
                raise ValueError(f"Text exceeds its column: {word}")
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


def load_capture(path):
    """Remove system bars using the metadata recorded with the real capture."""
    meta = json.loads(path.with_suffix(".json").read_text())
    with Image.open(path) as source:
        shot = source.convert("RGB")
    return shot.crop((0, int(meta["top"]), shot.width,
                      shot.height - int(meta["bottom"])))


def rounded(shot, width, height, radius):
    card = shot.resize((width, height), Image.Resampling.LANCZOS).convert("RGBA")
    mask = Image.new("L", card.size)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, width - 1, height - 1), radius=radius, fill=255,
    )
    card.putalpha(mask)
    return card


def screenshot(shot, caption, size):
    width, height = size
    canvas = Image.new("RGB", size, GREEN)
    draw = ImageDraw.Draw(canvas)
    title = font(width * 0.052, "ExtraBold")
    subtitle = font(width * 0.034)
    y = height * 0.052
    for value, face, spacing in ((caption["title"], title, 1.25),
                                  (caption["subtitle"], subtitle, 1.35)):
        for line in wrap(draw, value, face, width * 0.86):
            line_width = draw.textlength(line, font=face)
            draw.text(((width - line_width) / 2, y), line, font=face,
                      fill=INK, anchor="lt")
            y += face.size * spacing
        y += title.size * 0.18

    top = round(max(height * 0.2, y + height * 0.025))
    available = height - top - round(height * 0.055)
    if available <= 0:
        raise ValueError(f"Caption leaves no room for the screenshot: {caption}")
    # Preserve the complete phone UI and its aspect ratio on both phone and iPad.
    factor = min(width * 0.8 / shot.width, available / shot.height)
    card_width, card_height = round(shot.width * factor), round(shot.height * factor)
    card = rounded(shot, card_width, card_height, round(card_width * 0.055))
    canvas.paste(card, ((width - card_width) // 2, top), card)
    return canvas


def place_card(canvas, shot, center, height, angle, scale):
    height = round(height * scale)
    width = round(height * shot.width / shot.height)
    card = rounded(shot, width, height, round(17 * scale))
    card = card.rotate(angle, Image.Resampling.BICUBIC, expand=True)
    left = round(center[0] * scale) - card.width // 2
    top = round(center[1] * scale) - card.height // 2
    if (left < 0 or top < 0 or left + card.width > canvas.width
            or top + card.height > canvas.height):
        raise ValueError("Screenshot card extends beyond the creative canvas")
    mask = Image.new("L", canvas.size)
    mask.paste(card.getchannel("A"), (left, top + round(10 * scale)))
    mask = mask.filter(ImageFilter.GaussianBlur(round(14 * scale)))
    shadow = Image.new("RGBA", canvas.size, INK + (0,))
    shadow.putalpha(mask.point(lambda alpha: round(alpha * 0.19)))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(card, (left, top))


def creative(copy, captures, size):
    """Reflow the approved banner layout for the Header and Search aspect ratios."""
    width, height = size
    scale = width / 1024
    logical_height = height / scale
    offset = (logical_height - 500) / 2
    canvas = Image.new("RGBA", size, GREEN + (255,))
    draw = ImageDraw.Draw(canvas)

    def box(values):
        return tuple(round(value * scale) for value in values)

    def text(position, value, face, fill=INK):
        if draw.textlength(value, font=face) > 495 * scale:
            raise ValueError(f"Creative text exceeds its column: {value}")
        draw.text(box(position), value, font=face, fill=fill, anchor="lt")

    draw.ellipse(box((600, -30, 1170, logical_height + 40)), fill=(132, 222, 181))
    title_size = 60
    face = font(title_size * scale, "ExtraBold")
    while max(draw.textlength(line, font=face) for line in copy["headline"]) > 495 * scale:
        title_size -= 1
        face = font(title_size * scale, "ExtraBold")
    second_width = draw.textlength(copy["headline"][1], font=face) / scale
    draw.rounded_rectangle(box((51, 207 + offset, 78 + second_width, 283 + offset)),
                           radius=round(13 * scale), fill=CREAM)
    text((64, 141 + offset), copy["headline"][0], face)
    text((64, 213 + offset), copy["headline"][1], face)
    draw.line(box((64, 315 + offset, 110, 315 + offset)),
              fill=INK, width=round(2 * scale))
    text((64, 333 + offset), copy["encryption"], font(17 * scale, "Bold"))
    text((64, 360 + offset), copy["privacy"], font(17 * scale), MUTED)
    place_card(canvas, captures["01_chat_list"], (864, logical_height * 0.488),
               min(logical_height * 0.762, 464), -8, scale)
    place_card(canvas, captures["02_share_image"], (735, logical_height * 0.518),
               min(logical_height * 0.802, 490), 7, scale)
    return canvas.convert("RGB")


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, format="PNG", optimize=True)
    with Image.open(path) as exported:
        if exported.mode != "RGB" or exported.size != image.size:
            raise ValueError(f"Invalid export: {path}")
    return {"path": str(path), "size": list(image.size)}


def overview(images, labels, path):
    gap, label_height = 20, 30
    thumbs = []
    for image in images:
        thumb = image.copy()
        thumb.thumbnail((260, 560), Image.Resampling.LANCZOS)
        thumbs.append(thumb)
    sheet = Image.new("RGB", (sum(image.width for image in thumbs) + gap * (len(thumbs) + 1),
                              max(image.height for image in thumbs) + gap * 2 + label_height),
                      (244, 248, 245))
    draw = ImageDraw.Draw(sheet)
    x = gap
    for image, label in zip(thumbs, labels):
        draw.text((x, gap), label, font=font(13), fill=INK, anchor="lt")
        sheet.paste(image, (x, gap + label_height))
        x += image.width + gap
    save(sheet, path)


def write_guide(output):
    lines = [
        "# App Store assets", "",
        "German assets are in `de/`; English assets are in `en/`.", "",
        "| Asset | Location within each language folder | Size |",
        "| --- | --- | --- |",
    ]
    for placement, (width, height) in CREATIVES.items():
        lines.append(f"| {placement.title()} | `{placement}.png` | {width} × {height} |")
    for device, (width, height) in DEVICES.items():
        lines.append(f"| {device} screenshots | `{device}/` | {width} × {height} |")
    lines.extend([
        "", "Each device folder contains all six screenshots. All upload images are opaque",
        "RGB PNGs. The iPad versions reuse the real iPhone captures and preserve their",
        "aspect ratios. Existing 6.9-inch screenshots remain directly in each language folder.",
        "", "Contact sheets for review are in `previews/`; these are not upload assets.",
        "`asset_manifest.json` lists the generated upload files and sizes.",
        "", "Regenerate from the repository root:", "", "```sh",
        "python3 scripts/generate_app_store_assets.py", "```", "",
        "The screenshot capture workflow also generates these assets automatically.", "",
    ])
    (output / "README.md").write_text("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--raw-dir", type=Path,
                        default=ROOT / "build/store_screenshots/raw/ios")
    parser.add_argument("--captions", type=Path,
                        default=ROOT / "docs/screenshots/captions.json")
    parser.add_argument("--output", type=Path,
                        default=ROOT / "docs/screenshots/output/app-store")
    args = parser.parse_args()
    captions = json.loads(args.captions.read_text())
    exports = []
    for language, locale in LOCALES.items():
        source_dir = args.raw_dir / language
        if not source_dir.is_dir():
            continue
        captures = {name: load_capture(source_dir / f"{name}.png") for name in captions}
        target = args.output / language
        for placement, size in CREATIVES.items():
            image = creative(COPY[locale], captures, size)
            exports.append(save(image, target / f"{placement}.png"))
            print(f"{language}: {placement} at {size[0]} x {size[1]}", flush=True)
        for device, size in DEVICES.items():
            images = []
            for name, localized in captions.items():
                image = screenshot(captures[name], localized[language], size)
                exports.append(save(image, target / device / f"{name}.png"))
                images.append(image)
            overview(images, list(captions), args.output / "previews" / f"{device}-{language}.png")
            print(f"{language}: {len(images)} {device} screenshots at {size[0]} x {size[1]}",
                  flush=True)
    if not exports:
        parser.error(f"No localized iPhone captures found in {args.raw_dir}")
    for export in exports:
        export["path"] = str(Path(export["path"]).relative_to(args.output))
    (args.output / "asset_manifest.json").write_text(json.dumps(exports, indent=2) + "\n")
    write_guide(args.output)
    print(f"Saved and checked {len(exports)} upload assets in {args.output}")


if __name__ == "__main__":
    main()
