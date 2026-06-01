import XCTest
@testable import ClipletCore

final class ClipDisplayTests: XCTestCase {
    func testNoneShowsPlainValue() {
        let p = ClipDisplay.parts(preview: "hello world", alias: nil, maskMode: .none)
        XCTAssertEqual(p.value, "hello world")
        XCTAssertFalse(p.blur)
        XCTAssertNil(p.alias)
    }

    func testBlurredKeepsValueAndFlagsBlur() {
        let p = ClipDisplay.parts(preview: "secret", alias: nil, maskMode: .blurred)
        XCTAssertEqual(p.value, "secret")
        XCTAssertTrue(p.blur)
    }

    func testHiddenUsesPlaceholderAndNoBlur() {
        let p = ClipDisplay.parts(preview: "secret", alias: nil, maskMode: .hidden)
        XCTAssertEqual(p.value, ClipDisplay.hiddenPlaceholder)
        XCTAssertFalse(p.blur)
    }

    func testAliasIsTrimmedAndPassedThrough() {
        let p = ClipDisplay.parts(preview: "secret", alias: "  My work password  ", maskMode: .hidden)
        XCTAssertEqual(p.alias, "My work password")
    }

    func testWhitespaceOnlyAliasBecomesNil() {
        let p = ClipDisplay.parts(preview: "secret", alias: "   ", maskMode: .none)
        XCTAssertNil(p.alias)
    }

    func testEmptyAliasBecomesNil() {
        let p = ClipDisplay.parts(preview: "secret", alias: "", maskMode: .blurred)
        XCTAssertNil(p.alias)
    }
}
