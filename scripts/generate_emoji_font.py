#!/usr/bin/env python3
"""Generate the app's subsetted Noto Color Emoji font.

The full upstream font is kept outside Flutter's asset directory so it is not
packaged accidentally. The subset contains every code point referenced by the
emoji picker, including the skin-tone modifiers that are applied at runtime.
"""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import tempfile


SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent

DEFAULT_SOURCE_FONT = SCRIPT_DIR / "data" / "NotoColorEmoji.ttf"
DEFAULT_OUTPUT_FONT = PROJECT_ROOT / "assets" / "fonts" / "NotoColorEmoji.ttf"
DEFAULT_EMOJI_SET = (
    PROJECT_ROOT
    / "lib"
    / "src"
    / "visual"
    / "components"
    / "emoji_picker"
    / "default_emoji_set.dart"
)
DEFAULT_SKIN_TONES = (
    PROJECT_ROOT
    / "lib"
    / "src"
    / "visual"
    / "components"
    / "emoji_picker"
    / "skin_tones"
    / "emoji_skin_tones.dart"
)

DART_STRING_CONTENT = r"((?:\\.|[^'\\])*)"
EMOJI_PATTERN = re.compile(r"\bEmoji\s*\(\s*'" + DART_STRING_CONTENT + r"'")
SKIN_TONE_PATTERN = re.compile(
    r"\bstatic\s+const\s+String\s+\w+\s*=\s*'"
    + DART_STRING_CONTENT
    + r"'"
)


class GenerationError(RuntimeError):
    """Raised when the subset font cannot be generated safely."""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source-font",
        type=Path,
        default=DEFAULT_SOURCE_FONT,
        help=f"full input font (default: {DEFAULT_SOURCE_FONT})",
    )
    parser.add_argument(
        "--output-font",
        type=Path,
        default=DEFAULT_OUTPUT_FONT,
        help=f"generated Flutter asset (default: {DEFAULT_OUTPUT_FONT})",
    )
    parser.add_argument(
        "--font-subset",
        type=Path,
        help="path to Flutter's font-subset executable",
    )
    return parser.parse_args()


def require_file(path: Path, description: str) -> Path:
    path = path.expanduser().resolve()
    if not path.is_file():
        raise GenerationError(f"{description} not found: {path}")
    return path


def decode_dart_string(value: str) -> str:
    """Decode the Dart escapes that can occur in an emoji string literal."""

    value = re.sub(
        r"\\u\{([0-9a-fA-F]+)\}",
        lambda match: chr(int(match.group(1), 16)),
        value,
    )
    value = re.sub(
        r"\\u([0-9a-fA-F]{4})",
        lambda match: chr(int(match.group(1), 16)),
        value,
    )
    value = value.replace(r"\'", "'").replace(r"\\", "\\")
    if "\\" in value:
        raise GenerationError(f"unsupported escape in emoji literal: {value!r}")
    return value


def read_supported_emoji() -> tuple[list[str], set[int]]:
    emoji_source = require_file(DEFAULT_EMOJI_SET, "emoji picker data").read_text(
        encoding="utf-8"
    )
    skin_tone_source = require_file(DEFAULT_SKIN_TONES, "skin-tone data").read_text(
        encoding="utf-8"
    )

    emoji = [decode_dart_string(value) for value in EMOJI_PATTERN.findall(emoji_source)]
    skin_tones = [
        decode_dart_string(value)
        for value in SKIN_TONE_PATTERN.findall(skin_tone_source)
    ]

    # A very low result means the Dart format changed and silently generating an
    # almost-empty font would be worse than failing the build helper.
    if len(emoji) < 100:
        raise GenerationError(
            f"found only {len(emoji)} emoji entries; the picker parser needs updating"
        )
    if len(skin_tones) != 5:
        raise GenerationError(
            f"expected 5 skin-tone modifiers, found {len(skin_tones)}"
        )

    codepoints = {ord(character) for value in emoji + skin_tones for character in value}
    return emoji, codepoints


def flutter_root() -> Path:
    configured_root = os.environ.get("FLUTTER_ROOT")
    if configured_root:
        return Path(configured_root).expanduser().resolve()

    flutter = shutil.which("flutter")
    if flutter is None:
        raise GenerationError(
            "Flutter was not found on PATH; set FLUTTER_ROOT or pass --font-subset"
        )
    return Path(flutter).resolve().parent.parent


def find_font_subsetter(override: Path | None) -> Path:
    if override is not None:
        subsetter = require_file(override, "font-subset executable")
        if not os.access(subsetter, os.X_OK):
            raise GenerationError(f"font-subset is not executable: {subsetter}")
        return subsetter

    engine_artifacts = flutter_root() / "bin" / "cache" / "artifacts" / "engine"
    executable_name = "font-subset.exe" if os.name == "nt" else "font-subset"
    candidates = list(engine_artifacts.glob(f"*/{executable_name}"))
    executable_candidates = [path for path in candidates if os.access(path, os.X_OK)]
    if not executable_candidates:
        raise GenerationError(
            "Flutter's font-subset executable is missing. Run a Flutter command "
            "to populate the engine cache, then try again."
        )

    host_prefix = {
        "Darwin": "darwin-",
        "Linux": "linux-",
        "Windows": "windows-",
    }.get(platform.system())
    if host_prefix:
        host_candidates = [
            path
            for path in executable_candidates
            if path.parent.name.startswith(host_prefix)
        ]
        if host_candidates:
            return sorted(host_candidates)[0]

    if len(executable_candidates) == 1:
        return executable_candidates[0]
    raise GenerationError(
        "could not select a host font-subset executable; pass --font-subset explicitly"
    )


def generate_font(
    source_font: Path,
    output_font: Path,
    subsetter: Path,
    codepoints: set[int],
) -> None:
    output_font = output_font.expanduser().resolve()
    if source_font == output_font:
        raise GenerationError("source and output font paths must be different")

    output_font.parent.mkdir(parents=True, exist_ok=True)
    subset_input = " ".join(
        f"optional:{codepoint}" for codepoint in sorted(codepoints)
    ) + "\n"

    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            prefix=f".{output_font.stem}.",
            suffix=output_font.suffix,
            dir=output_font.parent,
            delete=False,
        ) as temporary_file:
            temporary_path = Path(temporary_file.name)

        result = subprocess.run(
            [str(subsetter), str(temporary_path), str(source_font)],
            input=subset_input,
            text=True,
            capture_output=True,
            check=False,
        )
        if result.returncode != 0:
            details = "\n".join(
                part.strip() for part in (result.stdout, result.stderr) if part.strip()
            )
            raise GenerationError(
                f"font-subset failed with exit code {result.returncode}:\n{details}"
            )

        if temporary_path.stat().st_size == 0:
            raise GenerationError("font-subset produced an empty file")
        if temporary_path.read_bytes()[:4] not in {b"\x00\x01\x00\x00", b"OTTO", b"ttcf"}:
            raise GenerationError("font-subset output is not a recognized font")

        temporary_path.chmod(source_font.stat().st_mode & 0o777)
        temporary_path.replace(output_font)
        temporary_path = None
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def format_size(byte_count: int) -> str:
    return f"{byte_count / 1_000_000:.2f} MB"


def main() -> int:
    try:
        args = parse_args()
        source_font = require_file(args.source_font, "full Noto Color Emoji font")
        subsetter = find_font_subsetter(args.font_subset)
        emoji, codepoints = read_supported_emoji()
        generate_font(source_font, args.output_font, subsetter, codepoints)

        output_font = args.output_font.expanduser().resolve()
        source_size = source_font.stat().st_size
        output_size = output_font.stat().st_size
        saved = source_size - output_size
        print(
            f"Generated {output_font}\n"
            f"  Picker entries: {len(emoji)}\n"
            f"  Unique code points: {len(codepoints)}\n"
            f"  Full font: {format_size(source_size)}\n"
            f"  Subset font: {format_size(output_size)}\n"
            f"  Saved: {format_size(saved)} ({saved / source_size:.1%})"
        )
        return 0
    except GenerationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
