import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject private var services: AppServices

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $services.launchAtLogin)
                Toggle("Move used clip to top", isOn: $services.settings.moveSelectedClipToTop)
            }

            Section {
                Toggle("Auto-paste after selection", isOn: $services.settings.autoPasteAfterSelection)
            } footer: {
                Text("Requires Accessibility permission to send the paste keystroke.")
            }

            Section {
                Stepper(
                    "Visible rows: \(services.settings.visibleRowLimit)",
                    value: $services.settings.visibleRowLimit,
                    in: 5...100
                )
            } footer: {
                Text("How many clips are shown in the popover at once.")
            }
        }
        .formStyle(.grouped)
    }
}
