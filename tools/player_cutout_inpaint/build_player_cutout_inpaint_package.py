#!/usr/bin/env python3
"""Build controlled inpaint packages for Andry skeleton cutouts.

The generated package is meant for image-edit tools that accept an input image
and mask. Existing visible pixels are kept locked; only transparent space around
the current cutout is marked editable.
"""

from __future__ import annotations

import argparse
import json
from dataclasses import asdict, dataclass
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw, ImageFilter
except ImportError as exc:  # pragma: no cover - local developer tool guard.
    raise SystemExit("Pillow is required: python3 -m pip install pillow") from exc


REPO_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT_DIR = Path("/tmp/andry-cutout-inpaint")


@dataclass(frozen=True)
class TargetSpec:
    cutout: str
    source: str
    source_crop: tuple[int, int, int, int]
    prompt_focus: str
    mask_margin: int = 18
    slot_size: int = 256


TARGETS: dict[str, TargetSpec] = {
    "front_thigh": TargetSpec(
        cutout="front_thigh.png",
        source="player/Andry.png",
        source_crop=(42, 360, 145, 735),
        prompt_focus="complete the trouser front thigh as one continuous pajama-cloth limb segment hidden behind the hand and the other leg",
        mask_margin=20,
    ),
    "back_thigh": TargetSpec(
        cutout="back_thigh.png",
        source="player/Andry.png",
        source_crop=(92, 360, 174, 735),
        prompt_focus="complete the trouser back thigh as one continuous pajama-cloth limb segment hidden by the front leg",
        mask_margin=20,
    ),
    "front_shin": TargetSpec(
        cutout="front_shin.png",
        source="player/Andry.png",
        source_crop=(45, 485, 125, 742),
        prompt_focus="complete the front lower trouser leg as one continuous shin segment with the same blue plaid fabric",
        mask_margin=18,
    ),
    "back_shin": TargetSpec(
        cutout="back_shin.png",
        source="player/Andry.png",
        source_crop=(112, 485, 194, 742),
        prompt_focus="complete the back lower trouser leg as one continuous shin segment with the same blue plaid fabric",
        mask_margin=18,
    ),
    "front_hand": TargetSpec(
        cutout="front_hand.png",
        source="player/AndryWithFlashlight.png",
        source_crop=(18, 370, 125, 462),
        prompt_focus="complete only the visible gripping hand shape, preserving the fingers and warm skin tones while removing trouser fragments",
        mask_margin=12,
    ),
    "back_hand": TargetSpec(
        cutout="back_hand.png",
        source="player/Andry.png",
        source_crop=(150, 372, 220, 455),
        prompt_focus="complete only the relaxed back hand shape, preserving finger proportions and warm skin tones",
        mask_margin=12,
    ),
    "flashlight": TargetSpec(
        cutout="flashlight.png",
        source="player/AndryWithFlashlight.png",
        source_crop=(16, 382, 125, 450),
        prompt_focus="complete the missing middle of the black metal flashlight handle hidden behind the hand, without changing the visible ends",
        mask_margin=10,
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    target_group = parser.add_mutually_exclusive_group(required=True)
    target_group.add_argument("--target", choices=sorted(TARGETS), help="Cutout target to package.")
    target_group.add_argument("--all", action="store_true", help="Build packages for every known target.")
    parser.add_argument("--out-dir", default=str(DEFAULT_OUT_DIR), help="Output directory.")
    args = parser.parse_args()

    out_dir = Path(args.out_dir).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    target_names = sorted(TARGETS) if args.all else [args.target]
    for target_name in target_names:
        _build_package(target_name, TARGETS[target_name], out_dir / target_name)
    print(out_dir)
    return 0


def _build_package(target_name: str, spec: TargetSpec, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    source = Image.open(REPO_ROOT / spec.source).convert("RGBA")
    cutout = Image.open(REPO_ROOT / "player/skeleton/cutouts" / spec.cutout).convert("RGBA")
    source_crop = source.crop(spec.source_crop)
    edit_canvas, paste_xy = _build_edit_canvas(cutout, spec.slot_size)
    mask = _build_mask(cutout, spec.slot_size, paste_xy, spec.mask_margin)
    preview = _build_preview(source_crop, cutout, edit_canvas, mask, target_name)
    prompt = _build_prompt(target_name, spec)

    edit_canvas.save(out_dir / f"{target_name}_edit_canvas.png")
    mask.save(out_dir / f"{target_name}_mask.png")
    preview.save(out_dir / f"{target_name}_reference_sheet.png")
    (out_dir / f"{target_name}_prompt.txt").write_text(prompt + "\n", encoding="utf-8")
    metadata = {
        "target": target_name,
        "spec": asdict(spec),
        "edit_canvas": f"{target_name}_edit_canvas.png",
        "mask": f"{target_name}_mask.png",
        "reference_sheet": f"{target_name}_reference_sheet.png",
        "prompt": f"{target_name}_prompt.txt",
        "locked_pixels_note": "Mask is black over existing cutout pixels and white only over nearby transparent completion space.",
    }
    (out_dir / f"{target_name}_metadata.json").write_text(json.dumps(metadata, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _build_edit_canvas(cutout: Image.Image, slot_size: int) -> tuple[Image.Image, tuple[int, int]]:
    if cutout.width > slot_size or cutout.height > slot_size:
        raise ValueError(f"Cutout {cutout.size} does not fit slot size {slot_size}")
    canvas = Image.new("RGBA", (slot_size, slot_size), (0, 0, 0, 0))
    paste_xy = ((slot_size - cutout.width) // 2, (slot_size - cutout.height) // 2)
    canvas.alpha_composite(cutout, paste_xy)
    return canvas, paste_xy


def _build_mask(cutout: Image.Image, slot_size: int, paste_xy: tuple[int, int], margin: int) -> Image.Image:
    alpha = cutout.getchannel("A")
    bbox = alpha.getbbox()
    if bbox is None:
        raise ValueError("Cutout has no opaque pixels")
    x0, y0, x1, y1 = bbox
    px, py = paste_xy
    expanded = (
        max(0, px + x0 - margin),
        max(0, py + y0 - margin),
        min(slot_size, px + x1 + margin),
        min(slot_size, py + y1 + margin),
    )
    editable = Image.new("L", (slot_size, slot_size), 0)
    ImageDraw.Draw(editable).rectangle(expanded, fill=255)

    locked = Image.new("L", (slot_size, slot_size), 0)
    locked.paste(alpha.point(lambda value: 255 if value > 12 else 0), paste_xy)
    editable = ImageChops.subtract(editable, locked)
    editable = editable.filter(ImageFilter.GaussianBlur(0.4)).point(lambda value: 255 if value > 8 else 0)
    return editable


def _build_preview(
    source_crop: Image.Image,
    cutout: Image.Image,
    edit_canvas: Image.Image,
    mask: Image.Image,
    target_name: str,
) -> Image.Image:
    panels = [
        ("source crop", source_crop),
        ("current cutout", cutout),
        ("edit canvas + mask", _overlay_mask(edit_canvas, mask)),
    ]
    cell_width = 300
    cell_height = 330
    sheet = Image.new("RGB", (cell_width * len(panels), cell_height), (20, 20, 24))
    for index, (label, image) in enumerate(panels):
        panel = _checker_panel(cell_width, cell_height, label, image)
        if index == 0:
            ImageDraw.Draw(panel).text((8, 8), target_name, fill=(245, 245, 245))
        sheet.paste(panel, (index * cell_width, 0))
    return sheet


def _checker_panel(width: int, height: int, label: str, image: Image.Image) -> Image.Image:
    label_height = 26
    checker = Image.new("RGBA", (width, height - label_height), (45, 45, 50, 255))
    draw = ImageDraw.Draw(checker)
    for y in range(0, checker.height, 16):
        for x in range(0, checker.width, 16):
            if (x // 16 + y // 16) % 2 == 0:
                draw.rectangle((x, y, x + 15, y + 15), fill=(70, 70, 75, 255))
    scale = min((width - 24) / image.width, (checker.height - 24) / image.height)
    resized = image.resize(
        (max(1, int(image.width * scale)), max(1, int(image.height * scale))),
        Image.Resampling.LANCZOS,
    )
    checker.alpha_composite(resized, ((width - resized.width) // 2, (checker.height - resized.height) // 2))
    panel = Image.new("RGBA", (width, height), (12, 12, 15, 255))
    panel.alpha_composite(checker, (0, 0))
    panel_draw = ImageDraw.Draw(panel)
    panel_draw.rectangle((0, height - label_height, width, height), fill=(8, 8, 11, 255))
    panel_draw.text((8, height - label_height + 7), label, fill=(235, 235, 235, 255))
    return panel.convert("RGB")


def _overlay_mask(edit_canvas: Image.Image, mask: Image.Image) -> Image.Image:
    overlay = edit_canvas.copy()
    red = Image.new("RGBA", overlay.size, (255, 80, 80, 105))
    overlay.alpha_composite(Image.composite(red, Image.new("RGBA", overlay.size, (0, 0, 0, 0)), mask))
    return overlay


def _build_prompt(target_name: str, spec: TargetSpec) -> str:
    return "\n".join(
        [
            "Edit the provided transparent cutout canvas for the Godot 2D character Andry.",
            "The visible existing pixels are locked by the mask and must remain unchanged.",
            f"Target cutout: {target_name}.",
            f"Task: {spec.prompt_focus}.",
            "Preserve the exact same character, facing direction, body proportions, fabric scale, color palette, lighting, texture sharpness, and photo-cutout style.",
            "Only fill the white mask area; do not add scenery, labels, outlines, shadows outside the original cutout style, or a new pose.",
            "Return a transparent PNG in the same canvas size with the original visible pixels unchanged.",
        ]
    )


if __name__ == "__main__":
    raise SystemExit(main())
