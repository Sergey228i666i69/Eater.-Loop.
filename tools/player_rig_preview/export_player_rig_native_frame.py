#!/usr/bin/env python3
"""Export a real Godot-rendered PlayerSkeletonRig pose frame for visual QA.

Unlike the montage and scene-context tools, this script does not recompose
cutout layers in Pillow. It asks Godot to draw the rig into a SubViewport and
saves the resulting canvas texture, so Polygon2D visibility regressions show up
the same way they would in the game renderer.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import tempfile
from pathlib import Path


DEFAULT_RIG_PATH = "res://player/player_skeleton_rig.tscn"
DEFAULT_ANIMATION_PLAYER_PATH = "SkeletonAnimationPlayer"
DEFAULT_OUTPUT = Path("/tmp/andry_player_rig_native_frame.png")
POSE_ANIMATIONS = ("idle", "light_idle", "walk", "light_walk", "run", "light_run")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        default=str(DEFAULT_OUTPUT),
        help=f"PNG output path. Defaults to {DEFAULT_OUTPUT}.",
    )
    parser.add_argument(
        "--godot",
        default=os.environ.get("GODOT_BIN", "godot"),
        help="Godot executable. Defaults to GODOT_BIN or 'godot'.",
    )
    parser.add_argument(
        "--rig-path",
        default=DEFAULT_RIG_PATH,
        help=f"Rig scene path to render. Defaults to {DEFAULT_RIG_PATH}.",
    )
    parser.add_argument(
        "--animation-player-path",
        default=DEFAULT_ANIMATION_PLAYER_PATH,
        help=f"AnimationPlayer node path inside the rig. Defaults to {DEFAULT_ANIMATION_PLAYER_PATH}.",
    )
    parser.add_argument(
        "--animation",
        default="light_run",
        choices=POSE_ANIMATIONS,
        help="Animation to sample. Defaults to light_run.",
    )
    parser.add_argument("--time", type=float, default=0.1375, help="Animation time to sample. Defaults to 0.1375.")
    parser.add_argument(
        "--flashlight",
        action="store_true",
        help="Force flashlight hand/beam layers visible. light_* animations enable this automatically.",
    )
    parser.add_argument("--width", type=int, default=512, help="Viewport width. Defaults to 512.")
    parser.add_argument("--height", type=int, default=832, help="Viewport height. Defaults to 832.")
    parser.add_argument("--origin-x", type=float, default=256.0, help="Rig root x position in the viewport.")
    parser.add_argument("--origin-y", type=float, default=390.0, help="Rig root y position in the viewport.")
    parser.add_argument("--scale", type=float, default=1.0, help="Rig scale in the viewport.")
    args = parser.parse_args()

    if args.width <= 0 or args.height <= 0:
        raise SystemExit("--width and --height must be positive")
    if args.scale <= 0.0:
        raise SystemExit("--scale must be positive")

    repo_root = Path(__file__).resolve().parents[2]
    output_path = Path(args.output).expanduser().resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    show_flashlight = args.flashlight or args.animation.startswith("light_")

    with tempfile.TemporaryDirectory(prefix="andry-rig-native-frame-") as temp_dir_name:
        script_path = Path(temp_dir_name) / "export_player_rig_native_frame.gd"
        script_path.write_text(
            _build_godot_render_script(
                output_path=output_path,
                rig_path=args.rig_path,
                animation_player_path=args.animation_player_path,
                animation=args.animation,
                time=args.time,
                show_flashlight=show_flashlight,
                width=args.width,
                height=args.height,
                origin_x=args.origin_x,
                origin_y=args.origin_y,
                scale=args.scale,
            ),
            encoding="utf-8",
        )
        # Godot's headless dummy renderer cannot provide a SubViewport texture;
        # this tool intentionally uses a render-capable launch.
        subprocess.run([args.godot, "--path", str(repo_root), "-s", str(script_path)], cwd=repo_root, check=True)

    print(output_path)
    return 0


def _build_godot_render_script(
    *,
    output_path: Path,
    rig_path: str,
    animation_player_path: str,
    animation: str,
    time: float,
    show_flashlight: bool,
    width: int,
    height: int,
    origin_x: float,
    origin_y: float,
    scale: float,
) -> str:
    return f"""extends SceneTree

const OUTPUT_PATH := {json.dumps(output_path.as_posix())}
const RIG_PATH := {json.dumps(rig_path)}
const ANIMATION_PLAYER_PATH := {json.dumps(animation_player_path)}
const POSE_ANIMATION := {json.dumps(animation)}
const POSE_TIME := {time:.8f}
const SHOW_FLASHLIGHT := {str(show_flashlight).lower()}
const VIEWPORT_SIZE := Vector2i({width}, {height})
const RIG_ORIGIN := Vector2({origin_x:.4f}, {origin_y:.4f})
const RIG_SCALE := {scale:.6f}

func _initialize() -> void:
\t_render_frame.call_deferred()

func _render_frame() -> void:
\tRenderingServer.set_default_clear_color(Color(0.07, 0.07, 0.085, 1.0))

\tvar viewport := SubViewport.new()
\tviewport.name = "NativeRigViewport"
\tviewport.size = VIEWPORT_SIZE
\tviewport.transparent_bg = false
\tviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
\troot.add_child(viewport)

\tvar canvas := Node2D.new()
\tcanvas.name = "NativeRigCanvas"
\tviewport.add_child(canvas)

\tvar scene := load(RIG_PATH) as PackedScene
\tif scene == null:
\t\tpush_error("Could not load rig scene: " + RIG_PATH)
\t\tquit(1)
\t\treturn

\tvar rig := scene.instantiate() as Node2D
\tif rig == null:
\t\tpush_error("Rig scene root must be a Node2D: " + RIG_PATH)
\t\tquit(1)
\t\treturn

\tcanvas.add_child(rig)
\trig.position = RIG_ORIGIN
\trig.scale = Vector2(RIG_SCALE, RIG_SCALE)
\t_set_runtime_flashlight_layers(rig, SHOW_FLASHLIGHT)

\tawait process_frame

\tvar animation_player := rig.get_node_or_null(ANIMATION_PLAYER_PATH) as AnimationPlayer
\tif animation_player == null:
\t\tpush_error("Could not find AnimationPlayer: " + ANIMATION_PLAYER_PATH)
\t\tquit(1)
\t\treturn

\tanimation_player.play(StringName(POSE_ANIMATION))
\tanimation_player.seek(POSE_TIME, true)

\tfor _frame in range(4):
\t\tawait process_frame
\tif RenderingServer.has_method("force_draw"):
\t\tRenderingServer.call("force_draw")

\tvar image := viewport.get_texture().get_image()
\tif image == null or image.is_empty():
\t\tpush_error("Native rig viewport rendered an empty image")
\t\tquit(1)
\t\treturn

\tvar error := image.save_png(OUTPUT_PATH)
\tif error != OK:
\t\tpush_error("Could not save native rig frame: " + OUTPUT_PATH)
\t\tquit(1)
\t\treturn

\tquit()

func _set_runtime_flashlight_layers(rig: Node, show_flashlight: bool) -> void:
\tvar held_hand := rig.get_node_or_null("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/VisualFrontHand") as CanvasItem
\tvar empty_hand := rig.get_node_or_null("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/VisualFrontHandEmpty") as CanvasItem
\tvar flashlight := rig.get_node_or_null("Skeleton2D/Hips/Spine/Chest/FrontUpperArm/FrontForearm/FrontHand/FlashlightMount/VisualFlashlight") as CanvasItem
\tif held_hand != null:
\t\theld_hand.visible = show_flashlight
\tif empty_hand != null:
\t\tempty_hand.visible = not show_flashlight
\tif flashlight != null:
\t\tflashlight.visible = show_flashlight
"""


if __name__ == "__main__":
    raise SystemExit(main())
