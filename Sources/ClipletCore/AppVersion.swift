import Foundation

public enum AppVersion {
    /// Formats a user-facing version string, e.g. "0.1.0 (1)".
    /// Falls back to "dev" when no short version is available (e.g. running via `swift run`,
    /// where there is no Info.plist `CFBundleShortVersionString`).
    public static func displayString(shortVersion: String?, build: String?) -> String {
        guard let short = shortVersion, !short.isEmpty else { return "dev" }
        if let build, !build.isEmpty { return "\(short) (\(build))" }
        return short
    }
}
