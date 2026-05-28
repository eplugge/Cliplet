import AppKit
import ClipletCore
import Combine
import Foundation

@MainActor
final class AppServices: ObservableObject {
    static let shared = AppServices()

    @Published var history: HistoryModel
    @Published var settings: ClipSettings {
        didSet {
            history.settings = settings
        }
    }
    @Published var exclusions: ExcludedApps

    let store: ClipStore

    private let storeRootDirectory: URL
    private let previewController: PreviewController

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cliplet", isDirectory: true)

        self.storeRootDirectory = supportDirectory
        let defaultSettings = ClipSettings.defaults

        self.store = ClipStore(rootDirectory: supportDirectory)
        self.settings = defaultSettings
        self.exclusions = ExcludedApps()
        self.previewController = PreviewController()

        let loadedClips = (try? store.load()) ?? []
        self.history = HistoryModel(settings: defaultSettings, clips: loadedClips)
    }

    func capture(_ clip: Clip) {
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

        pasteboard.clearContents()
        guard write() else {
            return
        }

        history.markUsed(clip.id, at: Date())
        persistQuietly()
    }

    func preview(_ clip: Clip) {
        previewController.preview(clip: clip, storeRootDirectory: storeRootDirectory)
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
}
