//
//  Extensions.swift
//  Accord
//
//  Created by evelyn on 2021-06-07.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications

extension Dictionary {
    mutating func switchKey(fromKey: Key, toKey: Key) {
        if let entry = removeValue(forKey: fromKey) {
            self[toKey] = entry
        }
    }
}

public extension NSImage {
    func decodedImage() -> NSImage {
        let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)
        let size = CGSize(width: cgImage?.width ?? 40, height: cgImage?.height ?? 40)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: cgImage!.bytesPerRow, space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        context?.draw(cgImage!, in: CGRect(origin: .zero, size: size))
        guard let decodedImage = context?.makeImage() else { return self }
        return NSImage(cgImage: decodedImage, size: NSSize(width: cgImage?.width ?? 40, height: cgImage?.height ?? 40))
    }
}

class cuteWindow: NSWindow {
    override func close() {
        super.close()
    }
}

extension Dictionary {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }
    
}

extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}

extension String  {
    func conformsTo(_ pattern: String) -> Bool {
        return NSPredicate(format:"SELF MATCHES %@", pattern).evaluate(with: self)
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

extension NSColor {
    convenience init(hex: Int, alpha: Float) {
        print(hex, "HEX")
        self.init(
            calibratedRed: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0xFF00) >> 8) / 255.0,
            blue: CGFloat((hex & 0xFF)) / 255.0,
            alpha: 1.0
        )
    }
    
    convenience init(hex: String, alpha: Float) {
        // Handle two types of literals: 0x and # prefixed
        var cleanedString = ""
        if hex.hasPrefix("0x") {
            cleanedString = String(hex[hex.index(cleanedString.startIndex, offsetBy: 2)...hex.endIndex])
        } else if hex.hasPrefix("#") {
            cleanedString = String(hex[hex.index(cleanedString.startIndex, offsetBy: 1)...hex.endIndex])
        }
        
        // Ensure it only contains valid hex characters 0
        let validHexPattern = "[a-fA-F0-9]+"
        if cleanedString.conformsTo(validHexPattern) {
            var value: UInt64 = 0
            Scanner(string: cleanedString).scanHexInt64(&value)
            self.init(hex: Int(value), alpha: 1)
        } else {
            fatalError("Unable to parse color?")
        }
    }
}

public extension Collection where Indices.Iterator.Element == Index {
    subscript (exist index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
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

    // MARK: Resizing

    /// Resize the image to the given size.
    ///
    /// - Parameter size: The size to resize the image to.
    /// - Returns: The resized image.
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
    func resizeMaintainingAspectRatio(withSize targetSize: NSSize) -> NSImage? {
        let newSize: NSSize
        let widthRatio  = targetSize.width / self.width
        let heightRatio = targetSize.height / self.height
        
        if targetSize.width >= self.width || targetSize.height >= self.height {
            print("too small")
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
}

/// Exceptions for the image extension class.
///
/// - creatingPngRepresentationFailed: Is thrown when the creation of the png representation failed.
enum NSImageExtensionError: Error {
    case unwrappingPNGRepresentationFailed
}

func showNotification(title: String, subtitle: String) -> Void {
            let notification = NSUserNotification()
            notification.title = title
            notification.subtitle = subtitle
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
}

func userNotificationCenter(_ center: NSUserNotificationCenter,
                                         shouldPresent notification: NSUserNotification) -> Bool {
        return true
}


func clearAllNotifications() {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
}


// For KeychainManager

// For regex

public extension String {
    func capturedGroups(withRegex pattern: String) -> [String] {
        var results = [String]()
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [] )
        } catch {
            return results
        }
        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))

        guard let match = matches.first else { return results }

        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }
        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }

        return results
    }
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
    
    func indexInt(of char: Character) -> Int? {
        return firstIndex(of: char)?.utf16Offset(in: self)
    }
}

// Hide the TextField Focus Ring on Big Sur

extension NSTextField {
    open override var focusRingType: NSFocusRingType {
        get { .none }
        set { }
    }
}
