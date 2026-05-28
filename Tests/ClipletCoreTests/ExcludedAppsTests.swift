import XCTest
@testable import ClipletCore

final class ExcludedAppsTests: XCTestCase {
    func testExcludesBundleIDsCaseInsensitively() {
        let excludedApps = ExcludedApps(bundleIDs: [
            " com.apple.TextEdit ",
            "COM.OPENAI.CHATGPT"
        ])

        XCTAssertTrue(excludedApps.isExcluded(bundleID: "com.apple.textedit"))
        XCTAssertTrue(excludedApps.isExcluded(bundleID: "COM.APPLE.TEXTEDIT"))
        XCTAssertTrue(excludedApps.isExcluded(bundleID: " com.openai.chatgpt "))
        XCTAssertEqual(excludedApps.bundleIDs, ["com.apple.textedit", "com.openai.chatgpt"])
    }

    func testEmptyOrMissingBundleIDIsNotExcluded() {
        let excludedApps = ExcludedApps(bundleIDs: ["com.apple.textedit"])

        XCTAssertFalse(excludedApps.isExcluded(bundleID: nil))
        XCTAssertFalse(excludedApps.isExcluded(bundleID: ""))
        XCTAssertFalse(excludedApps.isExcluded(bundleID: "   \n"))
    }

    func testAddRemoveAndSortedNormalizedOutput() {
        var excludedApps = ExcludedApps(bundleIDs: [
            " COM.ZETA.App ",
            "",
            "com.alpha.App",
            "  "
        ])

        excludedApps.add(bundleID: "COM.BETA.App")
        excludedApps.add(bundleID: " \n ")
        excludedApps.remove(bundleID: " com.zeta.app ")

        XCTAssertEqual(excludedApps.bundleIDs, ["com.alpha.app", "com.beta.app"])
        XCTAssertTrue(excludedApps.isExcluded(bundleID: "COM.BETA.APP"))
        XCTAssertFalse(excludedApps.isExcluded(bundleID: "com.zeta.app"))
    }

    func testCodableRoundTripPreservesNormalizedBundleIDs() throws {
        let excludedApps = ExcludedApps(bundleIDs: [
            "COM.ZETA.App",
            "com.alpha.App"
        ])

        let data = try JSONEncoder().encode(excludedApps)
        let decoded = try JSONDecoder().decode(ExcludedApps.self, from: data)

        XCTAssertEqual(decoded, excludedApps)
        XCTAssertEqual(decoded.bundleIDs, ["com.alpha.app", "com.zeta.app"])
    }
}
