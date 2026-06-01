import XCTest
@testable import ClipletCore

final class BlurSegmentsTests: XCTestCase {
    func testEqualLeadingAndTrailingEdges() {
        let r = BlurSegments.split("YourSecretPassword2026!", leading: 2, trailing: 2)
        XCTAssertEqual(r.prefix, "Yo")
        XCTAssertEqual(r.suffix, "6!")
        XCTAssertEqual(r.middle, "urSecretPassword202")
        XCTAssertEqual(r.prefix + r.middle + r.suffix, "YourSecretPassword2026!")
    }

    func testAsymmetricLeadingTrailing() {
        let r = BlurSegments.split("abcdefghij", leading: 1, trailing: 3)
        XCTAssertEqual(r.prefix, "a")
        XCTAssertEqual(r.middle, "bcdefg")
        XCTAssertEqual(r.suffix, "hij")
    }

    func testZeroLeadingKeepsOnlyTrailingSharp() {
        let r = BlurSegments.split("abcdefghij", leading: 0, trailing: 2)
        XCTAssertEqual(r.prefix, "")
        XCTAssertEqual(r.middle, "abcdefgh")
        XCTAssertEqual(r.suffix, "ij")
    }

    func testZeroBothBlursWholeValue() {
        let r = BlurSegments.split("abcdefghij", leading: 0, trailing: 0)
        XCTAssertEqual(r.prefix, "")
        XCTAssertEqual(r.middle, "abcdefghij")
        XCTAssertEqual(r.suffix, "")
    }

    func testRevealingWholeValueStillBlursEverything() {
        // leading + trailing covers the whole string -> blur it all (never fully readable).
        let r = BlurSegments.split("abcd", leading: 2, trailing: 2)
        XCTAssertEqual(r.prefix, "")
        XCTAssertEqual(r.middle, "abcd")
        XCTAssertEqual(r.suffix, "")
    }

    func testMultilineCollapsesToSingleLine() {
        let r = BlurSegments.split("line1\nline2", leading: 2, trailing: 2)
        XCTAssertFalse(r.middle.contains("\n"))
        XCTAssertEqual(r.prefix + r.middle + r.suffix, "line1 line2")
    }

    func testEmptyString() {
        let r = BlurSegments.split("", leading: 2, trailing: 2)
        XCTAssertEqual(r.prefix, "")
        XCTAssertEqual(r.middle, "")
        XCTAssertEqual(r.suffix, "")
    }
}
