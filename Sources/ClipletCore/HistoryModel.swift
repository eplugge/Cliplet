import Foundation

public struct HistoryModel: Sendable {
    public private(set) var clips: [Clip]
    public var settings: ClipSettings
    public var searchQuery: String {
        didSet {
            reconcileSelectionWithFilteredClips()
        }
    }
    public private(set) var selectedClipID: UUID?

    private var pendingDelete: (id: UUID, requestedAt: Date)?
    private let deleteConfirmationWindow: TimeInterval = 3

    public init(settings: ClipSettings, clips: [Clip] = [], searchQuery: String = "", selectedClipID: UUID? = nil) {
        self.settings = settings
        self.clips = clips
        self.searchQuery = searchQuery
        self.selectedClipID = selectedClipID ?? clips.first?.id
        trimToLimit()
        reconcileSelectionWithFilteredClips()
    }

    public var filteredClips: [Clip] {
        let query = normalizedSearchText(searchQuery)
        let matchingClips = query.isEmpty
            ? clips
            : clips.filter { normalizedSearchText($0.searchText).contains(query) }

        return matchingClips.sorted(by: clipSort)
    }

    public mutating func addOrUpdate(_ incoming: Clip) {
        if let index = duplicateIndex(for: incoming) {
            let id = clips[index].id
            let createdAt = clips[index].createdAt
            let isPinned = clips[index].isPinned

            clips[index] = incoming
            clips[index].id = id
            clips[index].createdAt = createdAt
            clips[index].isPinned = isPinned
        } else {
            clips.append(incoming)
        }

        trimToLimit()
        if selectedClipID != nil {
            reconcileSelectionWithFilteredClips()
        }
    }

    public mutating func markUsed(_ id: UUID, at date: Date) {
        selectedClipID = id

        guard settings.moveSelectedClipToTop,
              let index = clips.firstIndex(where: { $0.id == id }) else {
            return
        }

        clips[index].lastUsedAt = date
    }

    public mutating func setPinned(_ id: UUID) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[index].isPinned.toggle()
    }

    public mutating func setPinned(_ id: UUID, isPinned: Bool) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[index].isPinned = isPinned
    }

    public mutating func setMaskMode(_ id: UUID, _ maskMode: ClipMaskMode) {
        guard let index = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[index].maskMode = maskMode
    }

    public mutating func removeClip(_ id: UUID) {
        clips.removeAll { $0.id == id }
        if selectedClipID == id {
            selectedClipID = filteredClips.first?.id
        }
    }

    public mutating func removeAllClips() {
        clips.removeAll()
        selectedClipID = nil
        pendingDelete = nil
    }

    public mutating func moveSelection(offset: Int) {
        let visibleClips = filteredClips
        guard !visibleClips.isEmpty else {
            selectedClipID = nil
            return
        }

        guard let currentIndex = selectedClipID
            .flatMap({ id in visibleClips.firstIndex(where: { $0.id == id }) }) else {
            selectedClipID = offset < 0 ? visibleClips.last?.id : visibleClips.first?.id
            return
        }

        let nextIndex = min(max(currentIndex + offset, 0), visibleClips.count - 1)
        selectedClipID = visibleClips[nextIndex].id
    }

    public mutating func moveSelectionToStart() {
        selectedClipID = filteredClips.first?.id
    }

    public mutating func moveSelectionToEnd() {
        selectedClipID = filteredClips.last?.id
    }

    public mutating func selectClip(_ id: UUID?) {
        guard let id else {
            selectedClipID = nil
            return
        }

        if filteredClips.contains(where: { $0.id == id }) {
            selectedClipID = id
        }
    }

    @discardableResult
    public mutating func requestDelete(_ id: UUID, now: Date) -> Bool {
        if let pendingDelete,
           pendingDelete.id == id,
           now.timeIntervalSince(pendingDelete.requestedAt) <= deleteConfirmationWindow {
            clips.removeAll { $0.id == id }
            self.pendingDelete = nil

            if selectedClipID == id {
                selectedClipID = filteredClips.first?.id
            }

            return true
        }

        pendingDelete = (id: id, requestedAt: now)
        selectedClipID = id
        return false
    }

    private func duplicateIndex(for incoming: Clip) -> Int? {
        if let incomingHash = incoming.contentHash {
            return clips.firstIndex { clip in
                clip.kind == incoming.kind &&
                    clip.contentHash == incomingHash &&
                    clip.contentType == incoming.contentType
            }
        }

        switch incoming.payload {
        case .inlineText(let incomingText):
            return clips.firstIndex { clip in
                guard case .inlineText(let text) = clip.payload else { return false }
                return text == incomingText
            }

        case .fileReference(let incomingURL):
            return clips.firstIndex { clip in
                guard case .fileReference(let url) = clip.payload else { return false }
                return url == incomingURL
            }

        case .storedPayload(let incomingFilename):
            return clips.firstIndex { clip in
                guard case .storedPayload(let filename) = clip.payload else { return false }
                return filename == incomingFilename
            }

        case .metadataOnly:
            return clips.firstIndex { clip in
                guard case .metadataOnly = clip.payload else { return false }
                return clip.kind == incoming.kind &&
                    clip.preview == incoming.preview &&
                    clip.contentType == incoming.contentType
            }
        }
    }

    private mutating func trimToLimit() {
        guard settings.rememberedClipLimit >= 0 else { return }

        clips = Array(clips.sorted(by: clipSort).prefix(settings.rememberedClipLimit))

        if let selectedClipID, !clips.contains(where: { $0.id == selectedClipID }) {
            reconcileSelectionWithFilteredClips()
        }
    }

    private mutating func reconcileSelectionWithFilteredClips() {
        let visibleClips = filteredClips
        if let selectedClipID, visibleClips.contains(where: { $0.id == selectedClipID }) {
            return
        }

        selectedClipID = visibleClips.first?.id
    }

    private func clipSort(_ lhs: Clip, _ rhs: Clip) -> Bool {
        if lhs.isPinned != rhs.isPinned {
            return lhs.isPinned
        }

        // Pinned items always sort above unpinned (above). Within a group, recency drives
        // ordering: newest-first by default, or newest-last when the user opts to append new
        // clips to the bottom of the list.
        let newestFirst = !settings.appendNewClipsToBottom

        if lhs.lastUsedAt != rhs.lastUsedAt {
            return newestFirst ? lhs.lastUsedAt > rhs.lastUsedAt : lhs.lastUsedAt < rhs.lastUsedAt
        }

        return newestFirst ? lhs.createdAt > rhs.createdAt : lhs.createdAt < rhs.createdAt
    }

    private func normalizedSearchText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .lowercased()
    }
}
