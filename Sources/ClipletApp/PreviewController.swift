import AppKit
import ClipletCore
import QuickLookUI

@MainActor
final class PreviewController: NSObject, @preconcurrency QLPreviewPanelDataSource {
    private var previewURL: URL?
    private var closeObserver: NSObjectProtocol?

    /// Called with `true` when the Quick Look panel is shown and `false` when it closes,
    /// so the popover can stay open (and not dismiss itself) for the duration.
    var onVisibilityChanged: ((Bool) -> Void)?

    var isVisible: Bool {
        QLPreviewPanel.sharedPreviewPanelExists() && QLPreviewPanel.shared().isVisible
    }

    func show(clip: Clip, storeRootDirectory: URL) {
        switch clip.payload {
        case .fileReference(let url):
            previewURL = url

        case .storedPayload(let filename):
            previewURL = storeRootDirectory
                .appendingPathComponent("Payloads", isDirectory: true)
                .appendingPathComponent(filename, isDirectory: false)

        case .inlineText(let text):
            // Quick Look needs a file URL, so spill the text to a temp .txt.
            previewURL = temporaryTextFile(contents: text, id: clip.id)

        case .metadataOnly:
            previewURL = temporaryTextFile(contents: clip.preview, id: clip.id)
        }

        guard previewURL != nil,
              let panel = QLPreviewPanel.shared() else {
            return
        }

        // Activate first so the panel can hold key focus, and tell the popover to stay
        // open BEFORE the panel takes key (otherwise a transient popover dismisses itself).
        NSApp.activate(ignoringOtherApps: true)
        onVisibilityChanged?(true)

        panel.dataSource = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
        observeClose(of: panel)
    }

    func hide() {
        guard isVisible else { return }
        QLPreviewPanel.shared().close()
    }

    private func observeClose(of panel: QLPreviewPanel) {
        if let closeObserver {
            NotificationCenter.default.removeObserver(closeObserver)
        }
        closeObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if let closeObserver = self.closeObserver {
                    NotificationCenter.default.removeObserver(closeObserver)
                    self.closeObserver = nil
                }
                self.onVisibilityChanged?(false)
            }
        }
    }

    private func temporaryTextFile(contents: String, id: UUID) -> URL? {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipletPreviews", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("\(id.uuidString).txt", isDirectory: false)
            try contents.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURL == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        previewURL as NSURL?
    }
}
