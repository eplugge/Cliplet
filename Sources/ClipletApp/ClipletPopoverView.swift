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

                                    Button(clip.maskMode == .blurred ? "Unblur" : "Blur") {
                                        services.setMaskMode(clip.id, clip.maskMode == .blurred ? .none : .blurred)
                                    }

                                    Button("Edit…") {
                                        services.editClip(clip)
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
                // Scrolls only on keyboard navigation (which sets scrollTargetID); hover
                // selection leaves it untouched, so the list never yanks under the mouse.
                .onChange(of: services.scrollTargetID) { _, id in
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
        let chromeHeight: CGFloat = 130 // header + footer + dividers
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
        ZStack(alignment: .leading) {
            if services.history.searchQuery.isEmpty {
                Text("Type to filter. Click to copy.")
                    .lineLimit(1)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            TextField("Type to filter. Click to copy.", text: $services.history.searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .opacity(services.history.searchQuery.isEmpty ? 0.02 : 1)
                .focused($searchFocused)
        }
        .padding(.horizontal, 12)
        .frame(height: 36)
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

    @EnvironmentObject private var services: AppServices
    var index: Int
    var clip: Clip
    var selected: Bool

    var body: some View {
        HStack(spacing: 8) {
            valueLabel
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
        .background(selected ? Color.accentColor.opacity(0.18) : Color.clear)
        // Make the whole row width hit-test for hover and taps, not just the text.
        .contentShape(Rectangle())
        // Hovering a row selects it, so the mouse and keyboard share one highlight and
        // arrows continue from the hovered row. Selection changes don't scroll (only
        // keyboard navigation does), so this never yanks the list under the mouse.
        .onHover { hovering in
            if hovering { services.hoverSelect(clip.id) }
        }
    }

    /// A subtle pushpin (when pinned), the clip value (masked per its display mode), then an
    /// optional italic alias. The pin icon sits outside the value so it never blurs.
    @ViewBuilder private var valueLabel: some View {
        HStack(spacing: 5) {
            if clip.isPinned {
                Image(systemName: "pin.fill")
                    .rotationEffect(.degrees(45))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .frame(height: Self.height)
            }
            maskedValue
            if let alias = aliasText {
                Text(alias)
                    .italic()
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// The value portion: gaussian-blurred middle when blurred, a placeholder when hidden, or
    /// the plain value when shown/revealed.
    @ViewBuilder private var maskedValue: some View {
        if !services.isRevealed(clip) && clip.maskMode == .blurred {
            let seg = BlurSegments.split(
                clip.preview,
                leading: services.settings.blurLeadingReveal,
                trailing: services.settings.blurTrailingReveal
            )
            HStack(spacing: 0) {
                Text(seg.prefix)
                Text(seg.middle).blur(radius: 4.5)
                Text(seg.suffix)
            }
            .clipped()
        } else if !services.isRevealed(clip) && clip.maskMode == .hidden {
            Text(ClipDisplay.hiddenPlaceholder)
        } else {
            Text(clip.preview)
        }
    }

    private var aliasText: String? {
        let trimmed = clip.alias?.trimmingCharacters(in: .whitespacesAndNewlines)
        return (trimmed?.isEmpty == false) ? trimmed : nil
    }

    private var isBinary: Bool {
        switch clip.kind {
        case .text, .url:
            return false
        case .image, .file, .audio, .other:
            return true
        }
    }
}
