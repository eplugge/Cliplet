import AppKit

enum ClipletKeyCommand: Equatable {
    case moveUp
    case moveDown
    case pageUp
    case pageDown
    case home
    case end
    case enter
    case preview
    case close
    case delete
    case numbered(Int)

    static func parse(_ event: NSEvent) -> ClipletKeyCommand? {
        if event.modifierFlags.contains(.command),
           let characters = event.charactersIgnoringModifiers,
           let number = Int(characters),
           (1...9).contains(number) {
            return .numbered(number)
        }

        switch event.keyCode {
        case 126: return .moveUp
        case 125: return .moveDown
        case 116: return .pageUp
        case 121: return .pageDown
        case 115: return .home
        case 119: return .end
        case 36, 76: return .enter
        case 49: return .preview
        case 53: return .close
        case 117: return .delete // forward-delete removes a clip; backspace (51) edits search
        default: return nil
        }
    }
}
