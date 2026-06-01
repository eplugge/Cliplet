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
        services.onPausedChanged = { [weak self] _ in self?.refreshStatusIcon() }
        services.onTemporarySessionChanged = { [weak self] _ in self?.refreshStatusIcon() }
    }

    private func configureStatusItem() {
        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover)
        button.target = self
        // Receive right-clicks too, so we can show a command menu instead of the popover.
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        refreshStatusIcon()
    }

    /// Resolves the menu-bar icon by state precedence: temporary session > paused > normal.
    private func refreshStatusIcon() {
        let state: ClipletIcon.State = services.temporarySessionActive ? .session
            : (services.isPaused ? .paused : .normal)
        statusItem.button?.image = ClipletIcon.menuBarImage(state: state)
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

        // Right-click (or Control-click) shows a quick command menu instead of the clippings.
        if let event = NSApp.currentEvent,
           event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showCommandMenu(from: button)
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            // Remember who had focus so auto-paste can return there afterwards.
            previousApp = NSWorkspace.shared.frontmostApplication
            // Each fresh open re-masks blurred clips; holding ⌥ reveals them all for this viewing.
            services.resetReveal()
            if NSApp.currentEvent?.modifierFlags.contains(.option) == true {
                services.revealAllForViewing()
            }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            // Exclude the popover from screen capture/sharing so clipboard history isn't
            // exposed while presenting (unless the user disabled it). Recreated each show.
            popover.contentViewController?.view.window?.sharingType = services.windowSharingType()
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showCommandMenu(from button: NSStatusBarButton) {
        if popover.isShown { popover.performClose(nil) }
        let menu = NSMenu()
        func add(_ title: String, _ selector: Selector, _ key: String = "") {
            let item = NSMenuItem(title: title, action: selector, keyEquivalent: key)
            item.target = self
            menu.addItem(item)
        }
        add(services.isPaused ? "Resume Cliplet" : "Pause Cliplet", #selector(menuTogglePaused))
        add(services.temporarySessionActive ? "End Temporary Session" : "Start Temporary Session", #selector(menuToggleTemporarySession))
        menu.addItem(.separator())
        add("Clear History", #selector(menuClear))
        add("Preferences…", #selector(menuPreferences), ",")
        menu.addItem(.separator())
        add("Quit Cliplet", #selector(menuQuit), "q")
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY + 4), in: button)
    }

    @objc private func menuTogglePaused() { services.togglePaused() }
    @objc private func menuToggleTemporarySession() { services.toggleTemporarySession() }
    @objc private func menuClear() { services.clearHistory() }
    @objc private func menuPreferences() { services.showSettings() }
    @objc private func menuQuit() { services.quit() }

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
