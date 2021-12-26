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
        let delayTime = ((metadata as NSDictionary)["{GIF}"] as? NSMutableDictionary)?["DelayTime"] as? Double else { return nil }
        var images = [NSImage]()
        let imageCount = CGImageSourceGetCount(source)
        for i in 0 ..< imageCount {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                let tmpImage = NSImage(cgImage: image, size: CGSize(width: 40, height: 40))
                images.append(tmpImage)
            }
        }
        let calculatedDuration = Double(imageCount) * delayTime
        self.init()
        self.animatedImages = images
        self.calculatedDuration = calculatedDuration
    }
}
