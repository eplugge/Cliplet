import AppKit
import ClipletCore
import SwiftUI

struct AboutSettingsView: View {
    private var versionText: String {
        AppVersion.displayString(
            shortVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            build: Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 8)

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            Text("Cliplet")
                .font(.title2)
                .bold()

            Text("Version \(versionText)")
                .foregroundStyle(.secondary)

            Text("© 2026 Eelco Plugge")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                Button("★ Rate on the App Store") {
                    open("https://apps.apple.com/app/id6774704932?action=write-review")
                }
                Button("GitHub") {
                    open("https://github.com/eplugge/Cliplet")
                }
                Button("Report an Issue") {
                    open("https://github.com/eplugge/Cliplet/issues")
                }
            }
            .padding(.bottom, 16)
        }
        .frame(width: 480)
        .frame(maxWidth: .infinity)
    }

    private func open(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
