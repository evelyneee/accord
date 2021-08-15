//
//  GifManager.swift
//  NitrolessiOS
//
//  Created by Amy While on 16/02/2021.
//
import Cocoa

final class Gif: NSImage {
    var calculatedDuration: Double?
    var animatedImages: [NSImage]?

    convenience init?(data: Data) {
        self.init()
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
        self.animatedImages = images
        self.calculatedDuration = calculatedDuration
    }
    
    public class func downsample(image: NSImage, to pointSize: CGSize) -> NSImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let data = image.tiffRepresentation as CFData?,
              let imageSource = CGImageSourceCreateWithData(data, imageSourceOptions) else { return nil }
        let maxDimentionInPixels = max(pointSize.width, pointSize.height) * (NSScreen.main?.backingScaleFactor ?? 0)
        let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxDimentionInPixels] as CFDictionary
        guard let downScaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampledOptions) else { return nil }
        return NSImage(cgImage: downScaledImage, size: CGSize(width: 40, height: 40))
    }
}
