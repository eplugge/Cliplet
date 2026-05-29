import CoreGraphics

public enum PopoverLayout {
    /// How many clip rows the popover should show in its scroll viewport before
    /// scrolling kicks in.
    ///
    /// Bounded by three things, smallest wins:
    /// - the number of clips that actually exist (so an empty area never shows),
    /// - the user's "visible rows" preference, and
    /// - how many rows fit in the available screen height (so it never overflows).
    ///
    /// Returns 0 when there are no clips, and at least 1 row whenever there is at
    /// least one clip (even on a pathologically short screen).
    public static func visibleRowCount(
        clipCount: Int,
        visibleRowLimit: Int,
        rowHeight: CGFloat,
        availableHeight: CGFloat
    ) -> Int {
        guard rowHeight > 0, clipCount > 0 else { return 0 }
        let fitsOnScreen = max(1, Int(availableHeight / rowHeight))
        return min(clipCount, visibleRowLimit, fitsOnScreen)
    }
}
