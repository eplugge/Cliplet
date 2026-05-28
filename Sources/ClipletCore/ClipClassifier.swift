import Foundation

public enum ClipClassifier {
    public struct RawRepresentation: Equatable, Sendable {
        public var typeIdentifier: String
        public var data: Data
        public var filename: String?

        public init(typeIdentifier: String, data: Data, filename: String?) {
            self.typeIdentifier = typeIdentifier
            self.data = data
            self.filename = filename
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
        if let textRepresentation = item.representations.first(where: isTextRepresentation),
           let text = String(data: textRepresentation.data, encoding: .utf8) {
            return makeClip(
                item: item,
                kind: .text,
                preview: singleLinePreview(for: text),
                contentType: "public.utf8-plain-text",
                filename: textRepresentation.filename,
                byteSize: textRepresentation.data.count,
                payload: .inlineText(text)
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
                payload = .storedPayload(filename: filename ?? defaultImageFilename(for: imageRepresentation.typeIdentifier))
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
        payload: ClipPayload
    ) -> Clip {
        Clip(
            kind: kind,
            preview: preview,
            contentType: contentType,
            filename: filename,
            dimensions: nil,
            byteSize: byteSize,
            sourceAppBundleID: item.sourceAppBundleID,
            sourceAppName: item.sourceAppName,
            createdAt: item.now,
            lastUsedAt: item.now,
            isPinned: false,
            payload: payload
        )
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
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
