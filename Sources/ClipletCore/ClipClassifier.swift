import CryptoKit
import Foundation

public enum ClipClassifier {
    public struct RawRepresentation: Equatable, Sendable {
        public var typeIdentifier: String
        public var data: Data
        public var filename: String?
        public var storedPayloadFilename: String?

        public init(typeIdentifier: String, data: Data, filename: String?, storedPayloadFilename: String? = nil) {
            self.typeIdentifier = typeIdentifier
            self.data = data
            self.filename = filename
            self.storedPayloadFilename = storedPayloadFilename
        }
    }

    public struct RawItem: Equatable, Sendable {
        public var representations: [RawRepresentation]
        public var sourceAppBundleID: String?
        public var sourceAppName: String?
        public var now: Date

        public init(
            representations: [RawRepresentation],
            sourceAppBundleID: String?,
            sourceAppName: String?,
            now: Date
        ) {
            self.representations = representations
            self.sourceAppBundleID = sourceAppBundleID
            self.sourceAppName = sourceAppName
            self.now = now
        }
    }

    public static func classify(_ item: RawItem, settings: ClipSettings) -> Clip {
        if let urlRepresentation = item.representations.first(where: isURLRepresentation),
           let urlString = String(data: urlRepresentation.data, encoding: .utf8) {
            let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
            if URL(string: trimmedURL) != nil {
                return makeClip(
                    item: item,
                    kind: .url,
                    preview: trimmedURL,
                    contentType: urlRepresentation.typeIdentifier,
                filename: nil,
                byteSize: urlRepresentation.data.count,
                contentHash: contentHash(for: urlRepresentation.data),
                payload: .inlineText(trimmedURL)
            )
            }
        }

        if let decoded = firstDecodableText(in: item.representations) {
            return makeClip(
                item: item,
                kind: .text,
                preview: singleLinePreview(for: decoded.text),
                contentType: "public.utf8-plain-text",
                filename: decoded.representation.filename,
                byteSize: decoded.representation.data.count,
                contentHash: contentHash(for: decoded.representation.data),
                payload: .inlineText(decoded.text)
            )
        }

        if let fileRepresentation = item.representations.first(where: isFileURLRepresentation),
           let urlString = String(data: fileRepresentation.data, encoding: .utf8),
           let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)),
           url.isFileURL {
            let filename = url.lastPathComponent
            return makeClip(
                item: item,
                kind: .file,
                preview: "File: \(filename) · \(fileExtensionLabel(for: url.pathExtension))",
                contentType: fileRepresentation.typeIdentifier,
                filename: filename,
                byteSize: nil,
                contentHash: contentHash(for: fileRepresentation.data),
                payload: .fileReference(url)
            )
        }

        if let imageRepresentation = item.representations.first(where: isImageRepresentation) {
            let filename = imageRepresentation.filename
            let displayName = filename?.isEmpty == false ? filename! : "Clipboard Image"
            let typeLabel = imageTypeLabel(for: imageRepresentation.typeIdentifier, filename: filename)
            let byteSize = imageRepresentation.data.count
            let payload: ClipPayload
            if settings.persistBinaryClips && byteSize <= settings.maximumPersistedClipBytes {
                payload = .storedPayload(
                    filename: imageRepresentation.storedPayloadFilename ??
                        filename ??
                        defaultImageFilename(for: imageRepresentation.typeIdentifier)
                )
            } else {
                payload = .metadataOnly
            }

            return makeClip(
                item: item,
                kind: .image,
                preview: "Image: \(displayName) · \(typeLabel) · \(formattedBytes(byteSize))",
                contentType: imageRepresentation.typeIdentifier,
                filename: filename,
                byteSize: byteSize,
                contentHash: contentHash(for: imageRepresentation.data),
                payload: payload
            )
        }

        let representation = item.representations.first
        let contentType = representation?.typeIdentifier
        let byteSize = representation?.data.count
        let filename = representation?.filename
        let preview: String
        if let contentType, let byteSize {
            preview = "Clipboard Item: \(contentType) · \(formattedBytes(byteSize))"
        } else {
            preview = "Clipboard Item"
        }

        return makeClip(
            item: item,
            kind: .other,
            preview: preview,
            contentType: contentType,
            filename: filename,
            byteSize: byteSize,
            contentHash: representation.map { contentHash(for: $0.data) },
            payload: .metadataOnly
        )
    }

    private static func makeClip(
        item: RawItem,
        kind: ClipKind,
        preview: String,
        contentType: String?,
        filename: String?,
        byteSize: Int?,
        contentHash: String?,
        payload: ClipPayload
    ) -> Clip {
        Clip(
            kind: kind,
            preview: preview,
            contentType: contentType,
            filename: filename,
            dimensions: nil,
            byteSize: byteSize,
            contentHash: contentHash,
            sourceAppBundleID: item.sourceAppBundleID,
            sourceAppName: item.sourceAppName,
            createdAt: item.now,
            lastUsedAt: item.now,
            isPinned: false,
            payload: payload
        )
    }

    /// Returns the first text representation that actually decodes to non-empty text,
    /// using an encoding appropriate to its type. Picking by type alone is not enough:
    /// `public.utf16-external-plain-text` matches the text check but its bytes are UTF-16,
    /// so decoding them as UTF-8 fails — we must keep looking instead of giving up.
    private static func firstDecodableText(
        in representations: [RawRepresentation]
    ) -> (representation: RawRepresentation, text: String)? {
        for representation in representations where isTextRepresentation(representation) {
            if let text = decodeText(representation), !text.isEmpty {
                return (representation, text)
            }
        }
        return nil
    }

    private static func decodeText(_ representation: RawRepresentation) -> String? {
        if representation.typeIdentifier.lowercased().contains("utf16") {
            return String(data: representation.data, encoding: .utf16)
                ?? String(data: representation.data, encoding: .utf8)
        }
        return String(data: representation.data, encoding: .utf8)
            ?? String(data: representation.data, encoding: .utf16)
    }

    private static func isTextRepresentation(_ representation: RawRepresentation) -> Bool {
        let typeIdentifier = representation.typeIdentifier.lowercased()
        return typeIdentifier == "public.utf8-plain-text"
            || typeIdentifier == "public.plain-text"
            || typeIdentifier == "public.text"
            || typeIdentifier.contains("utf8")
            || typeIdentifier.contains("text")
    }

    private static func isFileURLRepresentation(_ representation: RawRepresentation) -> Bool {
        representation.typeIdentifier.lowercased() == "public.file-url"
    }

    private static func isURLRepresentation(_ representation: RawRepresentation) -> Bool {
        representation.typeIdentifier.lowercased() == "public.url"
    }

    private static func isImageRepresentation(_ representation: RawRepresentation) -> Bool {
        let typeIdentifier = representation.typeIdentifier.lowercased()
        return typeIdentifier == "public.png"
            || typeIdentifier == "public.jpeg"
            || typeIdentifier == "public.jpg"
            || typeIdentifier == "public.tiff"
            || typeIdentifier.contains("image")
    }

    private static func singleLinePreview(for text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static func fileExtensionLabel(for pathExtension: String) -> String {
        let label = pathExtension.trimmingCharacters(in: .whitespacesAndNewlines)
        return label.isEmpty ? "FILE" : label.uppercased()
    }

    private static func imageTypeLabel(for typeIdentifier: String, filename: String?) -> String {
        let loweredType = typeIdentifier.lowercased()
        if loweredType.contains("png") {
            return "PNG"
        }
        if loweredType.contains("jpeg") || loweredType.contains("jpg") {
            return "JPEG"
        }
        if loweredType.contains("tiff") {
            return "TIFF"
        }
        if let pathExtension = filename.flatMap({ URL(fileURLWithPath: $0).pathExtension.nilIfEmpty }) {
            return pathExtension.uppercased()
        }
        return "IMAGE"
    }

    private static func defaultImageFilename(for typeIdentifier: String) -> String {
        switch imageTypeLabel(for: typeIdentifier, filename: nil) {
        case "PNG":
            return "clipboard-image.png"
        case "JPEG":
            return "clipboard-image.jpeg"
        case "TIFF":
            return "clipboard-image.tiff"
        default:
            return "clipboard-image"
        }
    }

    private static func formattedBytes(_ byteCount: Int) -> String {
        if byteCount == 1 {
            return "1 byte"
        }
        if byteCount < 1_024 {
            return "\(byteCount) bytes"
        }

        let units = ["KB", "MB", "GB"]
        var value = Double(byteCount)
        var unitIndex = -1
        repeat {
            value /= 1_024
            unitIndex += 1
        } while value >= 1_024 && unitIndex < units.count - 1

        if value.rounded() == value {
            return "\(Int(value)) \(units[unitIndex])"
        }
        return String(format: "%.1f %@", value, units[unitIndex])
    }

    private static func contentHash(for data: Data) -> String {
        SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
