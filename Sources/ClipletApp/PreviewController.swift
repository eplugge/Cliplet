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

        panel.dataSource = self
        panel.reloadData()
        panel.level = .floating
        panel.setFrame(NSRect(x: 0, y: 0, width: 720, height: 520), display: false)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
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
