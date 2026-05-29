# Contributing

Thanks for your interest in Cliplet!

## Development

- Requires macOS 14+ and a Swift 6 toolchain (Xcode 16+).
- `swift build` / `swift run Cliplet` / `swift test`.
- Core logic (history, classification, storage, layout) lives in `ClipletCore` and is unit
  tested. UI lives in `ClipletApp`.

## Pull requests

- Branch off `main`, keep changes focused, and make sure `swift test` passes.
- Match the existing code style (logic in `ClipletCore`, thin AppKit/SwiftUI in `ClipletApp`).

## Releasing (maintainers)

1. Bump `VERSION` in `Scripts/build-app.sh`/`release.sh` and the cask.
2. `Scripts/release.sh` → notarized, stapled DMG + its sha256.
3. `git tag vX.Y.Z && git push --tags`; `gh release create vX.Y.Z dist/Cliplet-X.Y.Z.dmg`.
4. Update `Casks/cliplet.rb` (`version`, `sha256`) in `eplugge/homebrew-tap`.
