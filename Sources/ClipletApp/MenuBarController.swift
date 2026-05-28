import AppKit
import ClipletCore
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private var history: HistoryModel

    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.history = HistoryModel(settings: .defaults, clips: MenuBarController.sampleClips())
        super.init()

        configureStatusItem()
        configurePopover()
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.image = ClipletIcon.menuBarImage()
        button.action = #selector(togglePopover)
        button.target = self
    }

    private func configurePopover() {
        popover.behavior = .transient
        popover.animates = false
        popover.delegate = self
        popover.contentSize = NSSize(width: 404, height: 430)
        popover.contentViewController = NSHostingController(
            rootView: ClipletPopoverView(history: history)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private static func sampleClips() -> [Clip] {
        let now = Date()
        return [
            Clip(
                kind: .text,
                preview: "going to create a clipboard app for macOS...",
                contentType: "public.utf8-plain-text",
                filename: nil,
                dimensions: nil,
                byteSize: 44,
                sourceAppBundleID: nil,
                sourceAppName: "Notes",
                createdAt: now,
                lastUsedAt: now,
                isPinned: true,
                payload: .inlineText("going to create a clipboard app for macOS...")
            ),
            Clip(
                kind: .url,
                preview: "https://developer.apple.com/documentation/appkit/nsstatusitem",
                contentType: "public.url",
                filename: nil,
                dimensions: nil,
                byteSize: 63,
                sourceAppBundleID: nil,
                sourceAppName: "Safari",
                createdAt: now.addingTimeInterval(-60),
                lastUsedAt: now.addingTimeInterval(-60),
                isPinned: false,
                payload: .inlineText("https://developer.apple.com/documentation/appkit/nsstatusitem")
            ),
            Clip(
                kind: .image,
                preview: "Image: Photo123.png · PNG · 2.3 MB",
                contentType: "public.png",
                filename: "Photo123.png",
                dimensions: ClipDimensions(width: 1024, height: 768),
                byteSize: 2_400_000,
                sourceAppBundleID: nil,
                sourceAppName: "Preview",
                createdAt: now.addingTimeInterval(-120),
                lastUsedAt: now.addingTimeInterval(-120),
                isPinned: false,
                payload: .metadataOnly
            ),
            Clip(
                kind: .file,
                preview: "File: budget.xlsx · XLSX",
                contentType: "public.file-url",
                filename: "budget.xlsx",
                dimensions: nil,
                byteSize: nil,
                sourceAppBundleID: nil,
                sourceAppName: "Finder",
                createdAt: now.addingTimeInterval(-180),
                lastUsedAt: now.addingTimeInterval(-180),
                isPinned: false,
                payload: .fileReference(URL(fileURLWithPath: "/tmp/budget.xlsx"))
            )
        ]
    }
}
