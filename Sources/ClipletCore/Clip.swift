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

public enum ClipMaskMode: String, Codable, Equatable, Sendable {
    case none
    case blurred
    case hidden
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
    public var maskMode: ClipMaskMode
    public var alias: String?
    public var pinnedOrder: Int?
    public var ephemeral: Bool

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
        payload: ClipPayload,
        maskMode: ClipMaskMode = .none,
        alias: String? = nil,
        pinnedOrder: Int? = nil,
        ephemeral: Bool = false
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
        self.maskMode = maskMode
        self.alias = alias
        self.pinnedOrder = pinnedOrder
        self.ephemeral = ephemeral
    }

    private enum CodingKeys: String, CodingKey {
        case id, kind, preview, contentType, filename, dimensions, byteSize, contentHash
        case sourceAppBundleID, sourceAppName, createdAt, lastUsedAt, isPinned, payload, maskMode, alias, pinnedOrder, ephemeral
    }

    /// `maskMode` decodes with a default so clips persisted before it existed still load
    /// (a missing key would otherwise throw and lose the entire history on upgrade).
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        kind = try c.decode(ClipKind.self, forKey: .kind)
        preview = try c.decode(String.self, forKey: .preview)
        contentType = try c.decodeIfPresent(String.self, forKey: .contentType)
        filename = try c.decodeIfPresent(String.self, forKey: .filename)
        dimensions = try c.decodeIfPresent(ClipDimensions.self, forKey: .dimensions)
        byteSize = try c.decodeIfPresent(Int.self, forKey: .byteSize)
        contentHash = try c.decodeIfPresent(String.self, forKey: .contentHash)
        sourceAppBundleID = try c.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
        sourceAppName = try c.decodeIfPresent(String.self, forKey: .sourceAppName)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        lastUsedAt = try c.decode(Date.self, forKey: .lastUsedAt)
        isPinned = try c.decode(Bool.self, forKey: .isPinned)
        payload = try c.decode(ClipPayload.self, forKey: .payload)
        maskMode = try c.decodeIfPresent(ClipMaskMode.self, forKey: .maskMode) ?? .none
        alias = try c.decodeIfPresent(String.self, forKey: .alias)
        pinnedOrder = try c.decodeIfPresent(Int.self, forKey: .pinnedOrder)
        ephemeral = try c.decodeIfPresent(Bool.self, forKey: .ephemeral) ?? false
    }

    public var searchText: String {
        [
            preview,
            alias,
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
