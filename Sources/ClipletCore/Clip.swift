import Foundation

public enum ClipKind: String, Codable, Equatable, Sendable {
    case text
    case url
    case image
    case file
    case audio
    case other
}

public struct ClipDimensions: Codable, Equatable, Sendable {
    public var width: Int
    public var height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }
}

public enum ClipPayload: Codable, Equatable, Sendable {
    case inlineText(String)
    case fileReference(URL)
    case storedPayload(filename: String)
    case metadataOnly
}

public struct Clip: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var kind: ClipKind
    public var preview: String
    public var contentType: String?
    public var filename: String?
    public var dimensions: ClipDimensions?
    public var byteSize: Int?
    public var contentHash: String?
    public var sourceAppBundleID: String?
    public var sourceAppName: String?
    public var createdAt: Date
    public var lastUsedAt: Date
    public var isPinned: Bool
    public var payload: ClipPayload

    public init(
        id: UUID = UUID(),
        kind: ClipKind,
        preview: String,
        contentType: String?,
        filename: String?,
        dimensions: ClipDimensions?,
        byteSize: Int?,
        contentHash: String? = nil,
        sourceAppBundleID: String?,
        sourceAppName: String?,
        createdAt: Date,
        lastUsedAt: Date,
        isPinned: Bool,
        payload: ClipPayload
    ) {
        self.id = id
        self.kind = kind
        self.preview = preview
        self.contentType = contentType
        self.filename = filename
        self.dimensions = dimensions
        self.byteSize = byteSize
        self.contentHash = contentHash
        self.sourceAppBundleID = sourceAppBundleID
        self.sourceAppName = sourceAppName
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isPinned = isPinned
        self.payload = payload
    }

    public var searchText: String {
        [
            preview,
            contentType,
            filename,
            contentHash,
            sourceAppName,
            sourceAppBundleID
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }
}
