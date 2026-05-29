import AppKit
import ClipletCore
import SwiftUI

struct ClipletPopoverView: View {
    @EnvironmentObject private var services: AppServices
    @FocusState private var searchFocused: Bool

    var body: some View {
        // Compute the filtered+sorted list once per render; it is read by both the
        // row list and the height calculation, and re-sorting is not free.
        let visibleClips = services.history.filteredClips

        return VStack(spacing: 0) {
            header

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(visibleClips.enumerated()), id: \.element.id) { index, clip in
                            ClipRowView(index: index, clip: clip, selected: clip.id == services.history.selectedClipID)
                                .id(clip.id)
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
                .frame(height: listHeight(clipCount: visibleClips.count))
                // Only fires on keyboard-driven selection changes now that hover is
                // decoupled, so the list no longer yanks itself around under the mouse.
                .onChange(of: services.history.selectedClipID) { _, id in
                    guard let id else { return }
                    proxy.scrollTo(id, anchor: .center)
                }
            }

            Divider()
            footer
        }
        .frame(width: 440)
        .background(.regularMaterial)
        .onAppear {
            searchFocused = true
            services.history.moveSelectionToStart()
        }
    }

    /// Height of the scrollable clip list: sized to the clips that exist, capped by
    /// the user's visible-row preference and by how much vertical room the screen has,
    /// so the popover never shows empty space or runs off-screen. The full list stays
    /// scrollable when it exceeds this height.
    private func listHeight(clipCount: Int) -> CGFloat {
        let screenHeight = NSScreen.main?.visibleFrame.height ?? 800
        let chromeHeight: CGFloat = 156 // header + footer + dividers
        let edgeMargin: CGFloat = 40 // keep clear of the screen edges
        let available = screenHeight - chromeHeight - edgeMargin

        let rows = PopoverLayout.visibleRowCount(
            clipCount: clipCount,
            visibleRowLimit: services.history.settings.visibleRowLimit,
            rowHeight: ClipRowView.height,
            availableHeight: available
        )
        return CGFloat(rows) * ClipRowView.height
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

            if services.history.searchQuery.isEmpty {
                Text("Type to filter · click a clip to copy it")
                    .font(.system(size: 10))
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 62)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            footerButton("Clear", action: services.clearHistory)
            footerButton("Preferences", action: services.showSettings)
            footerButton("Quit", action: services.quit)
        }
        .padding(.vertical, 4)
    }

    private func footerButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .frame(height: 28)
    }
}

private struct ClipRowView: View {
    static let height: CGFloat = 23

    var index: Int
    var clip: Clip
    var selected: Bool
    @State private var isHovered = false

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: Self.height)
        .background(rowBackground)
        // Make the whole row width hit-test for hover and taps, not just the text.
        .contentShape(Rectangle())
        // Hover only highlights this row locally — it does not touch the shared
        // model, so it never triggers a re-filter/re-sort or a scroll.
        .onHover { isHovered = $0 }
    }

    private var rowBackground: Color {
        if selected {
            return Color.accentColor.opacity(0.18)
        }
        if isHovered {
            return Color.primary.opacity(0.08)
        }
        return Color.clear
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
