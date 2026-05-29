#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SET="$ROOT/AppStore/Assets.xcassets/AppIcon.appiconset"
TMP="$(mktemp -d)"
swift "$ROOT/Scripts/render-app-icon.swift" "$TMP/icon-1024.png"

mkdir -p "$SET"
gen() { sips -z "$1" "$1" "$TMP/icon-1024.png" --out "$SET/$2" >/dev/null; }
gen 16   icon_16.png
gen 32   icon_16@2x.png
gen 32   icon_32.png
gen 64   icon_32@2x.png
gen 128  icon_128.png
gen 256  icon_128@2x.png
gen 256  icon_256.png
gen 512  icon_256@2x.png
gen 512  icon_512.png
gen 1024 icon_512@2x.png

cat > "$SET/Contents.json" <<'JSON'
{
  "images": [
    {"idiom":"mac","scale":"1x","size":"16x16","filename":"icon_16.png"},
    {"idiom":"mac","scale":"2x","size":"16x16","filename":"icon_16@2x.png"},
    {"idiom":"mac","scale":"1x","size":"32x32","filename":"icon_32.png"},
    {"idiom":"mac","scale":"2x","size":"32x32","filename":"icon_32@2x.png"},
    {"idiom":"mac","scale":"1x","size":"128x128","filename":"icon_128.png"},
    {"idiom":"mac","scale":"2x","size":"128x128","filename":"icon_128@2x.png"},
    {"idiom":"mac","scale":"1x","size":"256x256","filename":"icon_256.png"},
    {"idiom":"mac","scale":"2x","size":"256x256","filename":"icon_256@2x.png"},
    {"idiom":"mac","scale":"1x","size":"512x512","filename":"icon_512.png"},
    {"idiom":"mac","scale":"2x","size":"512x512","filename":"icon_512@2x.png"}
  ],
  "info": {"version": 1, "author": "xcode"}
}
JSON
echo '{"info":{"version":1,"author":"xcode"}}' > "$ROOT/AppStore/Assets.xcassets/Contents.json"
rm -rf "$TMP"
echo "wrote AppStore/Assets.xcassets/AppIcon.appiconset"
