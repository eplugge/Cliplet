import AppKit

// Usage: swift Scripts/render-app-icon.swift <output.png>
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"

let side: CGFloat = 1024
let image = NSImage(size: NSSize(width: side, height: side))
image.lockFocus()

let rect = NSRect(x: 0, y: 0, width: side, height: side)
let corner = side * 0.2237 // macOS rounded-rect ratio
let bg = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
bg.addClip()
let gradient = NSGradient(colors: [
    NSColor(srgbRed: 0.22, green: 0.56, blue: 1.0, alpha: 1),
    NSColor(srgbRed: 0.04, green: 0.34, blue: 0.92, alpha: 1)
])!
gradient.draw(in: rect, angle: -90)

// White paperclip from the SF Symbol, tinted and centered.
let config = NSImage.SymbolConfiguration(pointSize: side * 0.52, weight: .regular)
if let base = NSImage(systemSymbolName: "paperclip", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let glyph = NSImage(size: base.size)
    glyph.lockFocus()
    base.draw(at: .zero, from: NSRect(origin: .zero, size: base.size), operation: .sourceOver, fraction: 1)
    NSColor.white.set()
    NSRect(origin: .zero, size: base.size).fill(using: .sourceAtop)
    glyph.unlockFocus()

    let gs = glyph.size
    let drawRect = NSRect(x: (side - gs.width) / 2, y: (side - gs.height) / 2, width: gs.width, height: gs.height)
    glyph.draw(in: drawRect)
}

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write(Data("failed to render icon\n".utf8))
    exit(1)
}
try! png.write(to: URL(fileURLWithPath: outputPath))
print("wrote \(outputPath)")
