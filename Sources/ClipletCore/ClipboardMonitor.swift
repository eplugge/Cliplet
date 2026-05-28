import Foundation

public final class ClipboardMonitor {
    public struct SourceApp: Equatable, Sendable {
        public var bundleID: String?
        public var name: String?

        public init(bundleID: String?, name: String?) {
            self.bundleID = bundleID
            self.name = name
        }
    }

    public typealias SourceAppProvider = () -> SourceApp?
    public typealias ReadItem = () -> ClipClassifier.RawItem?
    public typealias CaptureHandler = (Clip) -> Void

    public var settings: ClipSettings
    public var excludedApps: ExcludedApps

    private let sourceAppProvider: SourceAppProvider
    private let readItem: ReadItem
    private let onCapture: CaptureHandler
    private var lastSeenChangeCount: Int?
    private var suppressedChangeCounts: Set<Int>

    public init(
        settings: ClipSettings = .defaults,
        excludedApps: ExcludedApps = ExcludedApps(),
        sourceAppProvider: @escaping SourceAppProvider,
        readItem: @escaping ReadItem,
        onCapture: @escaping CaptureHandler
    ) {
        self.settings = settings
        self.excludedApps = excludedApps
        self.sourceAppProvider = sourceAppProvider
        self.readItem = readItem
        self.onCapture = onCapture
        self.lastSeenChangeCount = nil
        self.suppressedChangeCounts = []
    }

    public func suppressNextChangeCount(_ changeCount: Int) {
        suppressedChangeCounts.insert(changeCount)
    }

    public func poll(changeCount: Int, now: Date) {
        guard changeCount != lastSeenChangeCount else {
            return
        }

        lastSeenChangeCount = changeCount

        guard suppressedChangeCounts.remove(changeCount) == nil else {
            return
        }

        let sourceApp = sourceAppProvider()
        guard !excludedApps.isExcluded(bundleID: sourceApp?.bundleID) else {
            return
        }

        guard var item = readItem() else {
            return
        }

        item.now = now
        if item.sourceAppBundleID == nil {
            item.sourceAppBundleID = sourceApp?.bundleID
        }
        if item.sourceAppName == nil {
            item.sourceAppName = sourceApp?.name
        }

        guard !excludedApps.isExcluded(bundleID: item.sourceAppBundleID) else {
            return
        }

        onCapture(ClipClassifier.classify(item, settings: settings))
    }
}
