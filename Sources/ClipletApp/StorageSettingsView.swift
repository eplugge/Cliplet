import SwiftUI

struct StorageSettingsView: View {
    @EnvironmentObject private var services: AppServices

    private var maximumPersistedClipMegabytes: Binding<Int> {
        Binding(
            get: { max(1, services.settings.maximumPersistedClipBytes / 1_048_576) },
            set: { services.settings.maximumPersistedClipBytes = $0 * 1_048_576 }
        )
    }

    var body: some View {
        Form {
            Section {
                Stepper(
                    "Remembered clips: \(services.settings.rememberedClipLimit)",
                    value: $services.settings.rememberedClipLimit,
                    in: 10...5_000,
                    step: 10
                )
            } footer: {
                Text("The maximum number of clips kept in history.")
            }

            Section {
                Toggle("Keep images & files", isOn: $services.settings.persistBinaryClips)
                Stepper(
                    "Maximum clip size: \(maximumPersistedClipMegabytes.wrappedValue) MB",
                    value: maximumPersistedClipMegabytes,
                    in: 1...512
                )
            } footer: {
                Text("Binary payloads larger than this are not stored.")
            }
        }
        .formStyle(.grouped)
    }
}
