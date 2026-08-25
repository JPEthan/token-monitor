import AppKit
import Foundation

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: AppIconGenerator <source.png> <output.icns> <preview.png>\n", stderr)
    exit(64)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let iconURL = URL(fileURLWithPath: CommandLine.arguments[2])
let previewURL = URL(fileURLWithPath: CommandLine.arguments[3])
guard let source = NSImage(contentsOf: sourceURL) else {
    fputs("Unable to read source image.\n", stderr)
    exit(66)
}

func renderedPNG(pixelSize: Int) throws -> Data {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw CocoaError(.fileWriteUnknown)
    }

    bitmap.size = NSSize(width: pixelSize, height: pixelSize)
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw CocoaError(.fileWriteUnknown)
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    context.cgContext.clear(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
    context.imageInterpolation = .high
    context.shouldAntialias = true

    let inset = max(CGFloat(pixelSize) * 0.012, 1)
    let availableWidth = CGFloat(pixelSize) - inset * 2
    let availableHeight = CGFloat(pixelSize) - inset * 2
    let scale = min(availableWidth / source.size.width, availableHeight / source.size.height)
    let targetSize = NSSize(width: source.size.width * scale, height: source.size.height * scale)
    let targetRect = NSRect(
        x: (CGFloat(pixelSize) - targetSize.width) / 2,
        y: (CGFloat(pixelSize) - targetSize.height) / 2,
        width: targetSize.width,
        height: targetSize.height
    )

    source.draw(
        in: targetRect,
        from: NSRect(origin: .zero, size: source.size),
        operation: .sourceOver,
        fraction: 1,
        respectFlipped: true,
        hints: [.interpolation: NSImageInterpolation.high]
    )
    NSGraphicsContext.restoreGraphicsState()

    guard let data = bitmap.representation(using: .png, properties: [.compressionFactor: 1]) else {
        throw CocoaError(.fileWriteUnknown)
    }
    return data
}

extension Data {
    mutating func appendBigEndian(_ value: UInt32) {
        var bigEndian = value.bigEndian
        Swift.withUnsafeBytes(of: &bigEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}

let representations: [(type: String, size: Int)] = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024)
]

do {
    var chunks = Data()
    var preview = Data()

    for representation in representations {
        let png = try renderedPNG(pixelSize: representation.size)
        guard let typeData = representation.type.data(using: .utf8), typeData.count == 4 else {
            throw CocoaError(.fileWriteUnknown)
        }
        chunks.append(typeData)
        chunks.appendBigEndian(UInt32(png.count + 8))
        chunks.append(png)
        if representation.size == 1024 {
            preview = png
        }
    }

    var icon = Data("icns".utf8)
    icon.appendBigEndian(UInt32(chunks.count + 8))
    icon.append(chunks)
    try icon.write(to: iconURL, options: .atomic)
    try preview.write(to: previewURL, options: .atomic)
} catch {
    fputs("Unable to generate app icon: \(error.localizedDescription)\n", stderr)
    exit(70)
}
