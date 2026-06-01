import AppKit

enum ClipletIcon {
    enum State {
        case normal
        case paused
        case session
    }

    static func menuBarImage(state: State = .normal) -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        guard let paperclip = NSImage(
            systemSymbolName: "paperclip",
            accessibilityDescription: "Cliplet"
        )?.withSymbolConfiguration(configuration) else {
            return fallbackImage()
        }

        switch state {
        case .normal:
            paperclip.isTemplate = true
            return paperclip
        case .paused:
            return pausedImage(paperclip)
        case .session:
            return sessionImage(paperclip)
        }
    }

    /// Paused: pause bars centered over the full-strength paperclip, with a clear knockout halo
    /// so the bars stay distinct from the paperclip lines (template = single-tone).
    private static func pausedImage(_ paperclip: NSImage) -> NSImage {
        let size = paperclip.size
        let image = NSImage(size: size)
        image.lockFocus()
        paperclip.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .sourceOver, fraction: 1.0)
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
            NSRect(x: startX + CGFloat(i) * (barWidth + gap), y: barsRect.minY, width: barWidth, height: barsRect.height)
        }
        NSGraphicsContext.current?.compositingOperation = .clear
        for bar in bars {
            let halo = bar.insetBy(dx: -1.4, dy: -1.4)
            NSBezierPath(roundedRect: halo, xRadius: halo.width * 0.4, yRadius: halo.width * 0.4).fill()
        }
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

    /// Temporary session: a dented fedora + round shades sitting on top of the paperclip
    /// ("spy"). The canvas is taller than the clip to give the hat headroom.
    private static func sessionImage(_ paperclip: NSImage) -> NSImage {
        let clipSize = paperclip.size
        let canvas = NSSize(width: clipSize.width, height: clipSize.height * 1.45)
        let image = NSImage(size: canvas)
        image.lockFocus()
        let clipRect = NSRect(x: 0, y: 0, width: clipSize.width, height: clipSize.height)
        paperclip.draw(in: clipRect, from: NSRect(origin: .zero, size: clipSize), operation: .sourceOver, fraction: 1.0)
        drawSpy(clip: clipRect)
        image.unlockFocus()
        image.isTemplate = true
        image.accessibilityDescription = "Cliplet (temporary session)"
        return image
    }

    private static func drawSpy(clip r: NSRect) {
        let csW = r.width, csH = r.height, cx = r.midX
        let brimY = r.maxY - csH * 0.02

        // clear a thin gap under the hat so it reads against the clip's top
        NSGraphicsContext.current?.compositingOperation = .clear
        NSBezierPath(rect: NSRect(x: r.minX, y: brimY - csH * 0.10, width: r.width, height: csH * 0.05)).fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver

        // fedora: flat brim + tapered crown, with band + dent knockouts
        NSColor.black.setFill()
        let w = csW * 0.66, brimH = w * 0.13
        NSBezierPath(roundedRect: NSRect(x: cx - w / 2, y: brimY - brimH / 2, width: w, height: brimH), xRadius: brimH / 2, yRadius: brimH / 2).fill()
        let cb = w * 0.50, ct = w * 0.40, ch = w * 0.40, y0 = brimY + brimH * 0.2
        let crown = NSBezierPath()
        crown.move(to: NSPoint(x: cx - cb / 2, y: y0))
        crown.line(to: NSPoint(x: cx - ct / 2, y: y0 + ch))
        crown.line(to: NSPoint(x: cx + ct / 2, y: y0 + ch))
        crown.line(to: NSPoint(x: cx + cb / 2, y: y0))
        crown.close()
        crown.fill()
        NSGraphicsContext.current?.compositingOperation = .clear
        NSBezierPath(rect: NSRect(x: cx - cb / 2, y: y0 + ch * 0.10, width: cb, height: ch * 0.15)).fill()  // band
        NSBezierPath(ovalIn: NSRect(x: cx - ct * 0.20, y: y0 + ch * 0.72, width: ct * 0.40, height: ch * 0.5)).fill()  // dent
        NSGraphicsContext.current?.compositingOperation = .sourceOver

        // round shades under the brim
        let lensW = csW * 0.22, lensH = csH * 0.12, gap = lensW * 0.28, sy = r.maxY - csH * 0.155
        NSGraphicsContext.current?.compositingOperation = .clear
        NSBezierPath(roundedRect: NSRect(x: cx - (lensW + gap / 2) - 2, y: sy - lensH / 2 - 2, width: lensW * 2 + gap + 4, height: lensH + 4), xRadius: lensH, yRadius: lensH).fill()
        NSGraphicsContext.current?.compositingOperation = .sourceOver
        NSColor.black.setFill()
        for s in [-1.0, 1.0] {
            let x = cx + CGFloat(s) * (gap / 2 + lensW / 2) - lensW / 2
            NSBezierPath(roundedRect: NSRect(x: x, y: sy - lensH / 2, width: lensW, height: lensH), xRadius: lensH * 0.5, yRadius: lensH * 0.5).fill()
        }
        NSBezierPath(rect: NSRect(x: cx - gap / 2, y: sy - lensH * 0.14, width: gap, height: lensH * 0.28)).fill()
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
