import XCTest
@testable import ClipletCore

final class ClipStoreTests: XCTestCase {
    private var rootDirectory: URL!

    override func setUpWithError() throws {
        rootDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipStoreTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDownWithError() throws {
        if let rootDirectory,
           FileManager.default.fileExists(atPath: rootDirectory.path) {
            try FileManager.default.removeItem(at: rootDirectory)
        }
        rootDirectory = nil
    }

    func testSaveLoadRoundTripsClipMetadata() throws {
        let store = ClipStore(rootDirectory: rootDirectory)
        let clips = [
            makeClip(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                preview: "Hello",
                created: 10,
                used: 20,
                payload: .inlineText("Hello")
            ),
            makeClip(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                kind: .image,
                preview: "Screenshot.png",
                contentType: "public.png",
                filename: "Screenshot.png",
                dimensions: ClipDimensions(width: 800, height: 600),
                byteSize: 4096,
                sourceAppBundleID: "com.apple.Preview",
                sourceAppName: "Preview",
                created: 30,
                used: 40,
                isPinned: true,
                payload: .storedPayload(filename: "payload.png")
            )
        ]

        try store.save(clips)

        XCTAssertEqual(try store.load(), clips)
    }

    func testLoadReturnsEmptyArrayWhenMetadataIsMissing() throws {
        let store = ClipStore(rootDirectory: rootDirectory)

        XCTAssertEqual(try store.load(), [])
    }

    func testWriteReadPayloadRoundTripsData() throws {
        let store = ClipStore(rootDirectory: rootDirectory)
        let data = Data("payload bytes".utf8)

        try store.writePayload(data, filename: "payload.dat")

        XCTAssertEqual(try store.readPayload(filename: "payload.dat"), data)
    }

    func testPrunePayloadsRemovesUnreferencedPayloadsAndKeepsReferencedFiles() throws {
        let store = ClipStore(rootDirectory: rootDirectory)
        try store.writePayload(Data("keep".utf8), filename: "keep.dat")
        try store.writePayload(Data("remove".utf8), filename: "remove.dat")

        try store.prunePayloads(referencedFilenames: ["keep.dat"])

        XCTAssertEqual(try store.readPayload(filename: "keep.dat"), Data("keep".utf8))
        XCTAssertFalse(FileManager.default.fileExists(atPath: rootDirectory.appendingPathComponent("Payloads/remove.dat").path))
    }

    func testPrunePayloadsNoOpsWhenPayloadDirectoryIsMissing() throws {
        let store = ClipStore(rootDirectory: rootDirectory)

        XCTAssertNoThrow(try store.prunePayloads(referencedFilenames: ["missing.dat"]))
        XCTAssertFalse(FileManager.default.fileExists(atPath: rootDirectory.appendingPathComponent("Payloads").path))
    }

    private func makeClip(
        id: UUID = UUID(),
        kind: ClipKind = .text,
        preview: String,
        contentType: String? = "public.utf8-plain-text",
        filename: String? = nil,
        dimensions: ClipDimensions? = nil,
        byteSize: Int? = nil,
        sourceAppBundleID: String? = nil,
        sourceAppName: String? = nil,
        created: TimeInterval,
        used: TimeInterval,
        isPinned: Bool = false,
        payload: ClipPayload
    ) -> Clip {
        Clip(
            id: id,
            kind: kind,
            preview: preview,
            contentType: contentType,
            filename: filename,
            dimensions: dimensions,
            byteSize: byteSize,
            sourceAppBundleID: sourceAppBundleID,
            sourceAppName: sourceAppName,
            createdAt: Date(timeIntervalSince1970: created),
            lastUsedAt: Date(timeIntervalSince1970: used),
            isPinned: isPinned,
            payload: payload
        )
    }
}
