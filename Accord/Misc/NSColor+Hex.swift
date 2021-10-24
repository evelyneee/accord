//
//  NSColor+Hex.swift
//  NSColor+Hex
//
//  Created by evelyn on 2021-10-17.
//

import Foundation
import AppKit

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
