import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PrivacySettingsView: View {
    @EnvironmentObject private var services: AppServices
    @State private var manualBundleID: String = ""

    var body: some View {
        Form {
            Section {
                if services.exclusions.bundleIDs.isEmpty {
                    Text("No excluded apps.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(services.exclusions.bundleIDs, id: \.self) { bundleID in
                        HStack {
                            Text(bundleID)
                                .font(.system(.body, design: .monospaced))
                            Spacer()
                            Button {
                                services.removeExcludedApp(bundleID: bundleID)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.borderless)
                            .help("Remove \(bundleID)")
                        }
                    }
                }
            } header: {
                Text("Don't capture clipboard from these apps")
            }

            Section {
                Button("+ Add App…") {
                    presentAppPicker()
                }

                HStack {
                    TextField("com.example.app", text: $manualBundleID)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit(addManualBundleID)
                    Button("Add", action: addManualBundleID)
                        .disabled(manualBundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } footer: {
                Text("Pick an app, or type a bundle identifier directly.")
            }

            Section {
                revealCountRow("No. of leading characters to reveal", $services.settings.blurLeadingReveal)
                revealCountRow("No. of trailing characters to reveal", $services.settings.blurTrailingReveal)
            } header: {
                Text("Blurred clips")
            } footer: {
                Text("How many characters stay sharp at the start and end of a blurred clip. The rest is blurred; set both to 0 to blur the whole value.")
            }
        }
        .formStyle(.grouped)
    }

    /// A label with a numeric value field plus a stepper (rather than an inline stepper label).
    private func revealCountRow(_ title: String, _ value: Binding<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("", value: value, format: .number)
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .frame(width: 44)
                .textFieldStyle(.roundedBorder)
            Stepper("", value: value, in: 0...20)
                .labelsHidden()
        }
    }

    private func addManualBundleID() {
        let trimmed = manualBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        services.addExcludedApp(bundleID: trimmed)
        manualBundleID = ""
    }

    private func presentAppPicker() {
        NSApp.activate(ignoringOtherApps: true)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        if panel.runModal() == .OK, let url = panel.url {
            services.addExcludedApp(at: url)
        }
    }
}
