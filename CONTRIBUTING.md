# Contributing

Thanks for your interest in Cliplet!

## Development

- Requires macOS 14+ and a Swift 6 toolchain (Xcode 16+).
- `swift build` / `swift run Cliplet` / `swift test`.
- Core logic (history, classification, storage, layout) lives in `ClipletCore` and is unit
  tested. UI lives in `ClipletApp`.
- Two build paths must both compile: the default (Homebrew/direct) build and the sandboxed
  App Store build, which is gated behind the `APPSTORE` flag:

  ```sh
  swift build                       # default build
  swift build -Xswiftc -DAPPSTORE   # App Store (sandboxed) build — no auto-paste
  ```

## Pull requests

- `main` is the released branch; day-to-day work integrates into `develop` first.
- Branch off `develop` (`feat/<slug>` or `fix/<slug>`), keep changes focused, add tests for
  any `ClipletCore` logic, and make sure `swift test` and both build paths pass.
- Open the PR against `develop`. Match the existing code style (logic in `ClipletCore`, thin
  AppKit/SwiftUI in `ClipletApp`).

## Releasing (maintainers)

1. Bump the version in `project.yml` (`MARKETING_VERSION`), `Scripts/build-app.sh`,
   `Scripts/release.sh`, and the cask; add the release section to `CHANGELOG.md`.
2. Merge `develop` into `main` and tag from `main`.
3. `Scripts/release.sh` → signed, notarized, stapled DMG + its sha256.
4. `git push --tags`; `gh release create vX.Y.Z dist/Cliplet-X.Y.Z.dmg` with the CHANGELOG
   section as the release notes.
5. Update `Casks/cliplet.rb` (`version`, `sha256`) in `eplugge/homebrew-tap`.
6. Build the App Store archive from the XcodeGen project (`project.yml` → `AppStore/`) and
   upload it to App Store Connect.
