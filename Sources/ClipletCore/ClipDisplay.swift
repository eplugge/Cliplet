import Foundation

public enum ClipDisplay {
    /// Shown in place of a hidden clip's value.
    public static let hiddenPlaceholder = "••••••"

    public struct Parts: Equatable {
        public var value: String
        public var blur: Bool
        public var alias: String?

        public init(value: String, blur: Bool, alias: String?) {
            self.value = value
            self.blur = blur
            self.alias = alias
        }
    }

    /// How a masked (not-revealed) clip should render. `none` shows the value sharp, `blurred`
    /// shows it with `blur` set (the view blurs the middle), and `hidden` shows a placeholder.
    /// The alias is trimmed; an empty/whitespace-only alias becomes nil.
    public static func parts(preview: String, alias: String?, maskMode: ClipMaskMode) -> Parts {
        let trimmed = alias?.trimmingCharacters(in: .whitespacesAndNewlines)
        let aliasOut = (trimmed?.isEmpty == false) ? trimmed : nil
        switch maskMode {
        case .none:
            return Parts(value: preview, blur: false, alias: aliasOut)
        case .blurred:
            return Parts(value: preview, blur: true, alias: aliasOut)
        case .hidden:
            return Parts(value: hiddenPlaceholder, blur: false, alias: aliasOut)
        }
    }
}
