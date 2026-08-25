import AppKit
import Foundation

guard CommandLine.arguments.count == 2 else {
    fputs("usage: ImageAlphaCheck image.png\n", stderr)
    exit(2)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard
    let image = NSImage(contentsOf: url),
    let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
else {
    fputs("cannot decode image\n", stderr)
    exit(2)
}

let width = cgImage.width
let height = cgImage.height
var pixels = [UInt8](repeating: 0, count: width * height * 4)
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: &pixels,
    width: width,
    height: height,
    bitsPerComponent: 8,
    bytesPerRow: width * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("cannot create bitmap context\n", stderr)
    exit(2)
}

context.clear(CGRect(x: 0, y: 0, width: width, height: height))
context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

var transparent = 0
var translucent = 0
var solid = 0
var minimum = UInt8.max
var maximum = UInt8.min

for index in stride(from: 3, to: pixels.count, by: 4) {
    let alpha = pixels[index]
    minimum = min(minimum, alpha)
    maximum = max(maximum, alpha)
    switch alpha {
    case 0: transparent += 1
    case 250...255: solid += 1
    default: translucent += 1
    }
}

print("size=\(width)x\(height) alpha=\(minimum)...\(maximum) transparent=\(transparent) translucent=\(translucent) solid=\(solid)")
guard transparent > 0, solid > 0 else {
    fputs("image does not contain both transparent and solid subject pixels\n", stderr)
    exit(1)
}
