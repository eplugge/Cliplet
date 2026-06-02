#!/usr/bin/env bash
# Convert a screen recording of Cliplet into an optimized gif for the README.
# Usage: Scripts/gif-from-recording.sh <input.mov|mp4> [output.gif]
# Env: FPS (default 15), WIDTH (default 900), START (trim start, e.g. 0:02),
#      DUR (clip length seconds), CROP (ffmpeg crop "w:h:x:y").
set -euo pipefail
IN="${1:?usage: gif-from-recording.sh <input.mov> [out.gif]}"
OUT="${2:-/Users/eelco/dev/cliplet/docs/images/demo.gif}"
FPS="${FPS:-15}"
WIDTH="${WIDTH:-900}"
PALETTE="$(mktemp -t cliplet-pal).png"
trap 'rm -f "$PALETTE"' EXIT

# Optional trim/crop.
TRIM=()
[ -n "${START:-}" ] && TRIM+=(-ss "$START")
[ -n "${DUR:-}" ] && TRIM+=(-t "$DUR")
VF_CROP=""
[ -n "${CROP:-}" ] && VF_CROP="crop=${CROP},"

FILTERS="${VF_CROP}fps=${FPS},scale=${WIDTH}:-1:flags=lanczos"

# Two-pass: generate an optimized palette, then apply it (best quality/size).
ffmpeg -y "${TRIM[@]}" -i "$IN" -vf "${FILTERS},palettegen=stats_mode=diff" "$PALETTE" >/dev/null 2>&1
ffmpeg -y "${TRIM[@]}" -i "$IN" -i "$PALETTE" \
  -lavfi "${FILTERS}[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
  -loop 0 "$OUT" >/dev/null 2>&1

echo "wrote $OUT ($(du -h "$OUT" | cut -f1), $(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$OUT"), $(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$OUT")s)"
