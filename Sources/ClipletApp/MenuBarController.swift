import AppKit
import SwiftUI

@MainActor
final class MenuBarController: NSObject, NSPopoverDelegate {
    private let statusItem: NSStatusItem
    private let popover: NSPopover
    private let services: AppServices
    private var keyMonitor: Any?
    private var previousApp: NSRunningApplication?

    override init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.popover = NSPopover()
        self.services = .shared
        super.init()

        configureStatusItem()
        configurePopover()
        configureKeyMonitor()

        services.dismissAndReturnFocus = { [weak self] in
            self?.dismissAndReturnFocus()
        }
        services.setPopoverPersistent = { [weak self] persistent in
            self?.setPopoverPersistent(persistent)
        }
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
        popover.contentSize = NSSize(width: 440, height: 430)
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
            // Remember who had focus so auto-paste can return there afterwards.
            previousApp = NSWorkspace.shared.frontmostApplication
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func dismissAndReturnFocus() {
        popover.performClose(nil)
        previousApp?.activate()
    }

    private func setPopoverPersistent(_ persistent: Bool) {
        if persistent {
            // While Quick Look is up, stop the popover dismissing itself when QL takes key.
            popover.behavior = .applicationDefined
        } else {
            // QL closed: take key focus back BEFORE restoring transient dismissal, so the
            // popover stays open (a transient popover dismisses itself if it isn't key when
            // the behavior is applied).
            NSApp.activate(ignoringOtherApps: true)
            popover.contentViewController?.view.window?.makeKey()
            popover.behavior = .transient
        }
    }

    private func configureKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  self.popover.isShown,
                  let command = ClipletKeyCommand.parse(event) else {
                return event
            }

            self.services.handle(command)
            return nil
        }
    }
}
