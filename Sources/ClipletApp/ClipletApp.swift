import AppKit
import SwiftUI

@main
struct ClipletApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsSkeletonView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        menuBarController = MenuBarController()
    }
}

private struct SettingsSkeletonView: View {
    var body: some View {
        Text("Cliplet Settings")
            .frame(width: 360, height: 180)
    }
}
