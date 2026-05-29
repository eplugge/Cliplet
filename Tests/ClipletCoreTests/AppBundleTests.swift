import XCTest
@testable import ClipletCore

final class AppBundleTests: XCTestCase {
    func testResolvesBundleIDForSystemApplication() {
        // Finder is present on every macOS install.
        let url = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
        let bundleID = AppBundle.bundleID(forApplicationAt: url)
        XCTAssertEqual(bundleID, "com.apple.finder")
    }

    func testReturnsNilForNonApplicationURL() {
        let url = URL(fileURLWithPath: "/usr/bin/true")
        XCTAssertNil(AppBundle.bundleID(forApplicationAt: url))
    }
}
