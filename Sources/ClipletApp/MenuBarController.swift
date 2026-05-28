import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let services: AppServices
    private var keyMonitor: Any?

    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.services = .shared
        super.init()

        configureStatusItem()
        configurePopover()
        configureKeyMonitor()
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
            rootView: ClipletPopoverView()
                .environmentObject(services)
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

    private func configureKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  self.popover.isShown,
                  let command = ClipletKeyCommand.parse(event) else {
                return event
            }

            if command == .delete,
               self.popover.contentViewController?.view.window?.firstResponder is NSTextView {
                return event
            }

            self.services.handle(command)
            return nil
        }
    }
}
