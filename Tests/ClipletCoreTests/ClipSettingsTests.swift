import XCTest
@testable import ClipletCore

final class ClipSettingsTests: XCTestCase {
    /// Settings persisted by an older version (before `appendNewClipsToBottom` existed) must
    /// still decode — defaulting the new field — instead of throwing and resetting everything.
    func testLegacyJSONWithoutNewKeyDecodesWithDefaults() throws {
        let legacy = """
        {
          "rememberedClipLimit": 123,
          "visibleRowLimit": 40,
          "moveSelectedClipToTop": false,
          "maximumPersistedClipBytes": 1048576,
          "persistBinaryClips": false,
          "autoPasteAfterSelection": true
        }
        """
        let settings = try JSONDecoder().decode(ClipSettings.self, from: Data(legacy.utf8))
        // New field defaults; existing fields preserved (not reset to .defaults).
        XCTAssertEqual(settings.appendNewClipsToBottom, false)
        XCTAssertEqual(settings.rememberedClipLimit, 123)
        XCTAssertEqual(settings.visibleRowLimit, 40)
        XCTAssertEqual(settings.moveSelectedClipToTop, false)
        XCTAssertEqual(settings.maximumPersistedClipBytes, 1_048_576)
        XCTAssertEqual(settings.persistBinaryClips, false)
        XCTAssertEqual(settings.autoPasteAfterSelection, true)
    }

    func testRoundTripPreservesAppendFlag() throws {
        var settings = ClipSettings.defaults
        settings.appendNewClipsToBottom = true
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(ClipSettings.self, from: data)
        XCTAssertEqual(decoded, settings)
        XCTAssertTrue(decoded.appendNewClipsToBottom)
    }

    func testDefaultAppendFlagIsFalse() {
        XCTAssertFalse(ClipSettings.defaults.appendNewClipsToBottom)
    }
}
