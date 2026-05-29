import AppKit
import ClipletCore
import Combine
import Foundation
import ServiceManagement
import SwiftUI

@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()

    @Published var history: HistoryModel
    @Published var settings: ClipSettings {
        didSet {
            history.settings = settings
            saveSettings()
            monitor?.settings = settings
        }
    }
    @Published var exclusions: ExcludedApps {
        didSet {
            saveExclusions()
            monitor?.excludedApps = exclusions
        }
    }
    @Published var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: Self.launchAtLoginKey)
            setLaunchAtLogin(launchAtLogin)
        }
    }

    /// Set by MenuBarController: dismiss the popover and re-activate whichever app was
    /// frontmost before it opened. Called whenever a clip is restored, so the menu closes
    /// on selection and any auto-paste lands in the right app (not Cliplet's search field).
    var dismissAndReturnFocus: (() -> Void)?

    /// Set by MenuBarController: keep the popover open (non-dismissing) while the Quick Look
    /// preview is up, and restore normal transient dismissal when it closes.
    var setPopoverPersistent: ((Bool) -> Void)?

    /// Set to a clip id when keyboard navigation should scroll that row into view. Hover
    /// selection deliberately leaves this untouched, so the mouse never triggers a scroll.
    @Published var scrollTargetID: UUID?

    let store: ClipStore

    private let storeRootDirectory: URL
    private let previewController: PreviewController
    private var monitor: ClipboardMonitor?
    private var pollTimer: Timer?
    private var settingsWindowController: NSWindowController?
    private var pendingPayloadData: [String: Data] = [:]
    // Pointer location captured at the last keyboard navigation; used to distinguish a
    // real mouse move from a hover event fired by the list scrolling under the pointer.
    private var keyNavMouseAnchor: NSPoint?

    private static let settingsKey = "Cliplet.settings"
    private static let exclusionsKey = "Cliplet.exclusions"
    private static let launchAtLoginKey = "Cliplet.launchAtLogin"

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cliplet", isDirectory: true)

        self.storeRootDirectory = supportDirectory
        let storedSettings = Self.loadSettings() ?? .defaults
        let storedExclusions = Self.loadExclusions()

        self.store = ClipStore(rootDirectory: supportDirectory)
        self.settings = storedSettings
        self.exclusions = storedExclusions
        self.launchAtLogin = UserDefaults.standard.bool(forKey: Self.launchAtLoginKey)
        self.previewController = PreviewController()

        let loadedClips = (try? store.load()) ?? []
        self.history = HistoryModel(settings: storedSettings, clips: loadedClips)

        previewController.onVisibilityChanged = { [weak self] visible in
            self?.setPopoverPersistent?(visible)
        }

        configureMonitor()
        startPolling()
    }

    func capture(_ clip: Clip) {
        guard !clip.preview.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        if case .storedPayload(let filename) = clip.payload,
           let data = pendingPayloadData.removeValue(forKey: filename) {
            try? store.writePayload(data, filename: filename)
        }

        history.addOrUpdate(clip)
        persistQuietly()
    }

    func restore(_ clip: Clip) {
        let pasteboard = NSPasteboard.general

        let write: () -> Bool

        switch PasteboardWriting.writeRequest(for: clip) {
        case .text(let text):
            write = {
                pasteboard.setString(text, forType: .string)
            }

        case .file(let url):
            write = {
                pasteboard.writeObjects([url as NSURL])
            }

        case .storedPayload(let filename, let contentType):
            guard let contentType,
                  let data = try? store.readPayload(filename: filename) else {
                return
            }

            write = {
                pasteboard.setData(data, forType: NSPasteboard.PasteboardType(contentType))
            }

        case .unavailable:
            return
        }

        let previousItems = pasteboard.pasteboardItems ?? []
        pasteboard.clearContents()
        guard write() else {
            if !previousItems.isEmpty {
                pasteboard.writeObjects(previousItems)
            }
            return
        }

        monitor?.suppressNextChangeCount(pasteboard.changeCount)
        history.markUsed(clip.id, at: Date())
        persistQuietly()
        // Close the popover (and hand focus back) on every selection, then paste if enabled.
        dismissAndReturnFocus?()
        pasteIfEnabled()
    }

    func preview(_ clip: Clip) {
        previewController.show(clip: clip, storeRootDirectory: storeRootDirectory)
    }

    func togglePinned(_ clip: Clip) {
        history.setPinned(clip.id, isPinned: !clip.isPinned)
        persistQuietly()
    }

    func delete(_ clip: Clip) {
        history.removeClip(clip.id)
        persistQuietly()
    }

    func clearHistory() {
        history.removeAllClips()
        persistQuietly()
    }

    func showSettings() {
        NSApp.activate(ignoringOtherApps: true)

        if let settingsWindowController {
            settingsWindowController.showWindow(nil)
            settingsWindowController.window?.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingView(
            rootView: SettingsView()
                .environmentObject(self)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cliplet Preferences"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("ClipletPreferences")

        let controller = NSWindowController(window: window)
        settingsWindowController = controller
        controller.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    func quit() {
        NSApp.terminate(nil)
    }

    /// Hovering a row makes it the selection (so the mouse and keyboard share one
    /// highlight and arrows continue from the hovered row). Does NOT scroll — only
    /// keyboard navigation scrolls — so hovering never yanks the list around.
    ///
    /// Ignored when it fires without the mouse having actually moved: keyboard
    /// navigation scrolls the list under a stationary pointer, which makes a different
    /// row pass beneath it and fires onHover — accepting that would hijack the keyboard
    /// selection back to the mouse position.
    func hoverSelect(_ id: UUID) {
        let location = NSEvent.mouseLocation
        if let anchor = keyNavMouseAnchor,
           hypot(location.x - anchor.x, location.y - anchor.y) < 1 {
            return
        }
        keyNavMouseAnchor = nil
        history.selectClip(id)
    }

    private func requestScrollToSelection() {
        scrollTargetID = history.selectedClipID
        // Remember where the pointer was so hover events caused purely by the resulting
        // scroll (not by the user moving the mouse) are ignored until a real move.
        keyNavMouseAnchor = NSEvent.mouseLocation
    }

    func persistQuietly() {
        try? store.save(history.clips)

        let referencedPayloads = Set(history.clips.compactMap { clip -> String? in
            guard case .storedPayload(let filename) = clip.payload else {
                return nil
            }

            return filename
        })

        try? store.prunePayloads(referencedFilenames: referencedPayloads)
    }

    func handle(_ command: ClipletKeyCommand) {
        switch command {
        case .moveUp:
            history.moveSelection(offset: -1)
            requestScrollToSelection()
        case .moveDown:
            history.moveSelection(offset: 1)
            requestScrollToSelection()
        case .pageUp:
            history.moveSelection(offset: -settings.visibleRowLimit)
            requestScrollToSelection()
        case .pageDown:
            history.moveSelection(offset: settings.visibleRowLimit)
            requestScrollToSelection()
        case .home:
            history.moveSelectionToStart()
            requestScrollToSelection()
        case .end:
            history.moveSelectionToEnd()
            requestScrollToSelection()
        case .enter:
            restoreSelectedClip()
        case .preview:
            previewSelectedClip()
        case .close:
            NSApp.keyWindow?.close()
        case .delete:
            deleteSelectedClip()
        case .numbered(let number):
            restoreNumberedClip(number)
        }
    }

    func addExcludedApp(bundleID: String) {
        var updated = exclusions
        updated.add(bundleID: bundleID)
        exclusions = updated
    }

    func addExcludedApp(at url: URL) {
        guard let bundleID = AppBundle.bundleID(forApplicationAt: url) else { return }
        addExcludedApp(bundleID: bundleID)
    }

    func removeExcludedApp(bundleID: String) {
        var updated = exclusions
        updated.remove(bundleID: bundleID)
        exclusions = updated
    }

    private func configureMonitor() {
        monitor = ClipboardMonitor(
            settings: settings,
            excludedApps: exclusions,
            sourceAppProvider: { [weak self] in
                self?.frontmostSourceApp()
            },
            readItem: { [weak self] in
                self?.readGeneralPasteboardItem()
            },
            onCapture: { [weak self] clip in
                Task { @MainActor in
                    self?.capture(clip)
                }
            }
        )
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollClipboard()
            }
        }
    }

    private func pollClipboard() {
        monitor?.poll(changeCount: NSPasteboard.general.changeCount, now: Date())
    }

    private func frontmostSourceApp() -> ClipboardMonitor.SourceApp? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        return ClipboardMonitor.SourceApp(bundleID: app.bundleIdentifier, name: app.localizedName)
    }

    private func readGeneralPasteboardItem() -> ClipClassifier.RawItem? {
        let pasteboard = NSPasteboard.general
        let items = pasteboard.pasteboardItems ?? []
        guard let item = items.first else { return nil }

        var representations: [ClipClassifier.RawRepresentation] = []
        for type in item.types {
            guard let data = item.data(forType: type) else { continue }
            let typeIdentifier = type.rawValue
            let filename = filename(for: item, type: type, data: data)
            let storedPayloadFilename = data.count <= settings.maximumPersistedClipBytes && settings.persistBinaryClips
                ? storedPayloadFilename(for: typeIdentifier, filename: filename)
                : nil
            if let storedPayloadFilename {
                pendingPayloadData[storedPayloadFilename] = data
            }
            representations.append(
                ClipClassifier.RawRepresentation(
                    typeIdentifier: typeIdentifier,
                    data: data,
                    filename: filename,
                    storedPayloadFilename: storedPayloadFilename
                )
            )
        }

        guard !representations.isEmpty else { return nil }
        let source = frontmostSourceApp()
        return ClipClassifier.RawItem(
            representations: representations,
            sourceAppBundleID: source?.bundleID,
            sourceAppName: source?.name,
            now: Date()
        )
    }

    private func filename(for item: NSPasteboardItem, type: NSPasteboard.PasteboardType, data: Data) -> String? {
        if type == .fileURL,
           let string = String(data: data, encoding: .utf8),
           let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return url.lastPathComponent
        }

        return item.string(forType: NSPasteboard.PasteboardType("public.url-name"))
    }

    private func storedPayloadFilename(for typeIdentifier: String, filename: String?) -> String? {
        let lowered = typeIdentifier.lowercased()
        guard lowered == "public.png" ||
            lowered == "public.jpeg" ||
            lowered == "public.jpg" ||
            lowered == "public.tiff" ||
            lowered.contains("image") else {
            return nil
        }

        let extensionLabel = URL(fileURLWithPath: filename ?? "").pathExtension
        let fallbackExtension: String
        if lowered.contains("png") {
            fallbackExtension = "png"
        } else if lowered.contains("jpeg") || lowered.contains("jpg") {
            fallbackExtension = "jpeg"
        } else if lowered.contains("tiff") {
            fallbackExtension = "tiff"
        } else {
            fallbackExtension = "data"
        }

        let payloadExtension = extensionLabel.isEmpty ? fallbackExtension : extensionLabel
        return "\(UUID().uuidString).\(payloadExtension)"
    }

    private func restoreSelectedClip() {
        guard let clip = selectedClip else { return }
        restore(clip)
    }

    private func previewSelectedClip() {
        if previewController.isVisible {
            previewController.hide()
        } else if let clip = selectedClip {
            previewController.show(clip: clip, storeRootDirectory: storeRootDirectory)
        }
    }

    private func deleteSelectedClip() {
        guard let id = history.selectedClipID else { return }
        if history.requestDelete(id, now: Date()) {
            persistQuietly()
        }
    }

    private func restoreNumberedClip(_ number: Int) {
        let clips = history.filteredClips
        let index = number - 1
        guard index >= 0, index < min(clips.count, 9) else { return }
        restore(clips[index])
    }

    private func pasteIfEnabled() {
        guard settings.autoPasteAfterSelection,
              AXIsProcessTrusted() else {
            return
        }

        // restore() has already dismissed the popover and re-activated the previous app;
        // give that focus change a moment to settle before posting the keystroke.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            Self.postCommandV()
        }
    }

    private static func postCommandV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            UserDefaults.standard.set(false, forKey: Self.launchAtLoginKey)
        }
    }

    private var selectedClip: Clip? {
        guard let id = history.selectedClipID else { return nil }
        return history.filteredClips.first { $0.id == id }
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }

    private static func loadSettings() -> ClipSettings? {
        guard let data = UserDefaults.standard.data(forKey: settingsKey) else { return nil }
        return try? JSONDecoder().decode(ClipSettings.self, from: data)
    }

    private func saveExclusions() {
        guard let data = try? JSONEncoder().encode(exclusions) else { return }
        UserDefaults.standard.set(data, forKey: Self.exclusionsKey)
    }

    private static func loadExclusions() -> ExcludedApps {
        guard let data = UserDefaults.standard.data(forKey: exclusionsKey),
              let exclusions = try? JSONDecoder().decode(ExcludedApps.self, from: data) else {
            return ExcludedApps()
        }
        return exclusions
    }

}
