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

    func testAddOrUpdateSuppressesInlineTextDuplicates() {
        let original = makeClip("same", created: 1, used: 1)
        let duplicate = makeClip("same", created: 2, used: 2)
        var history = HistoryModel(settings: .defaults, clips: [original])

        history.addOrUpdate(duplicate)

        XCTAssertEqual(history.clips.count, 1)
        XCTAssertEqual(history.filteredClips.first?.lastUsedAt, Date(timeIntervalSince1970: 2))
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
        payload: ClipPayload? = nil
    ) -> Clip {
        Clip(
            kind: kind,
            preview: preview,
            contentType: contentType,
            filename: filename,
            dimensions: nil,
            byteSize: preview.utf8.count,
            sourceAppBundleID: nil,
            sourceAppName: nil,
            createdAt: Date(timeIntervalSince1970: created),
            lastUsedAt: Date(timeIntervalSince1970: used),
            isPinned: pinned,
            payload: payload ?? .inlineText(preview)
        )
    }
}
