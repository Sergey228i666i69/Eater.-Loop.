#!/usr/bin/env python3
"""Export a scene-context PlayerSkeletonRig preview for visual QA.

The montage preview isolates the cutout rig on a dark background. This script
uses the same real Godot Sprite2D transforms, but composites them into a small
room-like scene with a door behind the player and a foreground object in front.
It catches z-order regressions where an internal body part falls behind level
objects.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageOps
except ImportError as exc:  # pragma: no cover - local developer tool guard.
    raise SystemExit("Pillow is required: python3 -m pip install pillow") from exc

SCRIPT_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(SCRIPT_DIR))

from export_player_rig_montage import (  # noqa: E402
    _build_godot_dump_script,
    _load_texture,
    _transformed_corners,
)


DEFAULT_OUTPUT = Path("/tmp/andry_player_rig_scene_context.png")
PANEL_SIZE = (560, 720)
DARK_CLOSEUP_PANEL_SIZE = (520, 720)
PLAYER_ROOT_Z = 2
BEHIND_OBJECT_Z = 1
FOREGROUND_OBJECT_Z = 10
PLAYER_VISUAL_SCALE = 0.4480088
PLAYER_FLOOR_Y = 650
DARK_CLOSEUP_PLAYER_SCALE = 0.70
DARK_CLOSEUP_PLAYER_FLOOR_Y = 660
SCENE_POSES: list[tuple[str, str, float]] = [
    ("idle", "idle", 0.0),
    ("walk contact", "walk", 0.2),
    ("run contact", "light_run", 0.1375),
]
POSE_ANIMATIONS = ("idle", "walk", "light_run")

WALL_TEXTURE = "objects/environment/background/BackWalls.png"
FLOOR_TEXTURE = "objects/environment/background/Floor.png"
PLINTUS_TEXTURE = "objects/environment/background/Plintus.png"
BEHIND_DOOR_TEXTURE = "objects/interactable/door/sprites/DoorBasic.png"
FOREGROUND_CHAIR_TEXTURE = "objects/environment/sprites/bedroom/ChairBedroom.png"
LAYER_OVERLAY_COLORS: dict[str, tuple[int, int, int, int]] = {
    "VisualHead": (255, 220, 0, 172),
    "VisualNeckCollarCover": (255, 0, 255, 190),
    "VisualTorso": (100, 100, 100, 155),
    "VisualPelvis": (255, 0, 130, 145),
    "VisualSeamFill": (210, 0, 255, 172),
    "VisualBackUpperArm": (0, 130, 255, 150),
    "VisualBackForearm": (0, 220, 255, 150),
    "VisualBackHand": (0, 255, 180, 155),
    "VisualFrontUpperArm": (255, 120, 0, 150),
    "VisualFrontForearm": (255, 220, 0, 150),
    "VisualFrontHand": (255, 55, 0, 165),
    "VisualFrontHandEmpty": (255, 55, 0, 165),
    "VisualBackThigh": (0, 152, 255, 160),
    "VisualBackShin": (0, 220, 255, 160),
    "VisualBackFoot": (0, 255, 180, 165),
    "VisualFrontThigh": (255, 165, 0, 160),
    "VisualFrontShin": (255, 220, 0, 160),
    "VisualFrontFoot": (255, 75, 0, 165),
    "VisualFlashlight": (255, 255, 255, 190),
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="PNG output path.")
    parser.add_argument(
        "--godot",
        default=os.environ.get("GODOT_BIN", "godot"),
        help="Godot executable. Defaults to GODOT_BIN or 'godot'.",
    )
    parser.add_argument("--flashlight", action="store_true", help="Show the held flashlight cutout.")
    parser.add_argument(
        "--scale",
        type=float,
        default=PLAYER_VISUAL_SCALE,
        help="Scene preview scale for the unscaled skeleton rig. Defaults to the active player scene scale.",
    )
    parser.add_argument(
        "--dark-closeup",
        action="store_true",
        help="Render one darker close-up frame for screenshot-like rig QA instead of the three-panel sheet.",
    )
    parser.add_argument(
        "--pose-animation",
        choices=POSE_ANIMATIONS,
        default="idle",
        help="Animation sampled by --dark-closeup. Defaults to idle.",
    )
    parser.add_argument(
        "--pose-time",
        type=float,
        default=0.0,
        help="Animation time sampled by --dark-closeup. Defaults to 0.0.",
    )
    parser.add_argument(
        "--layer-overlay",
        action="store_true",
        help="Render player Visual* layers as colored silhouettes for cutout/z-order diagnosis.",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    poses = _resolve_scene_poses(args.dark_closeup, args.pose_animation, args.pose_time)

    with tempfile.TemporaryDirectory(prefix="andry-rig-scene-context-") as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        dump_script = temp_dir / "dump_player_rig_scene_context.gd"
        dump_script.write_text(_build_godot_dump_script(temp_dir, args.flashlight, poses), encoding="utf-8")
        subprocess.run(
            [args.godot, "--headless", "--path", str(repo_root), "-s", str(dump_script)],
            cwd=repo_root,
            check=True,
        )
        pose_data = [
            json.loads((temp_dir / f"pose_{index}.json").read_text(encoding="utf-8"))
            for index in range(len(poses))
        ]

    if args.dark_closeup:
        panel = _render_dark_closeup_panel(repo_root, pose_data[0], poses[0][0], args.scale, args.layer_overlay)
        panel.save(output_path)
    else:
        panels = [
            _render_scene_panel(repo_root, pose_data[index], label, args.scale, args.layer_overlay)
            for index, (label, _, _) in enumerate(poses)
        ]
        _save_scene_sheet(panels, output_path)
    print(output_path)
    return 0


def _resolve_scene_poses(dark_closeup: bool, pose_animation: str, pose_time: float) -> list[tuple[str, str, float]]:
    if not dark_closeup:
        return SCENE_POSES
    label = f"{pose_animation} {pose_time:.3f}"
    return [(label, pose_animation, pose_time)]


def _render_scene_panel(repo_root: Path, data: dict, label: str, scale: float, layer_overlay: bool = False) -> Image.Image:
    panel = _render_room_background(repo_root, PANEL_SIZE)
    layers: list[tuple[int, Image.Image, tuple[int, int]]] = []
    layers.append((BEHIND_OBJECT_Z, _scaled_asset(repo_root, BEHIND_DOOR_TEXTURE, 0.68), (260, 110)))
    layers.extend(_build_player_visual_layers(repo_root, data, scale, layer_overlay=layer_overlay))
    layers.append((FOREGROUND_OBJECT_Z, _scaled_asset(repo_root, FOREGROUND_CHAIR_TEXTURE, 0.32), (290, 390)))

    for _z, image, position in sorted(layers, key=lambda layer: layer[0]):
        panel.alpha_composite(image, position)

    darkness = Image.new("RGBA", panel.size, (0, 0, 16, 58))
    panel.alpha_composite(darkness)
    draw = ImageDraw.Draw(panel)
    draw.rectangle((0, 0, PANEL_SIZE[0], 34), fill=(7, 7, 10, 220))
    overlay_label = " | layer overlay" if layer_overlay else ""
    draw.text((10, 9), f"{label} | door z1, player z2+, chair z10{overlay_label}", fill=(245, 245, 245, 255))
    return panel


def _render_dark_closeup_panel(
    repo_root: Path,
    data: dict,
    label: str,
    base_scale: float,
    layer_overlay: bool = False,
) -> Image.Image:
    panel = _render_room_background(repo_root, DARK_CLOSEUP_PANEL_SIZE)
    layers: list[tuple[int, Image.Image, tuple[int, int]]] = []
    layers.append((BEHIND_OBJECT_Z, _scaled_asset(repo_root, BEHIND_DOOR_TEXTURE, 0.9), (235, 78)))
    closeup_scale = DARK_CLOSEUP_PLAYER_SCALE if base_scale == PLAYER_VISUAL_SCALE else base_scale
    layers.extend(
        _build_player_visual_layers(
            repo_root,
            data,
            closeup_scale,
            DARK_CLOSEUP_PANEL_SIZE,
            DARK_CLOSEUP_PLAYER_FLOOR_Y,
            player_x=250,
            layer_overlay=layer_overlay,
        )
    )
    for _z, image, position in sorted(layers, key=lambda layer: layer[0]):
        panel.alpha_composite(image, position)

    darkness = Image.new("RGBA", panel.size, (0, 0, 18, 118))
    panel.alpha_composite(darkness)
    draw = ImageDraw.Draw(panel)
    draw.rectangle((0, 0, DARK_CLOSEUP_PANEL_SIZE[0], 30), fill=(7, 7, 10, 225))
    overlay_label = " | layer overlay" if layer_overlay else ""
    draw.text((10, 8), f"{label} | dark close-up{overlay_label}", fill=(245, 245, 245, 255))
    return panel


def _render_room_background(repo_root: Path, panel_size: tuple[int, int]) -> Image.Image:
    width, height = panel_size
    wall_height = 465
    floor_y = 440
    panel = Image.new("RGBA", panel_size, (18, 17, 20, 255))
    wall = ImageOps.fit(_open_asset(repo_root, WALL_TEXTURE), (width, wall_height), method=Image.Resampling.LANCZOS)
    floor = ImageOps.fit(_open_asset(repo_root, FLOOR_TEXTURE), (width, height - floor_y), method=Image.Resampling.LANCZOS)
    plintus = _open_asset(repo_root, PLINTUS_TEXTURE)
    plintus = plintus.resize((width, max(1, int(plintus.height * width / plintus.width))), Image.Resampling.LANCZOS)
    panel.alpha_composite(wall, (0, 0))
    panel.alpha_composite(floor, (0, floor_y))
    panel.alpha_composite(plintus, (0, floor_y - plintus.height // 2))
    return panel


def _build_player_visual_layers(
    repo_root: Path,
    data: dict,
    scale: float,
    panel_size: tuple[int, int] = PANEL_SIZE,
    floor_y: int = PLAYER_FLOOR_Y,
    player_x: int | None = None,
    layer_overlay: bool = False,
) -> list[tuple[int, Image.Image, tuple[int, int]]]:
    texture_cache: dict[str, Image.Image] = {}
    visuals = [visual for visual in data["visuals"] if visual["visible"]]
    points: list[tuple[float, float]] = []
    for visual in visuals:
        texture = _load_texture(repo_root, texture_cache, visual["texture"])
        points.extend(_transformed_corners(texture, visual))
    min_x = min(x for x, _ in points)
    max_x = max(x for x, _ in points)
    max_y = max(y for _, y in points)
    center_x = (min_x + max_x) / 2.0
    if player_x is None:
        player_x = panel_size[0] // 2

    layers: list[tuple[int, Image.Image, tuple[int, int]]] = []
    for visual in visuals:
        texture = _load_texture(repo_root, texture_cache, visual["texture"])
        if layer_overlay:
            texture = _build_layer_overlay_texture(texture, visual["name"])
        transformed = _transform_texture(texture, visual, scale)
        origin_x, origin_y = visual["origin"]
        x = int(player_x + (origin_x - center_x) * scale - transformed.width / 2)
        y = int(floor_y + (origin_y - max_y) * scale - transformed.height / 2)
        layers.append((PLAYER_ROOT_Z + int(visual["z_index"]), transformed, (x, y)))
    return layers


def _build_layer_overlay_texture(texture: Image.Image, visual_name: str) -> Image.Image:
    alpha = texture.getchannel("A")
    color = LAYER_OVERLAY_COLORS.get(visual_name)
    if color is None:
        dimmed = texture.copy()
        dimmed.putalpha(alpha.point(lambda value: int(value * 0.22)))
        return dimmed
    overlay = Image.new("RGBA", texture.size, color)
    overlay.putalpha(alpha.point(lambda value: min(int(value * color[3] / 255), color[3])))
    return overlay


def _transform_texture(texture: Image.Image, visual: dict, scale: float) -> Image.Image:
    x_axis = visual["x"]
    y_axis = visual["y"]
    angle = math.degrees(math.atan2(x_axis[1], x_axis[0]))
    sx = math.hypot(x_axis[0], x_axis[1]) * scale
    sy = math.hypot(y_axis[0], y_axis[1]) * scale
    return texture.resize(
        (max(1, int(texture.width * sx)), max(1, int(texture.height * sy))),
        Image.Resampling.BICUBIC,
    ).rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)


def _scaled_asset(repo_root: Path, resource_path: str, scale: float) -> Image.Image:
    image = _open_asset(repo_root, resource_path)
    return image.resize((max(1, int(image.width * scale)), max(1, int(image.height * scale))), Image.Resampling.LANCZOS)


def _open_asset(repo_root: Path, resource_path: str) -> Image.Image:
    return Image.open(repo_root / resource_path).convert("RGBA")


def _save_scene_sheet(panels: list[Image.Image], output_path: Path) -> None:
    width, height = panels[0].size
    sheet = Image.new("RGBA", (width * len(panels), height), (8, 8, 11, 255))
    for index, panel in enumerate(panels):
        sheet.alpha_composite(panel, (index * width, 0))
    sheet.save(output_path)


if __name__ == "__main__":
    raise SystemExit(main())
