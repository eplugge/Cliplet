import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var services: AppServices
    private var maximumPersistedClipMegabytes: Binding<Int> {
        Binding(
            get: {
                max(1, services.settings.maximumPersistedClipBytes / 1_048_576)
            },
            set: { value in
                services.settings.maximumPersistedClipBytes = value * 1_048_576
            }
        )
    }

    var body: some View {
        Form {
            Stepper(
                "Remembered clips: \(services.settings.rememberedClipLimit)",
                value: $services.settings.rememberedClipLimit,
                in: 10...5_000,
                step: 10
            )

            Stepper(
                "Visible rows: \(services.settings.visibleRowLimit)",
                value: $services.settings.visibleRowLimit,
                in: 5...100
            )

            Toggle("Move selected clip to top", isOn: $services.settings.moveSelectedClipToTop)
            Toggle("Persist binary clips", isOn: $services.settings.persistBinaryClips)
            Stepper(
                "Maximum clip size: \(maximumPersistedClipMegabytes.wrappedValue) MB",
                value: maximumPersistedClipMegabytes,
                in: 1...512
            )
            Toggle("Auto-paste after selection", isOn: $services.settings.autoPasteAfterSelection)
            Toggle("Launch at login", isOn: $services.launchAtLogin)

            Section("Excluded apps") {
                TextEditor(text: $services.excludedAppInput)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 84)

                Button("Apply Exclusions") {
                    services.addExcludedBundleIDFromInput()
                }
            }
        }
        .padding(20)
        .frame(width: 460)
    }
}
