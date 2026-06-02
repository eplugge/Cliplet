#!/usr/bin/env bash
set -euo pipefail
VERSION="${VERSION:-0.2.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Cliplet.app"

# Universal binary so the app runs on both Apple Silicon and Intel Macs.
swift build -c release --arch arm64 --arch x86_64 --package-path "$ROOT"
BIN="$ROOT/.build/apple/Products/Release/Cliplet"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Cliplet"
cp "$ROOT/Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>Cliplet</string>
  <key>CFBundleIdentifier</key><string>nu.plugge.macOS.cliplet</string>
  <key>CFBundleName</key><string>Cliplet</string>
  <key>CFBundleDisplayName</key><string>Cliplet</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleVersion</key><string>${BUILD_NUMBER}</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHumanReadableCopyright</key><string>© 2026 Eelco Plugge — GPL-3.0</string>
</dict>
</plist>
PLIST

echo "Built $APP (version $VERSION)"
