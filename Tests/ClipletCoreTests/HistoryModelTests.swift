import XCTest
@testable import ClipletCore

final class HistoryModelTests: XCTestCase {
    func testDefaultSettingsMatchPlanValues() {
        XCTAssertEqual(ClipSettings.defaults.rememberedClipLimit, 200)
        XCTAssertEqual(ClipSettings.defaults.visibleRowLimit, 25)
        XCTAssertTrue(ClipSettings.defaults.moveSelectedClipToTop)
        XCTAssertEqual(ClipSettings.defaults.maximumPersistedClipBytes, 20 * 1024 * 1024)
        XCTAssertTrue(ClipSettings.defaults.persistBinaryClips)
        XCTAssertFalse(ClipSettings.defaults.autoPasteAfterSelection)
    }

    func testPinnedClipsSortAboveRecentUnpinnedClips() {
        let olderPinned = makeClip("Pinned", pinned: true, created: 1, used: 1)
        let newerRegular = makeClip("Regular", pinned: false, created: 10, used: 10)
        let history = HistoryModel(settings: .defaults, clips: [newerRegular, olderPinned])

        XCTAssertEqual(history.filteredClips.map(\.preview), ["Pinned", "Regular"])
    }

    func testDefaultOrderingPlacesNewestFirst() {
        let older = makeClip("older", created: 1, used: 1)
        let newer = makeClip("newer", created: 10, used: 10)
        let history = HistoryModel(settings: .defaults, clips: [older, newer])

        XCTAssertEqual(history.filteredClips.map(\.preview), ["newer", "older"])
    }

    func testAppendToBottomPlacesNewestLastButKeepsPinnedFirst() {
        var settings = ClipSettings.defaults
        settings.appendNewClipsToBottom = true
        let older = makeClip("older", created: 1, used: 1)
        let newer = makeClip("newer", created: 10, used: 10)
        let pinned = makeClip("pinned", pinned: true, created: 5, used: 5)
        let history = HistoryModel(settings: settings, clips: [newer, older, pinned])

        let order = history.filteredClips.map(\.preview)
        XCTAssertEqual(order.first, "pinned")                       // pinned always on top
        XCTAssertEqual(Array(order.dropFirst()), ["older", "newer"]) // newest last
    }

    func testAppendToBottomStillPromotesReusedClipToTop() {
        // append-to-bottom ON + move-used-to-top ON: a re-used clip must go to the TOP,
        // while never-used clips order oldest->newest (new captures at the bottom).
        var settings = ClipSettings.defaults
        settings.appendNewClipsToBottom = true
        settings.moveSelectedClipToTop = true
        let new1 = makeClip("new1", created: 1, used: 1)
        let new2 = makeClip("new2", created: 2, used: 2)
        let reused = makeClip("reused", created: 1, used: 99) // created early, used recently
        let history = HistoryModel(settings: settings, clips: [new1, new2, reused])

        XCTAssertEqual(history.filteredClips.map(\.preview), ["reused", "new1", "new2"])
    }

    func testAppendToBottomWithMoveOffOrdersByCreationAscending() {
        var settings = ClipSettings.defaults
        settings.appendNewClipsToBottom = true
        settings.moveSelectedClipToTop = false
        let a = makeClip("a", created: 1, used: 1)
        let b = makeClip("b", created: 2, used: 2)
        let history = HistoryModel(settings: settings, clips: [b, a])

        XCTAssertEqual(history.filteredClips.map(\.preview), ["a", "b"])
    }

    func testSetMaskModeUpdatesOnlyTargetClip() {
        let a = makeClip("a", created: 1, used: 1)
        let b = makeClip("b", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults, clips: [a, b])

        history.setMaskMode(a.id, .blurred)

        XCTAssertEqual(history.clips.first { $0.id == a.id }?.maskMode, ClipMaskMode.blurred)
        XCTAssertEqual(history.clips.first { $0.id == b.id }?.maskMode, ClipMaskMode.none)
    }

    func testPinningIsAdditiveSoNewPinsGoBelowExistingPins() {
        let a = makeClip("a", created: 1, used: 1)
        let b = makeClip("b", created: 2, used: 2) // more recently used than a
        var history = HistoryModel(settings: .defaults, clips: [a, b])

        history.setPinned(a.id, isPinned: true) // pinned first
        history.setPinned(b.id, isPinned: true) // pinned second

        // Despite b being newer, a (pinned first) stays above b.
        XCTAssertEqual(history.filteredClips.filter(\.isPinned).map(\.preview), ["a", "b"])
    }

    func testUnpinClearsPinnedOrder() {
        let a = makeClip("a")
        var history = HistoryModel(settings: .defaults, clips: [a])

        history.setPinned(a.id, isPinned: true)
        XCTAssertNotNil(history.clips.first?.pinnedOrder)

        history.setPinned(a.id, isPinned: false)
        XCTAssertNil(history.clips.first?.pinnedOrder)
    }

    func testMovePinnedReordersPinnedGroup() {
        let a = makeClip("a", created: 1, used: 1)
        let b = makeClip("b", created: 2, used: 2)
        let c = makeClip("c", created: 3, used: 3)
        var history = HistoryModel(settings: .defaults, clips: [a, b, c])
        history.setPinned(a.id, isPinned: true)
        history.setPinned(b.id, isPinned: true)
        history.setPinned(c.id, isPinned: true)
        XCTAssertEqual(history.filteredClips.filter(\.isPinned).map(\.preview), ["a", "b", "c"])

        history.movePinned(fromOffsets: IndexSet(integer: 2), toOffset: 0) // move c to front

        XCTAssertEqual(history.filteredClips.filter(\.isPinned).map(\.preview), ["c", "a", "b"])
    }

    func testSetAliasUpdatesOnlyTargetClip() {
        let a = makeClip("a", created: 1, used: 1)
        let b = makeClip("b", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults, clips: [a, b])

        history.setAlias(a.id, "Work login")

        XCTAssertEqual(history.clips.first { $0.id == a.id }?.alias, "Work login")
        XCTAssertNil(history.clips.first { $0.id == b.id }?.alias)
    }

    func testSearchFiltersPreviewAndMetadataImmediately() {
        let image = makeClip("Image: Photo123.png - PNG - 1024x768", kind: .image, contentType: "public.png", filename: "Photo123.png")
        let text = makeClip("coordinator")
        var history = HistoryModel(settings: .defaults, clips: [image, text])

        history.searchQuery = "png"

        XCTAssertEqual(history.filteredClips.map(\.preview), ["Image: Photo123.png - PNG - 1024x768"])
    }

    func testSearchQuerySelectsFirstMatchWhenCurrentSelectionIsFilteredOut() {
        let first = makeClip("alpha", created: 1, used: 1)
        let second = makeClip("beta", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults, clips: [first, second])

        history.moveSelectionToEnd()
        XCTAssertEqual(history.selectedClipID, first.id)

        history.searchQuery = "beta"

        XCTAssertEqual(history.filteredClips.map(\.preview), ["beta"])
        XCTAssertEqual(history.selectedClipID, second.id)
    }

    func testSearchQueryClearsSelectionWhenThereAreNoMatches() {
        let clip = makeClip("alpha")
        var history = HistoryModel(settings: .defaults, clips: [clip])

        history.searchQuery = "missing"

        XCTAssertTrue(history.filteredClips.isEmpty)
        XCTAssertNil(history.selectedClipID)
    }

    func testSelectingClipPromotesExistingEntryWithoutDuplicateWhenEnabled() {
        let first = makeClip("first", created: 1, used: 1)
        let second = makeClip("second", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults, clips: [second, first])

        history.markUsed(first.id, at: Date(timeIntervalSince1970: 20))

        XCTAssertEqual(history.clips.count, 2)
        XCTAssertEqual(history.selectedClipID, first.id)
        XCTAssertEqual(history.filteredClips.map(\.preview), ["first", "second"])
    }

    func testSelectingClipDoesNotPromoteWhenDisabled() {
        var settings = ClipSettings.defaults
        settings.moveSelectedClipToTop = false
        let first = makeClip("first", created: 1, used: 1)
        let second = makeClip("second", created: 2, used: 2)
        var history = HistoryModel(settings: settings, clips: [second, first])

        history.markUsed(first.id, at: Date(timeIntervalSince1970: 20))

        XCTAssertEqual(history.selectedClipID, first.id)
        XCTAssertEqual(history.filteredClips.map(\.preview), ["second", "first"])
    }

    func testDeleteRequiresSecondDeleteWithinTimeout() {
        let clip = makeClip("delete me")
        var history = HistoryModel(settings: .defaults, clips: [clip])

        XCTAssertFalse(history.requestDelete(clip.id, now: Date(timeIntervalSince1970: 1)))
        XCTAssertEqual(history.clips.count, 1)
        XCTAssertTrue(history.requestDelete(clip.id, now: Date(timeIntervalSince1970: 2)))
        XCTAssertTrue(history.clips.isEmpty)
    }

    func testDeleteRequiresSameClipWithinTimeout() {
        let first = makeClip("first")
        let second = makeClip("second")
        var history = HistoryModel(settings: .defaults, clips: [first, second])

        XCTAssertFalse(history.requestDelete(first.id, now: Date(timeIntervalSince1970: 1)))
        XCTAssertFalse(history.requestDelete(second.id, now: Date(timeIntervalSince1970: 2)))
        XCTAssertFalse(history.requestDelete(first.id, now: Date(timeIntervalSince1970: 5)))

        XCTAssertEqual(history.clips.count, 2)
    }

    func testRemoveAllClipsClearsHistoryAndSelection() {
        let first = makeClip("first")
        let second = makeClip("second")
        var history = HistoryModel(settings: .defaults, clips: [first, second])

        history.removeAllClips()

        XCTAssertTrue(history.clips.isEmpty)
        XCTAssertNil(history.selectedClipID)
    }

    func testAddOrUpdateSuppressesInlineTextDuplicates() {
        let original = makeClip("same", created: 1, used: 1)
        let duplicate = makeClip("same", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults, clips: [original])

        history.addOrUpdate(duplicate)

        XCTAssertEqual(history.clips.count, 1)
        XCTAssertEqual(history.filteredClips.first?.lastUsedAt, Date(timeIntervalSince1970: 2))
    }

    func testAddOrUpdateSuppressesStoredPayloadDuplicatesByContentHash() {
        let original = makeClip(
            "Image: Clipboard Image - PNG - 777.2 KB",
            kind: .image,
            created: 1,
            used: 1,
            contentType: "public.png",
            contentHash: "same-image-hash",
            payload: .storedPayload(filename: "first.png")
        )
        let duplicate = makeClip(
            "Image: Clipboard Image - PNG - 777.2 KB",
            kind: .image,
            created: 2,
            used: 2,
            contentType: "public.png",
            contentHash: "same-image-hash",
            payload: .storedPayload(filename: "second.png")
        )
        var history = HistoryModel(settings: .defaults, clips: [original])

        history.addOrUpdate(duplicate)

        XCTAssertEqual(history.clips.count, 1)
        XCTAssertEqual(history.filteredClips.first?.lastUsedAt, Date(timeIntervalSince1970: 2))
        XCTAssertEqual(history.filteredClips.first?.payload, .storedPayload(filename: "second.png"))
    }

    func testAddOrUpdateClearsSelectionWhenUpdatedDuplicateNoLongerMatchesSearch() {
        let original = makeClip(
            "Image: Photo123.png - PNG - 1024x768",
            kind: .image,
            created: 1,
            used: 1,
            contentType: "public.png",
            filename: "Photo123.png",
            payload: .inlineText("same clipboard payload")
        )
        let duplicate = makeClip(
            "same clipboard payload",
            created: 2,
            used: 2,
            contentType: "public.utf8-plain-text",
            payload: .inlineText("same clipboard payload")
        )
        var history = HistoryModel(settings: .defaults, clips: [original], searchQuery: "png")

        XCTAssertEqual(history.selectedClipID, original.id)

        history.addOrUpdate(duplicate)

        XCTAssertTrue(history.filteredClips.isEmpty)
        XCTAssertNil(history.selectedClipID)
    }

    func testMoveSelectionUsesFilteredOrderAndBounds() {
        let first = makeClip("first", pinned: true, created: 1, used: 1)
        let second = makeClip("second", created: 2, used: 2)
        let third = makeClip("third", created: 3, used: 3)
        var history = HistoryModel(settings: .defaults, clips: [second, first, third])

        history.moveSelectionToStart()
        XCTAssertEqual(history.selectedClipID, first.id)

        history.moveSelection(offset: 1)
        XCTAssertEqual(history.selectedClipID, third.id)

        history.moveSelectionToEnd()
        XCTAssertEqual(history.selectedClipID, second.id)

        history.moveSelection(offset: 10)
        XCTAssertEqual(history.selectedClipID, second.id)
    }

    func testMoveSelectionFromNoSelectionChoosesFirstVisibleClipForPositiveOffset() {
        let first = makeClip("first", created: 1, used: 1)
        let second = makeClip("second", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults)
        history.addOrUpdate(first)
        history.addOrUpdate(second)

        XCTAssertNil(history.selectedClipID)

        history.moveSelection(offset: 1)

        XCTAssertEqual(history.selectedClipID, second.id)
    }

    func testMoveSelectionFromNoSelectionChoosesLastVisibleClipForNegativeOffset() {
        let first = makeClip("first", created: 1, used: 1)
        let second = makeClip("second", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults)
        history.addOrUpdate(first)
        history.addOrUpdate(second)

        XCTAssertNil(history.selectedClipID)

        history.moveSelection(offset: -1)

        XCTAssertEqual(history.selectedClipID, first.id)
    }

    func testSelectClipOnlySelectsVisibleClips() {
        let visible = makeClip("visible match", created: 1, used: 1)
        let hidden = makeClip("hidden", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults, clips: [visible, hidden], searchQuery: "match")

        history.selectClip(hidden.id)

        XCTAssertEqual(history.selectedClipID, visible.id)

        history.selectClip(visible.id)

        XCTAssertEqual(history.selectedClipID, visible.id)
    }

    func testTrimPreservesPinnedAndMostRecentlyUsedClips() {
        var settings = ClipSettings.defaults
        settings.rememberedClipLimit = 2
        let olderPinned = makeClip("pinned", pinned: true, created: 1, used: 1)
        let newerRegular = makeClip("newer", created: 3, used: 3)
        let olderRegular = makeClip("older", created: 2, used: 2)
        var history = HistoryModel(settings: settings, clips: [])

        history.addOrUpdate(olderRegular)
        history.addOrUpdate(olderPinned)
        history.addOrUpdate(newerRegular)

        XCTAssertEqual(history.filteredClips.map(\.preview), ["pinned", "newer"])
    }

    private func makeClip(
        _ preview: String,
        kind: ClipKind = .text,
        pinned: Bool = false,
        created: TimeInterval = 1,
        used: TimeInterval = 1,
        contentType: String? = "public.utf8-plain-text",
        filename: String? = nil,
        contentHash: String? = nil,
        payload: ClipPayload? = nil
    ) -> Clip {
        Clip(
            kind: kind,
            preview: preview,
            contentType: contentType,
            filename: filename,
            dimensions: nil,
            byteSize: preview.utf8.count,
            contentHash: contentHash,
            sourceAppBundleID: nil,
            sourceAppName: nil,
            createdAt: Date(timeIntervalSince1970: created),
            lastUsedAt: Date(timeIntervalSince1970: used),
            isPinned: pinned,
            payload: payload ?? .inlineText(preview)
        )
    }
}
