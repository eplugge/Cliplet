import ClipletCore
import SwiftUI

struct ClipletPopoverView: View {
    @EnvironmentObject private var services: AppServices
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search clips", text: $services.history.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.horizontal, 12)
                .frame(height: 32)
                .focused($searchFocused)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(services.history.filteredClips.enumerated()), id: \.element.id) { index, clip in
                            ClipRowView(index: index, clip: clip, selected: clip.id == services.history.selectedClipID)
                                .id(clip.id)
                                .onTapGesture {
                                    services.restore(clip)
                                }
                                .contextMenu {
                                    Button("Preview") {
                                        services.preview(clip)
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
        }
        .frame(width: 404)
        .background(.regularMaterial)
        .onAppear {
            searchFocused = true
            services.history.moveSelectionToStart()
        }
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

            if index < 10 {
                Text("⌘\(index)")
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
