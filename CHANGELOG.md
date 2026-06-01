# Changelog

All notable changes to Cliplet are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — unreleased

### Added

- **Temporary session** — an ephemeral capture mode. Clips taken during a session are marked with an hourglass and kept only for that session; ending it discards them (with a confirm dialog that offers *Keep All*, plus a "don't ask again" option). Any leftovers are purged on the next launch, and individual clips can be promoted to the permanent history. ([#30])
- **Blur / mask clips** — hide a clip's contents behind a blur or a placeholder, reveal on demand, and configure how many leading and trailing characters stay visible. ([#4])
- **Clip aliases + Edit modal** — give any clip a label and set its display mode (Show / Blur / Hide), independent of pinning. ([#5])
- **Search matches aliases** — filtering now searches a clip's alias as well as its contents. ([#23])
- **Pause capture** — temporarily stop recording the clipboard from the popover footer or the menu-bar command menu. ([#7])
- **Hide during screen sharing** — exclude Cliplet's popover and Preferences from screen recordings and shared screens (toggle in the Privacy tab). ([#6])
- **Right-click command menu** — right-click the menu-bar icon for Pause, Temporary Session, Clear, Preferences, and Quit. ([#26])
- **Reorder pinned clips** — drag pinned clips into a manual order; newly pinned clips append to the bottom. ([#8])
- **Append-to-bottom option** — add new clips to the bottom of the list instead of the top. ([#3])
- **About tab** in Preferences. ([#1])

### Changed

- Renamed the **Storage** settings tab to **Clips**. ([#2])
- Pinned clips now use a subtle pushpin icon instead of a bullet. ([#19])
- Popover footer actions are grouped with separators and highlight on hover, mirroring the right-click command menu. ([#32])
- Settings UI polish: scroll affordance and General-tab spacing. ([#14])

### Fixed

- "Move used clip to top" no longer conflicts with the append-to-bottom ordering. ([#17])
- Preferences tab icons now render deterministically via a custom tab header. ([#28])

## [0.1.0] — 2026-05-29

Initial release.

- Menu-bar clipboard history for text, links, images, and files.
- Type-to-filter search, click or `Return` to copy a clip back.
- Quick Look previews, pin & promote, and `⌘1`–`9` quick copy.
- Per-app exclusions and configurable history size, visible rows, and max clip size.
- Optional auto-paste into the previous app (Homebrew / direct-download build).
- Distributed via the Mac App Store, Homebrew, and a notarized DMG.

[0.2.0]: https://github.com/eplugge/Cliplet/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/eplugge/Cliplet/releases/tag/v0.1.0

[#1]: https://github.com/eplugge/Cliplet/issues/1
[#2]: https://github.com/eplugge/Cliplet/issues/2
[#3]: https://github.com/eplugge/Cliplet/issues/3
[#4]: https://github.com/eplugge/Cliplet/issues/4
[#5]: https://github.com/eplugge/Cliplet/issues/5
[#6]: https://github.com/eplugge/Cliplet/issues/6
[#7]: https://github.com/eplugge/Cliplet/issues/7
[#8]: https://github.com/eplugge/Cliplet/issues/8
[#14]: https://github.com/eplugge/Cliplet/issues/14
[#17]: https://github.com/eplugge/Cliplet/issues/17
[#19]: https://github.com/eplugge/Cliplet/issues/19
[#23]: https://github.com/eplugge/Cliplet/issues/23
[#26]: https://github.com/eplugge/Cliplet/issues/26
[#28]: https://github.com/eplugge/Cliplet/issues/28
[#30]: https://github.com/eplugge/Cliplet/issues/30
[#32]: https://github.com/eplugge/Cliplet/issues/32
