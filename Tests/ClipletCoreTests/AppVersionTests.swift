import XCTest
@testable import ClipletCore

final class AppVersionTests: XCTestCase {
    func testShortVersionWithBuild() {
        XCTAssertEqual(AppVersion.displayString(shortVersion: "0.1.0", build: "1"), "0.1.0 (1)")
    }

    func testShortVersionWithoutBuild() {
        XCTAssertEqual(AppVersion.displayString(shortVersion: "0.1.0", build: nil), "0.1.0")
    }

    func testShortVersionWithEmptyBuild() {
        XCTAssertEqual(AppVersion.displayString(shortVersion: "0.1.0", build: ""), "0.1.0")
    }

    func testMissingShortVersionFallsBackToDev() {
        XCTAssertEqual(AppVersion.displayString(shortVersion: nil, build: "1"), "dev")
    }

    func testEmptyShortVersionFallsBackToDev() {
        XCTAssertEqual(AppVersion.displayString(shortVersion: "", build: "1"), "dev")
    }
}
