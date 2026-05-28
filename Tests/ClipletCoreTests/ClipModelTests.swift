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
}
