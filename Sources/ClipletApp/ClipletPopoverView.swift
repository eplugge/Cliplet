import ClipletCore
import SwiftUI

struct ClipletPopoverView: View {
    @EnvironmentObject private var services: AppServices
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(services.history.filteredClips.enumerated()), id: \.element.id) { index, clip in
                            ClipRowView(index: index, clip: clip, selected: clip.id == services.history.selectedClipID)
                                .id(clip.id)
                                .onHover { hovering in
                                    if hovering {
                                        services.select(clip)
                                    }
                                }
                                .onTapGesture {
                                    services.restore(clip)
                                }
                                .contextMenu {
                                    Button("Preview") {
                                        services.preview(clip)
                                    }

                                    Button(clip.isPinned ? "Unpin" : "Pin") {
                                        services.togglePinned(clip)
                                    }

                                    Button("Delete") {
                                        services.delete(clip)
                                    }
                                }
                        }
                    }
                }
                .frame(height: CGFloat(services.history.settings.visibleRowLimit) * ClipRowView.height)
                .onChange(of: services.history.selectedClipID) { _, id in
                    guard let id else { return }
                    proxy.scrollTo(id, anchor: .center)
                }
            }

            Divider()
            footer
        }
        .frame(width: 404)
        .background(.regularMaterial)
        .onAppear {
            searchFocused = true
            services.history.moveSelectionToStart()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Current clipboard")
                .font(.system(size: 9, weight: .medium))
                .textCase(.uppercase)
                .foregroundStyle(.quaternary)

            ZStack(alignment: .leading) {
                if services.history.searchQuery.isEmpty {
                    Text(services.currentClipboardPreview)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }

                TextField("Search clips", text: $services.history.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .opacity(services.history.searchQuery.isEmpty ? 0.02 : 1)
                    .focused($searchFocused)
            }
            .frame(height: 18)
        }
        .padding(.horizontal, 12)
        .frame(height: 48)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button("Preferences") {
                services.showSettings()
            }
            .buttonStyle(.plain)

            Button("Clear") {
                services.clearHistory()
            }
            .buttonStyle(.plain)

            Spacer(minLength: 8)

            Button("Quit") {
                services.quit()
            }
            .buttonStyle(.plain)
        }
        .font(.system(size: 11))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 28)
    }
}

private struct ClipRowView: View {
    static let height: CGFloat = 23

    var index: Int
    var clip: Clip
    var selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text(prefix + clip.preview)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(.system(size: 13))
                .foregroundStyle(isBinary ? .secondary : .primary)

            Spacer(minLength: 12)

            if index < 9 {
                Text("⌘\(index + 1)")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: Self.height)
        .background(selected ? Color.accentColor.opacity(0.18) : Color.clear)
    }

    private var isBinary: Bool {
        switch clip.kind {
        case .text, .url:
            return false
        case .image, .file, .audio, .other:
            return true
        }
    }

    private var prefix: String {
        clip.isPinned ? "• " : ""
    }
}
