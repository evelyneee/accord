//
//  GifManager.swift
//  NitrolessiOS
//
//  Created by Amy While on 16/02/2021.
//

import AppKit

final class Gif: NSImage {
    var calculatedDuration: Double?
    var animatedImages: [NSImage]?

    convenience init?(data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil),
              let delayTime = ((metadata as NSDictionary)["{GIF}"] as? NSDictionary)?["DelayTime"] as? Double else { return nil }
        var images: [NSImage] = .init()
        let imageCount = CGImageSourceGetCount(source)
        let width = (metadata as NSDictionary)["PixelWidth"] as? Double
        let height = (metadata as NSDictionary)["PixelHeight"] as? Double
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let tmpImage = NSImage(cgImage: image, size: CGSize(width: width ?? 40, height: height ?? 40))
                images.append(tmpImage)
            }
        }
        let calculatedDuration = Double(images.count) * delayTime
        self.init()
        animatedImages = images
        self.calculatedDuration = calculatedDuration
    }
}
