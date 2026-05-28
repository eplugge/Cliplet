import Foundation

public struct ClipSettings: Codable, Equatable, Sendable {
    public var rememberedClipLimit: Int
    public var visibleRowLimit: Int
    public var moveSelectedClipToTop: Bool
    public var maximumPersistedClipBytes: Int
    public var persistBinaryClips: Bool
    public var autoPasteAfterSelection: Bool

    public init(
        rememberedClipLimit: Int,
        visibleRowLimit: Int,
        moveSelectedClipToTop: Bool,
        maximumPersistedClipBytes: Int,
        persistBinaryClips: Bool,
        autoPasteAfterSelection: Bool
    ) {
        self.rememberedClipLimit = rememberedClipLimit
        self.visibleRowLimit = visibleRowLimit
        self.moveSelectedClipToTop = moveSelectedClipToTop
        self.maximumPersistedClipBytes = maximumPersistedClipBytes
        self.persistBinaryClips = persistBinaryClips
        self.autoPasteAfterSelection = autoPasteAfterSelection
    }

    public static let defaults = ClipSettings(
        rememberedClipLimit: 200,
        visibleRowLimit: 25,
        moveSelectedClipToTop: true,
        maximumPersistedClipBytes: 20 * 1024 * 1024,
        persistBinaryClips: true,
        autoPasteAfterSelection: false
    )
}
