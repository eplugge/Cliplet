import Foundation

public enum AppBundle {
    /// Resolves the bundle identifier for an application bundle on disk.
    /// Returns nil when the URL is not a readable bundle with an identifier.
    public static func bundleID(forApplicationAt url: URL) -> String? {
        guard let bundle = Bundle(url: url),
              let identifier = bundle.bundleIdentifier,
              !identifier.isEmpty else {
            return nil
        }
        return identifier
    }
}
