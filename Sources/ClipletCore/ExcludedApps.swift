import Foundation

public struct ExcludedApps: Codable, Equatable, Sendable {
    private var excludedBundleIDs: Set<String>

    public var bundleIDs: [String] {
        excludedBundleIDs.sorted()
    }

    public init(bundleIDs: [String] = []) {
        self.excludedBundleIDs = Set(bundleIDs.compactMap(Self.normalizedBundleID))
    }

    public func isExcluded(bundleID: String?) -> Bool {
        guard let normalized = Self.normalizedBundleID(bundleID) else {
            return false
        }

        return excludedBundleIDs.contains(normalized)
    }

    public mutating func add(bundleID: String) {
        guard let normalized = Self.normalizedBundleID(bundleID) else {
            return
        }

        excludedBundleIDs.insert(normalized)
    }

    public mutating func remove(bundleID: String) {
        guard let normalized = Self.normalizedBundleID(bundleID) else {
            return
        }

        excludedBundleIDs.remove(normalized)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bundleIDs = try container.decode([String].self, forKey: .bundleIDs)
        self.init(bundleIDs: bundleIDs)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bundleIDs, forKey: .bundleIDs)
    }

    private static func normalizedBundleID(_ bundleID: String?) -> String? {
        guard let bundleID else {
            return nil
        }

        let normalized = bundleID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return normalized.isEmpty ? nil : normalized
    }

    private enum CodingKeys: String, CodingKey {
        case bundleIDs
    }
}
