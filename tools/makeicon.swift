import CoreGraphics
import CoreText
import Foundation
import ImageIO

func drawIcon(size: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpaceCreateDeviceRGB(),
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    // 渐变背景
    let colors = [
        CGColor(red: 0.15, green: 0.45, blue: 0.95, alpha: 1),
        CGColor(red: 0.60, green: 0.28, blue: 0.92, alpha: 1)
    ] as CFArray
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(grad,
                           start: CGPoint(x: 0, y: CGFloat(size)),
                           end: CGPoint(x: CGFloat(size), y: 0),
                           options: [])
    // 音符
    let font = CTFontCreateWithName("Helvetica" as CFString, CGFloat(size) * 0.55, nil)
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: CGColor(red: 1, green: 1, blue: 1, alpha: 1)
    ]
    let str = CFAttributedStringCreate(nil, "♪" as CFString, attrs as CFDictionary)!
    let line = CTLineCreateWithAttributedString(str)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: (CGFloat(size) - bounds.width) / 2 - bounds.origin.x,
                               y: (CGFloat(size) - bounds.height) / 2 - bounds.origin.y)
    CTLineDraw(line, ctx)
    return ctx.makeImage()!
}

func savePNG(_ image: CGImage, to path: String) {
    let url = URL(fileURLWithPath: path) as CFURL
    let dest = CGImageDestinationCreateWithURL(url, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let entries: [(name: String, size: Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for e in entries {
    savePNG(drawIcon(size: e.size), to: outDir + "/" + e.name)
}
print("iconset written to \(outDir)")
