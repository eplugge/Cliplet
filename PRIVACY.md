# Privacy Policy

_Last updated: 2026-05-29_

**Cliplet does not collect, transmit, or share any of your data.**

Cliplet is a clipboard-history utility that runs entirely on your Mac.

## What Cliplet stores

- Cliplet keeps a history of items you copy (text, links, images, and files) so you can
  re-use them. This history is stored **only on your device** — in the app's local
  Application Support folder (or its sandbox container on the App Store build).
- Nothing you copy ever leaves your Mac.

## What Cliplet does NOT do

- It has **no network access** — it does not connect to any server, and there is no backend.
- It has **no accounts, no sign-in, and no analytics or tracking**.
- The developer **receives no data** of any kind from the app.

## Your control

- Clear individual clips or your entire history at any time from within the app.
- Use **per-app exclusions** to stop Cliplet from capturing anything copied in apps you choose.
- Uninstalling the app, or using its "Clear" action, removes the stored history. (Homebrew
  users can also run `brew uninstall --zap --cask cliplet` to remove all local data.)

## Permissions

- The non–App Store (Homebrew/DMG) build optionally uses macOS **Accessibility** permission
  to auto-paste into the previous app. This permission is used solely to send a paste
  keystroke locally; it is never used to read other apps' contents, and no data is collected.
  The App Store build does not include this feature.

## Contact

Questions? Open an issue at <https://github.com/eplugge/Cliplet/issues>.
