//
//  NSImage+Processing.swift
//  NSImage+Processing
//
//  Created by evelyn on 2021-10-17.
//

import Foundation
import AppKit

extension CGImage {
    var png: Data? {
        guard let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.png" as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}

extension NSImage {

    /// The height of the image.
    var height: CGFloat {
        return size.height
    }

    /// The width of the image.
    var width: CGFloat {
        return size.width
    }

    /// A PNG representation of the image.
    var PNGRepresentation: Data? {
        if let tiff = self.tiffRepresentation, let tiffData = NSBitmapImageRep(data: tiff) {
            return tiffData.representation(using: .png, properties: [:])
        }

        return nil
    }
    func resize(withSize targetSize: NSSize) -> NSImage? {
        let frame = NSRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
        guard let representation = self.bestRepresentation(for: frame, context: nil, hints: nil) else {
            return nil
        }
        let image = NSImage(size: targetSize, flipped: false, drawingHandler: { (_) -> Bool in
            return representation.draw(in: frame)
        })

        return image
    }

    /// Copy the image and resize it to the supplied size, while maintaining it's
    /// original aspect ratio.
    ///
    /// - Parameter size: The target size of the image.
    /// - Returns: The resized image.
    func downsample(withSize targetSize: NSSize) -> NSImage? {
        let newSize: NSSize
        let widthRatio  = targetSize.width / self.width
        let heightRatio = targetSize.height / self.height
        
        if targetSize.width >= self.width || targetSize.height >= self.height {
            print("too small, cancelling", self.width, self.height)
            return self
        }
        
        if widthRatio > heightRatio {
            newSize = NSSize(width: floor(self.width * widthRatio),
                             height: floor(self.height * widthRatio))
        } else {
            newSize = NSSize(width: floor(self.width * heightRatio),
                             height: floor(self.height * heightRatio))
        }
        return self.resize(withSize: newSize)
    }
    func downsampled() -> NSImage? {
        
        let ratio = self.width / 400
        
        let sizes = NSSize(width: self.width / ratio, height: self.height / ratio)
        
        if ratio <= 1 {
            return nil
        }
        
        return self.resize(withSize: sizes)
    }
    
    // Thanks Amy 🙂
    func downsample(to pointSize: CGSize? = nil, scale: CGFloat? = nil) -> Data? {
        let size = pointSize ?? CGSize(width: self.width, height: self.height)
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let data = self.tiffRepresentation as CFData?,
              let imageSource = CGImageSourceCreateWithData(data, imageSourceOptions) else { return nil }
        let downsampled = self.downsample(source: imageSource, size: size, scale: scale)
        guard let downsampled = downsampled else { return nil }
        return downsampled
    }
    
    private func downsample(source: CGImageSource, size: CGSize, scale: CGFloat?) -> Data? {
        let maxDimensionInPixels = max(size.width, size.height) * (scale ?? 0.5)
        let downsampledOptions = [kCGImageSourceCreateThumbnailFromImageAlways: true,
          kCGImageSourceShouldCacheImmediately: true,
          kCGImageSourceCreateThumbnailWithTransform: true,
          kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
        guard let downScaledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampledOptions) else { return nil }
        return downScaledImage.png
    }
}

/// Exceptions for the image extension class.
///
/// - creatingPngRepresentationFailed: Is thrown when the creation of the png representation failed.
enum NSImageExtensionError: Error {
    case unwrappingPNGRepresentationFailed
}
