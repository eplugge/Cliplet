import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            StorageSettingsView()
                .tabItem {
                    Label("Clips", systemImage: "list.bullet.clipboard")
                }

            PrivacySettingsView()
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 480)
    }
}

extension View {
    /// Shared styling for each settings tab: a grouped form with a small bottom inset so the
    /// last row never sits flush against the window edge — a subtle hint that taller tabs scroll.
    func clipletSettingsTab() -> some View {
        formStyle(.grouped)
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 12) }
    }
}
