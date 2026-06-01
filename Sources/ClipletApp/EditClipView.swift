import ClipletCore
import SwiftUI

struct EditClipView: View {
    @EnvironmentObject private var services: AppServices

    let clipID: UUID
    let preview: String
    @State private var alias: String
    @State private var maskMode: ClipMaskMode

    init(clipID: UUID, preview: String, initialAlias: String, initialMaskMode: ClipMaskMode) {
        self.clipID = clipID
        self.preview = preview
        _alias = State(initialValue: initialAlias)
        _maskMode = State(initialValue: initialMaskMode)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(preview)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Form {
                TextField("Alias (optional)", text: $alias)

                Picker("Display", selection: $maskMode) {
                    Text("Show").tag(ClipMaskMode.none)
                    Text("Blur").tag(ClipMaskMode.blurred)
                    Text("Hide").tag(ClipMaskMode.hidden)
                }
                .pickerStyle(.segmented)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { services.closeEditWindow() }
                    .keyboardShortcut(.cancelAction)
                Button("Save") {
                    services.updateClip(id: clipID, alias: alias, maskMode: maskMode)
                    services.closeEditWindow()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
}
