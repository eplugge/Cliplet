import XCTest
@testable import ClipletCore

final class ClipModelTests: XCTestCase {
    func testTextClipBuildsSearchTextFromPreviewAndMetadata() {
        let clip = Clip(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            kind: .text,
            preview: "Hello Clipboard",
            contentType: "public.utf8-plain-text",
            filename: nil,
            dimensions: nil,
            byteSize: 15,
            sourceAppBundleID: "com.apple.TextEdit",
            sourceAppName: "TextEdit",
            createdAt: Date(timeIntervalSince1970: 10),
            lastUsedAt: Date(timeIntervalSince1970: 10),
            isPinned: false,
            payload: .inlineText("Hello Clipboard")
        )

        XCTAssertEqual(clip.searchText, "hello clipboard public.utf8-plain-text textedit com.apple.textedit")
    }

    func testDefaultMaskModeIsNone() {
        XCTAssertEqual(makeBasicClip().maskMode, .none)
    }

    /// A clip persisted before `maskMode` existed must still decode (defaulting to .none),
    /// otherwise loading clips.json fails and the whole history is lost on upgrade.
    func testLegacyClipJSONWithoutMaskModeDecodesAsNone() throws {
        let clip = makeBasicClip()
        let data = try JSONEncoder().encode(clip)
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        object.removeValue(forKey: "maskMode") // simulate older persisted data
        let legacy = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(Clip.self, from: legacy)
        XCTAssertEqual(decoded.maskMode, .none)
        XCTAssertEqual(decoded.preview, clip.preview)
        XCTAssertEqual(decoded.id, clip.id)
    }

    func testMaskModeRoundTrips() throws {
        var clip = makeBasicClip()
        clip.maskMode = .blurred
        let decoded = try JSONDecoder().decode(Clip.self, from: JSONEncoder().encode(clip))
        XCTAssertEqual(decoded.maskMode, .blurred)
    }

    func testDefaultAliasIsNil() {
        XCTAssertNil(makeBasicClip().alias)
    }

    func testLegacyClipJSONWithoutAliasDecodesAsNil() throws {
        let clip = makeBasicClip()
        var object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(clip)) as! [String: Any]
        object.removeValue(forKey: "alias")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(Clip.self, from: legacy)
        XCTAssertNil(decoded.alias)
    }

    func testAliasAndHiddenMaskRoundTrip() throws {
        var clip = makeBasicClip()
        clip.alias = "My work password"
        clip.maskMode = .hidden
        let decoded = try JSONDecoder().decode(Clip.self, from: JSONEncoder().encode(clip))
        XCTAssertEqual(decoded.alias, "My work password")
        XCTAssertEqual(decoded.maskMode, .hidden)
    }

    private func makeBasicClip() -> Clip {
        Clip(
            id: UUID(uuidString: "00000000-0000-0000-0000-0000000000AA")!,
            kind: .text,
            preview: "secret",
            contentType: "public.utf8-plain-text",
            filename: nil,
            dimensions: nil,
            byteSize: 6,
            sourceAppBundleID: nil,
            sourceAppName: nil,
            createdAt: Date(timeIntervalSince1970: 10),
            lastUsedAt: Date(timeIntervalSince1970: 10),
            isPinned: false,
            payload: .inlineText("secret")
        )
    }
}
