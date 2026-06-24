#!/usr/bin/env python3
"""Export a PlayerSkeletonRig pose montage for visual QA.

The script uses Godot headless to sample real visual transforms from a skeleton
rig scene, then composites Sprite2D and weighted Polygon2D cutout textures with
Pillow. It intentionally writes the montage outside the repo by default.
"""

from __future__ import annotations

import argparse
import json
import math
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Optional

try:
    from PIL import Image, ImageDraw
except ImportError as exc:  # pragma: no cover - local developer tool guard.
    raise SystemExit("Pillow is required: python3 -m pip install pillow") from exc


DEFAULT_RIG_PATH = "res://player/player_skeleton_rig.tscn"
DEFAULT_ANIMATION_PLAYER_PATH = "SkeletonAnimationPlayer"
ANIMATION_LENGTHS: dict[str, float] = {
    "idle": 1.6,
    "walk": 0.8,
    "light_walk": 0.8,
    "run": 0.55,
    "light_run": 0.55,
    "forearm_mesh_flex": 0.8,
}

DEFAULT_MONTAGE_POSES: list[tuple[str, str, float]] = [
    ("idle 0.0", "idle", 0.0),
    ("idle 0.8", "idle", 0.8),
    ("walk 0.0", "walk", 0.0),
    ("walk 0.1", "walk", 0.1),
    ("walk 0.2", "walk", 0.2),
    ("walk 0.3", "walk", 0.3),
    ("walk 0.4", "walk", 0.4),
    ("walk 0.5", "walk", 0.5),
    ("walk 0.6", "walk", 0.6),
    ("light_walk 0.0", "light_walk", 0.0),
    ("light_walk 0.2", "light_walk", 0.2),
    ("light_walk 0.4", "light_walk", 0.4),
    ("light_walk 0.6", "light_walk", 0.6),
    ("run 0.0", "run", 0.0),
    ("run 0.137", "run", 0.1375),
    ("run 0.275", "run", 0.275),
    ("run 0.412", "run", 0.4125),
    ("light_run 0.0", "light_run", 0.0),
    ("light_run 0.137", "light_run", 0.1375),
    ("light_run 0.275", "light_run", 0.275),
    ("light_run 0.412", "light_run", 0.4125),
]

RUNTIME_MOTION_POSES: list[tuple[str, str, float, bool]] = [
    ("idle no-flash 0.0", "idle", 0.0, False),
    ("idle no-flash 0.8", "idle", 0.8, False),
    ("idle flashlight 0.0", "idle", 0.0, True),
    ("idle flashlight 0.8", "idle", 0.8, True),
    ("walk no-flash 0.0", "walk", 0.0, False),
    ("walk no-flash 0.2", "walk", 0.2, False),
    ("walk no-flash 0.4", "walk", 0.4, False),
    ("walk no-flash 0.6", "walk", 0.6, False),
    ("light_walk flashlight 0.0", "light_walk", 0.0, True),
    ("light_walk flashlight 0.2", "light_walk", 0.2, True),
    ("light_walk flashlight 0.4", "light_walk", 0.4, True),
    ("light_walk flashlight 0.6", "light_walk", 0.6, True),
    ("run no-flash 0.0", "run", 0.0, False),
    ("run no-flash 0.137", "run", 0.1375, False),
    ("run no-flash 0.275", "run", 0.275, False),
    ("run no-flash 0.412", "run", 0.4125, False),
    ("light_run flashlight 0.0", "light_run", 0.0, True),
    ("light_run flashlight 0.137", "light_run", 0.1375, True),
    ("light_run flashlight 0.275", "light_run", 0.275, True),
    ("light_run flashlight 0.412", "light_run", 0.4125, True),
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
    parser.add_argument(
        "--rig-path",
        default=DEFAULT_RIG_PATH,
        help=f"Rig scene path to sample. Defaults to {DEFAULT_RIG_PATH}.",
    )
    parser.add_argument(
        "--animation-player-path",
        default=DEFAULT_ANIMATION_PLAYER_PATH,
        help=f"AnimationPlayer node path inside the rig. Defaults to {DEFAULT_ANIMATION_PLAYER_PATH}.",
    )
    parser.add_argument(
        "--flashlight",
        action="store_true",
        help="Force the flashlight cutout visible in the preview montage.",
    )
    parser.add_argument(
        "--sequence-animation",
        help="Export evenly sampled frames for one animation instead of the default pose montage.",
    )
    parser.add_argument(
        "--runtime-motion-set",
        action="store_true",
        help="Export runtime-real idle/walk/run poses for no-flashlight and flashlight states in one montage.",
    )
    parser.add_argument(
        "--sequence-length",
        type=float,
        help="Animation length for custom --sequence-animation values.",
    )
    parser.add_argument(
        "--sequence-frames",
        type=int,
        default=12,
        help="Frame count for --sequence-animation. Defaults to 12.",
    )
    parser.add_argument(
        "--fps",
        type=int,
        default=12,
        help="Animated GIF playback speed for --sequence-animation outputs ending in .gif. Defaults to 12.",
    )
    parser.add_argument("--scale", type=float, default=0.9, help="Montage cell scale.")
    args = parser.parse_args()

    if args.sequence_frames <= 0:
        raise SystemExit("--sequence-frames must be greater than 0")
    if args.fps <= 0:
        raise SystemExit("--fps must be greater than 0")

    repo_root = Path(__file__).resolve().parents[2]
    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    if args.sequence_animation and args.runtime_motion_set:
        raise SystemExit("--runtime-motion-set cannot be combined with --sequence-animation")

    poses = _resolve_poses(
        args.sequence_animation,
        args.sequence_frames,
        args.sequence_length,
        args.flashlight,
        args.runtime_motion_set,
    )

    with tempfile.TemporaryDirectory(prefix="andry-rig-preview-") as temp_dir_name:
        temp_dir = Path(temp_dir_name)
        dump_script = temp_dir / "dump_player_rig_pose.gd"
        dump_script.write_text(
            _build_godot_dump_script(temp_dir, args.rig_path, args.animation_player_path, poses),
            encoding="utf-8",
        )
        subprocess.run(
            [args.godot, "--headless", "--path", str(repo_root), "-s", str(dump_script)],
            cwd=repo_root,
            check=True,
        )
        pose_data = [json.loads((temp_dir / f"pose_{index}.json").read_text(encoding="utf-8")) for index in range(len(poses))]
        shared_bounds = _calculate_shared_bounds(repo_root, pose_data) if args.sequence_animation else None
        pose_images = [
            _render_pose(repo_root, pose_data[index], label, args.scale, shared_bounds)
            for index, (label, _, _, _) in enumerate(poses)
        ]
        if args.sequence_animation and output_path.suffix.lower() == ".gif":
            _save_sequence_gif(pose_images, output_path, args.fps)
        else:
            _save_montage(pose_images, output_path)

    print(output_path)
    return 0


def _resolve_poses(
    sequence_animation: str | None,
    sequence_frames: int,
    sequence_length: float | None,
    show_flashlight: bool,
    runtime_motion_set: bool,
) -> list[tuple[str, str, float, bool]]:
    if runtime_motion_set:
        return RUNTIME_MOTION_POSES
    if not sequence_animation:
        return [(label, animation, time, show_flashlight) for label, animation, time in DEFAULT_MONTAGE_POSES]
    animation_length = sequence_length if sequence_length is not None else ANIMATION_LENGTHS.get(sequence_animation)
    if animation_length is None:
        raise SystemExit("--sequence-length is required for custom --sequence-animation values")
    return [
        (f"{sequence_animation} {index:02d}", sequence_animation, animation_length * index / sequence_frames, show_flashlight)
        for index in range(sequence_frames)
    ]


def _build_godot_dump_script(
    temp_dir: Path,
    rig_path: str,
    animation_player_path: str,
    poses: list[tuple[str, str, float, bool]],
) -> str:
    pose_rows = ",\n\t".join(
        '{"animation": "%s", "time": %.8f, "show_flashlight": %s, "path": "%s"}'
        % (animation, time, str(show_flashlight).lower(), str((temp_dir / f"pose_{index}.json").as_posix()))
        for index, (_, animation, time, show_flashlight) in enumerate(poses)
    )
    return f'''extends SceneTree

const RIG_PATH := "{rig_path}"
const ANIMATION_PLAYER_PATH := "{animation_player_path}"
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
\tvar animation_player := rig.get_node(ANIMATION_PLAYER_PATH) as AnimationPlayer
\tvar held_hand := rig.get_node_or_null("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/VisualFrontHand") as CanvasItem
\tvar empty_hand := rig.get_node_or_null("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/VisualFrontHandEmpty") as CanvasItem
\tvar flashlight := rig.get_node_or_null("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/FlashlightMount/VisualFlashlight") as CanvasItem
\tvar visuals := _collect_visuals(rig)
\tfor pose in POSES:
\t\tvar show_flashlight := bool(pose["show_flashlight"])
\t\tif held_hand != null:
\t\t\theld_hand.visible = show_flashlight
\t\tif empty_hand != null:
\t\t\tempty_hand.visible = not show_flashlight
\t\tif flashlight != null:
\t\t\tflashlight.visible = show_flashlight
\t\tanimation_player.play(StringName(pose["animation"]))
\t\tanimation_player.seek(float(pose["time"]), true)
\t\tawait process_frame
\t\tvar rows: Array = []
\t\tfor visual in visuals:
\t\t\tvar sprite := visual as Sprite2D
\t\t\tif sprite != null:
\t\t\t\tif sprite.texture == null:
\t\t\t\t\tcontinue
\t\t\t\tvar transform := sprite.get_global_transform()
\t\t\t\trows.append({{
\t\t\t\t\t"type": "sprite",
\t\t\t\t\t"name": sprite.name,
\t\t\t\t\t"texture": String(sprite.texture.resource_path),
\t\t\t\t\t"visible": sprite.visible,
\t\t\t\t\t"z_index": sprite.z_index,
\t\t\t\t\t"centered": sprite.centered,
\t\t\t\t\t"offset": [sprite.offset.x, sprite.offset.y],
\t\t\t\t\t"origin": [transform.origin.x, transform.origin.y],
\t\t\t\t\t"x": [transform.x.x, transform.x.y],
\t\t\t\t\t"y": [transform.y.x, transform.y.y],
\t\t\t\t}})
\t\t\t\tcontinue
\t\t\tvar polygon := visual as Polygon2D
\t\t\tif polygon != null:
\t\t\t\tif polygon.texture == null:
\t\t\t\t\tcontinue
\t\t\t\tvar transform := polygon.get_global_transform()
\t\t\t\trows.append({{
\t\t\t\t\t"type": "polygon",
\t\t\t\t\t"name": polygon.name,
\t\t\t\t\t"texture": String(polygon.texture.resource_path),
\t\t\t\t\t"visible": polygon.visible,
\t\t\t\t\t"z_index": polygon.z_index,
\t\t\t\t\t"origin": [transform.origin.x, transform.origin.y],
\t\t\t\t\t"x": [transform.x.x, transform.x.y],
\t\t\t\t\t"y": [transform.y.x, transform.y.y],
\t\t\t\t\t"polygon": _vector2_array_to_rows(polygon.polygon),
\t\t\t\t\t"uv": _vector2_array_to_rows(polygon.uv),
\t\t\t\t\t"internal_vertex_count": polygon.internal_vertex_count,
\t\t\t\t\t"bones": _polygon_bone_rows(polygon),
\t\t\t\t}})
\t\tvar file := FileAccess.open(String(pose["path"]), FileAccess.WRITE)
\t\tfile.store_string(JSON.stringify({{"visuals": rows}}))
\t\tfile.close()
\tquit()

func _collect_visuals(node: Node) -> Array:
\tvar result: Array = []
\tfor child in node.get_children():
\t\tif child is Sprite2D and String(child.name).begins_with("Visual"):
\t\t\tresult.append(child)
\t\telif child is Polygon2D and (String(child.name).begins_with("Visual") or String(child.name).begins_with("Mesh")):
\t\t\tresult.append(child)
\t\tresult.append_array(_collect_visuals(child))
\treturn result

func _vector2_array_to_rows(values: PackedVector2Array) -> Array:
\tvar rows: Array = []
\tfor value in values:
\t\trows.append([value.x, value.y])
\treturn rows

func _transform_to_row(transform: Transform2D) -> Dictionary:
\treturn {{
\t\t"origin": [transform.origin.x, transform.origin.y],
\t\t"x": [transform.x.x, transform.x.y],
\t\t"y": [transform.y.x, transform.y.y],
\t}}

func _polygon_bone_rows(polygon: Polygon2D) -> Array:
\tvar rows: Array = []
\tfor index in range(polygon.get_bone_count()):
\t\tvar bone_path := polygon.get_bone_path(index)
\t\tvar bone := polygon.get_node_or_null(bone_path) as Bone2D
\t\tif bone == null:
\t\t\tcontinue
\t\trows.append({{
\t\t\t"path": String(bone_path),
\t\t\t"weights": Array(polygon.get_bone_weights(index)),
\t\t\t"current_transform": _transform_to_row(bone.get_global_transform()),
\t\t\t"rest_transform": _transform_to_row(bone.get_skeleton_rest()),
\t\t}})
\treturn rows
'''


def _calculate_shared_bounds(repo_root: Path, pose_data: list[dict]) -> tuple[float, float, float, float]:
    texture_cache: dict[str, Image.Image] = {}
    points: list[tuple[float, float]] = []
    for data in pose_data:
        for visual in data["visuals"]:
            if not visual["visible"]:
                continue
            texture = _load_texture(repo_root, texture_cache, visual["texture"])
            points.extend(_visual_points(texture, visual))
    min_x, max_x = min(x for x, _ in points), max(x for x, _ in points)
    min_y, max_y = min(y for _, y in points), max(y for _, y in points)
    return min_x, min_y, max_x, max_y


def _render_pose(repo_root: Path, data: dict, label: str, scale: float, bounds: Optional[tuple[float, float, float, float]] = None) -> Image.Image:
    texture_cache: dict[str, Image.Image] = {}
    visuals = [visual for visual in data["visuals"] if visual["visible"]]
    if bounds:
        min_x, min_y, max_x, max_y = bounds
    else:
        points: list[tuple[float, float]] = []
        for visual in visuals:
            texture = _load_texture(repo_root, texture_cache, visual["texture"])
            points.extend(_visual_points(texture, visual))
        min_x, max_x = min(x for x, _ in points), max(x for x, _ in points)
        min_y, max_y = min(y for _, y in points), max(y for _, y in points)
    padding = 18
    width = int((max_x - min_x + padding * 2) * scale)
    height = int((max_y - min_y + padding * 2) * scale) + 24
    canvas = Image.new("RGBA", (width, height), (25, 25, 29, 255))

    for visual in sorted(visuals, key=lambda item: item["z_index"]):
        texture = _load_texture(repo_root, texture_cache, visual["texture"])
        _render_visual(canvas, texture, visual, scale, min_x, min_y, padding)

    draw = ImageDraw.Draw(canvas)
    draw.rectangle((0, height - 22, width, height), fill=(10, 10, 13, 235))
    draw.text((5, height - 18), label, fill=(245, 245, 245, 255))
    return canvas


def _load_texture(repo_root: Path, cache: dict[str, Image.Image], resource_path: str) -> Image.Image:
    if resource_path not in cache:
        cache[resource_path] = Image.open(repo_root / resource_path.removeprefix("res://")).convert("RGBA")
    return cache[resource_path]


def _visual_points(texture: Image.Image, visual: dict) -> list[tuple[float, float]]:
    if visual.get("type", "sprite") == "polygon":
        return _polygon_deformed_points(visual)
    return _transformed_corners(texture, visual)


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


def _render_visual(canvas: Image.Image, texture: Image.Image, visual: dict, scale: float, min_x: float, min_y: float, padding: int) -> None:
    if visual.get("type", "sprite") == "polygon":
        _render_polygon_visual(canvas, texture, visual, scale, min_x, min_y, padding)
        return
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


def _render_polygon_visual(canvas: Image.Image, texture: Image.Image, visual: dict, scale: float, min_x: float, min_y: float, padding: int) -> None:
    destination_points = [
        ((x - min_x + padding) * scale, (y - min_y + padding) * scale)
        for x, y in _polygon_deformed_points(visual)
    ]
    uv_points = [(float(x), float(y)) for x, y in visual["uv"]]
    layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    for i0, i1, i2 in _polygon_triangle_indices(visual):
        destination_triangle = [destination_points[i0], destination_points[i1], destination_points[i2]]
        source_triangle = [uv_points[i0], uv_points[i1], uv_points[i2]]
        layer.alpha_composite(_warp_texture_triangle(texture, canvas.size, source_triangle, destination_triangle))
    canvas.alpha_composite(layer)


def _polygon_triangle_indices(visual: dict) -> list[tuple[int, int, int]]:
    points = [(index, float(value[0]), float(value[1])) for index, value in enumerate(visual["polygon"])]
    rows: dict[int, list[tuple[int, float]]] = {}
    for index, x, y in points:
        rows.setdefault(round(y), []).append((index, x))
    ordered_rows = []
    for y in sorted(rows):
        row = sorted(rows[y], key=lambda item: item[1])
        if len(row) == 2:
            ordered_rows.append((row[0][0], row[1][0]))
    if len(ordered_rows) >= 2:
        triangles: list[tuple[int, int, int]] = []
        for row_index in range(len(ordered_rows) - 1):
            left_top, right_top = ordered_rows[row_index]
            left_bottom, right_bottom = ordered_rows[row_index + 1]
            triangles.append((left_top, right_top, right_bottom))
            triangles.append((left_top, right_bottom, left_bottom))
        return triangles
    outline_count = max(3, len(points) - int(visual.get("internal_vertex_count", 0)))
    return [(0, index, index + 1) for index in range(1, outline_count - 1)]


def _warp_texture_triangle(
    texture: Image.Image,
    output_size: tuple[int, int],
    source_triangle: list[tuple[float, float]],
    destination_triangle: list[tuple[float, float]],
) -> Image.Image:
    coefficients = _affine_coefficients(destination_triangle, source_triangle)
    warped = texture.transform(output_size, Image.Transform.AFFINE, coefficients, resample=Image.Resampling.BICUBIC)
    mask = Image.new("L", output_size, 0)
    ImageDraw.Draw(mask).polygon(destination_triangle, fill=255)
    warped.putalpha(Image.composite(warped.getchannel("A"), Image.new("L", output_size, 0), mask))
    return warped


def _affine_coefficients(
    destination_triangle: list[tuple[float, float]],
    source_triangle: list[tuple[float, float]],
) -> tuple[float, float, float, float, float, float]:
    (x0, y0), (x1, y1), (x2, y2) = destination_triangle
    (u0, v0), (u1, v1), (u2, v2) = source_triangle
    determinant = x0 * (y1 - y2) + x1 * (y2 - y0) + x2 * (y0 - y1)
    if abs(determinant) < 0.000001:
        return (1, 0, 0, 0, 1, 0)
    a = (u0 * (y1 - y2) + u1 * (y2 - y0) + u2 * (y0 - y1)) / determinant
    b = (u0 * (x2 - x1) + u1 * (x0 - x2) + u2 * (x1 - x0)) / determinant
    c = (u0 * (x1 * y2 - x2 * y1) + u1 * (x2 * y0 - x0 * y2) + u2 * (x0 * y1 - x1 * y0)) / determinant
    d = (v0 * (y1 - y2) + v1 * (y2 - y0) + v2 * (y0 - y1)) / determinant
    e = (v0 * (x2 - x1) + v1 * (x0 - x2) + v2 * (x1 - x0)) / determinant
    f = (v0 * (x1 * y2 - x2 * y1) + v1 * (x2 * y0 - x0 * y2) + v2 * (x0 * y1 - x1 * y0)) / determinant
    return (a, b, c, d, e, f)


def _polygon_deformed_points(visual: dict) -> list[tuple[float, float]]:
    points = []
    for vertex_index, point in enumerate(visual["polygon"]):
        base_point = _transform_point(visual, (float(point[0]), float(point[1])))
        total_weight = 0.0
        x = 0.0
        y = 0.0
        for bone in visual.get("bones", []):
            weights = bone["weights"]
            if vertex_index >= len(weights):
                continue
            weight = float(weights[vertex_index])
            if weight <= 0.0:
                continue
            total_weight += weight
            rest_space = _inverse_transform_point(bone["rest_transform"], base_point)
            current_point = _transform_point(bone["current_transform"], rest_space)
            x += current_point[0] * weight
            y += current_point[1] * weight
        if total_weight < 1.0:
            x += base_point[0] * (1.0 - total_weight)
            y += base_point[1] * (1.0 - total_weight)
        points.append((x, y))
    return points


def _transform_point(transform: dict, point: tuple[float, float]) -> tuple[float, float]:
    x_axis = transform["x"]
    y_axis = transform["y"]
    origin = transform["origin"]
    return (
        origin[0] + x_axis[0] * point[0] + y_axis[0] * point[1],
        origin[1] + x_axis[1] * point[0] + y_axis[1] * point[1],
    )


def _inverse_transform_point(transform: dict, point: tuple[float, float]) -> tuple[float, float]:
    x_axis = transform["x"]
    y_axis = transform["y"]
    origin = transform["origin"]
    px = point[0] - origin[0]
    py = point[1] - origin[1]
    determinant = x_axis[0] * y_axis[1] - x_axis[1] * y_axis[0]
    if abs(determinant) < 0.000001:
        return (px, py)
    return (
        (y_axis[1] * px - y_axis[0] * py) / determinant,
        (-x_axis[1] * px + x_axis[0] * py) / determinant,
    )


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


def _save_sequence_gif(images: list[Image.Image], output_path: Path, fps: int) -> None:
    cell_width = max(image.width for image in images)
    cell_height = max(image.height for image in images)
    frames: list[Image.Image] = []
    for image in images:
        frame = Image.new("RGBA", (cell_width, cell_height), (8, 8, 11, 255))
        x = (cell_width - image.width) // 2
        y = (cell_height - image.height) // 2
        frame.alpha_composite(image, (x, y))
        frames.append(frame.convert("P", palette=Image.Palette.ADAPTIVE))
    frames[0].save(
        output_path,
        save_all=True,
        append_images=frames[1:],
        duration=int(1000 / fps),
        loop=0,
        disposal=2,
    )


if __name__ == "__main__":
    raise SystemExit(main())
