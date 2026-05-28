import Foundation

public struct ClipStore: Sendable {
    private let rootDirectory: URL

    private var metadataURL: URL {
        rootDirectory.appendingPathComponent("clips.json", isDirectory: false)
    }

    private var payloadDirectory: URL {
        rootDirectory.appendingPathComponent("Payloads", isDirectory: true)
    }

    public init(rootDirectory: URL) {
        self.rootDirectory = rootDirectory
    }

    public func load() throws -> [Clip] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return []
        }

        let data = try Data(contentsOf: metadataURL)
        return try decoder.decode([Clip].self, from: data)
    }

    public func save(_ clips: [Clip]) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        let data = try encoder.encode(clips)
        try data.write(to: metadataURL, options: .atomic)
    }

    public func writePayload(_ data: Data, filename: String) throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: payloadDirectory, withIntermediateDirectories: true)
        try data.write(to: payloadURL(filename: filename), options: .atomic)
    }

    public func readPayload(filename: String) throws -> Data {
        try Data(contentsOf: payloadURL(filename: filename))
    }

    public func prunePayloads(referencedFilenames: Set<String>) throws {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: payloadDirectory.path) else {
            return
        }

        let payloads = try fileManager.contentsOfDirectory(
            at: payloadDirectory,
            includingPropertiesForKeys: [.isRegularFileKey]
        )

        for payload in payloads {
            let resourceValues = try payload.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else { continue }
            guard !referencedFilenames.contains(payload.lastPathComponent) else { continue }

            try fileManager.removeItem(at: payload)
        }
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func payloadURL(filename: String) throws -> URL {
        guard !filename.isEmpty,
              filename == URL(fileURLWithPath: filename).lastPathComponent else {
            throw CocoaError(.fileWriteInvalidFileName)
        }

        return payloadDirectory.appendingPathComponent(filename, isDirectory: false)
    }
}
