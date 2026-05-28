import Foundation

public enum PasteboardWriteRequest: Equatable, Sendable {
    case text(String)
    case file(URL)
    case storedPayload(filename: String, contentType: String?)
    case unavailable
}

public enum PasteboardWriting {
    public static func writeRequest(for clip: Clip) -> PasteboardWriteRequest {
        switch clip.payload {
        case let .inlineText(text):
            return .text(text)
        case let .fileReference(url):
            return .file(url)
        case let .storedPayload(filename):
            return .storedPayload(filename: filename, contentType: clip.contentType)
        case .metadataOnly:
            return .unavailable
        }
    }
}
