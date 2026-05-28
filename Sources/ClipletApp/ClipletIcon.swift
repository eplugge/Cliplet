import AppKit

enum ClipletIcon {
    static func menuBarImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 22, height: 22))
        image.lockFocus()

        let path = NSBezierPath()
        path.lineWidth = 1.8
        path.lineCapStyle = .round
        path.lineJoinStyle = .round

        path.move(to: NSPoint(x: 6.4, y: 9.0))
        path.curve(
            to: NSPoint(x: 13.6, y: 16.2),
            controlPoint1: NSPoint(x: 8.6, y: 11.4),
            controlPoint2: NSPoint(x: 11.0, y: 14.0)
        )
        path.curve(
            to: NSPoint(x: 18.6, y: 12.1),
            controlPoint1: NSPoint(x: 15.5, y: 18.1),
            controlPoint2: NSPoint(x: 20.2, y: 15.0)
        )
        path.curve(
            to: NSPoint(x: 8.4, y: 4.0),
            controlPoint1: NSPoint(x: 16.4, y: 8.2),
            controlPoint2: NSPoint(x: 12.1, y: 3.5)
        )

        let inner = NSBezierPath()
        inner.lineWidth = 1.8
        inner.lineCapStyle = .round
        inner.lineJoinStyle = .round
        inner.move(to: NSPoint(x: 8.6, y: 10.7))
        inner.line(to: NSPoint(x: 15.5, y: 17.2))

        NSColor.labelColor.setStroke()
        path.stroke()
        inner.stroke()

        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = "Cliplet"
        return image
    }
}
