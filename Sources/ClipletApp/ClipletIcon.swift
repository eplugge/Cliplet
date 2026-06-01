import AppKit

enum ClipletIcon {
    static func menuBarImage(paused: Bool = false) -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        guard let paperclip = NSImage(
            systemSymbolName: "paperclip",
            accessibilityDescription: "Cliplet"
        )?.withSymbolConfiguration(configuration) else {
            return fallbackImage()
        }

        guard paused else {
            paperclip.isTemplate = true
            return paperclip
        }

        // Paused: pause bars centered over the full-strength paperclip. A small clear
        // "knockout" halo is erased around each bar so the bars stay distinct from the
        // paperclip lines (a template image is single-tone, so overlapping shapes would
        // otherwise merge).
        let size = paperclip.size
        let image = NSImage(size: size)
        image.lockFocus()
        paperclip.draw(
            at: .zero,
            from: NSRect(origin: .zero, size: size),
            operation: .sourceOver,
            fraction: 1.0
        )
        let unit = size.height
        let barsRect = NSRect(
            x: size.width / 2 - unit * 0.22,
            y: size.height / 2 - unit * 0.22,
            width: unit * 0.44,
            height: unit * 0.44
        )
        let barWidth = barsRect.width * 0.32
        let gap = barsRect.width * 0.20
        let startX = barsRect.midX - (barWidth * 2 + gap) / 2
        let bars = (0..<2).map { i in
            NSRect(
                x: startX + CGFloat(i) * (barWidth + gap),
                y: barsRect.minY,
                width: barWidth,
                height: barsRect.height
            )
        }

        // Erase a slightly larger halo behind each bar for separation.
        NSGraphicsContext.current?.compositingOperation = .clear
        for bar in bars {
            let halo = bar.insetBy(dx: -1.4, dy: -1.4)
            NSBezierPath(roundedRect: halo, xRadius: halo.width * 0.4, yRadius: halo.width * 0.4).fill()
        }

        // Draw the solid bars.
        NSGraphicsContext.current?.compositingOperation = .sourceOver
        NSColor.black.setFill()
        for bar in bars {
            NSBezierPath(roundedRect: bar, xRadius: barWidth * 0.35, yRadius: barWidth * 0.35).fill()
        }

        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = "Cliplet (paused)"
        return image
    }

    private static func fallbackImage() -> NSImage {
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

        NSColor.labelColor.setStroke()
        path.stroke()

        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = "Cliplet"
        return image
    }
}
