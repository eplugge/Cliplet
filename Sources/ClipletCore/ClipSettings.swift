import Foundation

public struct ClipSettings: Codable, Equatable, Sendable {
    public var rememberedClipLimit: Int
    public var visibleRowLimit: Int
    public var moveSelectedClipToTop: Bool
    public var maximumPersistedClipBytes: Int
    public var persistBinaryClips: Bool
    public var autoPasteAfterSelection: Bool
    public var appendNewClipsToBottom: Bool
    public var blurLeadingReveal: Int
    public var blurTrailingReveal: Int
    public var hideDuringScreenSharing: Bool

    public init(
        rememberedClipLimit: Int,
        visibleRowLimit: Int,
        moveSelectedClipToTop: Bool,
        maximumPersistedClipBytes: Int,
        persistBinaryClips: Bool,
        autoPasteAfterSelection: Bool,
        appendNewClipsToBottom: Bool = false,
        blurLeadingReveal: Int = 2,
        blurTrailingReveal: Int = 2,
        hideDuringScreenSharing: Bool = true
    ) {
        self.rememberedClipLimit = rememberedClipLimit
        self.visibleRowLimit = visibleRowLimit
        self.moveSelectedClipToTop = moveSelectedClipToTop
        self.maximumPersistedClipBytes = maximumPersistedClipBytes
        self.persistBinaryClips = persistBinaryClips
        self.autoPasteAfterSelection = autoPasteAfterSelection
        self.appendNewClipsToBottom = appendNewClipsToBottom
        self.blurLeadingReveal = blurLeadingReveal
        self.blurTrailingReveal = blurTrailingReveal
        self.hideDuringScreenSharing = hideDuringScreenSharing
    }

    public static let defaults = ClipSettings(
        rememberedClipLimit: 200,
        visibleRowLimit: 25,
        moveSelectedClipToTop: true,
        maximumPersistedClipBytes: 20 * 1024 * 1024,
        persistBinaryClips: true,
        autoPasteAfterSelection: false
    )

    private enum CodingKeys: String, CodingKey {
        case rememberedClipLimit
        case visibleRowLimit
        case moveSelectedClipToTop
        case maximumPersistedClipBytes
        case persistBinaryClips
        case autoPasteAfterSelection
        case appendNewClipsToBottom
        case blurLeadingReveal
        case blurTrailingReveal
        case hideDuringScreenSharing
    }

    /// Decodes each field with a default fallback so settings persisted by an older version
    /// (missing newer keys) still load instead of throwing — which would otherwise reset all
    /// of the user's settings to `.defaults` on upgrade.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = ClipSettings.defaults
        rememberedClipLimit = try container.decodeIfPresent(Int.self, forKey: .rememberedClipLimit) ?? defaults.rememberedClipLimit
        visibleRowLimit = try container.decodeIfPresent(Int.self, forKey: .visibleRowLimit) ?? defaults.visibleRowLimit
        moveSelectedClipToTop = try container.decodeIfPresent(Bool.self, forKey: .moveSelectedClipToTop) ?? defaults.moveSelectedClipToTop
        maximumPersistedClipBytes = try container.decodeIfPresent(Int.self, forKey: .maximumPersistedClipBytes) ?? defaults.maximumPersistedClipBytes
        persistBinaryClips = try container.decodeIfPresent(Bool.self, forKey: .persistBinaryClips) ?? defaults.persistBinaryClips
        autoPasteAfterSelection = try container.decodeIfPresent(Bool.self, forKey: .autoPasteAfterSelection) ?? defaults.autoPasteAfterSelection
        appendNewClipsToBottom = try container.decodeIfPresent(Bool.self, forKey: .appendNewClipsToBottom) ?? defaults.appendNewClipsToBottom
        blurLeadingReveal = try container.decodeIfPresent(Int.self, forKey: .blurLeadingReveal) ?? defaults.blurLeadingReveal
        blurTrailingReveal = try container.decodeIfPresent(Int.self, forKey: .blurTrailingReveal) ?? defaults.blurTrailingReveal
        hideDuringScreenSharing = try container.decodeIfPresent(Bool.self, forKey: .hideDuringScreenSharing) ?? defaults.hideDuringScreenSharing
    }
}
