# Cliplet

**Paste from the past.** — a fast, native macOS menu-bar clipboard history.

Cliplet quietly remembers what you copy — text, links, images, files — and lets you
search and re-paste any of it from a keyboard-driven menu-bar popover.

> Screenshots: add `docs/images/popover.png` and `docs/images/preferences.png`.

## Features

- Lightweight menu-bar app (no Dock icon), native SwiftUI/AppKit.
- Searchable history; type to filter, click (or Enter) to copy a clip back.
- Space previews any clip via Quick Look (text included).
- Pin clips, move-used-to-top, ⌘1–9 quick paste.
- Optional auto-paste into the previous app (needs Accessibility permission).
- Per-app exclusions so secrets from chosen apps are never captured.
- Configurable history size, visible rows, and max clip size.

## Install

**Homebrew (recommended):**

```sh
brew install --cask eplugge/tap/cliplet
```

**Direct download:** grab `Cliplet-x.y.z.dmg` from the
[latest release](https://github.com/eplugge/Cliplet/releases/latest), open it, and drag
Cliplet to Applications.

## Permissions

Auto-paste synthesizes ⌘V into the previous app, which needs **Accessibility** access:
System Settings → Privacy & Security → Accessibility → enable **Cliplet**. Everything
else (history, search, manual copy) works without it.

## Keyboard shortcuts (popover)

| Key | Action |
| --- | --- |
| ↑ / ↓ | Move selection |
| Page Up / Page Down | Jump a page |
| Home / End | First / last clip |
| Return | Copy selected clip |
| Space | Quick Look preview (toggle) |
| ⌘1 – ⌘9 | Copy clip 1–9 |
| Delete (forward delete) | Delete selected clip (press twice to confirm) |
| Esc | Close |

## Build from source

```sh
swift build        # debug build
swift run Cliplet   # run from source
swift test         # run the test suite
```

To produce a distributable app: `Scripts/build-app.sh` (unsigned) or `Scripts/release.sh`
(signed + notarized DMG; requires a Developer ID cert and a `cliplet-notary` notarytool
profile).

## License

[GPL-3.0](LICENSE). Free to use, modify, and share; derivatives must remain open under GPL.
