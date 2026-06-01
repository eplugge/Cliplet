import Foundation

public enum BlurSegments {
    /// Splits a value into `(prefix, middle, suffix)` for partial blurring: `prefix` is the
    /// first `leading` characters and `suffix` is the last `trailing` characters, both kept
    /// sharp; `middle` is the portion to blur. The input is collapsed to a single line first.
    ///
    /// `leading`/`trailing` are clamped to be non-negative. When they reveal the whole value
    /// (i.e. `leading + trailing >= count`), the entire value is returned as `middle` so a
    /// blurred clip never ends up fully readable.
    public static func split(_ text: String, leading: Int, trailing: Int) -> (prefix: String, middle: String, suffix: String) {
        let line = singleLine(text)
        let chars = Array(line)
        let lead = max(0, leading)
        let trail = max(0, trailing)
        guard lead + trail < chars.count else {
            return ("", line, "")
        }
        let prefix = String(chars[0..<lead])
        let suffix = trail > 0 ? String(chars[(chars.count - trail)...]) : ""
        let middle = String(chars[lead..<(chars.count - trail)])
        return (prefix, middle, suffix)
    }

    private static func singleLine(_ text: String) -> String {
        text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}
