import XCTest
@testable import ClipletCore

final class ClipClassifierTests: XCTestCase {
    func testTextMetadataUsesSingleLinePreviewAndPreservesOriginalNewlinesInPayload() {
        let now = Date(timeIntervalSince1970: 100)
        let text = "hello\nclipboard\r\nworld"
        let item = ClipClassifier.RawItem(
            representations: [
                .init(
                    typeIdentifier: "public.utf8-plain-text",
                    data: Data(text.utf8),
                    filename: nil
                )
            ],
            sourceAppBundleID: "com.apple.TextEdit",
            sourceAppName: "TextEdit",
            now: now
        )

        let clip = ClipClassifier.classify(item, settings: .defaults)

        XCTAssertEqual(clip.kind, .text)
        XCTAssertEqual(clip.preview, "hello clipboard world")
        XCTAssertEqual(clip.contentType, "public.utf8-plain-text")
        XCTAssertNil(clip.filename)
        XCTAssertEqual(clip.byteSize, Data(text.utf8).count)
        XCTAssertEqual(clip.sourceAppBundleID, "com.apple.TextEdit")
        XCTAssertEqual(clip.sourceAppName, "TextEdit")
        XCTAssertEqual(clip.createdAt, now)
        XCTAssertEqual(clip.lastUsedAt, now)
        XCTAssertEqual(clip.payload, .inlineText(text))
    }

    func testRichTextWithUTF16FirstStillClassifiesAsText() {
        // Mirrors copying from apps like Xcode's console: an RTF rep, a UTF-16 plain-text
        // rep (whose bytes must NOT be decoded as UTF-8), then a UTF-8 plain-text rep.
        // The classifier must land on real text, not the opaque "public.rtf" fallback.
        let now = Date(timeIntervalSince1970: 100)
        let text = "Unable to obtain a task name port right for pid 605"
        let item = ClipClassifier.RawItem(
            representations: [
                .init(typeIdentifier: "public.rtf", data: Data("{\\rtf1 x}".utf8), filename: nil),
                .init(
                    typeIdentifier: "public.utf16-external-plain-text",
                    data: text.data(using: .utf16)!,
                    filename: nil
                ),
                .init(
                    typeIdentifier: "public.utf8-plain-text",
                    data: Data(text.utf8),
                    filename: nil
                )
            ],
            sourceAppBundleID: "com.apple.dt.Xcode",
            sourceAppName: "Xcode",
            now: now
        )

        let clip = ClipClassifier.classify(item, settings: .defaults)

        XCTAssertEqual(clip.kind, .text)
        XCTAssertEqual(clip.preview, text)
        XCTAssertEqual(clip.payload, .inlineText(text))
        XCTAssertEqual(clip.contentType, "public.utf8-plain-text")
    }

    func testUTF16OnlyTextRepresentationDecodesAsText() {
        let now = Date(timeIntervalSince1970: 100)
        let text = "café — résumé"
        let item = ClipClassifier.RawItem(
            representations: [
                .init(
                    typeIdentifier: "public.utf16-external-plain-text",
                    data: text.data(using: .utf16)!,
                    filename: nil
                )
            ],
            sourceAppBundleID: nil,
            sourceAppName: nil,
            now: now
        )

        let clip = ClipClassifier.classify(item, settings: .defaults)

        XCTAssertEqual(clip.kind, .text)
        XCTAssertEqual(clip.payload, .inlineText(text))
    }

    func testOversizedImageUsesMetadataOnlyAndExpectedPreview() {
        var settings = ClipSettings.defaults
        settings.maximumPersistedClipBytes = 4
        let data = Data(repeating: 0x89, count: 2_048)
        let item = ClipClassifier.RawItem(
            representations: [
                .init(typeIdentifier: "public.png", data: data, filename: "Screenshot.png")
            ],
            sourceAppBundleID: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: 200)
        )

        let clip = ClipClassifier.classify(item, settings: settings)

        XCTAssertEqual(clip.kind, .image)
        XCTAssertEqual(clip.preview, "Image: Screenshot.png · PNG · 2 KB")
        XCTAssertEqual(clip.contentType, "public.png")
        XCTAssertEqual(clip.filename, "Screenshot.png")
        XCTAssertEqual(clip.byteSize, 2_048)
        XCTAssertNotNil(clip.contentHash)
        XCTAssertEqual(clip.payload, .metadataOnly)
    }

    func testFileURLMetadataUsesFilenameAndFileReference() throws {
        let url = URL(fileURLWithPath: "/Users/eelco/Desktop/report.pdf")
        let item = ClipClassifier.RawItem(
            representations: [
                .init(typeIdentifier: "public.file-url", data: Data(url.absoluteString.utf8), filename: nil)
            ],
            sourceAppBundleID: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: 300)
        )

        let clip = ClipClassifier.classify(item, settings: .defaults)

        XCTAssertEqual(clip.kind, .file)
        XCTAssertEqual(clip.preview, "File: report.pdf · PDF")
        XCTAssertEqual(clip.contentType, "public.file-url")
        XCTAssertEqual(clip.filename, "report.pdf")
        XCTAssertNil(clip.byteSize)
        XCTAssertEqual(clip.payload, .fileReference(url))
    }

    func testURLRepresentationUsesRestorableInlinePayload() {
        let item = ClipClassifier.RawItem(
            representations: [
                .init(typeIdentifier: "public.url", data: Data("https://example.com/path".utf8), filename: nil)
            ],
            sourceAppBundleID: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: 350)
        )

        let clip = ClipClassifier.classify(item, settings: .defaults)

        XCTAssertEqual(clip.kind, .url)
        XCTAssertEqual(clip.preview, "https://example.com/path")
        XCTAssertEqual(clip.contentType, "public.url")
        XCTAssertEqual(clip.byteSize, Data("https://example.com/path".utf8).count)
        XCTAssertEqual(clip.payload, .inlineText("https://example.com/path"))
    }

    func testURLRepresentationWinsOverPlainTextFallbackAndIgnoresURLNameAsPayload() {
        let item = ClipClassifier.RawItem(
            representations: [
                .init(typeIdentifier: "public.url-name", data: Data("Example title".utf8), filename: nil),
                .init(typeIdentifier: "public.utf8-plain-text", data: Data("https://example.com/text".utf8), filename: nil),
                .init(typeIdentifier: "public.url", data: Data("https://example.com/url".utf8), filename: nil)
            ],
            sourceAppBundleID: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: 360)
        )

        let clip = ClipClassifier.classify(item, settings: .defaults)

        XCTAssertEqual(clip.kind, .url)
        XCTAssertEqual(clip.preview, "https://example.com/url")
        XCTAssertEqual(clip.payload, .inlineText("https://example.com/url"))
    }

    func testBinaryPersistenceDisabledForcesMetadataOnly() {
        var settings = ClipSettings.defaults
        settings.persistBinaryClips = false
        let data = Data(repeating: 0xFF, count: 512)
        let item = ClipClassifier.RawItem(
            representations: [
                .init(typeIdentifier: "public.jpeg", data: data, filename: "Photo.jpg")
            ],
            sourceAppBundleID: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: 400)
        )

        let clip = ClipClassifier.classify(item, settings: settings)

        XCTAssertEqual(clip.kind, .image)
        XCTAssertEqual(clip.preview, "Image: Photo.jpg · JPEG · 512 bytes")
        XCTAssertEqual(clip.contentType, "public.jpeg")
        XCTAssertEqual(clip.filename, "Photo.jpg")
        XCTAssertEqual(clip.byteSize, 512)
        XCTAssertEqual(clip.payload, .metadataOnly)
    }

    func testUnknownClipBecomesOtherAndMetadataOnly() {
        let data = Data([0x00, 0x01, 0x02])
        let item = ClipClassifier.RawItem(
            representations: [
                .init(typeIdentifier: "com.example.custom", data: data, filename: "payload.bin")
            ],
            sourceAppBundleID: nil,
            sourceAppName: nil,
            now: Date(timeIntervalSince1970: 500)
        )

        let clip = ClipClassifier.classify(item, settings: .defaults)

        XCTAssertEqual(clip.kind, .other)
        XCTAssertEqual(clip.preview, "Clipboard Item: com.example.custom · 3 bytes")
        XCTAssertEqual(clip.contentType, "com.example.custom")
        XCTAssertEqual(clip.filename, "payload.bin")
        XCTAssertEqual(clip.byteSize, 3)
        XCTAssertEqual(clip.payload, .metadataOnly)
    }
}
