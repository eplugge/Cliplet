import XCTest
@testable import ClipletCore

final class ClipboardMonitorTests: XCTestCase {
    func testCapturesOnlyWhenChangeCountChanges() {
        var capturedClips: [Clip] = []
        var readCount = 0
        let monitor = ClipboardMonitor(
            sourceAppProvider: { nil },
            readItem: {
                readCount += 1
                return Self.textItem("hello")
            },
            onCapture: { capturedClips.append($0) }
        )

        monitor.poll(changeCount: 1, now: Date(timeIntervalSince1970: 100))
        monitor.poll(changeCount: 1, now: Date(timeIntervalSince1970: 101))
        monitor.poll(changeCount: 2, now: Date(timeIntervalSince1970: 102))

        XCTAssertEqual(readCount, 2)
        XCTAssertEqual(capturedClips.map(\.payload), [.inlineText("hello"), .inlineText("hello")])
    }

    func testSkipsExcludedFrontmostApp() {
        var readCount = 0
        var capturedClips: [Clip] = []
        let monitor = ClipboardMonitor(
            excludedApps: ExcludedApps(bundleIDs: ["com.example.secret"]),
            sourceAppProvider: {
                ClipboardMonitor.SourceApp(
                    bundleID: "COM.EXAMPLE.SECRET",
                    name: "Secret"
                )
            },
            readItem: {
                readCount += 1
                return Self.textItem("secret")
            },
            onCapture: { capturedClips.append($0) }
        )

        monitor.poll(changeCount: 10, now: Date(timeIntervalSince1970: 200))

        XCTAssertEqual(readCount, 0)
        XCTAssertTrue(capturedClips.isEmpty)
    }

    func testSkipsExcludedSourceAppFromRawItem() {
        var capturedClips: [Clip] = []
        let monitor = ClipboardMonitor(
            excludedApps: ExcludedApps(bundleIDs: ["com.example.source"]),
            sourceAppProvider: { nil },
            readItem: {
                Self.textItem(
                    "source secret",
                    bundleID: "com.example.source",
                    appName: "Source"
                )
            },
            onCapture: { capturedClips.append($0) }
        )

        monitor.poll(changeCount: 11, now: Date(timeIntervalSince1970: 250))

        XCTAssertTrue(capturedClips.isEmpty)
    }

    func testSuppressNextChangeCountPreventsDuplicateCaptureAfterRestore() {
        var capturedClips: [Clip] = []
        let monitor = ClipboardMonitor(
            sourceAppProvider: { nil },
            readItem: { Self.textItem("restored") },
            onCapture: { capturedClips.append($0) }
        )

        monitor.poll(changeCount: 1, now: Date(timeIntervalSince1970: 300))
        monitor.suppressNextChangeCount(2)
        monitor.poll(changeCount: 2, now: Date(timeIntervalSince1970: 301))
        monitor.poll(changeCount: 2, now: Date(timeIntervalSince1970: 302))
        monitor.poll(changeCount: 3, now: Date(timeIntervalSince1970: 303))

        XCTAssertEqual(capturedClips.count, 2)
        XCTAssertEqual(capturedClips.map(\.createdAt), [
            Date(timeIntervalSince1970: 300),
            Date(timeIntervalSince1970: 303)
        ])
    }

    func testPollUsesProvidedNowTimestamp() {
        let expectedNow = Date(timeIntervalSince1970: 400)
        var capturedClip: Clip?
        let monitor = ClipboardMonitor(
            sourceAppProvider: { nil },
            readItem: {
                ClipClassifier.RawItem(
                    representations: [
                        .init(
                            typeIdentifier: "public.utf8-plain-text",
                            data: Data("timestamp".utf8),
                            filename: nil
                        )
                    ],
                    sourceAppBundleID: nil,
                    sourceAppName: nil,
                    now: Date(timeIntervalSince1970: 1)
                )
            },
            onCapture: { capturedClip = $0 }
        )

        monitor.poll(changeCount: 5, now: expectedNow)

        XCTAssertEqual(capturedClip?.createdAt, expectedNow)
        XCTAssertEqual(capturedClip?.lastUsedAt, expectedNow)
    }

    func testPasteboardWritingMapsPayloadsToWriteRequests() {
        let fileURL = URL(fileURLWithPath: "/tmp/report.pdf")

        XCTAssertEqual(
            PasteboardWriting.writeRequest(for: Self.clip(payload: .inlineText("copy me"))),
            .text("copy me")
        )
        XCTAssertEqual(
            PasteboardWriting.writeRequest(for: Self.clip(payload: .fileReference(fileURL))),
            .file(fileURL)
        )
        XCTAssertEqual(
            PasteboardWriting.writeRequest(
                for: Self.clip(
                    contentType: "public.png",
                    payload: .storedPayload(filename: "clipboard-image.png")
                )
            ),
            .storedPayload(filename: "clipboard-image.png", contentType: "public.png")
        )
        XCTAssertEqual(
            PasteboardWriting.writeRequest(for: Self.clip(payload: .metadataOnly)),
            .unavailable
        )
    }

    private static func textItem(
        _ text: String,
        bundleID: String? = nil,
        appName: String? = nil
    ) -> ClipClassifier.RawItem {
        ClipClassifier.RawItem(
            representations: [
                .init(
                    typeIdentifier: "public.utf8-plain-text",
                    data: Data(text.utf8),
                    filename: nil
                )
            ],
            sourceAppBundleID: bundleID,
            sourceAppName: appName,
            now: Date(timeIntervalSince1970: 0)
        )
    }

    private static func clip(
        contentType: String? = nil,
        payload: ClipPayload
    ) -> Clip {
        Clip(
            kind: .text,
            preview: "preview",
            contentType: contentType,
            filename: nil,
            dimensions: nil,
            byteSize: nil,
            sourceAppBundleID: nil,
            sourceAppName: nil,
            createdAt: Date(timeIntervalSince1970: 0),
            lastUsedAt: Date(timeIntervalSince1970: 0),
            isPinned: false,
            payload: payload
        )
    }
}
