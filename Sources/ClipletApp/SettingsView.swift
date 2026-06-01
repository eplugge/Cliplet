import SwiftUI

struct SettingsView: View {
    private enum Tab: Hashable {
        case general, clips, privacy, about
    }

    @State private var selection: Tab = .general

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            content
                .frame(maxHeight: .infinity)
        }
        .frame(width: 480, height: 460)
    }

    // Custom icon+label tab header. Replaces TabView's auto-styled tab bar, which rendered
    // its icons intermittently when hosted in our hand-built NSWindow.
    private var tabBar: some View {
        HStack(spacing: 8) {
            tabButton(.general, "General", "gearshape")
            tabButton(.clips, "Clips", "list.bullet.clipboard")
            tabButton(.privacy, "Privacy", "hand.raised")
            tabButton(.about, "About", "info.circle")
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }

    private func tabButton(_ tab: Tab, _ title: String, _ symbol: String) -> some View {
        let selected = selection == tab
        return Button {
            selection = tab
        } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 11))
            }
            .frame(width: 64)
            .padding(.vertical, 5)
            .foregroundStyle(selected ? Color.accentColor : Color.primary)
            .background(
                selected ? Color.secondary.opacity(0.18) : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private var content: some View {
        switch selection {
        case .general: GeneralSettingsView()
        case .clips: StorageSettingsView()
        case .privacy: PrivacySettingsView()
        case .about: AboutSettingsView()
        }
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
