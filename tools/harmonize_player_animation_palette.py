#!/usr/bin/env python3
"""Harmonize character animation frames to match the reference idle sprite palette and tone."""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path


def load_rgba(image_path: Path) -> tuple[int, int, bytearray]:
    out = subprocess.check_output(["identify", "-format", "%w %h", str(image_path)]).decode().strip().split()
    width, height = int(out[0]), int(out[1])
    raw = subprocess.check_output(["magick", str(image_path), "rgba:-"])
    return width, height, bytearray(raw)


def save_rgba(output_path: Path, width: int, height: int, raw_bytes: bytes | bytearray) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    proc = subprocess.Popen(
        ["magick", "-size", f"{width}x{height}", "-depth", "8", "rgba:-", f"png32:{output_path}"],
        stdin=subprocess.PIPE,
    )
    proc.communicate(input=raw_bytes)
    if proc.returncode != 0:
        raise RuntimeError(f"Failed to save image to {output_path}")


def compute_channel_stats(raw_bytes: bytearray, alpha_threshold: int = 64) -> list[tuple[float, float]]:
    """Return [(mean_R, std_R), (mean_G, std_G), (mean_B, std_B)] for pixels above alpha threshold."""
    channel_vals: list[list[int]] = [[], [], []]
    for i in range(0, len(raw_bytes), 4):
        if raw_bytes[i + 3] > alpha_threshold:
            channel_vals[0].append(raw_bytes[i])
            channel_vals[1].append(raw_bytes[i + 1])
            channel_vals[2].append(raw_bytes[i + 2])

    stats: list[tuple[float, float]] = []
    for c in range(3):
        vals = channel_vals[c]
        if not vals:
            stats.append((0.0, 0.0))
            continue
        mean = sum(vals) / len(vals)
        variance = sum((x - mean) ** 2 for x in vals) / len(vals)
        stats.append((mean, variance ** 0.5))
    return stats


def compute_cdfs(raw_bytes: bytearray, alpha_threshold: int = 64) -> list[list[float]]:
    """Return CDFs for R, G, B channels."""
    hists = [[0] * 256, [0] * 256, [0] * 256]
    total = 0
    for i in range(0, len(raw_bytes), 4):
        if raw_bytes[i + 3] > alpha_threshold:
            hists[0][raw_bytes[i]] += 1
            hists[1][raw_bytes[i + 1]] += 1
            hists[2][raw_bytes[i + 2]] += 1
            total += 1

    cdfs: list[list[float]] = []
    for c in range(3):
        cdf = [0.0] * 256
        acc = 0
        for v in range(256):
            acc += hists[c][v]
            cdf[v] = acc / total if total > 0 else 0.0
        cdfs.append(cdf)
    return cdfs


def build_linear_lut(ref_stats: list[tuple[float, float]], src_stats: list[tuple[float, float]]) -> list[bytes]:
    """Build linear gain/offset LUT per channel."""
    luts: list[bytes] = []
    for c in range(3):
        m_ref, s_ref = ref_stats[c]
        m_src, s_src = src_stats[c]
        gain = (s_ref / s_src) if s_src > 0.001 else 1.0
        offset = m_ref - gain * m_src
        table = bytes([max(0, min(255, int(round(v * gain + offset)))) for v in range(256)])
        luts.append(table)
    return luts


def build_cdf_lut(cdf_ref: list[list[float]], cdf_src: list[list[float]]) -> list[bytes]:
    """Build monotonic smoothed CDF matching LUT per channel."""
    luts: list[bytes] = []
    for c in range(3):
        raw_map = [0] * 256
        ref_idx = 0
        for v in range(256):
            target = cdf_src[c][v]
            while ref_idx < 255 and cdf_ref[c][ref_idx] < target:
                ref_idx += 1
            raw_map[v] = ref_idx

        # 3-tap monotonic smoothing
        smooth_map = [0] * 256
        for v in range(256):
            v_min = max(0, v - 2)
            v_max = min(255, v + 2)
            smooth_map[v] = int(round(sum(raw_map[v_min:v_max + 1]) / (v_max - v_min + 1)))
        for v in range(1, 256):
            if smooth_map[v] < smooth_map[v - 1]:
                smooth_map[v] = smooth_map[v - 1]
        luts.append(bytes(smooth_map))
    return luts


def apply_lut(raw_bytes: bytearray, luts: list[bytes]) -> bytearray:
    """Apply R, G, B LUTs while leaving Alpha intact."""
    result = bytearray(raw_bytes)
    result[0::4] = raw_bytes[0::4].translate(luts[0])
    result[1::4] = raw_bytes[1::4].translate(luts[1])
    result[2::4] = raw_bytes[2::4].translate(luts[2])
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--reference",
        type=Path,
        default=Path("player/AndryWithFlashlight.png"),
        help="Reference idle image for target color palette and tone.",
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=Path("player/animations/walking"),
        help="Directory containing walking animation frames to harmonize.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Optional output directory. If omitted, files in --input-dir will be updated in-place.",
    )
    parser.add_argument(
        "--method",
        choices=["linear", "cdf"],
        default="linear",
        help="Color matching algorithm ('linear' for exact dynamic range/mean match, 'cdf' for histogram curve match).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print color analysis and adjustments without modifying files.",
    )
    parser.add_argument(
        "--comparison-montage",
        type=Path,
        default=None,
        help="Optional path to save a before/after visual comparison montage.",
    )
    args = parser.parse_args()

    ref_path = args.reference.resolve()
    if not ref_path.exists():
        print(f"Error: Reference image not found: {ref_path}", file=sys.stderr)
        return 1

    input_dir = args.input_dir.resolve()
    if not input_dir.exists():
        print(f"Error: Input directory not found: {input_dir}", file=sys.stderr)
        return 1

    out_dir = args.output_dir.resolve() if args.output_dir else input_dir

    print(f"=== Character Animation Palette Harmonizer ===")
    print(f"Reference: {ref_path}")
    print(f"Input dir: {input_dir}")
    print(f"Output dir: {out_dir}")
    print(f"Method: {args.method}")
    print(f"Dry run: {args.dry_run}\n")

    w_ref, h_ref, raw_ref = load_rgba(ref_path)
    ref_stats = compute_channel_stats(raw_ref)
    ref_cdf = compute_cdfs(raw_ref)

    print(f"Reference Stats (Idle):")
    print(f"  R: mean={ref_stats[0][0]:.2f}, std={ref_stats[0][1]:.2f}")
    print(f"  G: mean={ref_stats[1][0]:.2f}, std={ref_stats[1][1]:.2f}")
    print(f"  B: mean={ref_stats[2][0]:.2f}, std={ref_stats[2][1]:.2f}\n")

    frame_files = sorted([f for f in input_dir.iterdir() if f.suffix.lower() == ".png"])
    if not frame_files:
        print(f"No PNG frames found in {input_dir}", file=sys.stderr)
        return 1

    print(f"Processing {len(frame_files)} frames...\n")
    print(f"{'Frame':<20} | {'Before (R, G, B)':<28} | {'After (R, G, B)':<28}")
    print("-" * 82)

    processed_frames: list[tuple[str, Path, Path, bytearray, bytearray]] = []

    for frame_path in frame_files:
        w_src, h_src, raw_src = load_rgba(frame_path)
        src_stats = compute_channel_stats(raw_src)

        if args.method == "linear":
            luts = build_linear_lut(ref_stats, src_stats)
        else:
            src_cdf = compute_cdfs(raw_src)
            luts = build_cdf_lut(ref_cdf, src_cdf)

        adjusted_raw = apply_lut(raw_src, luts)
        after_stats = compute_channel_stats(adjusted_raw)

        before_str = f"({src_stats[0][0]:.1f}, {src_stats[1][0]:.1f}, {src_stats[2][0]:.1f})"
        after_str = f"({after_stats[0][0]:.1f}, {after_stats[1][0]:.1f}, {after_stats[2][0]:.1f})"
        print(f"{frame_path.name:<20} | {before_str:<28} | {after_str:<28}")

        target_path = out_dir / frame_path.name
        if not args.dry_run:
            save_rgba(target_path, w_src, h_src, adjusted_raw)

        processed_frames.append((frame_path.name, frame_path, target_path, raw_src, adjusted_raw))

    print("-" * 82)
    print("Harmonization completed successfully!")

    if args.comparison_montage and not args.dry_run:
        _create_comparison_montage(
            args.comparison_montage,
            ref_path,
            processed_frames,
        )
        print(f"\nSaved comparison montage: {args.comparison_montage}")

    return 0


def _create_comparison_montage(
    output_montage_path: Path,
    ref_path: Path,
    frames: list[tuple[str, Path, Path, bytearray, bytearray]],
) -> None:
    """Create a side-by-side visual contact sheet of Reference, Before, and After."""
    # Create temp thumbnails and composite them with magick
    output_montage_path.parent.mkdir(parents=True, exist_ok=True)
    temp_dir = Path("/tmp/andry_montage_temp")
    temp_dir.mkdir(parents=True, exist_ok=True)

    # Pick representative frames: 001, 005, 009, 013
    sample_indices = [0, 4, 8, 12]
    cmd = [
        "magick",
        "(", str(ref_path), "-resize", "180x", "-background", "#1e1e24", "-flatten", "-set", "label", "REFERENCE (Idle)", ")",
    ]
    for idx in sample_indices:
        if idx < len(frames):
            name, src_p, dst_p, _, _ = frames[idx]
            cmd.extend([
                "(", str(src_p), "-resize", "180x", "-background", "#1e1e24", "-flatten", "-set", "label", f"Before {name}", ")",
                "(", str(dst_p), "-resize", "180x", "-background", "#1e1e24", "-flatten", "-set", "label", f"After {name}", ")",
            ])

    cmd.extend([
        "-background", "#121216",
        "-fill", "#f0f0f0",
        "-pointsize", "14",
        "+append",
        str(output_montage_path),
    ])
    subprocess.run(cmd, check=True)


if __name__ == "__main__":
    raise SystemExit(main())
