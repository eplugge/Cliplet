import AppKit
import ClipletCore
import QuickLookUI

@MainActor
final class PreviewController: NSObject, @preconcurrency QLPreviewPanelDataSource {
    private var previewURL: URL?

    func preview(clip: Clip, storeRootDirectory: URL) {
        switch clip.payload {
        case .fileReference(let url):
            previewURL = url

        case .storedPayload(let filename):
            previewURL = storeRootDirectory
                .appendingPathComponent("Payloads", isDirectory: true)
                .appendingPathComponent(filename, isDirectory: false)

        case .inlineText, .metadataOnly:
            previewURL = nil
        }

        guard previewURL != nil,
              let panel = QLPreviewPanel.shared() else {
            return
        }

        panel.dataSource = self
        panel.reloadData()
        panel.level = .floating
        panel.setFrame(NSRect(x: 0, y: 0, width: 720, height: 520), display: false)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        previewURL == nil ? 0 : 1
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        previewURL as NSURL?
    }
}
