//
//  NSColor+Hex.swift
//  NSColor+Hex
//
//  Created by evelyn on 2021-10-17.
//

import AppKit
import Foundation

extension String {
    func conformsTo(_ pattern: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }
}

public extension NSColor {
    static func color(from int: Int) -> NSColor? {
        let hex = String(format: "%06X", int)
        let r, g, b: CGFloat
        if hex.count == 6 {
            let scanner = Scanner(string: hex)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                r = CGFloat((hexNumber & 0xFF0000) >> 16) / 255
                g = CGFloat((hexNumber & 0xFF00) >> 8) / 255
                b = CGFloat(hexNumber & 0xFF) / 255
                if pastelColors {
                    return NSColor(calibratedRed: r + 0.1, green: g + 0.1, blue: b + 0.1, alpha: 1)
                } else {
                    return NSColor(calibratedRed: r, green: g, blue: b, alpha: 1)
                }
            }
        }
        return nil
    }
}

// https://gist.github.com/musa11971/62abcfda9ce3bb17f54301fdc84d8323
extension NSImage {
    /// Returns the average color that is present in the image.
    var averageColor: NSColor? {
        // Image is not valid, so we cannot get the average color
        if !isValid {
            return nil
        }

        // Create a CGImage from the NSImage
        var imageRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        let cgImageRef = cgImage(forProposedRect: &imageRect, context: nil, hints: nil)

        // Create vector and apply filter
        let inputImage = CIImage(cgImage: cgImageRef!)
        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )

        let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [kCIInputImageKey: inputImage, kCIInputExtentKey: extentVector]
        )
        let outputImage = filter!.outputImage!

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: kCFNull!])
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )

        return NSColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
    }
}
