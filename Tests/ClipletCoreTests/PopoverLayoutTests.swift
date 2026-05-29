import XCTest
@testable import ClipletCore

final class PopoverLayoutTests: XCTestCase {
    func testShrinksToActualClipCountWhenFewClips() {
        // 3 clips, generous limit and screen — show exactly 3 rows (no empty space).
        let rows = PopoverLayout.visibleRowCount(
            clipCount: 3,
            visibleRowLimit: 25,
            rowHeight: 23,
            availableHeight: 1000
        )
        XCTAssertEqual(rows, 3)
    }

    func testCapsAtVisibleRowLimitWhenManyClips() {
        // 200 clips but the user wants at most 25 visible before scrolling.
        let rows = PopoverLayout.visibleRowCount(
            clipCount: 200,
            visibleRowLimit: 25,
            rowHeight: 23,
            availableHeight: 5000
        )
        XCTAssertEqual(rows, 25)
    }

    func testCapsAtRowsThatFitOnScreen() {
        // Limit and clip count are high, but only ~10 rows fit in 230pt of screen space.
        let rows = PopoverLayout.visibleRowCount(
            clipCount: 200,
            visibleRowLimit: 100,
            rowHeight: 23,
            availableHeight: 230
        )
        XCTAssertEqual(rows, 10)
    }

    func testReturnsZeroForNoClips() {
        let rows = PopoverLayout.visibleRowCount(
            clipCount: 0,
            visibleRowLimit: 25,
            rowHeight: 23,
            availableHeight: 1000
        )
        XCTAssertEqual(rows, 0)
    }

    func testAlwaysAllowsAtLeastOneRowWhenScreenIsTiny() {
        // Even a pathologically short available height keeps one row visible.
        let rows = PopoverLayout.visibleRowCount(
            clipCount: 5,
            visibleRowLimit: 25,
            rowHeight: 23,
            availableHeight: 5
        )
        XCTAssertEqual(rows, 1)
    }

    func testGuardsAgainstNonPositiveRowHeight() {
        let rows = PopoverLayout.visibleRowCount(
            clipCount: 5,
            visibleRowLimit: 25,
            rowHeight: 0,
            availableHeight: 1000
        )
        XCTAssertEqual(rows, 0)
    }
}
