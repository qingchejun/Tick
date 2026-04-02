import AppKit
import CoreGraphics

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))

    image.lockFocus()
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    // Background: rounded rect with gradient
    let bgRect = CGRect(x: 0, y: 0, width: s, height: s)
    let cornerRadius = s * 0.22
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

    // Gradient: warm teal to deep blue
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        CGColor(colorSpace: colorSpace, components: [0.18, 0.80, 0.75, 1.0])!,  // teal
        CGColor(colorSpace: colorSpace, components: [0.15, 0.45, 0.85, 1.0])!,  // blue
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 1.0])!

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])
    ctx.restoreGState()

    // Center and sizing
    let cx = s / 2
    let cy = s / 2
    let ringRadius = s * 0.32
    let ringWidth = s * 0.065

    // Ring background (subtle white)
    ctx.setStrokeColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.25])!)
    ctx.setLineWidth(ringWidth)
    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: ringRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.strokePath()

    // Ring progress arc (~75%, from top going clockwise)
    // In CoreGraphics, 0 is right, pi/2 is up. We want to start at top.
    let startAngle = CGFloat.pi / 2
    let endAngle = startAngle - CGFloat.pi * 2 * 0.75  // 75% progress

    ctx.setStrokeColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.95])!)
    ctx.setLineWidth(ringWidth)
    ctx.setLineCap(.round)
    ctx.addArc(center: CGPoint(x: cx, y: cy), radius: ringRadius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
    ctx.strokePath()

    // Time text in center
    let timeText = "4:32" as NSString
    let fontSize = s * 0.19
    let font = NSFont.monospacedDigitSystemFont(ofSize: fontSize, weight: .semibold)
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let textSize = timeText.size(withAttributes: attrs)
    let textRect = CGRect(
        x: cx - textSize.width / 2,
        y: cy - textSize.height / 2,
        width: textSize.width,
        height: textSize.height
    )
    timeText.draw(in: textRect, withAttributes: attrs)

    // Small tick mark at top of ring (decorative dot)
    let dotRadius = s * 0.025
    let dotY = cy + ringRadius
    ctx.setFillColor(CGColor(colorSpace: colorSpace, components: [1, 1, 1, 0.9])!)
    ctx.addArc(center: CGPoint(x: cx, y: dotY), radius: dotRadius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
    ctx.fillPath()

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

// Generate iconset
let iconsetPath = "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, px) in sizes {
    let image = generateIcon(size: px)
    let path = "\(iconsetPath)/\(name).png"
    savePNG(image, to: path, size: px)
    print("Generated \(name).png (\(px)x\(px))")
}

print("Done! Now run: iconutil -c icns AppIcon.iconset")
