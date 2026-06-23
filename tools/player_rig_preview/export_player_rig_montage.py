#!/usr/bin/env python3
"""Export a PlayerSkeletonRig pose montage for visual QA.

The script uses Godot headless to sample real Sprite2D global transforms from
`res://player/player_skeleton_rig.tscn`, then composites the cutout textures
with Pillow. It intentionally writes the montage outside the repo by default.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import tempfile
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError as exc:  # pragma: no cover - local developer tool guard.
    raise SystemExit("Pillow is required: python3 -m pip install pillow") from exc


POSES: list[tuple[str, str, float]] = [
    ("idle", "idle", 0.0),
    ("walk 0.0", "walk", 0.0),
    ("walk 0.1", "walk", 0.1),
    ("walk 0.2", "walk", 0.2),
    ("walk 0.3", "walk", 0.3),
    ("walk 0.4", "walk", 0.4),
    ("walk 0.5", "walk", 0.5),
    ("walk 0.6", "walk", 0.6),
    ("run 0.0", "light_run", 0.0),
    ("run 0.068", "light_run", 0.06875),
    ("run 0.137", "light_run", 0.1375),
    ("run 0.206", "light_run", 0.20625),
    ("run 0.275", "light_run", 0.275),
    ("run 0.343", "light_run", 0.34375),
    ("run 0.412", "light_run", 0.4125),
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        default="/tmp/andry_player_rig_montage.png",
        help="PNG output path. Defaults to /tmp/andry_player_rig_montage.png.",
    )
    parser.add_argument(
        "--godot",
        default=os.environ.get("GODOT_BIN", "godot"),
        help="Godot executable. Defaults to GODOT_BIN or 'godot'.",
    )
    parser.add_argument("--scale", type=float, default=0.9, help="Montage cell scale.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[2]
    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="andry-rig-preview-") as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        dump_script = temp_dir / "dump_player_rig_pose.gd"
        dump_script.write_text(_build_godot_dump_script(temp_dir), encoding="utf-8")
        subprocess.run(
            [args.godot, "--headless", "--path", str(repo_root), "-s", str(dump_script)],
            cwd=repo_root,
            check=True,
        )
        pose_images = [_render_pose(repo_root, temp_dir / f"pose_{index}.json", label, args.scale) for index, (label, _, _) in enumerate(POSES)]
        _save_montage(pose_images, output_path)

    print(output_path)
    return 0


def _build_godot_dump_script(temp_dir: Path) -> str:
    pose_rows = ",\n\t".join(
        '{"animation": "%s", "time": %.8f, "path": "%s"}'
        % (animation, time, str((temp_dir / f"pose_{index}.json").as_posix()))
        for index, (_, animation, time) in enumerate(POSES)
    )
    return f'''extends SceneTree

const RIG_PATH := "res://player/player_skeleton_rig.tscn"
const POSES := [
\t{pose_rows}
]

func _initialize() -> void:
\t_deferred_dump.call_deferred()

func _deferred_dump() -> void:
\tawait process_frame
\tvar scene := load(RIG_PATH) as PackedScene
\tvar rig := scene.instantiate()
\troot.add_child(rig)
\tawait process_frame
\tvar animation_player := rig.get_node("SkeletonAnimationPlayer") as AnimationPlayer
\tvar visuals := _collect_visuals(rig)
\tfor pose in POSES:
\t\tanimation_player.play(StringName(pose["animation"]))
\t\tanimation_player.seek(float(pose["time"]), true)
\t\tawait process_frame
\t\tvar rows: Array = []
\t\tfor visual in visuals:
\t\t\tvar sprite := visual as Sprite2D
\t\t\tif sprite == null or sprite.texture == null:
\t\t\t\tcontinue
\t\t\tvar transform := sprite.get_global_transform()
\t\t\trows.append({{
\t\t\t\t"name": sprite.name,
\t\t\t\t"texture": String(sprite.texture.resource_path),
\t\t\t\t"visible": sprite.visible,
\t\t\t\t"z_index": sprite.z_index,
\t\t\t\t"centered": sprite.centered,
\t\t\t\t"offset": [sprite.offset.x, sprite.offset.y],
\t\t\t\t"origin": [transform.origin.x, transform.origin.y],
\t\t\t\t"x": [transform.x.x, transform.x.y],
\t\t\t\t"y": [transform.y.x, transform.y.y],
\t\t\t}})
\t\tvar file := FileAccess.open(String(pose["path"]), FileAccess.WRITE)
\t\tfile.store_string(JSON.stringify({{"visuals": rows}}))
\t\tfile.close()
\tquit()

func _collect_visuals(node: Node) -> Array:
\tvar result: Array = []
\tfor child in node.get_children():
\t\tif child is Sprite2D and String(child.name).begins_with("Visual"):
\t\t\tresult.append(child)
\t\tresult.append_array(_collect_visuals(child))
\treturn result
'''


def _render_pose(repo_root: Path, json_path: Path, label: str, scale: float) -> Image.Image:
    data = json.loads(json_path.read_text(encoding="utf-8"))
    texture_cache: dict[str, Image.Image] = {}
    visuals = [visual for visual in data["visuals"] if visual["visible"]]
    points: list[tuple[float, float]] = []
    for visual in visuals:
        texture = _load_texture(repo_root, texture_cache, visual["texture"])
        points.extend(_transformed_corners(texture, visual))
    min_x, max_x = min(x for x, _ in points), max(x for x, _ in points)
    min_y, max_y = min(y for _, y in points), max(y for _, y in points)
    padding = 18
    width = int((max_x - min_x + padding * 2) * scale)
    height = int((max_y - min_y + padding * 2) * scale) + 24
    canvas = Image.new("RGBA", (width, height), (25, 25, 29, 255))

    for visual in sorted(visuals, key=lambda item: item["z_index"]):
        texture = _load_texture(repo_root, texture_cache, visual["texture"])
        x_axis = visual["x"]
        y_axis = visual["y"]
        origin = visual["origin"]
        angle = math.degrees(math.atan2(x_axis[1], x_axis[0]))
        sx = math.hypot(x_axis[0], x_axis[1]) * scale
        sy = math.hypot(y_axis[0], y_axis[1]) * scale
        transformed = texture.resize(
            (max(1, int(texture.width * sx)), max(1, int(texture.height * sy))),
            Image.Resampling.BICUBIC,
        ).rotate(angle, expand=True, resample=Image.Resampling.BICUBIC)
        x = int((origin[0] - min_x + padding) * scale - transformed.width / 2)
        y = int((origin[1] - min_y + padding) * scale - transformed.height / 2)
        canvas.alpha_composite(transformed, (x, y))

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, height - 22, width, height), fill=(10, 10, 13, 235))
    draw.text((5, height - 18), label, fill=(245, 245, 245, 255))
    return canvas


def _load_texture(repo_root: Path, cache: dict[str, Image.Image], resource_path: str) -> Image.Image:
    if resource_path not in cache:
        cache[resource_path] = Image.open(repo_root / resource_path.removeprefix("res://")).convert("RGBA")
    return cache[resource_path]


def _transformed_corners(texture: Image.Image, visual: dict) -> list[tuple[float, float]]:
    if visual["centered"]:
        base_corners = [
            (-texture.width / 2, -texture.height / 2),
            (texture.width / 2, -texture.height / 2),
            (texture.width / 2, texture.height / 2),
            (-texture.width / 2, texture.height / 2),
        ]
    else:
        base_corners = [(0, 0), (texture.width, 0), (texture.width, texture.height), (0, texture.height)]
    offset_x, offset_y = visual["offset"]
    origin_x, origin_y = visual["origin"]
    x_axis = visual["x"]
    y_axis = visual["y"]
    return [
        (
            origin_x + x_axis[0] * (x + offset_x) + y_axis[0] * (y + offset_y),
            origin_y + x_axis[1] * (x + offset_x) + y_axis[1] * (y + offset_y),
        )
        for x, y in base_corners
    ]


def _save_montage(images: list[Image.Image], output_path: Path) -> None:
    columns = 5
    cell_width = max(image.width for image in images)
    cell_height = max(image.height for image in images)
    rows = math.ceil(len(images) / columns)
    montage = Image.new("RGBA", (columns * cell_width, rows * cell_height), (8, 8, 11, 255))
    for index, image in enumerate(images):
        x = (index % columns) * cell_width + (cell_width - image.width) // 2
        y = (index // columns) * cell_height + (cell_height - image.height) // 2
        montage.alpha_composite(image, (x, y))
    montage.save(output_path)


if __name__ == "__main__":
    raise SystemExit(main())
