import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var services: AppServices

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
            Toggle("Auto-paste after selection", isOn: $services.settings.autoPasteAfterSelection)
        }
        .padding(20)
        .frame(width: 420)
    }
}
