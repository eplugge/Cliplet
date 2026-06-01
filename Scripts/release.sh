#!/usr/bin/env bash
set -euo pipefail
VERSION="${VERSION:-0.2.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/Cliplet.app"
DMG="$ROOT/dist/Cliplet-${VERSION}.dmg"
IDENTITY="Developer ID Application: Eelco Plugge (75J677Q8TZ)"
PROFILE="cliplet-notary"

# 1. Build the bundle.
VERSION="$VERSION" "$ROOT/Scripts/build-app.sh"

# 2. Sign with Hardened Runtime (required for notarization).
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

# 3. Build a drag-to-Applications DMG.
rm -rf "$ROOT/dist"; mkdir -p "$ROOT/dist"
STAGE="$(mktemp -d)"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "Cliplet" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

# 4. Sign, notarize, staple.
codesign --force --sign "$IDENTITY" "$DMG"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

echo "==> DMG: $DMG"
shasum -a 256 "$DMG"
