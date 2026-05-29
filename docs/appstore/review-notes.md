# App Review notes for Cliplet (paste into App Store Connect → App Review Information → Notes)

**IMPORTANT — how to open the app:** Cliplet is a **menu-bar utility** (a macOS agent app,
`LSUIElement`). It has **no Dock icon and no main window** by design. After launching, click
the **paperclip icon on the right side of the macOS menu bar** to open Cliplet's popover. If
the app appears to "do nothing" at launch, that is expected — its entire UI is the menu-bar
popover.

**3. Purpose & target audience.** Cliplet is a clipboard-history utility for macOS. macOS only
keeps the single most-recent item you copy; Cliplet keeps a searchable history of everything you
copy — text, links, images, and files — so you can find and reuse earlier clips. Target audience:
developers, writers, and Mac power users who copy and paste frequently. Value: never lose a copied
item, and quickly search and re-paste past clips from the keyboard.

**4. Setup & accessing the main features** (no account, credentials, or sample files required):
1. Launch Cliplet. It runs in the menu bar (no Dock icon). Click the paperclip icon in the menu bar.
2. Copy anything in any app (⌘C) — some text, a link, or an image. It appears at the top of the list.
3. In the popover: type to filter the list; click a row (or press Return) to copy that item back to
   the clipboard; press Space to Quick Look a clip; ⌘1–9 copy the corresponding clip.
4. Preferences (popover footer → "Preferences…"): history size, visible rows, max clip size, and
   per-app exclusions.
No login or sample files are needed — copying any text or image demonstrates the full feature set.

**5. External services / tools / platforms.** None. Cliplet runs entirely on-device. It makes **no
network connections**, has **no backend or servers, no accounts/authentication, no analytics or
tracking**, and uses **no third-party data, AI, or payment services**. All clipboard history is
stored locally in the app's sandbox container.

**6. Regional differences.** None. The app functions identically in all regions; there is no
region-specific feature or content.

**7. Regulated industry / protected third-party material.** None. Cliplet does not operate in a
regulated industry and contains no protected third-party material.

**2. Tested on.** <FILL IN your Mac model + OS, e.g. "MacBook Pro (Apple Silicon, M3), macOS 26.x">.

**1. Screen recording.** See the capture script below; attach the recording (or note it's attached).

**Note on permissions:** The App Store build is sandboxed and requests **no** sensitive-data or
device-capability permissions (no Accessibility, no location/contacts/camera, no tracking). It only
reads/writes the standard pasteboard, which requires no permission prompt.

---

## Screen-recording script (record on your Mac with ⇧⌘5 → "Record Entire Screen", ~30–60s)

1. Launch Cliplet — point the cursor at the **paperclip icon appearing in the menu bar** (note: no
   Dock icon, no window — this is the whole point to show the reviewer).
2. In another app, copy a few different things: a line of text, a URL, and an image.
3. Click the menu-bar paperclip → the popover opens showing the captured history.
4. Type a few letters → the list filters.
5. Press **Space** on an image clip → Quick Look preview opens; press Space again → it closes.
6. Click a clip (or press Return) → it's copied back; paste it into a text field to prove it worked.
7. Briefly open **Preferences** from the footer, then close.

There are **no** login, purchase/subscription, user-generated-content, or sensitive-permission
flows in the app, so none need to be shown.
