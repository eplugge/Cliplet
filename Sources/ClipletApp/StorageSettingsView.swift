import ClipletCore
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
        // A List (not a Form) so the pinned section supports inline drag-to-reorder (.onMove),
        // which grouped Form does not. Styled to match the other grouped settings tabs.
        List {
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

            Section {
                Toggle("Add new clips to the bottom", isOn: $services.settings.appendNewClipsToBottom)
            } footer: {
                Text("New clips appear at the end of the list instead of the top.")
            }

            if !services.history.pinnedClips.isEmpty {
                Section {
                    ForEach(services.history.pinnedClips) { clip in
                        Label(pinnedLabel(clip), systemImage: "pin.fill")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    .onMove { from, to in
                        services.movePinned(fromOffsets: from, toOffset: to)
                    }
                } header: {
                    Text("Pinned clips")
                } footer: {
                    Text("Drag to reorder. This is the order pinned clips appear in the menu.")
                }
            }
        }
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 12) }
    }

    /// A readable, privacy-respecting label for a pinned clip in the reorder list:
    /// the alias when set, otherwise the value (or a placeholder for hidden clips).
    private func pinnedLabel(_ clip: Clip) -> String {
        if let alias = clip.alias?.trimmingCharacters(in: .whitespacesAndNewlines), !alias.isEmpty {
            return alias
        }
        return clip.maskMode == .hidden ? ClipDisplay.hiddenPlaceholder : clip.preview
    }
}
